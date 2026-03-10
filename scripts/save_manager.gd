extends Node

class_name SaveManager

# 存档系统 - 保存和加载游戏进度

const SAVE_PATH = "user://savegame.save"
const SETTINGS_PATH = "user://settings.cfg"

var current_save: Dictionary = {}

func _ready():
	load_game()

func save_game(player_data: Dictionary, world_data: Dictionary = {}):
	current_save = {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"player": player_data,
		"world": world_data
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(current_save)
		file.store_string(json_string)
		file.close()
		print("游戏已保存")
		return true
	else:
		print("保存失败：无法写入文件")
		return false

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		print("没有找到存档")
		return {}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			current_save = json.data
			print("存档已加载")
			return current_save
		else:
			print("存档解析失败")
			return {}
	else:
		print("无法读取存档")
		return {}

func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		current_save = {}
		print("存档已删除")
		return true
	return false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_player_data() -> Dictionary:
	return current_save.get("player", {})

func get_world_data() -> Dictionary:
	return current_save.get("world", {})

func save_settings(settings: Dictionary):
	var config = ConfigFile.new()
	
	for section in settings.keys():
		for key in settings[section].keys():
			config.set_value(section, key, settings[section][key])
	
	config.save(SETTINGS_PATH)

func load_settings() -> Dictionary:
	var config = ConfigFile.new()
	var settings = {}
	
	if config.load(SETTINGS_PATH) == OK:
		for section in config.get_sections():
			settings[section] = {}
			for key in config.get_section_keys(section):
				settings[section][key] = config.get_value(section, key)
	
	return settings

# 自动存档
func auto_save(player: Node):
	if player == null:
		return
	
	var player_data = {
		"hp": player.current_hp,
		"max_hp": player.max_hp,
		"mp": player.current_mp,
		"max_mp": player.max_mp,
		"level": player.level,
		"exp": player.exp,
		"attack": player.attack if "attack" in player else 0,
		"defense": player.defense,
		"position": {
			"x": player.global_position.x,
			"y": player.global_position.y
		}
	}
	
	save_game(player_data)

# 加载到玩家
func load_to_player(player: Node):
	if player == null:
		return
	
	var data = get_player_data()
	if data.is_empty():
		return
	
	player.current_hp = data.get("hp", player.max_hp)
	player.max_hp = data.get("max_hp", player.max_hp)
	player.current_mp = data.get("mp", player.max_mp)
	player.max_mp = data.get("max_mp", player.max_mp)
	player.level = data.get("level", 1)
	player.exp = data.get("exp", 0)
	player.defense = data.get("defense", player.defense)
	
	if "attack" in player and data.has("attack"):
		player.attack = data["attack"]
	
	# 恢复位置
	if data.has("position"):
		player.global_position = Vector2(data.position.x, data.position.y)
