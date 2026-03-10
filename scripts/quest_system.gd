extends Node

class_name QuestSystem

# 任务系统 - 主线/支线/日常任务

signal quest_updated(quest: Dictionary)
signal quest_completed(quest_id: String)
signal quest_reward_claimed(quest_id: String)

# 任务类型
enum QuestType {
	MAIN,       # 主线任务
	SIDE,       # 支线任务
	DAILY,      # 日常任务
	WEEKLY,     # 周常任务
	ACHIEVEMENT # 成就任务
}

# 任务状态
enum QuestState {
	LOCKED,     # 未解锁
	AVAILABLE,  # 可接取
	IN_PROGRESS # 进行中
	COMPLETED   # 已完成
}

# 任务数据库
var quest_database: Array = [
	{
		"id": "main_01",
		"type": QuestType.MAIN,
		"name": "初入冒险",
		"description": "与新手村的村长对话，了解当前的情况",
		"objectives": [{"type": "talk", "target": "village_chief", "count": 1}],
		"rewards": {"exp": 100, "gold": 50},
		"next_quest": "main_02"
	},
	{
		"id": "main_02",
		"type": QuestType.MAIN,
		"name": "击杀史莱姆",
		"description": "前往森林击杀10只史莱姆",
		"objectives": [{"type": "kill", "target": "slime", "count": 10}],
		"rewards": {"exp": 200, "gold": 100, "item": "iron_sword"},
		"next_quest": "main_03"
	},
	{
		"id": "main_03",
		"type": QuestType.MAIN,
		"name": "哥布林入侵",
		"description": "哥布林正在袭击村庄，击败它们",
		"objectives": [{"type": "kill", "target": "goblin", "count": 5}, {"type": "boss", "target": "goblin_chief", "count": 1}],
		"rewards": {"exp": 500, "gold": 200, "item": "steel_armor"},
		"next_quest": "main_04"
	},
	{
		"id": "side_01",
		"type": QuestType.SIDE,
		"name": "收集药材",
		"description": "采集10份草药",
		"objectives": [{"type": "collect", "target": "herb", "count": 10}],
		"rewards": {"exp": 150, "gold": 80}
	},
	{
		"id": "side_02",
		"type": QuestType.SIDE,
		"name": "商人请求",
		"description": "帮助商人送一封信到城里",
		"objectives": [{"type": "deliver", "target": "letter", "count": 1}],
		"rewards": {"exp": 100, "gold": 150}
	},
	{
		"id": "daily_01",
		"type": QuestType.DAILY,
		"name": "每日讨伐",
		"description": "击杀20只任意怪物",
		"objectives": [{"type": "kill", "target": "any", "count": 20}],
		"rewards": {"exp": 300, "gold": 100}
	},
	{
		"id": "daily_02",
		"type": QuestType.DAILY,
		"name": "采集任务",
		"description": "收集5份铁矿石",
		"objectives": [{"type": "collect", "target": "iron_ore", "count": 5}],
		"rewards": {"exp": 200, "gold": 80}
	}
]

# 玩家任务进度
var active_quests: Dictionary = {}  # quest_id: {progress: int, state: QuestState}
var completed_quests: Array = []

# 任务目标类型处理
var objective_handlers: Dictionary = {
	"talk": "_handle_talk_objective",
	"kill": "_handle_kill_objective",
	"collect": "_handle_collect_objective",
	"deliver": "_handle_deliver_objective",
	"boss": "_handle_boss_objective"
}

func _ready():
	load_quest_progress()

func get_quest(quest_id: String) -> Dictionary:
	for quest in quest_database:
		if quest.id == quest_id:
			return quest
	return {}

func get_available_quests(player_level: int) -> Array:
	var available = []
	
	for quest in quest_database:
		if is_quest_available(quest, player_level):
			available.append(quest)
	
	return available

func is_quest_available(quest: Dictionary, player_level: int) -> bool:
	var quest_id = quest.id
	
	# 已完成的不能重复接
	if quest_id in completed_quests:
		return false
	
	# 检查前置任务
	if quest.has("prerequest"):
		if not quest.prerequest in completed_quests:
			return false
	
	# 检查等级要求
	if quest.has("min_level"):
		if player_level < quest.min_level:
			return false
	
	return true

func accept_quest(quest_id: String) -> bool:
	var quest = get_quest(quest_id)
	if quest.is_empty():
		print("任务不存在: ", quest_id)
		return false
	
	if active_quests.has(quest_id):
		print("任务已接取")
		return false
	
	# 初始化任务进度
	active_quests[quest_id] = {
		"state": QuestState.IN_PROGRESS,
		"progress": {},
		"started_at": Time.get_unix_time_from_system()
	}
	
	# 初始化每个目标进度
	for objective in quest.objectives:
		active_quests[quest_id].progress[objective.target] = 0
	
	print("接受任务: ", quest.name)
	emit_signal("quest_updated", quest)
	return true

func update_quest_progress(objective_type: String, target: String, amount: int = 1):
	for quest_id in active_quests.keys():
		var quest = get_quest(quest_id)
		if quest.is_empty():
			continue
		
		# 检查任务目标
		for objective in quest.objectives:
			if objective.type == objective_type:
				# 检查目标匹配
				if objective.target == target or objective.target == "any":
					_update_objective_progress(quest_id, target, amount)
					break

func _update_objective_progress(quest_id: String, target: String, amount: int):
	var quest_progress = active_quests[quest_id]
	var current = quest_progress.progress.get(target, 0)
	quest_progress.progress[target] = current + amount
	
	var quest = get_quest(quest_id)
	var objective = null
	
	for obj in quest.objectives:
		if obj.target == target:
			objective = obj
			break
	
	if objective:
		var required = objective.count
		var current_total = 0
		
		# 计算总进度
		for obj in quest.objectives:
			current_total += quest_progress.progress.get(obj.target, 0)
		
		var total_required = 0
		for obj in quest.objectives:
			total_required += obj.count
		
		# 检查是否完成
		if current_total >= total_required:
			_complete_quest(quest_id)
	
	emit_signal("quest_updated", quest)

func _complete_quest(quest_id: String):
	var quest = get_quest(quest_id)
	if quest.is_empty():
		return
	
	active_quests[quest_id].state = QuestState.COMPLETED
	completed_quests.append(quest_id)
	
	print("任务完成: ", quest.name)
	emit_signal("quest_completed", quest_id)
	
	# 奖励
	claim_reward(quest_id)
	
	# 自动解锁下一个任务
	if quest.has("next_quest"):
		var next_id = quest.next_quest
		var next_quest = get_quest(next_id)
		if not next_quest.is_empty():
			print("解锁新任务: ", next_quest.name)

func claim_reward(quest_id: String) -> bool:
	var quest_progress = active_quests.get(quest_id)
	if quest_progress == null or quest_progress.state != QuestState.COMPLETED:
		return false
	
	if quest_progress.has("reward_claimed"):
		return false
	
	var quest = get_quest(quest_id)
	var rewards = quest.get("rewards", {})
	
	# 发放奖励
	if rewards.has("exp"):
		print("获得经验: ", rewards.exp)
	
	if rewards.has("gold"):
		print("获得金币: ", rewards.gold)
	
	if rewards.has("item"):
		print("获得物品: ", rewards.item)
	
	quest_progress.reward_claimed = true
	active_quests.erase(quest_id)
	
	emit_signal("quest_reward_claimed", quest_id)
	return true

func abandon_quest(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	
	active_quests.erase(quest_id)
	print("放弃任务: ", quest_id)
	return true

func get_quest_progress(quest_id: String) -> Dictionary:
	return active_quests.get(quest_id, {})

func get_active_quest_list() -> Array:
	var result = []
	
	for quest_id in active_quests.keys():
		var quest = get_quest(quest_id)
		if not quest.is_empty():
			quest["progress"] = active_quests[quest_id]
			result.append(quest)
	
	return result

func get_completed_quest_list() -> Array:
	var result = []
	
	for quest_id in completed_quests:
		var quest = get_quest(quest_id)
		if not quest.is_empty():
			result.append(quest)
	
	return result

func save_quest_progress():
	var save_data = {
		"active_quests": active_quests,
		"completed_quests": completed_quests
	}
	
	var save_manager = get_tree().current_scene.get_node_or_null("SaveManager")
	if save_manager:
		save_manager.current_save["quests"] = save_data

func load_quest_progress():
	# 从存档加载
	pass
