extends Node

class_name SignSystem

# 签到系统

signal signed(day: int, rewards: Dictionary)
signal monthly_reward_claimed(month: int)

var last_sign_date: String = ""
var consecutive_days: int = 0
var total_days: int = 0

# 签到奖励配置
var daily_rewards: Dictionary = {
	1: {"gold": 100, "exp": 100},
	2: {"gold": 120, "exp": 120},
	3: {"gold": 150, "exp": 150, "items": ["灵草×1"]},
	4: {"gold": 180, "exp": 180},
	5: {"gold": 200, "exp": 200, "items": ["灵石×5"]},
	6: {"gold": 250, "exp": 250},
	7: {"gold": 500, "exp": 500, "items": ["灵丹×1", "灵草×3"]}
}

# 月度大奖
var monthly_reward: Dictionary = {
	"day_required": 21,
	"rewards": {"gold": 5000, "exp": 5000, "items": ["仙级装备×1", "灵石×100"]}
}

func _ready():
	load_sign()

# 签到
func sign_in() -> Dictionary:
	var today = Time.get_date_string_from_system()
	
	# 检查是否已签到
	if last_sign_date == today:
		return {"success": false, "message": "今日已签到"}
	
	# 检查是否连续签到
	var yesterday = get_yesterday_date()
	if last_sign_date == yesterday:
		consecutive_days += 1
	else:
		consecutive_days = 1
	
	total_days += 1
	last_sign_date = today
	
	# 获取奖励
	var reward_day = consecutive_days if consecutive_days <= 7 else 7
	var reward = daily_rewards[reward_day].duplicate()
	
	emit_signal("signed", consecutive_days, reward)
	save_sign()
	
	return {
		"success": true,
		"day": consecutive_days,
		"total_days": total_days,
		"reward": reward
	}

# 领取月度大奖
func claim_monthly_reward() -> Dictionary:
	if consecutive_days < monthly_reward.day_required:
		return {
			"success": false,
			"message": "签到天数不足，需要%d天" % monthly_reward.day_required
		}
	
	emit_signal("monthly_reward_claimed", consecutive_days)
	save_sign()
	
	return {
		"success": true,
		"rewards": monthly_reward.rewards
	}

# 获取签到状态
func get_sign_status() -> Dictionary:
	var today = Time.get_date_string_from_system()
	var can_sign = last_sign_date != today
	
	var yesterday = get_yesterday_date()
	var is_continuous = last_sign_date == yesterday
	
	return {
		"can_sign": can_sign,
		"today": today,
		"last_sign": last_sign_date,
		"consecutive_days": consecutive_days,
		"total_days": total_days,
		"is_continuous": is_continuous,
		"monthly_progress": float(consecutive_days) / monthly_reward.day_required * 100
	}

# 获取昨日日期
func get_yesterday_date() -> String:
	var today = Time.get_datetime_dict_from_system()
	var unix_time = Time.get_unix_time_from_system()
	unix_time -= 86400  # 减去一天
	return Time.get_date_string_from_unix_time(unix_time)

# 保存/加载
func save_sign():
	var cfg = ConfigFile.new()
	cfg.set_value("sign", "last_date", last_sign_date)
	cfg.set_value("sign", "consecutive_days", consecutive_days)
	cfg.set_value("sign", "total_days", total_days)
	cfg.save("user://sign.cfg")

func load_sign():
	if FileAccess.file_exists("user://sign.cfg"):
		var cfg = ConfigFile.new()
		if cfg.load("user://sign.cfg") == OK:
			last_sign_date = cfg.get_value("sign", "last_date", "")
			consecutive_days = cfg.get_value("sign", "consecutive_days", 0)
			total_days = cfg.get_value("sign", "total_days", 0)
