extends CharacterBody2D

class_name Monster

# 妖兽/怪物系统

signal died(rewards: Dictionary)
signal damaged(amount: int, is_critical: bool)

# 怪物类型
enum MonsterType {
	NORMAL,    # 普通怪
	ELITE,     # 精英怪
	BOSS,      # Boss
	WORLD_BOSS # 世界Boss
}

# 怪物种族
enum MonsterRace {
	SPIRIT,    # 灵兽
	BEAST,     # 妖兽
	UNDEAD,    # 亡灵
	DEMON,     # 恶魔
	DRAGON,    # 龙族
	DIVINE     # 神兽
}

# 基本属性
var monster_name: String = "妖兽"
var monster_type: int = MonsterType.NORMAL
var monster_race: int = MonsterRace.BEAST
var level: int = 1

# 战斗属性
var max_hp: int = 50
var current_hp: int = 50
var physical_attack: int = 5
var magic_attack: int = 0
var physical_defense: int = 2
var magic_defense: int = 1
var attack_speed: float = 1.0
var move_speed: int = 100

# AI属性
var detection_range: float = 300.0
var attack_range: float = 50.0
var can_move: bool = true
var attack_cooldown: float = 0.0
var is_attacking: bool = false

# 特殊能力
var skills: Array = []
var has_special_ability: bool = false
var special_cooldown: float = 0.0

# 掉落
var exp_reward: int = 10
var gold_reward: int = 5
var drop_items: Array = []
var drop_rates: Dictionary = {}

# 动画
var sprite: ColorRect
var attack_timer: Timer

func _ready():
	init_visuals()
	init_timers()

func init_visuals():
	# 视觉表现
	sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	sprite.color = get_monster_color()
	add_child(sprite)
	
	# 碰撞体
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	add_child(collision)

func init_timers():
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_end)
	add_child(attack_timer)

# 初始化怪物
func setup_monster(monster_config: Dictionary):
	monster_name = monster_config.get("name", "妖兽")
	monster_type = monster_config.get("type", MonsterType.NORMAL)
	monster_race = monster_config.get("race", MonsterRace.BEAST)
	level = monster_config.get("level", 1)
	
	# 根据类型调整属性
	var type_multiplier: float
	match monster_type:
		MonsterType.NORMAL:
			type_multiplier = 1.0
		MonsterType.ELITE:
			type_multiplier = 3.0
		MonsterType.BOSS:
			type_multiplier = 10.0
		MonsterType.WORLD_BOSS:
			type_multiplier = 50.0
		_:
			type_multiplier = 1.0
	
	# 基础属性
	var base_hp = monster_config.get("hp", 50)
	max_hp = int(base_hp * type_multiplier)
	current_hp = max_hp
	
	physical_attack = int(monster_config.get("attack", 5) * type_multiplier)
	physical_defense = int(monster_config.get("defense", 2) * type_multiplier)
	move_speed = monster_config.get("speed", 100)
	
	# 掉落
	exp_reward = int(monster_config.get("exp", 10) * type_multiplier)
	gold_reward = int(monster_config.get("gold", 5) * type_multiplier)
	drop_items = monster_config.get("drops", [])
	drop_rates = monster_config.get("drop_rates", {})
	
	# 技能
	skills = monster_config.get("skills", [])
	has_special_ability = monster_config.get("has_special", false)

func _physics_process(delta):
	if current_hp <= 0:
		return
	
	# 减少冷却
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	if special_cooldown > 0:
		special_cooldown -= delta
	
	# AI行为
	if can_move and not is_attacking:
		var player = get_nearest_player()
		if player and is_instance_valid(player):
			var distance = global_position.distance_to(player.global_position)
			
			if distance <= detection_range:
				if distance > attack_range:
					# 追击
					chase_player(player)
				else:
					# 攻击
					attack_player(player)
			else:
				# 闲置
				velocity = Vector2.ZERO

func get_nearest_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("players")
	var nearest = null
	var min_dist = detection_range
	
	for player in players:
		if is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = player
	
	return nearest

func chase_player(player: Node2D):
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func attack_player(player: Node2D):
	if attack_cooldown <= 0:
		is_attacking = true
		
		# 造成物理伤害
		if player.has_method("take_damage"):
			player.take_damage(physical_attack)
		
		# 设置冷却
		attack_cooldown = 1.0 / attack_speed
		attack_timer.start(attack_cooldown)
		
		# 动画
		play_attack_animation()

func _on_attack_cooldown_end():
	is_attacking = false

func take_damage(damage: int, is_magic: bool = false):
	if current_hp <= 0:
		return
	
	# 计算伤害
	var actual_damage = damage
	if is_magic:
		actual_damage = max(1, damage - magic_defense)
	else:
		actual_damage = max(1, damage - physical_defense)
	
	current_hp = max(0, current_hp - actual_damage)
	
	# 显示伤害数字
	show_damage_number(actual_damage)
	
	emit_signal("damaged", actual_damage, false)
	
	if current_hp <= 0:
		die()

func show_damage_number(amount: int):
	# 创建伤害数字显示
	var label = Label.new()
	label.text = "-" + str(amount)
	label.add_theme_font_size_override("font_size", 16)
	label.modulate = Color(1, 0, 0, 1)
	label.position = Vector2(0, -30)
	add_child(label)
	
	# 动画
	var tween = create_tween()
	tween.tween_property(label, "position", Vector2(0, -60), 1.0)
	tween.tween_callback(func():
		label.queue_free()
	)

func die():
	# 掉落
	var rewards = generate_rewards()
	emit_signal("died", rewards)
	
	# 死亡动画
	play_death_animation()
	
	# 延迟销毁
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func():
		queue_free()
	)
	add_child(timer)
	timer.start()

func generate_rewards() -> Dictionary:
	var rewards = {
		"exp": exp_reward,
		"gold": gold_reward,
		"items": []
	}
	
	# 物品掉落
	for item_name in drop_items:
		var rate = drop_rates.get(item_name, 0.1)
		if randf() < rate:
			var count = randi_range(1, 3)
			rewards.items.append(item_name + "×" + str(count))
	
	return rewards

func play_attack_animation():
	# 简单的缩放动画
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1, 1), 0.1)

func play_death_animation():
	# 淡出动画
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5, 0), 2.0)

# 根据种族获取颜色
func get_monster_color() -> Color:
	match monster_race:
		MonsterRace.SPIRIT: return Color(0.3, 0.9, 0.3, 1)  # 绿色
		MonsterRace.BEAST: return Color(0.8, 0.4, 0.2, 1)   # 棕色
		MonsterRace.UNDEAD: return Color(0.6, 0.6, 0.5, 1)  # 灰白
		MonsterRace.DEMON: return Color(0.8, 0.1, 0.1, 1)   # 深红
		MonsterRace.DRAGON: return Color(0.3, 0.5, 0.9, 1)  # 蓝色
		MonsterRace.DIVINE: return Color(1, 0.9, 0.3, 1)    # 金色
		_: return Color(0.5, 0.5, 0.5, 1)

# 静态方法：创建怪物配置
static func create_monster_config(monster_race: int, level: int) -> Dictionary:
	var base_stats = {
		MonsterRace.SPIRIT: {"name": "灵兽", "hp": 60, "attack": 6, "defense": 2, "speed": 120, "exp": 12, "gold": 6},
		MonsterRace.BEAST: {"name": "妖兽", "hp": 50, "attack": 5, "defense": 2, "speed": 100, "exp": 10, "gold": 5},
		MonsterRace.UNDEAD: {"name": "亡灵", "hp": 40, "attack": 6, "defense": 1, "speed": 80, "exp": 8, "gold": 4},
		MonsterRace.DEMON: {"name": "恶魔", "hp": 70, "attack": 8, "defense": 3, "speed": 110, "exp": 15, "gold": 8},
		MonsterRace.DRAGON: {"name": "龙族", "hp": 100, "attack": 12, "defense": 5, "speed": 130, "exp": 25, "gold": 15},
		MonsterRace.DIVINE: {"name": "神兽", "hp": 80, "attack": 10, "defense": 4, "speed": 140, "exp": 20, "gold": 12}
	}
	
	var base = base_stats.get(monster_race, base_stats[MonsterRace.BEAST])
	var multiplier = 1.0 + (level - 1) * 0.2
	
	return {
		"name": base.name + "·Lv" + str(level),
		"race": monster_race,
		"level": level,
		"hp": int(base.hp * multiplier),
		"attack": int(base.attack * multiplier),
		"defense": int(base.defense * multiplier),
		"speed": base.speed,
		"exp": int(base.exp * multiplier),
		"gold": int(base.gold * multiplier),
		"drops": ["灵草", "灵石碎片"],
		"drop_rates": {"灵草": 0.7, "灵石碎片": 0.5}
	}
