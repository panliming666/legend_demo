extends Node

class_name RoguelikeSystem

# Roguelike模式 - 单机核心玩法

signal run_started(seed: int)
signal room_entered(room_type: String, floor: int)
signal run_completed(success: bool, floor_reached: int)
signal relic_acquired(relic_id: String, relic_name: String)

# 房间类型
enum RoomType {
	NORMAL,    # 普通战斗
	ELITE,     # 精英战斗
	BOSS,      # Boss战
	REST,      # 休息房间
	SHOP,      # 商店
	EVENT,     # 随机事件
	TREASURE   # 宝箱
}

# 遗物（Roguelike特色）
var relic_database: Dictionary = {
	"relic_1": {"name": "狂暴之血", "effect": {"crit_damage": 0.5}, "rarity": "common", "description": "暴击伤害+50%"},
	"relic_2": {"name": "铁壁", "effect": {"defense": 20}, "rarity": "common", "description": "防御+20"},
	"relic_3": {"name": "生命源泉", "effect": {"hp_regen": 5}, "rarity": "common", "description": "每秒恢复5生命"},
	"relic_4": {"name": "法力潮汐", "effect": {"mp_regen": 3}, "rarity": "common", "description": "每秒恢复3法力"},
	"relic_5": {"name": "火焰之心", "effect": {"fire_damage": 0.3}, "rarity": "rare", "description": "火系伤害+30%"},
	"relic_6": {"name": "雷霆之怒", "effect": {"thunder_damage": 0.3}, "rarity": "rare", "description": "雷系伤害+30%"},
	"relic_7": {"name": "寒冰之核", "effect": {"ice_damage": 0.3, "slow_effect": 0.2}, "rarity": "rare", "description": "冰系伤害+30%，减速+20%"},
	"relic_8": {"name": "吸血獠牙", "effect": {"life_steal": 0.1}, "rarity": "rare", "description": "10%伤害转化为生命"},
	"relic_9": {"name": "连击护符", "effect": {"double_attack": 0.15}, "rarity": "epic", "description": "15%几率连击"},
	"relic_10": {"name": "反伤刺甲", "effect": {"thorn_damage": 0.2}, "rarity": "epic", "description": "反弹20%伤害"},
	"relic_11": {"name": "时间沙漏", "effect": {"cooldown_reduction": 0.25}, "rarity": "epic", "description": "技能冷却-25%"},
	"relic_12": {"name": "神圣护盾", "effect": {"shield": 100, "shield_regen": 10}, "rarity": "legendary", "description": "获得100护盾，每秒恢复10"},
	"relic_13": {"name": "混沌之种", "effect": {"all_damage": 0.5, "defense": -10}, "rarity": "legendary", "description": "全伤害+50%，防御-10"},
	"relic_14": {"name": "不朽之心", "effect": {"revive": 1, "hp_bonus": 0.3}, "rarity": "legendary", "description": "复活1次，生命上限+30%"}
}

# 当前Run状态
var current_run: Dictionary = {
	"active": false,
	"seed": 0,
	"floor": 1,
	"max_floor": 50,
	"hp": 100,
	"max_hp": 100,
	"relics": [],
	"rooms_cleared": 0,
	"current_room": null,
	"map": []  # 当前层地图
}

# 历史记录
var best_runs: Array = []  # {floor, rooms, time, relics}

func _ready():
	load_roguelike_data()

# 开始新Run
func start_new_run() -> Dictionary:
	var seed = randi()
	seed(seed)
	
	current_run = {
		"active": true,
		"seed": seed,
		"floor": 1,
		"max_floor": 50,
		"hp": 100,  # 基础生命
		"max_hp": 100,
		"relics": [],
		"rooms_cleared": 0,
		"current_room": null,
		"map": generate_floor_map(1),
		"start_time": Time.get_unix_time_from_system()
	}
	
	emit_signal("run_started", seed)
	
	return {
		"success": true,
		"seed": seed,
		"first_room": current_run.map[0]
	}

# 生成楼层地图
func generate_floor_map(floor: int) -> Array:
	var rooms = []
	var room_count = 3 + floor / 5  # 层数越高房间越多
	
	# 必定有Boss房间
	rooms.append({"type": RoomType.BOSS, "cleared": false})
	
	# 随机其他房间
	for i in range(room_count - 1):
		var roll = randf()
		var room_type = RoomType.NORMAL
		
		if roll < 0.1:
			room_type = RoomType.TREASURE
		elif roll < 0.2:
			room_type = RoomType.EVENT
		elif roll < 0.3:
			room_type = RoomType.SHOP
		elif roll < 0.4 and floor > 5:
			room_type = RoomType.REST
		elif roll < 0.55 and floor > 3:
			room_type = RoomType.ELITE
		
		rooms.insert(0, {"type": room_type, "cleared": false})
	
	return rooms

# 进入房间
func enter_room(room_index: int) -> Dictionary:
	if not current_run.active:
		return {"success": false, "message": "Run未开始"}
	
	if room_index < 0 or room_index >= current_run.map.size():
		return {"success": false, "message": "房间不存在"}
	
	var room = current_run.map[room_index]
	
	if room.cleared:
		return {"success": false, "message": "房间已完成"}
	
	current_run.current_room = room_index
	
	emit_signal("room_entered", RoomType.keys()[room.type], current_run.floor)
	
	return {
		"success": true,
		"room_type": room.type,
		"room_name": get_room_name(room.type)
	}

# 完成房间
func complete_room(room_index: int, victory: bool = true) -> Dictionary:
	if not current_run.active:
		return {"success": false, "message": "Run未开始"}
	
	var room = current_run.map[room_index]
	
	if victory:
		room.cleared = true
		current_run.rooms_cleared += 1
		
		# 房间奖励
		var rewards = get_room_rewards(room.type)
		
		# 精英和Boss房间给遗物
		if room.type == RoomType.ELITE or room.type == RoomType.BOSS:
			var relic = give_random_relic()
			rewards["relic"] = relic
		
		# 检查是否完成本层
		if room_index == current_run.map.size() - 1:
			return next_floor()
		
		return {
			"success": true,
			"rewards": rewards,
			"next_room_available": true
		}
	else:
		# 失败，结束Run
		return end_run(false)

# 获取房间奖励
func get_room_rewards(room_type: int) -> Dictionary:
	var rewards = {"exp": 50, "gold": 20}
	
	match room_type:
		RoomType.NORMAL:
			rewards.exp = 50
			rewards.gold = 20
		RoomType.ELITE:
			rewards.exp = 150
			rewards.gold = 60
		RoomType.BOSS:
			rewards.exp = 500
			rewards.gold = 200
		RoomType.TREASURE:
			rewards.items = ["灵石×10", "灵草×5"]
		RoomType.SHOP:
			rewards.shop_available = true
		RoomType.REST:
			rewards.heal = 30  # 恢复30%生命
		RoomType.EVENT:
			rewards.random = true
	
	return rewards

# 进入下一层
func next_floor() -> Dictionary:
	current_run.floor += 1
	
	if current_run.floor > current_run.max_floor:
		# 通关！
		return end_run(true)
	
	# 生成新层地图
	current_run.map = generate_floor_map(current_run.floor)
	
	return {
		"success": true,
		"new_floor": current_run.floor,
		"message": "进入第%d层" % current_run.floor
	}

# 获取随机遗物
func give_random_relic() -> Dictionary:
	var relics = relic_database.keys()
	var selected = relics[randi() % relics.size()]
	var relic = relic_database[selected]
	
	current_run.relics.append(selected)
	
	emit_signal("relic_acquired", selected, relic.name)
	
	return {
		"id": selected,
		"name": relic.name,
		"effect": relic.effect,
		"description": relic.description
	}

# 计算遗物总效果
func calculate_relic_effects() -> Dictionary:
	var total_effects: Dictionary = {}
	
	for relic_id in current_run.relics:
		var relic = relic_database[relic_id]
		for key in relic.effect.keys():
			if not total_effects.has(key):
				total_effects[key] = 0
			total_effects[key] += relic.effect[key]
	
	return total_effects

# 结束Run
func end_run(victory: bool) -> Dictionary:
	current_run.active = false
	
	var end_time = Time.get_unix_time_from_system()
	var duration = end_time - current_run.start_time
	
	var result = {
		"victory": victory,
		"floor_reached": current_run.floor,
		"rooms_cleared": current_run.rooms_cleared,
		"relics_collected": current_run.relics.size(),
		"duration": duration,
		"relics": current_run.relics.duplicate()
	}
	
	# 记录最佳成绩
	best_runs.append(result)
	best_runs.sort_custom(func(a, b): return a.floor_reached > b.floor_reached)
	if best_runs.size() > 10:
		best_runs.resize(10)
	
	emit_signal("run_completed", victory, current_run.floor)
	save_roguelike_data()
	
	return {
		"success": true,
		"result": result,
		"new_record": is_new_record(result)
	}

# 是否是新纪录
func is_new_record(result: Dictionary) -> bool:
	if best_runs.is_empty():
		return true
	return result.floor_reached > best_runs[0].floor_reached

# 获取房间名称
func get_room_name(room_type: int) -> String:
	match room_type:
		RoomType.NORMAL: return "战斗房间"
		RoomType.ELITE: return "精英房间"
		RoomType.BOSS: return "Boss房间"
		RoomType.REST: return "休息房间"
		RoomType.SHOP: return "商店"
		RoomType.EVENT: return "事件房间"
		RoomType.TREASURE: return "宝箱房间"
	return "未知房间"

# 保存/加载
func save_roguelike_data():
	var config = ConfigFile.new()
	config.set_value("roguelike", "best_runs", best_runs)
	config.save("user://roguelike.cfg")

func load_roguelike_data():
	if FileAccess.file_exists("user://roguelike.cfg"):
		var config = ConfigFile.new()
		if config.load("user://roguelike.cfg") == OK:
			best_runs = config.get_value("roguelike", "best_runs", [])
