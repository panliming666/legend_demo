extends Node

class_name LevelManager

# 关卡系统 - 管理地图和关卡进度

# 关卡数据
var levels: Array = [
	{
		"name": "新手森林",
		"id": 1,
		"description": "最初的冒险之地",
		"enemy_level": 1,
		"enemy_count": 3,
		"boss": false,
		"bg_color": Color(0.2, 0.4, 0.2)
	},
	{
		"name": "哥布林洞穴",
		"id": 2,
		"description": "哥布林们的巢穴",
		"enemy_level": 3,
		"enemy_count": 5,
		"boss": false,
		"bg_color": Color(0.3, 0.25, 0.2)
	},
	{
		"name": "亡者墓地",
		"id": 3,
		"description": "不死族游荡的荒地",
		"enemy_level": 5,
		"enemy_count": 6,
		"boss": false,
		"bg_color": Color(0.25, 0.25, 0.3)
	},
	{
		"name": "龙之巢穴",
		"id": 4,
		"description": "巨龙沉睡的地方",
		"enemy_level": 8,
		"enemy_count": 8,
		"boss": true,
		"boss_name": "远古红龙",
		"boss_hp": 500,
		"boss_attack": 30,
		"bg_color": Color(0.4, 0.2, 0.2)
	},
	{
		"name": "恶魔城",
		"id": 5,
		"description": "最终决战之地",
		"enemy_level": 10,
		"enemy_count": 10,
		"boss": true,
		"boss_name": "恶魔领主",
		"boss_hp": 1000,
		"boss_attack": 50,
		"bg_color": Color(0.3, 0.1, 0.4)
	}
]

var current_level_index: int = 0
var is_level_completed: bool = false
var player_required_level: Dictionary = {
	1: 1,
	2: 3,
	3: 5,
	4: 8,
	5: 10
}

func _ready():
	load_level_progress()

func get_current_level() -> Dictionary:
	if current_level_index < levels.size():
		return levels[current_level_index]
	return {}

func get_next_level() -> Dictionary:
	if current_level_index + 1 < levels.size():
		return levels[current_level_index + 1]
	return {}

func can_access_level(level_index: int) -> bool:
	if level_index < 1 or level_index > levels.size():
		return false
	return player_required_level.get(level_index, 99) <= get_current_player_level()

func get_current_player_level() -> int:
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and "level" in player:
		return player.level
	return 1

func enter_level(level_index: int) -> bool:
	if not can_access_level(level_index):
		print("无法进入该关卡，等级不足")
		return false
	
	if level_index < 1 or level_index > levels.size():
		return false
	
	current_level_index = level_index - 1
	is_level_completed = false
	
	# 设置场景背景色
	_apply_level_visual()
	
	# 生成关卡敌人
	_generate_level_enemies()
	
	print("进入关卡：", get_current_level().name)
	return true

func next_level() -> bool:
	var next = get_next_level()
	if next.is_empty():
		print("已完成所有关卡！")
		return false
	
	return enter_level(current_level_index + 2)

func complete_level():
	is_level_completed = true
	save_level_progress()
	print("关卡完成：", get_current_level().name)

func _apply_level_visual():
	var level = get_current_level()
	if level.is_empty():
		return
	
	var env = get_tree().current_scene.get_node_or_null("WorldEnvironment")
	if env and env.environment:
		env.environment.background_color = level.get("bg_color", Color(0.1, 0.15, 0.25))
		env.environment.fog_color = level.get("bg_color", Color(0.1, 0.15, 0.25))

func _generate_level_enemies():
	var level = get_current_level()
	if level.is_empty():
		return
	
	var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
	if game_manager and game_manager.has_method("set_level_params"):
		game_manager.set_level_params(level.get("enemy_level", 1), level.get("enemy_count", 3))

func save_level_progress():
	var save_data = {
		"current_level": current_level_index + 1,
		"completed_levels": []
	}
	
	# 保存已完成的关卡
	for i in range(current_level_index):
		save_data.completed_levels.append(i + 1)
	
	if is_level_completed:
		save_data.completed_levels.append(current_level_index + 1)
	
	# 实际保存需要通过SaveManager
	var save_manager = get_tree().current_scene.get_node_or_null("SaveManager")
	if save_manager:
		save_manager.save_game(save_data)

func load_level_progress():
	# 从存档加载关卡进度
	if SaveManager:
		var save_data = SaveManager.load_game()
		if save_data.has("world") and save_data.world.has("current_level"):
			current_level = save_data.world.current_level
			print("加载关卡进度: ", current_level)
			return true
	return false

func get_level_name(level_index: int) -> String:
	if level_index >= 1 and level_index <= levels.size():
		return levels[level_index - 1].name
	return "未知"

func get_level_description(level_index: int) -> String:
	if level_index >= 1 and level_index <= levels.size():
		return levels[level_index - 1].description
	return ""

func is_boss_level(level_index: int) -> bool:
	if level_index >= 1 and level_index <= levels.size():
		return levels[level_index - 1].get("boss", false)
	return false
