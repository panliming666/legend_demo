extends Node

class_name NewGamePlusSystem

# 多周目系统 - 单机后期玩法

signal new_game_plus_started(plus_level: int)
signal cycle_completed(cycle: int)

# 周目配置
var ng_plus_config: Dictionary = {
	1: {"name": "二周目", "enemy_scale": 1.5, "drop_rate": 1.5, "new_enemies": false},
	2: {"name": "三周目", "enemy_scale": 2.0, "drop_rate": 2.0, "new_enemies": false},
	3: {"name": "四周目", "enemy_scale": 2.5, "drop_rate": 2.5, "new_enemies": true},
	4: {"name": "五周目", "enemy_scale": 3.0, "drop_rate": 3.0, "new_enemies": true},
	5: {"name": "六周目", "enemy_scale": 3.5, "drop_rate": 3.5, "new_enemies": true},
	6: {"name": "七周目", "enemy_scale": 4.0, "drop_rate": 4.0, "new_enemies": true},
	7: {"name": "八周目", "enemy_scale": 5.0, "drop_rate": 5.0, "new_enemies": true},
	8: {"name": "九周目", "enemy_scale": 6.0, "drop_rate": 6.0, "new_enemies": true},
	9: {"name": "十周目", "enemy_scale": 8.0, "drop_rate": 8.0, "new_enemies": true},
	10: {"name": "化神期", "enemy_scale": 10.0, "drop_rate": 10.0, "new_enemies": true}
}

# 当前周目
var current_ng_plus: int = 0
var ng_plus_unlocked: bool = false
var cycle_count: int = 0  # 完成剧情的次数

# 保留的能力
var preserved_stats: Dictionary = {
	"max_level": 0,
	"skills_unlocked": [],
	"titles_unlocked": [],
	"pets_unlocked": [],
	"mounts_unlocked": []
}

func _ready():
	load_ng_plus_data()

# 开始新周目
func start_new_game_plus() -> Dictionary:
	if not ng_plus_unlocked:
		return {"success": false, "message": "通关剧情后可开启多周目"}
	
	if current_ng_plus >= 10:
		return {"success": false, "message": "已达最高周目"}
	
	current_ng_plus += 1
	cycle_count += 1
	
	emit_signal("new_game_plus_started", current_ng_plus)
	
	var config = ng_plus_config[current_ng_plus]
	
	save_ng_plus_data()
	
	return {
		"success": true,
		"ng_plus": current_ng_plus,
		"name": config.name,
		"enemy_scale": config.enemy_scale,
		"drop_rate": config.drop_rate,
		"new_enemies": config.new_enemies,
		"message": "开启%s！" % config.name
	}

# 获取当前周目加成
func get_ng_plus_bonus() -> Dictionary:
	if current_ng_plus == 0:
		return {}
	
	var config = ng_plus_config[current_ng_plus]
	
	return {
		"enemy_scale": config.enemy_scale,
		"drop_rate": config.drop_rate,
		"new_enemies": config.new_enemies,
		"exp_bonus": 1.0 + (current_ng_plus - 1) * 0.2,
		"gold_bonus": 1.0 + (current_ng_plus - 1) * 0.3
	}

# 解锁多周目
func unlock_ng_plus():
	ng_plus_unlocked = true
	save_ng_plus_data()
	print("多周目已解锁！")

# 检查是否可以开启新周目
func can_start_ng_plus() -> bool:
	return ng_plus_unlocked and current_ng_plus < 10

# 获取周目信息
func get_ng_plus_info() -> Dictionary:
	var config = ng_plus_config.get(current_ng_plus, {})
	
	return {
		"current": current_ng_plus,
		"name": config.get("name", "一周目"),
		"unlocked": ng_plus_unlocked,
		"max_level": 10,
		"cycles_completed": cycle_count,
		"bonus": get_ng_plus_bonus()
	}

# 保存/加载
func save_ng_plus_data():
	var config = ConfigFile.new()
	config.set_value("ng_plus", "current", current_ng_plus)
	config.set_value("ng_plus", "unlocked", ng_plus_unlocked)
	config.set_value("ng_plus", "cycles", cycle_count)
	config.set_value("ng_plus", "preserved", preserved_stats)
	config.save("user://ng_plus.cfg")

func load_ng_plus_data():
	if FileAccess.file_exists("user://ng_plus.cfg"):
		var config = ConfigFile.new()
		if config.load("user://ng_plus.cfg") == OK:
			current_ng_plus = config.get_value("ng_plus", "current", 0)
			ng_plus_unlocked = config.get_value("ng_plus", "unlocked", false)
			cycle_count = config.get_value("ng_plus", "cycles", 0)
			preserved_stats = config.get_value("ng_plus", "preserved", preserved_stats)
