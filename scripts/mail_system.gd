extends Node

class_name MailSystem

# 邮件系统

signal mail_received(mail_id: String)
signal mail_read(mail_id: String)
signal mail_deleted(mail_id: String)

# 邮件类型
enum MailType {
	SYSTEM,    # 系统邮件
	REWARD,    # 奖励邮件
	TRADE,     # 交易邮件
	FRIEND,    # 好友邮件
	GUILD,     # 行会邮件
	ANNOUCE    # 公告邮件
}

# 邮件
var mails: Array = []  # Array of Dictionary
var mail_counter: int = 0

func _ready():
	load_mails()

# 发送邮件
func send_mail(receiver_id: String, sender: String, title: String, content: String, 
			   attachments: Dictionary = {}, mail_type: int = MailType.SYSTEM) -> String:
	mail_counter += 1
	var mail_id = "mail_" + str(mail_counter)
	
	var mail = {
		"id": mail_id,
		"receiver_id": receiver_id,
		"sender": sender,
		"sender_id": "",
		"title": title,
		"content": content,
		"attachments": attachments,  # {"gold": 100, "items": ["item1×1"]}
		"type": mail_type,
		"read": false,
		"claimed": false,
		"timestamp": Time.get_unix_time_from_system(),
		"expire_time": Time.get_unix_time_from_system() + 30 * 24 * 3600  # 30天过期
	}
	
	mails.append(mail)
	emit_signal("mail_received", mail_id)
	
	print("邮件发送：", title, " -> ", receiver_id)
	save_mails()
	
	return mail_id

# 发送系统邮件（带奖励）
func send_reward_mail(receiver_id: String, title: String, content: String, reward: Dictionary) -> String:
	return send_mail(receiver_id, "系统", title, content, reward, MailType.REWARD)

# 读取邮件
func read_mail(mail_id: String) -> Dictionary:
	for mail in mails:
		if mail.id == mail_id:
			if not mail.read:
				mail.read = true
				emit_signal("mail_read", mail_id)
				save_mails()
			return mail
	
	return {}

# 领取附件
func claim_attachments(mail_id: String) -> Dictionary:
	for mail in mails:
		if mail.id == mail_id:
			if mail.claimed:
				return {"success": false, "message": "已领取"}
			
			var attachments = mail.attachments
			if attachments.is_empty():
				return {"success": false, "message": "无附件"}
			
			mail.claimed = true
			save_mails()
			
			return {
				"success": true,
				"attachments": attachments,
				"message": "领取成功"
			}
	
	return {"success": false, "message": "邮件不存在"}

# 删除邮件
func delete_mail(mail_id: String) -> bool:
	for i in range(mails.size()):
		if mails[i].id == mail_id:
			mails.remove_at(i)
			emit_signal("mail_deleted", mail_id)
			save_mails()
			return true
	return false

# 获取玩家邮件
func get_player_mails(receiver_id: String) -> Array:
	var result = []
	for mail in mails:
		if mail.receiver_id == receiver_id:
			result.append(mail)
	return result

# 获取未读邮件数
func get_unread_count(receiver_id: String) -> int:
	var count = 0
	for mail in mails:
		if mail.receiver_id == receiver_id and not mail.read:
			count += 1
	return count

# 清理过期邮件
func cleanup_expired_mails():
	var current_time = Time.get_unix_time_from_system()
	var expired = []
	
	for mail in mails:
		if mail.expire_time < current_time:
			expired.append(mail.id)
	
	for mail_id in expired:
		delete_mail(mail_id)
	
	if expired.size() > 0:
		print("清理过期邮件：", expired.size(), "封")

# 批量发送（GM用）
func broadcast_mail(sender: String, title: String, content: String, reward: Dictionary = {}) -> int:
	var count = 0
	# 这里应该获取所有玩家ID，这里简化为发送给系统公告
	var mail_id = send_mail("all", sender, title, content, reward, MailType.ANNOUCE)
	if mail_id:
		count = 1
	return count

# 获取邮件摘要
func get_mail_summary(receiver_id: String) -> Dictionary:
	var player_mails = get_player_mails(receiver_id)
	var unread = 0
	var unclaimed = 0
	
	for mail in player_mails:
		if not mail.read:
			unread += 1
		if not mail.claimed and not mail.attachments.is_empty():
			unclaimed += 1
	
	return {
		"total": player_mails.size(),
		"unread": unread,
		"unclaimed": unclaimed
	}

# 保存/加载
func save_mails():
	var config = ConfigFile.new()
	config.set_value("mail", "counter", mail_counter)
	config.set_value("mail", "mails", mails)
	config.save("user://mail.cfg")

func load_mails():
	if FileAccess.file_exists("user://mail.cfg"):
		var config = ConfigFile.new()
		if config.load("user://mail.cfg") == OK:
			mail_counter = config.get_value("mail", "counter", 0)
			mails = config.get_value("mail", "mails", [])
	
	# 定期清理过期邮件
	cleanup_expired_mails()
