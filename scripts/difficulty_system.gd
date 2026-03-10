extends Node

class_name DifficultySystem

# 难度选择系统 - 单机体验

signal difficulty_changed(new_difficulty: int)

# 难度等级
enum DifficultyLevel {
	EASY,       # 简单 - 休闲玩家
	NORMAL,     # 普通 - 标准体验
	HARD,       # 困难 - 硬核玩家
	NIGHTMARE,  # 噩梦 - 抖M玩家
	HARDCORE    # 极限 - 真正的勇者
}

# 难度配置
var difficulty_config: Dictionary = {
	DifficultyLevel.EASY: {
		"name": "简单",
		"description": "适合休闲玩家，享受剧情",
		"enemy_hp": 0.5,        # 敌人血量50%
		"enemy_attack": 0.6,    # 敌人攻击60%
		"drop_rate": 1.5,       # 掉落率150%
		"exp_rate": 1.2,        # 经验120%
		"auto_save": true,      # 自动保存
		"no_permadeath": true,  # 无永久死亡
		"show_tips": true,      # 显示提示
		"recommended_for": "休闲玩家、剧情爱好者"
	},
	DifficultyLevel.NORMAL: {
		"name": "普通",
		"description": "标准游戏体验",
		"enemy_hp": 1.0,
		"enemy_attack": 1.0,
		"drop_rate": 1.0,
		"exp_rate": 1.0,
		"auto_save": true,
		"no_permadeath": true,
		"show_tips": false,
		"recommended_for": "大多数玩家"
	},
	DifficultyLevel.HARD: {
		"name": "困难",
		"description": "更具挑战性的体验",
		"enemy_hp": 1.5,
		"enemy_attack": 1.3,
		"drop_rate": 1.3,
		"exp_rate": 1.5,
		"auto_save": false,
		"no_permadeath": true,
		"show_tips": false,
		"recommended_for": "有一定基础的玩家"
	},
	DifficultyLevel.NIGHTMARE: {
		"name": "噩梦",
		"description": "极其困难的挑战",
		"enemy_hp": 2.0,
		"enemy_attack": 1.8,
		"drop_rate": 2.0,
		"exp_rate": 2.5,
		"auto_save": false,
		"no_permadeath": false,  # 允许永久死亡
		"show_tips": false,
		"extra_enemies": true,    # 额外敌人
		"recommended_for": "硬核玩家"
	},
	DifficultyLevel.HARDCORE: {
		"name": "极限",
		"description": "地狱难度，存活即胜利",
		"enemy_hp": 3.0,
		"enemy_attack": 2.5,
		"drop_rate": 3.0,
		"exp_rate": 4.0,
		"auto_save": false,
		"no_permadeath": true,  # 死亡后保留部分装备
		"show_tips": false,
		"extra_enemies": true,
		"random_events": true,   # 随机事件
		"recommended_for": "真正的勇者"
	}
}

var current_difficulty: int = DifficultyLevel.NORMAL

func _ready():
	load_difficulty()

# 设置难度
func set_difficulty(difficulty: int) -> bool:
	if not difficulty_config.has(difficulty):
		return false
	
	current_difficulty = difficulty
	emit_signal("difficulty_changed", difficulty)
	save_difficulty()
	
	print("难度设置为：", difficulty_config[difficulty].name)
	return true

# 获取当前难度配置
func get_current_config() -> Dictionary:
	return difficulty_config.get(current_difficulty, {})

# 获取难度名称
func get_difficulty_name() -> String:
	return difficulty_config.get(current_difficulty, {}).get("name", "未知")

# 计算敌人属性
func calculate_enemy_stats(base_hp: int, base_attack: int) -> Dictionary:
	var config = get_current_config()
	
	return {
		"hp": int(base_hp * config.get("enemy_hp", 1.0)),
		"attack": int(base_attack * config.get("enemy_attack", 1.0))
	}

# 计算掉落率
func calculate_drop_rate(base_rate: float) -> float:
	return base_rate * get_current_config().get("drop_rate", 1.0)

# 计算经验
func calculate_exp(base_exp: int) -> int:
	return int(base_exp * get_current_config().get("exp_rate", 1.0))

# 是否启用额外敌人
func has_extra_enemies() -> bool:
	return get_current_config().get("extra_enemies", false)

# 是否允许永久死亡
func allows_permadeath() -> bool:
	return not get_current_config().get("no_permadeath", true)

# 获取所有难度信息
func get_all_difficulties() -> Array:
	var result = []
	
	for level in difficulty_config.keys():
		var config = difficulty_config[level]
		result.append({
			"level": level,
			"name": config.name,
			"description": config.description,
			"enemy_hp": config.enemy_hp,
			"enemy_attack": config.enemy_attack,
			"drop_rate": config.drop_rate,
			"exp_rate": config.exp_rate,
			"recommended": config.recommended_for,
			"selected": level == current_difficulty
		})
	
	return result

# 保存/加载
func save_difficulty():
	var config = ConfigFile.new()
	config.set_value("difficulty", "level", current_difficulty)
	config.save("user://difficulty.cfg")

func load_difficulty():
	if FileAccess.file_exists("user://difficulty.cfg"):
		var config = ConfigFile.new()
		if config.load("user://difficulty.cfg") == OK:
			current_difficulty = config.get_value("difficulty", "level", DifficultyLevel.NORMAL)
