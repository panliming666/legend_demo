extends CharacterBody2D

# 三清问道 - 玩家控制器（优化版）
# HD-2D修仙游戏主角

signal hp_changed(current: int, max_hp: int)
signal mp_changed(current: int, max_mp: int)
signal exp_changed(current: int, max_exp: int)
signal level_up(new_level: int)
signal player_died()
signal gold_changed(amount: int)
signal buff_added(buff_name: String)
signal buff_removed(buff_name: String)

# ============ 基础属性 ============
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var attack_power: int = 10
@export var defense: int = 5
@export var speed: float = 200.0
@export var crit_rate: float = 0.05  # 5%暴击率
@export var crit_damage: float = 1.5  # 150%暴击伤害

# 当前状态
var current_hp: int
var current_mp: int
var current_exp: int = 0
var level: int = 1
var gold: int = 0

# 移动
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var mouse_control: bool = true  # 鼠标控制模式

# 战斗
var attack_cooldown: float = 0.0
var is_attacking: bool = false
var combo_count: int = 0
var invincible: bool = false  # 无敌状态
var invincible_timer: float = 0.0

# 技能
var skills: Array = []
var skill_cooldowns: Dictionary = {}

# Buff/Debuff系统
var active_buffs: Dictionary = {}  # buff_name: {duration, effect}

# 统计
var total_kills: int = 0
var total_damage_dealt: int = 0
var total_damage_taken: int = 0

# 存档自动保存计时器
var auto_save_timer: float = 0.0
const AUTO_SAVE_INTERVAL: float = 60.0  # 60秒自动保存

# ============ 初始化 ============
func _ready():
	current_hp = max_hp
	current_mp = max_mp
	add_to_group("player")
	
	# 初始化技能
	_init_skills()
	
	# 连接输入
	set_process_input(true)
	
	# 尝试加载存档
	_load_from_save()
	
	print("玩家已就绪 - Lv.", level)

func _init_skills():
	# 根据职业初始化技能（可扩展）
	skills = [
		{"name": "普攻", "damage": attack_power, "cooldown": 0.5, "mp_cost": 0, "type": "attack"},
		{"name": "烈焰斩", "damage": attack_power * 2, "cooldown": 3.0, "mp_cost": 10, "type": "attack"},
		{"name": "护盾", "damage": 0, "cooldown": 10.0, "mp_cost": 20, "type": "defense", "shield_amount": 50},
		{"name": "大招", "damage": attack_power * 5, "cooldown": 30.0, "mp_cost": 50, "type": "ultimate"}
	]
	
	for i in range(skills.size()):
		skill_cooldowns[i] = 0.0

# ============ 主循环 ============
func _physics_process(delta):
	# 更新冷却
	_update_cooldowns(delta)
	
	# 更新无敌时间
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
	
	# 更新Buff
	_update_buffs(delta)
	
	# 移动处理
	if mouse_control:
		_mouse_movement(delta)
	else:
		_keyboard_movement(delta)
	
	move_and_slide()
	
	# 攻击冷却
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# 自动保存
	auto_save_timer += delta
	if auto_save_timer >= AUTO_SAVE_INTERVAL:
		auto_save_timer = 0.0
		_auto_save()

func _update_cooldowns(delta):
	for i in skill_cooldowns.keys():
		if skill_cooldowns[i] > 0:
			skill_cooldowns[i] -= delta

func _update_buffs(delta):
	var expired_buffs = []
	for buff_name in active_buffs.keys():
		active_buffs[buff_name].duration -= delta
		if active_buffs[buff_name].duration <= 0:
			expired_buffs.append(buff_name)
	
	for buff_name in expired_buffs:
		_remove_buff(buff_name)

# ============ 输入处理 ============
func _input(event):
	# 鼠标点击移动
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				target_position = get_global_mouse_position()
				is_moving = true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# 右键奔跑
			if event.pressed:
				speed = 350.0
			else:
				speed = 200.0
	
	# 技能快捷键
	if event.is_action_pressed("skill_1"):
		use_skill(0)
	elif event.is_action_pressed("skill_2"):
		use_skill(1)
	elif event.is_action_pressed("skill_3"):
		use_skill(2)
	elif event.is_action_pressed("skill_4"):
		use_skill(3)
	
	# 快速存档
	if event.is_action_pressed("save_game"):
		_auto_save()

# ============ 移动系统 ============
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
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5)

func _mouse_movement(delta):
	if is_moving and target_position != Vector2.ZERO:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > 5.0:
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO
			is_moving = false
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5)

# ============ 技能系统 ============
func use_skill(skill_index: int):
	if skill_index >= skills.size():
		return
	
	var skill = skills[skill_index]
	
	# 检查冷却
	if skill_cooldowns[skill_index] > 0:
		print("技能冷却中：", skill_cooldowns[skill_index])
		return
	
	# 检查蓝量
	if current_mp < skill.mp_cost:
		print("蓝量不足")
		return
	
	# 消耗蓝量
	current_mp -= skill.mp_cost
	skill_cooldowns[skill_index] = skill.cooldown
	
	# 执行技能
	_execute_skill(skill)
	
	emit_signal("mp_changed", current_mp, max_mp)
	print("使用技能：", skill.name)

func _execute_skill(skill: Dictionary):
	match skill.type:
		"attack":
			_attack_enemies(skill.damage)
		"defense":
			_activate_shield(skill.get("shield_amount", 50))
		"ultimate":
			_attack_enemies(skill.damage)
			_add_buff("power_up", 5.0, {"attack_multiplier": 1.5})

func _attack_enemies(damage: int):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance < 100:  # 攻击范围
			# 计算暴击
			var final_damage = damage
			if randf() < crit_rate:
				final_damage = int(damage * crit_damage)
				print("暴击！")
			
			# 应用buff效果
			if active_buffs.has("power_up"):
				final_damage = int(final_damage * active_buffs["power_up"].effect.get("attack_multiplier", 1.0))
			
			enemy.take_damage(final_damage)
			total_damage_dealt += final_damage
			hit_count += 1
	
	if hit_count > 0:
		print("攻击命中", hit_count, "个敌人")

func _activate_shield(amount: int):
	# 激活护盾buff
	_add_buff("shield", 10.0, {"shield_amount": amount})
	print("护盾已激活：", amount)

# ============ Buff系统 ============
func _add_buff(buff_name: String, duration: float, effect: Dictionary):
	active_buffs[buff_name] = {
		"duration": duration,
		"effect": effect
	}
	emit_signal("buff_added", buff_name)
	
	# 应用即时效果
	if buff_name == "shield":
		max_hp += effect.get("shield_amount", 0)

func _remove_buff(buff_name: String):
	if not active_buffs.has(buff_name):
		return
	
	# 移除效果
	if buff_name == "shield":
		max_hp -= active_buffs[buff_name].effect.get("shield_amount", 0)
		if current_hp > max_hp:
			current_hp = max_hp
	
	active_buffs.erase(buff_name)
	emit_signal("buff_removed", buff_name)

func has_buff(buff_name: String) -> bool:
	return active_buffs.has(buff_name)

# ============ 战斗系统 ============
func take_damage(damage: int):
	if invincible:
		return
	
	var actual_damage = max(1, damage - defense)
	
	# 护盾优先承受伤害
	if has_buff("shield"):
		var shield_amount = active_buffs["shield"].effect.get("shield_amount", 0)
		if shield_amount >= actual_damage:
			active_buffs["shield"].effect["shield_amount"] -= actual_damage
			actual_damage = 0
		else:
			actual_damage -= shield_amount
			_remove_buff("shield")
	
	current_hp -= actual_damage
	total_damage_taken += actual_damage
	
	# 受伤后短暂无敌
	invincible = true
	invincible_timer = 0.5
	
	emit_signal("hp_changed", current_hp, max_hp)
	
	if current_hp <= 0:
		die()

func heal(amount: int):
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)

func restore_mp(amount: int):
	current_mp = min(current_mp + amount, max_mp)
	emit_signal("mp_changed", current_mp, max_mp)

# ============ 经验/升级系统 ============
func add_exp(amount: int):
	current_exp += amount
	emit_signal("exp_changed", current_exp, get_exp_for_level(level + 1))
	
	var exp_needed = get_exp_for_level(level + 1)
	while current_exp >= exp_needed:
		current_exp -= exp_needed
		_on_level_up()
		exp_needed = get_exp_for_level(level + 1)

func _on_level_up():
	level += 1
	
	# 属性提升（可配置的成长曲线）
	max_hp += 20 + level * 2
	max_mp += 10 + level
	attack_power += 5 + int(level / 5)
	defense += 2 + int(level / 10)
	
	# 恢复满血满蓝
	current_hp = max_hp
	current_mp = max_mp
	
	emit_signal("level_up", level)
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("mp_changed", current_mp, max_mp)
	
	print("升级！等级：", level, " 属性已提升")

func get_exp_for_level(lvl: int) -> int:
	# 指数增长的经验需求
	return int(lvl * 100 * pow(1.1, lvl - 1))

# ============ 金币系统 ============
func add_gold(amount: int):
	gold += amount
	emit_signal("gold_changed", gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		emit_signal("gold_changed", gold)
		return true
	return false

# ============ 死亡/复活 ============
func die():
	emit_signal("player_died")
	print("玩家死亡")
	
	# 触发死亡惩罚
	var death_penalty = get_node_or_null("/root/DeathPenaltySystem")
	if death_penalty and death_penalty.has_method("on_player_death"):
		var penalty = death_penalty.on_player_death(level, current_exp, gold)
		_apply_death_penalty(penalty)

func _apply_death_penalty(penalty: Dictionary):
	# 应用惩罚
	if penalty.get("exp_lost", 0) > 0:
		current_exp = max(0, current_exp - penalty["exp_lost"])
	
	if penalty.get("gold_lost", 0) > 0:
		gold = max(0, gold - penalty["gold_lost"])
		emit_signal("gold_changed", gold)
	
	if penalty.get("level_lost", 0) > 0:
		level = max(1, level - penalty["level_lost"])
	
	# 恢复部分生命值复活
	current_hp = int(max_hp * 0.5)
	current_mp = int(max_mp * 0.5)
	
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("mp_changed", current_mp, max_mp)
	emit_signal("exp_changed", current_exp, get_exp_for_level(level + 1))

func revive(full_restore: bool = false):
	if full_restore:
		current_hp = max_hp
		current_mp = max_mp
	else:
		current_hp = int(max_hp * 0.3)
		current_mp = int(max_mp * 0.3)
	
	invincible = true
	invincible_timer = 2.0  # 复活后2秒无敌
	
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("mp_changed", current_mp, max_mp)

# ============ 存档系统 ============
func _auto_save():
	if SaveManager:
		SaveManager.auto_save(self)
		print("游戏已自动保存")

func _load_from_save():
	if SaveManager and SaveManager.has_save():
		SaveManager.load_to_player(self)
		print("存档已加载")

func get_save_data() -> Dictionary:
	return {
		"hp": current_hp,
		"max_hp": max_hp,
		"mp": current_mp,
		"max_mp": max_mp,
		"level": level,
		"exp": current_exp,
		"gold": gold,
		"attack_power": attack_power,
		"defense": defense,
		"position": {
			"x": global_position.x,
			"y": global_position.y
		},
		"total_kills": total_kills,
		"total_damage_dealt": total_damage_dealt,
		"total_damage_taken": total_damage_taken
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
	
	if data.has("position"):
		global_position = Vector2(data.position.x, data.position.y)
	
	total_kills = data.get("total_kills", 0)
	total_damage_dealt = data.get("total_damage_dealt", 0)
	total_damage_taken = data.get("total_damage_taken", 0)
	
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("mp_changed", current_mp, max_mp)
	emit_signal("exp_changed", current_exp, get_exp_for_level(level + 1))
	emit_signal("gold_changed", gold)

# ============ 统计 ============
func on_kill_enemy():
	total_kills += 1

func get_stats() -> Dictionary:
	return {
		"level": level,
		"exp": current_exp,
		"exp_needed": get_exp_for_level(level + 1),
		"hp": current_hp,
		"max_hp": max_hp,
		"mp": current_mp,
		"max_mp": max_mp,
		"gold": gold,
		"attack": attack_power,
		"defense": defense,
		"crit_rate": crit_rate,
		"speed": speed,
		"total_kills": total_kills,
		"total_damage_dealt": total_damage_dealt,
		"total_damage_taken": total_damage_taken
	}
