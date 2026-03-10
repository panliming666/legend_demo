extends Node

class_name CheatCodeSystem

# 秘籍/彩蛋系统 - 单机趣味元素

signal cheat_activated(cheat_id: String, cheat_name: String)
signal easter_egg_found(egg_id: String, egg_name: String)

# 秘籍码
var cheat_codes: Dictionary = {
	"GODMODE": {
		"id": "godmode",
		"name": "上帝模式",
		"description": "无敌，一击必杀",
		"effect": {"invincible": true, "one_hit_kill": true},
		"unlock_condition": "通关剧情模式",
		"activated": false
	},
	"MONEY": {
		"id": "money",
		"name": "金钱雨",
		"description": "获得100000金币",
		"effect": {"gold": 100000},
		"unlock_condition": "到达化神期",
		"activated": false
	},
	"LEVELUP": {
		"id": "levelup",
		"name": "直升50级",
		"description": "直接升到50级",
		"effect": {"level": 50},
		"unlock_condition": "完成任意挑战",
		"activated": false
	},
	"MAXSTATS": {
		"id": "maxstats",
		"name": "满属性",
		"description": "全属性最大值",
		"effect": {"all_stats": 999},
		"unlock_condition": "通关最高周目",
		"activated": false
	},
	"ALLITEMS": {
		"id": "allitems",
		"name": "全物品",
		"description": "获得所有道具各10个",
		"effect": {"all_items": 10},
		"unlock_condition": "收集所有图鉴",
		"activated": false
	},
	"TINY": {
		"id": "tiny",
		"name": "变小",
		"description": "角色体型缩小50%",
		"effect": {"scale": 0.5},
		"unlock_condition": "发现第一个彩蛋",
		"activated": false
	},
	"GIANT": {
		"id": "giant",
		"name": "变大",
		"description": "角色体型放大200%",
		"effect": {"scale": 2.0},
		"unlock_condition": "变大变小各一次",
		"activated": false
	}
}

# 彩蛋位置
var easter_eggs: Dictionary = {
	"egg_secret_room": {
		"id": "egg_secret_room",
		"name": "秘密房间",
		"description": "在新手村某个角落发现隐藏房间",
		"location": "新手森林(10, 50)",
		"found": false,
		"reward": "新手宝藏"
	},
	"egg_dev_message": {
		"id": "egg_dev_message",
		"name": "开发者留言",
		"description": "在加载画面等待5分钟",
		"location": "加载画面",
		"found": false,
		"reward": "开发者徽章"
	},
	"egg_mooncake": {
		"id": "egg_mooncake",
		"name": "中秋月饼",
		"description": "在中秋节进入游戏",
		"location": "任何时间",
		"found": false,
		"reward": "月饼×10"
	},
	"egg_speedrun": {
		"id": "egg_speedrun",
		"name": "速通之神",
		"description": "全剧情通关时间少于2小时",
		"location": "任意存档",
		"found": false,
		"reward": "速通称号"
	},
	"egg_no_damage": {
		"id": "egg_no_damage",
		"name": "无伤通关",
		"description": "全程不受任何伤害通关",
		"location": "极限难度",
		"found": false,
		"reward": "无伤称号"
	},
	"egg_collect_all": {
		"id": "egg_collect_all",
		"name": "收藏大师",
		"description": "收集所有装备、宠物、坐骑",
		"location": "任意存档",
		"found": false,
		"reward": "收藏大师称号"
	},
	"egg_nyancat": {
		"id": "egg_nyancat",
		"name": "彩虹猫",
		"description": "连续跳跃100次",
		"location": "任意地图",
		"found": false,
		"reward": "彩虹尾巴时装"
	},
	"egg_konami": {
		"id": "egg_konami",
		"name": "上上下下",
		"description": "输入经典代码",
		"location": "主菜单",
		"found": false,
		"reward": "经典玩家称号"
	}
}

# 已激活的秘籍
var active_cheats: Array = []

# 已找到的彩蛋
var found_eggs: Array = []

func _ready():
	load_cheat_data()

# 输入秘籍
func input_cheat(code: String) -> Dictionary:
	code = code.to_upper()
	
	if not cheat_codes.has(code):
		return {"success": false, "message": "无效秘籍码"}
	
	var cheat = cheat_codes[code]
	
	if cheat.activated:
		return {"success": false, "message": "该秘籍已激活"}
	
	# 激活秘籍
	cheat.activated = true
	active_cheats.append(cheat.id)
	
	emit_signal("cheat_activated", cheat.id, cheat.name)
	save_cheat_data()
	
	return {
		"success": true,
		"name": cheat.name,
		"description": cheat.description,
		"effect": cheat.effect
	}

# 发现彩蛋
func discover_egg(egg_id: String) -> Dictionary:
	if not easter_eggs.has(egg_id):
		return {"success": false, "message": "彩蛋不存在"}
	
	var egg = easter_eggs[egg_id]
	
	if egg.found:
		return {"success": false, "message": "彩蛋已发现"}
	
	egg.found = true
	found_eggs.append(egg_id)
	
	emit_signal("easter_egg_found", egg_id, egg.name)
	save_cheat_data()
	
	return {
		"success": true,
		"name": egg.name,
		"description": egg.description,
		"reward": egg.reward
	}

# 获取秘籍列表
func get_cheat_list() -> Array:
	var result = []
	
	for code in cheat_codes.keys():
		var cheat = cheat_codes[code]
		result.append({
			"code": code,
			"name": cheat.name,
			"description": cheat.description,
			"activated": cheat.activated,
			"unlock_condition": cheat.unlock_condition
		})
	
	return result

# 获取彩蛋列表
func get_egg_list() -> Array:
	var result = []
	
	for egg_id in easter_eggs.keys():
		var egg = easter_eggs[egg_id]
		result.append({
			"id": egg_id,
			"name": egg.name,
			"description": egg.description,
			"location": egg.location,
			"found": egg.found,
			"reward": egg.reward
		})
	
	return result

# 获取已激活的秘籍效果
func get_active_cheat_effects() -> Dictionary:
	var total_effects: Dictionary = {}
	
	for cheat_id in active_cheats:
		for code in cheat_codes.keys():
			if cheat_codes[code].id == cheat_id:
				var effect = cheat_codes[code].effect
				for key in effect.keys():
					total_effects[key] = effect[key]
				break
	
	return total_effects

# 检查是否使用了任何秘籍
func has_cheats_active() -> bool:
	return active_cheats.size() > 0

# 获取统计
func get_stats() -> Dictionary:
	return {
		"total_cheats": cheat_codes.size(),
		"activated_cheats": active_cheats.size(),
		"total_eggs": easter_eggs.size(),
		"found_eggs": found_eggs.size(),
		"cheat_percent": float(active_cheats.size()) / cheat_codes.size() * 100,
		"egg_percent": float(found_eggs.size()) / easter_eggs.size() * 100
	}

# 保存/加载
func save_cheat_data():
	var config = ConfigFile.new()
	
	# 保存秘籍状态
	var cheat_status = {}
	for code in cheat_codes.keys():
		cheat_status[code] = cheat_codes[code].activated
	config.set_value("cheats", "status", cheat_status)
	config.set_value("cheats", "active", active_cheats)
	
	# 保存彩蛋状态
	var egg_status = {}
	for egg_id in easter_eggs.keys():
		egg_status[egg_id] = easter_eggs[egg_id].found
	config.set_value("eggs", "status", egg_status)
	config.set_value("eggs", "found", found_eggs)
	
	config.save("user://cheats.cfg")

func load_cheat_data():
	if FileAccess.file_exists("user://cheats.cfg"):
		var config = ConfigFile.new()
		if config.load("user://cheats.cfg") == OK:
			# 加载秘籍
			var cheat_status = config.get_value("cheats", "status", {})
			for code in cheat_status.keys():
				if cheat_codes.has(code):
					cheat_codes[code].activated = cheat_status[code]
			active_cheats = config.get_value("cheats", "active", [])
			
			# 加载彩蛋
			var egg_status = config.get_value("eggs", "status", {})
			for egg_id in egg_status.keys():
				if easter_eggs.has(egg_id):
					easter_eggs[egg_id].found = egg_status[egg_id]
			found_eggs = config.get_value("eggs", "found", [])
