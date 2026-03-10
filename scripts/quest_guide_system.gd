extends Node

class_name QuestGuideSystem

# 任务指引系统

signal quest_accepted(quest_id: String)
signal quest_updated(quest_id: String, objective_id: String, progress: int)
signal quest_completed(quest_id: String)
signal quest_reward_claimed(quest_id: String)

# 任务类型
enum QuestType {
	MAIN,       # 主线任务
	SIDE,       # 支线任务
	DAILY,      # 日常任务
	GUILD,      # 行会任务
	DAILY_QUEST # 每日任务
}

# 任务状态
enum QuestState {
	UNAVAILABLE,  # 不可接
	AVAILABLE,    # 可接
	IN_PROGRESS,  # 进行中
	COMPLETED,    # 已完成
	REWARDED     # 已领奖
}

# 任务数据库
var quest_database: Dictionary = {
	# 主线任务
	"main_1": {
		"id": "main_1",
		"type": QuestType.MAIN,
		"name": "三清问道",
		"description": "前往玉清殿拜见元始天尊，选择宗门",
		"objectives": [
			{"id": "talk_npc", "type": "talk", "target": "元始天尊", "count": 1}
		],
		"rewards": {"exp": 100, "gold": 50},
		"next_quest": "main_2",
		"level_required": 1
	},
	"main_2": {
		"id": "main_2",
		"type": QuestType.MAIN,
		"name": "初入仙门",
		"description": "了解宗门基本操作，击杀3只灵兽",
		"objectives": [
			{"id": "kill_spirit", "type": "kill", "target": "灵兽", "count": 3}
		],
		"rewards": {"exp": 200, "gold": 100},
		"next_quest": "main_3",
		"level_required": 1
	},
	"main_3": {
		"id": "main_3",
		"type": QuestType.MAIN,
		"name": "初次战斗",
		"description": "前往灵气洞穴，击杀5只妖兽",
		"objectives": [
			{"id": "kill_beast", "type": "kill", "target": "妖兽", "count": 5}
		],
		"rewards": {"exp": 300, "gold": 150, "items": ["灵草×3"]},
		"next_quest": "main_4",
		"level_required": 3
	},
	"main_4": {
		"id": "main_4",
		"type": QuestType.MAIN,
		"name": "筑基之路",
		"description": "达到5级，完成筑基",
		"objectives": [
			{"id": "reach_level", "type": "level", "target": 5, "count": 1}
		],
		"rewards": {"exp": 500, "gold": 200, "items": ["筑基丹×1"]},
		"next_quest": "main_5",
		"level_required": 4
	},
	"main_5": {
		"id": "main_5",
		"type": QuestType.MAIN,
		"name": "秘境初探",
		"description": "通关一次新手试炼秘境",
		"objectives": [
			{"id": "clear_dungeon", "type": "dungeon", "target": "beginner_trial", "count": 1}
		],
		"rewards": {"exp": 800, "gold": 300, "items": ["灵芝×2"]},
		"next_quest": "",
		"level_required": 5
	},
	
	# 支线任务
	"side_1": {
		"id": "side_1",
		"type": QuestType.SIDE,
		"name": "灵草采集",
		"description": "采集10株灵草",
		"objectives": [
			{"id": "collect_herb", "type": "collect", "target": "灵草", "count": 10}
		],
		"rewards": {"exp": 150, "gold": 50},
		"level_required": 1
	},
	"side_2": {
		"id": "side_2",
		"type": QuestType.SIDE,
		"name": "药材商人",
		"description": "收集5份药材交给药店老板",
		"objectives": [
			{"id": "collect_medicine", "type": "collect", "target": "药材", "count": 5}
		],
		"rewards": {"exp": 200, "gold": 100},
		"level_required": 2
	},
	"side_3": {
		"id": "side_3",
		"type": QuestType.SIDE,
		"name": "灵石矿工",
		"description": "挖掘10块灵石",
		"objectives": [
			{"id": "mine_ore", "type": "collect", "target": "灵石", "count": 10}
		],
		"rewards": {"exp": 300, "gold": 150},
		"level_required": 3
	},
	
	# 日常任务
	"daily_1": {
		"id": "daily_1",
		"type": QuestType.DAILY,
		"name": "日常讨伐",
		"description": "击杀20只怪物",
		"objectives": [
			{"id": "daily_kill", "type": "kill", "target": "any", "count": 20}
		],
		"rewards": {"exp": 300, "gold": 100},
		"reset_time": "daily"
	},
	"daily_2": {
		"id": "daily_2",
		"type": QuestType.DAILY,
		"name": "日常采集",
		"description": "采集15份材料",
		"objectives": [
			{"id": "daily_collect", "type": "collect", "target": "any", "count": 15}
		],
		"rewards": {"exp": 250, "gold": 80},
		"reset_time": "daily"
	},
	"daily_3": {
		"id": "daily_3",
		"type": QuestType.DAILY,
		"name": "日常副本",
		"description": "通关1次秘境",
		"objectives": [
			{"id": "daily_dungeon", "type": "dungeon", "target": "any", "count": 1}
		],
		"rewards": {"exp": 500, "gold": 200},
		"reset_time": "daily"
	}
}

# 玩家任务进度
var player_quests: Dictionary = {}  # player_id: {quest_id: quest_data}

func _ready():
	pass

# 接受任务
func accept_quest(player_id: String, quest_id: String, player_level: int) -> Dictionary:
	var quest = quest_database.get(quest_id)
	if quest == null:
		return {"success": false, "message": "任务不存在"}
	
	# 检查等级
	if player_level < quest.get("level_required", 1):
		return {"success": false, "message": "等级不足"}
	
	# 初始化玩家任务数据
	if not player_quests.has(player_id):
		player_quests[player_id] = {}
	
	# 检查是否已接取
	if player_quests[player_id].has(quest_id):
		return {"success": false, "message": "已接取该任务"}
	
	# 检查前置任务
	var prereq = quest.get("prerequisite_quest", "")
	if prereq != "":
		var prereq_data = player_quests[player_id].get(prereq)
		if prereq_data == nil or prereq_data.state != QuestState.COMPLETED:
			return {"success": false, "message": "前置任务未完成"}
	
	# 接受任务
	var quest_progress = {
		"quest_id": quest_id,
		"state": QuestState.IN_PROGRESS,
		"objectives": {}
	}
	
	# 初始化目标进度
	for obj in quest.objectives:
		quest_progress.objectives[obj.id] = {
			"current": 0,
			"target": obj.count,
			"completed": false
		}
	
	player_quests[player_id][quest_id] = quest_progress
	
	emit_signal("quest_accepted", quest_id)
	save_quests()
	
	return {
		"success": true,
		"quest_name": quest.name,
		"message": "接受任务：" + quest.name
	}

# 更新任务进度
func update_quest_progress(player_id: String, objective_type: String, target: String, amount: int = 1):
	if not player_quests.has(player_id):
		return
	
	var quests_to_update = []
	
	# 查找需要更新的任务
	for quest_id in player_quests[player_id].keys():
		var quest_data = player_quests[player_id][quest_id]
		
		if quest_data.state != QuestState.IN_PROGRESS:
			continue
		
		var quest = quest_database.get(quest_id)
		if quest == null:
			continue
		
		# 检查目标是否匹配
		for obj in quest.objectives:
			if obj.type == objective_type:
				if obj.target == target or obj.target == "any":
					# 更新进度
					quest_data.objectives[obj.id].current += amount
					
					var current = quest_data.objectives[obj.id].current
					var obj_target = obj.count
					
					if current >= obj_target:
						quest_data.objectives[obj.id].completed = true
					
					emit_signal("quest_updated", quest_id, obj.id, current)
					quests_to_update.append(quest_id)
	
	# 检查任务是否全部完成
	for quest_id in quests_to_update:
		if is_quest_completed(player_id, quest_id):
			complete_quest(player_id, quest_id)
	
	save_quests()

# 完成任务
func complete_quest(player_id: String, quest_id: String):
	if not player_quests.has(player_id):
		return
	
	var quest_data = player_quests[player_id].get(quest_id)
	if quest_data == null:
		return
	
	quest_data.state = QuestState.COMPLETED
	
	emit_signal("quest_completed", quest_id)
	print("任务完成：", quest_id)
	save_quests()

# 检查任务是否完成
func is_quest_completed(player_id: String, quest_id: String) -> bool:
	if not player_quests.has(player_id):
		return false
	
	var quest_data = player_quests[player_id].get(quest_id)
	if quest_data == null:
		return false
	
	# 检查所有目标
	for obj_id in quest_data.objectives.keys():
		if not quest_data.objectives[obj_id].completed:
			return false
	
	return true

# 领取奖励
func claim_reward(player_id: String, quest_id: String) -> Dictionary:
	if not player_quests.has(player_id):
		return {"success": false, "message": "未接取任务"}
	
	var quest_data = player_quests[player_id].get(quest_id)
	if quest_data == null:
		return {"success": false, "message": "未接取该任务"}
	
	if quest_data.state != QuestState.COMPLETED:
		return {"success": false, "message": "任务未完成"}
	
	if quest_data.state == QuestState.REWARDED:
		return {"success": false, "message": "奖励已领取"}
	
	var quest = quest_database.get(quest_id)
	if quest == null:
		return {"success": false, "message": "任务不存在"}
	
	quest_data.state = QuestState.REWARDED
	
	emit_signal("quest_reward_claimed", quest_id)
	save_quests()
	
	return {
		"success": true,
		"rewards": quest.rewards,
		"message": "领取任务奖励成功"
	}

# 获取任务状态
func get_quest_status(player_id: String, quest_id: String) -> Dictionary:
	var quest = quest_database.get(quest_id)
	if quest == null:
		return {}
	
	var quest_data = player_quests[player_id].get(quest_id)
	var state = QuestState.AVAILABLE
	var objectives = []
	
	if quest_data != null:
		state = quest_data.state
		for obj in quest.objectives:
			var progress = quest_data.objectives.get(obj.id, {})
			objectives.append({
				"id": obj.id,
				"description": obj.type + " " + obj.target,
				"current": progress.get("current", 0),
				"target": obj.count,
				"completed": progress.get("completed", false)
			})
	else:
		# 未接取，显示目标预览
		for obj in quest.objectives:
			objectives.append({
				"id": obj.id,
				"description": obj.type + " " + obj.target,
				"current": 0,
				"target": obj.count,
				"completed": false
			})
	
	return {
		"id": quest_id,
		"name": quest.name,
		"description": quest.description,
		"type": quest.type,
		"state": state,
		"objectives": objectives,
		"rewards": quest.rewards,
		"level_required": quest.get("level_required", 1)
	}

# 获取可接任务列表
func get_available_quests(player_id: String, player_level: int) -> Array:
	var result = []
	
	for quest_id in quest_database.keys():
		var quest = quest_database[quest_id]
		
		# 检查等级
		if player_level < quest.get("level_required", 1):
			continue
		
		# 检查是否已接取或已完成
		if player_quests.has(player_id):
			var quest_data = player_quests[player_id].get(quest_id)
			if quest_data != null:
				continue
		
		# 检查前置任务
		var prereq = quest.get("prerequisite_quest", "")
		if prereq != "":
			if not player_quests.has(player_id):
				continue
			var prereq_data = player_quests[player_id].get(prereq)
			if prereq_data == nil or prereq_data.state != QuestState.COMPLETED:
				continue
		
		result.append(get_quest_status(player_id, quest_id))
	
	return result

# 获取进行中的任务
func get_in_progress_quests(player_id: String) -> Array:
	var result = []
	
	if not player_quests.has(player_id):
		return result
	
	for quest_id in player_quests[player_id].keys():
		var quest_data = player_quests[player_id][quest_id]
		if quest_data.state == QuestState.IN_PROGRESS:
			result.append(get_quest_status(player_id, quest_id))
	
	return result

# 获取已完成待领奖的任务
func get_completed_quests(player_id: String) -> Array:
	var result = []
	
	if not player_quests.has(player_id):
		return result
	
	for quest_id in player_quests[player_id].keys():
		var quest_data = player_quests[player_id][quest_id]
		if quest_data.state == QuestState.COMPLETED:
			result.append(get_quest_status(player_id, quest_id))
	
	return result

# 便捷方法
func on_kill(player_id: String, monster_type: String):
	update_quest_progress(player_id, "kill", monster_type)

def on_collect(player_id: String, item_type: String):
	update_quest_progress(player_id, "collect", item_type)

func on_talk(player_id: String, npc_name: String):
	update_quest_progress(player_id, "talk", npc_name)

func on_level_up(player_id: String, level: int):
	update_quest_progress(player_id, "level", str(level))

func on_dungeon_clear(player_id: String, dungeon_id: String):
	update_quest_progress(player_id, "dungeon", dungeon_id)

# 保存/加载
func save_quests():
	var config = ConfigFile.new()
	config.set_value("quests", "player_quests", player_quests)
	config.save("user://quests.cfg")

func load_quests():
	if FileAccess.file_exists("user://quests.cfg"):
		var config = ConfigFile.new()
		if config.load("user://quests.cfg") == OK:
			player_quests = config.get_value("quests", "player_quests", {})
