extends Node

class_name GameManager

# 单例实例
static var instance: GameManager

# 游戏状态
var current_level: int = 1
var total_enemies_killed: int = 0
var total_gold_earned: int = 0

# 玩家引用
var player: Node = null

# 游戏配置
var spawn_enemy_count: int = 10
var spawn_interval: float = 5.0

# 场景引用
var enemy_scene = preload("res://scenes/enemy.tscn")

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
	
	print("游戏管理器初始化完成")
	start_game()

func start_game():
	# 查找玩家
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# 开始生成敌人
	start_enemy_spawner()

func start_enemy_spawner():
	while true:
		await get_tree().create_timer(spawn_interval).timeout
		if get_tree().get_nodes_in_group("enemies").size() < spawn_enemy_count:
			spawn_enemy()

func spawn_enemy():
	if enemy_scene == null:
		return
	
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	
	var player = current_scene.get_node_or_null("Player")
	if player == null:
		return
	
	var enemy = enemy_scene.instantiate()
	
	# 在玩家周围随机位置生成
	var random_angle = randf() * PI * 2
	var random_distance = randf_range(300, 500)
	var spawn_pos = player.global_position + Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)
	
	enemy.global_position = spawn_pos
	current_scene.add_child(enemy)
	
	# 根据当前关卡调整敌人等级
	enemy.level = current_level
	enemy.max_hp = 30 + (current_level * 10)
	enemy.current_hp = enemy.max_hp
	enemy.attack = 5 + (current_level * 2)
	enemy.defense = 2 + (current_level)

func on_enemy_killed(enemy_level: int):
	total_enemies_killed += 1
	
	# 计算掉落
	var drops = DropSystem.calculate_drop(enemy_level)
	
	# 给予玩家奖励
	if player:
		if player.has_method("gain_exp"):
			player.gain_exp(drops["exp"])
		
		total_gold_earned += drops["gold"]
		
		if drops["equipment"] != null:
			# 触发掉落UI显示
			show_drop_notification(drops["equipment"])

func show_drop_notification(equipment: Equipment):
	print("获得装备: ", equipment.name)
	print("稀有度: ", equipment.get_rarity_color())
	print("属性: ")
	print(equipment.get_stats_text())

func check_level_progression():
	# 检查是否可以进入下一关
	if total_enemies_killed >= current_level * 20:
		current_level += 1
		spawn_enemy_count += 5
		print("进入第", current_level, "关！")
		print("敌人数量增加到", spawn_enemy_count)
