extends Node

class_name EndlessTowerSystem

# 无尽爬塔系统 - 单机后期核心玩法

signal tower_entered(floor: int)
signal floor_cleared(floor: int, rewards: Dictionary)
signal tower_record_broken(new_record: int)
signal boss_floor_reached(floor: int)

# 塔层配置
var floor_config: Dictionary = {
	"base_enemy_count": 3,
	"enemy_growth": 0.5,  # 每层增加0.5个敌人
	"hp_growth": 1.1,     # 每层血量增加10%
	"attack_growth": 1.05, # 每层攻击增加5%
	"boss_floor_interval": 10,  # 每10层Boss
	"reward_growth": 1.15  # 每层奖励增加15%
}

# 当前进度
var current_floor: int = 1
var highest_record: int = 1
var is_in_tower: bool = false

# 塔内状态
var tower_state: Dictionary = {
	"enemies_remaining": 0,
	"total_enemies": 0,
	"current_hp_percent": 100.0,
	"buffs": []  # 当前获得的增益
}

# 爬塔奖励池
var reward_pool: Dictionary = {
	"common": ["灵草", "灵石碎片"],
	"rare": ["灵芝", "灵玉"],
	"epic": ["仙草", "神铁"],
	"legendary": ["神草", "神玉"]
}

func _ready():
	load_tower_data()

# 进入爬塔
func enter_tower(start_floor: int = 1) -> Dictionary:
	if is_in_tower:
		return {"success": false, "message": "已在塔中"}
	
	current_floor = start_floor
	is_in_tower = true
	
	# 初始化该层
	init_floor(current_floor)
	
	emit_signal("tower_entered", current_floor)
	
	return {
		"success": true,
		"floor": current_floor,
		"is_boss_floor": is_boss_floor(current_floor),
		"enemy_count": tower_state.total_enemies,
		"message": "进入无尽塔第%d层" % current_floor
	}

# 初始化楼层
func init_floor(floor: int):
	var enemy_count = int(floor_config.base_enemy_count + floor * floor_config.enemy_growth)
	
	if is_boss_floor(floor):
		enemy_count = 1  # Boss层只有1个Boss
	
	tower_state.total_enemies = enemy_count
	tower_state.enemies_remaining = enemy_count
	tower_state.current_hp_percent = 100.0

# 计算敌人属性
func calculate_enemy_stats(floor: int) -> Dictionary:
	var multiplier = pow(floor_config.hp_growth, floor - 1)
	var attack_mult = pow(floor_config.attack_growth, floor - 1)
	
	var base_hp = 100
	var base_attack = 20
	
	if is_boss_floor(floor):
		multiplier *= 5  # Boss血量为5倍
		attack_mult *= 2  # Boss攻击为2倍
	
	return {
		"hp": int(base_hp * multiplier),
		"attack": int(base_attack * attack_mult),
		"defense": int(10 * multiplier * 0.5),
		"exp": int(50 * multiplier),
		"gold": int(20 * multiplier)
	}

# 击杀敌人
func enemy_killed() -> Dictionary:
	if not is_in_tower:
		return {"success": false, "message": "不在塔中"}
	
	tower_state.enemies_remaining -= 1
	
	# 计算即时奖励
	var enemy_stats = calculate_enemy_stats(current_floor)
	
	if tower_state.enemies_remaining <= 0:
		# 该层完成
		return complete_floor()
	
	return {
		"success": true,
		"enemies_left": tower_state.enemies_remaining,
		"exp_gained": enemy_stats.exp,
		"gold_gained": enemy_stats.gold
	}

# 完成楼层
func complete_floor() -> Dictionary:
	var is_boss = is_boss_floor(current_floor)
	var rewards = generate_floor_rewards(current_floor, is_boss)
	
	emit_signal("floor_cleared", current_floor, rewards)
	
	# 检查记录
	if current_floor > highest_record:
		highest_record = current_floor
		emit_signal("tower_record_broken", highest_record)
		print("新纪录！到达第%d层" % highest_record)
	
	# 进入下一层
	current_floor += 1
	init_floor(current_floor)
	
	if is_boss_floor(current_floor):
		emit_signal("boss_floor_reached", current_floor)
	
	return {
		"success": true,
		"next_floor": current_floor,
		"is_boss_floor": is_boss_floor(current_floor),
		"rewards": rewards,
		"new_record": current_floor > highest_record - 1
	}

# 生成楼层奖励
func generate_floor_rewards(floor: int, is_boss: bool) -> Dictionary:
	var multiplier = pow(floor_config.reward_growth, floor - 1)
	
	var rewards: Dictionary = {
		"exp": int(100 * multiplier),
		"gold": int(50 * multiplier),
		"items": []
	}
	
	# 根据层数决定奖励品质
	var roll = randf()
	var quality = "common"
	
	if is_boss:
		if roll < 0.3:
			quality = "legendary"
		elif roll < 0.6:
			quality = "epic"
		else:
			quality = "rare"
	else:
		if floor >= 50:
			if roll < 0.1:
				quality = "legendary"
			elif roll < 0.3:
				quality = "epic"
			elif roll < 0.6:
				quality = "rare"
		elif floor >= 20:
			if roll < 0.05:
				quality = "legendary"
			elif roll < 0.2:
				quality = "epic"
			elif roll < 0.5:
				quality = "rare"
		elif floor >= 10:
			if roll < 0.1:
				quality = "epic"
			elif roll < 0.3:
				quality = "rare"
	
	# 添加物品奖励
	var pool = reward_pool[quality]
	var item_count = 2 if is_boss else 1
	for i in range(item_count):
		var item = pool[randi() % pool.size()]
		rewards.items.append(item + "×" + str(int(multiplier)))
	
	return rewards

# 是否是Boss层
func is_boss_floor(floor: int) -> bool:
	return floor % floor_config.boss_floor_interval == 0

# 退出爬塔
func exit_tower():
	is_in_tower = false
	tower_state.enemies_remaining = 0
	save_tower_data()
	print("退出无尽塔")

# 获取当前状态
func get_tower_status() -> Dictionary:
	return {
		"in_tower": is_in_tower,
		"current_floor": current_floor,
		"highest_record": highest_record,
		"enemies_remaining": tower_state.enemies_remaining,
		"is_boss_floor": is_boss_floor(current_floor) if is_in_tower else false
	}

# 保存/加载
func save_tower_data():
	var config = ConfigFile.new()
	config.set_value("tower", "highest_record", highest_record)
	config.set_value("tower", "current_floor", current_floor)
	config.save("user://tower.cfg")

func load_tower_data():
	if FileAccess.file_exists("user://tower.cfg"):
		var config = ConfigFile.new()
		if config.load("user://tower.cfg") == OK:
			highest_record = config.get_value("tower", "highest_record", 1)
			current_floor = config.get_value("tower", "current_floor", 1)
