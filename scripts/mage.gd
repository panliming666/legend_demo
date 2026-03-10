extends CharacterBody2D

class_name Mage

# 法师职业 - 远程魔法攻击（鼠标方向控制版）

# 基础属性
var max_hp: int = 70
var current_hp: int = 70
var max_mp: int = 100
var current_mp: int = 100
var level: int = 1
var exp: int = 0

# 战斗属性
var magic_attack: int = 20
var defense: int = 3

# 移动参数
@export var walk_speed: float = 130.0
@export var run_speed: float = 200.0
var current_speed: float = 0.0

# 鼠标控制
var is_walking: bool = false
var is_running: bool = false
var cast_range: float = 250.0
var target_enemy: Node = null

# 状态
var is_casting: bool = false
var is_dead: bool = false

# 技能列表
var skills: Dictionary = {
	"fireball": {"mp_cost": 10, "damage": 30, "cooldown": 1.0},
	"ice_shield": {"mp_cost": 15, "defense_bonus": 20, "duration": 5.0, "cooldown": 10.0},
	"thunder": {"mp_cost": 25, "damage": 50, "aoe": true, "cooldown": 5.0}
}

var color_rect: ColorRect

func _ready():
	color_rect = $ColorRect
	if color_rect:
		color_rect.color = Color(0.6, 0.2, 0.8, 1)
	print("法师初始化完成 - 鼠标方向控制模式")

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
		
		# 鼠标右键 - 跑动 + 施法
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_running = true
				current_speed = run_speed
				# 右键按下时施放技能
				var mouse_pos = get_global_mouse_position()
				check_enemy_at_mouse(mouse_pos)
				if target_enemy:
					cast_spell_on_target(target_enemy)
				else:
					cast_fireball_at(mouse_pos)
			else:
				is_running = false

func _physics_process(delta):
	if is_dead:
		return
	
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# 检测鼠标位置的敌人
	check_enemy_at_mouse(mouse_pos)
	
	# 移动控制
	if is_walking or is_running:
		velocity = direction * current_speed
		
		if color_rect:
			if is_running:
				color_rect.color = Color(0.8, 0.3, 0.9, 1)
			else:
				color_rect.color = Color(0.6, 0.2, 0.8, 1)
		
		move_and_slide()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 20.0)
		move_and_slide()
		if color_rect:
			color_rect.color = Color(0.6, 0.2, 0.8, 1)

func check_enemy_at_mouse(mouse_pos: Vector2):
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

func cast_spell_on_target(enemy: Node):
	if enemy == null or is_casting:
		return
	
	var distance = global_position.distance_to(enemy.global_position)
	if distance > cast_range:
		return
	
	if current_mp < skills["fireball"]["mp_cost"]:
		return
	
	current_mp -= skills["fireball"]["mp_cost"]
	_cast_fireball_at(enemy.global_position, enemy)

func cast_fireball_at(position: Vector2):
	if is_casting or current_mp < skills["fireball"]["mp_cost"]:
		return
	
	current_mp -= skills["fireball"]["mp_cost"]
	_cast_fireball_at(position, null)

func _cast_fireball_at(target_pos: Vector2, target_enemy: Node):
	is_casting = true
	if color_rect:
		color_rect.color = Color(1, 0.5, 0, 1)
	
	# 创建火球
	_create_projectile(target_pos, skills["fireball"]["damage"], Color(1, 0.3, 0))
	
	await get_tree().create_timer(skills["fireball"]["cooldown"]).timeout
	is_casting = false

func _create_projectile(target_pos: Vector2, damage: int, color: Color) -> Area2D:
	var projectile = Area2D.new()
	projectile.name = "Fireball"
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10
	collision.shape = shape
	projectile.add_child(collision)
	
	var visual = ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.color = color
	visual.position = Vector2(-10, -10)
	projectile.add_child(visual)
	
	projectile.global_position = global_position
	
	var script = GDScript.new()
	script.source_code = """
extends Area2D
var target: Vector2 = Vector2.ZERO
var damage: int = 0
var speed: float = 400.0

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if target != Vector2.ZERO:
		var direction = (target - global_position).normalized()
		position += direction * speed * delta
		
		if global_position.distance_to(target) < 10:
			queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
"""
	script.reload()
	projectile.set_script(script)
	projectile.damage = damage
	projectile.target = target_pos
	
	get_tree().current_scene.add_child(projectile)
	
	return projectile

func take_damage(amount: int):
	var actual_damage = max(1, amount - defense)
	current_hp -= actual_damage
	
	if color_rect:
		color_rect.color = Color.RED
		await get_tree().create_timer(0.1).timeout
		color_rect.color = Color(0.6, 0.2, 0.8, 1)
	
	if current_hp <= 0:
		die()

func die():
	is_dead = true
	if color_rect:
		color_rect.color = Color(0.3, 0.3, 0.3, 0.5)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
