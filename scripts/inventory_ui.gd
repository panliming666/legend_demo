extends Control

class_name InventoryUI

# 背包界面 - 显示装备和物品

var inventory_slots: Array = []
var equipped_slots: Dictionary = {}
const SLOT_SIZE = 60

func _ready():
	setup_ui()
	hide()

func setup_ui():
	# 创建背景面板
	var background = Panel.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_CENTER)
	background.size = Vector2(600, 500)
	add_child(background)
	
	# 标题
	var title = Label.new()
	title.name = "Title"
	title.text = "背包"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.offset_top = 10
	background.add_child(title)
	
	# 已装备区域
	_create_equipped_section(background)
	
	# 背包格子区域
	_create_inventory_grid(background)
	
	# 关闭按钮
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "关闭"
	close_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	close_button.offset_left = -100
	close_button.offset_top = -50
	close_button.offset_right = -20
	close_button.offset_bottom = -20
	close_button.pressed.connect(_on_close_pressed)
	background.add_child(close_button)

func _create_equipped_section(parent: Control):
	var equipped_label = Label.new()
	equipped_label.text = "已装备"
	equipped_label.position = Vector2(30, 50)
	parent.add_child(equipped_label)
	
	# 装备槽位类型
	var slot_types = ["weapon", "armor", "helmet", "boots", "accessory"]
	var slot_names = ["武器", "护甲", "头盔", "靴子", "饰品"]
	
	for i in range(slot_types.size()):
		var slot = _create_equipment_slot(slot_types[i], slot_names[i])
		slot.position = Vector2(30, 80 + i * 70)
		parent.add_child(slot)
		equipped_slots[slot_types[i]] = slot

func _create_equipment_slot(slot_type: String, slot_name: String) -> Control:
	var container = HBoxContainer.new()
	
	# 槽位按钮
	var slot_button = Button.new()
	slot_button.name = slot_type + "_slot"
	slot_button.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot_button.text = "空"
	container.add_child(slot_button)
	
	# 槽位名称
	var name_label = Label.new()
	name_label.text = slot_name
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(name_label)
	
	# 属性标签
	var stats_label = Label.new()
	stats_label.name = slot_type + "_stats"
	stats_label.text = ""
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(stats_label)
	
	return container

func _create_inventory_grid(parent: Control):
	var grid_label = Label.new()
	grid_label.text = "物品"
	grid_label.position = Vector2(250, 50)
	parent.add_child(grid_label)
	
	# 创建物品格子网格
	var grid_container = GridContainer.new()
	grid_container.name = "GridContainer"
	grid_container.columns = 5
	grid_container.position = Vector2(250, 80)
	parent.add_child(grid_container)
	
	# 创建25个格子
	for i in range(25):
		var slot = _create_inventory_slot(i)
		grid_container.add_child(slot)
		inventory_slots.append(slot)

func _create_inventory_slot(index: int) -> Button:
	var slot = Button.new()
	slot.name = "Slot_" + str(index)
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.text = ""
	slot.tooltip_text = "空"
	return slot

func update_inventory(items: Array):
	for i in range(min(items.size(), inventory_slots.size())):
		var slot = inventory_slots[i]
		var item = items[i]
		
		if item != null:
			slot.text = item.name.substr(0, 3) + "..."
			slot.tooltip_text = item.name + "\n" + item.get_stats_text()
			slot.modulate = item.get_rarity_color()
		else:
			slot.text = ""
			slot.tooltip_text = "空"
			slot.modulate = Color.WHITE

func update_equipped(equipment: Dictionary):
	for slot_type in equipped_slots.keys():
		var slot = equipped_slots[slot_type]
		var item = equipment.get(slot_type)
		
		var button = slot.get_node(slot_type + "_slot")
		var stats_label = slot.get_node(slot_type + "_stats")
		
		if item != null:
			button.text = item.name.substr(0, 4)
			button.modulate = item.get_rarity_color()
			stats_label.text = item.get_stats_text().replace("\n", " | ")
		else:
			button.text = "空"
			button.modulate = Color.WHITE
			stats_label.text = ""

func show_inventory():
	show()
	z_index = 100

func hide_inventory():
	hide()

func _on_close_pressed():
	hide_inventory()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if visible:
			hide_inventory()
