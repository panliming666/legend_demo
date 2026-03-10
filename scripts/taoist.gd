extends CharacterBody2D

class_name Taoist

# 道士职业 - 召唤与辅助

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

# 状态
var is_casting: bool = false
var is_dead: bool = false

# 技能列表
var skills: Dictionary = {
	"summon_skeleton": {"mp_cost": 20, "damage": 15, "count": 2},
	"heal": {"mp_cost": 15, "heal_amount": 30},
	"poison_cloud": {"mp_cost": 25, "damage": 10, "duration": 5.0},
	"blessing": {"mp_cost": 30, "defense_bonus": 15, "attack_bonus": 10, "duration": 10.0}
}

# 召唤物
var summons: Array = []

var color_rect: ColorRect

func _ready():
	color_rect = $ColorRect
	if color_rect:
		color_rect.color = Color(0.2, 0.7, 0.3, 1)  # 绿色道士

func _physics_process(delta):
	if is_dead:
		return
	
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * speed, 9.0)
		if color_rect:
			color_rect.color = Color(0.3, 0.8, 0.4, 1)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 9.0)
		if color_rect:
			color_rect.color = Color(0.2, 0.7, 0.3, 1)
	
	move_and_slide()
	
	# 更新召唤物位置
	_update_summons()

func cast_spell(spell_name: String):
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
			_cast_poison_cloud(spell)
		"blessing":
			_cast_blessing(spell)

func _summon_skeleton(spell_data: Dictionary):
	is_casting = true
	if color_rect:
		color_rect.color = Color(0.5, 0.5, 0.5, 1)  # 灰色召唤
	
	# 创建骷髅召唤物
	for i in range(spell_data["count"]):
		var skeleton = _create_skeleton(spell_data["damage"])
		skeleton.position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		summons.append(skeleton)
		get_tree().current_scene.add_child(skeleton)
	
	await get_tree().create_timer(0.5).timeout
	is_casting = false

func _create_skeleton(damage: int) -> CharacterBody2D:
	var skeleton = CharacterBody2D.new()
	skeleton.add_to_group("summons")
	skeleton.add_to_group("allies")
	
	# 碰撞
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 32)
	collision.shape = shape
	skeleton.add_child(collision)
	
	# 视觉
	var visual = ColorRect.new()
	visual.size = Vector2(24, 32)
	visual.color = Color(0.7, 0.7, 0.6, 1)  # 骨白色
	visual.position = Vector2(-12, -16)
	skeleton.add_child(visual)
	
	# 简单AI脚本
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
	var min_dist = 1000.0
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

func _cast_heal(spell_data: Dictionary):
	is_casting = true
	if color_rect:
		color_rect.color = Color(0.3, 1, 0.3, 1)  # 治愈绿
	
	# 治疗自己
	current_hp = min(max_hp, current_hp + spell_data["heal_amount"])
	
	# 治疗召唤物
	for summon in summons:
		if summon.has_method("heal"):
			summon.heal(spell_data["heal_amount"])
	
	await get_tree().create_timer(0.3).timeout
	is_casting = false

func _cast_poison_cloud(spell_data: Dictionary):
	is_casting = true
	if color_rect:
		color_rect.color = Color(0.5, 0, 0.8, 1)  # 毒紫色
	
	# 创建毒云区域
	var poison_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 100
	collision.shape = shape
	poison_area.add_child(collision)
	
	# 视觉效果
	var visual = ColorRect.new()
	visual.size = Vector2(200, 200)
	visual.color = Color(0.5, 0, 0.8, 0.3)
	visual.position = Vector2(-100, -100)
	poison_area.add_child(visual)
	
	poison_area.position = global_position
	get_tree().current_scene.add_child(poison_area)
	
	# 持续伤害
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
		color_rect.color = Color(1, 1, 0.5, 1)  # 祝福金色
	
	# 增益自己
	defense += spell_data["defense_bonus"]
	magic_attack += spell_data["attack_bonus"]
	
	# 增益召唤物
	for summon in summons:
		if summon.has_method("apply_buff"):
			summon.apply_buff(spell_data["defense_bonus"], spell_data["attack_bonus"])
	
	await get_tree().create_timer(spell_data["duration"]).timeout
	
	# 移除增益
	defense -= spell_data["defense_bonus"]
	magic_attack -= spell_data["attack_bonus"]
	is_casting = false

func _update_summons():
	# 移除无效的召唤物
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
	
	# 清除所有召唤物
	for summon in summons:
		if is_instance_valid(summon):
			summon.queue_free()
	summons.clear()
	
	if color_rect:
		color_rect.color = Color(0.3, 0.3, 0.3, 0.5)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
