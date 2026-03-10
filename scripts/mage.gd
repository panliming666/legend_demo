extends CharacterBody2D

class_name Mage

# 法师职业 - 远程魔法攻击（鼠标交互版）

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
@export var speed: float = 180.0

# 鼠标交互
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var target_enemy: Node = null
var cast_range: float = 250.0

# 状态
var is_casting: bool = false
var is_dead: bool = false

# 技能列表
var skills: Dictionary = {
	"fireball": {"mp_cost": 10, "damage": 30, "range": 250, "cooldown": 1.0},
	"ice_shield": {"mp_cost": 15, "defense_bonus": 20, "duration": 5.0, "cooldown": 10.0},
	"thunder": {"mp_cost": 25, "damage": 50, "aoe": true, "range": 200, "cooldown": 5.0}
}

var current_skill: String = "fireball"

var color_rect: ColorRect

func _ready():
	color_rect = $ColorRect
	if color_rect:
		color_rect.color = Color(0.6, 0.2, 0.8, 1)  # 紫色法师
	
	target_position = global_position
	print("法师初始化完成 - 鼠标交互模式")

func _input(event):
	if is_dead:
		return
	
	# 鼠标左键 - 移动/普通魔法攻击
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_left_click(event.position)
	
	# 鼠标右键 - 释放当前技能
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		handle_right_click(event.position)
	
	# 技能切换快捷键
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			current_skill = "fireball"
			print("当前技能: 火球术")
		elif event.keycode == KEY_2:
			current_skill = "ice_shield"
			print("当前技能: 冰盾")
		elif event.keycode == KEY_3:
			current_skill = "thunder"
			print("当前技能: 雷电术")

func handle_left_click(screen_position: Vector2):
	var world_position = get_global_mouse_position()
	
	# 检测点击的对象
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	
	target_enemy = null
	for result in results:
		var collider = result.collider
		if collider.is_in_group("enemies"):
			target_enemy = collider
			break
	
	if target_enemy:
		move_to_cast(target_enemy)
	else:
		target_position = world_position
		is_moving = true
		target_enemy = null

func handle_right_click(screen_position: Vector2):
	var world_position = get_global_mouse_position()
	
	# 释放当前选择的技能
	cast_spell_at(world_position, current_skill)

func move_to_cast(enemy: Node):
	if enemy == null:
		return
	
	var distance = global_position.distance_to(enemy.global_position)
	
	if distance <= cast_range:
		# 在施法范围内，直接释放
		cast_spell_on_target(enemy)
	else:
		# 移动到施法范围内
		var direction = (enemy.global_position - global_position).normalized()
		target_position = enemy.global_position - direction * (cast_range - 20)
		is_moving = true
		target_enemy = enemy

func cast_spell_at(position: Vector2, spell_name: String):
	if is_casting or current_mp < skills[spell_name]["mp_cost"]:
		return
	
	var spell = skills[spell_name]
	current_mp -= spell["mp_cost"]
	
	match spell_name:
		"fireball":
			_cast_fireball_at(position)
		"ice_shield":
			_cast_ice_shield()
		"thunder":
			_cast_thunder_at(position)

func cast_spell_on_target(target: Node):
	if target == null:
		return
	
	var distance = global_position.distance_to(target.global_position)
	if distance > cast_range:
		return
	
	if is_casting or current_mp < skills["fireball"]["mp_cost"]:
		return
	
	current_mp -= skills["fireball"]["mp_cost"]
	_cast_fireball_at(target.global_position)

func _cast_fireball_at(target_pos: Vector2):
	is_casting = true
	if color_rect:
		color_rect.color = Color(1, 0.5, 0, 1)
	
	# 创建火球投射物
	_create_projectile(target_pos, skills["fireball"]["damage"], Color(1, 0.3, 0))
	
	await get_tree().create_timer(skills["fireball"]["cooldown"]).timeout
	is_casting = false

func _cast_ice_shield():
	is_casting = true
	if color_rect:
		color_rect.color = Color(0.3, 0.7, 1, 1)
	
	var bonus = skills["ice_shield"]["defense_bonus"]
	defense += bonus
	
	await get_tree().create_timer(skills["ice_shield"]["duration"]).timeout
	
	defense -= bonus
	is_casting = false

func _cast_thunder_at(target_pos: Vector2):
	is_casting = true
	if color_rect:
		color_rect.color = Color(1, 1, 0.3, 1)
	
	# AOE范围伤害
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if target_pos.distance_to(enemy.global_position) < skills["thunder"]["range"]:
			if enemy.has_method("take_damage"):
				enemy.take_damage(skills["thunder"]["damage"])
	
	await get_tree().create_timer(skills["thunder"]["cooldown"]).timeout
	is_casting = false

func _create_projectile(target_pos: Vector2, damage: int, color: Color) -> Area2D:
	var projectile = Area2D.new()
	projectile.name = "Fireball"
	
	# 碰撞
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10
	collision.shape = shape
	projectile.add_child(collision)
	
	# 视觉效果
	var visual = ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.color = color
	visual.position = Vector2(-10, -10)
	projectile.add_child(visual)
	
	# 设置投射物位置
	projectile.global_position = global_position
	
	# 添加移动脚本
	var script = GDScript.new()
	script.source_code = """
extends Area2D
var target: Vector2 = Vector2.ZERO
var damage: int = 0
var speed: float = 400.0

func _ready():
	var target_node = get_node("/root/Main/Player/TargetPosition")
	if target_node:
		target = target_node.global_position
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

func _physics_process(delta):
	if is_dead:
		return
	
	# 处理移动
	if is_moving:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance < 5:
			is_moving = false
			velocity = Vector2.ZERO
			
			if target_enemy and is_instance_valid(target_enemy):
				var enemy_distance = global_position.distance_to(target_enemy.global_position)
				if enemy_distance <= cast_range:
					cast_spell_on_target(target_enemy)
		else:
			velocity = direction * speed
			if color_rect:
				if direction.x > 0:
					color_rect.color = Color(0.7, 0.3, 0.9, 1)
				elif direction.x < 0:
					color_rect.color = Color(0.5, 0.2, 0.8, 1)
		
		move_and_slide()
	
	# 自动施法目标
	if target_enemy and is_instance_valid(target_enemy):
		var distance = global_position.distance_to(target_enemy.global_position)
		if distance <= cast_range and not is_casting:
			cast_spell_on_target(target_enemy)

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
