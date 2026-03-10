extends Node

# 游戏主控制器

# 单例模式
static var instance: GameController

var player_name: String = "修仙者"
var player_id: String = ""
var player_level: int = 1
var player_realm: int = 0  # 境界
var player_class: int = 0  # 职业类型
var gold: int = 1000
var diamond: int = 0

# 系统实例
var equipment_system: Node
var alchemy_system: Node
var spirit_pet_system: Node
var mount_system: Node
var refining_system: Node
var dungeon_system: Node
var achievement_system: Node
var mail_system: Node
var skill_tree_system: Node
var auction_system: Node
var ranking_system: Node
var activity_system: Node
var quest_guide_system: Node
var friend_system: Node
var world_boss_system: Node
var guild_system: Node
var fashion_system: Node
var title_system: Node
var vip_system: Node
var sign_system: Node

func _ready():
	instance = self
	initialize_systems()

func initialize_systems():
	# 初始化所有系统
	equipment_system = load("res://scripts/equipment_system.gd").new()
	alchemy_system = load("res://scripts/alchemy_system.gd").new()
	spirit_pet_system = load("res://scripts/spirit_pet_system.gd").new()
	mount_system = load("res://scripts/mount_system.gd").new()
	refining_system = load("res://scripts/refining_system.gd").new()
	dungeon_system = load("res://scripts/dungeon_system.gd").new()
	achievement_system = load("res://scripts/achievement_system.gd").new()
	mail_system = load("res://scripts/mail_system.gd").new()
	skill_tree_system = load("res://scripts/skill_tree_system.gd").new()
	auction_system = load("res://scripts/auction_system.gd").new()
	ranking_system = load("res://scripts/ranking_system.gd").new()
	activity_system = load("res://scripts/activity_system.gd").new()
	quest_guide_system = load("res://scripts/quest_guide_system.gd").new()
	friend_system = load("res://scripts/friend_system.gd").new()
	world_boss_system = load("res://scripts/world_boss_system.gd").new()
	fashion_system = load("res://scripts/fashion_system.gd").new()
	title_system = load("res://scripts/title_system.gd").new()
	vip_system = load("res://scripts/vip_system.gd").new()
	sign_system = load("res://scripts/sign_system.gd").new()
	
	add_child(equipment_system)
	add_child(alchemy_system)
	add_child(spirit_pet_system)
	add_child(mount_system)
	add_child(refining_system)
	add_child(dungeon_system)
	add_child(achievement_system)
	add_child(mail_system)
	add_child(skill_tree_system)
	add_child(auction_system)
	add_child(ranking_system)
	add_child(activity_system)
	add_child(quest_guide_system)
	add_child(friend_system)
	add_child(world_boss_system)
	add_child(fashion_system)
	add_child(title_system)
	add_child(vip_system)
	add_child(sign_system)
	
	print("游戏系统初始化完成")

# 获取玩家战力
func get_combat_power() -> int:
	var cp = 0
	
	# 基础
	cp += player_level * 10
	
	# 装备
	var equipment_bonus = equipment_system.get_equipment_stats()
	cp += equipment_bonus.get("physical_attack", 0) * 2
	cp += equipment_bonus.get("magic_attack", 0) * 2
	
	# 灵宠
	cp += spirit_pet_system.get_all_pets().size() * 50
	
	# 坐骑
	cp += mount_system.get_all_mounts().size() * 30
	
	# VIP加成
	var vip_bonus = vip_system.get_vip_bonus()
	cp = int(cp * (1 + vip_bonus.get("exp_bonus", 0)))
	
	return cp

# 获得经验
func gain_exp(amount: int):
	var exp_bonus = vip_system.get_vip_bonus()
	var final_exp = int(amount * (1 + exp_bonus.get("exp_bonus", 0)))
	
	player_level += 1  # 简化：每级需要1点经验
	
	# 更新排行榜
	ranking_system.update_level_ranking(player_id, player_name, player_level)
	ranking_system.update_combat_ranking(player_id, player_name, get_combat_power())
	ranking_system.update_wealth_ranking(player_id, player_name, gold)

# 获得金币
func gain_gold(amount: int):
	gold += amount
	ranking_system.update_wealth_ranking(player_id, player_name, gold)

# 保存游戏
func save_game():
	# 保存所有系统
	equipment_system.save_equipment()
	alchemy_system.save_inventory()
	spirit_pet_system.save_pets()
	mount_system.save_mounts()
	refining_system.save_refining()
	dungeon_system.save_records()
	achievement_system.save_achievements()
	mail_system.save_mails()
	skill_tree_system.save_skills()
	auction_system.save_auction()
	ranking_system.save_rankings()
	activity_system.save_activities()
	quest_guide_system.save_quests()
	friend_system.save_friends()
	fashion_system.save_fashions()
	title_system.save_titles()
	vip_system.save_vip()
	sign_system.save_sign()
	
	print("游戏保存完成")

# 加载游戏
func load_game():
	equipment_system.load_equipment()
	alchemy_system.load_inventory()
	spirit_pet_system.load_pets()
	mount_system.load_mounts()
	refining_system.load_refining()
	dungeon_system.load_records()
	achievement_system.load_achievements()
	mail_system.load_mails()
	skill_tree_system.load_skills()
	auction_system.load_auction()
	ranking_system.load_rankings()
	activity_system.load_activities()
	quest_guide_system.load_quests()
	friend_system.load_friends()
	fashion_system.load_fashions()
	title_system.load_titles()
	vip_system.load_vip()
	sign_system.load_sign()
	
	print("游戏加载完成")
