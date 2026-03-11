extends Node2D

# 三清问道 - 主场景
# 游戏入口，管理场景切换

@onready var ui: CanvasLayer = $UI
@onready var player: CharacterBody2D = $Player
@onready var enemies: Node = $Enemies
@onready var drops: Node = $Drops

var current_scene: String = "main_menu"
var is_paused: bool = false
var game_time: float = 0.0

func _ready():
	print("=== 三清问道 ===")
	print("混沌初开，天地鸿蒙...")
	
	# 初始化游戏
	_init_game()
	
	# 连接信号
	_connect_signals()
	
	# 显示主菜单
	_show_main_menu()

func _init_game():
	# 加载存档
	if SaveManager:
		var save_data = SaveManager.load_game()
		if not save_data.is_empty() and player:
			SaveManager.load_to_player(player)
			print("加载存档成功")
	
	# 初始化音效
	if SoundManager:
		SoundManager.play_bgm("main_theme")

func _connect_signals():
	# 连接 GameManager 信号
	if GameManager:
		GameManager.level_up.connect(_on_level_up)
		GameManager.game_over.connect(_on_game_over)
		GameManager.player_died.connect(_on_player_died)
	
	# 连接玩家信号
	if player:
		player.level_up.connect(_on_player_level_up)
		player.player_died.connect(_on_player_died)
		player.hp_changed.connect(_on_hp_changed)

func _show_main_menu():
	print("显示主菜单...")
	current_scene = "main_menu"

func _on_level_up(new_level: int):
	print("升级！当前等级：", new_level)
	_play_level_up_effect()
	if SoundManager:
		SoundManager.play_sound("level_up")

func _on_player_level_up(new_level: int):
	print("玩家升级到: ", new_level)
	_play_level_up_effect()
	if SoundManager:
		SoundManager.play_sound("level_up")

func _on_game_over():
	print("游戏结束")
	current_scene = "game_over"
	_show_game_over_ui()

func _on_player_died():
	print("玩家死亡")
	current_scene = "player_died"
	_show_revive_ui()
	if SoundManager:
		SoundManager.play_sound("death")

func _on_hp_changed(current: int, max_hp: int):
	# 更新 UI 血条
	pass

func _play_level_up_effect():
	# 升级特效 - 可以添加粒子效果
	print("播放升级特效")

func _show_game_over_ui():
	print("显示游戏结束界面")

func _show_revive_ui():
	print("显示复活界面")
	# 可以添加倒计时复活逻辑

func _switch_scene(scene_name: String):
	current_scene = scene_name
	print("切换场景: ", scene_name)

func _process(delta):
	if not is_paused:
		game_time += delta
	
	# 更新游戏时间显示
	_update_game_time(delta)

func _update_game_time(delta):
	# 游戏时间更新逻辑
	pass

func _input(event):
	# 暂停游戏
	if event.is_action_pressed("pause"):
		_toggle_pause()
	
	# 快捷键
	if event.is_action_pressed("ui_cancel"):
		if current_scene == "playing":
			_toggle_pause()
		elif is_paused:
			_resume_game()

func _toggle_pause():
	is_paused = not is_paused
	get_tree().paused = is_paused
	print("游戏暂停：", is_paused)

func _resume_game():
	is_paused = false
	get_tree().paused = false
	print("游戏继续")

func start_new_game():
	print("开始新游戏")
	current_scene = "playing"
	
	# 重置玩家状态
	if player:
		player.current_hp = player.max_hp
		player.current_mp = player.max_mp
		player.current_exp = 0
		player.level = 1
		player.gold = 0
	
	# 重置游戏状态
	game_time = 0.0
	
	if SoundManager:
		SoundManager.play_bgm("gameplay")

func load_game():
	print("加载存档")
	current_scene = "playing"

func save_game():
	print("保存游戏")
	if player and SaveManager:
		SaveManager.auto_save(player)

func quit_game():
	print("退出游戏")
	get_tree().quit()
