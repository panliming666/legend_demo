extends Node

class_name AlchemySystem

# 炼丹系统

signal pill_crafted(pill_name: String, count: int)
signal pill_used(pill_name: String, effect: Dictionary)

# 丹药类型
enum PillType {
	# 治疗类
	HEALING_SMALL,    # 回春丹（小）
	HEALING_MEDIUM,   # 回春丹（中）
	HEALING_LARGE,    # 回春丹（大）
	HEALING_ULTIMATE, # 还魂丹
	
	# 法力类
	MP_SMALL,        # 聚气丹（小）
	MP_MEDIUM,       # 聚气丹（中）
	MP_LARGE,        # 聚气丹（大）
	
	# 增益类
	ATTACK_BOOST,    # 巨力丹
	DEFENSE_BOOST,   # 金刚丹
	SPEED_BOOST,     # 神行丹
	CRITICAL_BOOST,  # 必杀丹
	
	# 境界类
	BREAKTHROUGH_ZHUJI,  # 筑基丹
	BREAKTHROUGH_JINDAN, # 金丹丹
	BREAKTHROUGH_YUANYING, # 元婴丹
	BREAKTHROUGH_HUASHEN, # 化神丹
	
	# 特殊类
	REBIRTH,         # 复活丹
	EXP_BOOST,       # 悟道丹（经验加成）
	LOOT_BOOST       # 财运丹（掉落加成）
}

# 丹药数据
var pill_database: Dictionary = {
	PillType.HEALING_SMALL: {
		"name": "回春丹（小）",
		"type": "healing",
		"effect": {"hp": 50},
		"duration": 0,  # 即时
		"materials": {"灵草": 2},
		"success_rate": 0.95,
		"required_level": 1,
		"description": "恢复50点生命"
	},
	PillType.HEALING_MEDIUM: {
		"name": "回春丹（中）",
		"type": "healing",
		"effect": {"hp": 150},
		"duration": 0,
		"materials": {"灵草": 5, "灵芝": 1},
		"success_rate": 0.9,
		"required_level": 10,
		"description": "恢复150点生命"
	},
	PillType.HEALING_LARGE: {
		"name": "回春丹（大）",
		"type": "healing",
		"effect": {"hp": 500},
		"duration": 0,
		"materials": {"灵芝": 3, "仙草": 1},
		"success_rate": 0.85,
		"required_level": 25,
		"description": "恢复500点生命"
	},
	PillType.HEALING_ULTIMATE: {
		"name": "还魂丹",
		"type": "healing",
		"effect": {"hp_percent": 100},
		"duration": 0,
		"materials": {"仙草": 5, "神草": 1},
		"success_rate": 0.7,
		"required_level": 40,
		"description": "完全恢复生命"
	},
	PillType.MP_SMALL: {
		"name": "聚气丹（小）",
		"type": "mp",
		"effect": {"mp": 30},
		"duration": 0,
		"materials": {"灵草": 1, "灵石碎片": 1},
		"success_rate": 0.95,
		"required_level": 5,
		"description": "恢复30点法力"
	},
	PillType.MP_MEDIUM: {
		"name": "聚气丹（中）",
		"type": "mp",
		"effect": {"mp": 100},
		"duration": 0,
		"materials": {"灵芝": 2, "灵石碎片": 3},
		"success_rate": 0.9,
		"required_level": 15,
		"description": "恢复100点法力"
	},
	PillType.MP_LARGE: {
		"name": "聚气丹（大）",
		"type": "mp",
		"effect": {"mp": 300},
		"duration": 0,
		"materials": {"仙草": 2, "灵石": 1},
		"success_rate": 0.85,
		"required_level": 30,
		"description": "恢复300点法力"
	},
	PillType.ATTACK_BOOST: {
		"name": "巨力丹",
		"type": "buff",
		"effect": {"attack_percent": 20},
		"duration": 300,  # 5分钟
		"materials": {"虎骨": 3, "灵草": 2},
		"success_rate": 0.8,
		"required_level": 10,
		"description": "攻击力提升20%，持续5分钟"
	},
	PillType.DEFENSE_BOOST: {
		"name": "金刚丹",
		"type": "buff",
		"effect": {"defense_percent": 20},
		"duration": 300,
		"materials": {"龟甲": 3, "灵草": 2},
		"success_rate": 0.8,
		"required_level": 10,
		"description": "防御力提升20%，持续5分钟"
	},
	PillType.SPEED_BOOST: {
		"name": "神行丹",
		"type": "buff",
		"effect": {"speed_percent": 30},
		"duration": 180,
		"materials": {"凤羽": 1, "灵草": 3},
		"success_rate": 0.75,
		"required_level": 15,
		"description": "移动速度提升30%，持续3分钟"
	},
	PillType.CRITICAL_BOOST: {
		"name": "必杀丹",
		"type": "buff",
		"effect": {"crit_rate": 50, "crit_damage": 100},
		"duration": 120,
		"materials": {"龙血": 1, "灵芝": 3},
		"success_rate": 0.7,
		"required_level": 25,
		"description": "暴击率+50%，暴击伤害+100%，持续2分钟"
	},
	PillType.BREAKTHROUGH_ZHUJI: {
		"name": "筑基丹",
		"type": "breakthrough",
		"effect": {"breakthrough_chance": 0.5},
		"duration": 0,
		"materials": {"筑基草": 5, "灵石": 10, "妖丹": 1},
		"success_rate": 0.6,
		"required_level": 20,
		"description": "增加筑基期突破成功率50%"
	},
	PillType.BREAKTHROUGH_JINDAN: {
		"name": "金丹丹",
		"type": "breakthrough",
		"effect": {"breakthrough_chance": 0.4},
		"duration": 0,
		"materials": {"金丹草": 5, "灵石": 20, "妖王丹": 1},
		"success_rate": 0.5,
		"required_level": 35,
		"description": "增加金丹期突破成功率40%"
	},
	PillType.BREAKTHROUGH_YUANYING: {
		"name": "元婴丹",
		"type": "breakthrough",
		"effect": {"breakthrough_chance": 0.3},
		"duration": 0,
		"materials": {"元婴果": 3, "灵石": 50, "仙丹": 1},
		"success_rate": 0.4,
		"required_level": 45,
		"description": "增加元婴期突破成功率30%"
	},
	PillType.BREAKTHROUGH_HUASHEN: {
		"name": "化神丹",
		"type": "breakthrough",
		"effect": {"breakthrough_chance": 0.2},
		"duration": 0,
		"materials": {"化神花": 1, "灵石": 100, "神丹": 1},
		"success_rate": 0.3,
		"required_level": 55,
		"description": "增加化神期突破成功率20%"
	},
	PillType.REBIRTH: {
		"name": "复活丹",
		"type": "special",
		"effect": {"revive": true, "hp_percent": 30},
		"duration": 0,
		"materials": {"仙草": 10, "神草": 3, "凤凰羽": 2},
		"success_rate": 0.5,
		"required_level": 30,
		"description": "死亡后自动复活，恢复30%生命"
	},
	PillType.EXP_BOOST: {
		"name": "悟道丹",
		"type": "special",
		"effect": {"exp_percent": 50},
		"duration": 600,
		"materials": {"悟道草": 3, "灵石": 5},
		"success_rate": 0.7,
		"required_level": 15,
		"description": "经验获取+50%，持续10分钟"
	},
	PillType.LOOT_BOOST: {
		"name": "财运丹",
		"type": "special",
		"effect": {"loot_percent": 30},
		"duration": 600,
		"materials": {"财运草": 3, "灵石": 5},
		"success_rate": 0.7,
		"required_level": 15,
		"description": "掉落率+30%，持续10分钟"
	}
}

# 玩家丹药库存
var inventory: Dictionary = {}  # pill_type: count

# 炼丹等级
var alchemy_level: int = 1
var alchemy_exp: int = 0

# 材料库存
var materials: Dictionary = {
	"灵草": 50,
	"灵芝": 20,
	"仙草": 5,
	"神草": 0,
	"灵石碎片": 30,
	"灵石": 10,
	"虎骨": 10,
	"龟甲": 10,
	"凤羽": 2,
	"龙血": 1,
	"妖丹": 5,
	"妖王丹": 2,
	"筑基草": 3,
	"金丹草": 2,
	"元婴果": 1,
	"化神花": 0,
	"凤凰羽": 0,
	"悟道草": 5,
	"财运草": 5
}

func _ready():
	load_inventory()

# 炼丹
func craft_pill(pill_type: int, count: int = 1) -> Dictionary:
	var pill_data = pill_database.get(pill_type)
	if pill_data == null:
		return {"success": false, "message": "丹药不存在"}
	
	# 检查等级
	if alchemy_level < pill_data.required_level:
		return {"success": false, "message": "炼丹等级不足"}
	
	# 检查材料
	var mats_needed = pill_data.materials.duplicate()
	for mat in mats_needed.keys():
		mats_needed[mat] *= count
	
	if not has_materials(mats_needed):
		return {"success": false, "message": "材料不足"}
	
	# 消耗材料
	for mat in mats_needed.keys():
		materials[mat] -= mats_needed[mat]
	
	# 炼制判定
	var success_count = 0
	for i in range(count):
		if randf() <= pill_data.success_rate:
			success_count += 1
	
	if success_count > 0:
		# 添加到库存
		if not inventory.has(pill_type):
			inventory[pill_type] = 0
		inventory[pill_type] += success_count
		
		# 增加经验
		alchemy_exp += success_count * 10
		check_level_up()
		
		emit_signal("pill_crafted", pill_data.name, success_count)
		
		save_inventory()
		return {
			"success": true,
			"crafted": success_count,
			"failed": count - success_count,
			"message": "炼制成功 %d 颗，失败 %d 颗" % [success_count, count - success_count]
		}
	else:
		save_inventory()
		return {"success": false, "message": "炼制失败，材料已消耗"}

# 使用丹药
func use_pill(pill_type: int, target: Node) -> Dictionary:
	var count = inventory.get(pill_type, 0)
	if count <= 0:
		return {"success": false, "message": "丹药不足"}
	
	var pill_data = pill_database[pill_type]
	var effect = pill_data.effect
	
	# 应用效果
	apply_pill_effect(effect, target)
	
	# 消耗丹药
	inventory[pill_type] -= 1
	
	emit_signal("pill_used", pill_data.name, effect)
	
	return {
		"success": true,
		"effect": effect,
		"message": "使用 " + pill_data.name
	}

func apply_pill_effect(effect: Dictionary, target: Node):
	# 生命恢复
	if effect.has("hp"):
		if target.has_method("heal"):
			target.heal(effect.hp)
	
	if effect.has("hp_percent"):
		if "max_hp" in target and "current_hp" in target:
			target.current_hp = int(target.max_hp * effect.hp_percent / 100.0)
	
	# 法力恢复
	if effect.has("mp"):
		if "current_mp" in target and "max_mp" in target:
			target.current_mp = min(target.max_mp, target.current_mp + effect.mp)
	
	# 增益效果（简化版）
	if effect.has("attack_percent"):
		print("攻击提升 ", effect.attack_percent, "%")
	
	if effect.has("defense_percent"):
		print("防御提升 ", effect.defense_percent, "%")
	
	if effect.has("speed_percent"):
		print("速度提升 ", effect.speed_percent, "%")

# 检查材料
func has_materials(mats: Dictionary) -> bool:
	for mat in mats.keys():
		if materials.get(mat, 0) < mats[mat]:
			return false
	return true

# 获取丹药信息
func get_pill_info(pill_type: int) -> Dictionary:
	return pill_database.get(pill_type, {})

# 获取库存
func get_inventory() -> Dictionary:
	return inventory.duplicate()

# 获取材料库存
func get_materials() -> Dictionary:
	return materials.duplicate()

# 添加材料
func add_material(mat_name: String, count: int):
	if not materials.has(mat_name):
		materials[mat_name] = 0
	materials[mat_name] += count

# 检查升级
func check_level_up():
	var exp_needed = alchemy_level * 100
	if alchemy_exp >= exp_needed:
		alchemy_level += 1
		alchemy_exp -= exp_needed
		print("炼丹等级提升: ", alchemy_level)

# 保存/加载
func save_inventory():
	var config = ConfigFile.new()
	config.set_value("alchemy", "level", alchemy_level)
	config.set_value("alchemy", "exp", alchemy_exp)
	config.set_value("alchemy", "inventory", inventory)
	config.set_value("alchemy", "materials", materials)
	config.save("user://alchemy.cfg")

func load_inventory():
	if FileAccess.file_exists("user://alchemy.cfg"):
		var config = ConfigFile.new()
		if config.load("user://alchemy.cfg") == OK:
			alchemy_level = config.get_value("alchemy", "level", 1)
			alchemy_exp = config.get_value("alchemy", "exp", 0)
			inventory = config.get_value("alchemy", "inventory", {})
			materials = config.get_value("alchemy", "materials", materials)
