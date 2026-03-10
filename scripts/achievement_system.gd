extends Node

class_name AchievementSystem

# 成就系统

signal achievement_unlocked(achievement_id: String, reward: Dictionary)

# 成就类型
enum AchievementType {
	LEVEL,      # 等级成就
	COMBAT,     # 战斗成就
	EXPLORE,    # 探索成就
	COLLECT,    # 收集成就
	SPECIAL,    # 特殊成就
	DAILY       # 每日成就
}

# 成就数据库
var achievement_database: Dictionary = {
	# 等级成就
	"level_5": {
		"type": AchievementType.LEVEL,
		"name": "初窥门径",
		"description": "达到5级",
		"requirement": {"level": 5},
		"reward": {"gold": 100},
		"icon": "⭐"
	},
	"level_10": {
		"type": AchievementType.LEVEL,
		"name": "小有所成",
		"description": "达到10级",
		"requirement": {"level": 10},
		"reward": {"gold": 200},
		"icon": "⭐⭐"
	},
	"level_20": {
		"type": AchievementType.LEVEL,
		"name": "筑基成功",
		"description": "达到20级（筑基期）",
		"requirement": {"level": 20},
		"reward": {"gold": 500, "items": ["筑基丹×1"]},
		"icon": "⭐⭐⭐"
	},
	"level_30": {
		"type": AchievementType.LEVEL,
		"name": "金丹大道",
		"description": "达到30级（金丹期）",
		"requirement": {"level": 30},
		"reward": {"gold": 1000, "items": ["金丹丹×1"]},
		"icon": "⭐⭐⭐⭐"
	},
	"level_50": {
		"type": AchievementType.LEVEL,
		"name": "元婴真君",
		"description": "达到50级（元婴期）",
		"requirement": {"level": 50},
		"reward": {"gold": 5000, "items": ["元婴丹×1"]},
		"icon": "🌟"
	},
	
	# 战斗成就
	"kill_100": {
		"type": AchievementType.COMBAT,
		"name": "初出茅庐",
		"description": "累计击杀100只怪物",
		"requirement": {"kill_count": 100},
		"reward": {"gold": 200},
		"icon": "⚔️"
	},
	"kill_1000": {
		"type": AchievementType.COMBAT,
		"name": "斩妖除魔",
		"description": "累计击杀1000只怪物",
		"requirement": {"kill_count": 1000},
		"reward": {"gold": 1000},
		"icon": "⚔️⚔️"
	},
	"kill_boss_1": {
		"type": AchievementType.COMBAT,
		"name": "Boss杀手",
		"description": "击杀1只Boss",
		"requirement": {"boss_kill": 1},
		"reward": {"gold": 500},
		"icon": "👹"
	},
	"kill_boss_10": {
		"type": AchievementType.COMBAT,
		"name": "Boss克星",
		"description": "累计击杀10只Boss",
		"requirement": {"boss_kill": 10},
		"reward": {"gold": 2000},
		"icon": "👹👹"
	},
	"die_1": {
		"type": AchievementType.COMBAT,
		"name": "死里逃生",
		"description": "死亡1次",
		"requirement": {"death": 1},
		"reward": {"gold": 50},
		"icon": "💀"
	},
	
	# 探索成就
	"enter_dungeon_1": {
		"type": AchievementType.EXPLORE,
		"name": "初入秘境",
		"description": "进入1次秘境",
		"requirement": {"dungeon_enter": 1},
		"reward": {"gold": 100},
		"icon": "🗝️"
	},
	"clear_dungeon_1": {
		"type": AchievementType.EXPLORE,
		"name": "秘境探索者",
		"description": "通关1次秘境",
		"requirement": {"dungeon_clear": 1},
		"reward": {"gold": 300},
		"icon": "🏆"
	},
	"clear_dungeon_10": {
		"type": AchievementType.EXPLORE,
		"name": "秘境征服者",
		"description": "通关10次秘境",
		"requirement": {"dungeon_clear": 10},
		"reward": {"gold": 1000},
		"icon": "🏆🏆"
	},
	"visit_map_5": {
		"type": AchievementType.EXPLORE,
		"name": "云游四方",
		"description": "访问5张地图",
		"requirement": {"map_visit": 5},
		"reward": {"gold": 200},
		"icon": "🗺️"
	},
	
	# 收集成就
	"collect_item_100": {
		"type": AchievementType.COLLECT,
		"name": "收集爱好者",
		"description": "累计获得100件物品",
		"requirement": {"item_collect": 100},
		"reward": {"gold": 300},
		"icon": "📦"
	},
	"equip_rare_1": {
		"type": AchievementType.COLLECT,
		"name": "福缘深厚",
		"description": "获得1件稀有装备",
		"requirement": {"rare_equip": 1},
		"reward": {"gold": 500},
		"icon": "💎"
	},
	"own_pet_1": {
		"type": AchievementType.COLLECT,
		"name": "灵宠结缘",
		"description": "获得1只灵宠",
		"requirement": {"pet_count": 1},
		"reward": {"gold": 200},
		"icon": "🐾"
	},
	"own_mount_1": {
		"type": AchievementType.COLLECT,
		"name": "神驹相伴",
		"description": "获得1只坐骑",
		"requirement": {"mount_count": 1},
		"reward": {"gold": 300},
		"icon": "🐴"
	},
	
	# 特殊成就
	"first_login": {
		"type": AchievementType.SPECIAL,
		"name": "初入仙途",
		"description": "首次登录游戏",
		"requirement": {"login": 1},
		"reward": {"gold": 100},
		"icon": "🎮"
	},
	"online_1h": {
		"type": AchievementType.SPECIAL,
		"name": "初学乍练",
		"description": "累计在线1小时",
		"requirement": {"online_time": 3600},
		"reward": {"gold": 200},
		"icon": "⏰"
	},
	"online_100h": {
		"type": AchievementType.SPECIAL,
		"name": "修仙有成",
		"description": "累计在线100小时",
		"requirement": {"online_time": 360000},
		"reward": {"gold": 5000},
		"icon": "⏰⏰"
	},
	"rich": {
		"type": AchievementType.SPECIAL,
		"name": "富甲天下",
		"description": "拥有10000金币",
		"requirement": {"gold": 10000},
		"reward": {"items": ["财运丹×3"]},
		"icon": "💰"
	}
}

# 玩家成就进度
var achievement_progress: Dictionary = {}  # achievement_id: current_value
var unlocked_achievements: Array = []  # 已解锁的成就ID列表
var total_achievements: int = 0

func _ready():
	load_achievements()
	total_achievements = achievement_database.size()

# 更新成就进度
func update_progress(progress_type: String, amount: int):
	# 检查所有相关成就
	for ach_id in achievement_database.keys():
		var ach = achievement_database[ach_id]
		if ach_id in unlocked_achievements:
			continue
		
		var req = ach.requirement
		if not req.has(progress_type):
			continue
		
		var target = req[progress_type]
		
		# 初始化进度
		if not achievement_progress.has(ach_id):
			achievement_progress[ach_id] = 0
		
		# 更新进度
		achievement_progress[ach_id] += amount
		
		# 检查是否达成
		if achievement_progress[ach_id] >= target:
			unlock_achievement(ach_id)

# 解锁成就
func unlock_achievement(ach_id: String):
	if ach_id in unlocked_achievements:
		return
	
	var ach = achievement_database.get(ach_id)
	if ach == null:
		return
	
	unlocked_achievements.append(ach_id)
	
	# 发放奖励
	var reward = ach.reward.duplicate()
	
	emit_signal("achievement_unlocked", ach_id, reward)
	print("成就解锁：", ach.name, " - 奖励：", reward)
	
	# 发送系统邮件
	send_reward_mail(ach.name, reward)
	
	save_achievements()

# 发送奖励邮件
func send_reward_mail(achievement_name: String, reward: Dictionary):
	# 这里应该调用邮件系统
	print("发送奖励邮件：", achievement_name)

# 获取成就状态
func get_achievement_status(ach_id: String) -> Dictionary:
	var ach = achievement_database.get(ach_id, {})
	var unlocked = ach_id in unlocked_achievements
	var progress = achievement_progress.get(ach_id, 0)
	var target = ach.requirement.values()[0] if ach.has("requirement") else 0
	
	return {
		"unlocked": unlocked,
		"progress": progress,
		"target": target,
		"percent": float(progress) / target * 100 if target > 0 else 0
	}

# 获取所有成就
func get_all_achievements() -> Array:
	var result = []
	
	for ach_id in achievement_database.keys():
		var ach = achievement_database[ach_id]
		var status = get_achievement_status(ach_id)
		
		result.append({
			"id": ach_id,
			"name": ach.name,
			"description": ach.description,
			"type": ach.type,
			"icon": ach.icon,
			"reward": ach.reward,
			"unlocked": status.unlocked,
			"progress": status.progress,
			"target": status.target,
			"percent": status.percent
		})
	
	return result

# 获取已解锁成就数
func get_unlocked_count() -> int:
	return unlocked_achievements.size()

# 获取成就进度百分比
func get_total_progress() -> float:
	if total_achievements == 0:
		return 0
	return float(unlocked_achievements.size()) / total_achievements * 100

# 便捷方法：等级变化
func on_level_up(new_level: int):
	update_progress("level", new_level)

# 便捷方法：击杀怪物
func on_kill_monster(is_boss: bool = false):
	update_progress("kill_count", 1)
	if is_boss:
		update_progress("boss_kill", 1)

# 便捷方法：死亡
func on_player_die():
	update_progress("death", 1)

# 便捷方法：进入秘境
func on_enter_dungeon():
	update_progress("dungeon_enter", 1)

# 便捷方法：通关秘境
func on_clear_dungeon():
	update_progress("dungeon_clear", 1)

# 便捷方法：获得物品
func on_collect_item():
	update_progress("item_collect", 1)

# 便捷方法：登录
func on_login():
	update_progress("login", 1)

# 保存/加载
func save_achievements():
	var config = ConfigFile.new()
	config.set_value("achievements", "progress", achievement_progress)
	config.set_value("achievements", "unlocked", unlocked_achievements)
	config.save("user://achievements.cfg")

func load_achievements():
	if FileAccess.file_exists("user://achievements.cfg"):
		var config = ConfigFile.new()
		if config.load("user://achievements.cfg") == OK:
			achievement_progress = config.get_value("achievements", "progress", {})
			unlocked_achievements = config.get_value("achievements", "unlocked", [])
