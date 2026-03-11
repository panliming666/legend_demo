extends CharacterBody2D

# 三清问道 - 玩家控制器
# HD-2D修仙游戏主角

signal hp_changed(current: int, max_hp: int)
signal mp_changed(current: int, max_mp: int)
signal exp_changed(current: int, max_exp: int)
signal level_up(new_level: int)
signal player_died()

# 基础属性
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var attack_power: int = 10
@export var defense: int = 5
@export var speed: float = 200.0

# 当前状态
var current_hp: int
var current_mp: int
var current_exp: int = 0
var level: int = 1
var gold: int = 0

# 移动
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var mouse_control: bool = true  # 鼠标控制模式

# 战斗
var attack_cooldown: float = 0.0
var is_attacking: bool = false
var combo_count: int = 0

# 技能
var skills: Array = []
var skill_cooldowns: Dictionary = {}

func _ready():
	current_hp = max_hp
	current_mp = max_mp
	add_to_group("player")
	
	# 初始化技能
	_init_skills()
	
	# 连接输入
	set_process_input(true)
	
	print("玩家已就绪 - Lv.", level)

func _init_skills():
	# 根据职业初始化技能
	skills = [
		{"name": "普攻", "damage": attack_power, "cooldown": 0.5, "mp_cost": 0},
		{"name": "烈焰斩", "damage": attack_power * 2, "cooldown": 3.0, "mp_cost": 10},
		{"name": "护盾", "damage": 0, "cooldown": 10.0, "mp_cost": 20},
		{"name": "大招", "damage": attack_power * 5, "cooldown": 30.0, "mp_cost": 50}
	]
	
	for i in range(skills.size()):
		skill_cooldowns[i] = 0.0

func _physics_process(delta):
	# 更新冷却
	_update_cooldowns(delta)
	
	# 移动处理
	if mouse_control:
		_mouse_movement(delta)
	else:
		_keyboard_movement(delta)
	
	move_and_slide()
	
	# 攻击冷却
	if attack_cooldown > 0:
		attack_cooldown -= delta

func _input(event):
	# 鼠标点击移动
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				target_position = get_global_mouse_position()
				is_moving = true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# 右键奔跑
			if event.pressed:
				speed = 350.0
			else:
				speed = 200.0
	
	# 技能快捷键
	if event.is_action_pressed("skill_1"):
		use_skill(0)
	elif event.is_action_pressed("skill_2"):
		use_skill(1)
	elif event.is_action_pressed("skill_3"):
		use_skill(2)
	elif event.is_action_pressed("skill_4"):
		use_skill(3)

func _keyboard_movement(delta):
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5)

func _mouse_movement(delta):
	if is_moving and target_position != Vector2.ZERO:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > 5.0:
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO
			is_moving = false
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5)

func _update_cooldowns(delta):
	for i in skill_cooldowns.keys():
		if skill_cooldowns[i] > 0:
			skill_cooldowns[i] -= delta

func use_skill(skill_index: int):
	if skill_index >= skills.size():
		return
	
	var skill = skills[skill_index]
	
	# 检查冷却
	if skill_cooldowns[skill_index] > 0:
		print("技能冷却中：", skill_cooldowns[skill_index])
		return
	
	# 检查蓝量
	if current_mp < skill.mp_cost:
		print("蓝量不足")
		return
	
	# 消耗蓝量
	current_mp -= skill.mp_cost
	skill_cooldowns[skill_index] = skill.cooldown
	
	# 执行技能
	_execute_skill(skill)
	
	emit_signal("mp_changed", current_mp, max_mp)
	print("使用技能：", skill.name)

func _execute_skill(skill: Dictionary):
	if skill.damage > 0:
		# 攻击技能
		_attack_enemies(skill.damage)
	elif skill.name == "护盾":
		# 防御技能
		_activate_shield()

func _attack_enemies(damage: int):
	# 查找范围内的敌人
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < 100:  # 攻击范围
			enemy.take_damage(damage)

func _activate_shield():
	# 激活护盾
	max_hp += 50
	emit_signal("hp_changed", current_hp, max_hp)

func take_damage(damage: int):
	var actual_damage = max(1, damage - defense)
	current_hp -= actual_damage
	
	emit_signal("hp_changed", current_hp, max_hp)
	
	if current_hp <= 0:
		die()

func heal(amount: int):
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)

func add_exp(amount: int):
	current_exp += amount
	emit_signal("exp_changed", current_exp, get_exp_for_level(level + 1))
	
	var exp_needed = get_exp_for_level(level + 1)
	while current_exp >= exp_needed:
		current_exp -= exp_needed
		_on_level_up()

func _on_level_up():
	level += 1
	
	# 属性提升
	max_hp += 20
	max_mp += 10
	attack_power += 5
	defense += 2
	
	# 恢复满血满蓝
	current_hp = max_hp
	current_mp = max_mp
	
	emit_signal("level_up", level)
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("mp_changed", current_mp, max_mp)
	
	print("升级！等级：", level)

func get_exp_for_level(lvl: int) -> int:
	return lvl * 100

func add_gold(amount: int):
	gold += amount

func die():
	emit_signal("player_died")
	print("玩家死亡")
	# 这里可以添加复活逻辑
