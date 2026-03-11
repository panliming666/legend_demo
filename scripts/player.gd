extends CharacterBody2D

# 三清问道 - 玩家控制器（多职业版本）
# 支持剑修/法修/符修

signal hp_changed(current: int, max_hp: int)
signal mp_changed(current: int, max_mp: int)
signal exp_changed(current: int, max_exp: int)
signal level_up(new_level: int)
signal player_died()
signal gold_changed(amount: int)
signal class_changed(new_class: int)
signal buff_added(buff_name: String)
signal buff_removed(buff_name: String)
signal target_locked(enemy)
signal target_unlocked()
signal skill_used(skill_name: String)

# ============ 职业系统 ============
enum ClassType {
	SWORD,    # 剑修 - 近战物理
	MAGE,     # 法修 - 远程魔法
	TAOIST    # 符修 - 召唤辅助
}

var current_class: ClassType = ClassType.SWORD

# ============ 基础属性 ============
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var attack_power: int = 10
@export var magic_power: int = 0     # 法术攻击
@export var defense: int = 5
@export var speed: float = 200.0
@export var crit_rate: float = 0.05
@export var crit_damage: float = 1.5
@export var attack_speed: float = 1.0
@export var attack_range: float = 50.0  # 职业差异

var current_hp: int
var current_mp: int
var current_exp: int = 0
var level: int = 1
var gold: int = 0

# ============ 战斗系统 ============
var locked_target: Node = null
var is_auto_attacking: bool = false
var attack_cooldown: float = 0.0
var attack_interval: float = 1.0

# 移动
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var mouse_control: bool = true

# Buff
var active_buffs: Dictionary = {}
var invincible: bool = false
var invincible_timer: float = 0.0

# 统计
var total_kills: int = 0
var total_damage_dealt: int = 0
var total_damage_taken: int = 0

# 自动存档
var auto_save_timer: float = 0.0
const AUTO_SAVE_INTERVAL: float = 60.0

# 技能相关
var skills: Array = []
var skill_cooldowns: Dictionary = {}

# ============ 初始化 ============
func _ready():
	# 根据职业设置初始属性
	_setup_class_stats(current_class)
	
	current_hp = max_hp
	current_mp = max_mp
	attack_interval = 1.0 / attack_speed
	add_to_group("player")
	
	_init_skills()
	set_process_input(true)
	_load_from_save()
	
	print("玩家已就绪 - ", _get_class_name(), " Lv.", level)

# 根据职业设置属性
func _setup_class_stats(class_type: ClassType):
	match class_type:
		ClassType.SWORD:
			max_hp = 120
			max_mp = 60
			attack_power = 18
			magic_power = 0
			defense = 8
			speed = 220.0
			attack_speed = 1.2
			attack_range = 50.0
			crit_rate = 0.08
		
		ClassType.MAGE:
			max_hp = 70
			max_mp = 150
			attack_power = 5
			magic_power = 25
			defense = 3
			speed = 180.0
			attack_speed = 0.8
			attack_range = 300.0
			crit_rate = 0.12
		
		ClassType.TAOIST:
			max_hp = 85
			max_mp = 100
			attack_power = 8
			magic_power = 15
			defense = 5
			speed = 200.0
			attack_speed = 0.9
			attack_range = 180.0
			crit_rate = 0.05

# 获取职业名称
func _get_class_name() -> String:
	match current_class:
		ClassType.SWORD: return "剑修"
		ClassType.MAGE: return "法修"
		ClassType.TAOIST: return "符修"
		_: return "剑修"

# 切换职业
func set_class(new_class: ClassType):
	current_class = new_class
	_setup_class_stats(new_class)
	current_hp = max_hp
	current_mp = max_mp
	attack_interval = 1.0 / attack_speed
	_init_skills()
	emit_signal("class_changed", new_class)
	print("切换职业: ", _get_class_name())

# ============ 技能系统（职业差异） ============
func _init_skills():
	skills = []
	
	match current_class:
		ClassType.SWORD:
			skills = [
				{"name": "基础剑术", "damage": attack_power, "cooldown": 0, "mp_cost": 0, "type": "melee", "range": attack_range},
				{"name": "剑气斩", "damage": attack_power * 2, "cooldown": 2.0, "mp_cost": 10, "type": "ranged", "range": 150},
				{"name": "疾风剑", "damage": attack_power * 3, "cooldown": 4.0, "mp_cost": 20, "type": "multi", "hits": 3},
				{"name": "破军式", "damage": attack_power * 5, "cooldown": 10.0, "mp_cost": 40, "type": "heavy", "range": 80}
			]
		
		ClassType.MAGE:
			skills = [
				{"name": "灵火术", "damage": magic_power * 1.5, "cooldown": 0.8, "mp_cost": 5, "type": "projectile", "range": attack_range},
				{"name": "雷击术", "damage": magic_power * 2.5, "cooldown": 3.0, "mp_cost": 15, "type": "single", "range": attack_range},
				{"name": "冰封术", "damage": magic_power * 2, "cooldown": 5.0, "mp_cost": 25, "type": "aoe", "range": 200, "slow": true},
				{"name": "天雷降", "damage": magic_power * 5, "cooldown": 15.0, "mp_cost": 60, "type": "ultimate", "range": 350}
			]
		
		ClassType.TAOIST:
			skills = [
				{"name": "符咒攻击", "damage": magic_power * 1.2, "cooldown": 1.0, "mp_cost": 5, "type": "projectile", "range": attack_range},
				{"name": "召唤灵宠", "damage": 0, "cooldown": 8.0, "mp_cost": 20, "type": "summon", "count": 2},
				{"name": "治疗符", "damage": 0, "cooldown": 5.0, "mp_cost": 15, "type": "heal", "amount": max_hp * 0.3},
				{"name": "毒云术", "damage": magic_power * 1.5, "cooldown": 10.0, "mp_cost": 30, "type": "dot_aoe", "duration": 5.0, "range": 150}
			]
	
	for i in range(skills.size()):
		skill_cooldowns[i] = 0.0

# 召唤物（符修用）
var summons: Array = []

# ============ 主循环 ============
func _physics_process(delta):
	_update_cooldowns(delta)
	_update_buffs(delta)
	
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
	
	# 自动攻击
	if locked_target and is_instance_valid(locked_target):
		_auto_attack_logic(delta)
	
	# 移动
	if mouse_control:
		_mouse_movement(delta)
	else:
		_keyboard_movement(delta)
	
	move_and_slide()
	
	# 自动存档
	auto_save_timer += delta
	if auto_save_timer >= AUTO_SAVE_INTERVAL:
		auto_save_timer = 0.0
		_auto_save()

func _update_cooldowns(delta):
	for i in skill_cooldowns.keys():
		if skill_cooldowns[i] > 0:
			skill_cooldowns[i] -= delta
	if attack_cooldown > 0:
		attack_cooldown -= delta

func _update_buffs(delta):
	var expired = []
	for buff in active_buffs.keys():
		active_buffs[buff].duration -= delta
		if active_buffs[buff].duration <= 0:
			expired.append(buff)
	for buff in expired:
		_remove_buff(buff)

# ============ 自动攻击 ============
func _auto_attack_logic(delta):
	if not locked_target or not is_instance_valid(locked_target):
		_unlock_target()
		return
	
	var distance = global_position.distance_to(locked_target.global_position)
	
	if distance <= attack_range:
		is_moving = false
		velocity = Vector2.ZERO
		if attack_cooldown <= 0:
			_perform_normal_attack()
	else:
		var direction = (locked_target.global_position - global_position).normalized()
		velocity = direction * speed

func _perform_normal_attack():
	attack_cooldown = attack_interval
	
	var damage = _calculate_damage(attack_power)
	
	match current_class:
		ClassType.SWORD:
			# 近战：直接伤害
			if locked_target.has_method("take_damage"):
				locked_target.take_damage(damage)
				total_damage_dealt += damage
		
		ClassType.MAGE:
			# 法师：发射魔法弹
			_cast_magic_projectile(locked_target.global_position, damage)
		
		ClassType.TAOIST:
			# 道士：发射符咒
			_cast_talisman(locked_target.global_position, damage)

# ============ 法师技能：魔法弹 ============
func _cast_magic_projectile(target_pos: Vector2, damage: int):
	# 简单的弹道效果
	var projectile = Area2D.new()
	projectile.name = "MagicProjectile"
	
	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = 8
	projectile.add_child(col)
	
	# 视觉效果
	var visual = ColorRect.new()
	visual.size = Vector2(16, 16)
	visual.color = Color(0.5, 0.3, 1.0)  # 紫色魔法弹
	visual.position = Vector2(-8, -8)
	projectile.add_child(visual)
	
	projectile.global_position = global_position
	get_tree().current_scene.add_child(projectile)
	
	# 简单的移动脚本
	var tween = create_tween()
	tween.tween_property(projectile, "global_position", target_pos, 0.3)
	tween.tween_callback(func():
		# 命中检测
		var bodies = projectile.get_overlapping_bodies()
		for b in bodies:
			if b.is_in_group("enemies") and b.has_method("take_damage"):
				b.take_damage(damage)
				total_damage_dealt += damage
		projectile.queue_free()
	)

# ============ 道士技能：符咒 ============
func _cast_talisman(target_pos: Vector2, damage: int):
	var projectile = Area2D.new()
	projectile.name = "Talisman"
	
	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = 6
	projectile.add_child(col)
	
	var visual = ColorRect.new()
	visual.size = Vector2(12, 12)
	visual.color = Color(0.2, 0.8, 0.3)  # 绿色符咒
	visual.position = Vector2(-6, -6)
	projectile.add_child(visual)
	
	projectile.global_position = global_position
	get_tree().current_scene.add_child(projectile)
	
	var tween = create_tween()
	tween.tween_property(projectile, "global_position", target_pos, 0.25)
	tween.tween_callback(func():
		var bodies = projectile.get_overlapping_bodies()
		for b in bodies:
			if b.is_in_group("enemies") and b.has_method("take_damage"):
				b.take_damage(damage)
				total_damage_dealt += damage
		projectile.queue_free()
	)

# ============ 输入处理 ============
func _input(event):
	# 左键锁定/移动
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_lock_target_at_position(get_global_mouse_position())
			else:
				is_moving = false
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_unlock_target()
	
	# 技能键
	if event.is_action_pressed("skill_1"): use_skill(0)
	elif event.is_action_pressed("skill_2"): use_skill(1)
	elif event.is_action_pressed("skill_3"): use_skill(2)
	elif event.is_action_pressed("skill_4"): use_skill(3)

func _lock_target_at_position(world_pos: Vector2):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest = null
	var closest_dist = 50.0
	
	for e in enemies:
		var d = e.global_position.distance_to(world_pos)
		if d < closest_dist:
			closest_dist = d
			closest = e
	
	if closest:
		_lock_target(closest)
	else:
		target_position = world_pos
		is_moving = true

func _lock_target(enemy: Node):
	locked_target = enemy
	is_auto_attacking = true
	emit_signal("target_locked", enemy)

func _unlock_target():
	locked_target = null
	is_auto_attacking = false
	emit_signal("target_unlocked")

# ============ 移动 ============
func _mouse_movement(delta):
	if is_moving and target_position != Vector2.ZERO:
		if locked_target and is_instance_valid(locked_target):
			var dist = global_position.distance_to(locked_target.global_position)
			if dist > attack_range:
				target_position = locked_target.global_position
		
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > 5.0:
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO
			is_moving = false
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5)

func _keyboard_movement(delta):
	var dir = Vector2.ZERO
	if Input.is_action_pressed("move_left"): dir.x -= 1
	if Input.is_action_pressed("move_right"): dir.x += 1
	if Input.is_action_pressed("move_up"): dir.y -= 1
	if Input.is_action_pressed("move_down"): dir.y += 1
	
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity = dir * speed
		if locked_target: _unlock_target()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5)

# ============ 技能系统 ============
func use_skill(skill_index: int):
	if skill_index >= skills.size(): return
	
	var skill = skills[skill_index]
	if skill_cooldowns[skill_index] > 0: return
	if current_mp < skill.mp_cost: return
	
	current_mp -= skill.mp_cost
	skill_cooldowns[skill_index] = skill.cooldown
	emit_signal("mp_changed", current_mp, max_mp)
	emit_signal("skill_used", skill.name)
	
	match skill.type:
		"melee", "ranged", "heavy":
			_sword_skill(skill)
		"projectile", "single", "aoe", "ultimate":
			_mage_skill(skill)
		"summon", "heal", "dot_aoe":
			_taoist_skill(skill)

# 剑修技能
func _sword_skill(skill: Dictionary):
	if skill.type == "ranged" or skill.type == "multi":
		# 远程剑气
		if locked_target:
			var dmg = _calculate_damage(skill.damage)
			locked_target.take_damage(dmg)
			total_damage_dealt += dmg
	else:
		# 近战
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if global_position.distance_to(e.global_position) <= skill.range:
				e.take_damage(_calculate_damage(skill.damage))

# 法修技能
func _mage_skill(skill: Dictionary):
	match skill.type:
		"projectile", "single":
			if locked_target:
				var dmg = _calculate_damage(skill.damage, true)
				_cast_magic_projectile(locked_target.global_position, dmg)
		
		"aoe":
			# 范围魔法
			var center = locked_target.global_position if locked_target else global_position
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if global_position.distance_to(e.global_position) <= skill.range:
					e.take_damage(_calculate_damage(skill.damage, true))
		
		"ultimate":
			# 天雷降
			if locked_target:
				_lock_target(locked_target)
				var dmg = _calculate_damage(skill.damage, true)
				locked_target.take_damage(dmg)
				total_damage_dealt += dmg

# 符修技能
func _taoist_skill(skill: Dictionary):
	match skill.type:
		"projectile":
			if locked_target:
				var dmg = _calculate_damage(skill.damage, true)
				_cast_talisman(locked_target.global_position, dmg)
		
		"summon":
			_spawn_summons(skill.count)
		
		"heal":
			heal(int(skill.amount))
		
		"dot_aoe":
			_create_poison_area(skill)

func _spawn_summons(count: int):
	for i in range(count):
		var summon = CharacterBody2D.new()
		summon.add_to_group("summons")
		
		var col = CollisionShape2D.new()
		col.shape = CircleShape2D.new()
		col.shape.radius = 10
		summon.add_child(col)
		
		var visual = ColorRect.new()
		visual.size = Vector2(20, 20)
		visual.color = Color(0.3, 0.7, 0.4)
		visual.position = Vector2(-10, -10)
		summon.add_child(visual)
		
		summon.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		get_tree().current_scene.add_child(summon)
		summons.append(summon)

func _create_poison_area(skill: Dictionary):
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = skill.range
	area.add_child(col)
	
	var visual = ColorRect.new()
	visual.size = Vector2(skill.range * 2, skill.range * 2)
	visual.color = Color(0.2, 0.5, 0.2, 0.3)
	visual.position = Vector2(-skill.range, -skill.range)
	area.add_child(visual)
	
	area.global_position = global_position
	get_tree().current_scene.add_child(area)
	
	# 持续伤害
	var timer = 0.0
	while timer < skill.duration:
		await get_tree().create_timer(1.0).timeout
		var bodies = area.get_overlapping_bodies()
		for b in bodies:
			if b.is_in_group("enemies"):
				b.take_damage(int(skill.damage))
		timer += 1.0
	
	area.queue_free()

# ============ 伤害计算 ============
func _calculate_damage(base: int, is_magic: bool = false) -> int:
	var dmg = base
	if is_magic:
		dmg += magic_power
	
	# 暴击
	if randf() < crit_rate:
		dmg = int(dmg * crit_damage)
	
	# Buff
	if active_buffs.has("power"):
		dmg = int(dmg * active_buffs["power"].effect.get("multiplier", 1.5))
	
	return dmg

# ============ Buff ============
func _add_buff(name: String, duration: float, effect: Dictionary):
	active_buffs[name] = {"duration": duration, "effect": effect}
	emit_signal("buff_added", name)

func _remove_buff(name: String):
	active_buffs.erase(name)
	emit_signal("buff_removed", name)

# ============ 受伤 ============
func take_damage(dmg: int):
	if invincible: return
	
	var actual = max(1, dmg - defense)
	
	if active_buffs.has("shield"):
		var s = active_buffs["shield"].effect.shield
		if s >= actual:
			active_buffs["shield"].effect.shield = s - actual
			actual = 0
		else:
			actual -= s
			_remove_buff("shield")
	
	if actual > 0:
		current_hp -= actual
		total_damage_taken += actual
		invincible = true
		invincible_timer = 0.3
	
	emit_signal("hp_changed", current_hp, max_hp)
	if current_hp <= 0: die()

func heal(amount: int):
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)

# ============ 升级 ============
func add_exp(amt: int):
	current_exp += amt
	emit_signal("exp_changed", current_exp, get_exp_needed())
	while current_exp >= get_exp_needed():
		current_exp -= get_exp_needed()
		_on_level_up()

func _on_level_up():
	level += 1
	match current_class:
		ClassType.SWORD:
			max_hp += 25; max_mp += 10; attack_power += 6; defense += 3
		ClassType.MAGE:
			max_hp += 15; max_mp += 30; magic_power += 8
		ClassType.TAOIST:
			max_hp += 20; max_mp += 20; magic_power += 5; defense += 2
	
	current_hp = max_hp
	current_mp = max_mp
	attack_speed = min(3.0, attack_speed + 0.05)
	attack_interval = 1.0 / attack_speed
	
	emit_signal("level_up", level)
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("mp_changed", current_mp, max_mp)

func get_exp_needed() -> int:
	return int(level * 100 * pow(1.1, level - 1))

# ============ 金币 ============
func add_gold(amt: int):
	gold += amt
	emit_signal("gold_changed", gold)

# ============ 死亡 ============
func die():
	emit_signal("player_died")
	_unlock_target()
	# 清除召唤物
	for s in summons:
		if is_instance_valid(s): s.queue_free()
	summons.clear()

func revive(full: bool = false):
	current_hp = int(max_hp * (1.0 if full else 0.3))
	current_mp = int(max_mp * (1.0 if full else 0.5))
	invincible = true
	invincible_timer = 3.0

# ============ 存档 ============
func _auto_save():
	if SaveManager: SaveManager.auto_save(self)

func _load_from_save():
	if SaveManager and SaveManager.has_save():
		SaveManager.load_to_player(self)

func get_save_data() -> Dictionary:
	return {
		"hp": current_hp, "max_hp": max_hp,
		"mp": current_mp, "max_mp": max_mp,
		"level": level, "exp": current_exp,
		"gold": gold, "class": current_class,
		"attack_power": attack_power, "magic_power": magic_power,
		"defense": defense, "position": {"x": global_position.x, "y": global_position.y}
	}

func load_from_data(data: Dictionary):
	current_hp = data.get("hp", max_hp)
	max_hp = data.get("max_hp", max_hp)
	current_mp = data.get("mp", max_mp)
	max_mp = data.get("max_mp", max_mp)
	level = data.get("level", 1)
	current_exp = data.get("exp", 0)
	gold = data.get("gold", 0)
	
	if data.has("class"):
		set_class(data["class"])
	
	attack_power = data.get("attack_power", 10)
	magic_power = data.get("magic_power", 0)
	defense = data.get("defense", 5)
	
	if data.has("position"):
		global_position = Vector2(data.position.x, data.position.y)
	
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("mp_changed", current_mp, max_mp)
