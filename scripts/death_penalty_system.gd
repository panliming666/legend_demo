extends Node

class_name DeathPenaltySystem

# 死亡惩罚系统 - 难度相关

signal player_died(penalty: Dictionary)
signal resurrection()

# 惩罚配置
var penalty_config: Dictionary = {
	"easy": {
		"level_penalty": 0,       # 不掉级
		"gold_penalty": 0.05,      # 掉落5%金币
		"equip_drop_chance": 0,   # 不掉落装备
		"exp_penalty": 0.1,        # 掉落10%经验
		"respawn_time": 3,         # 3秒复活
		"debuff_duration": 0,      # 无debuff
		"can_revoke": true,       # 可撤销
		"revive_cost": 0           # 复活免费
	},
	"normal": {
		"level_penalty": 0,
		"gold_penalty": 0.1,
		"equip_drop_chance": 0.05,
		"exp_penalty": 0.2,
		"respawn_time": 5,
		"debuff_duration": 30,
		"can_revoke": true,
		"revive_cost": 100
	},
	"hard": {
		"level_penalty": 0,
		"gold_penalty": 0.2,
		"equip_drop_chance": 0.1,
		"exp_penalty": 0.3,
		"respawn_time": 10,
		"debuff_duration": 60,
		"can_revoke": true,
		"revive_cost": 500
	},
	"nightmare": {
		"level_penalty": 1,         # 掉1级
		"gold_penalty": 0.3,
		"equip_drop_chance": 0.2,
		"exp_penalty": 0.5,
		"respawn_time": 30,
		"debuff_duration": 120,
		"can_revoke": false,       # 无法撤销
		"revive_cost": 0,
		"permadeath_chance": 0.1  # 10%几率真死
	}
}

# 当前难度
var current_difficulty: String = "normal"

# 死亡次数统计
var death_count: int = 0
var total_exp_lost: int = 0
var total_gold_lost: int = 0

func _ready():
	load_death_data()

# 设置难度
func set_difficulty(difficulty: String):
	if penalty_config.has(difficulty):
		current_difficulty = difficulty

# 玩家死亡处理
func on_player_death(current_level: int, current_exp: int, current_gold: int) -> Dictionary:
	var config = penalty_config.get(current_difficulty, penalty_config.normal)
	
	death_count += 1
	
	# 计算惩罚
	var result: Dictionary = {
		"level_lost": 0,
		"exp_lost": 0,
		"gold_lost": 0,
		"equip_dropped": false,
		"debuff": {},
		"respawn_time": config.respawn_time,
		"permadeath": false
	}
	
	# 经验惩罚
	result.exp_lost = int(current_exp * config.exp_penalty)
	total_exp_lost += result.exp_lost
	
	# 金币惩罚
	result.gold_lost = int(current_gold * config.gold_penalty)
	total_gold_lost += result.gold_lost
	
	# 等级惩罚（仅噩梦难度）
	if config.level_penalty > 0 and current_level > 1:
		result.level_lost = config.level_penalty
	
	# 装备掉落
	if randf() < config.equip_drop_chance:
		result.equip_dropped = true
	
	# Debuff
	if config.debuff_duration > 0:
		result.debuff = {
			"type": "weakness",
			"duration": config.debuff_duration,
			"effect": {"attack": 0.5, "defense": 0.5}
		}
	
	# 噩梦难度真死
	if current_difficulty == "nightmare" and randf() < config.get("permadeath_chance", 0):
		result.permadeath = true
	
	emit_signal("player_died", result)
	save_death_data()
	
	print("死亡惩罚 - 经验:", result.exp_lost, " 金币:", result.gold_lost)
	
	return result

# 复活处理
func on_resurrection() -> Dictionary:
	var config = penalty_config.get(current_difficulty, penalty_config.normal)
	
	emit_signal("resurrection")
	
	return {
		"respawn_time": config.respawn_time,
		"revive_cost": config.revive_cost if config.can_revoke else 0
	}

# 获取死亡统计
func get_death_stats() -> Dictionary:
	return {
		"death_count": death_count,
		"total_exp_lost": total_exp_lost,
		"total_gold_lost": total_gold_lost,
		"current_difficulty": current_difficulty
	}

# 获取当前难度惩罚配置
func get_current_penalty_config() -> Dictionary:
	return penalty_config.get(current_difficulty, penalty_config.normal)

# 重置统计
func reset_stats():
	death_count = 0
	total_exp_lost = 0
	total_gold_lost = 0
	save_death_data()

# 保存/加载
func save_death_data():
	var config = ConfigFile.new()
	config.set_value("death", "count", death_count)
	config.set_value("death", "exp_lost", total_exp_lost)
	config.set_value("death", "gold_lost", total_gold_lost)
	config.save("user://death.cfg")

func load_death_data():
	if FileAccess.file_exists("user://death.cfg"):
		var config = ConfigFile.new()
		if config.load("user://death.cfg") == OK:
			death_count = config.get_value("death", "count", 0)
			total_exp_lost = config.get_value("death", "exp_lost", 0)
			total_gold_lost = config.get_value("death", "gold_lost", 0)
