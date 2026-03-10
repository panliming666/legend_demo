extends Node

class_name CharacterClass

# 三清问道 - 职业系统

enum ClassType {
	YUQING_FA,    # 玉清宗 · 法修（原法师）
	SHANGQING_FU, # 上清宗 · 符修（原道士）
	TAIQING_JIAN  # 太清宗 · 剑修（原战士）
}

# 职业名称
var class_names: Dictionary = {
	ClassType.YUQING_FA: "法修",
	ClassType.SHANGQING_FU: "符修",
	ClassType.TAIQING_JIAN: "剑修"
}

# 宗门名称
var sect_names: Dictionary = {
	ClassType.YUQING_FA: "玉清宗",
	ClassType.SHANGQING_FU: "上清宗",
	ClassType.TAIQING_JIAN: "太清宗"
}

# 天尊名称
var tianzun_names: Dictionary = {
	ClassType.YUQING_FA: "元始天尊",
	ClassType.SHANGQING_FU: "灵宝天尊",
	ClassType.TAIQING_JIAN: "道德天尊"
}

# 境界系统
enum Realm {
	LIANQI,    # 炼气期
	ZHUJI,     # 筑基期
	JINDAN,    # 金丹期
	YUANYING,  # 元婴期
	HUASHEN    # 化神期
}

# 境界名称
var realm_names: Dictionary = {
	Realm.LIANQI: "炼气期",
	Realm.ZHUJI: "筑基期",
	Realm.JINDAN: "金丹期",
	Realm.YUANYING: "元婴期",
	Realm.HUASHEN: "化神期"
}

# 称号系统
var titles: Dictionary = {
	ClassType.YUQING_FA: {
		Realm.LIANQI: "玄元童子",
		Realm.ZHUJI: "玄元真人",
		Realm.JINDAN: "玄元尊者",
		Realm.YUANYING: "玄元仙师",
		Realm.HUASHEN: "玄元真君"
	},
	ClassType.SHANGQING_FU: {
		Realm.LIANQI: "灵宝童子",
		Realm.ZHUJI: "灵宝真人",
		Realm.JINDAN: "灵宝尊者",
		Realm.YUANYING: "灵宝仙师",
		Realm.HUASHEN: "灵宝真君"
	},
	ClassType.TAIQING_JIAN: {
		Realm.LIANQI: "道德童子",
		Realm.ZHUJI: "道德真人",
		Realm.JINDAN: "道德尊者",
		Realm.YUANYING: "道德仙师",
		Realm.HUASHEN: "道德真君"
	}
}

# 主属性名
var main_attribute: Dictionary = {
	ClassType.YUQING_FA: "法力",
	ClassType.SHANGQING_FU: "道法",
	ClassType.TAIQING_JIAN: "武力"
}

# 基础属性配置
var base_stats: Dictionary = {
	ClassType.YUQING_FA: {
		"max_hp": 70,
		"max_mp": 120,
		"main_attack": 20,  # 法力
		"defense": 3,
		"attack_range": 250,
		"walk_speed": 130,
		"run_speed": 200
	},
	ClassType.SHANGQING_FU: {
		"max_hp": 80,
		"max_mp": 90,
		"main_attack": 15,  # 道法
		"defense": 4,
		"attack_range": 200,
		"walk_speed": 140,
		"run_speed": 210
	},
	ClassType.TAIQING_JIAN: {
		"max_hp": 100,
		"max_mp": 50,
		"main_attack": 15,  # 武力
		"defense": 5,
		"attack_range": 50,
		"walk_speed": 150,
		"run_speed": 220
	}
}

# 技能配置
var skill_configs: Dictionary = {
	ClassType.YUQING_FA: {
		"linghuo": {"name": "灵火术", "level": 1, "mp_cost": 5, "damage": 15, "cooldown": 1.0, "type": "single"},
		"leifa": {"name": "雷法·引雷诀", "level": 5, "mp_cost": 15, "damage": 40, "cooldown": 3.0, "type": "single"},
		"xuanbing": {"name": "玄冰咒", "level": 10, "mp_cost": 12, "damage": 25, "cooldown": 2.5, "type": "single", "effect": "slow"},
		"wuxing": {"name": "五行遁术", "level": 15, "mp_cost": 20, "cooldown": 8.0, "type": "teleport"},
		"jiutian": {"name": "九天神雷", "level": 20, "mp_cost": 30, "damage": 80, "cooldown": 10.0, "type": "aoe"},
		"hunyuan": {"name": "混元金光", "level": 25, "mp_cost": 25, "cooldown": 15.0, "type": "shield"},
		"tiandi": {"name": "天地法相", "level": 30, "mp_cost": 50, "damage": 150, "cooldown": 30.0, "type": "summon"}
	},
	ClassType.SHANGQING_FU: {
		"huichun": {"name": "回春符", "level": 1, "mp_cost": 8, "heal": 30, "cooldown": 2.0, "type": "heal"},
		"fugu": {"name": "腐骨符", "level": 1, "mp_cost": 6, "damage": 10, "duration": 5.0, "cooldown": 3.0, "type": "dot"},
		"guling": {"name": "召唤·骨灵", "level": 5, "mp_cost": 20, "summon_count": 2, "cooldown": 5.0, "type": "summon"},
		"kunling": {"name": "困灵符", "level": 10, "mp_cost": 15, "duration": 3.0, "cooldown": 8.0, "type": "trap"},
		"ruishou": {"name": "召唤·瑞兽", "level": 15, "mp_cost": 30, "cooldown": 10.0, "type": "summon"},
		"qunti": {"name": "群体治愈", "level": 20, "mp_cost": 25, "heal": 50, "cooldown": 12.0, "type": "aoe_heal"},
		"tianjiang": {"name": "召唤·天将", "level": 25, "mp_cost": 40, "cooldown": 20.0, "type": "summon"},
		"lingbao": {"name": "灵宝金光咒", "level": 30, "mp_cost": 50, "cooldown": 30.0, "type": "buff"}
	},
	ClassType.TAIQING_JIAN: {
		"jichu": {"name": "基础剑法", "level": 1, "mp_cost": 0, "damage": 10, "cooldown": 0.5, "type": "attack"},
		"jianqi": {"name": "剑气斩", "level": 5, "mp_cost": 10, "damage": 30, "range": 150, "cooldown": 2.0, "type": "ranged"},
		"jifeng": {"name": "疾风剑", "level": 10, "mp_cost": 15, "damage": 20, "hit_count": 3, "cooldown": 4.0, "type": "multi"},
		"pojun": {"name": "剑意·破军", "level": 15, "mp_cost": 25, "damage": 80, "cooldown": 8.0, "type": "single"},
		"yujian": {"name": "御剑术", "level": 20, "mp_cost": 20, "damage": 40, "range": 200, "cooldown": 5.0, "type": "ranged"},
		"qianjian": {"name": "剑阵·千剑归宗", "level": 25, "mp_cost": 40, "damage": 100, "cooldown": 15.0, "type": "aoe"},
		"tianren": {"name": "天人合一", "level": 30, "mp_cost": 50, "cooldown": 30.0, "type": "buff"}
	}
}

# 获取职业信息
func get_class_info(class_type: int) -> Dictionary:
	return {
		"name": class_names.get(class_type, "未知"),
		"sect": sect_names.get(class_type, "未知"),
		"tianzun": tianzun_names.get(class_type, "未知"),
		"main_attribute": main_attribute.get(class_type, "未知"),
		"base_stats": base_stats.get(class_type, {}),
		"skills": skill_configs.get(class_type, {})
	}

# 获取称号
func get_title(class_type: int, realm: int) -> String:
	var class_titles = titles.get(class_type, {})
	return class_titles.get(realm, "无名")

# 获取境界名称
func get_realm_name(realm: int) -> String:
	return realm_names.get(realm, "未知境界")

# 计算境界属性加成
func get_realm_bonus(realm: int) -> float:
	match realm:
		Realm.LIANQI: return 1.0
		Realm.ZHUJI: return 1.2
		Realm.JINDAN: return 1.5
		Realm.YUANYING: return 2.0
		Realm.HUASHEN: return 3.0
	return 1.0

# 计算升级所需经验
func get_exp_for_realm(realm: int, level: int) -> int:
	var base_exp = [100, 500, 2000, 10000, 50000]
	var realm_base = base_exp[realm] if realm < base_exp.size() else 100000
	return realm_base * (1 + level * 0.5)

# 获取解锁技能列表
func get_unlocked_skills(class_type: int, player_level: int) -> Array:
	var all_skills = skill_configs.get(class_type, {})
	var unlocked = []
	
	for skill_id in all_skills.keys():
		var skill = all_skills[skill_id]
		if skill.level <= player_level:
			unlocked.append({
				"id": skill_id,
				"data": skill
			})
	
	return unlocked

# 拜师选择界面数据
func get_sect_selection() -> Array:
	return [
		{
			"sect": "玉清宗",
			"tianzun": "元始天尊",
			"class_type": ClassType.YUQING_FA,
			"class_name": "法修",
			"description": "操控天地法则，释放元素法术\n主修：法力\n特点：远程魔法伤害，范围攻击",
			"book": "《玉清玄法录》"
		},
		{
			"sect": "上清宗",
			"tianzun": "灵宝天尊",
			"class_type": ClassType.SHANGQING_FU,
			"class_name": "符修",
			"description": "符箓咒术，召唤灵兽，辅助治疗\n主修：道法\n特点：召唤灵宠，团队辅助",
			"book": "《上清灵宝经》"
		},
		{
			"sect": "太清宗",
			"tianzun": "道德天尊",
			"class_type": ClassType.TAIQING_JIAN,
			"class_name": "剑修",
			"description": "炼体修剑，近战无敌，肉身成圣\n主修：武力\n特点：高防御，近战输出",
			"book": "《太清剑道篇》"
		}
	]
