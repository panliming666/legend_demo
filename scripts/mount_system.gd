extends Node

class_name MountSystem

# 坐骑系统

signal mount_ride(mount_name: String)
signal mount_dismount()
signal mount_level_up(mount_name: String, new_level: int)

# 坐骑类型
enum MountType {
	HORSE,      # 骏马
	DEER,       # 灵鹿
	WOLF,       # 灵狼
	TIGER,      # 猛虎
	CRANE,      # 仙鹤
	LION,       # 雄狮
	DRAGON,     # 飞龙
	PHOENIX     # 凤凰
}

# 坐骑品质
enum MountQuality {
	COMMON,     # 普通
	ELITE,     # 精英
	ROYAL,     # 王者
	LEGENDARY,  # 传说
	MYTHICAL   # 神话
}

# 坐骑数据库
var mount_database: Dictionary = {
	MountType.HORSE: {
		"name": "骏马",
		"quality": MountQuality.COMMON,
		"base_speed": 30,
		"hp_bonus": 50,
		"attack_bonus": 5,
		"defense_bonus": 3,
		"level_required": 1,
		"evolve_to": MountType.DEER,
		"evolve_level": 10,
		"description": "日行千里的良驹",
		"color": Color(0.6, 0.4, 0.2, 1)
	},
	MountType.DEER: {
		"name": "灵鹿",
		"quality": MountQuality.COMMON,
		"base_speed": 45,
		"hp_bonus": 80,
		"attack_bonus": 8,
		"defense_bonus": 5,
		"level_required": 10,
		"evolve_to": MountType.WOLF,
		"evolve_level": 20,
		"description": "灵山福地的仙鹿",
		"color": Color(0.7, 0.6, 0.5, 1)
	},
	MountType.WOLF: {
		"name": "灵狼",
		"quality": MountQuality.ELITE,
		""base_speed": 60,
		"hp_bonus": 120,
		"attack_bonus": 12,
		"defense_bonus": 8,
		"level_required": 20,
		"evolve_to": MountType.TIGER,
		"evolve_level": 30,
		"description": "北方神速的狼王",
		"color": Color(0.5, 0.5, 0.6, 1)
	},
	MountType.TIGER: {
		"name": "猛虎",
		"quality": MountQuality.ELITE,
		"base_speed": 75,
		"hp_bonus": 180,
		"attack_bonus": 18,
		"defense_bonus": 12,
		"level_required": 30,
		"evolve_to": MountType.CRANE,
		"evolve_level": 40,
		"description": "万兽之王，威风凛凛",
		"color": Color(0.9, 0.5, 0.2, 1)
	},
	MountType.CRANE: {
		"name": "仙鹤",
		"quality": MountQuality.ROYAL,
		"base_speed": 100,
		"hp_bonus": 250,
		"attack_bonus": 25,
		"defense_bonus": 18,
		"level_required": 40,
		"evolve_to": MountType.LION,
		"evolve_level": 50,
		"description": "翱翔九天的仙鹤",
		"color": Color(0.9, 0.9, 0.9, 1)
	},
	MountType.LION: {
		"name": "雄狮",
		"quality": MountQuality.ROYAL,
		"base_speed": 90,
		"hp_bonus": 300,
		"attack_bonus": 30,
		"defense_bonus": 22,
		"level_required": 50,
		"evolve_to": MountType.DRAGON,
		"evolve_level": 60,
		"description": "草原霸主，狮王降临",
		"color": Color(0.8, 0.6, 0.1, 1)
	},
	MountType.DRAGON: {
		"name": "飞龙",
		"quality": MountQuality.LEGENDARY,
		"base_speed": 150,
		"hp_bonus": 500,
		"attack_bonus": 50,
		"defense_bonus": 35,
		"level_required": 60,
		"evolve_to": MountType.PHOENIX,
		"evolve_level": 80,
		"description": "呼风唤雨的神龙",
		"color": Color(0.3, 0.5, 0.9, 1)
	},
	MountType.PHOENIX: {
		"name": "凤凰",
		"quality": MountQuality.MYTHICAL,
		"base_speed": 200,
		"hp_bonus": 800,
		"attack_bonus": 80,
		"defense_bonus": 50,
		"level_required": 80,
		"evolve_to": -1,
		"evolve_level": 0,
		"description": "浴火重生的神鸟",
		"color": Color(1, 0.4, 0.1, 1)
	}
}

# 玩家拥有的坐骑
var owned_mounts: Dictionary = {}  # mount_type: mount_data
var active_mount: int = -1  # 当前骑乘的坐骑类型
var is_riding: bool = false

func _ready():
	load_mounts()

# 获取坐骑
func obtain_mount(mount_type: int) -> bool:
	var mount_data = mount_database.get(mount_type)
	if mount_data == null:
		return false
	
	if owned_mounts.has(mount_type):
		print("已拥有该坐骑")
		return false
	
	# 添加坐骑
	var new_mount = mount_data.duplicate()
	new_mount["level"] = 1
	new_mount["exp"] = 0
	new_mount["loyalty"] = 50  # 亲密度
	owned_mounts[mount_type] = new_mount
	
	save_mounts()
	print("获得坐骑：", new_mount.name)
	return true

# 骑乘/下骑
func toggle_ride() -> bool:
	if active_mount < 0:
		return false
	
	if is_riding:
		return dismount()
	else:
		return ride()

func ride() -> bool:
	if active_mount < 0:
		return false
	
	if is_riding:
		return false
	
	var mount = owned_mounts.get(active_mount)
	if mount == null:
		return false
	
	is_riding = true
	emit_signal("mount_ride", mount.name)
	print("骑乘：", mount.name)
	return true

func dismount() -> bool:
	if not is_riding:
		return false
	
	var mount = owned_mounts.get(active_mount)
	is_riding = false
	emit_signal("mount_dismount")
	print("下骑")
	return true

# 切换坐骑
func switch_mount(mount_type: int) -> bool:
	if not owned_mounts.has(mount_type):
		return false
	
	# 如果正在骑乘，先下骑
	if is_riding:
		dismount()
	
	active_mount = mount_type
	print("切换坐骑：", owned_mounts[mount_type].name)
	return true

# 坐骑升级
func mount_level_up(mount_type: int) -> bool:
	if not owned_mounts.has(mount_type):
		return false
	
	var mount = owned_mounts[mount_type]
	var exp_needed = mount.level * 50
	
	if mount.exp >= exp_needed:
		mount.level += 1
		mount.exp -= exp_needed
		
		# 属性提升
		mount.hp_bonus = int(mount.hp_bonus * 1.1)
		mount.attack_bonus = int(mount.attack_bonus * 1.1)
		mount.defense_bonus = int(mount.defense_bonus * 1.1)
		mount.base_speed = int(mount.base_speed * 1.05)
		
		# 检查进化
		check_evolve(mount_type)
		
		emit_signal("mount_level_up", mount.name, mount.level)
		save_mounts()
		return true
	
	return false

# 增加经验
func add_exp(mount_type: int, exp: int):
	if not owned_mounts.has(mount_type):
		return
	
	owned_mounts[mount_type].exp += exp
	mount_level_up(mount_type)

# 检查进化
func check_evolve(mount_type: int):
	var mount = owned_mounts[mount_type]
	var evolve_to = mount_database[mount_type].evolve_to
	
	if evolve_to == -1:
		return
	
	if mount.level >= mount_database[mount_type].evolve_level:
		# 进化
		var new_mount_data = mount_database[evolve_to].duplicate()
		new_mount_data["level"] = 1
		new_mount_data["exp"] = 0
		new_mount_data["loyalty"] = mount.loyalty
		
		owned_mounts.erase(mount_type)
		owned_mounts[evolve_to] = new_mount_data
		
		if active_mount == mount_type:
			active_mount = evolve_to
		
		print("坐骑进化：", mount.name new_mount_data.name)
		save_mounts()

#, " -> ", 获取坐骑属性加成
func get_mount_bonus() -> Dictionary:
	if not is_riding or active_mount < 0:
		return {}
	
	var mount = owned_mounts.get(active_mount)
	if mount == null:
		return {}
	
	return {
		"move_speed": mount.base_speed,
		"max_hp": mount.hp_bonus,
		"physical_attack": mount.attack_bonus,
		"physical_defense": mount.defense_bonus
	}

# 获取坐骑信息
func get_mount_info(mount_type: int) -> Dictionary:
	return owned_mounts.get(mount_type, {})

# 获取所有坐骑
func get_all_mounts() -> Dictionary:
	return owned_mounts.duplicate()

# 获取当前状态
func get_status() -> Dictionary:
	return {
		"is_riding": is_riding,
		"active_mount": active_mount,
		"active_mount_name": owned_mounts.get(active_mount, {}).get("name", "") if active_mount >= 0 else ""
	}

# 保存/加载
func save_mounts():
	var save_data = {}
	for mt in owned_mounts.keys():
		save_data[str(mt)] = owned_mounts[mt]
	
	var config = ConfigFile.new()
	config.set_value("mounts", "owned", save_data)
	config.set_value("mounts", "active", active_mount)
	config.save("user://mounts.cfg")

func load_mounts():
	if FileAccess.file_exists("user://mounts.cfg"):
		var config = ConfigFile.new()
		if config.load("user://mounts.cfg") == OK:
			var save_data = config.get_value("mounts", "owned", {})
			for mt_str in save_data.keys():
				var mt = int(mt_str)
				owned_mounts[mt] = save_data[mt_str]
			active_mount = config.get_value("mounts", "active", -1)
