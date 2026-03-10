extends CharacterBody2D

class_name Player

# 基础属性（传奇风格）
var max_hp: int = 100
var current_hp: int = 100
var max_mp: int = 50
var current_mp: int = 50
var level: int = 1
var exp: int = 0

# 战斗属性
var attack: int = 10
var defense: int = 5

# 移动参数
@export var walk_speed: float = 150.0   # 行走速度
@export var run_speed: float = 250.0    # 跑动速度
var current_speed: float = 0.0

# 鼠标控制
var is_walking: bool = false
var is_running: bool = false
var attack_range: float = 50.0
var target_enemy: Node = null

# 状态
var is_attacking: bool = false
var is_dead: bool = false

var color_rect: ColorRect
var attack_area: Area2D

func _ready():
	color_rect = $ColorRect
	if has_node("AttackArea"):
		attack_area = $AttackArea
	
	await get_tree().create_timer(0.1).timeout
	update_hp_bar()
	update_exp_bar()
	print("玩家初始化完成 - 鼠标方向控制模式")

func _input(event):
	if is_dead:
		return
	
	# 鼠标左键 - 行走
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_walking = true
				current_speed = walk_speed
			else:
				is_walking = false
		
		# 鼠标右键 - 跑动
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_running = true
				current_speed = run_speed
			else:
				is_running = false
		
		# 优先跑动
		if is_running:
			is_walking = false

func _physics_process(delta):
	if is_dead:
		return
	
	# 获取鼠标世界坐标
	var mouse_pos = get_global_mouse_position()
	
	# 计算朝向
	var direction = (mouse_pos - global_position).normalized()
	
	# 检测鼠标位置的敌人（用于攻击）
	check_enemy_at_mouse(mouse_pos)
	
	# 移动控制
	if is_walking or is_running:
		velocity = direction * current_speed
		
		# 更新朝向颜色
		if color_rect:
			if is_running:
				color_rect.color = Color(0.4, 0.8, 1, 1)  # 跑动时颜色更亮
			else:
				color_rect.color = Color(0.2, 0.6, 1, 1)  # 行走时正常颜色
		
		move_and_slide()
		
		# 如果鼠标在敌人上且在攻击范围内，自动攻击
		if target_enemy and not is_attacking:
			var distance = global_position.distance_to(target_enemy.global_position)
			if distance <= attack_range:
				perform_attack_on(target_enemy)
	else:
		# 停止移动
		velocity = velocity.move_toward(Vector2.ZERO, 20.0)
		move_and_slide()
		if color_rect:
			color_rect.color = Color(0.2, 0.6, 1, 1)

func check_enemy_at_mouse(mouse_pos: Vector2):
	# 检测鼠标位置的敌人
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	
	target_enemy = null
	for result in results:
		var collider = result.collider
		if collider.is_in_group("enemies"):
			target_enemy = collider
			break

func perform_attack_on(enemy: Node):
	if is_attacking or enemy == null:
		return
	
	is_attacking = true
	
	# 攻击闪烁效果
	if color_rect:
		color_rect.color = Color(1, 1, 0.5, 1)
	
	# 对敌人造成伤害
	if enemy.has_method("take_damage"):
		enemy.take_damage(attack)
		print("攻击命中！", attack, "点伤害")
	
	await get_tree().create_timer(0.4).timeout
	
	if color_rect:
		color_rect.color = Color(0.2, 0.6, 1, 1)
	
	is_attacking = false

func take_damage(amount: int):
	var actual_damage = max(1, amount - defense)
	current_hp -= actual_damage
	update_hp_bar()
	
	print("受到", actual_damage, "点伤害，剩余HP:", current_hp)
	
	# 受伤闪烁效果
	if color_rect:
		color_rect.color = Color.RED
		await get_tree().create_timer(0.1).timeout
		color_rect.color = Color(0.2, 0.6, 1, 1)
	
	if current_hp <= 0:
		die()

func heal(amount: int):
	current_hp = min(max_hp, current_hp + amount)
	update_hp_bar()
	print("恢复", amount, "点HP，当前HP:", current_hp)

func gain_exp(amount: int):
	exp += amount
	update_exp_bar()
	print("获得", amount, "点经验")
	check_level_up()

func check_level_up():
	var required_exp = level * 100
	if exp >= required_exp:
		level_up()

func level_up():
	level += 1
	max_hp += 20
	current_hp = max_hp
	max_mp += 10
	current_mp = max_mp
	attack += 5
	defense += 2
	exp = 0
	
	update_hp_bar()
	update_exp_bar()
	update_level_label()
	
	print("升级！当前等级:", level)
	print("HP:", max_hp, "MP:", max_mp, "攻击:", attack, "防御:", defense)

func die():
	is_dead = true
	if color_rect:
		color_rect.color = Color(0.3, 0.3, 0.3, 0.5)
	print("玩家死亡")
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func update_hp_bar():
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui:
		var hp_bar = ui.get_node_or_null("HPBar")
		if hp_bar:
			hp_bar.max_value = max_hp
			hp_bar.value = current_hp
			var label = hp_bar.get_node_or_null("Label")
			if label:
				label.text = "HP: " + str(current_hp) + "/" + str(max_hp)
		
		var mp_bar = ui.get_node_or_null("MPBar")
		if mp_bar:
			mp_bar.max_value = max_mp
			mp_bar.value = current_mp
			var label = mp_bar.get_node_or_null("Label")
			if label:
				label.text = "MP: " + str(current_mp) + "/" + str(max_mp)

func update_exp_bar():
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui:
		var exp_bar = ui.get_node_or_null("EXPBar")
		if exp_bar:
			var required_exp = level * 100
			exp_bar.max_value = required_exp
			exp_bar.value = exp
			var label = exp_bar.get_node_or_null("Label")
			if label:
				label.text = "EXP: " + str(exp) + "/" + str(required_exp)

func update_level_label():
	var ui = get_tree().current_scene.get_node_or_null("UI")
	if ui:
		var level_label = ui.get_node_or_null("LevelLabel")
		if level_label:
			level_label.text = "等级: " + str(level)
