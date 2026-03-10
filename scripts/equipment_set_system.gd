extends Node

class_name EquipmentSetSystem

# 装备套装系统 - 单机收集要素

signal set_completed(set_id: String, set_name: String)
signal set_bonus_activated(set_id: String, bonus_level: int)

# 套装数据库
var set_database: Dictionary = {
	"set_beginner": {
		"id": "set_beginner",
		"name": "新手套装",
		"description": "初入仙门的制式装备",
		"pieces": ["beginner_weapon", "beginner_armor", "beginner_helmet"],
		"bonuses": {
			2: {"hp": 50, "attack": 5},
			3: {"hp": 100, "attack": 10, "defense": 5}
		},
		"rarity": "common"
	},
	"set_iron": {
		"id": "set_iron",
		"name": "铁壁套装",
		"description": "坚如磐石的防御装备",
		"pieces": ["iron_helmet", "iron_armor", "iron_boots", "iron_gloves"],
		"bonuses": {
			2: {"defense": 20},
			3: {"defense": 40, "hp": 100},
			4: {"defense": 60, "hp": 200, "damage_reduction": 0.1}
		},
		"rarity": "rare"
	},
	"set_flame": {
		"id": "set_flame",
		"name": "烈焰套装",
		"description": "燃烧着永恒之火的装备",
		"pieces": ["flame_weapon", "flame_ring", "flame_amulet", "flame_belt"],
		"bonuses": {
			2: {"fire_damage": 0.15},
			3: {"fire_damage": 0.3, "attack": 20},
			4: {"fire_damage": 0.5, "attack": 40, "burn_effect": true}
		},
		"rarity": "epic"
	},
	"set_frost": {
		"id": "set_frost",
		"name": "霜寒套装",
		"description": "来自极北之地的寒冰装备",
		"pieces": ["frost_weapon", "frost_ring", "frost_amulet", "frost_boots"],
		"bonuses": {
			2: {"ice_damage": 0.15},
			3: {"ice_damage": 0.3, "slow_effect": 0.2},
			4: {"ice_damage": 0.5, "freeze_chance": 0.1}
		},
		"rarity": "epic"
	},
	"set_thunder": {
		"id": "set_thunder",
		"name": "雷霆套装",
		"description": "蕴含天雷之力的神兵",
		"pieces": ["thunder_weapon", "thunder_ring", "thunder_amulet", "thunder_belt"],
		"bonuses": {
			2: {"thunder_damage": 0.15},
			3: {"thunder_damage": 0.3, "crit_rate": 5},
			4: {"thunder_damage": 0.5, "chain_lightning": true}
		},
		"rarity": "epic"
	},
	"set_immortal": {
		"id": "set_immortal",
		"name": "不朽套装",
		"description": "上古仙人留下的传承",
		"pieces": ["immortal_weapon", "immortal_armor", "immortal_helmet", 
				   "immortal_ring", "immortal_amulet"],
		"bonuses": {
			2: {"all_stats": 10},
			3: {"all_stats": 20, "hp_regen": 10},
			4: {"all_stats": 40, "hp_regen": 20, "revive_chance": 0.1},
			5: {"all_stats": 60, "hp_regen": 30, "revive_chance": 0.2, "invincible_time": 3}
		},
		"rarity": "legendary"
	},
	"set_dragon": {
		"id": "set_dragon",
		"name": "真龙套装",
		"description": "以龙鳞龙骨打造的神装",
		"pieces": ["dragon_weapon", "dragon_armor", "dragon_helmet", 
				   "dragon_ring", "dragon_amulet", "dragon_boots"],
		"bonuses": {
			2: {"attack": 50},
			3: {"attack": 100, "crit_damage": 0.2},
			4: {"attack": 150, "crit_damage": 0.4, "dragon_roar": true},
			5: {"attack": 200, "crit_damage": 0.6, "dragon_form": true},
			6: {"attack": 300, "crit_damage": 1.0, "dragon_soul": true}
		},
		"rarity": "legendary"
	},
	"set_phoenix": {
		"id": "set_phoenix",
		"name": "凤凰套装",
		"description": "浴火重生的不死神装",
		"pieces": ["phoenix_weapon", "phoenix_armor", "phoenix_helmet",
				   "phoenix_ring", "phoenix_amulet", "phoenix_wings"],
		"bonuses": {
			2: {"hp": 200},
			3: {"hp": 400, "fire_resist": 0.3},
			4: {"hp": 600, "fire_resist": 0.5, "rebirth": 1},
			5: {"hp": 800, "fire_resist": 0.7, "rebirth": 2, "phoenix_fire": true},
			6: {"hp": 1200, "fire_immune": true, "rebirth": 3, "true_phoenix": true}
		},
		"rarity": "legendary"
	}
}

# 玩家收集进度
var collected_pieces: Dictionary = {}  # piece_id: set_id
var completed_sets: Array = []

func _ready():
	load_set_data()

# 收集装备部件
func collect_piece(piece_id: String) -> Dictionary:
	# 检查是否属于某个套装
	var set_info = find_set_for_piece(piece_id)
	if set_info == null:
		return {"success": false, "message": "该装备不属于任何套装"}
	
	if piece_id in collected_pieces:
		return {"success": false, "message": "已收集该部件"}
	
	collected_pieces[piece_id] = set_info.id
	
	# 检查套装是否完成
	check_set_completion(set_info.id)
	
	save_set_data()
	
	return {
		"success": true,
		"piece": piece_id,
		"set": set_info.name,
		"progress": get_set_progress(set_info.id)
	}

# 查找装备所属套装
func find_set_for_piece(piece_id: String) -> Dictionary:
	for set_id in set_database.keys():
		var set_data = set_database[set_id]
		if piece_id in set_data.pieces:
			return set_data
	return null

# 检查套装完成度
func check_set_completion(set_id: String):
	var set_data = set_database[set_id]
	var collected = 0
	
	for piece in set_data.pieces:
		if piece in collected_pieces:
			collected += 1
	
	# 检查是否刚完成
	if collected == set_data.pieces.size():
		if not set_id in completed_sets:
			completed_sets.append(set_id)
			emit_signal("set_completed", set_id, set_data.name)
			print("套装完成：", set_data.name)

# 获取套装进度
func get_set_progress(set_id: String) -> Dictionary:
	var set_data = set_database.get(set_id)
	if set_data == null:
		return {}
	
	var collected = 0
	var pieces_status = []
	
	for piece in set_data.pieces:
		var has_piece = piece in collected_pieces
		if has_piece:
			collected += 1
		pieces_status.append({
			"id": piece,
			"collected": has_piece
		})
	
	var completed = collected == set_data.pieces.size()
	var active_bonus = get_active_bonus_level(set_id, collected)
	
	return {
		"id": set_id,
		"name": set_data.name,
		"collected": collected,
		"total": set_data.pieces.size(),
		"percent": float(collected) / set_data.pieces.size() * 100,
		"completed": completed,
		"pieces": pieces_status,
		"active_bonus": active_bonus,
		"bonuses": set_data.bonuses
	}

# 获取当前激活的套装效果等级
func get_active_bonus_level(set_id: String, collected_count: int = -1) -> int:
	if collected_count < 0:
		var progress = get_set_progress(set_id)
		collected_count = progress.collected
	
	var set_data = set_database[set_id]
	var highest_bonus = 0
	
	for bonus_level in set_data.bonuses.keys():
		if collected_count >= bonus_level:
			highest_bonus = max(highest_bonus, bonus_level)
	
	return highest_bonus

# 获取所有套装效果
func get_all_set_bonuses() -> Dictionary:
	var total_bonus: Dictionary = {}
	
	for set_id in set_database.keys():
		var bonus_level = get_active_bonus_level(set_id)
		if bonus_level > 0:
			var set_data = set_database[set_id]
			var bonus = set_data.bonuses[bonus_level]
			
			for key in bonus.keys():
				if not total_bonus.has(key):
					total_bonus[key] = 0
				total_bonus[key] += bonus[key]
			
			emit_signal("set_bonus_activated", set_id, bonus_level)
	
	return total_bonus

# 获取所有套装信息
func get_all_sets() -> Array:
	var result = []
	
	for set_id in set_database.keys():
		result.append(get_set_progress(set_id))
	
	# 按稀有度排序
	var rarity_order = {"common": 0, "rare": 1, "epic": 2, "legendary": 3}
	result.sort_custom(func(a, b):
		var rarity_a = rarity_order.get(set_database[a.id].rarity, 0)
		var rarity_b = rarity_order.get(set_database[b.id].rarity, 0)
		return rarity_a < rarity_b
	)
	
	return result

# 获取收集统计
func get_collection_stats() -> Dictionary:
	var total_pieces = 0
	var collected_count = collected_pieces.size()
	
	for set_id in set_database.keys():
		total_pieces += set_database[set_id].pieces.size()
	
	return {
		"collected_pieces": collected_count,
		"total_pieces": total_pieces,
		"completion_percent": float(collected_count) / total_pieces * 100,
		"completed_sets": completed_sets.size(),
		"total_sets": set_database.size()
	}

# 保存/加载
func save_set_data():
	var config = ConfigFile.new()
	config.set_value("sets", "collected", collected_pieces)
	config.set_value("sets", "completed", completed_sets)
	config.save("user://equipment_sets.cfg")

func load_set_data():
	if FileAccess.file_exists("user://equipment_sets.cfg"):
		var config = ConfigFile.new()
		if config.load("user://equipment_sets.cfg") == OK:
			collected_pieces = config.get_value("sets", "collected", {})
			completed_sets = config.get_value("sets", "completed", [])
