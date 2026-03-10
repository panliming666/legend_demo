class_name Equipment

enum EquipmentType {
	WEAPON,
	ARMOR,
	HELMET,
	BOOTS,
	ACCESSORY
}

enum EquipmentRarity {
	COMMON,      # 白色
	UNCOMMON,    # 绿色
	RARE,        # 蓝色
	EPIC,        # 紫色
	LEGENDARY    # 橙色
}

var name: String
var type: EquipmentType
var rarity: EquipmentRarity
var level: int

# 属性加成
var hp_bonus: int = 0
var mp_bonus: int = 0
var attack_bonus: int = 0
var defense_bonus: int = 0
var speed_bonus: float = 0.0

# 掉落权重（传奇风格）
var drop_weight: float = 100.0

func _init(_name: String, _type: EquipmentType, _rarity: EquipmentRarity, _level: int):
	name = _name
	type = _type
	rarity = _rarity
	level = _level
	
	# 根据稀有度生成属性
	generate_stats()

func generate_stats():
	var base_multiplier = 1.0 + (int(rarity) * 0.5) + (level * 0.1)
	
	match type:
		EquipmentType.WEAPON:
			attack_bonus = int(10 * base_multiplier)
		EquipmentType.ARMOR:
			defense_bonus = int(8 * base_multiplier)
			hp_bonus = int(20 * base_multiplier)
		EquipmentType.HELMET:
			defense_bonus = int(5 * base_multiplier)
			mp_bonus = int(10 * base_multiplier)
		EquipmentType.BOOTS:
			defense_bonus = int(3 * base_multiplier)
			speed_bonus = 10.0 * base_multiplier
		EquipmentType.ACCESSORY:
			hp_bonus = int(10 * base_multiplier)
			mp_bonus = int(5 * base_multiplier)
			attack_bonus = int(5 * base_multiplier)
	
	# 根据稀有度调整掉落权重
	match rarity:
		EquipmentRarity.COMMON:
			drop_weight = 100.0
		EquipmentRarity.UNCOMMON:
			drop_weight = 50.0
		EquipmentRarity.RARE:
			drop_weight = 20.0
		EquipmentRarity.EPIC:
			drop_weight = 5.0
		EquipmentRarity.LEGENDARY:
			drop_weight = 1.0

func get_rarity_color() -> Color:
	match rarity:
		EquipmentRarity.COMMON:
			return Color.WHITE
		EquipmentRarity.UNCOMMON:
			return Color.GREEN
		EquipmentRarity.RARE:
			return Color.BLUE
		EquipmentRarity.EPIC:
			return Color.PURPLE
		EquipmentRarity.LEGENDARY:
			return Color.ORANGE
	return Color.WHITE

func get_stats_text() -> String:
	var stats = []
	if hp_bonus > 0:
		stats.append("HP +" + str(hp_bonus))
	if mp_bonus > 0:
		stats.append("MP +" + str(mp_bonus))
	if attack_bonus > 0:
		stats.append("攻击 +" + str(attack_bonus))
	if defense_bonus > 0:
		stats.append("防御 +" + str(defense_bonus))
	if speed_bonus > 0:
		stats.append("速度 +" + str(speed_bonus))
	return "\n".join(stats)
