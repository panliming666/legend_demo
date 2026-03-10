extends Node

class_name PlatformAdapter

# 双端适配系统 - PC/移动端自动适配

# 平台类型
enum Platform {
	PC,
	MOBILE,
	WEB
}

var current_platform: Platform = Platform.PC
var is_touch_device: bool = false
var screen_size: Vector2 = Vector2(1280, 720)
var safe_area: Rect2 = Rect2(0, 0, 1280, 720)

# UI缩放设置
var ui_scale: float = 1.0
var min_ui_scale: float = 0.5
var max_ui_scale: float = 2.0

# 触摸控制
var virtual_joystick: Node = null
var virtual_buttons: Dictionary = {}

# 配置
var platform_config: Dictionary = {
	Platform.PC: {
		"ui_scale": 1.0,
		"touch_controls": false,
		"fps_limit": 60,
		"fullscreen": false
	},
	Platform.MOBILE: {
		"ui_scale": 1.2,
		"touch_controls": true,
		"fps_limit": 60,
		"fullscreen": true
	},
	Platform.WEB: {
		"ui_scale": 1.0,
		"touch_controls": false,
		"fps_limit": 60,
		"fullscreen": false
	}
}

signal platform_changed(platform: Platform)
signal screen_size_changed(size: Vector2)

func _ready():
	detect_platform()
	apply_platform_settings()
	
	# 监听屏幕尺寸变化
	get_tree().root.size_changed.connect(_on_screen_size_changed)

func detect_platform():
	# 检测运行平台
	if OS.has_feature("mobile"):
		current_platform = Platform.MOBILE
		is_touch_device = true
	elif OS.has_feature("web"):
		current_platform = Platform.WEB
		# Web可能是PC或移动端
		if DisplayServer.is_touch_available():
			is_touch_device = true
	else:
		current_platform = Platform.PC
		is_touch_device = DisplayServer.is_touch_available()
	
	# 更新屏幕尺寸
	screen_size = DisplayServer.screen_get_size()
	safe_area = DisplayServer.get_display_safe_area()
	
	print("检测到平台: ", Platform.keys()[current_platform])
	print("触摸设备: ", is_touch_device)
	print("屏幕尺寸: ", screen_size)

func apply_platform_settings():
	var config = platform_config[current_platform]
	
	# 应用UI缩放
	ui_scale = config.ui_scale
	_apply_ui_scale()
	
	# 设置FPS限制
	Engine.max_fps = config.fps_limit
	
	# 全屏设置
	if config.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# 触摸控制
	if config.touch_controls and is_touch_device:
		setup_touch_controls()
	
	emit_signal("platform_changed", current_platform)

func setup_touch_controls():
	# 创建虚拟摇杆
	virtual_joystick = _create_virtual_joystick()
	
	# 创建虚拟按钮
	virtual_buttons["attack"] = _create_virtual_button("攻击", Vector2(0.85, 0.7))
	virtual_buttons["skill_1"] = _create_virtual_button("Q", Vector2(0.75, 0.8))
	virtual_buttons["skill_2"] = _create_virtual_button("W", Vector2(0.85, 0.85))
	virtual_buttons["skill_3"] = _create_virtual_button("E", Vector2(0.95, 0.8))
	virtual_buttons["skill_4"] = _create_virtual_button("R", Vector2(0.85, 0.95))
	
	print("触摸控制已设置")

func _create_virtual_joystick() -> Node:
	var joystick_base = Control.new()
	joystick_base.name = "VirtualJoystick"
	joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick_base.offset_left = 50
	joystick_base.offset_top = -200
	joystick_base.offset_right = 200
	joystick_base.offset_bottom = -50
	
	# 基础圆
	var base = ColorRect.new()
	base.color = Color(1, 1, 1, 0.3)
	base.custom_minimum_size = Vector2(150, 150)
	base.position = Vector2(0, 0)
	joystick_base.add_child(base)
	
	# 摇杆圆
	var stick = ColorRect.new()
	stick.name = "Stick"
	stick.color = Color(1, 1, 1, 0.6)
	stick.custom_minimum_size = Vector2(60, 60)
	stick.position = Vector2(45, 45)
	joystick_base.add_child(stick)
	
	# 添加触摸处理脚本
	var script = GDScript.new()
	script.source_code = """
extends Control
var touch_index: int = -1
var center: Vector2 = Vector2(75, 75)
var max_distance: float = 60.0
signal joystick_moved(direction: Vector2)

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			reset_stick()
	
	if event is InputEventScreenDrag and event.index == touch_index:
		update_stick(event.position)

func update_stick(touch_pos: Vector2):
	var stick = $Stick
	var direction = touch_pos - center
	var distance = direction.length()
	
	if distance > max_distance:
		direction = direction.normalized() * max_distance
	
	stick.position = center + direction - Vector2(30, 30)
	
	var normalized_direction = direction / max_distance
	emit_signal("joystick_moved", normalized_direction)

func reset_stick():
	var stick = $Stick
	stick.position = Vector2(45, 45)
	emit_signal("joystick_moved", Vector2.ZERO)
"""
	script.reload()
	joystick_base.set_script(script)
	
	# 添加到场景
	get_tree().current_scene.add_child(joystick_base)
	
	return joystick_base

func _create_virtual_button(label: String, position: Vector2) -> Button:
	var button = Button.new()
	button.name = "VirtualButton_" + label
	button.text = label
	button.custom_minimum_size = Vector2(60, 60)
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	
	# 相对位置
	button.offset_right = -int((1.0 - position.x) * screen_size.x)
	button.offset_bottom = -int((1.0 - position.y) * screen_size.y)
	button.offset_left = button.offset_right - 60
	button.offset_top = button.offset_bottom - 60
	
	# 样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.7)
	style.border_color = Color(1, 1, 1, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", style)
	
	get_tree().current_scene.add_child(button)
	
	return button

func _apply_ui_scale():
	# 获取主视口
	var viewport = get_tree().root
	if viewport:
		viewport.content_scale_factor = ui_scale

func _on_screen_size_changed():
	screen_size = DisplayServer.window_get_size()
	safe_area = DisplayServer.get_display_safe_area()
	
	# 自动调整UI缩放
	_auto_adjust_scale()
	
	emit_signal("screen_size_changed", screen_size)

func _auto_adjust_scale():
	# 根据屏幕尺寸自动调整缩放
	var base_height = 720.0
	var height_ratio = screen_size.y / base_height
	
	if current_platform == Platform.MOBILE:
		ui_scale = clamp(height_ratio, min_ui_scale, max_ui_scale)
		_apply_ui_scale()

func set_ui_scale(scale: float):
	ui_scale = clamp(scale, min_ui_scale, max_ui_scale)
	_apply_ui_scale()

func get_platform() -> Platform:
	return current_platform

func is_mobile() -> bool:
	return current_platform == Platform.MOBILE

func is_pc() -> bool:
	return current_platform == Platform.PC

func is_web() -> bool:
	return current_platform == Platform.WEB

func has_touch() -> bool:
	return is_touch_device

func get_ui_scale() -> float:
	return ui_scale

func get_safe_area() -> Rect2:
	return safe_area

func hide_touch_controls():
	if virtual_joystick:
		virtual_joystick.visible = false
	for button in virtual_buttons.values():
		button.visible = false

func show_touch_controls():
	if virtual_joystick:
		virtual_joystick.visible = true
	for button in virtual_buttons.values():
		button.visible = true

func set_touch_controls_enabled(enabled: bool):
	if enabled:
		show_touch_controls()
	else:
		hide_touch_controls()
