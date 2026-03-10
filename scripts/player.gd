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
@export var speed: float = 200.0

# 鼠标交互
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var target_enemy: Node = null
var attack_range: float = 50.0

# 状态
var is_attacking: bool = false
var is_dead: bool = false

var color_rect: ColorRect
var attack_area: Area2D

func _ready():
	color_rect = $ColorRect
	if has_node("AttackArea"):
		attack_area = $AttackArea
	
	# 初始化目标位置为当前位置
	target_position = global_position
	
	await get_tree().create_timer(0.1).timeout
	update_hp_bar()
	update_exp_bar()
	print("玩家初始化完成 - 鼠标交互模式")

func _input(event):
	if is_dead:
		return
	
	# 鼠标左键点击
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_left_click(event.position)
	
	# 鼠标右键点击（技能）
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		handle_right_click(event.position)

func handle_left_click(screen_position: Vector2):
	# 将屏幕坐标转换为世界坐标
	var world_position = get_global_mouse_position()
	
	# 检测点击的对象
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	
	# 检查是否点击了敌人
	target_enemy = null
	for result in results:
		var collider = result.collider
		if collider.is_in_group("enemies"):
			target_enemy = collider
			break
	
	if target_enemy:
		# 点击敌人 -> 攻击模式
		print("目标锁定: ", target_enemy.name)
		move_to_attack(target_enemy)
	else:
		# 点击地面 -> 移动
		target_position = world_position
		is_moving = true
		target_enemy = null
		print("移动到: ", world_position)

func handle_right_click(screen_position: Vector2):
	# 右键技能攻击
	var world_position = get_global_mouse_position()
	
	# 检测目标
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_position
	
	var results = space_state.intersect_point(query)
	
	for result in results:
		var collider = result.collider
		if collider.is_in_group("enemies"):
			# 对敌人释放技能
			cast_skill_on_target(collider)
			return
	
	# 没有目标，原地释放
	cast_skill_on_position(world_position)

func move_to_attack(enemy: Node):
	if enemy == null:
		return
	
	var distance = global_position.distance_to(enemy.global_position)
	
	if distance <= attack_range:
		# 在攻击范围内，直接攻击
		perform_attack_on(enemy)
	else:
		# 移动到攻击范围内
		var direction = (enemy.global_position - global_position).normalized()
		target_position = enemy.global_position - direction * (attack_range - 10)
		is_moving = true
		target_enemy = enemy

func _physics_process(delta):
	if is_dead:
		return
	
	# 处理移动
	if is_moving:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance < 5:
			# 到达目标
			is_moving = false
			velocity = Vector2.ZERO
			
			# 如果有目标敌人，开始攻击
			if target_enemy and is_instance_valid(target_enemy):
				var enemy_distance = global_position.distance_to(target_enemy.global_position)
				if enemy_distance <= attack_range:
					perform_attack_on(target_enemy)
		else:
			# 继续移动
			velocity = direction * speed
			
			# 更新朝向
			if color_rect:
				if direction.x > 0:
					color_rect.color = Color(0.3, 0.7, 1, 1)
				elif direction.x < 0:
					color_rect.color = Color(0.15, 0.5, 1, 1)
		
		move_and_slide()
	
	# 自动攻击目标
	if target_enemy and is_instance_valid(target_enemy):
		var distance = global_position.distance_to(target_enemy.global_position)
		if distance <= attack_range and not is_attacking:
			perform_attack_on(target_enemy)

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
	
	await get_tree().create_timer(0.5).timeout
	
	if color_rect:
		color_rect.color = Color(0.2, 0.6, 1, 1)
	
	is_attacking = false

func cast_skill_on_target(target: Node):
	# 简单的技能实现
	print("对目标释放技能")
	perform_attack_on(target)

func cast_skill_on_position(position: Vector2):
	# 在指定位置释放技能（AOE）
	print("在位置释放技能: ", position)
	
	# 检测范围内的敌人
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = position.distance_to(enemy.global_position)
		if distance < 100:  # AOE范围
			if enemy.has_method("take_damage"):
				enemy.take_damage(attack * 1.5)  # AOE伤害更高

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
