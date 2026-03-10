extends Node

class_name DungeonSystem

# 秘境副本系统

signal dungeon_entered(dungeon_name: String)
signal dungeon_cleared(dungeon_name: String, rewards: Dictionary)
signal dungeon_failed(dungeon_name: String)
signal boss_spawned(boss_name: String)

# 秘境类型
enum DungeonType {
	TRIAL,      # 试炼秘境
	INHERIT,    # 传承秘境
	ELITE,      # 精英副本
	BOSS,       # Boss副本
	SECRET      # 隐藏副本
}

# 秘境难度
enum Difficulty {
	NORMAL,     # 简单
	HARD,       # 困难
	NIGHTMARE   # 噩梦
}

# 秘境数据库
var dungeon_database: Dictionary = {
	"beginner_trial": {
		"name": "新手试炼",
		"type": DungeonType.TRIAL,
		"level_required": 1,
		"difficulty": Difficulty.NORMAL,
		"description": "新人弟子的入门试炼",
		"floors": 3,
		"enemies_per_floor": 3,
		"enemy_level": 1,
		"time_limit": 300,  # 5分钟
		"rewards": {
			"exp": 100,
			"items": ["灵草×3"]
		},
		"entrance_fee": 0,
		"map_color": Color(0.3, 0.8, 0.3, 1)
	},
	"spirit_cave": {
		"name": "灵气洞穴",
		"type": DungeonType.TRIAL,
		"level_required": 5,
		"difficulty": Difficulty.NORMAL,
		"description": "蕴含丰富灵气的地下洞穴",
		"floors": 5,
		"enemies_per_floor": 4,
		"enemy_level": 5,
		"time_limit": 600,
		"rewards": {
			"exp": 300,
			"items": ["灵芝×2", "灵石×5"]
		},
		"entrance_fee": 10,
		"map_color": Color(0.4, 0.6, 0.8, 1)
	},
	"bone_pit": {
		"name": "白骨坑",
		"type": DungeonType.ELITE,
		"level_required": 10,
		"difficulty": Difficulty.HARD,
		"description": "堆积如山的白骨之地",
		"floors": 7,
		"enemies_per_floor": 5,
		"enemy_level": 10,
		"boss": "骨魔",
		"time_limit": 900,
		"rewards": {
			"exp": 800,
			"items": ["妖丹×2", "灵玉×3"]
		},
		"entrance_fee": 50,
		"map_color": Color(0.7, 0.7, 0.6, 1)
	},
	"demon_lair": {
		"name": "恶魔巢穴",
		"type": DungeonType.BOSS,
		"level_required": 20,
		"difficulty": Difficulty.HARD,
		"description": "群魔乱舞的邪恶之地",
		"floors": 10,
		"enemies_per_floor": 6,
		"enemy_level": 20,
		"boss": "恶魔领主",
		"time_limit": 1200,
		"rewards": {
			"exp": 2000,
			"items": ["金丹草×2", "灵石×20"]
		},
		"entrance_fee": 200,
		"map_color": Color(0.8, 0.2, 0.2, 1)
	},
	"immortal_tomb": {
		"name": "仙人陵墓",
		"type": DungeonType.INHERIT,
		"level_required": 30,
		"difficulty": Difficulty.NIGHTMARE,
		"description": "上古仙人的陵墓遗址",
		"floors": 15,
		"enemies_per_floor": 8,
		"enemy_level": 30,
		"boss": "仙灵守护者",
		"time_limit": 1800,
		"rewards": {
			"exp": 5000,
			"items": ["元婴果×1", "仙草×3", "神铁×5"]
		},
		"entrance_fee": 500,
		"map_color": Color(0.9, 0.8, 0.3, 1)
	},
	"dragon_den": {
		"name": "龙巢",
		"type": DungeonType.SECRET,
		"level_required": 40,
		"difficulty": Difficulty.NIGHTMARE,
		"description": "神龙藏身的神秘洞穴",
		"floors": 20,
		"enemies_per_floor": 10,
		"enemy_level": 40,
		"boss": "远古青龙",
		"time_limit": 2400,
		"rewards": {
			"exp": 10000,
			"items": ["龙血×3", "神玉×2", "仙木×3"]
		},
		"entrance_fee": 1000,
		"map_color": Color(0.2, 0.5, 0.9, 1)
	}
}

# 当前状态
var current_dungeon: String = ""
var current_floor: int = 0
var enemies_remaining: int = 0
var time_remaining: int = 0
var is_in_dungeon: bool = false

# 玩家进入记录
var dungeon_records: Dictionary = {}  # dungeon_name: {times_entered, times_cleared, best_time}

func _ready():
	load_records()

# 进入秘境
func enter_dungeon(dungeon_name: String, player_level: int, player_gold: int) -> Dictionary:
	if is_in_dungeon:
		return {"success": false, "message": "已在秘境中"}
	
	var dungeon = dungeon_database.get(dungeon_name)
	if dungeon == null:
		return {"success": false, "message": "秘境不存在"}
	
	# 检查等级
	if player_level < dungeon.level_required:
		return{"success": false, "message": "等级不足，需要%d级" % dungeon.level_required}
	
	# 检查金币
	if player_gold < dungeon.entrance_fee:
		return {"success": false, "message": "金币不足，需要%d" % dungeon.entrance_fee}
	
	# 进入秘境
	current_dungeon = dungeon_name
	current_floor = 1
	enemies_remaining = dungeon.enemies_per_floor
	time_remaining = dungeon.time_limit
	is_in_dungeon = true
	
	# 更新记录
	if not dungeon_records.has(dungeon_name):
		dungeon_records[dungeon_name] = {"times_entered": 0, "times_cleared": 0, "best_time": 0}
	dungeon_records[dungeon_name].times_entered += 1
	
	emit_signal("dungeon_entered", dungeon.name)
	print("进入秘境：", dungeon.name, " 第", current_floor, "层")
	
	return {
		"success": true,
		"dungeon": dungeon,
		"floor": current_floor,
		"enemies": enemies_remaining,
		"time": time_remaining,
		"message": "进入%s，第%d层" % [dungeon.name, current_floor]
	}

# 击杀敌人
func enemy_killed() -> bool:
	if not is_in_dungeon:
		return false
	
	enemies_remaining -= 1
	print("敌人剩余：", enemies_remaining)
	
	if enemies_remaining <= 0:
		# 进入下一层
		var dungeon = dungeon_database[current_dungeon]
		
		if current_floor < dungeon.floors:
			current_floor += 1
			enemies_remaining = dungeon.enemies_per_floor
			print("进入第", current_floor, "层")
			return true
		else:
			# 通关秘境
			return complete_dungeon()
	
	return false

# 完成秘境
func complete_dungeon() -> Dictionary:
	var dungeon = dungeon_database[current_dungeon]
	
	# 发放奖励
	var rewards = dungeon.rewards.duplicate()
	
	# 更新记录
	if dungeon_records.has(current_dungeon):
		dungeon_records[current_dungeon].times_cleared += 1
		if dungeon_records[current_dungeon].best_time == 0 or (dungeon.time_limit - time_remaining) < dungeon_records[current_dungeon].best_time:
			dungeon_records[current_dungeon].best_time = dungeon.time_limit - time_remaining
	
	emit_signal("dungeon_cleared", dungeon.name, rewards)
	
	# 重置状态
	is_in_dungeon = false
	current_dungeon = ""
	current_floor = 0
	
	save_records()
	print("通关秘境：", dungeon.name)
	
	return {
		"success": true,
		"rewards": rewards,
		"time_used": dungeon.time_limit - time_remaining,
		"message": "恭喜通关%s！" % dungeon.name
	}

# 秘境失败
func fail_dungeon() -> Dictionary:
	if not is_in_dungeon:
		return {"success": false, "message": "不在秘境中"}
	
	var dungeon = dungeon_database[current_dungeon]
	
	emit_signal("dungeon_failed", dungeon.name)
	
	is_in_dungeon = false
	current_dungeon = ""
	current_floor = 0
	
	save_records()
	print("秘境失败：", dungeon.name)
	
	return {
		"success": false,
		"message": "挑战失败，超时"
	}

# 时间减少（每秒调用）
func update_time(delta: float):
	if is_in_dungeon:
		time_remaining -= delta
		if time_remaining <= 0:
			fail_dungeon()

# 获取当前秘境状态
func get_dungeon_status() -> Dictionary:
	if not is_in_dungeon:
		return {"in_dungeon": false}
	
	var dungeon = dungeon_database[current_dungeon]
	return {
		"in_dungeon": true,
		"name": dungeon.name,
		"floor": current_floor,
		"total_floors": dungeon.floors,
		"enemies": enemies_remaining,
		"time": time_remaining,
		"boss": dungeon.get("boss", "")
	}

# 获取可用秘境列表
func get_available_dungeons(player_level: int) -> Array:
	var available = []
	
	for dungeon_name in dungeon_database.keys():
		var dungeon = dungeon_database[dungeon_name]
		if player_level >= dungeon.level_required - 5:  # 显示相近等级的秘境
			available.append({
				"id": dungeon_name,
				"name": dungeon.name,
				"type": dungeon.type,
				"level_required": dungeon.level_required,
				"difficulty": dungeon.difficulty,
				"floors": dungeon.floors,
				"entrance_fee": dungeon.entrance_fee,
				"description": dungeon.description,
				"boss": dungeon.get("boss", "无")
			})
	
	return available

# 获取秘境记录
func get_dungeon_record(dungeon_name: String) -> Dictionary:
	return dungeon_records.get(dungeon_name, {})

# 获取所有记录
func get_all_records() -> Dictionary:
	return dungeon_records.duplicate()

# 保存/加载
func save_records():
	var config = ConfigFile.new()
	config.set_value("dungeons", "records", dungeon_records)
	config.save("user://dungeons.cfg")

func load_records():
	if FileAccess.file_exists("user://dungeons.cfg"):
		var config = ConfigFile.new()
		if config.load("user://dungeons.cfg") == OK:
			dungeon_records = config.get_value("dungeons", "records", {})
