extends Node

class_name RefiningSystem

# 炼器系统 - 法宝打造与强化

signal item_crafted(item_name: String, rarity: int)
signal item_refined(item_name: String, new_level: int)
signal item_failed()

# 法宝类型
enum ItemType {
	SWORD,      # 剑（剑修武器）
	STAFF,      # 杖（法修武器）
	BRUSH,      # 笔（符修武器）
	ARMOR,      # 甲（衣服）
	HELMET,     # 冠（头盔）
	NECKLACE,   # 佩（项链）
	BRACELET,   # 镯（手镯）
	RING,       # 戒（戒指）
	BELT,       # 带（腰带）
	BOOTS,      # 靴（靴子）
	GEM         # 灵石（宝石）
}

# 品质
enum Rarity {
	FAN,    # 凡品
	LING,   # 灵品
	BAO,    # 宝品
	XIAN,   # 仙品
	SHEN,   # 神品
	SHENG   # 圣品
}

# 法宝数据库
var item_templates: Dictionary = {
	ItemType.SWORD: {
		"name": "仙剑",
		"base_stats": {"武力": 15, "攻击速度": 5},
		"materials": {"玄铁": 5, "灵石": 2},
		"required_level": 1,
		"class_restriction": ["太清宗"]
	},
	ItemType.STAFF: {
		"name": "法杖",
		"base_stats": {"法力": 15, "施法速度": 5},
		"materials": {"灵木": 5, "灵石": 2},
		"required_level": 1,
		"class_restriction": ["玉清宗"]
	},
	ItemType.BRUSH: {
		"name": "符笔",
		"base_stats": {"道法": 15, "施法速度": 5},
		"materials": {"灵木": 3, "妖毛": 3},
		"required_level": 1,
		"class_restriction": ["上清宗"]
	},
	ItemType.ARMOR: {
		"name": "道袍",
		"base_stats": {"防御": 10, "生命": 50},
		"materials": {"灵丝": 5, "灵石": 1},
		"required_level": 1,
		"class_restriction": []
	},
	ItemType.HELMET: {
		"name": "道冠",
		"base_stats": {"防御": 5, "法力": 10},
		"materials": {"玄铁": 3, "灵丝": 2},
		"required_level": 5,
		"class_restriction": []
	},
	ItemType.NECKLACE: {
		"name": "玉佩",
		"base_stats": {"法力": 8, "准确": 5},
		"materials": {"灵玉": 3, "灵石": 1},
		"required_level": 3,
		"class_restriction": []
	},
	ItemType.BRACELET: {
		"name": "护腕",
		"base_stats": {"武力": 5, "道法": 5, "法力": 5},
		"materials": {"玄铁": 2, "灵玉": 2},
		"required_level": 5,
		"class_restriction": []
	},
	ItemType.RING: {
		"name": "戒指",
		"base_stats": {"暴击": 3, "武力": 3},
		"materials": {"灵玉": 2, "灵石": 1},
		"required_level": 3,
		"class_restriction": []
	},
	ItemType.BELT: {
		"name": "束带",
		"base_stats": {"生命": 30, "敏捷": 3},
		"materials": {"灵丝": 3, "灵石": 1},
		"required_level": 5,
		"class_restriction": []
	},
	ItemType.BOOTS: {
		"name": "道靴",
		"base_stats": {"防御": 3, "移动速度": 5},
		"materials": {"灵丝": 2, "玄铁": 2},
		"required_level": 5,
		"class_restriction": []
	},
	ItemType.GEM: {
		"name": "灵石",
		"base_stats": {"全属性": 3},
		"materials": {"灵石碎片": 10},
		"required_level": 1,
		"class_restriction": []
	}
}

# 材料库存
var materials: Dictionary = {
	"玄铁": 30,
	"灵木": 25,
	"灵丝": 20,
	"灵玉": 15,
	"灵石": 50,
	"灵石碎片": 100,
	"妖毛": 10,
	"神铁": 5,
	"仙木": 3,
	"天丝": 2,
	"神玉": 1
}

# 炼器等级
var refining_level: int = 1
var refining_exp: int = 0

func _ready():
	load_refining()

# 打造法宝
func craft_item(item_type: int, target_rarity: int = Rarity.FAN) -> Dictionary:
	var template = item_templates.get(item_type)
	if template == null:
		return {"success": false, "message": "法宝类型不存在"}
	
	# 检查等级
	if refining_level < template.required_level:
		return {"success": false, "message": "炼器等级不足"}
	
	# 计算材料消耗（品质越高消耗越大）
	var mats_needed = {}
	var mat_multiplier = 1.0 + target_rarity * 0.5
	for mat in template.materials.keys():
		mats_needed[mat] = int(template.materials[mat] * mat_multiplier)
	
	# 高品质需要额外材料
	if target_rarity >= Rarity.BAO:
		mats_needed["灵石"] = mats_needed.get("灵石", 0) + target_rarity * 3
	if target_rarity >= Rarity.XIAN:
		mats_needed["神铁"] = mats_needed.get("神铁", 0) + target_rarity
	if target_rarity >= Rarity.SHEN:
		mats_needed["仙木"] = mats_needed.get("仙木", 0) + 1
	
	# 检查材料
	if not has_materials(mats_needed):
		return {"success": false, "message": "材料不足"}
	
	# 消耗材料
	for mat in mats_needed.keys():
		materials[mat] -= mats_needed[mat]
	
	# 成功率计算（品质越高成功率越低）
	var base_rate = 0.9
	var rarity_penalty = target_rarity * 0.15
	var level_bonus = refining_level * 0.02
	var success_rate = base_rate - rarity_penalty + level_bonus
	success_rate = max(0.1, min(1.0, success_rate))
	
	if randf() <= success_rate:
		# 打造成功
		var item = create_item(item_type, template, target_rarity)
		
		# 增加经验
		refining_exp += 10 + target_rarity * 5
		check_level_up()
		
		emit_signal("item_crafted", item.name, target_rarity)
		save_refining()
		
		return {
			"success": true,
			"item": item,
			"message": "打造成功：%s（%s）" % [item.name, get_rarity_name(target_rarity)]
		}
	else:
		# 打造失败
		emit_signal("item_failed")
		save_refining()
		return {"success": false, "message": "打造失败，材料已消耗"}

# 创建法宝
func create_item(item_type: int, template: Dictionary, rarity: int) -> Dictionary:
	var rarity_multiplier = 1.0 + rarity * 0.3
	var rarity_names = ["凡品", "灵品", "宝品", "仙品", "神品", "圣品"]
	var rarity_prefix = rarity_names[rarity]
	
	var item: Dictionary = {
		"id": str(item_type) + "_" + str(randi()),
		"type": item_type,
		"name": rarity_prefix + template.name,
		"rarity": rarity,
		"level": template.required_level,
		"refine_level": 0,  # 强化等级
		"stats": {},
		"class_restriction": template.class_restriction,
		"description": ""
	}
	
	# 计算属性
	for stat in template.base_stats.keys():
		item.stats[stat] = int(template.base_stats[stat] * rarity_multiplier)
	
	# 高品质附加随机属性
	if rarity >= Rarity.LING:
		item.stats.merge(get_random_bonus_stats(rarity))
	
	item.description = generate_description(item)
	
	return item

# 随机附加属性
func get_random_bonus_stats(rarity: int) -> Dictionary:
	var bonus: Dictionary = {}
	var possible_stats = ["生命", "法力", "武力", "法力", "道法", "防御", "暴击", "敏捷", "准确"]
	var bonus_count = rarity  # 品质越高，附加属性越多
	
	for i in range(bonus_count):
		var stat = possible_stats[randi() % possible_stats.size()]
		var value = (rarity + 1) * randi_range(1, 5)
		
		if bonus.has(stat):
			bonus[stat] += value
		else:
			bonus[stat] = value
	
	return bonus

# 强化法宝
func refine_item(item: Dictionary, use_protection: bool = false) -> Dictionary:
	var current_level = item.get("refine_level", 0)
	
	if current_level >= 10:
		return {"success": false, "message": "已达最高强化等级"}
	
	# 检查材料
	var mats_needed = {
		"灵石": current_level + 1
	}
	
	if current_level >= 5:
		mats_needed["神铁"] = 1
	if current_level >= 8:
		mats_needed["神玉"] = 1
	
	if not has_materials(mats_needed):
		return {"success": false, "message": "材料不足"}
	
	# 消耗材料
	for mat in mats_needed.keys():
		materials[mat] -= mats_needed[mat]
	
	# 成功率（等级越高越难）
	var base_rate = 0.9 - current_level * 0.08
	var level_bonus = refining_level * 0.01
	var success_rate = max(0.1, base_rate + level_bonus)
	
	# 使用保护符
	if use_protection:
		# 消耗保护符（未实现）
		success_rate = 1.0
	
	if randf() <= success_rate:
		# 强化成功
		item.refine_level = current_level + 1
		
		# 提升属性
		for stat in item.stats.keys():
			item.stats[stat] = int(item.stats[stat] * 1.1)
		
		refining_exp += 5 + current_level
		check_level_up()
		
		emit_signal("item_refined", item.name, item.refine_level)
		save_refining()
		
		return {
			"success": true,
			"item": item,
			"message": "强化成功：+%d" % item.refine_level
		}
	else:
		# 强化失败
		if not use_protection:
			# 降级
			item.refine_level = max(0, current_level - 1)
			for stat in item.stats.keys():
				item.stats[stat] = int(item.stats[stat] / 1.1)
		
		emit_signal("item_failed")
		save_refining()
		
		return {
			"success": false,
			"message": "强化失败，等级降低",
			"item": item
		}

# 洗炼属性
func reroll_stats(item: Dictionary) -> Dictionary:
	if item.rarity < Rarity.LING:
		return {"success": false, "message": "品质不足，无法洗炼"}
	
	# 检查材料
	var mats_needed = {
		"灵石": 5 * item.rarity,
		"灵玉": item.rarity
	}
	
	if not has_materials(mats_needed):
		return {"success": false, "message": "材料不足"}
	
	# 消耗材料
	for mat in mats_needed.keys():
		materials[mat] -= mats_needed[mat]
	
	# 重新生成附加属性
	var new_bonus = get_random_bonus_stats(item.rarity)
	
	# 保留基础属性，重置附加属性
	var template = item_templates[item.type]
	item.stats = {}
	for stat in template.base_stats.keys():
		item.stats[stat] = int(template.base_stats[stat] * (1.0 + item.rarity * 0.3))
	
	# 应用新的附加属性
	for stat in new_bonus.keys():
		if item.stats.has(stat):
			item.stats[stat] += new_bonus[stat]
		else:
			item.stats[stat] = new_bonus[stat]
	
	item.description = generate_description(item)
	
	save_refining()
	return {
		"success": true,
		"item": item,
		"message": "洗炼成功"
	}

# 检查材料
func has_materials(mats: Dictionary) -> bool:
	for mat in mats.keys():
		if materials.get(mat, 0) < mats[mat]:
			return false
	return true

# 获取品质名称
func get_rarity_name(rarity: int) -> String:
	var names = ["凡品", "灵品", "宝品", "仙品", "神品", "圣品"]
	return names[rarity] if rarity < names.size() else "未知"

# 生成描述
func generate_description(item: Dictionary) -> String:
	var desc = item.name + "\n"
	desc += "品质：" + get_rarity_name(item.rarity) + "\n"
	desc += "等级要求：" + str(item.level) + "\n"
	if item.refine_level > 0:
		desc += "强化：+" + str(item.refine_level) + "\n"
	desc += "\n属性：\n"
	for stat in item.stats.keys():
		desc += "  " + stat + "：+" + str(item.stats[stat]) + "\n"
	return desc

# 检查升级
func check_level_up():
	var exp_needed = refining_level * 20
	if refining_exp >= exp_needed:
		refining_level += 1
		refining_exp -= exp_needed
		print("炼器等级提升：", refining_level)

# 添加材料
func add_material(mat_name: String, count: int):
	if not materials.has(mat_name):
		materials[mat_name] = 0
	materials[mat_name] += count

# 获取材料
func get_materials() -> Dictionary:
	return materials.duplicate()

# 保存/加载
func save_refining():
	var config = ConfigFile.new()
	config.set_value("refining", "level", refining_level)
	config.set_value("refining", "exp", refining_exp)
	config.set_value("refining", "materials", materials)
	config.save("user://refining.cfg")

func load_refining():
	if FileAccess.file_exists("user://refining.cfg"):
		var config = ConfigFile.new()
		if config.load("user://refining.cfg") == OK:
			refining_level = config.get_value("refining", "level", 1)
			refining_exp = config.get_value("refining", "exp", 0)
			materials = config.get_value("refining", "materials", materials)
