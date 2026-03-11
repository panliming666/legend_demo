extends CharacterBody2D

# 三清问道 - 玩家控制器（传奇风格即时战斗）
# HD-2D修仙游戏主角

signal hp_changed(current: int, max_hp: int)
signal mp_changed(current: int, max_mp: int)
signal exp_changed(current: int, max_exp: int)
signal level_up(new_level: int)
signal player_died()
signal gold_changed(amount: int)
signal buff_added(buff_name: String)
signal buff_removed(buff_name: String)
signal target_locked(enemy)
signal target_unlocked()

# ============ 基础属性 ============
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var attack_power: int = 10
@export var defense: int = 5
@export var speed: float = 200.0
@export var crit_rate: float = 0.05
@export var crit_damage: float = 1.5

# 攻击速度（传奇风格：每秒攻击次数）
@export var attack_speed: float = 1.0  # 1次/秒
var attack_interval: float = 1.0  # 攻击间隔

# 当前状态
var current_hp: int
var current_mp: int
var current_exp: int = 0
var level: int = 1
var gold: int = 0

# ============ 移动系统 ============
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var mouse_control: bool = true

# ============ 战斗系统（传奇风格） ============
var locked_target: Node = null  # 锁定的目标
var is_auto_attacking: bool = false  # 自动攻击状态
var attack_cooldown: float = 0.0  # 攻击冷却
var is_attacking: bool = false  # 攻击中
var combo_count: int = 0  # 连击数

# 攻击范围
var normal_attack_range: float = 50.0  # 普通攻击范围
var skill_attack_range: float = 150.0  # 技能攻击范围

# ============ 技能系统 ============
var skills: Array = []
var skill_cooldowns: Dictionary = {}

# Buff/Debuff
var active_buffs: Dictionary = {}

# 无敌状态
var invincible: bool = false
var invincible_timer: float = 0.0

# 统计
var total_kills: int = 0
var total_damage_dealt: int = 0
var total_damage_taken: int = 0

# 自动存档
var auto_save_timer: float = 0.0
const AUTO_SAVE_INTERVAL: float = 60.0

# ============ 初始化 ============
func _ready():
	current_hp = max_hp
	current_mp = max_mp
	attack_interval = 1.0 / attack_speed
	add_to_group("player")
	
	_init_skills()
	set_process_input(true)
	_load_from_save()
	
	print("玩家已就绪 - Lv.", level)

func _init_skills():
	skills = [
		{"name": "普攻", "damage": attack_power, "cooldown": 0, "mp_cost": 0, "type": "attack", "range": normal_attack_range},
		{"name": "烈焰斩", "damage": attack_power * 2, "cooldown": 3.0, "mp_cost": 10, "type": "attack", "range": skill_attack_range},
		{"name": "雷霆一击", "damage": attack_power * 3, "cooldown": 5.0, "mp_cost": 20, "type": "aoe", "range": skill_attack_range * 1.5},
		{"name": "护盾", "damage": 0, "cooldown": 10.0, "mp_cost": 15, "type": "defense", "range": 0},
		{"name": "大招", "damage": attack_power * 5, "cooldown": 30.0, "mp_cost": 50, "type": "ultimate", "range": skill_attack_range * 2}
	]
	
	for i in range(skills.size()):
		skill_cooldowns[i] = 0.0

# ============ 主循环 ============
func _physics_process(delta):
	# 更新冷却
	_update_cooldowns(delta)
	
	# 更新无敌
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
	
	# 更新Buff
	_update_buffs(delta)
	
	# 传奇风格：自动攻击逻辑
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
	
	# 攻击冷却
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

# ============ 传奇风格：自动攻击系统 ============
func _auto_attack_logic(delta):
	if not locked_target or not is_instance_valid(locked_target):
		_unlock_target()
		return
	
	var distance = global_position.distance_to(locked_target.global_position)
	
	# 如果在攻击范围内，停止移动并攻击
	if distance <= normal_attack_range:
		# 停止移动
		is_moving = false
		velocity = Vector2.ZERO
		
		# 执行自动攻击
		if attack_cooldown <= 0:
			_perform_normal_attack()
	else:
		# 距离太远，追逐目标
		var direction = (locked_target.global_position - global_position).normalized()
		velocity = direction * speed

# 执行普通攻击
func _perform_normal_attack():
	if not locked_target or not is_instance_valid(locked_target):
		return
	
	# 攻击间隔
	attack_cooldown = attack_interval
	
	# 计算伤害
	var damage = _calculate_damage(attack_power)
	
	# 朝向目标
	_look_at_target(locked_target)
	
	# 造成伤害
	if locked_target.has_method("take_damage"):
		locked_target.take_damage(damage)
		total_damage_dealt += damage
	
	# 连击
	combo_count += 1
	if combo_count >= 3:
		# 第3下触发额外伤害
		locked_target.take_damage(int(damage * 0.5))
		combo_count = 0
	
	print("普攻命中！伤害:", damage)

# 计算最终伤害
func _calculate_damage(base_damage: int) -> int:
	var damage = base_damage
	
	# 暴击
	if randf() < crit_rate:
		damage = int(damage * crit_damage)
		print("暴击！")
	
	# Buff加成
	if active_buffs.has("power_up"):
		damage = int(damage * active_buffs["power_up"].effect.get("attack_multiplier", 1.5))
	
	return damage

# 朝向目标
func _look_at_target(target: Node):
	if target:
		var direction = (target.global_position - global_position).normalized()
		# 对于Sprite可以设置朝向
		pass

# ============ 输入处理 ============
func _input(event):
	# 鼠标点击 - 锁定目标
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 点击位置
				var click_pos = get_global_mouse_position()
				_lock_target_at_position(click_pos)
			else:
				# 松开时停止移动
				is_moving = false
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# 右键 - 取消锁定
			if event.pressed:
				_unlock_target()
	
	# 键盘移动
	if event.is_action_pressed("move_left"):
		target_position = global_position + Vector2(-100, 0)
		is_moving = true
		mouse_control = false
	elif event.is_action_pressed("move_right"):
		target_position = global_position + Vector2(100, 0)
		is_moving = true
		mouse_control = false
	elif event.is_action_pressed("move_up"):
		target_position = global_position + Vector2(0, -100)
		is_moving = true
		mouse_control = false
	elif event.is_action_pressed("move_down"):
		target_position = global_position + Vector2(0, 100)
		is_moving = true
		mouse_control = false
	
	# 技能快捷键
	if event.is_action_pressed("skill_1"):
		use_skill(0)
	elif event.is_action_pressed("skill_2"):
		use_skill(1)
	elif event.is_action_pressed("skill_3"):
		use_skill(2)
	elif event.is_action_pressed("skill_4"):
		use_skill(3)

# 锁定目标（传奇风格）
func _lock_target_at_position(world_pos: Vector2):
	# 查找点击位置附近的敌人
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_distance = 50.0  # 点击容差范围
	
	for enemy in enemies:
		var distance = enemy.global_position.distance_to(world_pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	if closest_enemy:
		_lock_target(closest_enemy)
	else:
		# 没有敌人，设置为移动目标
		target_position = world_pos
		is_moving = true

# 锁定目标
func _lock_target(enemy: Node):
	if locked_target == enemy:
		return
	
	locked_target = enemy
	is_auto_attacking = true
	emit_signal("target_locked", enemy)
	print("锁定目标: ", enemy.name)

# 解除锁定
func _unlock_target():
	if locked_target:
		locked_target = null
		is_auto_attacking = false
		emit_signal("target_unlocked")
		print("解除锁定")

# ============ 移动系统 ============
func _mouse_movement(delta):
	if is_moving and target_position != Vector2.ZERO:
		# 如果有锁定目标且不在攻击范围内，优先走向目标
		if locked_target and is_instance_valid(locked_target):
			var dist_to_target = global_position.distance_to(locked_target.global_position)
			if dist_to_target > normal_attack_range:
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
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * speed
		# 移动时取消锁定
		if locked_target:
			_unlock_target()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5)

# ============ 技能系统 ============
func use_skill(skill_index: int):
	if skill_index >= skills.size():
		return
	
	var skill = skills[skill_index]
	
	# 检查冷却
	if skill_cooldowns[skill_index] > 0:
		print("技能冷却中: ", skill_cooldowns[skill_index])
		return
	
	# 检查蓝量
	if current_mp < skill.mp_cost:
		print("蓝量不足")
		return
	
	# 检查范围（传奇风格：需要朝向目标或目标在范围内）
	var can_use = false
	match skill.type:
		"attack", "aoe", "ultimate":
			if locked_target and is_instance_valid(locked_target):
				var distance = global_position.distance_to(locked_target.global_position)
				can_use = distance <= skill.range
			else:
				# 没有锁定目标则攻击鼠标位置
				can_use = true
		"defense":
			can_use = true
	
	if not can_use:
		print("目标距离太远")
		return
	
	# 消耗
	current_mp -= skill.mp_cost
	skill_cooldowns[skill_index] = skill.cooldown
	emit_signal("mp_changed", current_mp, max_mp)
	
	# 执行技能
	_execute_skill(skill)

func _execute_skill(skill: Dictionary):
	match skill.type:
		"attack":
			# 单体攻击
			if locked_target and is_instance_valid(locked_target):
				var damage = _calculate_damage(skill.damage)
				locked_target.take_damage(damage)
				total_damage_dealt += damage
				print("技能命中: ", skill.name, " 伤害: ", damage)
		
		"aoe":
			# 范围攻击
			_skill_aoe_attack(skill)
		
		"defense":
			# 防御技能
			_activate_shield(skill.get("shield_amount", 50))
			print("使用技能: ", skill.name)
		
		"ultimate":
			# 大招
			_skill_ultimate(skill)

# 范围攻击
func _skill_aoe_attack(skill: Dictionary):
	var center_pos = locked_target.global_position if locked_target else global_position
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= skill.range:
			var damage = _calculate_damage(skill.damage)
			enemy.take_damage(damage)
			total_damage_dealt += damage
			hit_count += 1
	
	print("AOE命中", hit_count, "个敌人")

# 大招
func _skill_ultimate(skill: Dictionary):
	# 先给自己加buff
	_add_buff("ultimate_power", 10.0, {"attack_multiplier": 2.0})
	
	# 然后范围攻击
	_skill_aoe_attack(skill)

# ============ Buff系统 ============
func _add_buff(buff_name: String, duration: float, effect: Dictionary):
	active_buffs[buff_name] = {
		"duration": duration,
		"effect": effect
	}
	emit_signal("buff_added", buff_name)

func _remove_buff(buff_name: String):
	if active_buffs.has(buff_name):
		active_buffs.erase(buff_name)
		emit_signal("buff_removed", buff_name)

func _activate_shield(amount: int):
	_add_buff("shield", 15.0, {"shield_amount": amount})
	max_hp += amount
	current_hp += amount

# ============ 受伤/治疗 ============
func take_damage(damage: int):
	if invincible:
		return
	
	var actual_damage = max(1, damage - defense)
	
	# 护盾
	if active_buffs.has("shield"):
		var shield = active_buffs["shield"].effect.shield_amount
		if shield >= actual_damage:
			active_buffs["shield"].effect.shield_amount = shield - actual_damage
			actual_damage = 0
		else:
			actual_damage -= shield
			_remove_buff("shield")
	
	if actual_damage > 0:
		current_hp -= actual_damage
		total_damage_taken += actual_damage
		invincible = true
		invincible_timer = 0.3  # 受伤后0.3秒无敌
	
	emit_signal("hp_changed", current_hp, max_hp)
	
	if current_hp <= 0:
		die()

func heal(amount: int):
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)

func restore_mp(amount: int):
	current_mp = min(current_mp + amount, max_mp)
	emit_signal("mp_changed", current_mp, max_mp)

# ============ 经验/升级 ============
func add_exp(amount: int):
	current_exp += amount
	emit_signal("exp_changed", current_exp, get_exp_for_level(level + 1))
	
	while current_exp >= get_exp_for_level(level + 1):
		current_exp -= get_exp_for_level(level + 1)
		_on_level_up()

func _on_level_up():
	level += 1
	max_hp += 25 + level * 2
	max_mp += 15 + level
	attack_power += 5 + int(level / 3)
	defense += 2 + int(level / 5)
	attack_speed = min(3.0, attack_speed + 0.05)  # 攻速提升
	
	current_hp = max_hp
	current_mp = max_mp
	
	attack_interval = 1.0 / attack_speed
	
	emit_signal("level_up", level)
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("mp_changed", current_mp, max_mp)
	print("升级！Lv.", level)

func get_exp_for_level(lvl: int) -> int:
	return int(lvl * 100 * pow(1.1, lvl - 1))

# ============ 金币 ============
func add_gold(amount: int):
	gold += amount
	emit_signal("gold_changed", gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		emit_signal("gold_changed", gold)
		return true
	return false

# ============ 死亡 ============
func die():
	emit_signal("player_died")
	print("玩家死亡")
	_unlock_target()

func revive(full: bool = false):
	current_hp = int(max_hp * (1.0 if full else 0.3))
	current_mp = int(max_mp * (1.0 if full else 0.5))
	invincible = true
	invincible_timer = 3.0
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("mp_changed", current_mp, max_mp)

# ============ 存档 ============
func _auto_save():
	if SaveManager:
		SaveManager.auto_save(self)

func _load_from_save():
	if SaveManager and SaveManager.has_save():
		SaveManager.load_to_player(self)

func get_save_data() -> Dictionary:
	return {
		"hp": current_hp, "max_hp": max_hp,
		"mp": current_mp, "max_mp": max_mp,
		"level": level, "exp": current_exp,
		"gold": gold, "attack_power": attack_power,
		"defense": defense, "attack_speed": attack_speed,
		"position": {"x": global_position.x, "y": global_position.y}
	}

func load_from_data(data: Dictionary):
	current_hp = data.get("hp", max_hp)
	max_hp = data.get("max_hp", max_hp)
	current_mp = data.get("mp", max_mp)
	max_mp = data.get("max_mp", max_mp)
	level = data.get("level", 1)
	current_exp = data.get("exp", 0)
	gold = data.get("gold", 0)
	attack_power = data.get("attack_power", 10)
	defense = data.get("defense", 5)
	attack_speed = data.get("attack_speed", 1.0)
	attack_interval = 1.0 / attack_speed
	
	if data.has("position"):
		global_position = Vector2(data.position.x, data.position.y)
	
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("mp_changed", current_mp, max_mp)

# ============ 统计 ============
func on_kill_enemy():
	total_kills += 1

func get_stats() -> Dictionary:
	return {
		"level": level, "hp": current_hp, "max_hp": max_hp,
		"mp": current_mp, "max_mp": max_mp,
		"gold": gold, "attack": attack_power,
		"defense": defense, "attack_speed": attack_speed,
		"kills": total_kills, "damage_dealt": total_damage_dealt,
		"target": locked_target.name if locked_target else "无"
	}
