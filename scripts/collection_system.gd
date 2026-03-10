extends Node

class_name CollectionSystem

# 图鉴收集系统 - 单机收集要素

signal item_collected(category: String, item_id: String)
signal category_completed(category: String)

# 图鉴类别
enum CollectionCategory {
	MONSTERS,   # 怪物图鉴
	ITEMS,      # 物品图鉴
	EQUIPMENT,  # 装备图鉴
	PETS,       # 灵宠图鉴
	MOUNTS,     # 坐骑图鉴
	WINGS,      # 翅膀图鉴
	BOSSES,     # Boss图鉴
	SCENES      # 场景图鉴
}

# 图鉴数据库
var collection_database: Dictionary = {
	CollectionCategory.MONSTERS: {
		"name": "怪物图鉴",
		"items": {
			"spirit_beast": {"name": "灵兽", "description": "最常见的修仙界生物", "location": "灵气洞穴"},
			"wild_boar": {"name": "野猪", "description": "山林中的野兽", "location": "新手森林"},
			"snake": {"name": "毒蛇", "description": "带有剧毒的蛇类", "location": "迷雾谷"},
			"wolf": {"name": "野狼", "description": "成群行动的肉食动物", "location": "野外"},
			"skeleton": {"name": "骷髅", "description": "亡者墓地的不死生物", "location": "亡者墓地"},
			"ghost": {"name": "幽灵", "description": "游荡的魂魄", "location": "鬼魂洞"},
			"demon": {"name": "恶魔", "description": "来自魔域的生物", "location": "魔域"},
			"ogre": {"name": "食人魔", "description": "智力低下的巨人族", "location": "深渊"}
		}
	},
	CollectionCategory.BOSSES: {
		"name": "Boss图鉴",
		"items": {
			"bone_lord": {"name": "骨魔", "description": "白骨坑的统领", "location": "白骨坑", "reward": "成就解锁"},
			"demon_lord": {"name": "恶魔领主", "description": "恶魔巢穴的王", "location": "恶魔巢穴", "reward": "称号解锁"},
			"ancient_dragon": {"name": "远古青龙", "description": "龙巢的最强者", "location": "龙巢", "reward": "套装部件"},
			"immortal_guardian": {"name": "仙灵守护者", "description": "仙人陵墓的守护者", "location": "仙人陵墓", "reward": "传承装备"},
			"tianmo_lord": {"name": "天魔领主", "description": "三清终章Boss", "location": "天魔战场", "reward": "通关奖励"}
		}
	},
	CollectionCategory.PETS: {
		"name": "灵宠图鉴",
		"items": {
			"bone_spirit": {"name": "骨灵", "description": "最低阶的灵宠", "unlock": "击败骨魔"},
			"spirit_wolf": {"name": "灵狼", "description": "忠诚的伙伴", "unlock": "灵宠系统解锁"},
			"spirit_bear": {"name": "灵熊", "description": "力量型灵宠", "unlock": "灵狼进化"},
			"spirit_tiger": {"name": "灵虎", "description": "威猛的战斗伙伴", "unlock": "灵熊进化"},
			"crane": {"name": "仙鹤", "description": "飞行灵宠", "unlock": "境界达到金丹"},
			"cloud_dragon": {"name": "云龙", "description": "呼云唤雨", "unlock": "仙鹤进化"},
			"phoenix": {"name": "凤凰", "description": "浴火重生", "unlock": "云龙进化"},
			"heavenly_general": {"name": "天将", "description": "天界神将", "unlock": "达到化神期"}
		}
	},
	CollectionCategory.MOUNTS: {
		"name": "坐骑图鉴",
		"items": {
			"horse": {"name": "骏马", "description": "基础坐骑", "unlock": "坐骑系统解锁"},
			"deer": {"name": "灵鹿", "description": "速度提升", "unlock": "骏马进化"},
			"wolf": {"name": "灵狼", "description": "战斗坐骑", "unlock": "灵鹿进化"},
			"tiger": {"name": "猛虎", "description": "威风凛凛", "unlock": "灵狼进化"},
			"crane": {"name": "仙鹤", "description": "飞行坐骑", "unlock": "境界达到金丹"},
			"lion": {"name": "雄狮", "description": "草原霸主", "unlock": "仙鹤进化"},
			"dragon": {"name": "飞龙", "description": "神龙摆尾", "unlock": "狮子进化"},
			"phoenix": {"name": "凤凰", "description": "终极坐骑", "unlock": "飞龙进化"}
		}
	},
	CollectionCategory.WINGS: {
		"name": "翅膀图鉴",
		"items": {
			"white_wing": {"name": "白羽之翼", "description": "最基础的翅膀", "unlock": "境界达到20级"},
			"blue_wing": {"name": "青云之翼", "description": "进阶翅膀", "unlock": "白羽之翼进化"},
			"crystal_wing": {"name": "蓝晶之翼", "description": "晶莹剔透", "unlock": "青云之翼进化"},
			"purple_wing": {"name": "紫电之翼", "description": "雷电缠绕", "unlock": "蓝晶之翼进化"},
			"gold_wing": {"name": "金霞之翼", "description": "金光闪闪", "unlock": "紫电之翼进化"},
			"orange_wing": {"name": "橙焰之翼", "description": "火焰翅膀", "unlock": "金霞之翼进化"},
			"red_wing": {"name": "赤霄之翼", "description": "终极翅膀", "unlock": "橙焰之翼进化"}
		}
	},
	CollectionCategory.ITEMS: {
		"name": "物品图鉴",
		"items": {
			"herb": {"name": "灵草", "description": "基础药材"},
			"lingzhi": {"name": "灵芝", "description": "珍稀药材"},
			"xiancao": {"name": "仙草", "description": "仙家药材"},
			"shencao": {"name": "神草", "description": "神级药材"},
			"ore": {"name": "灵石", "description": "基础矿石"},
			"jade": {"name": "灵玉", "description": "珍稀矿石"},
			"dan": {"name": "妖丹", "description": "妖怪内丹"},
			"yuan_ball": {"name": "元婴果", "description": "突破境界所需"}
		}
	}
}

# 已收集的图鉴
var collected_items: Dictionary = {}  # category: [item_ids]

func _ready():
	load_collection_data()

# 收集物品
func collect_item(category: int, item_id: String) -> bool:
	if not collection_database.has(category):
		return false
	
	var category_data = collection_database[category]
	if not category_data.items.has(item_id):
		return false
	
	# 初始化类别
	if not collected_items.has(category):
		collected_items[category] = []
	
	# 检查是否已收集
	if item_id in collected_items[category]:
		return false
	
	# 添加到收集
	collected_items[category].append(item_id)
	
	emit_signal("item_collected", category_data.name, item_id)
	
	# 检查类别是否完成
	check_category_completion(category)
	
	save_collection_data()
	print("图鉴收集：", category_data.name, " - ", item_id)
	return true

# 检查类别完成
func check_category_completion(category: int):
	if not collection_database.has(category):
		return
	
	var category_data = collection_database[category]
	var total_items = category_data.items.size()
	var collected = collected_items.get(category, []).size()
	
	if collected >= total_items:
		emit_signal("category_completed", category_data.name)
		print("图鉴类别完成：", category_data.name)

# 获取收集进度
func get_category_progress(category: int) -> Dictionary:
	if not collection_database.has(category):
		return {}
	
	var category_data = collection_database[category]
	var total = category_data.items.size()
	var collected = collected_items.get(category, []).size()
	
	var items_status = []
	for item_id in category_data.items.keys():
		items_status.append({
			"id": item_id,
			"name": category_data.items[item_id].name,
			"collected": item_id in collected_items.get(category, [])
		})
	
	return {
		"category": category,
		"name": category_data.name,
		"collected": collected,
		"total": total,
		"percent": float(collected) / total * 100 if total > 0 else 0,
		"completed": collected >= total,
		"items": items_status
	}

# 获取所有图鉴进度
func get_all_progress() -> Array:
	var result = []
	
	for category in collection_database.keys():
		result.append(get_category_progress(category))
	
	return result

# 获取收集统计
func get_total_stats() -> Dictionary:
	var total_collected = 0
	var total_items = 0
	var categories_completed = 0
	
	for category in collection_database.keys():
		var category_data = collection_database[category]
		total_items += category_data.items.size()
		total_collected += collected_items.get(category, []).size()
		if collected_items.get(category, []).size() >= category_data.items.size():
			categories_completed += 1
	
	return {
		"total_collected": total_collected,
		"total_items": total_items,
		"completion_percent": float(total_collected) / total_items * 100 if total_items > 0 else 0,
		"categories_completed": categories_completed,
		"total_categories": collection_database.size()
	}

# 保存/加载
func save_collection_data():
	var config = ConfigFile.new()
	config.set_value("collection", "items", collected_items)
	config.save("user://collection.cfg")

func load_collection_data():
	if FileAccess.file_exists("user://collection.cfg"):
		var config = ConfigFile.new()
		if config.load("user://collection.cfg") == OK:
			collected_items = config.get_value("collection", "items", {})
