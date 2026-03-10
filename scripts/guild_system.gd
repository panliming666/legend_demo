extends Node

class_name GuildSystem

# 行会系统 - 玩家组织管理

signal guild_updated(guild_data: Dictionary)
signal member_joined(member_name: String)
signal member_left(member_name: String)

# 行会数据
var guild_data: Dictionary = {
	"name": "冒险者行会",
	"level": 1,
	"exp": 0,
	"max_members": 10,
	"members": [],
	"rank": "member",
	"contribution": 0,
	"treasury": 0  # 行会资金
}

# 行会等级经验需求
var level_exp_requirements: Array = [
	0,      # 1级
	1000,   # 2级
	3000,   # 3级
	6000,   # 4级
	10000,  # 5级
	20000,  # 6级
	35000,  # 7级
	55000,  # 8级
	80000,  # 9级
	120000  # 10级
]

# 成员职位
enum MemberRank {
	LEADER = 3,      # 会长
	OFFICER = 2,     # 官员
	MEMBER = 1       # 普通成员
}

# 行会技能
var guild_skills: Dictionary = {
	"treasure_bonus": {
		"name": "财富祝福",
		"level": 1,
		"max_level": 5,
		"effect": "增加金币掉落10%",
		"cost": 500
	},
	"exp_bonus": {
		"name": "经验加成",
		"level": 1,
		"max_level": 5,
		"effect": "增加经验获取10%",
		"cost": 500
	},
	"defense_bonus": {
		"name": "行会守护",
		"level": 1,
		"max_level": 5,
		"effect": "增加成员防御5%",
		"cost": 800
	},
	"attack_bonus": {
		"name": "战争号召",
		"level": 1,
		"max_level": 5,
		"effect": "增加成员攻击5%",
		"cost": 800
	}
}

func _ready():
	load_guild_data()

func load_guild_data():
	# 从存档加载行会数据
	var save_manager = get_tree().current_scene.get_node_or_null("SaveManager")
	if save_manager and save_manager.current_save.has("guild"):
		guild_data = save_manager.current_save["guild"]
	emit_signal("guild_updated", guild_data)

func save_guild_data():
	# 保存行会数据
	var save_manager = get_tree().current_scene.get_node_or_null("SaveManager")
	if save_manager:
		save_manager.current_save["guild"] = guild_data
		print("行会数据已保存")

func create_guild(guild_name: String, leader_name: String) -> bool:
	if guild_data.members.size() > 0:
		print("玩家已有行会")
		return false
	
	guild_data = {
		"name": guild_name,
		"level": 1,
		"exp": 0,
		"max_members": 10,
		"members": [{
			"name": leader_name,
			"rank": MemberRank.LEADER,
			"contribution": 0,
			"join_time": Time.get_unix_time_from_system()
		}],
		"treasury": 0
	}
	
	emit_signal("guild_updated", guild_data)
	save_guild_data()
	print("行会创建成功: ", guild_name)
	return true

func join_guild(player_name: String) -> bool:
	if guild_data.members.size() >= guild_data.max_members:
		print("行会已满")
		return false
	
	# 检查是否已是成员
	for member in guild_data.members:
		if member.name == player_name:
			print("已是行会成员")
			return false
	
	guild_data.members.append({
		"name": player_name,
		"rank": MemberRank.MEMBER,
		"contribution": 0,
		"join_time": Time.get_unix_time_from_system()
	})
	
	emit_signal("member_joined", player_name)
	emit_signal("guild_updated", guild_data)
	save_guild_data()
	print(player_name, "加入了行会")
	return true

func leave_guild(player_name: String) -> bool:
	for i in range(guild_data.members.size()):
		if guild_data.members[i].name == player_name:
			var rank = guild_data.members[i].rank
			guild_data.members.remove_at(i)
			
			emit_signal("member_left", player_name)
			emit_signal("guild_updated", guild_data)
			save_guild_data()
			print(player_name, "离开了行会")
			return true
	
	return false

func kick_member(leader_name: String, target_name: String) -> bool:
	var leader = get_member(leader_name)
	if leader == null or leader.rank != MemberRank.LEADER:
		print("只有会长可以踢人")
		return false
	
	return leave_guild(target_name)

func add_exp(amount: int) -> bool:
	guild_data.exp += amount
	var old_level = guild_data.level
	
	# 检查升级
	while guild_data.level < level_exp_requirements.size():
		var next_level_exp = level_exp_requirements[guild_data.level]
		if guild_data.exp >= next_level_exp:
			guild_data.level += 1
			guild_data.max_members += 5
			print("行会升级到", guild_data.level, "级")
		else:
			break
	
	emit_signal("guild_updated", guild_data)
	return true

func add_treasury(amount: int):
	guild_data.treasury += amount
	emit_signal("guild_updated", guild_data)
	save_guild_data()

func get_member(player_name: String) -> Dictionary:
	for member in guild_data.members:
		if member.name == player_name:
			return member
	return {}

func get_guild_bonus(bonus_type: String) -> float:
	var level = guild_skills.get(bonus_type, {}).get("level", 1)
	
	match bonus_type:
		"treasure_bonus":
			return level * 0.1  # 10% per level
		"exp_bonus":
			return level * 0.1
		"defense_bonus":
			return level * 0.05
		"attack_bonus":
			return level * 0.05
	return 0.0

func upgrade_skill(skill_name: String) -> bool:
	var skill = guild_skills.get(skill_name)
	if skill == null:
		return false
	
	if skill.level >= skill.max_level:
		print("技能已满级")
		return false
	
	if guild_data.treasury < skill.cost:
		print("行会资金不足")
		return false
	
	guild_data.treasury -= skill.cost
	skill.level += 1
	skill.cost = int(skill.cost * 1.5)
	
	emit_signal("guild_updated", guild_data)
	save_guild_data()
	print("技能升级: ", skill.name, " -> ", skill.level)
	return true

func get_online_members() -> Array:
	# 获取当前在线的成员
	var online = []
	var all_players = get_tree().get_nodes_in_group("players")
	
	for member in guild_data.members:
		for player in all_players:
			if player.name == member.name:
				online.append(member)
				break
	
	return online

func get_guild_info() -> Dictionary:
	return {
		"name": guild_data.name,
		"level": guild_data.level,
		"exp": guild_data.exp,
		"exp_required": _get_next_level_exp(),
		"members_count": guild_data.members.size(),
		"max_members": guild_data.max_members,
		"treasury": guild_data.treasury,
		"skills": guild_skills.duplicate(true)
	}

func _get_next_level_exp() -> int:
	if guild_data.level >= level_exp_requirements.size():
		return level_exp_requirements[-1]
	return level_exp_requirements[guild_data.level]

func is_leader(player_name: String) -> bool:
	var member = get_member(player_name)
	return member.get("rank", 0) == MemberRank.LEADER

func is_officer(player_name: String) -> bool:
	var member = get_member(player_name)
	return member.get("rank", 0) >= MemberRank.OFFICER
