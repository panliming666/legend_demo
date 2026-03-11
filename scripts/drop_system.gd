class_name DropSystem

# 预加载 Equipment 类
const EquipmentClass = preload("res://scripts/equipment.gd")

# 传奇掉落概率配置
const BASE_DROP_RATE = 0.3  # 基础掉落率30%
const LEGENDARY_RATE = 0.001  # 传奇装备0.1%概率
const EPIC_RATE = 0.005  # 史诗装备0.5%概率
const RARE_RATE = 0.02  # 稀有装备2%概率
const UNCOMMON_RATE = 0.1  # 普通装备10%概率

# 金币掉落范围
const MIN_GOLD = 10
const MAX_GOLD = 100

# 经验掉落
const EXP_MULTIPLIER = 1.0

static func calculate_drop(enemy_level: int, player_kill_bonus: float = 0.0) -> Dictionary:
	var drops = {
		"gold": 0,
		"exp": 0,
		"equipment": null
	}
	
	# 计算经验
	drops["exp"] = int(enemy_level * 10 * EXP_MULTIPLIER)
	
	# 计算金币（带随机波动）
	drops["gold"] = randi_range(MIN_GOLD, MAX_GOLD) + (enemy_level * 5)
	
	# 计算装备掉落
	var drop_roll = randf()
	var adjusted_drop_rate = BASE_DROP_RATE + player_kill_bonus
	
	if drop_roll < adjusted_drop_rate:
		drops["equipment"] = generate_equipment(enemy_level)
	
	return drops

static func generate_equipment(level: int) -> Object:
	var rarity_roll = randf()
	var rarity: int
	
	# 稀有度判定
	if rarity_roll < LEGENDARY_RATE:
		rarity = EquipmentClass.EquipmentRarity.LEGENDARY
	elif rarity_roll < LEGENDARY_RATE + EPIC_RATE:
		rarity = EquipmentClass.EquipmentRarity.EPIC
	elif rarity_roll < LEGENDARY_RATE + EPIC_RATE + RARE_RATE:
		rarity = EquipmentClass.EquipmentRarity.RARE
	elif rarity_roll < LEGENDARY_RATE + EPIC_RATE + RARE_RATE + UNCOMMON_RATE:
		rarity = EquipmentClass.EquipmentRarity.UNCOMMON
	else:
		rarity = EquipmentClass.EquipmentRarity.COMMON
	
	# 随机装备类型
	var type_roll = randi() % 5
	var equipment_type = EquipmentClass.EquipmentType.values()[type_roll]
	
	# 生成装备名称
	var equipment_name = get_equipment_name(equipment_type, rarity)
	
	return EquipmentClass.new(equipment_name, equipment_type, rarity, level)

static func get_equipment_name(type: int, rarity: int) -> String:
	var prefix = ""
	var suffix = ""
	
	# 稀有度前缀
	match rarity:
		EquipmentClass.EquipmentRarity.LEGENDARY:
			prefix = "传说"
		EquipmentClass.EquipmentRarity.EPIC:
			prefix = "史诗"
		EquipmentClass.EquipmentRarity.RARE:
			prefix = "稀有"
		EquipmentClass.EquipmentRarity.UNCOMMON:
			prefix = "优秀"
		EquipmentClass.EquipmentRarity.COMMON:
			prefix = "普通"
	
	# 类型后缀
	match type:
		EquipmentClass.EquipmentType.WEAPON:
			suffix = "之剑"
		EquipmentClass.EquipmentType.ARMOR:
			suffix = "胸甲"
		EquipmentClass.EquipmentType.HELMET:
			suffix = "头盔"
		EquipmentClass.EquipmentType.BOOTS:
			suffix = "靴子"
		EquipmentClass.EquipmentType.ACCESSORY:
			suffix = "戒指"
	
	return prefix + suffix
