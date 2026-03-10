extends CharacterBody2D

class_name Taoist

# 道士职业 - 召唤与辅助（鼠标交互版）

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
@export var speed: float = 190.0

# 鼠标交互
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var target_enemy: Node = null
var cast_range: float = 200.0

# 状态
var is_casting: bool = false
var is_dead: bool = false

# 技能列表
var skills: Dictionary = {
	"summon_skeleton": {"mp_cost": 20, "damage": 15, "count": 2, "cooldown": 5.0},
	"heal": {"mp_cost": 15, "heal_amount": 30, "cooldown": 3.0},
	"poison_cloud": {"mp_cost": 25, "damage": 10, "duration": 5.0, "range": 150, "cooldown": 8.0},
	"blessing": {"mp_cost": 30, "defense_bonus": 15, "attack_bonus": 10, "duration": 10.0, "cooldown": 15.0}
}

var current_skill: String = "summon_skeleton"

# 召唤物
var summons: Array = []

var color_rect: ColorRect

func _ready():
	color_rect = $ColorRect
	if color_rect:
		color_rect.color = Color(0.2, 0.7, 0.3, 1)  # 绿色道士
	
	target_position = global_position
	print("道士初始化完成 - 鼠标交互模式")

func _input(event):
	if is_dead:
		return
	
	# 鼠标左键 - 移动/召唤攻击
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_left_click(event.position)
	
	# 鼠标右键 - 释放当前技能
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		handle_right_click(event.position)
	
	# 技能切换快捷键
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			current_skill = "summon_skeleton"
			print("当前技能: 召唤骷髅")
		elif event.keycode == KEY_2:
			current_skill = "heal"
			print("当前技能: 治愈术")
		elif event.keycode == KEY_3:
			current_skill = "poison_cloud"
			print("当前技能: 毒云")
		elif event.keycode == KEY_4:
			current_skill = "blessing"
			print("当前技能: 祝福")

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
	cast_spell_at(world_position, current_skill)

func move_to_cast(enemy: Node):
	if enemy == null:
		return
	
	var distance = global_position.distance_to(enemy.global_position)
	
	if distance <= cast_range:
		cast_spell_on_target(enemy)
	else:
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
		"summon_skeleton":
			_summon_skeleton(spell)
		"heal":
			_cast_heal(spell)
		"poison_cloud":
			_cast_poison_cloud(position, spell)
		"blessing":
			_cast_blessing(spell)

func cast_spell_on_target(target: Node):
	if target == null:
		return
	
	var distance = global_position.distance_to(target.global_position)
	if distance > cast_range:
		return
	
	# 召唤骷髅攻击目标
	if current_mp >= skills["summon_skeleton"]["mp_cost"]:
		current_mp -= skills["summon_skeleton"]["mp_cost"]
		_summon_skeleton_with_target(skills["summon_skeleton"], target)

func _summon_skeleton(spell_data: Dictionary):
	is_casting = true
	if color_rect:
		color_rect.color = Color(0.5, 0.5, 0.5, 1)
	
	for i in range(spell_data["count"]):
		var skeleton = _create_skeleton(spell_data["damage"])
		skeleton.position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		summons.append(skeleton)
		get_tree().current_scene.add_child(skeleton)
	
	await get_tree().create_timer(spell_data["cooldown"]).timeout
	is_casting = false

func _summon_skeleton_with_target(spell_data: Dictionary, target: Node):
	is_casting = true
	if color_rect:
		color_rect.color = Color(0.5, 0.5, 0.5, 1)
	
	var skeleton = _create_skeleton_with_target(spell_data["damage"], target)
	skeleton.position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	summons.append(skeleton)
	get_tree().current_scene.add_child(skeleton)
	
	await get_tree().create_timer(spell_data["cooldown"]).timeout
	is_casting = false

func _create_skeleton(damage: int) -> CharacterBody2D:
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
	
	# 简单AI - 自动寻找最近敌人
	var script = GDScript.new()
	script.source_code = """
extends CharacterBody2D
var damage = %d
var target = null
var speed = 100.0

func _physics_process(delta):
	if target == null or not is_instance_valid(target):
		target = _find_nearest_enemy()
	if target:
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * speed
		if global_position.distance_to(target.global_position) < 30:
			if target.has_method("take_damage"):
				target.take_damage(damage)
		move_and_slide()

func _find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var min_dist = 500.0
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy
	return nearest
""" % damage
	script.reload()
	skeleton.set_script(script)
	
	return skeleton

func _create_skeleton_with_target(damage: int, target: Node) -> CharacterBody2D:
	var skeleton = _create_skeleton(damage)
	skeleton.target = target
	return skeleton

func _cast_heal(spell_data: Dictionary):
	is_casting = true
	if color_rect:
		color_rect.color = Color(0.3, 1, 0.3, 1)
	
	current_hp = min(max_hp, current_hp + spell_data["heal_amount"])
	
	for summon in summons:
		if is_instance_valid(summon) and summon.has_method("heal"):
			summon.heal(spell_data["heal_amount"])
	
	await get_tree().create_timer(spell_data["cooldown"]).timeout
	is_casting = false

func _cast_poison_cloud(position: Vector2, spell_data: Dictionary):
	is_casting = true
	if color_rect:
		color_rect.color = Color(0.5, 0, 0.8, 1)
	
	var poison_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = spell_data["range"]
	collision.shape = shape
	poison_area.add_child(collision)
	
	var visual = ColorRect.new()
	visual.size = Vector2(spell_data["range"] * 2, spell_data["range"] * 2)
	visual.color = Color(0.5, 0, 0.8, 0.3)
	visual.position = Vector2(-spell_data["range"], -spell_data["range"])
	poison_area.add_child(visual)
	
	poison_area.global_position = position
	get_tree().current_scene.add_child(poison_area)
	
	var timer = 0.0
	while timer < spell_data["duration"]:
		var bodies = poison_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				body.take_damage(spell_data["damage"])
		await get_tree().create_timer(1.0).timeout
		timer += 1.0
	
	poison_area.queue_free()
	is_casting = false

func _cast_blessing(spell_data: Dictionary):
	is_casting = true
	if color_rect:
		color_rect.color = Color(1, 1, 0.5, 1)
	
	defense += spell_data["defense_bonus"]
	magic_attack += spell_data["attack_bonus"]
	
	for summon in summons:
		if is_instance_valid(summon) and summon.has_method("apply_buff"):
			summon.apply_buff(spell_data["defense_bonus"], spell_data["attack_bonus"])
	
	await get_tree().create_timer(spell_data["duration"]).timeout
	
	defense -= spell_data["defense_bonus"]
	magic_attack -= spell_data["attack_bonus"]
	is_casting = false

func _physics_process(delta):
	if is_dead:
		return
	
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
					color_rect.color = Color(0.3, 0.8, 0.4, 1)
				elif direction.x < 0:
					color_rect.color = Color(0.2, 0.6, 0.3, 1)
		
		move_and_slide()
	
	# 自动施法
	if target_enemy and is_instance_valid(target_enemy):
		var distance = global_position.distance_to(target_enemy.global_position)
		if distance <= cast_range and not is_casting:
			cast_spell_on_target(target_enemy)
	
	# 更新召唤物
	summons = summons.filter(func(s): return is_instance_valid(s) and is_inside_tree())

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
