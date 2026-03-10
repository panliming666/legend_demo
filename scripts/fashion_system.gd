extends Node

class_name FashionSystem

# 时装系统

signal fashion_equipped(fashion_id: String)
signal fashion_unequipped(fashion_id: String)

# 时装类型
enum FashionType {
	WEAPON_FASHION,   # 武器时装
	CLOTHING_FASHION, # 衣服时装
	HEAD_FASHION,     # 头部时装
	WING_FASHION,     # 翅膀时装
	MOUNT_FASHION     # 坐骑时装
}

# 稀有度
enum FashionRarity {
	COMMON,     # 普通
	RARE,       # 稀有
	EPIC,       # 史诗
	LEGENDARY,  # 传说
	MYTHICAL    # 神级
}

# 时装数据库
var fashion_database: Dictionary = {
	# 武器时装
	"weapon_1": {
		"name": "新手剑外观",
		"type": FashionType.WEAPON_FASHION,
		"rarity": FashionRarity.COMMON,
		"description": "新手剑的外观",
		"model": "sword_newbie",
		"effect": {}
	},
	"weapon_2": {
		"name": "仙剑·青莲",
		"type": FashionType.WEAPON_FASHION,
		"rarity": FashionRarity.EPIC,
		"description": "青莲仙剑的外观",
		"model": "sword_lotus",
		"effect": {"all_attack": 10}
	},
	"weapon_3": {
		"name": "法杖·星辰",
		"type": FashionType.WEAPON_FASHION,
		"rarity": FashionRarity.LEGENDARY,
		"description": "星辰法杖的外观",
		"model": "staff_star",
		"effect": {"magic_attack": 15}
	},
	
	# 衣服时装
	"clothing_1": {
		"name": "门派制服",
		"type": FashionType.CLOTHING_FASHION,
		"rarity": FashionRarity.COMMON,
		"description": "宗门发放的制式服装",
		"model": "clothing_sect",
		"effect": {}
	},
	"clothing_2": {
		"name": "霓裳羽衣",
		"type": FashionType.CLOTHING_FASHION,
		"rarity": FashionRarity.LEGENDARY,
		"description": "仙气飘飘的羽衣",
		"model": "clothing_feather",
		"effect": {"charm": 20, "all_defense": 10}
	},
	
	# 头部时装
	"head_1": {
		"name": "玉清冠",
		"type": FashionType.HEAD_FASHION,
		"rarity": FashionRarity.RARE,
		"description": "玉清宗弟子头冠",
		"model": "head_yuqing",
		"effect": {"magic_defense": 5}
	},
	"head_2": {
		"name": "太清冠",
		"type": FashionType.HEAD_FASHION,
		"rarity": FashionRarity.RARE,
		"description": "太清宗弟子头冠",
		"model": "head_taiqing",
		"effect": {"physical_defense": 5}
	},
	
	# 翅膀时装
	"wing_1": {
		"name": "灵气化翼",
		"type": FashionType.WING_FASHION,
		"rarity": FashionRarity.EPIC,
		"description": "修炼出的灵气翅膀",
		"model": "wing_spirit",
		"effect": {"move_speed": 10, "all_attack": 5}
	},
	"wing_2": {
		"name": "天使翅膀",
		"type": FashionType.WING_FASHION,
		"rarity": FashionRarity.LEGENDARY,
		"description": "神圣的天使翅膀",
		"model": "wing_angel",
		"effect": {"move_speed": 20, "all_attack": 10, "charm": 30}
	},
	"wing_3": {
		"name": "天龙之翼",
		"type": FashionType.WING_FASHION,
		"rarity": FashionRarity.MYTHICAL,
		"description": "天龙化身的神翅",
		"model": "wing_dragon",
		"effect": {"move_speed": 30, "all_attack": 20, "all_defense": 15, "charm": 50}
	},
	
	# 坐骑时装
	"mount_1": {
		"name": "云辇",
		"type": FashionType.MOUNT_FASHION,
		"rarity": FashionRarity.EPIC,
		"description": "仙云缭绕的辇车",
		"model": "mount_cloud",
		"effect": {"move_speed": 15}
	}
}

# 玩家拥有的时装
var owned_fashions: Array = []
var equipped_fashions: Dictionary = {}  # type: fashion_id

func _ready():
	load_fashions()

# 获得时装
func obtain_fashion(fashion_id: String) -> bool:
	var fashion = fashion_database.get(fashion_id)
	if fashion == null:
		return false
	
	if fashion_id in owned_fashions:
		return false
	
	owned_fashions.append(fashion_id)
	save_fashions()
	
	print("获得时装：", fashion.name)
	return true

# 穿戴时装
func equip_fashion(fashion_id: String) -> bool:
	var fashion = fashion_database.get(fashion_id)
	if fashion == null:
		return false
	
	if not fashion_id in owned_fashions:
		return false
	
	# 卸下同类型时装
	var f_type = fashion.type
	if equipped_fashions.has(f_type):
		unequip_fashion(f_type)
	
	# 穿戴
	equipped_fashions[f_type] = fashion_id
	
	emit_signal("fashion_equipped", fashion_id)
	save_fashions()
	
	print("穿戴时装：", fashion.name)
	return true

# 卸下时装
func unequip_fashion(fashion_type: int) -> bool:
	if not equipped_fashions.has(fashion_type):
		return false
	
	var fashion_id = equipped_fashions[fashion_type]
	equipped_fashions.erase(fashion_type)
	
	emit_signal("fashion_unequipped", fashion_id)
	save_fashions()
	
	return true

# 获取时装属性加成
func get_fashion_bonus() -> Dictionary:
	var bonus: Dictionary = {}
	
	for f_type in equipped_fashions.keys():
		var fashion_id = equipped_fashions[f_type]
		var fashion = fashion_database.get(fashion_id)
		
		if fashion != null and fashion.has("effect"):
			for key in fashion.effect.keys():
				if not bonus.has(key):
					bonus[key] = 0
				bonus[key] += fashion.effect[key]
	
	return bonus

# 获取已穿戴的时装
func get_equipped_fashions() -> Dictionary:
	var result = {}
	
	for f_type in equipped_fashions.keys():
		var fashion_id = equipped_fashions[f_type]
		var fashion = fashion_database.get(fashion_id)
		if fashion != null:
			result[f_type] = fashion
	
	return result

# 获取拥有的时装列表
func get_owned_fashions() -> Array:
	var result = []
	
	for fashion_id in owned_fashions:
		var fashion = fashion_database.get(fashion_id)
		if fashion != null:
			result.append({
				"id": fashion_id,
				"name": fashion.name,
				"type": fashion.type,
				"rarity": fashion.rarity,
				"description": fashion.description,
				"equipped": equipped_fashions.has(fashion.type) and equipped_fashions[fashion.type] == fashion_id
			})
	
	return result

# 获取时装修正
func get_fashion_model(fashion_type: int) -> String:
	if equipped_fashions.has(fashion_type):
		var fashion_id = equipped_fashions[fashion_type]
		var fashion = fashion_database.get(fashion_id)
		if fashion != null:
			return fashion.model
	return ""

# 保存/加载
func save_fashions():
	var config = ConfigFile.new()
	config.set_value("fashion", "owned", owned_fashions)
	config.set_value("fashion", "equipped", equipped_fashions)
	config.save("user://fashion.cfg")

func load_fashions():
	if FileAccess.file_exists("user://fashion.cfg"):
		var config = ConfigFile.new()
		if config.load("user://fashion.cfg") == OK:
			owned_fashions = config.get_value("fashion", "owned", [])
			equipped_fashions = config.get_value("fashion", "equipped", {})
