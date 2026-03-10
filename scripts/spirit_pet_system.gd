extends Node

class_name SpiritPetSystem

# 灵宠/召唤系统

signal pet_summoned(pet_name: String)
signal pet_died(pet_name: String)
signal pet_level_up(pet_name: String, new_level: int)

# 灵宠类型
enum PetType {
	BONE,      # 骨灵（最低级）
	WOLF,      # 灵狼
	BEAR,      # 灵熊
	TIGER,     # 灵虎
	CRANE,     # 仙鹤
	DRAGON,    # 云龙
	PHENIX,    # 凤凰
	HEAVENLY   # 天将（最高级）
}

# 灵宠数据
var pet_database: Dictionary = {
	PetType.BONE: {
		"name": "骨灵",
		"type": " undead",
		"level": 1,
		"hp": 50,
		"attack": 10,
		"defense": 5,
		"speed": 80,
		"skills": ["普通攻击"],
		"evolve_to": PetType.WOLF,
		"evolve_level": 5,
		"description": "由骸骨而成的低阶灵宠",
		"rarity": 1
	},
	PetType.WOLF: {
		"name": "灵狼",
		"type": "beast",
		"level": 1,
		"hp": 80,
		"attack": 18,
		"defense": 8,
		"speed": 120,
		"skills": ["撕咬", "嚎叫"],
		"evolve_to": PetType.BEAR,
		"evolve_level": 10,
		"description": "具有灵性的狼族",
		"rarity": 2
	},
	PetType.BEAR: {
		"name": "灵熊",
		"type": "beast",
		"level": 1,
		"hp": 150,
		"attack": 25,
		"defense": 20,
		"speed": 60,
		"skills": ["撕裂", "护甲"],
		"evolve_to": PetType.TIGER,
		"evolve_level": 20,
		"description": "力大无穷的灵熊",
		"rarity": 2
	},
	PetType.TIGER: {
		"name": "灵虎",
		"type": "beast",
		"level": 1,
		"hp": 200,
		"attack": 35,
		"defense": 15,
		"speed": 150,
		"skills": ["猛扑", "爪击", "威慑"],
		"evolve_to": PetType.CRANE,
		"evolve_level": 30,
		"description": "万兽之王，凶猛异常",
		"rarity": 3
	},
	PetType.CRANE: {
		"name": "仙鹤",
		"type": "beast",
		"level": 1,
		"hp": 120,
		"attack": 40,
		"defense": 20,
		"speed": 200,
		"skills": ["羽刃", "仙风", "治疗"],
		"evolve_to": PetType.DRAGON,
		"evolve_level": 40,
		"description": "仙风道骨的灵禽",
		"rarity": 3
	},
	PetType.DRAGON: {
		"name": "云龙",
		"type": "dragon",
		"level": 1,
		"hp": 300,
		"attack": 60,
		"defense": 30,
		"speed": 180,
		"skills": ["龙息", "云雾", "雷击"],
		"evolve_to": PetType.PHENIX,
		"evolve_level": 50,
		"description": "神龙见首不见尾",
		"rarity": 4
	},
	PetType.PHENIX: {
		"name": "凤凰",
		"type": "divine",
		"level": 1,
		"hp": 350,
		"attack": 80,
		"defense": 40,
		"speed": 220,
		"skills": ["凤凰火", "重生", "烈焰"],
		"evolve_to": PetType.HEAVENLY,
		"evolve_level": 60,
		"description": "浴火重生的神鸟",
		"rarity": 5
	},
	PetType.HEAVENLY: {
		"name": "天将",
		"type": "divine",
		"level": 1,
		"hp": 500,
		"attack": 100,
		"defense": 50,
		"speed": 200,
		"skills": ["天雷", "金光", "召唤", "无敌"],
		"evolve_to": -1,
		"evolve_level": 0,
		"description": "天界神将降临",
		"rarity": 6
	}
}

# 玩家已捕捉的灵宠
var owned_pets: Dictionary = {}  # pet_type: pet_data

# 当前召唤的灵宠
var active_pet: Node = null

func _ready():
	load_pets()

# 捕捉灵宠
func capture_pet(pet_type: int, success_rate: float = 0.5) -> bool:
	var pet_data = pet_database.get(pet_type)
	if pet_data == null:
		return false
	
	# 检查是否已拥有
	if owned_pets.has(pet_type):
		print("已拥有此灵宠")
		return false
	
	# 捕捉判定
	if randf() < success_rate:
		var new_pet = pet_data.duplicate()
		new_pet["level"] = 1
		new_pet["exp"] = 0
		new_pet["loyalty"] = 50  # 忠诚度
		owned_pets[pet_type] = new_pet
		save_pets()
		print("捕捉成功: ", new_pet.name)
		return true
	else:
		print("捕捉失败")
		return false

# 召唤灵宠
func summon_pet(pet_type: int, owner_scene: Node) -> bool:
	if not owned_pets.has(pet_type):
		print("未拥有此灵宠")
		return false
	
	# 卸下当前灵宠
	if active_pet != null:
		desummon_pet()
	
	var pet_data = owned_pets[pet_type]
	active_pet = create_pet_node(pet_type, pet_data, owner_scene)
	
	emit_signal("pet_summoned", pet_data.name)
	print("召唤灵宠: ", pet_data.name)
	return true

# 取消召唤
func desummon_pet():
	if active_pet != null:
		var pet_name = active_pet.name
		active_pet.queue_free()
		active_pet = null
		print("取消召唤: ", pet_name)

# 创建灵宠节点
func create_pet_node(pet_type: int, pet_data: Dictionary, owner_scene: Node) -> Node:
	var pet = CharacterBody2D.new()
	pet.name = pet_data.name
	pet.add_to_group("pets")
	pet.add_to_group("allies")
	
	# 设置属性
	pet.set_meta("pet_type", pet_type)
	pet.set_meta("pet_data", pet_data)
	
	# 碰撞体
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	pet.add_child(collision)
	
	# 视觉表现
	var visual = ColorRect.new()
	visual.size = Vector2(32, 32)
	visual.color = _get_pet_color(pet_type)
	visual.position = Vector2(-16, -16)
	pet.add_child(visual)
	
	# AI脚本
	var script = GDScript.new()
	script.source_code = _get_pet_ai_script(pet_data)
	script.reload()
	pet.set_script(script)
	
	owner_scene.add_child(pet)
	return pet

func _get_pet_color(pet_type: int) -> Color:
	match pet_type:
		PetType.BONE: return Color(0.8, 0.8, 0.7, 1)
		PetType.WOLF: return Color(0.5, 0.5, 0.6, 1)
		PetType.BEAR: return Color(0.6, 0.4, 0.3, 1)
		PetType.TIGER: return Color(0.9, 0.5, 0.2, 1)
		PetType.CRANE: return Color(0.9, 0.9, 0.9, 1)
		PetType.DRAGON: return Color(0.3, 0.5, 0.9, 1)
		PetType.PHENIX: return Color(1, 0.4, 0.1, 1)
		PetType.HEAVENLY: return Color(1, 0.9, 0.3, 1)
	return Color.WHITE

func _get_pet_ai_script(pet_data: Dictionary) -> String:
	var name = pet_data.name
	var attack = pet_data.attack
	var speed = pet_data.speed
	
	return """
extends CharacterBody2D
var pet_name = "%s"
var attack = %d
var speed = %d
var target = null

func _physics_process(delta):
	if target == null or not is_instance_valid(target):
		target = _find_nearest_enemy()
	
	if target:
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * speed
		
		# 保持距离
		var distance = global_position.distance_to(target.global_position)
		if distance < 50:
			# 攻击
			if target.has_method("take_damage"):
				target.take_damage(attack)
				# 击退
				global_position -= dir * 10
		
		move_and_slide()

func _find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var min_dist = 500.0
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy
	return nearest
""" % [name, attack, speed]

# 灵宠升级
func pet_level_up(pet_type: int) -> bool:
	if not owned_pets.has(pet_type):
		return false
	
	var pet = owned_pets[pet_type]
	var exp_needed = pet.level * 100
	
	if pet.exp >= exp_needed:
		pet.level += 1
		pet.exp -= exp_needed
		
		# 属性提升
		pet.hp = int(pet.hp * 1.1)
		pet.attack = int(pet.attack * 1.1)
		pet.defense = int(pet.defense * 1.1)
		
		# 检查进化
		check_evolve(pet_type)
		
		emit_signal("pet_level_up", pet.name, pet.level)
		print("灵宠升级: ", pet.name, " -> Lv.", pet.level)
		return true
	
	return false

# 检查进化
func check_evolve(pet_type: int):
	var pet = owned_pets[pet_type]
	var evolve_to = pet_database[pet_type].evolve_to
	
	if evolve_to == -1:
		return
	
	if pet.level >= pet_database[pet_type].evolve_level:
		# 进化
		var new_pet = pet_database[evolve_to].duplicate()
		new_pet["level"] = 1
		new_pet["exp"] = 0
		new_pet["loyalty"] = pet.loyalty
		
		owned_pets.erase(pet_type)
		owned_pets[evolve_to] = new_pet
		
		print("灵宠进化: ", pet.name, " -> ", new_pet.name)
		save_pets()

# 灵宠战斗死亡
func on_pet_died(pet_type: int):
	var pet_data = owned_pets.get(pet_type)
	if pet_data:
		emit_signal("pet_died", pet_data.name)
		
		# 忠诚度下降
		if owned_pets.has(pet_type):
			owned_pets[pet_type].loyalty = max(0, owned_pets[pet_type].loyalty - 10)
		
		# 取消召唤
		active_pet = null

# 获取灵宠信息
func get_pet_info(pet_type: int) -> Dictionary:
	return owned_pets.get(pet_type, {})

# 获取所有灵宠
func get_all_pets() -> Dictionary:
	return owned_pets.duplicate()

# 放生灵宠
func release_pet(pet_type: int) -> bool:
	if not owned_pets.has(pet_type):
		return false
	
	# 不能放生最高级灵宠
	if pet_type == PetType.HEAVENLY:
		print("无法放生神级灵宠")
		return false
	
	owned_pets.erase(pet_type)
	save_pets()
	print("放生灵宠")
	return true

# 保存/加载
func save_pets():
	var save_data = {}
	for pet_type in owned_pets.keys():
		save_data[str(pet_type)] = owned_pets[pet_type]
	
	var config = ConfigFile.new()
	config.set_value("pets", "owned", save_data)
	config.save("user://pets.cfg")

func load_pets():
	if FileAccess.file_exists("user://pets.cfg"):
		var config = ConfigFile.new()
		if config.load("user://pets.cfg") == OK:
			var save_data = config.get_value("pets", "owned", {})
			for pet_type_str in save_data.keys():
				var pet_type = int(pet_type_str)
				owned_pets[pet_type] = save_data[pet_type_str]

# 捕捉概率（基于怪物等级）
func get_capture_rate(monster_level: int, pet_rarity: int) -> float:
	var base_rate = 0.5
	var level_factor = monster_level * 0.02
	var rarity_factor = pet_rarity * 0.1
	return max(0.1, base_rate - rarity_factor + level_factor)
