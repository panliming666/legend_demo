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
@export var acceleration: float = 10.0
@export var friction: float = 10.0

# 状态
var is_attacking: bool = false
var is_dead: bool = false

var color_rect: ColorRect
var attack_area: Area2D

func _ready():
	color_rect = $ColorRect
	if has_node("AttackArea"):
		attack_area = $AttackArea
	
	# 延迟初始化UI引用
	await get_tree().create_timer(0.1).timeout
	update_hp_bar()
	update_exp_bar()
	print("玩家初始化完成 - HP:", current_hp, "/", max_hp)

func _physics_process(delta):
	if is_dead:
		return
	
	# 移动控制
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * speed, acceleration)
		# 根据方向翻转颜色
		if input_vector.x > 0:
			color_rect.color = Color(0.3, 0.7, 1, 1)
		elif input_vector.x < 0:
			color_rect.color = Color(0.15, 0.5, 1, 1)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)
		color_rect.color = Color(0.2, 0.6, 1, 1)
	
	# 攻击控制
	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		perform_attack()
	
	move_and_slide()

func perform_attack():
	is_attacking = true
	# 攻击闪烁效果
	color_rect.color = Color(1, 1, 0.5, 1)
	
	# 检测攻击范围内的敌人
	if has_node("AttackArea"):
		var bodies = $AttackArea.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				body.take_damage(attack)
				print("攻击命中！造成", attack, "点伤害")
	
	await get_tree().create_timer(0.2).timeout
	is_attacking = false

func take_damage(amount: int):
	var actual_damage = max(1, amount - defense)
	current_hp -= actual_damage
	update_hp_bar()
	
	print("受到", actual_damage, "点伤害，剩余HP:", current_hp)
	
	# 受伤闪烁效果
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
