extends Node

class_name SignInSystem

# 签到系统

signal daily_sign_in(day: int, rewards: Dictionary)
signal monthly_sign_complete()

# 当前签到数据
var current_month: int = 0
var sign_in_days: Array = []  # 已签到的日期列表
var consecutive_days: int = 0  # 连续签到天数
var last_sign_date: int = 0  # 上次签到时间戳

func _ready():
	load_sign_data()
	check_new_month()

# 检查新月
func check_new_month():
	var now = Time.get_date_dict_from_system()
	if now.month != current_month:
		# 新月，重置签到
		current_month = now.month
		sign_in_days.clear()
		consecutive_days = 0
		save_sign_data()
		print("新月开始，签到已重置")

# 今日签到
func sign_in_today() -> Dictionary:
	check_new_month()
	
	var today = Time.get_date_dict_from_system().day
	
	# 检查今天是否已签到
	if today in sign_in_days:
		return {"success": false, "message": "今天已经签到过了"}
	
	# 检查是否连续签到
	var yesterday = today - 1
	if yesterday in sign_in_days:
		consecutive_days += 1
	else:
		consecutive_days = 1
	
	# 记录签到
	sign_in_days.append(today)
	last_sign_date = Time.get_unix_time_from_system()
	
	# 计算奖励
	var rewards = calculate_rewards(today, consecutive_days)
	
	emit_signal("daily_sign_in", today, rewards)
	save_sign_data()
	
	# 检查是否签满全月
	if sign_in_days.size() >= get_days_in_month():
		emit_signal("monthly_sign_complete")
	
	return {
		"success": true,
		"day": today,
		"consecutive": consecutive_days,
		"rewards": rewards,
		"message": "签到成功！连续签到第%d天" % consecutive_days
	}

# 计算奖励
func calculate_rewards(day: int, consecutive: int) -> Dictionary:
	var rewards: Dictionary = {}
	
	# 基础奖励
	rewards["exp"] = day * 10
	rewards["gold"] = day * 5
	
	# 特殊天数奖励
	if day == 7:
		rewards["items"] = ["灵石×10"]
	elif day == 14:
		rewards["items"] = ["灵石×20", "灵草×10"]
	elif day == 21:
		rewards["items"] = ["灵石×30", "灵芝×5"]
	elif day == 28:
		rewards["items"] = ["仙草×5", "灵玉×3"]
	
	# 连续签到奖励
	if consecutive >= 7:
		rewards["exp"] = int(rewards["exp"] * 1.5)
		rewards["gold"] = int(rewards["gold"] * 1.5)
	
	if consecutive >= 15:
		if not rewards.has("items"):
			rewards["items"] = []
		rewards["items"].append("筑基丹×1")
	
	return rewards

# 获取当前月份天数
func get_days_in_month() -> int:
	var date = Time.get_date_dict_from_system()
	match date.month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			return 29 if date.year % 4 == 0 else 28
	return 30

# 检查今天是否已签到
func has_signed_today() -> bool:
	var today = Time.get_date_dict_from_system().day
	return today in sign_in_days

# 获取签到状态
func get_sign_in_status() -> Dictionary:
	check_new_month()
	
	var today = Time.get_date_dict_from_system().day
	var days_in_month = get_days_in_month()
	
	return {
		"current_month": current_month,
		"today": today,
		"signed_today": has_signed_today(),
		"signed_days": sign_in_days.size(),
		"total_days": days_in_month,
		"consecutive_days": consecutive_days,
		"reward_preview": calculate_rewards(today + 1, consecutive_days + 1)
	}

# 获取本月签到日历
func get_monthly_calendar() -> Array:
	check_new_month()
	
	var days_in_month = get_days_in_month()
	var calendar = []
	
	for day in range(1, days_in_month + 1):
		calendar.append({
			"day": day,
			"signed": day in sign_in_days,
			"is_today": day == Time.get_date_dict_from_system().day
		})
	
	return calendar

# 保存/加载
func save_sign_data():
	var config = ConfigFile.new()
	config.set_value("sign", "month", current_month)
	config.set_value("sign", "days", sign_in_days)
	config.set_value("sign", "consecutive", consecutive_days)
	config.set_value("sign", "last_sign", last_sign_date)
	config.save("user://sign_in.cfg")

func load_sign_data():
	if FileAccess.file_exists("user://sign_in.cfg"):
		var config = ConfigFile.new()
		if config.load("user://sign_in.cfg") == OK:
			current_month = config.get_value("sign", "month", 0)
			sign_in_days = config.get_value("sign", "days", [])
			consecutive_days = config.get_value("sign", "consecutive", 0)
			last_sign_date = config.get_value("sign", "last_sign", 0)
