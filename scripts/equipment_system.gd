extends Node

class_name EquipmentSystem

# 传奇世界装备系统
# 槽位：头盔、项链、手镯x2、戒指x2、腰带、靴子、武器、衣服、宝石x2

signal equipment_changed(slot: String, item: Dictionary)
signal equipment_unequipped(slot: String)

# 装备槽位类型
enum EquipmentSlot {
	HELMET,      # 头盔
	NECKLACE,    # 项链
	BRACELET_L,  # 左手镯
	BRACELET_R,  # 右手镯
	RING_L,      # 左戒指
	RING_R,      # 右戒指
	BELT,        # 腰带
	BOOTS,       # 靴子
	WEAPON,      # 武器
	ARMOR,       # 衣服
	GEM_1,       # 宝石槽1
	GEM_2        # 宝石槽2
}

# 槽位名称映射
var slot_names: Dictionary = {
	EquipmentSlot.HELMET: "头盔",
	EquipmentSlot.NECKLACE: "项链",
	EquipmentSlot.BRACELET_L: "左手镯",
	EquipmentSlot.BRACELET_R: "右手镯",
	EquipmentSlot.RING_L: "左戒指",
	EquipmentSlot.RING_R: "右戒指",
	EquipmentSlot.BELT: "腰带",
	EquipmentSlot.BOOTS: "靴子",
	EquipmentSlot.WEAPON: "武器",
	EquipmentSlot.ARMOR: "衣服",
	EquipmentSlot.GEM_1: "宝石1",
	EquipmentSlot.GEM_2: "宝石2"
}

# 玩家装备
var equipped_items: Dictionary = {}

# 装备属性加成
var total_bonus: Dictionary = {
	"physical_attack": 0,    # 物理攻击
	"magic_attack": 0,       # 魔法攻击
	"taoism_attack": 0,     # 道术攻击
	"physical_defense": 0,   # 物理防御
	"magic_defense": 0,     # 魔法防御
	"max_hp": 0,            # 生命上限
	"max_mp": 0,            # 魔法上限
	"accuracy": 0,           # 准确
	"agility": 0,           # 敏捷
	"crit_rate": 0,         # 暴击率
	"crit_damage": 0,       # 暴击伤害
	"attack_speed": 0,      # 攻击速度
	"move_speed": 0,        # 移动速度
	"hp_regen": 0,          # 生命恢复
	"mp_regen": 0           # 魔法恢复
}

func _ready():
	# 初始化装备槽位
	for slot in EquipmentSlot.keys():
		equipped_items[EquipmentSlot[slot]] = null

# 穿戴装备
func equip_item(item: Dictionary) -> bool:
	var slot_type = _get_slot_type(item)
	
	if slot_type == -1:
		print("无效装备类型")
		return false
	
	# 检查职业限制
	if not _check_job_restriction(item):
		print("职业不匹配")
		return false
	
	# 卸下原有装备
	var old_item = equipped_items.get(slot_type)
	if old_item:
		unequip_item(slot_type)
	
	# 穿戴新装备
	equipped_items[slot_type] = item
	
	# 更新属性加成
	_update_total_bonus()
	
	emit_signal("equipment_changed", slot_names[slot_type], item)
	print("穿戴装备: ", item.name, " -> ", slot_names[slot_type])
	return true

# 卸下装备
func unequip_item(slot_type) -> bool:
	if not equipped_items.has(slot_type):
		return false
	
	var item = equipped_items[slot_type]
	if item == null:
		return false
	
	equipped_items[slot_type] = null
	_update_total_bonus()
	
	emit_signal("equipment_unequipped", slot_names[slot_type])
	print("卸下装备: ", slot_names[slot_type])
	return true

# 获取槽位类型
func _get_slot_type(item: Dictionary) -> int:
	var type = item.get("type", "")
	
	match type:
		"helmet": return EquipmentSlot.HELMET
		"necklace": return EquipmentSlot.NECKLACE
		"bracelet": return EquipmentSlot.BRACELET_L  # 默认左手镯
		"bracelet_l": return EquipmentSlot.BRACELET_L
		"bracelet_r": return EquipmentSlot.BRACELET_R
		"ring": return EquipmentSlot.RING_L  # 默认左戒指
		"ring_l": return EquipmentSlot.RING_L
		"ring_r": return EquipmentSlot.RING_R
		"belt": return EquipmentSlot.BELT
		"boots": return EquipmentSlot.BOOTS
		"weapon": return EquipmentSlot.WEAPON
		"armor": return EquipmentSlot.ARMOR
		"gem": return EquipmentSlot.GEM_1
	
	return -1

# 检查职业限制
_restriction(item: Dictionary) -> boolfunc _check_job:
	var allowed_jobs = item.get("allowed_jobs", ["warrior", "mage", "taoist"])
	var player_job = "warrior"  # 默认战士
	
	return player_job in allowed_jobs

# 更新总属性加成
func _update_total_bonus():
	# 重置属性
	for key in total_bonus.keys():
		total_bonus[key] = 0
	
	# 遍历所有已装备物品
	for slot in equipped_items.keys():
		var item = equipped_items[slot]
		if item != null:
			_add_item_bonus(item)
	
	# 加上宝石属性
	_add_gem_bonus()

func _add_item_bonus(item: Dictionary):
	var stats = item.get("stats", {})
	for key in stats.keys():
		if total_bonus.has(key):
			total_bonus[key] += stats[key]

func _add_gem_bonus():
	# 宝石特殊加成（3件同属性宝石激活套装效果）
	var gem_colors = []
	
	for slot in [EquipmentSlot.GEM_1, EquipmentSlot.GEM_2]:
		var gem = equipped_items.get(slot)
		if gem != null:
			gem_colors.append(gem.get("gem_color", ""))
	
	# 套装效果
	if gem_colors.size() >= 2 and gem_colors[0] == gem_colors[1]:
		match gem_colors[0]:
			"red":  # 红宝石 - 攻击套装
				total_bonus["physical_attack"] += 10
				total_bonus["magic_attack"] += 10
				total_bonus["crit_rate"] += 5
			"blue": # 蓝宝石 - 防御套装
				total_bonus["physical_defense"] += 10
				total_bonus["magic_defense"] += 10
				total_bonus["max_hp"] += 100
			"green": # 绿宝石 - 生命套装
				total_bonus["max_hp"] += 50
				total_bonus["hp_regen"] += 5
				total_bonus["agility"] += 5

# 获取装备属性
func get_equipment_stats() -> Dictionary:
	return total_bonus.duplicate()

# 获取指定槽位的装备
func get_equipped_item(slot_type: int) -> Dictionary:
	return equipped_items.get(slot_type)

# 获取所有装备
func get_all_equipped() -> Dictionary:
	return equipped_items.duplicate()

# 装备强化
func enhance_equipment(slot_type: int, level: int) -> bool:
	var item = equipped_items.get(slot_type)
	if item == null:
		return false
	
	# 强化成功率（每级降低10%）
	var success_rate = 1.0 - (level * 0.1)
	if randf() > success_rate:
		print("强化失败")
		return false
	
	# 强化成功
	if not item.has("enhance_level"):
		item["enhance_level"] = 0
	item["enhance_level"] += 1
	
	# 计算强化属性
	var base_stats = item.get("base_stats", item.get("stats", {}))
	var enhanced_stats = {}
	for key in base_stats.keys():
		enhanced_stats[key] = int(base_stats[key] * (1 + level * 0.1))
	
	item["stats"] = enhanced_stats
	
	_update_total_bonus()
	print("强化成功: ", item.name, " +", level)
	return true

# 装备合成（2件同等级装备合成下一级）
func combine_equipment(slot_type: int) -> bool:
	var item = equipped_items.get(slot_type)
	if item == null:
		return false
	
	if item.get("enhance_level", 0) < 1:
		return false
	
	# 简化版：直接升级
	item["enhance_level"] += 1
	
	# 更新属性
	var base_stats = item.get("base_stats", item.get("stats", {}))
	var enhanced_stats = {}
	for key in base_stats.keys():
		enhanced_stats[key] = int(base_stats[key] * (1 + item["enhance_level"] * 0.1))
	
	item["stats"] = enhanced_stats
	
	_update_total_bonus()
	print("合成成功: ", item.name, " +", item["enhance_level"])
	return true

# 创建传奇世界风格装备
static func create_equipment(equipment_type: String, level: int, rarity: int) -> Dictionary:
	var item: Dictionary = {
		"id": equipment_type + "_" + str(level) + "_" + str(rarity),
		"name": "",
		"type": equipment_type,
		"level": level,
		"rarity": rarity,
		"stats": {},
		"base_stats": {},
		"allowed_jobs": ["warrior", "mage", "taoist"],
		"description": ""
	}
	
	# 装备名称前缀
	var rarity_names = ["普通", "高级", "稀有", "卓越", "史诗", "传说"]
	var rarity_name = rarity_names[min(rarity, rarity_names.size() - 1)]
	
	# 基础属性（基于等级）
	var base_value = level * 5
	
	match equipment_type:
		"helmet":
			item.name = rarity_name + "头盔"
			item.base_stats = {
				"physical_defense": base_value,
				"magic_defense": int(base_value * 0.5),
				"max_hp": int(base_value * 2)
			}
			item.description = "等级" + str(level) + "，物理防御+" + str(base_value)
		
		"necklace":
			item.name = rarity_name + "项链"
			item.base_stats = {
				"max_mp": int(base_value * 3),
				"magic_attack": base_value,
				"accuracy": int(base_value * 0.5)
			}
			item.description = "等级" + str(level) + "，魔法+" + str(base_value)
		
		"bracelet":
			item.name = rarity_name + "手镯"
			item.base_stats = {
				"physical_attack": base_value,
				"magic_attack": base_value,
				"attack_speed": 1
			}
			item.description = "等级" + str(level) + "，攻击+" + str(base_value)
		
		"ring":
			item.name = rarity_name + "戒指"
			item.base_stats = {
				"physical_attack": int(base_value * 0.8),
				"crit_rate": 2,
				"max_hp": int(base_value)
			}
			item.description = "等级" + str(level) + "，攻击+" + str(int(base_value * 0.8))
		
		"belt":
			item.name = rarity_name + "腰带"
			item.base_stats = {
				"physical_defense": int(base_value * 0.5),
				"max_hp": int(base_value * 2),
				"agility": int(base_value * 0.3)
			}
			item.description = "等级" + str(level) + "，生命+" + str(int(base_value * 2))
		
		"boots":
			item.name = rarity_name + "靴子"
			item.base_stats = {
				"physical_defense": int(base_value * 0.5),
				"move_speed": 5,
				"agility": int(base_value * 0.5)
			}
			item.description = "等级" + str(level) + "，移动速度+" + str(5)
		
		"weapon":
			item.name = rarity_name + "武器"
			item.allowed_jobs = ["warrior"]  # 默认战士武器
			item.base_stats = {
				"physical_attack": base_value * 2,
				"attack_speed": 2
			}
			item.description = "等级" + str(level) + "，物理攻击+" + str(base_value * 2)
		
		"armor":
			item.name = rarity_name + "衣服"
			item.base_stats = {
				"physical_defense": base_value * 2,
				"magic_defense": base_value,
				"max_hp": int(base_value * 3)
			}
			item.description = "等级" + str(level) + "，物理防御+" + str(base_value * 2)
		
		"gem":
			item.name = rarity_name + "宝石"
			item.base_stats = {
				"physical_attack": int(base_value * 0.5)
			}
			item.description = "可镶嵌宝石"
	
	# 应用稀有度加成
	if rarity > 0:
		var rarity_multiplier = 1.0 + (rarity * 0.2)
		for key in item.base_stats.keys():
			item.base_stats[key] = int(item.base_stats[key] * rarity_multiplier)
	
	item.stats = item.base_stats.duplicate()
	
	return item

# 获取装备描述
func get_equipment_description(slot_type: int) -> String:
	var item = equipped_items.get(slot_type)
	if item == null:
		return slot_names.get(slot_type, "空") + ": 无"
	
	var desc = item.name + "\n"
	desc += item.get("description", "") + "\n"
	
	if item.has("enhance_level") and item.enhance_level > 0:
		desc += "强化等级: +" + str(item.enhance_level) + "\n"
	
	var stats = item.get("stats", {})
	for stat_name in stats.keys():
		desc += _get_stat_name(stat_name) + ": +" + str(stats[stat_name]) + "\n"
	
	return desc

func _get_stat_name(stat: String) -> String:
	var names = {
		"physical_attack": "物理攻击",
		"magic_attack": "魔法攻击",
		"taoism_attack": "道术攻击",
		"physical_defense": "物理防御",
		"magic_defense": "魔法防御",
		"max_hp": "生命上限",
		"max_mp": "魔法上限",
		"accuracy": "准确",
		"agility": "敏捷",
		"crit_rate": "暴击率",
		"crit_damage": "暴击伤害",
		"attack_speed": "攻击速度",
		"move_speed": "移动速度"
	}
	return names.get(stat, stat)
