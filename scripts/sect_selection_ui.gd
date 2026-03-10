extends Control

class_name SectSelectionUI

# 拜师三清 - 宗门选择界面

signal sect_selected(sect_type: int)

var selected_sect: int = -1

# 三宗数据
var sects: Array = [
	{
		"name": "玉清宗",
		"tianzun": "元始天尊",
		"class_type": 0,  # ClassType.YUQING_FA
		"class_name": "法修",
		"description": "操控天地法则，释放元素法术",
		"main_attr": "法力",
		"feature": "远程魔法 · 范围AOE",
		"book": "《玉清玄法录》",
		"color": Color(0.4, 0.6, 1, 1),
		"skills": ["灵火术", "雷法·引雷诀", "九天神雷"]
	},
	{
		"name": "上清宗",
		"tianzun": "灵宝天尊",
		"class_type": 1,  # ClassType.SHANGQING_FU
		"class_name": "符修",
		"description": "符箓咒术，召唤灵兽，辅助治疗",
		"main_attr": "道法",
		"feature": "召唤灵宠 · 团队辅助",
		"book": "《上清灵宝经》",
		"color": Color(0.3, 0.8, 0.4, 1),
		"skills": ["回春符", "召唤·骨灵", "召唤·天将"]
	},
	{
		"name": "太清宗",
		"tianzun": "道德天尊",
		"class_type": 2,  # ClassType.TAIQING_JIAN
		"class_name": "剑修",
		"description": "炼体修剑，近战无敌，肉身成圣",
		"main_attr": "武力",
		"feature": "近战肉搏 · 高防御",
		"book": "《太清剑道篇》",
		"color": Color(0.9, 0.5, 0.2, 1),
		"skills": ["基础剑法", "剑气斩", "剑阵·千剑归宗"]
	}
]

func _ready():
	setup_ui()

func setup_ui():
	# 背景
	var background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0.05, 0.08, 0.12, 1)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# 标题
	var title = Label.new()
	title.name = "Title"
	title.text = "三清问道"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -200
	title.offset_top = 40
	title.offset_right = 200
	title.offset_bottom = 120
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	background.add_child(title)
	
	# 副标题
	var subtitle = Label.new()
	subtitle.text = "混沌初分，三清立道。少年有缘，拜入仙门，问道长生。"
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.offset_left = -300
	subtitle.offset_top = 100
	subtitle.offset_right = 300
	subtitle.offset_bottom = 140
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	background.add_child(subtitle)
	
	# 提示文字
	var hint = Label.new()
	hint.text = "请选择你要拜入的宗门"
	hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hint.offset_left = -150
	hint.offset_top = 160
	hint.offset_right = 150
	hint.offset_bottom = 190
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	background.add_child(hint)
	
	# 三宗选择卡片
	var card_container = HBoxContainer.new()
	card_container.name = "CardContainer"
	card_container.set_anchors_preset(Control.PRESET_CENTER)
	card_container.offset_left = -450
	card_container.offset_top = -150
	card_container.offset_right = 450
	card_container.offset_bottom = 200
	card_container.add_theme_constant_override("separation", 30)
	background.add_child(card_container)
	
	# 创建三个宗门卡片
	for i in range(sects.size()):
		var card = create_sect_card(i)
		card_container.add_child(card)
	
	# 确认按钮
	var confirm_btn = Button.new()
	confirm_btn.name = "ConfirmButton"
	confirm_btn.text = "确认拜师"
	confirm_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	confirm_btn.offset_left = -100
	confirm_btn.offset_top = -80
	confirm_btn.offset_right = 100
	confirm_btn.offset_bottom = -30
	confirm_btn.add_theme_font_size_override("font_size", 24)
	confirm_btn.disabled = true
	confirm_btn.pressed.connect(_on_confirm_pressed)
	background.add_child(confirm_btn)

func create_sect_card(index: int) -> Panel:
	var sect = sects[index]
	
	var card = Panel.new()
	card.name = "Card_" + str(index)
	card.custom_minimum_size = Vector2(260, 380)
	
	# 卡片背景色
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.95)
	style.border_color = sect.color
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", style)
	
	# 垂直布局
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 15
	vbox.offset_top = 15
	vbox.offset_right = -15
	vbox.offset_bottom = -15
	card.add_child(vbox)
	
	# 天尊名
	var tianzun_label = Label.new()
	tianzun_label.text = sect.tianzun
	tianzun_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tianzun_label.add_theme_font_size_override("font_size", 14)
	tianzun_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	vbox.add_child(tianzun_label)
	
	# 宗门名
	var name_label = Label.new()
	name_label.text = sect.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", sect.color)
	vbox.add_child(name_label)
	
	# 职业名
	var class_label = Label.new()
	class_label.text = "【" + sect.class_name + "】"
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_label.add_theme_font_size_override("font_size", 18)
	class_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7, 1))
	vbox.add_child(class_label)
	
	# 分隔线
	var separator = HSeparator.new()
	separator.add_theme_stylebox_override("separator", StyleBoxEmpty.new())
	vbox.add_child(separator)
	
	# 描述
	var desc_label = Label.new()
	desc_label.text = sect.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(desc_label)
	
	# 主修属性
	var attr_label = Label.new()
	attr_label.text = "主修：" + sect.main_attr
	attr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attr_label.add_theme_font_size_override("font_size", 13)
	attr_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(attr_label)
	
	# 特点
	var feature_label = Label.new()
	feature_label.text = sect.feature
	feature_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feature_label.add_theme_font_size_override("font_size", 13)
	feature_label.add_theme_color_override("font_color", sect.color)
	vbox.add_child(feature_label)
	
	# 功法
	var book_label = Label.new()
	book_label.text = "传承功法"
	book_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	book_label.add_theme_font_size_override("font_size", 12)
	book_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	vbox.add_child(book_label)
	
	var book_name = Label.new()
	book_name.text = sect.book
	book_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	book_name.add_theme_font_size_override("font_size", 14)
	book_name.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
	vbox.add_child(book_name)
	
	# 选择按钮
	var select_btn = Button.new()
	select_btn.text = "选择此宗"
	select_btn.add_theme_font_size_override("font_size", 16)
	select_btn.pressed.connect(_on_sect_selected.bind(index))
	vbox.add_child(select_btn)
	
	return card

func _on_sect_selected(index: int):
	selected_sect = index
	
	# 更新选中状态
	var card_container = get_node("Background/CardContainer")
	for i in range(card_container.get_child_count()):
		var card = card_container.get_child(i)
		var style = card.get_theme_stylebox("panel") as StyleBoxFlat
		
		if i == index:
			# 高亮选中
			style.set_border_width_all(5)
			style.border_color = Color(1, 0.9, 0.3, 1)
		else:
			# 恢复默认
			style.set_border_width_all(3)
			style.border_color = sects[i].color
	
	# 启用确认按钮
	var confirm_btn = get_node("Background/ConfirmButton")
	confirm_btn.disabled = false
	
	print("选择宗门: ", sects[index].name)

func _on_confirm_pressed():
	if selected_sect >= 0:
		emit_signal("sect_selected", selected_sect)
		print("确认拜师: ", sects[selected_sect].name)
		# 保存选择并开始游戏
		save_sect_selection(selected_sect)
		# 隐藏选择界面
		hide()
		# 开始游戏
		start_game()

func save_sect_selection(sect_type: int):
	var config = ConfigFile.new()
	config.set_value("player", "sect_type", sect_type)
	config.set_value("player", "sect_name", sects[sect_type].name)
	config.set_value("player", "class_name", sects[sect_type].class_name)
	config.save("user://player_data.cfg")

func start_game():
	# 切换到主游戏场景
	print("开始游戏...")
	# get_tree().change_scene_to_file("res://scenes/main.tscn")
