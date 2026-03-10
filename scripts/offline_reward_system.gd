extends Node

class_name OfflineRewardSystem

# 离线挂机奖励系统

signal offline_rewards_calculated(offline_seconds: int, rewards: Dictionary)
signal offline_rewards_claimed(rewards: Dictionary)

# 离线奖励设置
var settings: Dictionary = {
	"max_offline_hours": 12,  # 最大离线时长12小时
	"exp_per_hour": 1000,     # 每小时经验
	"gold_per_hour": 500,     # 每小时金币
	"drop_rate": 0.3,         # 掉落概率
	"possible_drops": ["灵草", "灵石", "装备"]
}

# 上次离线时间
var last_online_time: int = 0

func _ready():
	load_offline_data()

# 玩家上线时调用
func on_player_login() -> Dictionary:
	if last_online_time == 0:
		return {"success": false, "message": "首次登录，无离线奖励"}
	
	var current_time = Time.get_unix_time_from_system()
	var offline_seconds = current_time - last_online_time
	var offline_hours = float(offline_seconds) / 3600.0
	
	# 限制最大离线时长
	var actual_hours = min(offline_hours, settings.max_offline_hours)
	
	if actual_hours < 0.5:  # 少于30分钟无奖励
		return {"success": false, "message": "离线时间过短"}
	
	# 计算奖励
	var rewards = calculate_rewards(actual_hours)
	
	emit_signal("offline_rewards_calculated", int(actual_hours * 3600), rewards)
	
	return {
		"success": true,
		"offline_hours": actual_hours,
		"rewards": rewards,
		"message": "离线挂机 %.1f 小时" % actual_hours
	}

# 计算奖励
func calculate_rewards(hours: float) -> Dictionary:
	var exp = int(hours * settings.exp_per_hour)
	var gold = int(hours * settings.gold_per_hour)
	var drops = []
	
	# 计算掉落
	var drop_count = int(hours * settings.drop_rate)
	for i in range(drop_count):
		var item = settings.possible_drops[randi() % settings.possible_drops.size()]
		drops.append(item)
	
	return {
		"exp": exp,
		"gold": gold,
		"items": drops
	}

# 领取离线奖励
func claim_offline_rewards() -> Dictionary:
	var result = on_player_login()
	if result.success:
		# 发放奖励
		emit_signal("offline_rewards_claimed", result.rewards)
		
	# 更新时间
	update_online_time()
	
	return result

# 更新在线时间
func update_online_time():
	last_online_time = Time.get_unix_time_from_system()
	save_offline_data()

# 玩家下线时调用
func on_player_logout():
	update_online_time()

# 保存/加载
func save_offline_data():
	var config = ConfigFile.new()
	config.set_value("offline", "last_online", last_online_time)
	config.save("user://offline.cfg")

func load_offline_data():
	if FileAccess.file_exists("user://offline.cfg"):
		var config = ConfigFile.new()
		if config.load("user://offline.cfg") == OK:
			last_online_time = config.get_value("offline", "last_online", 0)
