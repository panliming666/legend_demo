extends CharacterBody2D

class_name Enemy

## 敌人系统 - 支持多种类型和行为

# ============ 信号 ============
signal enemy_died(enemy)
signal enemy_damaged(damage, attacker)

# ============ 基础属性 ============
var max_hp: int = 30
var current_hp: int = 30
var level: int = 1
var enemy_type: String = "slime"  # 敌人类型

# 战斗属性
var attack: int = 5
var defense: int = 2
var attack_speed: float = 1.0  # 攻击间隔(秒)
var move_speed: float = 50.0

# 掉落奖励
var exp_drop: int = 10
var gold_drop: int = 5

# 移动参数
var chase_speed: float = 100.0
var patrol_speed: float = 50.0

# AI参数
var detection_range: float = 200.0
var attack_range: float = 50.0
var retreat_hp_percent: float = 0.2  # 血量低于20%时逃跑
var is_retreating: bool = false

# 状态
var is_chasing: bool = false
var is_attacking: bool = false
var is_dead: bool = false

# AI状态机
enum AIState {
	IDLE,       # 待机
	PATROL,     # 巡逻
	CHASE,      # 追逐
	ATTACK,     # 攻击
	RETREAT,    # 逃跑
	DEAD        # 死亡
}
var current_state: AIState = AIState.IDLE

# 巡逻路径
var patrol_points: Array = []
var current_patrol_index: int = 0

# 引用
var color_rect: ColorRect
var player: Node = null

# 战斗冷却
var attack_cooldown: float = 0.0
var last_attack_time: float = 0.0

# 仇恨系统
var hate_list: Dictionary = {}  # player_id: hate_value
var current_target: Node = null

# ============ 初始化 ============
func _ready():
	add_to_group("enemies")
	
	# 获取颜色矩形引用
	color_rect = $ColorRect if has_node("ColorRect") else null
	
	# 设置初始状态
	current_state = AIState.IDLE
	
	# 查找玩家
	_update_player_reference()
	
	# 根据敌人类型设置属性
	_setup_by_type()

func _setup_by_type():
	match enemy_type:
		"slime":
			max_hp = 20 + level * 5
			attack = 3 + level
			defense = 1
			attack_speed = 1.5
			detection_range = 150.0
			attack_range = 30.0
			exp_drop = 5 + level * 2
			gold_drop = 2 + level
			chase_speed = 80.0
			_change_color(Color(0.3, 0.7, 0.3))  # 绿色
		
		"goblin":
			max_hp = 30 + level * 8
			attack = 5 + level * 2
			defense = 2
			attack_speed = 1.2
			detection_range = 250.0
			attack_range = 40.0
			exp_drop = 10 + level * 3
			gold_drop = 5 + level * 2
			chase_speed = 120.0
			_change_color(Color(0.5, 0.4, 0.3))  # 棕色
		
		"skeleton":
			max_hp = 50 + level * 10
			attack = 8 + level * 2
			defense = 5
			attack_speed = 1.0
			detection_range = 300.0
			attack_range = 50.0
			exp_drop = 15 + level * 5
			gold_drop = 10 + level * 3
			chase_speed = 100.0
			_change_color(Color(0.9, 0.9, 0.85))  # 白色
		
		"boss":
			max_hp = 200 + level * 50
			attack = 15 + level * 5
			defense = 10
			attack_speed = 2.0
			detection_range = 400.0
			attack_range = 80.0
			exp_drop = 100 + level * 20
			gold_drop = 50 + level * 10
			chase_speed = 60.0
			retreat_hp_percent = 0.1
			_change_color(Color(0.8, 0.2, 0.2))  # 红色
	
	current_hp = max_hp

func _change_color(color: Color):
	if color_rect:
		color_rect.color = color

func _update_player_reference():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# ============ 主循环 ============
func _physics_process(delta):
	if is_dead:
		return
	
	# 更新玩家引用
	_update_player_reference()
	
	# 更新冷却
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# 状态机
	match current_state:
		AIState.IDLE:
			_do_idle_state(delta)
		AIState.PATROL:
			_do_patrol_state(delta)
		AIState.CHASE:
			_do_chase_state(delta)
		AIState.ATTACK:
			_do_attack_state(delta)
		AIState.RETREAT:
			_do_retreat_state(delta)
	
	# 应用移动
	if velocity.length() > 0:
		move_and_slide()

# ============ AI状态行为 ============
func _do_idle_state(delta):
	# 待机一段时间后开始巡逻
	if randf() < 0.02:
		current_state = AIState.PATROL
		_pick_patrol_point()
	
	# 检测到玩家则追逐
	if player and _get_distance_to_player() < detection_range:
		current_state = AIState.CHASE

func _do_patrol_state(delta):
	# 巡逻移动
	if patrol_points.size() > 0:
		var target = patrol_points[current_patrol_index]
		var direction = (target - global_position).normalized()
		velocity = direction * patrol_speed
		
		# 到达目标点
		if global_position.distance_to(target) < 10:
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	else:
		# 随机移动
		if randf() < 0.02:
			velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * patrol_speed
	
	# 检测到玩家则追逐
	if player and _get_distance_to_player() < detection_range:
		current_state = AIState.CHASE

func _do_chase_state(delta):
	if not player:
		current_state = AIState.IDLE
		return
	
	var distance = _get_distance_to_player()
	
	# 超出检测范围，返回巡逻
	if distance > detection_range * 1.5:
		current_state = AIState.PATROL
		return
	
	# 进入攻击范围
	if distance < attack_range:
		current_state = AIState.ATTACK
		return
	
	# 血量过低逃跑
	if float(current_hp) / max_hp < retreat_hp_percent and retreat_hp_percent > 0:
		current_state = AIState.RETREAT
		return
	
	# 追逐玩家
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed

func _do_attack_state(delta):
	if not player:
		current_state = AIState.IDLE
		return
	
	var distance = _get_distance_to_player()
	
	# 玩家离开攻击范围
	if distance > attack_range * 1.5:
		current_state = AIState.CHASE
		return
	
	# 停止移动
	velocity = Vector2.ZERO
	
	# 攻击
	if attack_cooldown <= 0:
		perform_attack()
		attack_cooldown = attack_speed
		last_attack_time = Time.get_ticks_msec() / 1000.0

func _do_retreat_state(delta):
	# 远离玩家
	if player:
		var direction = (global_position - player.global_position).normalized()
		velocity = direction * chase_speed * 0.8
	
	# 跑远后消失或恢复
	if player and _get_distance_to_player() > detection_range * 2:
		# 可以选择恢复或彻底逃跑
		if float(current_hp) / max_hp > 0.5:
			current_state = AIState.PATROL
		else:
			_flee_away()

func _get_distance_to_player() -> float:
	if player:
		return global_position.distance_to(player.global_position)
	return 9999.0

func _pick_patrol_point():
	patrol_points.clear()
	var base_pos = global_position
	for i in range(3):
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		patrol_points.append(base_pos + offset)

func _flee_away():
	# 彻底逃离（消失）
	print("敌人逃跑消失")
	queue_free()

# ============ 战斗系统 ============
func perform_attack():
	if is_attacking or not player:
		return
	
	is_attacking = true
	
	# 视觉反馈
	_change_color(Color(1, 0.5, 0.5))
	
	# 对玩家造成伤害
	if player and player.has_method("take_damage"):
		# 添加仇恨
		_add_hate(player, attack)
		player.take_damage(attack)
	
	await get_tree().create_timer(0.3).timeout
	_change_to_normal_color()
	is_attacking = false

func _change_to_normal_color():
	match enemy_type:
		"slime": _change_color(Color(0.3, 0.7, 0.3))
		"goblin": _change_color(Color(0.5, 0.4, 0.3))
		"skeleton": _change_color(Color(0.9, 0.9, 0.85))
		"boss": _change_color(Color(0.8, 0.2, 0.2))
		_: _change_color(Color(1, 0.2, 0.2))

func take_damage(amount: int):
	if is_dead:
		return
	
	# 计算伤害
	var actual_damage = max(1, amount - defense)
	current_hp -= actual_damage
	
	emit_signal("enemy_damaged", actual_damage, null)
	
	print("敌人受到", actual_damage, "点伤害，剩余HP:", current_hp, "/", max_hp)
	
	# 受伤闪烁
	_take_damage_effect()
	
	# 检查死亡
	if current_hp <= 0:
		die()

func _take_damage_effect():
	# 闪烁效果
	if color_rect:
		color_rect.color = Color.YELLOW
		await get_tree().create_timer(0.1).timeout
		_change_to_normal_color()
	
	# 被打后短暂硬直
	velocity = Vector2.ZERO

func die():
	if is_dead:
		return
	
	is_dead = true
	current_state = AIState.DEAD
	
	# 死亡视觉
	if color_rect:
		color_rect.color = Color(0.5, 0.5, 0.5, 0.5)
	
	# 给予经验
	if player and player.has_method("add_exp"):
		player.add_exp(exp_drop)
		player.on_kill_enemy()  # 通知玩家击杀
	
	# 给予金币
	if player and player.has_method("add_gold"):
		player.add_gold(gold_drop)
	
	# 触发GameManager
	var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
	if game_manager and game_manager.has_method("on_enemy_killed"):
		game_manager.on_enemy_killed(level)
	
	emit_signal("enemy_died", self)
	
	# 延迟消失
	await get_tree().create_timer(0.5).timeout
	queue_free()

# ============ 仇恨系统 ============
func _add_hate(target: Node, hate_value: int):
	var target_id = str(target.get_instance_id())
	if not hate_list.has(target_id):
		hate_list[target_id] = 0
	hate_list[target_id] += hate_value
	
	# 切换仇恨目标
	_update_hate_target()

func _update_hate_target():
	if hate_list.is_empty():
		current_target = player
		return
	
	var max_hate = 0
	var new_target_id = ""
	
	for id in hate_list.keys():
		if hate_list[id] > max_hate:
			max_hate = hate_list[id]
			new_target_id = id
	
	# 切换到仇恨最高的玩家
	current_target = player  # 简化处理

# ============ 公共方法 ============
func set_level(new_level: int):
	level = new_level
	_setup_by_type()

func get_hp_percent() -> float:
	return float(current_hp) / max_hp if max_hp > 0 else 0.0

func is_alive() -> bool:
	return not is_dead

func get_info() -> Dictionary:
	return {
		"type": enemy_type,
		"level": level,
		"hp": current_hp,
		"max_hp": max_hp,
		"attack": attack,
		"defense": defense,
		"exp_drop": exp_drop,
		"gold_drop": gold_drop
	}
