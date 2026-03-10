extends Node

# 像素角色生成器 - 创建八方旅人风格的2D像素角色

static func generate_character_sprite(size: int = 32) -> ImageTexture:
	var image = Image.new()
	image.create(size, size, false, Image.FORMAT_RGBA8)
	image.lock()
	
	# 透明背景
	for y in range(size):
		for x in range(size):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	# 绘制简单的像素战士
	_draw_warrior(image, size)
	
	image.unlock()
	
	var texture = ImageTexture.new()
	texture.create_from_image(image, 0)
	return texture

static func _draw_warrior(image: Image, size: int):
	# 战士配色（八方旅人风格）
	var armor_color = Color(0.3, 0.4, 0.6)  # 蓝色盔甲
	var skin_color = Color(0.9, 0.7, 0.6)   # 肤色
	var hair_color = Color(0.2, 0.15, 0.1)  # 棕色头发
	var sword_color = Color(0.7, 0.7, 0.75) # 银色剑
	var cape_color = Color(0.6, 0.2, 0.2)   # 红色披风
	
	# 简化的像素绘制（基于比例）
	var scale = size / 32.0
	
	# 头部（8x8）
	_draw_rect(image, 12 * scale, 4 * scale, 8 * scale, 8 * scale, skin_color)
	# 头发
	_draw_rect(image, 12 * scale, 4 * scale, 8 * scale, 2 * scale, hair_color)
	
	# 身体（盔甲）
	_draw_rect(image, 10 * scale, 12 * scale, 12 * scale, 12 * scale, armor_color)
	
	# 披风
	_draw_rect(image, 6 * scale, 12 * scale, 4 * scale, 12 * scale, cape_color)
	
	# 腿部
	_draw_rect(image, 11 * scale, 24 * scale, 4 * scale, 6 * scale, armor_color.darkened(0.2))
	_draw_rect(image, 17 * scale, 24 * scale, 4 * scale, 6 * scale, armor_color.darkened(0.2))
	
	# 剑
	_draw_rect(image, 22 * scale, 10 * scale, 3 * scale, 14 * scale, sword_color)
	_draw_rect(image, 20 * scale, 20 * scale, 7 * scale, 2 * scale, Color(0.5, 0.3, 0.1))

static func _draw_rect(image: Image, x: float, y: float, w: float, h: float, color: Color):
	var start_x = int(x)
	var start_y = int(y)
	var end_x = int(x + w)
	var end_y = int(y + h)
	
	for py in range(start_y, min(end_y, image.get_height())):
		for px in range(start_x, min(end_x, image.get_width())):
			image.set_pixel(px, py, color)

static func generate_enemy_sprite(size: int = 32) -> ImageTexture:
	var image = Image.new()
	image.create(size, size, false, Image.FORMAT_RGBA8)
	image.lock()
	
	# 透明背景
	for y in range(size):
		for x in range(size):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	# 绘制史莱姆怪物
	var body_color = Color(0.8, 0.3, 0.8)  # 紫色史莱姆
	var highlight = Color(1.0, 0.5, 1.0)
	
	# 身体
	_draw_circle(image, size/2, size/2, size/3, body_color)
	# 高光
	image.set_pixel(size/2 - 2, size/2 - 3, highlight)
	image.set_pixel(size/2 - 1, size/2 - 4, highlight)
	
	# 眼睛
	image.set_pixel(size/2 - 3, size/2 - 1, Color.WHITE)
	image.set_pixel(size/2 + 2, size/2 - 1, Color.WHITE)
	image.set_pixel(size/2 - 3, size/2, Color.BLACK)
	image.set_pixel(size/2 + 2, size/2, Color.BLACK)
	
	image.unlock()
	
	var texture = ImageTexture.new()
	texture.create_from_image(image, 0)
	return texture

static func _draw_circle(image: Image, cx: int, cy: int, radius: int, color: Color):
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				var px = cx + x
				var py = cy + y
				if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
					image.set_pixel(px, py, color)
