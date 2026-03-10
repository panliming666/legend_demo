extends Node

class_name CraftingSystem

# 锻造/强化系统 - 装备升级与制作

signal item_crafted(item_name: String)
signal item_enhanced(item_name: String, new_level: int)
signal enhancement_failed(item_name: String)

# 锻造配方
var recipes: Array = [
	{
		"id": "iron_sword",
		"name": "铁剑",
		"type": "weapon",
		"materials": {"iron_ore": 5, "wood": 2},
		"result": {"name": "Iron Sword", "attack": 15, "defense": 0},
		"success_rate": 0.9,
		"required_level": 1
	},
	{
		"id": "steel_sword",
		"name": "钢剑",
		"type": "weapon",
		"materials": {"steel_ore": 8, "leather": 3},
		"result": {"name": "Steel Sword", "attack": 25, "defense": 0},
		"success_rate": 0.8,
		"required_level": 5
	},
	{
		"id": "dragon_blade",
		"name": "龙牙剑",
		"type": "weapon",
		"materials": {"dragon_tooth": 10, "mithril_ore": 5, "soul_crystal": 1},
		"result": {"name": "Dragon Blade", "attack": 50, "defense": 5},
		"success_rate": 0.5,
		"required_level": 15
	},
	{
		"id": "iron_armor",
		"name": "铁甲",
		"type": "armor",
		"materials": {"iron_ore": 10, "leather": 5},
		"result": {"name": "Iron Armor", "attack": 0, "defense": 20},
		"success_rate": 0.85,
		"required_level": 1
	},
	{
		"id": "health_potion",
		"name": "生命药水",
		"type": "consumable",
		"materials": {"herb": 3, "water": 1},
		"result": {"name": "Health Potion", "heal": 50},
		"success_rate": 1.0,
		"required_level": 1
	}
]

# 强化配置
var enhancement_config: Dictionary = {
	"max_level": 10,
	"base_success_rate": 1.0,
	"rate_decay": 0.1,  # 每级成功率降低10%
	"cost_multiplier": 1.5,  # 每级费用增加50%
	"base_gold_cost": 100,
	"stat_increase": {
		"attack": 2,
		"defense": 2,
		"hp": 10,
		"mp": 5
	}
}

# 玩家库存（简化版）
var player_inventory: Dictionary = {}

# 锻造经验
var crafting_exp: int = 0
var crafting_level: int = 1

func _ready():
	# 初始化库存（测试用）
	_init_test_inventory()

func _init_test_inventory():
	player_inventory = {
		"iron_ore": 50,
		"steel_ore": 30,
		"wood": 20,
		"leather": 15,
		"herb": 100,
		"water": 50,
		"dragon_tooth": 5,
		"mithril_ore": 10,
		"soul_crystal": 2
	}

func get_available_recipes(player_level: int) -> Array:
	var available = []
	
	for recipe in recipes:
		if recipe.required_level <= player_level:
			if has_materials(recipe.materials):
				recipe["can_craft"] = true
			else:
				recipe["can_craft"] = false
			available.append(recipe)
	
	return available

func has_materials(materials: Dictionary) -> bool:
	for material in materials.keys():
		var required = materials[material]
		var owned = player_inventory.get(material, 0)
		if owned < required:
			return false
	return true

func craft_item(recipe_id: String) -> Dictionary:
	var recipe = null
	
	for r in recipes:
		if r.id == recipe_id:
			recipe = r
			break
	
	if recipe == null:
		return {"success": false, "message": "配方不存在"}
	
	# 检查材料
	if not has_materials(recipe.materials):
		return {"success": false, "message": "材料不足"}
	
	# 检查等级
	if crafting_level < recipe.required_level:
		return {"success": false, "message": "锻造等级不足"}
	
	# 消耗材料
	for material in recipe.materials.keys():
		player_inventory[material] -= recipe.materials[material]
	
	# 成功率判定
	var success_roll = randf()
	var success = success_roll <= recipe.success_rate
	
	if success:
		# 获得物品
		var item = recipe.result.duplicate()
		item["enhancement_level"] = 0
		
		# 增加经验
		crafting_exp += 10
		_check_crafting_level_up()
		
		emit_signal("item_crafted", item.name)
		print("锻造成功: ", item.name)
		
		return {"success": true, "item": item, "message": "锻造成功！"}
	else:
		# 失败但返还部分材料
		print("锻造失败")
		return {"success": false, "message": "锻造失败，材料已消耗"}

func enhance_equipment(equipment: Dictionary, player_gold: int) -> Dictionary:
	var current_level = equipment.get("enhancement_level", 0)
	
	if current_level >= enhancement_config.max_level:
		return {"success": false, "message": "已达最高强化等级"}
	
	# 计算费用
	var gold_cost = _calculate_enhancement_cost(current_level)
	
	if player_gold < gold_cost:
		return {"success": false, "message": "金币不足"}
	
	# 计算成功率
	var success_rate = _calculate_success_rate(current_level)
	var success_roll = randf()
	var success = success_roll <= success_rate
	
	if success:
		# 强化成功
		equipment["enhancement_level"] = current_level + 1
		
		# 增加属性
		var stat_increase = enhancement_config.stat_increase
		if equipment.has("attack"):
			equipment["attack"] += stat_increase.attack
		if equipment.has("defense"):
			equipment["defense"] += stat_increase.defense
		if equipment.has("hp"):
			equipment["hp"] += stat_increase.hp
		if equipment.has("mp"):
			equipment["mp"] += stat_increase.mp
		
		emit_signal("item_enhanced", equipment.name, equipment.enhancement_level)
		print("强化成功: ", equipment.name, " -> +", equipment.enhancement_level)
		
		return {
			"success": true,
			"equipment": equipment,
			"gold_cost": gold_cost,
			"message": "强化成功！"
		}
	else:
		# 强化失败
		# 某些游戏中失败会降级，这里简化为只消耗金币
		emit_signal("enhancement_failed", equipment.name)
		print("强化失败: ", equipment.name)
		
		return {
			"success": false,
			"gold_cost": gold_cost,
			"message": "强化失败，金币已消耗"
		}

func _calculate_enhancement_cost(current_level: int) -> int:
	var base_cost = enhancement_config.base_gold_cost
	var multiplier = enhancement_config.cost_multiplier
	
	return int(base_cost * pow(multiplier, current_level))

func _calculate_success_rate(current_level: int) -> float:
	var base_rate = enhancement_config.base_success_rate
	var decay = enhancement_config.rate_decay
	
	return max(0.1, base_rate - (current_level * decay))

func _check_crafting_level_up():
	var required_exp = crafting_level * 100
	
	if crafting_exp >= required_exp:
		crafting_level += 1
		crafting_exp -= required_exp
		print("锻造等级提升: ", crafting_level)

func add_material(material_name: String, amount: int):
	if not player_inventory.has(material_name):
		player_inventory[material_name] = 0
	player_inventory[material_name] += amount
	print("获得材料: ", material_name, " x", amount)

func remove_material(material_name: String, amount: int) -> bool:
	var owned = player_inventory.get(material_name, 0)
	if owned < amount:
		return false
	
	player_inventory[material_name] = owned - amount
	return true

func get_material_count(material_name: String) -> int:
	return player_inventory.get(material_name, 0)

func get_all_materials() -> Dictionary:
	return player_inventory.duplicate(true)

func get_crafting_info() -> Dictionary:
	return {
		"level": crafting_level,
		"exp": crafting_exp,
		"next_level_exp": crafting_level * 100
	}

# 特殊锻造：套装
func craft_set_item(set_name: String, piece: String) -> Dictionary:
	var set_recipes = {
		"dragon_set": {
			"weapon": {"materials": {"dragon_tooth": 15, "soul_crystal": 3}},
			"armor": {"materials": {"dragon_scale": 20, "soul_crystal": 2}},
			"helmet": {"materials": {"dragon_scale": 10, "soul_crystal": 1}}
		}
	}
	
	if not set_recipes.has(set_name):
		return {"success": false, "message": "套装不存在"}
	
	var set_data = set_recipes[set_name]
	if not set_data.has(piece):
		return {"success": false, "message": "部位不存在"}
	
	var materials = set_data[piece].materials
	
	if not has_materials(materials):
		return {"success": false, "message": "材料不足"}
	
	# 消耗材料
	for material in materials.keys():
		player_inventory[material] -= materials[material]
	
	var item_name = set_name + "_" + piece
	emit_signal("item_crafted", item_name)
	
	return {
		"success": true,
		"item": {
			"name": item_name,
			"set": set_name,
			"piece": piece,
			"enhancement_level": 0
		}
	}
