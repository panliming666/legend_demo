extends Node

class_name RandomEventSystem

# 随机事件系统 - 单机Roguelike元素

signal event_triggered(event_id: String, event_name: String)
signal event_completed(event_id: String, result: String)

# 随机事件数据库
var event_database: Dictionary = {
	"treasure_chest": {
		"id": "treasure_chest",
		"name": "神秘宝箱",
		"description": "你发现一个上锁的宝箱",
		"choices": [
			{"text": "强行打开", "result": "forced", "chance": 0.5, "success_reward": {"gold": 500}, "fail_penalty": {"hp": 20}},
			{"text": "寻找钥匙", "result": "search", "chance": 0.8, "success_reward": {"gold": 500, "item": "钥匙"}, "fail_penalty": {}},
			{"text": "无视它", "result": "ignore", "chance": 1.0, "success_reward": {}, "fail_penalty": {}}
		]
	},
	"old_hermit": {
		"id": "old_hermit",
		"name": "神秘老者",
		"description": "一位白发老者拦住你的去路，似乎有话要说",
		"choices": [
			{"text": "聆听教诲", "result": "listen", "chance": 1.0, "success_reward": {"exp": 200}, "fail_penalty": {}},
			{"text": "给予金币", "result": "donate", "chance": 1.0, "success_reward": {"exp": 500, "buff": "exp_boost"}, "fail_penalty": {"gold": 100}},
			{"text": "直接离开", "result": "leave", "chance": 1.0, "success_reward": {}, "fail_penalty": {}}
		]
	},
	"fallen_adventurer": {
		"id": "fallen_adventurer",
		"name": "遇险的冒险者",
		"description": "一位受伤的冒险者向你求助",
		"choices": [
			{"text": "救助他", "result": "help", "chance": 0.9, "success_reward": {"karma": 10, "item": "随机装备"}, "fail_penalty": {"hp": 10}},
			{"text": "搜刮他的财物", "result": "rob", "chance": 1.0, "success_reward": {"gold": 200}, "fail_penalty": {"karma": -20}},
			{"text": "无视", "result": "ignore", "chance": 1.0, "success_reward": {}, "fail_penalty": {}}
		]
	},
	"mysterious_altar": {
		"id": "mysterious_altar",
		"name": "神秘祭坛",
		"description": "一个散发着诡异光芒的祭坛",
		"choices": [
			{"text": "献祭生命值", "result": "sacrifice_hp", "chance": 1.0, "success_reward": {"max_mp": 50}, "fail_penalty": {"max_hp": 50}},
			{"text": "献祭金币", "result": "sacrifice_gold", "chance": 1.0, "success_reward": {"max_hp": 100}, "fail_penalty": {"gold": 500}},
			{"text": "摧毁祭坛", "result": "destroy", "chance": 0.7, "success_reward": {"exp": 300}, "fail_penalty": {"hp": 50}}
		]
	},
	"gambling_demon": {
		"id": "gambling_demon",
		"name": "赌鬼",
		"description": "一个恶魔提出和你玩个游戏",
		"choices": [
			{"text": "赌一把", "result": "gamble", "chance": 0.4, "success_reward": {"gold": 1000}, "fail_penalty": {"gold": 200}},
			{"text": "稳妥投注", "result": "safe_bet", "chance": 0.6, "success_reward": {"gold": 300}, "fail_penalty": {"gold": 100}},
			{"text": "拒绝", "result": "refuse", "chance": 1.0, "success_reward": {}, "fail_penalty": {}}
		]
	},
	"blessing_shrine": {
		"id": "blessing_shrine",
		"name": "祝福祭坛",
		"description": "一个散发着神圣光芒的祭坛",
		"choices": [
			{"text": "接受祝福", "result": "bless", "chance": 1.0, "success_reward": {"buff": "holy_blessing", "hp": 50}, "fail_penalty": {}},
			{"text": "祈祷", "result": "pray", "chance": 0.8, "success_reward": {"buff": "exp_boost", "duration": 300}, "fail_penalty": {}},
			{"text": "离开", "result": "leave", "chance": 1.0, "success_reward": {}, "fail_penalty": {}}
		]
	},
	"cursed_item": {
		"id": "cursed_item",
		"name": "诅咒物品",
		"description": "你发现一件散发着邪恶气息的物品",
		"choices": [
			{"text": "拾取", "result": "pickup", "chance": 0.5, "success_reward": {"item": "强力装备"}, "fail_penalty": {"curse": "weakness", "duration": 60}},
			{"text": "净化", "result": "cleanse", "chance": 0.7, "success_reward": {"item": "普通装备", "exp": 100}, "fail_penalty": {"hp": 30}},
			{"text": "离开", "result": "leave", "chance": 1.0, "success_reward": {}, "fail_penalty": {}}
		]
	}
}

# 触发概率配置
var trigger_chance: float = 0.3  # 30%概率触发事件

func _ready():
	print("随机事件系统初始化完成")

# 尝试触发随机事件
func try_trigger_event() -> Dictionary:
	if randf() > trigger_chance:
		return {"success": false, "message": "无事发生"}
	
	# 随机选择一个事件
	var event_ids = event_database.keys()
	var selected_id = event_ids[randi() % event_ids.size()]
	
	return trigger_event(selected_id)

# 触发指定事件
func trigger_event(event_id: String) -> Dictionary:
	var event = event_database.get(event_id)
	if event == null:
		return {"success": false, "message": "事件不存在"}
	
	emit_signal("event_triggered", event_id, event.name)
	
	return {
		"success": true,
		"event": event,
		"message": "触发事件：" + event.name
	}

# 处理事件选择
func make_choice(event_id: String, choice_index: int) -> Dictionary:
	var event = event_database.get(event_id)
	if event == null:
		return {"success": false, "message": "事件不存在"}
	
	if choice_index < 0 or choice_index >= event.choices.size():
		return {"success": false, "message": "无效选择"}
	
	var choice = event.choices[choice_index]
	
	# 判定结果
	var roll = randf()
	var success = roll <= choice.chance
	
	var result_data: Dictionary
	
	if success:
		result_data = {
			"success": true,
			"result": choice.result,
			"rewards": choice.success_reward,
			"message": "选择成功！"
		}
	else:
		result_data = {
			"success": false,
			"result": choice.result,
			"penalties": choice.fail_penalty,
			"message": "选择失败..."
		}
	
	emit_signal("event_completed", event_id, choice.result)
	
	return result_data

# 获取所有事件
func get_all_events() -> Array:
	var result = []
	
	for event_id in event_database.keys():
		var event = event_database[event_id]
		result.append({
			"id": event_id,
			"name": event.name,
			"description": event.description,
			"choices_count": event.choices.size()
		})
	
	return result
