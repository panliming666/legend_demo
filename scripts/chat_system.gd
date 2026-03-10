extends Node

class_name ChatSystem

# 聊天系统

signal message_sent(channel: String, message: String)
signal message_received(channel: String, sender: String, message: String)

# 聊天频道
enum ChatChannel {
	WORLD,     # 世界
	GUILD,     # 行会
	TEAM,      # 队伍
	PRIVATE,   # 私聊
	SYSTEM     # 系统
}

# 消息历史
var message_history: Dictionary = {
	ChatChannel.WORLD: [],
	ChatChannel.GUILD: [],
	ChatChannel.TEAM: [],
	ChatChannel.PRIVATE: []
}

var max_history: int = 100

func _ready():
	pass

# 发送消息
func send_message(channel: int, sender_id: String, sender_name: String, message: String) -> bool:
	if message.is_empty():
		return false
	
	# 敏感词过滤
	message = filter_message(message)
	
	var chat_message = {
		"sender_id": sender_id,
		"sender_name": sender_name,
		"message": message,
		"timestamp": Time.get_unix_time_from_system(),
		"channel": channel
	}
	
	# 添加到历史
	if message_history.has(channel):
		message_history[channel].append(chat_message)
		
		# 限制历史数量
		if message_history[channel].size() > max_history:
			message_history[channel].remove_at(0)
	
	emit_signal("message_sent", ChatChannel.keys()[channel], message)
	
	return true

# 获取历史消息
func get_history(channel: int, count: int = 20) -> Array:
	if not message_history.has(channel):
		return []
	
	var history = message_history[channel]
	return history.slice(max(0, history.size() - count), history.size())

# 过滤敏感词
func filter_message(message: String) -> String:
	var sensitive_words = ["fuck", "shit", "垃圾", "傻逼"]  # 简化示例
	var filtered = message
	
	for word in sensitive_words:
		filtered = filtered.replace(word, "**")
	
	return filtered

# 便捷方法
func send_world_message(sender_id: String, sender_name: String, message: String) -> bool:
	return send_message(ChatChannel.WORLD, sender_id, sender_name, message)

func send_guild_message(sender_id: String, sender_name: String, message: String) -> bool:
	return send_message(ChatChannel.GUILD, sender_id, sender_name, message)

func send_team_message(sender_id: String, sender_name: String, message: String) -> bool:
	return send_message(ChatChannel.TEAM, sender_id, sender_name, message)
