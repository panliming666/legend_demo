extends Node

class_name VIPSystem

# VIP会员系统

signal vip_level_changed(new_level: int)
signal vip_points_gained(points: int)

# VIP等级配置
var vip_levels: Dictionary = {
	0: {"name": "普通修士", "points_required": 0, "benefits": {}},
	1: {"name": "VIP1", "points_required": 100, "benefits": {"exp_bonus": 0.05, "gold_bonus": 0.05}},
	2: {"name": "VIP2", "points_required": 500, "benefits": {"exp_bonus": 0.10, "gold_bonus": 0.10, "daily_gift": 1}},
	3: {"name": "VIP3", "points_required": 1000, "benefits": {"exp_bonus": 0.15, "gold_bonus": 0.15, "daily_gift": 2}},
	4: {"name": "VIP4", "points_required": 2000, "benefits": {"exp_bonus": 0.20, "gold_bonus": 0.20, "daily_gift": 3, "auto_battle": true}},
	5: {"name": "VIP5", "points_required": 5000, "benefits": {"exp_bonus": 0.25, "gold_bonus": 0.25, "daily_gift": 5, "auto_battle": true, "extra_dungeon": 1}},
	6: {"name": "VIP6", "points_required": 10000, "benefits": {"exp_bonus": 0.30, "gold_bonus": 0.30, "daily_gift": 10, "auto_battle": true, "extra_dungeon": 2}},
	7: {"name": "VIP7", "points_required": 20000, "benefits": {"exp_bonus": 0.40, "gold_bonus": 0.40, "daily_gift": 15, "auto_battle": true, "extra_dungeon": 3, "special_title": true}},
	8: {"name": "VIP8", "points_required": 50000, "benefits": {"exp_bonus": 0.50, "gold_bonus": 0.50, "daily_gift": 20, "auto_battle": true, "extra_dungeon": 5, "special_title": true, "exclusive_mount": true}},
	9: {"name": "VIP9", "points_required": 100000, "benefits": {"exp_bonus": 0.60, "gold_bonus": 0.60, "daily_gift": 30, "auto_battle": true, "extra_dungeon": 10, "special_title": true, "exclusive_mount": true, "exclusive_fashion": true}},
	10: {"name": "至尊VIP", "points_required": 200000, "benefits": {"exp_bonus": 0.80, "gold_bonus": 0.80, "daily_gift": 50, "auto_battle": true, "extra_dungeon": 20, "special_title": true, "exclusive_mount": true, "exclusive_fashion": true, "exclusive_pet": true}}
}

var current_vip_level: int = 0
var vip_points: int = 0

func _ready():
	load_vip()

# 添加VIP点数
func add_vip_points(points: int) -> bool:
	vip_points += points
	emit_signal("vip_points_gained", points)
	
	# 检查升级
	var old_level = current_vip_level
	check_level_up()
	
	if current_vip_level > old_level:
		return true
	return false

# 检查升级
func check_level_up():
	for level in range(10, 0, -1):
		if vip_points >= vip_levels[level].points_required:
			if current_vip_level < level:
				current_vip_level = level
				emit_signal("vip_level_changed", level)
			break

# 获取当前特权
func get_benefits() -> Dictionary:
	return vip_levels.get(current_vip_level, {}).get("benefits", {})

# 获取特权值
func get_benefit(benefit_name: String) -> float:
	var benefits = get_benefits()
	return benefits.get(benefit_name, 0)

# 获取VIP信息
func get_vip_info() -> Dictionary:
	var current = vip_levels[current_vip_level]
	var next_level = min(current_vip_level + 1, 10)
	var next = vip_levels[next_level]
	
	return {
		"level": current_vip_level,
		"name": current.name,
		"points": vip_points,
		"current_required": current.points_required,
		"next_required": next.points_required,
		"progress": float(vip_points - current.points_required) / (next.points_required - current.points_required) if next_level > current_vip_level else 1.0,
		"benefits": current.benefits
	}

# 每日VIP奖励
func claim_daily_vip_reward() -> Dictionary:
	var benefits = get_benefits()
	var daily_gift = benefits.get("daily_gift", 0)
	
	if daily_gift <= 0:
		return {"success": false, "message": "当前VIP等级无每日奖励"}
	
	return {
		"success": true,
		"gold": daily_gift * 100,
		"exp": daily_gift * 500,
		"items": ["VIP礼包×" + str(daily_gift)],
		"message": "领取VIP每日奖励"
	}

# 保存/加载
func save_vip():
	var config = ConfigFile.new()
	config.set_value("vip", "level", current_vip_level)
	config.set_value("vip", "points", vip_points)
	config.save("user://vip.cfg")

func load_vip():
	if FileAccess.file_exists("user://vip.cfg"):
		var config = ConfigFile.new()
		if config.load("user://vip.cfg") == OK:
			current_vip_level = config.get_value("vip", "level", 0)
			vip_points = config.get_value("vip", "points", 0)
