class_name DropSystem

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

static func generate_equipment(level: int) -> Equipment:
	var rarity_roll = randf()
	var rarity: Equipment.EquipmentRarity
	
	# 稀有度判定
	if rarity_roll < LEGENDARY_RATE:
		rarity = Equipment.EquipmentRarity.LEGENDARY
	elif rarity_roll < LEGENDARY_RATE + EPIC_RATE:
		rarity = Equipment.EquipmentRarity.EPIC
	elif rarity_roll < LEGENDARY_RATE + EPIC_RATE + RARE_RATE:
		rarity = Equipment.EquipmentRarity.RARE
	elif rarity_roll < LEGENDARY_RATE + EPIC_RATE + RARE_RATE + UNCOMMON_RATE:
		rarity = Equipment.EquipmentRarity.UNCOMMON
	else:
		rarity = Equipment.EquipmentRarity.COMMON
	
	# 随机装备类型
	var type_roll = randi() % 5
	var equipment_type = Equipment.EquipmentType.values()[type_roll]
	
	# 生成装备名称
	var equipment_name = get_equipment_name(equipment_type, rarity)
	
	return Equipment.new(equipment_name, equipment_type, rarity, level)

static func get_equipment_name(type: Equipment.EquipmentType, rarity: Equipment.EquipmentRarity) -> String:
	var prefix = ""
	var suffix = ""
	
	# 稀有度前缀
	match rarity:
		Equipment.EquipmentRarity.LEGENDARY:
			prefix = "传说"
		Equipment.EquipmentRarity.EPIC:
			prefix = "史诗"
		Equipment.EquipmentRarity.RARE:
			prefix = "稀有"
		Equipment.EquipmentRarity.UNCOMMON:
			prefix = "优秀"
		Equipment.EquipmentRarity.COMMON:
			prefix = "普通"
	
	# 类型后缀
	match type:
		Equipment.EquipmentType.WEAPON:
			suffix = "之剑"
		Equipment.EquipmentType.ARMOR:
			suffix = "胸甲"
		Equipment.EquipmentType.HELMET:
			suffix = "头盔"
		Equipment.EquipmentType.BOOTS:
			suffix = "靴子"
		Equipment.EquipmentType.ACCESSORY:
			suffix = "戒指"
	
	return prefix + suffix
