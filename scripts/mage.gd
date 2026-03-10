extends CharacterBody2D

class_name Mage

# 法师职业 - 远程魔法攻击

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

# 状态
var is_casting: bool = false
var is_dead: bool = false

# 技能列表
var skills: Dictionary = {
	"fireball": {"mp_cost": 10, "damage": 30, "range": 300},
	"ice_shield": {"mp_cost": 15, "defense_bonus": 20, "duration": 5.0},
	"thunder": {"mp_cost": 25, "damage": 50, "aoe": true}
}

var color_rect: ColorRect

func _ready():
	color_rect = $ColorRect
	if color_rect:
		color_rect.color = Color(0.6, 0.2, 0.8, 1)  # 紫色法师

func _physics_process(delta):
	if is_dead:
		return
	
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * speed, 8.0)
		if color_rect:
			color_rect.color = Color(0.7, 0.3, 0.9, 1)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 8.0)
		if color_rect:
			color_rect.color = Color(0.6, 0.2, 0.8, 1)
	
	move_and_slide()

func cast_spell(spell_name: String):
	if is_casting or current_mp < skills[spell_name]["mp_cost"]:
		return
	
	var spell = skills[spell_name]
	current_mp -= spell["mp_cost"]
	
	match spell_name:
		"fireball":
			_cast_fireball(spell)
		"ice_shield":
			_cast_ice_shield(spell)
		"thunder":
			_cast_thunder(spell)

func _cast_fireball(spell_data: Dictionary):
	is_casting = true
	if color_rect:
		color_rect.color = Color(1, 0.5, 0, 1)  # 橙色施法
	
	# 创建火球投射物
	var fireball = _create_projectile(spell_data["damage"], Color(1, 0.3, 0))
	fireball.position = global_position
	
	await get_tree().create_timer(0.5).timeout
	is_casting = false

func _cast_ice_shield(spell_data: Dictionary):
	is_casting = true
	if color_rect:
		color_rect.color = Color(0.3, 0.7, 1, 1)  # 冰蓝色
	
	defense += spell_data["defense_bonus"]
	await get_tree().create_timer(spell_data["duration"]).timeout
	defense -= spell_data["defense_bonus"]
	is_casting = false

func _cast_thunder(spell_data: Dictionary):
	is_casting = true
	if color_rect:
		color_rect.color = Color(1, 1, 0.3, 1)  # 黄色闪电
	
	# AOE伤害
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < 200:  # AOE范围
			if enemy.has_method("take_damage"):
				enemy.take_damage(spell_data["damage"])
	
	await get_tree().create_timer(0.5).timeout
	is_casting = false

func _create_projectile(damage: int, color: Color) -> Area2D:
	var projectile = Area2D.new()
	var collision = CollisionShape2D.new()
	var visual = ColorRect.new()
	
	visual.size = Vector2(20, 20)
	visual.color = color
	
	projectile.add_child(collision)
	projectile.add_child(visual)
	
	# 伤害处理
	projectile.body_entered.connect(func(body):
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage)
			projectile.queue_free()
	)
	
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
