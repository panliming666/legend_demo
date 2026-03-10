extends Node

class_name SiegeWarfare

# 攻城战系统 - 大型PVP战斗

signal siege_started(siege_id: String)
signal siege_ended(siege_id: String, winner: String)
signal siege_point_captured(point_name: String, guild_name: String)

# 攻城战配置
var siege_config: Dictionary = {
	"registration_duration": 300,    # 报名时长5分钟
	"preparation_duration": 180,    # 准备时长3分钟
	"battle_duration": 1800,        # 战斗时长30分钟
	"min_guilds": 2,
	"max_guilds": 10
}

# 活跃的攻城战
var active_sieges: Dictionary = {}

# 城池列表
var cities: Array = [
	{
		"id": "city_1",
		"name": "龙城",
		"level": 1,
		"owner_guild": "",
		"rewards": {"gold": 10000, "exp": 1000},
		"capture_points": ["北门", "南门", "东门", "西门", "中央"]
	},
	{
		"id": "city_2",
		"name": "凤鸣城",
		"level": 2,
		"owner_guild": "",
		"rewards": {"gold": 20000, "exp": 2000},
		"capture_points": ["城门", "城墙", "内城", "皇宫"]
	},
	{
		"id": "city_3",
		"name": "虎啸城",
		"level": 3,
		"owner_guild": "",
		"rewards": {"gold": 50000, "exp": 5000},
		"capture_points": ["外城", "中城", "内城", "主殿"]
	}
]

# 攻城战状态
enum SiegeState {
	REGISTRATION,  # 报名阶段
	PREPARATION,   # 准备阶段
	BATTLE,        # 战斗阶段
	ENDED          # 已结束
}

func _ready():
	# 定时检查攻城战
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_check_siege_timers)
	add_child(timer)

func get_city_by_id(city_id: String) -> Dictionary:
	for city in cities:
		if city.id == city_id:
			return city
	return {}

func get_active_siege(city_id: String) -> Dictionary:
	return active_sieges.get(city_id, {})

func start_siege_registration(city_id: String) -> bool:
	var city = get_city_by_id(city_id)
	if city.is_empty():
		print("城池不存在")
		return false
	
	if active_sieges.has(city_id):
		print("该城池已有攻城战进行中")
		return false
	
	# 创建攻城战
	var siege = {
		"city_id": city_id,
		"city_name": city.name,
		"state": SiegeState.REGISTRATION,
		"start_time": Time.get_unix_time_from_system(),
		"end_time": Time.get_unix_time_from_system() + siege_config.registration_duration,
		"registered_guilds": [],
		"capture_points": {},
		"scores": {}
	}
	
	# 初始化据点
	for point in city.capture_points:
		siege.capture_points[point] = {"owner": "", "hp": 100}
	
	active_sieges[city_id] = siege
	emit_signal("siege_started", city_id)
	print("攻城战报名开始: ", city.name)
	return true

func register_guild(city_id: String, guild_name: String) -> bool:
	var siege = active_sieges.get(city_id)
	if siege == null or siege.state != SiegeState.REGISTRATION:
		print("不在报名阶段")
		return false
	
	if siege.registered_guilds.has(guild_name):
		print("行会已报名")
		return false
	
	if siege.registered_guilds.size() >= siege_config.max_guilds:
		print("报名已满")
		return false
	
	siege.registered_guilds.append(guild_name)
	siege.scores[guild_name] = 0
	print(guild_name, "报名参加攻城战")
	return true

func _check_siege_timers():
	var current_time = Time.get_unix_time_from_system()
	
	for city_id in active_sieges.keys():
		var siege = active_sieges[city_id]
		
		if current_time >= siege.end_time:
			_transition_siege_state(city_id)

func _transition_siege_state(city_id: String):
	var siege = active_sieges[city_id]
	
	match siege.state:
		SiegeState.REGISTRATION:
			# 转入准备阶段
			if siege.registered_guilds.size() >= siege_config.min_guilds:
				siege.state = SiegeState.PREPARATION
				siege.end_time = Time.get_unix_time_from_system() + siege_config.preparation_duration
				print("攻城战准备阶段: ", siege.city_name)
			else:
				print("报名行会不足，攻城战取消")
				active_sieges.erase(city_id)
		
		SiegeState.PREPARATION:
			# 转入战斗阶段
			siege.state = SiegeState.BATTLE
			siege.end_time = Time.get_unix_time_from_system() + siege_config.battle_duration
			siege.battle_start_time = Time.get_unix_time_from_system()
			print("攻城战开始: ", siege.city_name)
		
		SiegeState.BATTLE:
			# 结束攻城战
			_end_siege(city_id)

func _end_siege(city_id: String):
	var siege = active_sieges[city_id]
	var winner = _determine_winner(siege)
	
	# 更新城主
	for city in cities:
		if city.id == city_id:
			city.owner_guild = winner
			break
	
	# 发放奖励
	_distribute_rewards(city_id, winner)
	
	siege.state = SiegeState.ENDED
	emit_signal("siege_ended", city_id, winner)
	print("攻城战结束: ", siege.city_name, " 胜者: ", winner)
	
	active_sieges.erase(city_id)

func _determine_winner(siege: Dictionary) -> String:
	var max_score = 0
	var winner = ""
	
	for guild in siege.scores.keys():
		if siege.scores[guild] > max_score:
			max_score = siege.scores[guild]
			winner = guild
	
	# 如果没有积分，取第一个报名的行会
	if winner.is_empty() and siege.registered_guilds.size() > 0:
		winner = siege.registered_guilds[0]
	
	return winner

func capture_point(city_id: String, point_name: String, guild_name: String, damage: int) -> bool:
	var siege = active_sieges.get(city_id)
	if siege == null or siege.state != SiegeState.BATTLE:
		return false
	
	var point = siege.capture_points.get(point_name)
	if point == null:
		return false
	
	point.hp -= damage
	
	if point.hp <= 0:
		# 据点被占领
		var old_owner = point.owner
		point.owner = guild_name
		point.hp = 100  # 重置HP
		
		# 积分
		if not siege.scores.has(guild_name):
			siege.scores[guild_name] = 0
		siege.scores[guild_name] += 100
		
		emit_signal("siege_point_captured", point_name, guild_name)
		print(guild_name, "占领了", point_name)
		return true
	
	return false

func attack_capture_point(city_id: String, point_name: String, guild_name: String, damage: int) -> int:
	var siege = active_sieges.get(city_id)
	if siege == null or siege.state != SiegeState.BATTLE:
		return 0
	
	var point = siege.capture_points.get(point_name)
	if point == null:
		return 0
	
	# 只有非占领方可以攻击
	if point.owner == guild_name:
		return 0
	
	var actual_damage = min(damage, point.hp)
	point.hp -= actual_damage
	
	# 占领判定
	if point.hp <= 0:
		point.owner = guild_name
		point.hp = 100
		
		if not siege.scores.has(guild_name):
			siege.scores[guild_name] = 0
		siege.scores[guild_name] += 100
		
		emit_signal("siege_point_captured", point_name, guild_name)
		print(guild_name, "占领了", point_name)
	
	return actual_damage

func _distribute_rewards(city_id: String, winner_guild: String):
	var city = get_city_by_id(city_id)
	if city.is_empty():
		return
	
	var rewards = city.rewards
	print("奖励发放 - 金币:", rewards.gold, " 经验:", rewards.exp)
	# 实际发放需要通过GuildSystem

func get_siege_status(city_id: String) -> Dictionary:
	var siege = active_sieges.get(city_id)
	if siege == null:
		return {"active": false}
	
	return {
		"active": true,
		"city_name": siege.city_name,
		"state": siege.state,
		"remaining_time": max(0, siege.end_time - Time.get_unix_time_from_system()),
		"registered_guilds": siege.registered_guilds,
		"capture_points": siege.capture_points,
		"scores": siege.scores
	}

func get_city_list() -> Array:
	var result = []
	for city in cities:
		result.append({
			"id": city.id,
			"name": city.name,
			"level": city.level,
			"owner": city.owner_guild,
			"has_active_siege": active_sieges.has(city.id)
		})
	return result
