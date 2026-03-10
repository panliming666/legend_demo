extends Node

class_name SkillTreeSystem

# 技能树系统

signal skill_learned(skill_id: String, skill_name: String)
signal skill_upgraded(skill_id: String, new_level: int)
signal skill_point_gained(points: int)

# 技能分支
enum SkillBranch {
	ATTACK,     # 攻击
	DEFENSE,    # 防御
	UTILITY,    # 辅助
	ULTIMATE    # 终极
}

# 玉清宗·法修技能树
var yuqing_skill_tree: Dictionary = {
	# 攻击分支
	"fire_mastery": {
		"name": "火系精通",
		"branch": SkillBranch.ATTACK,
		"max_level": 5,
		"description": "火系技能伤害提升",
		"effect": {"fire_damage": 0.1},
		"prerequisites": [],
		"cost": 1,
		"icon": "🔥"
	},
	"thunder_mastery": {
		"name": "雷系精通",
		"branch": SkillBranch.ATTACK,
		"max_level": 5,
		"description": "雷系技能伤害提升",
		"effect": {"thunder_damage": 0.1},
		"prerequisites": [],
		"cost": 1,
		"icon": "⚡"
	},
	"ice_mastery": {
		"name": "冰系精通",
		"branch": SkillBranch.ATTACK,
		"max_level": 5,
		"description": "冰系技能伤害和减速效果提升",
		"effect": {"ice_damage": 0.08, "slow_effect": 0.1},
		"prerequisites": [],
		"cost": 1,
		"icon": "❄️"
	},
	"ultimate_magic": {
		"name": "法术奥义",
		"branch": SkillBranch.ULTIMATE,
		"max_level": 3,
		"description": "所有法术伤害大幅提升",
		"effect": {"all_magic_damage": 0.15},
		"prerequisites": ["fire_mastery", "thunder_mastery", "ice_mastery"],
		"cost": 3,
		"icon": "✨"
	},
	
	# 防御分支
	"magic_shield": {
		"name": "魔法护盾",
		"branch": SkillBranch.DEFENSE,
		"max_level": 5,
		"description": "获得可吸收伤害的魔法护盾",
		"effect": {"shield_absorb": 50},
		"prerequisites": [],
		"cost": 1,
		"icon": "🛡️"
	},
	"spell_resistance": {
		"name": "法术抗性",
		"branch": SkillBranch.DEFENSE,
		"max_level": 5,
		"description": "减少受到的魔法伤害",
		"effect": {"magic_resist": 0.05},
		"prerequisites": [],
		"cost": 1,
		"icon": "🧿"
	},
	"mana_regen": {
		"name": "法力回复",
		"branch": SkillBranch.UTILITY,
		"max_level": 5,
		"description": "法力自然恢复速度提升",
		"effect": {"mp_regen": 2},
		"prerequisites": [],
		"cost": 1,
		"icon": "💧"
	},
	"cast_speed": {
		"name": "施法速度",
		"branch": SkillBranch.UTILITY,
		"max_level": 5,
		"description": "减少技能冷却时间",
		"effect": {"cooldown_reduction": 0.05},
		"prerequisites": [],
		"cost": 1,
		"icon": "⚡"
	}
}

# 上清宗·符修技能树
var shangqing_skill_tree: Dictionary = {
	"summon_mastery": {
		"name": "召唤精通",
		"branch": SkillBranch.ATTACK,
		"max_level": 5,
		"description": "召唤物属性提升",
		"effect": {"summon_stat": 0.1},
		"prerequisites": [],
		"cost": 1,
		"icon": "👻"
	},
	"poison_mastery": {
		"name": "毒术精通",
		"branch": SkillBranch.ATTACK,
		"max_level": 5,
		"description": "毒伤效果增强",
		"effect": {"poison_damage": 0.1, "poison_duration": 1},
		"prerequisites": [],
		"cost": 1,
		"icon": "☠️"
	},
	"healing_mastery": {
		"name": "治疗精通",
		"branch": SkillBranch.UTILITY,
		"max_level": 5,
		"description": "治疗效果提升",
		"effect": {"heal_amount": 0.1},
		"prerequisites": [],
		"cost": 1,
		"icon": "💚"
	},
	"blessing_mastery": {
		"name": "增益精通",
		"branch": SkillBranch.UTILITY,
		"max_level": 5,
		"description": "增益技能效果延长",
		"effect": {"buff_duration": 0.15},
		"prerequisites": ["healing_mastery"],
		"cost": 1,
		"icon": "🌟"
	},
	"spirit_control": {
		"name": "御灵术",
		"branch": SkillBranch.DEFENSE,
		"max_level": 5,
		"description": "召唤物分担伤害",
		"effect": {"damage_transfer": 0.05},
		"prerequisites": ["summon_mastery"],
		"cost": 1,
		"icon": "🌀"
	},
	"ultimate_summon": {
		"name": "万灵召唤",
		"branch": SkillBranch.ULTIMATE,
		"max_level": 1,
		"description": "可同时召唤更多灵宠",
		"effect": {"summon_limit": 1},
		"prerequisites": ["summon_mastery", "spirit_control"],
		"cost": 5,
		"icon": "👑"
	}
}

# 太清宗·剑修技能树
var taiqing_skill_tree: Dictionary = {
	"sword_mastery": {
		"name": "剑术精通",
		"branch": SkillBranch.ATTACK,
		"max_level": 5,
		"description": "剑系技能伤害提升",
		"effect": {"sword_damage": 0.1},
		"prerequisites": [],
		"cost": 1,
		"icon": "🗡️"
	},
	"critical_strike": {
		"name": "致命一击",
		"branch": SkillBranch.ATTACK,
		"max_level": 5,
		"description": "暴击率和暴击伤害提升",
		"effect": {"crit_rate": 2, "crit_damage": 0.1},
		"prerequisites": [],
		"cost": 1,
		"icon": "⚔️"
	},
	"armor_mastery": {
		"name": "护甲精通",
		"branch": SkillBranch.DEFENSE,
		"max_level": 5,
		"description": "防御力提升",
		"effect": {"defense": 5},
		"prerequisites": [],
		"cost": 1,
		"icon": "🛡️"
	},
	"life_force": {
		"name": "生命强化",
		"branch": SkillBranch.DEFENSE,
		"max_level": 5,
		"description": "生命上限提升",
		"effect": {"max_hp": 50},
		"prerequisites": [],
		"cost": 1,
		"icon": "❤️"
	},
	"sword_qi": {
		"name": "剑气外放",
		"branch": SkillBranch.ATTACK,
		"max_level": 3,
		"description": "普通攻击有几率发射剑气",
		"effect": {"sword_qi_chance": 0.1},
		"prerequisites": ["sword_mastery"],
		"cost": 2,
		"icon": "💨"
	},
	"ultimate_sword": {
		"name": "人剑合一",
		"branch": SkillBranch.ULTIMATE,
		"max_level": 1,
		"description": "终极技能，大幅提升全属性",
		"effect": {"all_stats": 0.2},
		"prerequisites": ["sword_mastery", "critical_strike"],
		"cost": 5,
		"icon": "👑"
	}
}

# 玩家技能数据
var skill_levels: Dictionary = {}  # skill_id: level
var available_points: int = 0

func _ready():
	load_skills()

# 获取技能树
func get_skill_tree(class_type: int) -> Dictionary:
	match class_type:
		0: return yuqing_skill_tree  # 法修
		1: return shangqing_skill_tree  # 符修
		2: return taiqing_skill_tree  # 剑修
	return {}

# 学习技能
func learn_skill(skill_id: String, class_type: int) -> bool:
	var tree = get_skill_tree(class_type)
	var skill = tree.get(skill_id)
	
	if skill == null:
		return false
	
	# 检查是否已学满
	var current_level = skill_levels.get(skill_id, 0)
	if current_level >= skill.max_level:
		return false
	
	# 检查点数
	if available_points < skill.cost:
		return false
	
	# 检查前置技能
	for prereq in skill.prerequisites:
		if skill_levels.get(prereq, 0) == 0:
			return false
	
	# 学习技能
	skill_levels[skill_id] = current_level + 1
	available_points -= skill.cost
	
	if current_level == 0:
		emit_signal("skill_learned", skill_id, skill.name)
	else:
		emit_signal("skill_upgraded", skill_id, current_level + 1)
	
	save_skills()
	print("学习技能：", skill.name, " Lv.", current_level + 1)
	return true

# 获得技能点
func gain_skill_points(points: int):
	available_points += points
	emit_signal("skill_point_gained", points)
	print("获得技能点：", points)

# 计算总效果
func calculate_effects() -> Dictionary:
	var effects: Dictionary = {}
	
	for skill_id in skill_levels.keys():
		var level = skill_levels[skill_id]
		
		# 从所有技能树中查找
		var skill = null
		for tree in [yuqing_skill_tree, shangqing_skill_tree, taiqing_skill_tree]:
			if tree.has(skill_id):
				skill = tree[skill_id]
				break
		
		if skill == null:
			continue
		
		# 叠加效果
		for key in skill.effect.keys():
			if not effects.has(key):
				effects[key] = 0
			effects[key] += skill.effect[key] * level
	
	return effects

# 获取技能状态
func get_skill_status(skill_id: String, class_type: int) -> Dictionary:
	var tree = get_skill_tree(class_type)
	var skill = tree.get(skill_id)
	
	if skill == null:
		return {}
	
	var current_level = skill_levels.get(skill_id, 0)
	var can_learn = true
	var reason = ""
	
	if current_level >= skill.max_level:
		can_learn = false
		reason = "已达最高等级"
	elif available_points < skill.cost:
		can_learn = false
		reason = "技能点不足"
	else:
		# 检查前置
		for prereq in skill.prerequisites:
			if skill_levels.get(prereq, 0) == 0:
				can_learn = false
				reason = "前置技能未学习"
				break
	
	return {
		"id": skill_id,
		"name": skill.name,
		"description": skill.description,
		"level": current_level,
		"max_level": skill.max_level,
		"cost": skill.cost,
		"branch": skill.branch,
		"icon": skill.icon,
		"effect": skill.effect,
		"can_learn": can_learn,
		"reason": reason
	}

# 获取所有技能状态
func get_all_skills_status(class_type: int) -> Array:
	var tree = get_skill_tree(class_type)
	var result = []
	
	for skill_id in tree.keys():
		result.append(get_skill_status(skill_id, class_type))
	
	return result

# 获取可用点数
func get_available_points() -> int:
	return available_points

# 重置技能树
func reset_skills():
	var total_spent = 0
	for skill_id in skill_levels.keys():
		for tree in [yuqing_skill_tree, shangqing_skill_tree, taiqing_skill_tree]:
			if tree.has(skill_id):
				total_spent += tree[skill_id].cost * skill_levels[skill_id]
				break
	
	available_points += total_spent
	skill_levels.clear()
	save_skills()
	print("技能树已重置")

# 保存/加载
func save_skills():
	var config = ConfigFile.new()
	config.set_value("skills", "levels", skill_levels)
	config.set_value("skills", "points", available_points)
	config.save("user://skills.cfg")

func load_skills():
	if FileAccess.file_exists("user://skills.cfg"):
		var config = ConfigFile.new()
		if config.load("user://skills.cfg") == OK:
			skill_levels = config.get_value("skills", "levels", {})
			available_points = config.get_value("skills", "points", 0)
