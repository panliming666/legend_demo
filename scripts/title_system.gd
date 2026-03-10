extends Node

class_name TitleSystem

# 称号系统

signal title_equipped(title_id: String)
signal title_unequipped()

# 称号类型
enum TitleType {
	ACHIEVEMENT,  # 成就称号
	RANKING,      # 排行称号
	ACTIVITY,     # 活动称号
	GUILD,        # 行会称号
	VIP,          # VIP称号
	SPECIAL       # 特殊称号
}

# 称号稀有度
enum TitleRarity {
	COMMON,       # 普通
	RARE,         # 稀有
	EPIC,         # 史诗
	LEGENDARY,    # 传说
	MYTHICAL      # 神话
}

# 称号数据库
var title_database: Dictionary = {
	# 成就称号
	"title_achieve_1": {
		"name": "初出茅庐",
		"type": TitleType.ACHIEVEMENT,
		"rarity": TitleRarity.COMMON,
		"description": "达到10级的成就称号",
		"effect": {"all_attack": 5},
		"condition": "达到10级"
	},
	"title_achieve_2": {
		"name": "修仙有成",
		"type": TitleType.ACHIEVEMENT,
		"rarity": TitleRarity.RARE,
		"description": "达到30级的成就称号",
		"effect": {"all_attack": 15, "all_defense": 10},
		"condition": "达到30级"
	},
	"title_achieve_3": {
		"name": "元婴真君",
		"type": TitleType.ACHIEVEMENT,
		"rarity": TitleRarity.EPIC,
		"description": "达到50级的成就称号",
		"effect": {"all_attack": 30, "all_defense": 20, "max_hp": 200},
		"condition": "达到50级"
	},
	
	# 排行称号
	"title_rank_1": {
		"name": "天下第一",
		"type": TitleType.RANKING,
		"rarity": TitleRarity.LEGENDARY,
		"description": "战力榜第一名",
		"effect": {"all_attack": 50, "all_defense": 30, "charm": 100},
		"condition": "战力榜第一"
	},
	"title_rank_2": {
		"name": "等级至尊",
		"type": TitleType.RANKING,
		"rarity": TitleRarity.LEGENDARY,
		"description": "等级榜第一名",
		"effect": {"max_hp": 500, "max_mp": 200, "charm": 100},
		"condition": "等级榜第一"
	},
	
	# 活动称号
	"title_event_1": {
		"name": "首充大佬",
		"type": TitleType.ACTIVITY,
		"rarity": TitleRarity.EPIC,
		"description": "完成首充活动的称号",
		"effect": {"gold_drop": 0.1},
		"condition": "完成首充"
	},
	
	# 行会称号
	"title_guild_1": {
		"name": "行会长老",
		"type": TitleType.GUILD,
		"rarity": TitleRarity.RARE,
		"description": "成为行会长老",
		"effect": {"guild_bonus": 0.1},
		"condition": "担任行会长老"
	},
	"title_guild_2": {
		"name": "行会会长",
		"type": TitleType.GUILD,
		"rarity": TitleRarity.EPIC,
		"description": "成为行会会长",
		"effect": {"guild_bonus": 0.2, "all_attack": 10},
		"condition": "担任行会会长"
	},
	
	# 特殊称号
	"title_special_1": {
		"name": "幸运儿",
		"type": TitleType.SPECIAL,
		"rarity": TitleRarity.RARE,
		"description": "幸运的称号",
		"effect": {"lucky": 5},
		"condition": "特殊获得"
	}
}

# 玩家拥有的称号
var owned_titles: Array = []
var equipped_title: String = ""

func _ready():
	load_titles()

# 获得称号
func obtain_title(title_id: String) -> bool:
	var title = title_database.get(title_id)
	if title == null:
		return false
	
	if title_id in owned_titles:
		return false
	
	owned_titles.append(title_id)
	save_titles()
	
	print("获得称号：", title.name)
	return true

# 装备称号
func equip_title(title_id: String) -> bool:
	var title = title_database.get(title_id)
	if title == null:
		return false
	
	if not title_id in owned_titles:
		return false
	
	# 卸下当前称号
	if equipped_title != "":
		unequip_title()
	
	equipped_title = title_id
	
	emit_signal("title_equipped", title_id)
	save_titles()
	
	print("装备称号：", title.name)
	return true

# 卸下称号
func unequip_title() -> bool:
	if equipped_title == "":
		return false
	
	equipped_title = ""
	
	emit_signal("title_unequipped")
	save_titles()
	
	return true

# 获取称号属性加成
func get_title_bonus() -> Dictionary:
	if equipped_title == "":
		return {}
	
	var title = title_database.get(equipped_title)
	if title == null:
		return {}
	
	return title.effect.duplicate()

# 获取装备的称号
func get_equipped_title() -> Dictionary:
	if equipped_title == "":
		return {}
	
	var title = title_database.get(equipped_title)
	if title == null:
		return {}
	
	return {
		"id": equipped_title,
		"name": title.name,
		"type": title.type,
		"rarity": title.rarity,
		"description": title.description,
		"effect": title.effect
	}

# 获取拥有的称号列表
func get_owned_titles() -> Array:
	var result = []
	
	for title_id in owned_titles:
		var title = title_database.get(title_id)
		if title != null:
			result.append({
				"id": title_id,
				"name": title.name,
				"type": title.type,
				"rarity": title.rarity,
				"description": title.description,
				"effect": title.effect,
				"condition": title.condition,
				"equipped": equipped_title == title_id
			})
	
	return result

# 保存/加载
func save_titles():
	var config = ConfigFile.new()
	config.set_value("titles", "owned", owned_titles)
	config.set_value("titles", "equipped", equipped_title)
	config.save("user://titles.cfg")

func load_titles():
	if FileAccess.file_exists("user://titles.cfg"):
		var config = ConfigFile.new()
		if config.load("user://titles.cfg") == OK:
			owned_titles = config.get_value("titles", "owned", [])
			equipped_title = config.get_value("titles", "equipped", "")
