extends Node

class_name FriendSystem

# 好友系统

signal friend_added(player_id: String, friend_name: String)
signal friend_removed(player_id: String, friend_name: String)
signal friend_online_changed(player_id: String, is_online: bool)
signal private_message_received(sender_id: String, sender_name: String, message: String)

# 好友状态
enum FriendStatus {
	OFFLINE,    # 离线
	ONLINE,     # 在线
	BUSY,       # 忙碌
	AWAY        # 离开
}

# 好友数据
var friends: Dictionary = {}  # player_id: friend_data
var friend_limit: int = 100
var block_list: Array = []  # 黑名单

# 私聊记录
var private_messages: Dictionary = {}  # friend_id: Array of messages

func _ready():
	pass

# 添加好友
func add_friend(player_id: String, player_name: String) -> Dictionary:
	if friends.size() >= friend_limit:
		return {"success": false, "message": "好友数量已达上限"}
	
	if friends.has(player_id):
		return {"success": false, "message": "已经是好友"}
	
	if player_id in block_list:
		return {"success": false, "message": "对方在黑名单中"}
	
	# 添加好友
	friends[player_id] = {
		"id": player_id,
		"name": player_name,
		"status": FriendStatus.OFFLINE,
		"last_online": 0,
		"remarks": "",  # 备注
		"added_time": Time.get_unix_time_from_system()
	}
	
	emit_signal("friend_added", player_id, player_name)
	save_friends()
	
	return {"success": true, "message": "添加好友成功"}

# 删除好友
func remove_friend(player_id: String) -> Dictionary:
	if not friends.has(player_id):
		return {"success": false, "message": "不是好友"}
	
	var friend_name = friends[player_id].name
	friends.erase(player_id)
	
	# 删除聊天记录
	private_messages.erase(player_id)
	
	emit_signal("friend_removed", player_id, friend_name)
	save_friends()
	
	return {"success": true, "message": "删除好友成功"}

# 更新好友状态
func update_friend_status(player_id: String, status: int):
	if not friends.has(player_id):
		return
	
	friends[player_id].status = status
	
	if status == FriendStatus.OFFLINE:
		friends[player_id].last_online = Time.get_unix_time_from_system()
	
	emit_signal("friend_online_changed", player_id, status == FriendStatus.ONLINE)

# 发送私聊
func send_private_message(receiver_id: String, message: String) -> Dictionary:
	if not friends.has(receiver_id):
		return {"success": false, "message": "不是好友"}
	
	if message.is_empty():
		return {"success": false, "message": "消息不能为空"}
	
	# 添加到记录
	if not private_messages.has(receiver_id):
		private_messages[receiver_id] = []
	
	private_messages[receiver_id].append({
		"sender": "me",
		"message": message,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# 这里应该通过网络发送给对方
	print("发送私聊给", receiver_id, ":", message)
	
	return {"success": true, "message": "发送成功"}

# 接收私聊
func receive_private_message(sender_id: String, sender_name: String, message: String):
	if not private_messages.has(sender_id):
		private_messages[sender_id] = []
	
	private_messages[sender_id].append({
		"sender": sender_name,
		"message": message,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	emit_signal("private_message_received", sender_id, sender_name, message)

# 获取聊天记录
func get_chat_history(friend_id: String, limit: int = 50) -> Array:
	if not private_messages.has(friend_id):
		return []
	
	var history = private_messages[friend_id]
	return history.slice(max(0, history.size() - limit), history.size())

# 获取好友列表
func get_friend_list() -> Array:
	var result = []
	
	for friend_id in friends.keys():
		var friend = friends[friend_id]
		result.append({
			"id": friend.id,
			"name": friend.name,
			"status": friend.status,
			"remarks": friend.remarks,
			"last_online": friend.last_online
		})
	
	# 排序：在线优先，然后按名称
	result.sort_custom(func(a, b):
		if a.status != b.status:
			return a.status < b.status
		return a.name < b.name
	)
	
	return result

# 获取在线好友数量
func get_online_count() -> int:
	var count = 0
	for friend_id in friends.keys():
		if friends[friend_id].status != FriendStatus.OFFLINE:
			count += 1
	return count

# 搜索好友
func search_friend(keyword: String) -> Array:
	var result = []
	
	keyword = keyword.to_lower()
	
	for friend_id in friends.keys():
		var friend = friends[friend_id]
		if friend.name.to_lower().contains(keyword) or friend.remarks.to_lower().contains(keyword):
			result.append({
				"id": friend.id,
				"name": friend.name,
				"status": friend.status
			})
	
	return result

# 设置备注
func set_remarks(friend_id: String, remarks: String) -> bool:
	if not friends.has(friend_id):
		return false
	
	friends[friend_id].remarks = remarks
	save_friends()
	return true

# 加入黑名单
func add_to_block_list(player_id: String):
	if player_id in block_list:
		return
	
	block_list.append(player_id)
	
	# 如果是好友，删除好友
	if friends.has(player_id):
		remove_friend(player_id)
	
	save_friends()

# 移出黑名单
func remove_from_block_list(player_id: String):
	if player_id in block_list:
		block_list.erase(player_id)
		save_friends()

# 检查是否在黑名单
func is_blocked(player_id: String) -> bool:
	return player_id in block_list

# 获取好友信息
func get_friend_info(friend_id: String) -> Dictionary:
	return friends.get(friend_id, {})

# 保存/加载
func save_friends():
	var config = ConfigFile.new()
	var friends_data = {}
	for friend_id in friends.keys():
		friends_data[friend_id] = friends[friend_id]
	
	config.set_value("friends", "list", friends_data)
	config.set_value("friends", "block_list", block_list)
	config.save("user://friends.cfg")

func load_friends():
	if FileAccess.file_exists("user://friends.cfg"):
		var config = ConfigFile.new()
		if config.load("user://friends.cfg") == OK:
			friends = config.get_value("friends", "list", {})
			block_list = config.get_value("friends", "block_list", [])
