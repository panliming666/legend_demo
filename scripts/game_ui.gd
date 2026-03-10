extends CanvasLayer

class_name GameUI

# 游戏主UI - 技能栏/快捷键/状态显示

# UI节点引用
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var exp_bar: ProgressBar
var level_label: Label
var skill_slots: Array = []
var inventory_button: Button
var menu_button: Button
var minimap: Control
var fps_label: Label

# 技能配置
var skills_config: Dictionary = {
	0: {"name": "普通攻击", "key": "Space", "cooldown": 0.0},
	1: {"name": "技能1", "key": "Q", "cooldown": 3.0},
	2: {"name": "技能2", "key": "W", "cooldown": 5.0},
	3: {"name": "技能3", "key": "E", "cooldown": 8.0},
	4: {"name": "技能4", "key": "R", "cooldown": 15.0},
	5: {"name": "药品", "key": "1", "cooldown": 2.0},
	6: {"name": "药品", "key": "2", "cooldown": 2.0}
}

var cooldown_timers: Dictionary = {}

func _ready():
	setup_ui()
	connect_signals()

func setup_ui():
	# 技能栏容器
	var skill_bar = HBoxContainer.new()
	skill_bar.name = "SkillBar"
	skill_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	skill_bar.offset_top = -80
	skill_bar.offset_left = -200
	add_child(skill_bar)
	
	# 创建技能槽位
	for i in range(7):
		var slot = create_skill_slot(i)
		skill_bar.add_child(slot)
		skill_slots.append(slot)
	
	# 快捷键提示
	var hotkeys = ["空格", "Q", "W", "E", "R", "1", "2"]
	for i in range(skill_slots.size()):
		var label = Label.new()
		label.text = hotkeys[i]
		label.position = Vector2(2, 42)
		label.add_theme_font_size_override("font_size", 10)
		skill_slots[i].add_child(label)
	
	# 系统按钮
	var top_right = HBoxContainer.new()
	top_right.name = "TopRight"
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.offset_left = -150
	top_right.offset_top = 10
	add_child(top_right)
	
	# 背包按钮
	inventory_button = Button.new()
	inventory_button.text = "背包[I]"
	inventory_button.custom_minimum_size = Vector2(60, 30)
	top_right.add_child(inventory_button)
	
	# 菜单按钮
	menu_button = Button.new()
	menu_button.text = "菜单[ESC]"
	menu_button.custom_minimum_size = Vector2(70, 30)
	top_right.add_child(menu_button)
	
	# FPS显示
	fps_label = Label.new()
	fps_label.name = "FPS"
	fps_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	fps_label.offset_left = 10
	fps_label.offset_top = 120
	fps_label.text = "FPS: 60"
	add_child(fps_label)
	
	# 金币显示
	var gold_label = Label.new()
	gold_label.name = "Gold"
	gold_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	gold_label.offset_left = 10
	gold_label.offset_top = 140
	gold_label.text = "金币: 0"
	add_child(gold_label)

func create_skill_slot(index: int) -> Panel:
	var slot = Panel.new()
	slot.name = "SkillSlot_" + str(index)
	slot.custom_minimum_size = Vector2(50, 50)
	
	# 技能图标背景
	var icon = ColorRect.new()
	icon.name = "Icon"
	icon.size = Vector2(46, 46)
	icon.position = Vector2(2, 2)
	icon.color = Color(0.2, 0.2, 0.3, 1)
	slot.add_child(icon)
	
	# 冷却遮罩
	var cooldown_overlay = ColorRect.new()
	cooldown_overlay.name = "CooldownOverlay"
	cooldown_overlay.size = Vector2(46, 46)
	cooldown_overlay.position = Vector2(2, 2)
	cooldown_overlay.color = Color(0, 0, 0, 0.7)
	cooldown_overlay.visible = false
	slot.add_child(cooldown_overlay)
	
	# 技能名称
	var skill_name = Label.new()
	skill_name.name = "SkillName"
	skill_name.text = skills_config.get(index, {}).get("name", "空")
	skill_name.position = Vector2(5, 5)
	skill_name.add_theme_font_size_override("font_size", 10)
	slot.add_child(skill_name)
	
	return slot

func connect_signals():
	# 连接按钮信号
	if inventory_button:
		inventory_button.pressed.connect(_on_inventory_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func _process(delta):
	# 更新FPS显示
	if fps_label:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	
	# 更新冷却时间
	update_cooldowns(delta)
	
	# 检测技能快捷键
	check_skill_hotkeys()

func update_cooldowns(delta):
	for skill_index in cooldown_timers.keys():
		cooldown_timers[skill_index] -= delta
		
		if cooldown_timers[skill_index] <= 0:
			cooldown_timers.erase(skill_index)
			set_skill_cooldown(skill_index, false)
		else:
			update_cooldown_display(skill_index, cooldown_timers[skill_index])

func update_cooldown_display(skill_index: int, remaining: float):
	if skill_index >= skill_slots.size():
		return
	
	var slot = skill_slots[skill_index]
	var overlay = slot.get_node_or_null("CooldownOverlay")
	if overlay:
		overlay.visible = true
		# 更新冷却进度显示
		var max_cooldown = skills_config.get(skill_index, {}).get("cooldown", 1.0)
		var progress = remaining / max_cooldown
		overlay.size.y = 46 * progress

func set_skill_cooldown(skill_index: int, active: bool):
	if skill_index >= skill_slots.size():
		return
	
	var slot = skill_slots[skill_index]
	var overlay = slot.get_node_or_null("CooldownOverlay")
	if overlay:
		overlay.visible = active

func check_skill_hotkeys():
	# 检测技能按键
	if Input.is_action_just_pressed("skill_1"):
		use_skill(1)
	if Input.is_action_just_pressed("skill_2"):
		use_skill(2)
	if Input.is_action_just_pressed("skill_3"):
		use_skill(3)
	if Input.is_action_just_pressed("skill_4"):
		use_skill(4)
	if Input.is_action_just_pressed("use_item_1"):
		use_skill(5)
	if Input.is_action_just_pressed("use_item_2"):
		use_skill(6)

func use_skill(skill_index: int):
	# 检查冷却
	if cooldown_timers.has(skill_index):
		print("技能冷却中...")
		return
	
	var skill = skills_config.get(skill_index, {})
	if skill.is_empty():
		return
	
	# 触发技能
	print("使用技能: ", skill.name)
	
	# 设置冷却
	var cooldown = skill.get("cooldown", 1.0)
	cooldown_timers[skill_index] = cooldown
	
	# 通知玩家施放技能
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("cast_skill"):
		player.cast_skill(skill_index)

func update_gold(amount: int):
	var gold_label = get_node_or_null("Gold")
	if gold_label:
		gold_label.text = "金币: " + str(amount)

func _on_inventory_pressed():
	print("打开背包")
	# 显示背包UI
	var inventory = get_tree().current_scene.get_node_or_null("InventoryUI")
	if inventory:
		inventory.show_inventory()

func _on_menu_pressed():
	print("打开菜单")
	# 显示游戏菜单
	show_game_menu()

func show_game_menu():
	var menu = PopupPanel.new()
	menu.name = "GameMenu"
	menu.size = Vector2(300, 400)
	menu.position = Vector2(
		get_viewport().size.x / 2 - 150,
		get_viewport().size.y / 2 - 200
	)
	
	var vbox = VBoxContainer.new()
	menu.add_child(vbox)
	
	# 菜单标题
	var title = Label.new()
	title.text = "游戏菜单"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# 继续游戏按钮
	var resume_btn = Button.new()
	resume_btn.text = "继续游戏"
	resume_btn.pressed.connect(func(): menu.hide())
	vbox.add_child(resume_btn)
	
	# 保存游戏按钮
	var save_btn = Button.new()
	save_btn.text = "保存游戏"
	save_btn.pressed.connect(_save_game)
	vbox.add_child(save_btn)
	
	# 加载游戏按钮
	var load_btn = Button.new()
	load_btn.text = "加载游戏"
	load_btn.pressed.connect(_load_game)
	vbox.add_child(load_btn)
	
	# 设置按钮
	var settings_btn = Button.new()
	settings_btn.text = "设置"
	settings_btn.pressed.connect(_show_settings)
	vbox.add_child(settings_btn)
	
	# 退出游戏按钮
	var quit_btn = Button.new()
	quit_btn.text = "退出游戏"
	quit_btn.pressed.connect(_quit_game)
	vbox.add_child(quit_btn)
	
	add_child(menu)
	menu.popup()

func _save_game():
	print("保存游戏...")
	var save_manager = get_tree().current_scene.get_node_or_null("SaveManager")
	var player = get_tree().current_scene.get_node_or_null("Player")
	if save_manager and player:
		save_manager.auto_save(player)
		print("游戏已保存")

func _load_game():
	print("加载游戏...")
	var save_manager = get_tree().current_scene.get_node_or_null("SaveManager")
	var player = get_tree().current_scene.get_node_or_null("Player")
	if save_manager and player:
		save_manager.load_to_player(player)
		print("游戏已加载")

func _show_settings():
	print("打开设置")

func _quit_game():
	get_tree().quit()
