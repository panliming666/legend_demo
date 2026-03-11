extends Node

class_name ActivitySystem

# 活动系统

signal activity_started(activity_id: String)
signal activity_ended(activity_id: String)
signal reward_claimed(activity_id: String, player_id: String)

# 活动类型
enum ActivityType {
	LIMITED_TIME,  # 限时活动
	DAILY,         # 每日活动
	WEEKLY,        # 每周活动
	EVENT          # 事件活动
}

# 活动状态
enum ActivityState {
	INACTIVE,
	ACTIVE,
	ENDED
}

# 活动数据库
var activity_database: Dictionary = {
	"daily_kill": {
		"id": "daily_kill",
		"name": "日常讨伐",
		"type": ActivityType.DAILY,
		"description": "击杀指定数量的怪物",
		"requirements": {"kill_count": 50},
		"rewards": {"exp": 500, "gold": 100},
		"refresh_time": {"hour": 0, "minute": 0},  # 每天0点刷新
		"icon": "⚔️"
	},
	"daily_dungeon": {
		"id": "daily_dungeon",
		"name": "秘境挑战",
		"type": ActivityType.DAILY,
		"description": "通关1次秘境",
		"requirements": {"dungeon_clear": 1},
		"rewards": {"exp": 300, "items": ["灵石×5"]},
		"refresh_time": {"hour": 0, "minute": 0},
		"icon": "🗝️"
	},
	"daily_collection": {
		"id": "daily_collection",
		"name": "采集任务",
		"type": ActivityType.DAILY,
		"description": "收集指定材料",
		"requirements": {"collect_count": 10},
		"rewards": {"exp": 200, "gold": 50},
		"refresh_time": {"hour": 0, "minute": 0},
		"icon": "📦"
	},
	"weekly_boss": {
		"id": "weekly_boss",
		"name": "周常Boss",
		"type": ActivityType.WEEKLY,
		"description": "击杀1只世界Boss",
		"requirements": {"boss_kill": 1},
		"rewards": {"exp": 2000, "gold": 500, "items": ["仙草×3"]},
		"refresh_time": {"weekday": 0, "hour": 0},  # 每周一0点刷新
		"icon": "👹"
	},
	"double_exp": {
		"id": "double_exp",
		"name": "双倍经验",
		"type": ActivityType.LIMITED_TIME,
		"description": "周末全天双倍经验",
		"start_time": {"weekday": 6, "hour": 12},  # 周六12点
		"end_time": {"weekday": 0, "hour": 0},     # 周日24点
		"effect": {"exp_multiplier": 2.0},
		"icon": "⭐"
	},
	"gold_rush": {
		"id": "gold_rush",
		"name": "金币大作战",
		"type": ActivityType.LIMITED_TIME,
		"description": "掉落金币翻倍",
		"start_time": {"hour": 19, "minute": 0},  # 每天19点
		"end_time": {"hour": 21, "minute": 0},    # 21点结束
		"effect": {"gold_multiplier": 2.0},
		"icon": "💰"
	},
	"first_recharge": {
		"id": "first_recharge",
		"name": "首充豪礼",
		"type": ActivityType.EVENT,
		"description": "首次充值获得额外奖励",
		"once": true,
		"rewards": {"items": ["仙级装备×1", "灵石×100"]},
		"icon": "🎁"
	},
	"seven_days": {
		"id": "seven_days",
		"name": "七天登录",
		"type": ActivityType.EVENT,
		"description": "累计登录7天领取大奖",
		"requirements": {"login_days": 7},
		"rewards": {"exp": 5000, "gold": 2000, "items": ["神级装备×1"]},
		"icon": "📅"
	}
}

# 玩家活动进度
var player_activities: Dictionary = {}  # player_id: {activity_id: progress}

func _ready():
	check_activities()

func _process(delta):
	# 定时检查活动状态
	check_activities()

# 检查活动状态
func check_activities():
	var current_time = Time.get_time_dict_from_system()
	var current_weekday = Time.get_weekday_from_system()
	
	for act_id in activity_database.keys():
		var activity = activity_database[act_id]
		
		# 检查是否在活动时间
		if activity.type == ActivityType.LIMITED_TIME:
			# 检查是否在时间范围内
			# 简化处理，实际应该更复杂
			pass

# 获取活动状态
func get_activity_status(activity_id: String, player_id: String) -> Dictionary:
	var activity = activity_database.get(activity_id)
	if activity == null:
		return {}
	
	var progress = 0
	var completed = false
	var claimed = false
	
	if player_activities.has(player_id):
		var player_data = player_activities[player_id]
		if player_data.has(activity_id):
			progress = player_data[activity_id].get("progress", 0)
			completed = player_data[activity_id].get("completed", false)
			claimed = player_data[activity_id].get("claimed", false)
	
	var requirements = activity.get("requirements", {})
	var target = requirements.values()[0] if requirements.size() > 0 else 1
	
	return {
		"id": activity_id,
		"name": activity.name,
		"description": activity.description,
		"type": activity.type,
		"icon": activity.icon,
		"progress": progress,
		"target": target,
		"percent": float(progress) / target * 100 if target > 0 else 0,
		"completed": completed,
		"claimed": claimed,
		"rewards": activity.get("rewards", {})
	}

# 更新活动进度
func update_progress(player_id: String, activity_id: String, amount: int):
	if not activity_database.has(activity_id):
		return
	
	var activity = activity_database[activity_id]
	
	# 初始化玩家数据
	if not player_activities.has(player_id):
		player_activities[player_id] = {}
	
	if not player_activities[player_id].has(activity_id):
		player_activities[player_id][activity_id] = {
			"progress": 0,
			"completed": false,
			"claimed": false
		}
	
	var player_data = player_activities[player_id][activity_id]
	player_data.progress += amount
	
	# 检查完成
	var requirements = activity.get("requirements", {})
	for key in requirements.keys():
		if player_data.progress >= requirements[key]:
			player_data.completed = true
	
	save_activities()
	print("活动进度更新：", activity_id, " ", player_data.progress)

# 领取奖励
func claim_reward(player_id: String, activity_id: String) -> Dictionary:
	var activity = activity_database.get(activity_id)
	if activity == null:
		return {"success": false, "message": "活动不存在"}
	
	if not player_activities.has(player_id) or not player_activities[player_id].has(activity_id):
		return {"success": false, "message": "未参与活动"}
	
	var player_data = player_activities[player_id][activity_id]
	
	if not player_data.completed:
		return {"success": false, "message": "活动未完成"}
	
	if player_data.claimed:
		return {"success": false, "message": "奖励已领取"}
	
	# 发放奖励
	var rewards = activity.get("rewards", {})
	player_data.claimed = true
	
	emit_signal("reward_claimed", activity_id, player_id)
	save_activities()
	
	return {
		"success": true,
		"rewards": rewards,
		"message": "领取成功"
	}

# 获取玩家所有活动
func get_player_activities(player_id: String) -> Array:
	var result = []
	
	for act_id in activity_database.keys():
		result.append(get_activity_status(act_id, player_id))
	
	return result

# 获取进行中的活动
func get_active_activities() -> Array:
	var result = []
	var current_time = Time.get_time_dict_from_system()
	
	# 简化处理
	for act_id in activity_database.keys():
		var activity = activity_database[act_id]
		if activity.type == ActivityType.LIMITED_TIME:
			# 检查时间
			result.append(activity)
		elif activity.type == ActivityType.DAILY or activity.type == ActivityType.WEEKLY:
			result.append(activity)
	
	return result

# 便捷方法
func on_kill_monster(player_id: String):
	update_progress(player_id, "daily_kill", 1)

func on_clear_dungeon(player_id: String):
	update_progress(player_id, "daily_dungeon", 1)

func on_collect_item(player_id: String):
	update_progress(player_id, "daily_collection", 1)

func on_kill_boss(player_id: String):
	update_progress(player_id, "weekly_boss", 1)

# 保存/加载
func save_activities():
	var config = ConfigFile.new()
	config.set_value("activities", "player_data", player_activities)
	config.save("user://activities.cfg")

func load_activities():
	if FileAccess.file_exists("user://activities.cfg"):
		var config = ConfigFile.new()
		if config.load("user://activities.cfg") == OK:
			player_activities = config.get_value("activities", "player_data", {})
