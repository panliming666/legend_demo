extends Node2D

# 三清问道 - 主场景
# 游戏入口，管理场景切换

@onready var ui: CanvasLayer = $UI
@onready var player: CharacterBody2D = $Player
@onready var enemies: Node = $Enemies
@onready var drops: Node = $Drops

var current_scene: String = "main_menu"

func _ready():
	print("=== 三清问道 ===")
	print("混沌初开，天地鸿蒙...")
	
	# 初始化游戏
	_init_game()
	
	# 连接信号
	_connect_signals()

func _init_game():
	# 加载存档
	if SaveManager:
		SaveManager.load_game()
	
	# 初始化音效
	if SoundManager:
		SoundManager.play_bgm("main_theme")

func _connect_signals():
	# 连接GameManager信号
	if GameManager:
		GameManager.level_up.connect(_on_level_up)
		GameManager.game_over.connect(_on_game_over)
		GameManager.player_died.connect(_on_player_died)

func _on_level_up(new_level: int):
	print("升级！当前等级：", new_level)
	# 播放升级特效
	_play_level_up_effect()

func _on_game_over():
	print("游戏结束")
	# 切换到结束场景
	_switch_scene("game_over")

func _on_player_died():
	print("玩家死亡")
	# 显示复活界面
	_show_revive_ui()

func _play_level_up_effect():
	# 升级特效
	pass

func _switch_scene(scene_name: String):
	current_scene = scene_name
	# 场景切换逻辑
	pass

func _show_revive_ui():
	# 显示复活界面
	pass

func _process(delta):
	# 每帧更新
	pass

func _input(event):
	# 输入处理
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause():
	get_tree().paused = not get_tree().paused
	print("游戏暂停：", get_tree().paused)
