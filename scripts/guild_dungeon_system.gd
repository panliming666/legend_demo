extends Node

class_name GuildDungeonSystem

# 行会副本系统

signal guild_dungeon_opened(dungeon_name: String)
signal guild_dungeon_cleared(guild_name: String, rewards: Dictionary)
signal guild_boss_spawned(boss_name: String)

# 行会副本类型
enum GuildDungeonType {
	EASY,       # 简单
	NORMAL,     # 普通
	HARD,       # 困难
	WORLD       # 世界
}

# 行会副本数据
var guild_dungeons: Dictionary = {
	"guild_1": {
		"id": "guild_1",
		"name": "行会试炼",
		"type": GuildDungeonType.EASY,
		"level_required": 1,
		"member_limit": 5,
		"floors": 3,
		"boss": "试炼守护者",
		"rewards": {"exp": 1000, "guild_exp": 100, "items": ["行会建设令×5"]}
	},
	"guild_2": {
		"id": "guild_2",
		"name": "行会挑战",
		"type": GuildDungeonType.NORMAL,
		"level_required": 10,
		"member_limit": 10,
		"floors": 5,
		"boss": "守卫统领",
		"rewards": {"exp": 3000, "guild_exp": 300, "items": ["行会建设令×10"]}
	},
	"guild_3": {
		"id": "guild_3",
		"name": "行会深渊",
		"type": GuildDungeonType.HARD,
		"level_required": 20,
		"member_limit": 15,
		"floors": 7,
		"boss": "深渊之主",
		"rewards": {"exp": 5000, "guild_exp": 500, "items": ["行会建设令×20"]}
	},
	"guild_4": {
		"id": "guild_4",
		"name": "行会圣地",
		"type": GuildDungeonType.WORLD,
		"level_required": 30,
		"member_limit": 20,
		"floors": 10,
		"boss": "圣地守护神",
		"rewards": {"exp": 10000, "guild_exp": 1000, "items": ["神级装备×1"]}
	}
}

# 当前开启的副本
var active_dungeons: Dictionary = {}  # dungeon_id: {guild_id, members, progress, status}

# 开启行会副本
func open_dungeon(guild_id: String, dungeon_id: String) -> Dictionary:
	var dungeon = guild_dungeons.get(dungeon_id)
	if dungeon == null:
		return {"success": false, "message": "副本不存在"}
	
	# 检查是否已开启
	if active_dungeons.has(dungeon_id):
		return {"success": false, "message": "副本已在进行中"}
	
	# 开启副本
	active_dungeons[dungeon_id] = {
		"guild_id": guild_id,
		"members": [],
		"current_floor": 1,
		"boss_hp": 0,
		"boss_max_hp": 0,
		"start_time": Time.get_unix_time_from_system(),
		"status": "active"
	}
	
	emit_signal("guild_dungeon_opened", dungeon.name)
	
	return {
		"success": true,
		"dungeon": dungeon,
		"message": "行会副本已开启"
	}

# 加入副本
func join_dungeon(dungeon_id: String, player_id: String) -> Dictionary:
	if not active_dungeons.has(dungeon_id):
		return {"success": false, "message": "副本不存在或已结束"}
	
	var dungeon = active_dungeons[dungeon_id]
	
	if dungeon.status != "active":
		return {"success": false, "message": "副本已结束"}
	
	if not player_id in dungeon.members:
		dungeon.members.append(player_id)
	
	return {
		"success": true,
		"dungeon": guild_dungeons[dungeon_id],
		"floor": dungeon.current_floor,
		"members": dungeon.members.size()
	}

# 离开副本
func leave_dungeon(dungeon_id: String, player_id: String):
	if active_dungeons.has(dungeon_id):
		var dungeon = active_dungeons[dungeon_id]
		if player_id in dungeon.members:
			dungeon.members.erase(player_id)

# 击杀怪物
func kill_monster(dungeon_id: String, player_id: String, damage: int) -> Dictionary:
	if not active_dungeons.has(dungeon_id):
		return {"success": false, "message": "副本不存在"}
	
	var dungeon = active_dungeons[dungeon_id]
	var base_dungeon = guild_dungeons[dungeon_id]
	
	# 扣除Boss血量（假设每层最后有Boss）
	if dungeon.boss_max_hp > 0:
		dungeon.boss_hp -= damage
		
		if dungeon.boss_hp <= 0:
			# 进入下一层
			dungeon.current_floor += 1
			
			if dungeon.current_floor > base_dungeon.floors:
				# 通关
				return complete_dungeon(dungeon_id)
			else:
				# 重置Boss
				dungeon.boss_hp = 0
				dungeon.boss_max_hp = 0
	
	return {
		"success": true,
		"floor": dungeon.current_floor,
		"boss_hp": dungeon.boss_hp,
		"boss_max_hp": dungeon.boss_max_hp
	}

# 通关副本
func complete_dungeon(dungeon_id: String) -> Dictionary:
	if not active_dungeons.has(dungeon_id):
		return {"success": false, "message": "副本不存在"}
	
	var dungeon = active_dungeons[dungeon_id]
	var base_dungeon = guild_dungeons[dungeon_id]
	
	# 发放奖励
	var rewards = base_dungeon.rewards.duplicate()
	
	emit_signal("guild_dungeon_cleared", dungeon.guild_id, rewards)
	
	# 清理
	active_dungeons.erase(dungeon_id)
	
	return {
		"success": true,
		"rewards": rewards,
		"message": "恭喜通关行会副本！"
	}

# 获取副本状态
func get_dungeon_status(dungeon_id: String) -> Dictionary:
	if not active_dungeons.has(dungeon_id):
		return {"active": false}
	
	var dungeon = active_dungeons[dungeon_id]
	return {
		"active": true,
		"floor": dungeon.current_floor,
		"members": dungeon.members.size(),
		"boss_hp": dungeon.boss_hp,
		"boss_max_hp": dungeon.boss_max_hp
	}

# 获取可用副本
func get_available_dungeons(guild_level: int) -> Array:
	var available = []
	
	for dg_id in guild_dungeons.keys():
		var dungeon = guild_dungeons[dg_id]
		if guild_level >= dungeon.level_required - 2:
			available.append(dungeon)
	
	return available
