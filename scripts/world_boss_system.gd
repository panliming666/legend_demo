extends Node

class_name WorldBossSystem

# 世界Boss系统

signal world_boss_spawn(boss_name: String, location: String)
signal world_boss_died(boss_name: String, damage_ranking: Array)
signal world_boss_end()

# Boss状态
enum BossState {
	INACTIVE,  # 未激活
	WAITING,   # 等待中（即将刷新）
	ALIVE,     # 存活中
	DYING      # 濒死
}

# 世界Boss数据库
var boss_database: Dictionary = {
	"azure_dragon": {
		"name": "青龙",
		"level": 50,
		"hp": 100000,
		"attack": 200,
		"defense": 100,
		"location": "东方云海",
		"spawn_time": [12, 0],  # 每天12:00
		"duration": 1800,  # 存在30分钟
		"description": "四圣兽之一，掌管东方",
		"skills": ["龙息", "雷击", "龙卷风"],
		"rewards": {
			"exp": 5000,
			"gold": 5000,
			"items": ["龙鳞×5", "龙血×3", "神级装备"]
		},
		"min_participants": 10
	},
	"vermillion_bird": {
		"name": "朱雀",
		"level": 50,
		"hp": 80000,
		"attack": 250,
		"defense": 80,
		"location": "南方火山",
		"spawn_time": [18, 0],  # 每天18:00
		"duration": 1800,
		"description": "四圣兽之一，掌管南方",
		"skills": ["凤凰火", "浴火", "烈焰风暴"],
		"rewards": {
			"exp": 5000,
			"gold": 5000,
			"items": ["凤羽×5", "凤凰血×3", "神级装备"]
		},
		"min_participants": 10
	},
	"white_tiger": {
		"name": "白虎",
		"level": 50,
		"hp": 90000,
		"attack": 280,
		"defense": 90,
		"location": "西方荒原",
		"spawn_time": [20, 0],  # 每天20:00
		"duration": 1800,
		"description": "四圣兽之一，掌管西方",
		"skills": ["虎啸", "风刃", "撕裂"],
		"rewards": {
			"exp": 5000,
			"gold": 5000,
			"items": ["虎牙×5", "虎骨×3", "神级装备"]
		},
		"min_participants": 10
	},
	"black_tortoise": {
		"name": "玄武",
		"level": 50,
		"hp": 150000,
		"attack": 150,
		"defense": 150,
		"location": "北方冰原",
		"spawn_time": [22, 0],  # 每天22:00
		"duration": 1800,
		"description": "四圣兽之一，掌管北方",
		"skills": ["水遁", "冰冻", "绝对防御"],
		"rewards": {
			"exp": 5000,
			"gold": 5000,
			"items": ["龟甲×5", "玄冰×3", "神级装备"]
		},
		"min_participants": 10
	}
}

# 当前状态
var current_boss: String = ""
var current_boss_hp: int = 0
var current_boss_max_hp: int = 0
var boss_state: int = BossState.INACTIVE
var spawn_timer: float = 0.0
var alive_timer: float = 0.0

# 伤害排行榜
var damage_ranking: Dictionary = {}  # player_id: damage
var participant_count: int = 0

# 奖励发放
var reward_distributed: bool = false

func _ready():
	check_next_boss()

func _process(delta):
	# 更新倒计时
	if boss_state == BossState.WAITING:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_world_boss()
	
	elif boss_state == BossState.ALIVE:
		alive_timer -= delta
		if alive_timer <= 0:
			boss_escape()

# 检查下一个Boss
func check_next_boss():
	if boss_state == BossState.INACTIVE:
		# 计算下一个Boss的刷新时间
		var current_time = Time.get_time_dict_from_system()
		var next_spawn = null
		var min_wait = 86400  # 24小时
		
		for boss_id in boss_database.keys():
			var boss = boss_database[boss_id]
			var spawn_hour = boss.spawn_time[0]
			var spawn_minute = boss.spawn_time[1]
			
			var spawn_seconds = spawn_hour * 3600 + spawn_minute * 60
			var current_seconds = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
			
			var wait_time = spawn_seconds - current_seconds
			if wait_time < 0:
				wait_time += 86400  # 加24小时
			
			if wait_time < min_wait:
				min_wait = wait_time
				next_spawn = boss_id
		
		if next_spawn:
			current_boss = next_spawn
			spawn_timer = min_wait
			boss_state = BossState.WAITING
			print("下一个世界Boss:", boss_database[next_spawn].name, ", 等待", min_wait, "秒")

# 刷新世界Boss
func spawn_world_boss():
	if current_boss.is_empty():
		return
	
	var boss_data = boss_database[current_boss]
	current_boss_hp = boss_data.hp
	current_boss_max_hp = boss_data.hp
	alive_timer = boss_data.duration
	boss_state = BossState.ALIVE
	damage_ranking.clear()
	participant_count = 0
	reward_distributed = false
	
	emit_signal("world_boss_spawn", boss_data.name, boss_data.location)
	print("世界Boss刷新：", boss_data.name, "在", boss_data.location)
	
	# 发送全服公告（通过邮件）
	broadcast_boss_spawn(boss_data.name, boss_data.location)

# Boss逃跑
func boss_escape():
	if boss_state == BossState.ALIVE:
		boss_state = BossState.INACTIVE
		emit_signal("world_boss_end")
		print("世界Boss逃跑：", boss_database[current_boss].name)
		
		# 重置
		damage_ranking.clear()
		current_boss = ""
		
		# 计算下一个Boss
		check_next_boss()

# 记录伤害
func record_damage(player_id: String, player_name: String, damage: int) -> Dictionary:
	if boss_state != BossState.ALIVE:
		return {"success": false, "message": "Boss未激活"}
	
	if current_boss_hp <= 0:
		return {"success": false, "message": "Boss已死亡"}
	
	# 记录伤害
	if not damage_ranking.has(player_id):
		damage_ranking[player_id] = {
			"name": player_name,
			"damage": 0
		}
		participant_count += 1
	
	damage_ranking[player_id].damage += damage
	
	# 扣除Boss血量
	current_boss_hp = max(0, current_boss_hp - damage)
	
	# 检查Boss死亡
	if current_boss_hp <= 0:
		boss_died()
	
	return {
		"success": true,
		"current_hp": current_boss_hp,
		"max_hp": current_boss_max_hp,
		"your_rank": get_player_rank(player_id)
	}

# Boss死亡
func boss_died():
	if boss_state == BossState.ALIVE and current_boss_hp <= 0:
		boss_state = BossState.DYING
		
		# 生成排行榜
		var ranking = get_damage_ranking()
		
		emit_signal("world_boss_died", boss_database[current_boss].name, ranking)
		print("世界Boss被击杀：", boss_database[current_boss].name)
		
		# 发放奖励
		distribute_rewards(ranking)
		
		# 延迟重置
		await get_tree().create_timer(10.0).timeout
		
		boss_state = BossState.INACTIVE
		current_boss = ""
		
		check_next_boss()

# 发放奖励
func distribute_rewards(ranking: Array):
	if reward_distributed:
		return
	
	reward_distributed = true
	
	var boss_data = boss_database[current_boss]
	
	for i in range(min(ranking.size(), 20)):  # 前20名
		var player_id = ranking[i].player_id
		var rank = i + 1
		var reward_multiplier = max(0.1, 1.0 - rank * 0.05)  # 排名越靠前，奖励越高
		
		var exp_reward = int(boss_data.rewards.exp * reward_multiplier)
		var gold_reward = int(boss_data.rewards.gold * reward_multiplier)
		
		# 前三名特殊奖励
		var items = []
		if rank == 1:
			items = boss_data.rewards.items.duplicate()
		elif rank <= 5:
			items = boss_data.rewards.items.slice(0, 2)
		else:
			items = [boss_data.rewards.items[0]]
		
		# 发送奖励（这里应该调用邮件系统）
		var title = "世界Boss奖励 - " + boss_data.name
		var content = "恭喜您在击杀%s的战斗中排名第%d，获得奖励！" % [boss_data.name, rank]
		var reward = {"exp": exp_reward, "gold": gold_reward, "items": items}
		
		print("发送奖励给", ranking[i].name, ":", reward)

# 获取排行榜
func get_damage_ranking() -> Array:
	var sorted = []
	
	for player_id in damage_ranking.keys():
		var data = damage_ranking[player_id]
		sorted.append({
			"player_id": player_id,
			"name": data.name,
			"damage": data.damage
		})
	
	# 按伤害排序
	sorted.sort_custom(func(a, b): return a.damage > b.damage)
	
	return sorted

# 获取玩家排名
func get_player_rank(player_id: String) -> int:
	var ranking = get_damage_ranking()
	for i in range(ranking.size()):
		if ranking[i].player_id == player_id:
			return i + 1
	return 0

# 广播Boss刷新（通过邮件系统）
func broadcast_boss_spawn(boss_name: String, location: String):
	# 这里应该调用邮件系统广播
	print("全服广播：", boss_name, "在", location, "刷新了！")

# 获取当前Boss状态
func get_boss_status() -> Dictionary:
	if current_boss.is_empty():
		return {
			"active": false,
			"next_spawn": spawn_timer
		}
	
	var boss_data = boss_database[current_boss]
	
	return {
		"active": boss_state == BossState.ALIVE,
		"name": boss_data.name,
		"location": boss_data.location,
		"hp_percent": float(current_boss_hp) / current_boss_max_hp * 100,
		"hp": current_boss_hp,
		"max_hp": current_boss_max_hp,
		"time_left": alive_timer if boss_state == BossState.ALIVE else spawn_timer,
		"participants": participant_count,
		"state": boss_state
	}

# 获取所有Boss刷新时间
func get_all_spawn_times() -> Array:
	var times = []
	
	for boss_id in boss_database.keys():
		var boss = boss_database[boss_id]
		times.append({
			"id": boss_id,
			"name": boss.name,
			"location": boss.location,
			"spawn_time": boss.spawn_time
		})
	
	return times
