extends Node

class_name AuctionSystem

# 拍卖行系统

signal item_listed(item_id: String, price: int)
signal item_bought(item_id: String, buyer: String)
signal item_expired(item_id: String)

# 拍卖物品
class AuctionItem:
	var id: String
	var seller_id: String
	var seller_name: String
	var item_name: String
	var item_data: Dictionary
	var start_price: int
	var buyout_price: int
	var current_bid: int
	var current_bidder: String
	var listed_time: int
	var expire_time: int
	var status: String  # "active", "sold", "expired"

var auction_items: Array = []  # Array of AuctionItem
var item_counter: int = 0

# 手续费率
const LISTING_FEE_RATE = 0.05  # 上架费5%
const TRANSACTION_FEE_RATE = 0.10  # 成交费10%

# 上架时长（秒）
const LISTING_DURATION = 48 * 3600  # 48小时

func _ready():
	load_auction()

# 上架物品
func list_item(seller_id: String, seller_name: String, item_data: Dictionary, 
			   start_price: int, buyout_price: int) -> Dictionary:
	if start_price < 100:
		return {"success": false, "message": "起拍价不能低于100金币"}
	
	if buyout_price < start_price:
		return {"success": false, "message": "一口价不能低于起拍价"}
	
	# 计算上架费
	var listing_fee = int(start_price * LISTING_FEE_RATE)
	
	item_counter += 1
	var item_id = "auc_" + str(item_counter)
	
	var auction_item = AuctionItem.new()
	auction_item.id = item_id
	auction_item.seller_id = seller_id
	auction_item.seller_name = seller_name
	auction_item.item_name = item_data.get("name", "未知物品")
	auction_item.item_data = item_data
	auction_item.start_price = start_price
	auction_item.buyout_price = buyout_price
	auction_item.current_bid = start_price
	auction_item.current_bidder = ""
	auction_item.listed_time = Time.get_unix_time_from_system()
	auction_item.expire_time = auction_item.listed_time + LISTING_DURATION
	auction_item.status = "active"
	
	auction_items.append(auction_item)
	
	emit_signal("item_listed", item_id, start_price)
	save_auction()
	
	return {
		"success": true,
		"item_id": item_id,
		"listing_fee": listing_fee,
		"message": "上架成功，扣除手续费%d金币" % listing_fee
	}

# 出价
func place_bid(item_id: String, bidder_id: String, bid: int) -> Dictionary:
	var item = get_item_by_id(item_id)
	if item == null:
		return {"success": false, "message": "物品不存在"}
	
	if item.status != "active":
		return {"success": false, "message": "拍卖已结束"}
	
	if bid <= item.current_bid:
		return {"success": false, "message": "出价必须高于当前价格"}
	
	if bid > item.buyout_price:
		return {"success": false, "message": "出价超过一口价"}
	
	# 检查是否达到一口价
	if bid >= item.buyout_price:
		return buy_item(item_id, bidder_id)
	
	item.current_bid = bid
	item.current_bidder = bidder_id
	save_auction()
	
	return {
		"success": true,
		"current_bid": bid,
		"message": "出价成功"
	}

# 一口价购买
func buy_item(item_id: String, buyer_id: String) -> Dictionary:
	var item = get_item_by_id(item_id)
	if item == null:
		return {"success": false, "message": "物品不存在"}
	
	if item.status != "active":
		return {"success": false, "message": "拍卖已结束"}
	
	# 交易
	var final_price = item.current_bidder.is_empty() ? item.buyout_price : item.current_bid
	
	# 计算卖家实得
	var seller_receive = int(final_price * (1 - TRANSACTION_FEE_RATE))
	var fee = final_price - seller_receive
	
	# 结算（这里应该调用货币系统）
	print("交易完成：", item.item_name, "价格:", final_price)
	print("卖家", item.seller_name, "获得:", seller_receive)
	print("手续费:", fee)
	
	item.status = "sold"
	item.current_bid = final_price
	item.current_bidder = buyer_id
	
	emit_signal("item_bought", item_id, buyer_id)
	save_auction()
	
	return {
		"success": true,
		"final_price": final_price,
		"item": item.item_data,
		"message": "购买成功"
	}

# 下架
func delist_item(item_id: String, seller_id: String) -> Dictionary:
	var item = get_item_by_id(item_id)
	if item == null:
		return {"success": false, "message": "物品不存在"}
	
	if item.seller_id != seller_id:
		return {"success": false, "message": "不是您的物品"}
	
	if item.status != "active":
		return {"success": false, "message": "拍卖已结束"}
	
	if not item.current_bidder.is_empty():
		return {"success": false, "message": "已有出价，无法下架"}
	
	item.status = "expired"
	save_auction()
	
	return {
		"success": true,
		"message": "下架成功"
	}

# 获取物品
func get_item_by_id(item_id: String) -> AuctionItem:
	for item in auction_items:
		if item.id == item_id:
			return item
	return null

# 获取拍卖列表
func get_auction_list(filters: Dictionary = {}) -> Array:
	var result = []
	var current_time = Time.get_unix_time_from_system()
	
	for item in auction_items:
		# 检查过期
		if item.status == "active" and item.expire_time < current_time:
			item.status = "expired"
			emit_signal("item_expired", item.id)
			continue
		
		# 过滤
		if filters.has("status") and item.status != filters.status:
			continue
		
		if filters.has("seller") and item.seller_id != filters.seller:
			continue
		
		if filters.has("min_price") and item.start_price < filters.min_price:
			continue
		
		if filters.has("max_price") and item.start_price > filters.max_price:
			continue
		
		result.append({
			"id": item.id,
			"seller": item.seller_name,
			"item_name": item.item_name,
			"start_price": item.start_price,
			"buyout_price": item.buyout_price,
			"current_bid": item.current_bid,
			"current_bidder": item.current_bidder,
			"expire_time": item.expire_time,
			"status": item.status,
			"time_left": item.expire_time - current_time
		})
	
	return result

# 获取我的拍卖
func get_my_auctions(player_id: String) -> Array:
	return get_auction_list({"seller": player_id})

# 获取我参与的拍卖
func get_my_bids(player_id: String) -> Array:
	var result = []
	for item in auction_items:
		if item.current_bidder == player_id and item.status == "active":
			result.append({
				"id": item.id,
				"item_name": item.item_name,
				"my_bid": item.current_bid,
				"time_left": item.expire_time - Time.get_unix_time_from_system()
			})
	return result

# 清理已完成的拍卖
func cleanup_completed():
	var keep = []
	for item in auction_items:
		if item.status == "active":
			keep.append(item)
	auction_items = keep

# 保存/加载
func save_auction():
	var data = []
	for item in auction_items:
		data.append({
			"id": item.id,
			"seller_id": item.seller_id,
			"seller_name": item.seller_name,
			"item_name": item.item_name,
			"item_data": item.item_data,
			"start_price": item.start_price,
			"buyout_price": item.buyout_price,
			"current_bid": item.current_bid,
			"current_bidder": item.current_bidder,
			"listed_time": item.listed_time,
			"expire_time": item.expire_time,
			"status": item.status
		})
	
	var config = ConfigFile.new()
	config.set_value("auction", "items", data)
	config.set_value("auction", "counter", item_counter)
	config.save("user://auction.cfg")

func load_auction():
	if FileAccess.file_exists("user://auction.cfg"):
		var config = ConfigFile.new()
		if config.load("user://auction.cfg") == OK:
			item_counter = config.get_value("auction", "counter", 0)
			var data = config.get_value("auction", "items", [])
			for d in data:
				var item = AuctionItem.new()
				item.id = d.id
				item.seller_id = d.seller_id
				item.seller_name = d.seller_name
				item.item_name = d.item_name
				item.item_data = d.item_data
				item.start_price = d.start_price
				item.buyout_price = d.buyout_price
				item.current_bid = d.current_bid
				item.current_bidder = d.current_bidder
				item.listed_time = d.listed_time
				item.expire_time = d.expire_time
				item.status = d.status
				auction_items.append(item)
