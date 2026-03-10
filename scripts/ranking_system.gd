extends Node

class_name RankingSystem

# 排行榜系统

signal ranking_updated(ranking_type: String)

# 排行榜类型
enum RankingType {
	LEVEL,          # 等级榜
	COMBAT,         # 战力榜
	WEALTH,         # 财富榜
	PK,             # PK榜
	DUNGEON,        # 副本通关榜
	MOUNT,          # 坐骑榜
	PET,            # 灵宠榜
	GUILD           # 行会榜
}

var rankings: Dictionary = {
	RankingType.LEVEL: [],
	RankingType.COMBAT: [],
	RankingType.WEALTH: [],
	RankingType.PK: [],
	RankingType.DUNGEON: [],
	RankingType.MOUNT: [],
	RankingType.PET: [],
	RankingType.GUILD: []
}

# 更新排行榜
func update_ranking(ranking_type: int, player_id: String, player_name: String, value: int):
	var ranking = rankings[ranking_type]
	
	# 查找玩家
	var found = false
	for entry in ranking:
		if entry.player_id == player_id:
			entry.value = value
			entry.player_name = player_name
			found = true
			break
	
	# 新玩家
	if not found:
		ranking.append({
			"player_id": player_id,
			"player_name": player_name,
			"value": value,
			"last_update": Time.get_unix_time_from_system()
		})
	
	# 排序
	ranking.sort_custom(func(a, b): return a.value > b.value)
	
	# 只保留前100名
	if ranking.size() > 100:
		ranking.resize(100)
	
	emit_signal("ranking_updated", RankingType.keys()[ranking_type])
	save_rankings()

# 获取排行榜
func get_ranking(ranking_type: int, start: int = 0, count: int = 10) -> Array:
	var ranking = rankings.get(ranking_type, [])
	return ranking.slice(start, start + count)

# 获取玩家排名
func get_player_rank(ranking_type: int, player_id: String) -> int:
	var ranking = rankings.get(ranking_type, [])
	for i in range(ranking.size()):
		if ranking[i].player_id == player_id:
			return i + 1
	return 0

# 获取玩家信息
func get_player_info(ranking_type: int, player_id: String) -> Dictionary:
	var ranking = rankings.get(ranking_type, [])
	for entry in ranking:
		if entry.player_id == player_id:
			return entry
	return {}

# 等级榜更新
func update_level_ranking(player_id: String, player_name: String, level: int):
	update_ranking(RankingType.LEVEL, player_id, player_name, level)

# 战力榜更新
func update_combat_ranking(player_id: String, player_name: String, combat_power: int):
	update_ranking(RankingType.COMBAT, player_id, player_name, combat_power)

# 财富榜更新
func update_wealth_ranking(player_id: String, player_name: String, gold: int):
	update_ranking(RankingType.WEALTH, player_id, player_name, gold)

# PK榜更新
func update_pk_ranking(player_id: String, player_name: String, pk_points: int):
	update_ranking(RankingType.PK, player_id, player_name, pk_points)

# 副本榜更新
func update_dungeon_ranking(player_id: String, player_name: String, dungeon_clears: int):
	update_ranking(RankingType.DUNGEON, player_id, player_name, dungeon_clears)

# 计算战力
func calculate_combat_power(player_data: Dictionary) -> int:
	var cp = 0
	
	# 基础属性
	cp += player_data.get("level", 1) * 10
	cp += player_data.get("attack", 0) * 2
	cp += player_data.get("defense", 0)
	cp += player_data.get("hp", 0) / 10
	cp += player_data.get("crit_rate", 0) * 5
	cp += player_data.get("crit_damage", 0) * 3
	
	# 装备加成
	if player_data.has("equipment"):
		for slot in player_data.equipment.keys():
			var item = player_data.equipment[slot]
			if item != null:
				cp += item.get("attack", 0) * 3
				cp += item.get("defense", 0) * 2
	
	# 灵宠加成
	if player_data.has("pets"):
		cp += player_data.pets.size() * 50
	
	# 坐骑加成
	if player_data.has("mounts"):
		cp += player_data.mounts.size() * 30
	
	return cp

# 保存/加载
func save_rankings():
	var config = ConfigFile.new()
	for rt in rankings.keys():
		config.set_value("ranking", RankingType.keys()[rt], rankings[rt])
	config.save("user://rankings.cfg")

func load_rankings():
	if FileAccess.file_exists("user://rankings.cfg"):
		var config = ConfigFile.new()
		if config.load("user://rankings.cfg") == OK:
			for rt in RankingType.keys():
				if config.has_section_key("ranking", rt):
					rankings[RankingType[rt]] = config.get_value("ranking", rt, [])
