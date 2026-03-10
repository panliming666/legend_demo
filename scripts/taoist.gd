extends CharacterBody2D

class_name Taoist

# 道士职业 - 召唤与辅助（鼠标方向控制版）

# 基础属性
var max_hp: int = 80
var current_hp: int = 80
var max_mp: int = 80
var current_mp: int = 80
var level: int = 1
var exp: int = 0

# 战斗属性
var magic_attack: int = 15
var defense: int = 4

# 移动参数
@export var walk_speed: float = 140.0
@export var run_speed: float = 210.0
var current_speed: float = 0.0

# 鼠标控制
var is_walking: bool = false
var is_running: bool = false
var cast_range: float = 200.0
var target_enemy: Node = null

# 状态
var is_casting: bool = false
var is_dead: bool = false

# 技能列表
var skills: Dictionary = {
	"summon_skeleton": {"mp_cost": 20, "damage": 15, "count": 2, "cooldown": 5.0},
	"heal": {"mp_cost": 15, "heal_amount": 30, "cooldown": 3.0},
	"poison_cloud": {"mp_cost": 25, "damage": 10, "duration": 5.0, "range": 150, "cooldown": 8.0}
}

# 召唤物
var summons: Array = []

var color_rect: ColorRect

func _ready():
	color_rect = $ColorRect
	if color_rect:
		color_rect.color = Color(0.2, 0.7, 0.3, 1)
	print("道士初始化完成 - 鼠标方向控制模式")

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
				# 右键施放技能
				var mouse_pos = get_global_mouse_position()
				check_enemy_at_mouse(mouse_pos)
				if target_enemy:
					summon_skeleton_to_target(target_enemy)
				else:
					cast_poison_cloud_at(mouse_pos)
			else:
				is_running = false

func _physics_process(delta):
	if is_dead:
		return
	
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	check_enemy_at_mouse(mouse_pos)
	
	# 移动控制
	if is_walking or is_running:
		velocity = direction * current_speed
		
		if color_rect:
			if is_running:
				color_rect.color = Color(0.3, 0.8, 0.4, 1)
			else:
				color_rect.color = Color(0.2, 0.7, 0.3, 1)
		
		move_and_slide()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 20.0)
		move_and_slide()
		if color_rect:
			color_rect.color = Color(0.2, 0.7, 0.3, 1)
	
	# 更新召唤物
	summons = summons.filter(func(s): return is_instance_valid(s) and is_inside_tree())

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

func summon_skeleton_to_target(enemy: Node):
	if enemy == null or is_casting:
		return
	
	if current_mp < skills["summon_skeleton"]["mp_cost"]:
		return
	
	current_mp -= skills["summon_skeleton"]["mp_cost"]
	is_casting = true
	
	if color_rect:
		color_rect.color = Color(0.5, 0.5, 0.5, 1)
	
	# 召唤骷髅攻击目标
	var skeleton = _create_skeleton_with_target(skills["summon_skeleton"]["damage"], enemy)
	skeleton.position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	summons.append(skeleton)
	get_tree().current_scene.add_child(skeleton)
	
	await get_tree().create_timer(skills["summon_skeleton"]["cooldown"]).timeout
	is_casting = false

func cast_poison_cloud_at(position: Vector2):
	if is_casting or current_mp < skills["poison_cloud"]["mp_cost"]:
		return
	
	current_mp -= skills["poison_cloud"]["mp_cost"]
	is_casting = true
	
	if color_rect:
		color_rect.color = Color(0.5, 0, 0.8, 1)
	
	# 创建毒云
	var poison_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = skills["poison_cloud"]["range"]
	collision.shape = shape
	poison_area.add_child(collision)
	
	var visual = ColorRect.new()
	visual.size = Vector2(skills["poison_cloud"]["range"] * 2, skills["poison_cloud"]["range"] * 2)
	visual.color = Color(0.5, 0, 0.8, 0.3)
	visual.position = Vector2(-skills["poison_cloud"]["range"], -skills["poison_cloud"]["range"])
	poison_area.add_child(visual)
	
	poison_area.global_position = position
	get_tree().current_scene.add_child(poison_area)
	
	# 持续伤害
	var timer = 0.0
	while timer < skills["poison_cloud"]["duration"]:
		var bodies = poison_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				body.take_damage(skills["poison_cloud"]["damage"])
		await get_tree().create_timer(1.0).timeout
		timer += 1.0
	
	poison_area.queue_free()
	is_casting = false

func _create_skeleton_with_target(damage: int, target: Node) -> CharacterBody2D:
	var skeleton = CharacterBody2D.new()
	skeleton.add_to_group("summons")
	skeleton.add_to_group("allies")
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 32)
	collision.shape = shape
	skeleton.add_child(collision)
	
	var visual = ColorRect.new()
	visual.size = Vector2(24, 32)
	visual.color = Color(0.7, 0.7, 0.6, 1)
	visual.position = Vector2(-12, -16)
	skeleton.add_child(visual)
	
	# 骷髅AI脚本
	var script = GDScript.new()
	script.source_code = """
extends CharacterBody2D
var damage = %d
var target = null
var speed = 100.0

func _ready():
	target = get_node_or_null(\"%s\")

func _physics_process(delta):
	if target == null or not is_instance_valid(target):
		target = _find_nearest_enemy()
	if target:
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * speed
		if global_position.distance_to(target.global_position) < 30:
			if target.has_method(\"take_damage\"):
				target.take_damage(damage)
		move_and_slide()

func _find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group(\"enemies\")
	var nearest = null
	var min_dist = 500.0
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy
	return nearest
""" % [damage, target.get_path()]
	script.reload()
	skeleton.set_script(script)
	
	return skeleton

func take_damage(amount: int):
	var actual_damage = max(1, amount - defense)
	current_hp -= actual_damage
	
	if color_rect:
		color_rect.color = Color.RED
		await get_tree().create_timer(0.1).timeout
		color_rect.color = Color(0.2, 0.7, 0.3, 1)
	
	if current_hp <= 0:
		die()

func die():
	is_dead = true
	
	for summon in summons:
		if is_instance_valid(summon):
			summon.queue_free()
	summons.clear()
	
	if color_rect:
		color_rect.color = Color(0.3, 0.3, 0.3, 0.5)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
