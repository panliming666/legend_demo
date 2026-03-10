extends Node

class_name SinglePlayerController

# 单机游戏主控制器

signal game_started(mode: String)
signal game_paused()
signal game_resumed()
signal game_saved(slot: int)
signal game_loaded(slot: int)

# 游戏模式
enum GameMode {
	STORY,      # 剧情模式
	ENDLESS,    # 无尽爬塔
	ROGUELIKE,  # Roguelike
	CHALLENGE,  # 挑战模式
	NEW_GAME_PLUS  # 多周目
}

# 子系统引用
var systems: Dictionary = {}

# 当前游戏状态
var current_mode: int = -1
var is_paused: bool = false

# 存档槽位
var save_slots: int = 3

func _ready():
	init_systems()

# 初始化系统
func init_systems():
	# 基础系统
	systems["character"] = CharacterClass.new()
	systems["equipment"] = EquipmentSystem.new()
	systems["skill_tree"] = SkillTreeSystem.new()
	
	# 玩法系统
	systems["story"] = StoryModeSystem.new()
	systems["tower"] = EndlessTowerSystem.new()
	systems["roguelike"] = RoguelikeSystem.new()
	systems["challenge"] = ChallengeModeSystem.new()
	systems["ng_plus"] = NewGamePlusSystem.new()
	
	# 辅助系统
	systems["achievements"] = AchievementSystem.new()
	systems["titles"] = TitleSystem.new()
	systems["pets"] = SpiritPetSystem.new()
	systems["mounts"] = MountSystem.new()
	systems["alchemy"] = AlchemySystem.new()
	systems["refining"] = RefiningSystem.new()
	systems["dungeon"] = DungeonSystem.new()
	systems["offline"] = OfflineRewardSystem.new()
	
	# 添加为子节点
	for key in systems.keys():
		add_child(systems[key])

# 开始剧情模式
func start_story_mode():
	current_mode = GameMode.STORY
	emit_signal("game_started", "story")
	
	# 检查离线奖励
	var offline = systems["offline"].on_player_login()
	if offline.success:
		print("离线奖励：", offline.rewards)
	
	# 开始第一章
	systems["story"].start_chapter("chapter_1")

# 开始无尽爬塔
func start_endless_tower():
	current_mode = GameMode.ENDLESS
	emit_signal("game_started", "endless")
	systems["tower"].enter_tower(1)

# 开始Roguelike
func start_roguelike():
	current_mode = GameMode.ROGUELIKE
	emit_signal("game_started", "roguelike")
	systems["roguelike"].start_new_run()

# 开始挑战模式
func start_challenge(challenge_id: String):
	current_mode = GameMode.CHALLENGE
	emit_signal("game_started", "challenge")
	systems["challenge"].start_challenge(challenge_id)

# 保存游戏
func save_game(slot: int) -> bool:
	if slot < 1 or slot > save_slots:
		return false
	
	var save_data: Dictionary = {
		"mode": current_mode,
		"timestamp": Time.get_unix_time_from_system(),
		"systems": {}
	}
	
	# 收集各系统数据
	for key in systems.keys():
		if systems[key].has_method("save_data"):
			save_data.systems[key] = systems[key].save_data()
	
	# 保存到文件
	var file = FileAccess.open("user://save_%d.sav" % slot, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		
		emit_signal("game_saved", slot)
		print("游戏已保存到槽位", slot)
		return true
	
	return false

# 加载游戏
func load_game(slot: int) -> bool:
	if slot < 1 or slot > save_slots:
		return false
	
	var file_path = "user://save_%d.sav" % slot
	if not FileAccess.file_exists(file_path):
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		# 恢复系统数据
		if save_data.has("systems"):
			for key in save_data.systems.keys():
				if systems.has(key) and systems[key].has_method("load_data"):
					systems[key].load_data(save_data.systems[key])
		
		current_mode = save_data.get("mode", GameMode.STORY)
		
		emit_signal("game_loaded", slot)
		print("游戏已从槽位", slot, "加载")
		return true
	
	return false

# 暂停/恢复
func toggle_pause() -> bool:
	is_paused = not is_paused
	
	if is_paused:
		emit_signal("game_paused")
	else:
		emit_signal("game_resumed")
	
	get_tree().paused = is_paused
	return is_paused

# 获取存档列表
func get_save_slots() -> Array:
	var slots = []
	
	for i in range(1, save_slots + 1):
		var file_path = "user://save_%d.sav" % i
		if FileAccess.file_exists(file_path):
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var data = file.get_var()
				file.close()
				
				slots.append({
					"slot": i,
					"exists": true,
					"timestamp": data.get("timestamp", 0),
					"mode": data.get("mode", 0)
				})
		else:
			slots.append({
				"slot": i,
				"exists": false
			})
	
	return slots

# 获取系统
func get_system(system_name: String) -> Node:
	return systems.get(system_name, null)
