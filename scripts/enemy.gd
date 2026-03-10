extends CharacterBody2D

class_name Enemy

# 基础属性
var max_hp: int = 30
var current_hp: int = 30
var level: int = 1

# 战斗属性
var attack: int = 5
var defense: int = 2

# 移动参数
var speed: float = 50.0
var chase_speed: float = 100.0

# AI参数
var detection_range: float = 200.0
var attack_range: float = 30.0

# 状态
var is_chasing: bool = false
var is_attacking: bool = false
var is_dead: bool = false

# 引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var player: Node = null

func _ready():
	add_to_group("enemies")
	# 查找玩家
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	if is_dead:
		return
	
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# AI行为
		if distance_to_player < detection_range:
			is_chasing = true
			
			# 追逐玩家
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * chase_speed
			
			# 检测攻击范围
			if distance_to_player < attack_range and not is_attacking:
				perform_attack()
		else:
			is_chasing = false
			# 随机巡逻
			if randf() < 0.01:
				velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed
		
		move_and_slide()

func perform_attack():
	is_attacking = true
	animated_sprite.play("attack")
	
	# 对玩家造成伤害
	if player and player.has_method("take_damage"):
		player.take_damage(attack)
	
	await get_tree().create_timer(1.0).timeout
	is_attacking = false

func take_damage(amount: int):
	var actual_damage = max(1, amount - defense)
	current_hp -= actual_damage
	
	print("敌人受到", actual_damage, "点伤害，剩余HP:", current_hp)
	
	# 受伤闪烁
	animated_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	animated_sprite.modulate = Color.WHITE
	
	# 掉落经验
	if current_hp <= 0:
		die()

func die():
	is_dead = true
	animated_sprite.play("die")
	
	# 掉落经验给玩家
	if player and player.has_method("gain_exp"):
		player.gain_exp(level * 10)
	
	await get_tree().create_timer(1.0).timeout
	queue_free()
