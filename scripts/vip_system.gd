extends Node

class_name VIPSystem

# VIP系统

signal vip_level_changed(new_level: int)

# VIP等级
var vip_level: int = 0
var vip_exp: int = 0

# VIP等级配置
var vip_config: Dictionary = {
	0: {"name": "普通玩家", "exp_required": 0},
	1: {"name": "VIP1", "exp_required": 100, "benefits": ["每日签到+1", "经验加成+5%"]},
	2: {"name": "VIP2", "exp_required": 500, "benefits": ["每日签到+2", "经验加成+10%", "背包上限+20"]},
	3: {"name": "VIP3", "exp_required": 2000, "benefits": ["每日签到+3", "经验加成+15%", "掉落加成+5%", "专属传送"]},
	4: {"name": "VIP4", "exp_required": 5000, "benefits": ["每日签到+4", "经验加成+20%", "掉落加成+10%", "专属称号"]},
	5: {"name": "VIP5", "exp_required": 10000, "benefits": ["每日签到+5", "经验加成+30%", "掉落加成+15%", "专属时装"]},
	6: {"name": "VIP6", "exp_required": 20000, "benefits": ["每日签到+6", "经验加成+40%", "掉落加成+20%", "专属坐骑"]},
	7: {"name": "VIP7", "exp_required": 50000, "benefits": ["每日签到+7", "经验加成+50%", "掉落加成+30%", "专属灵宠"]},
	8: {"name": "VIP8", "exp_required": 100000, "benefits": ["每日签到+8", "经验加成+80%", "掉落加成+50%", "全属性+10%"]},
	9: {"name": "VIP9", "exp_required": 200000, "benefits": ["每日签到+9", "经验加成+100%", "掉落加成+100%", "全属性+20%"]},
	10: {"name": "SVIP", "exp_required": 500000, "benefits": ["无限每日签到", "经验加成+200%", "掉落加成+200%", "全属性+50%"]}
}

func _ready():
	load_vip()

# 获得VIP经验
func add_vip_exp(amount: int):
	vip_exp += amount
	check_level_up()
	save_vip()

# 检查升级
func check_level_up():
	var new_level = 0
	
	for level in range(10, -1, -1):
		if vip_exp >= vip_config[level].exp_required:
			new_level = level
			break
	
	if new_level > vip_level:
		vip_level = new_level
		emit_signal("vip_level_changed", vip_level)
		print("VIP等级提升：", vip_level)

# 获取VIP信息
func get_vip_info() -> Dictionary:
	var config = vip_config[vip_level]
	var next_level = vip_level + 1
	var exp_needed = 0
	var exp_progress = 0
	
	if next_level <= 10:
		exp_needed = vip_config[next_level].exp_required - vip_exp
		exp_progress = vip_exp - vip_config[vip_level].exp_required
	
	return {
		"level": vip_level,
		"name": config.name,
		"exp": vip_exp,
		"exp_needed": exp_needed,
		"exp_progress": exp_progress,
		"benefits": config.benefits,
		"progress_percent": float(exp_progress) / (exp_needed + exp_progress) * 100 if exp_needed > 0 else 100
	}

# 获取VIP加成
func get_vip_bonus() -> Dictionary:
	var bonus = {
		"exp_bonus": vip_level * 0.05,
		"drop_bonus": vip_level * 0.05,
		"sign_bonus": vip_level
	}
	
	if vip_level >= 8:
		bonus["all_stats"] = 0.1 * (vip_level - 7)
	elif vip_level >= 9:
		bonus["all_stats"] = 0.2
	
	return bonus

# 是否为VIP
func is_vip() -> bool:
	return vip_level > 0

# 保存/加载
func save_vip():
	var config = ConfigFile.new()
	config.set_value("vip", "level", vip_level)
	config.set_value("vip", "exp", vip_exp)
	config.save("user://vip.cfg")

func load_vip():
	if FileAccess.file_exists("user://vip.cfg"):
		var cfg = ConfigFile.new()
		if cfg.load("user://vip.cfg") == OK:
			vip_level = cfg.get_value("vip", "level", 0)
			vip_exp = cfg.get_value("vip", "exp", 0)
