extends Node

class_name TitleSystem

# 称号系统

signal title_unlocked(title_id: String, title_name: String)
signal title_equipped(title_id: String)
signal title_removed()

# 称号类型
enum TitleType {
	NORMAL,    # 普通称号
	RARE,      # 稀有称号
	EPIC,      # 史诗称号
	LEGENDARY, # 传说称号
	MYTHICAL   # 神级称号
}

# 称号数据库
var title_database: Dictionary = {
	# 等级称号
	"title_level_10": {
		"id": "title_level_10",
		"name": "筑基修士",
		"type": TitleType.NORMAL,
		"description": "达到10级获得",
		"condition": {"level": 10},
		"effect": {"exp_gain": 0.05},
		"icon": "⭐"
	},
	"title_level_20": {
		"id": "title_level_20",
		"name": "金丹真人",
		"type": TitleType.RARE,
		"description": "达到20级获得",
		"condition": {"level": 20},
		"effect": {"exp_gain": 0.10, "attack": 10},
		"icon": "⭐⭐"
	},
	"title_level_30": {
		"id": "title_level_30",
		"name": "元婴真君",
		"type": TitleType.EPIC,
		"description": "达到30级获得",
		"condition": {"level": 30},
		"effect": {"exp_gain": 0.15, "attack": 20, "defense": 10},
		"icon": "⭐⭐⭐"
	},
	"title_level_50": {
		"id": "title_level_50",
		"name": "化神真仙",
		"type": TitleType.LEGENDARY,
		"description": "达到50级获得",
		"condition": {"level": 50},
		"effect": {"exp_gain": 0.20, "attack": 50, "defense": 30},
		"icon": "🌟"
	},
	
	# 战斗称号
	"title_kill_100": {
		"id": "title_kill_100",
		"name": "斩妖者",
		"type": TitleType.NORMAL,
		"description": "击杀100只怪物",
		"condition": {"kill_count": 100},
		"effect": {"attack": 5},
		"icon": "⚔️"
	},
	"title_kill_1000": {
		"id": "title_kill_1000",
		"name": "斩妖师",
		"type": TitleType.RARE,
		"description": "击杀1000只怪物",
		"condition": {"kill_count": 1000},
		"effect": {"attack": 15},
		"icon": "⚔️⚔️"
	},
	"title_kill_10000": {
		"id": "title_kill_10000",
		"name": "斩妖大仙",
		"type": TitleType.EPIC,
		"description": "击杀10000只怪物",
		"condition": {"kill_count": 10000},
		"effect": {"attack": 30},
		"icon": "⚔️⚔️⚔️"
	},
	"title_pk_king": {
		"id": "title_pk_king",
		"name": "PK王者",
		"type": TitleType.LEGENDARY,
		"description": "PK榜第一名",
		"condition": {"pk_rank": 1},
		"effect": {"attack": 100, "hp": 500},
		"icon": "👑"
	},
	
	# 财富称号
	"title_rich": {
		"id": "title_rich",
		"name": "富甲一方",
		"type": TitleType.RARE,
		"description": "拥有100000金币",
		"condition": {"gold": 100000},
		"effect": {"gold_drop": 0.10},
		"icon": "💰"
	},
	"title_millionaire": {
		"id": "title_millionaire",
		"name": "富可敌国",
		"type": TitleType.EPIC,
		"description": "拥有1000000金币",
		"condition": {"gold": 1000000},
		"effect": {"gold_drop": 0.20},
		"icon": "💎"
	},
	
	# 秘境称号
	"title_dungeon_clear": {
		"id": "title_dungeon_clear",
		"name": "秘境探索者",
		"type": TitleType.NORMAL,
		"description": "通关所有秘境",
		"condition": {"dungeon_clear_all": true},
		"effect": {"dungeon_exp": 0.10},
		"icon": "🗝️"
	},
	
	# Boss称号
	"title_boss_slayer": {
		"id": "title_boss_slayer",
		"name": "Boss终结者",
		"type": TitleType.EPIC,
		"description": "击杀10只Boss",
		"condition": {"boss_kill": 10},
		"effect": {"boss_damage": 0.10},
		"icon": "👹"
	},
	"title_world_boss": {
		"id": "title_world_boss",
		"name": "世界Boss杀手",
		"type": TitleType.LEGENDARY,
		"description": "击杀世界Boss伤害排名前三",
		"condition": {"world_boss_rank": 3},
		"effect": {"boss_damage": 0.20, "attack": 50},
		"icon": "🐉"
	},
	
	# 行会称号
	"title_guild_leader": {
		"id": "title_guild_leader",
		"name": "宗主",
		"type": TitleType.RARE,
		"description": "成为行会宗主",
		"condition": {"guild_rank": "leader"},
		"effect": {"guild_exp": 0.10},
		"icon": "🏛️"
	},
	
	# 特殊称号
	"title_first_player": {
		"id": "title_first_player",
		"name": "开服元老",
		"type": TitleType.MYTHICAL,
		"description": "开服首日登录",
		"condition": {"first_day_login": true},
		"effect": {"all_stats": 0.05, "exp_gain": 0.10},
		"icon": "🌟🌟"
	},
	"title_perfect": {
		"id": "title_perfect",
		"name": "完美修士",
		"type": TitleType.MYTHICAL,
		"description": "完成所有成就",
		"condition": {"all_achievements": true},
		"effect": {"all_stats": 0.10},
		"icon": "👑👑"
	}
}

# 已解锁称号
var unlocked_titles: Array = []

# 当前佩戴的称号
var current_title: String = ""

func _ready():
	load_titles()

# 检查并解锁称号
func check_title_unlock(condition_type: String, value: int):
	for title_id in title_database.keys():
		var title = title_database[title_id]
		
		if title_id in unlocked_titles:
			continue
		
		var cond = title.condition
		
		for key in cond.keys():
			if key == condition_type:
				var required = cond[key]
				
				if required is int and value >= required:
					unlock_title(title_id)
					break
				elif required is bool and value:
					unlock_title(title_id)
					break

# 解锁称号
func unlock_title(title_id: String) -> bool:
	var title = title_database.get(title_id)
	if title == null:
		return false
	
	if title_id in unlocked_titles:
		return false
	
	unlocked_titles.append(title_id)
	
	emit_signal("title_unlocked", title_id, title.name)
	save_titles()
	
	print("解锁称号：", title.name)
	return true

# 佩戴称号
func equip_title(title_id: String) -> bool:
	var title = title_database.get(title_id)
	if title == null:
		return false
	
	if not title_id in unlocked_titles:
		return false
	
	current_title = title_id
	
	emit_signal("title_equipped", title_id)
	save_titles()
	
	print("佩戴称号：", title.name)
	return true

# 取消佩戴
func remove_title():
	if current_title.is_empty():
		return
	
	current_title = ""
	emit_signal("title_removed")
	save_titles()

# 获取称号效果
func get_title_effect() -> Dictionary:
	if current_title.is_empty():
		return {}
	
	var title = title_database.get(current_title)
	if title == null:
		return {}
	
	return title.effect.duplicate()

# 获取称号信息
func get_title_info(title_id: String) -> Dictionary:
	var title = title_database.get(title_id)
	if title == null:
		return {}
	
	return {
		"id": title_id,
		"name": title.name,
		"type": title.type,
		"description": title.description,
		"condition": title.condition,
		"effect": title.effect,
		"icon": title.icon,
		"unlocked": title_id in unlocked_titles,
		"equipped": current_title == title_id
	}

# 获取所有称号
func get_all_titles() -> Array:
	var result = []
	
	for title_id in title_database.keys():
		result.append(get_title_info(title_id))
	
	return result

# 获取已解锁称号
func get_unlocked_titles() -> Array:
	var result = []
	
	for title_id in unlocked_titles:
		result.append(get_title_info(title_id))
	
	return result

# 获取当前称号信息
func get_current_title() -> Dictionary:
	if current_title.is_empty():
		return {"name": "无称号", "effect": {}}
	
	return get_title_info(current_title)

# 保存/加载
func save_titles():
	var config = ConfigFile.new()
	config.set_value("titles", "unlocked", unlocked_titles)
	config.set_value("titles", "current", current_title)
	config.save("user://titles.cfg")

func load_titles():
	if FileAccess.file_exists("user://titles.cfg"):
		var config = ConfigFile.new()
		if config.load("user://titles.cfg") == OK:
			unlocked_titles = config.get_value("titles", "unlocked", [])
			current_title = config.get_value("titles", "current", "")
