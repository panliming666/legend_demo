extends Node

class_name AutoBattleSystem

# 自动战斗系统

signal auto_battle_started()
signal auto_battle_stopped()
signal target_changed(new_target: String)

# 自动战斗状态
var is_auto_battling: bool = false
var current_target: Node = null

# 自动战斗设置
var settings: Dictionary = {
	"auto_attack": true,
	"auto_use_skill": true,
	"auto_pickup": true,
	"auto_heal": true,
	"heal_threshold": 0.3,
	"target_priority": "nearest",  # nearest, weakest, strongest
	"skill_rotation": [1, 2, 3, 4],  # 技能释放顺序
	"range": 300  # 索敌范围
}

func _ready():
	pass

func _process(delta):
	if is_auto_battling:
		auto_battle_tick(delta)

# 开始自动战斗
func start_auto_battle():
	is_auto_battling = true
	emit_signal("auto_battle_started")
	print("自动战斗已开启")

# 停止自动战斗
func stop_auto_battle():
	is_auto_battling = false
	current_target = null
	emit_signal("auto_battle_stopped")
	print("自动战斗已关闭")

# 切换自动战斗
func toggle_auto_battle() -> bool:
	if is_auto_battling:
		stop_auto_battle()
		return false
	else:
		start_auto_battle()
		return true

# 自动战斗逻辑
func auto_battle_tick(delta: float):
	# 这里需要与玩家系统交互
	# 简化逻辑
	
	# 1. 检查血量，需要治疗
	if settings.auto_heal:
		if should_heal():
			use_heal_skill()
			return
	
	# 2. 寻找目标
	if current_target == null or not is_instance_valid(current_target):
		current_target = find_target()
		if current_target:
			emit_signal("target_changed", current_target.name if current_target.has("name") else "Target")
	
	# 3. 攻击目标
	if current_target and is_instance_valid(current_target):
		attack_target(current_target)
	else:
		# 没有目标，移动寻找
		wander()

# 检查是否需要治疗
func should_heal() -> bool:
	# 需要与玩家系统交互
	return false

# 使用治疗技能
func use_heal_skill():
	# 需要与技能系统交互
	print("使用治疗技能")

# 寻找目标
func find_target() -> Node:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	var player = get_tree().get_first_node_in_group("players")
	if not player:
		return null
	
	var best_target = null
	var best_value = 0
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance > settings.range:
			continue
		
		match settings.target_priority:
			"nearest":
				if best_target == null or distance < best_value:
					best_target = enemy
					best_value = distance
			"weakest":
				var hp = enemy.get("current_hp") if enemy.has("current_hp") else 9999
				if best_target == null or hp < best_value:
					best_target = enemy
					best_value = hp
			"strongest":
				var hp = enemy.get("current_hp") if enemy.has("current_hp") else 0
				if best_target == null or hp > best_value:
					best_target = enemy
					best_value = hp
	
	return best_target

# 攻击目标
func attack_target(target: Node):
	if settings.auto_use_skill:
		# 尝试使用技能
		for skill_slot in settings.skill_rotation:
			if can_use_skill(skill_slot):
				use_skill(skill_slot)
				return
	
	# 使用普通攻击
	normal_attack(target)

# 普通攻击
func normal_attack(target: Node):
	# 需要与玩家系统交互
	print("普通攻击", target.name if target.has("name") else "Target")

# 检查是否可以使用技能
func can_use_skill(skill_slot: int) -> bool:
	# 需要与技能系统交互
	return false

# 使用技能
func use_skill(skill_slot: int):
	# 需要与技能系统交互
	print("使用技能", skill_slot)

# 闲逛（寻找目标）
func wander():
	# 简单实现：随机移动
	print("寻找目标中...")

# 获取设置
func get_settings() -> Dictionary:
	return settings.duplicate()

# 更新设置
func update_settings(new_settings: Dictionary):
	for key in new_settings.keys():
		if settings.has(key):
			settings[key] = new_settings[key]
