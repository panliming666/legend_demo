extends Node

class_name ChallengeModeSystem

# 挑战模式系统 - 单机高难度玩法

signal challenge_started(challenge_id: String)
signal challenge_completed(challenge_id: String, time: float, stars: int)
signal challenge_failed(challenge_id: String)

# 挑战类型
enum ChallengeType {
	TIME_ATTACK,   # 限时挑战
	SURVIVAL,      # 生存挑战
	NO_DAMAGE,     # 无伤挑战
	BOSS_RUSH,     # Boss连战
	KILL_COUNT,    # 击杀数挑战
	PRECISION      # 精准挑战
}

# 挑战配置
var challenge_database: Dictionary = {
	"challenge_1": {
		"id": "challenge_1",
		"name": "速通新手村",
		"type": ChallengeType.TIME_ATTACK,
		"description": "在60秒内清理所有怪物",
		"time_limit": 60,
		"target": {"kill_all": true},
		"rewards": {"gold": 500, "item": "新手挑战徽章"},
		"star_requirements": [60, 45, 30]  # 3星/2星/1星
	},
	"challenge_2": {
		"id": "challenge_2",
		"name": "生存考验",
		"type": ChallengeType.SURVIVAL,
		"description": "在无尽波次中生存3分钟",
		"waves": 10,
		"duration": 180,
		"rewards": {"gold": 1000, "item": "生存者徽章"},
		"star_requirements": [180, 120, 60]
	},
	"challenge_3": {
		"id": "challenge_3",
		"name": "无伤通关",
		"type": ChallengeType.NO_DAMAGE,
		"description": "不受任何伤害完成关卡",
		"level": "新手森林",
		"rewards": {"gold": 2000, "item": "完美徽章"},
		"star_requirements": [1, 0.8, 0.5]  # 1=无伤, 0.8=受伤<20%, 0.5=受伤<50%
	},
	"challenge_4": {
		"id": "challenge_4",
		"name": "Boss连战",
		"type": ChallengeType.BOSS_RUSH,
		"description": "连续击败5个Boss",
		"boss_list": ["骨魔", "恶魔领主", "仙灵守护者", "远古青龙", "恶魔领主"],
		"rewards": {"gold": 5000, "item": "猎人徽章"},
		"star_requirements": [300, 240, 180]  # 总时间
	},
	"challenge_5": {
		"id": "challenge_5",
		"name": "百人斩",
		"type": ChallengeType.KILL_COUNT,
		"description": "在限定时间内击杀100个敌人",
		"kill_target": 100,
		"time_limit": 300,
		"rewards": {"gold": 3000, "item": "屠夫徽章"},
		"star_requirements": [100, 80, 60]
	},
	"challenge_6": {
		"id": "challenge_6",
		"name": "精准打击",
		"type": ChallengeType.PRECISION,
		"description": "命中率100%击杀50个敌人",
		"hit_target": 50,
		"miss_limit": 0,
		"rewards": {"gold": 2500, "item": "神射手徽章"},
		"star_requirements": [50, 40, 30]
	}
}

# 当前挑战状态
var current_challenge: Dictionary = {}
var is_in_challenge: bool = false

# 历史记录
var challenge_records: Dictionary = {}  # challenge_id: {best_time, stars}

func _ready():
	load_challenge_data()

# 开始挑战
func start_challenge(challenge_id: String) -> Dictionary:
	var challenge = challenge_database.get(challenge_id)
	if challenge == null:
		return {"success": false, "message": "挑战不存在"}
	
	current_challenge = {
		"id": challenge_id,
		"start_time": Time.get_unix_time_from_system(),
		"kills": 0,
		"damage_taken": 0,
		"hits": 0,
		"misses": 0,
		"bosses_killed": 0,
		"time_elapsed": 0.0
	}
	
	is_in_challenge = true
	
	emit_signal("challenge_started", challenge_id)
	
	return {
		"success": true,
		"challenge": challenge,
		"message": "挑战开始：%s" % challenge.name
	}

# 更新挑战进度
func update_progress(progress_type: String, amount: int = 1):
	if not is_in_challenge:
		return
	
	match progress_type:
		"kill":
			current_challenge.kills += amount
		"damage":
			current_challenge.damage_taken += amount
		"hit":
			current_challenge.hits += amount
		"miss":
			current_challenge.misses += amount
		"boss_kill":
			current_challenge.bosses_killed += amount

# 挑战Tick
func challenge_tick(delta: float):
	if not is_in_challenge:
		return
	
	current_challenge.time_elapsed += delta
	
	var challenge = challenge_database[current_challenge.id]
	
	# 检查限时挑战
	if challenge.type == ChallengeType.TIME_ATTACK:
		if current_challenge.time_elapsed > challenge.time_limit:
			complete_challenge(false)
	
	# 检查生存挑战
	elif challenge.type == ChallengeType.SURVIVAL:
		if current_challenge.time_elapsed >= challenge.duration:
			complete_challenge(true)

# 完成挑战
func complete_challenge(success: bool) -> Dictionary:
	if not is_in_challenge:
		return {"success": false, "message": "未在挑战中"}
	
	var challenge = challenge_database[current_challenge.id]
	var time_elapsed = current_challenge.time_elapsed
	
	is_in_challenge = false
	
	if success:
		# 计算星级
		var stars = calculate_stars(challenge, current_challenge)
		
		# 发放奖励
		var rewards = challenge.rewards.duplicate()
		
		# 更新记录
		if not challenge_records.has(challenge.id):
			challenge_records[challenge.id] = {"best_time": 999999, "stars": 0}
		
		if time_elapsed < challenge_records[challenge.id].best_time:
			challenge_records[challenge.id].best_time = time_elapsed
		
		if stars > challenge_records[challenge.id].stars:
			challenge_records[challenge.id].stars = stars
		
		emit_signal("challenge_completed", challenge.id, time_elapsed, stars)
		save_challenge_data()
		
		return {
			"success": true,
			"stars": stars,
			"time": time_elapsed,
			"rewards": rewards,
			"new_record": time_elapsed < challenge_records[challenge.id].best_time
		}
	else:
		emit_signal("challenge_failed", challenge.id)
		return {
			"success": false,
			"message": "挑战失败"
		}

# 计算星级
func calculate_stars(challenge: Dictionary, progress: Dictionary) -> int:
	var requirements = challenge.star_requirements
	var value = 0.0
	
	match challenge.type:
		ChallengeType.TIME_ATTACK, ChallengeType.BOSS_RUSH:
			value = progress.time_elapsed
		ChallengeType.SURVIVAL:
			value = progress.time_elapsed
		ChallengeType.KILL_COUNT:
			value = progress.kills
		ChallengeType.NO_DAMAGE:
			value = 1.0 - (progress.damage_taken / 100.0)  # 假设100血
		ChallengeType.PRECISION:
			value = progress.hits
	
	var stars = 0
	
	# 3星
	if value <= requirements[0]:
		stars = 3
	elif value <= requirements[1]:
		stars = 2
	elif value <= requirements[2]:
		stars = 1
	
	return stars

# 获取挑战信息
func get_challenge_info(challenge_id: String) -> Dictionary:
	var challenge = challenge_database.get(challenge_id)
	if challenge == null:
		return {}
	
	var record = challenge_records.get(challenge_id, {"best_time": 0, "stars": 0})
	
	return {
		"id": challenge_id,
		"name": challenge.name,
		"type": challenge.type,
		"description": challenge.description,
		"rewards": challenge.rewards,
		"star_requirements": challenge.star_requirements,
		"best_time": record.best_time,
		"stars": record.stars
	}

# 获取所有挑战
func get_all_challenges() -> Array:
	var result = []
	
	for challenge_id in challenge_database.keys():
		result.append(get_challenge_info(challenge_id))
	
	return result

# 获取总星级
func get_total_stars() -> int:
	var total = 0
	for challenge_id in challenge_records.keys():
		total += challenge_records[challenge_id].stars
	return total

# 保存/加载
func save_challenge_data():
	var config = ConfigFile.new()
	config.set_value("challenge", "records", challenge_records)
	config.save("user://challenge.cfg")

func load_challenge_data():
	if FileAccess.file_exists("user://challenge.cfg"):
		var config = ConfigFile.new()
		if config.load("user://challenge.cfg") == OK:
			challenge_records = config.get_value("challenge", "records", {})
