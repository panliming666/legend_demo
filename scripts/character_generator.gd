extends Node

## 像素角色生成器 - 创建八方旅人风格的2D像素角色
## Godot 4.x 兼容版本

## 生成角色精灵纹理（支持自定义颜色）
static func generate_character_sprite(size: int = 32, tint: Color = Color(0.8, 0.3, 0.3)) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# 透明背景
	for y in range(size):
		for x in range(size):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	# 绘制像素战士（带颜色）
	_draw_warrior(image, size, tint)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

## 绘制像素战士
static func _draw_warrior(image: Image, size: int, tint: Color):
	var scale = size / 32.0
	
	# 战士配色（可自定义tint）
	var armor_color = tint  # 盔甲使用传入的颜色
	var skin_color = Color(0.92, 0.75, 0.65)   # 肤色
	var hair_color = Color(0.2, 0.15, 0.12)  # 深棕色头发
	var sword_color = Color(0.75, 0.75, 0.8)  # 银色剑
	var cape_color = Color(0.65, 0.2, 0.2)   # 红色披风
	var boot_color = Color(0.3, 0.2, 0.15)   # 靴子颜色
	
	# 头部（8x8）- 居中
	_draw_rect(image, 12 * scale, 5 * scale, 8 * scale, 8 * scale, skin_color)
	# 头发
	_draw_rect(image, 11 * scale, 4 * scale, 10 * scale, 3 * scale, hair_color)
	# 眼睛
	image.set_pixel(14 * scale, 8 * scale, Color(0.1, 0.1, 0.1))
	image.set_pixel(18 * scale, 8 * scale, Color(0.1, 0.1, 0.1))
	
	# 身体（盔甲）- 12x12
	_draw_rect(image, 10 * scale, 13 * scale, 12 * scale, 10 * scale, armor_color)
	# 盔甲高光
	_draw_rect(image, 11 * scale, 13 * scale, 10 * scale, 2 * scale, armor_color.lightened(0.15))
	# 盔甲暗部
	_draw_rect(image, 10 * scale, 20 * scale, 12 * scale, 3 * scale, armor_color.darkened(0.2))
	
	# 披风
	_draw_rect(image, 7 * scale, 13 * scale, 3 * scale, 14 * scale, cape_color.darkened(0.15))
	_draw_rect(image, 22 * scale, 13 * scale, 3 * scale, 14 * scale, cape_color)
	
	# 左臂
	_draw_rect(image, 7 * scale, 14 * scale, 3 * scale, 8 * scale, armor_color.darkened(0.1))
	# 右臂（持剑）
	_draw_rect(image, 22 * scale, 14 * scale, 3 * scale, 8 * scale, armor_color.darkened(0.1))
	
	# 腿部
	_draw_rect(image, 11 * scale, 23 * scale, 4 * scale, 7 * scale, boot_color)
	_draw_rect(image, 17 * scale, 23 * scale, 4 * scale, 7 * scale, boot_color)
	
	# 剑（右手侧）
	_draw_rect(image, 24 * scale, 11 * scale, 2 * scale, 14 * scale, sword_color)
	# 剑柄
	_draw_rect(image, 23 * scale, 23 * scale, 4 * scale, 2 * scale, Color(0.45, 0.25, 0.1))
	# 剑鞘
	_draw_rect(image, 25 * scale, 18 * scale, 2 * scale, 6 * scale, Color(0.35, 0.2, 0.15))

## 绘制敌人精灵
static func generate_enemy_sprite(size: int = 32, tint: Color = Color(0.4, 0.8, 0.4)) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# 透明背景
	for y in range(size):
		for x in range(size):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	# 绘制史莱姆
	_draw_slime(image, size, tint)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

## 绘制史莱姆怪物
static func _draw_slime(image: Image, size: int, tint: Color):
	var cx = size / 2
	var cy = size / 2
	var radius = int(size / 3)
	
	# 身体
	_draw_circle_fill(image, cx, cy, radius, tint)
	# 高光
	_draw_circle_fill(image, cx - 2, cy - 2, radius / 3, tint.lightened(0.3))
	
	# 眼睛（白色底）
	image.set_pixel(cx - 3, cy - 1, Color.WHITE)
	image.set_pixel(cx + 2, cy - 1, Color.WHITE)
	# 瞳孔
	image.set_pixel(cx - 3, cy, Color.BLACK)
	image.set_pixel(cx + 2, cy, Color.BLACK)
	
	# 高光点
	image.set_pixel(cx - 4, cy - 2, Color.WHITE)
	image.set_pixel(cx + 1, cy - 2, Color.WHITE)

## 绘制恶魔怪物
static func generate_demon_sprite(size: int = 32) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# 透明背景
	for y in range(size):
		for x in range(size):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var demon_color = Color(0.6, 0.15, 0.15)  # 暗红色
	var horn_color = Color(0.3, 0.3, 0.35)  # 灰色
	
	# 身体
	_draw_rect(image, 10 * (size/32), 10 * (size/32), 12 * (size/32), 14 * (size/32), demon_color)
	
	# 角
	_draw_rect(image, 8 * (size/32), 5 * (size/32), 4 * (size/32), 6 * (size/32), horn_color)
	_draw_rect(image, 20 * (size/32), 5 * (size/32), 4 * (size/32), 6 * (size/32), horn_color)
	
	# 眼睛（发光）
	image.set_pixel(13 * (size/32), 14 * (size/32), Color(1.0, 0.3, 0.0))
	image.set_pixel(18 * (size/32), 14 * (size/32), Color(1.0, 0.3, 0.0))
	
	# 牙齿
	_draw_rect(image, 14 * (size/32), 22 * (size/32), 2 * (size/32), 2 * (size/32), Color.WHITE)
	_draw_rect(image, 16 * (size/32), 22 * (size/32), 2 * (size/32), 2 * (size/32), Color.WHITE)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

## 绘制幽灵怪物
static func generate_ghost_sprite(size: int = 32) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# 透明背景
	for y in range(size):
		for x in range(size):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var ghost_color = Color(0.6, 0.7, 0.9)
	var highlight_color = Color(0.9, 0.95, 1.0)
	
	# 身体（半圆形顶部）
	_draw_circle_fill(image, size/2, size/2 + 4, size/2 - 2, ghost_color)
	
	# 眼睛（发光）
	image.set_pixel(size/2 - 3, size/2, Color(0.1, 0.1, 0.2))
	image.set_pixel(size/2 + 2, size/2, Color(0.1, 0.1, 0.2))
	
	# 下摆（波浪形）
	for i in range(5):
		var x = 6 + i * 5
		image.set_pixel(x, size - 3, ghost_color)
		image.set_pixel(x + 1, size - 2, ghost_color)
		image.set_pixel(x + 2, size - 3, ghost_color.darkened(0.1))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

## 辅助：填充矩形
static func _draw_rect(image: Image, x: float, y: float, w: float, h: float, color: Color):
	var start_x = int(x)
	var start_y = int(y)
	var end_x = int(x + w)
	var end_y = int(y + h)
	
	for py in range(start_y, min(end_y, image.get_height())):
		for px in range(start_x, min(end_x, image.get_width())):
			image.set_pixel(px, py, color)

## 辅助：填充圆形
static func _draw_circle_fill(image: Image, cx: int, cy: int, radius: int, color: Color):
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				var px = cx + x
				var py = cy + y
				if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
					image.set_pixel(px, py, color)
