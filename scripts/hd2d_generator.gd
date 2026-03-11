extends Node

## HD-2D素材生成器 - 创建八方旅人风格的像素纹理
## Godot 4.x 兼容版本

## 生成像素纹理（主入口）
static func generate_pixel_texture(width: int, height: int, pattern_type: String) -> ImageTexture:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	match pattern_type:
		"grass":
			_generate_grass_pattern(image)
		"stone":
			_generate_stone_pattern(image)
		"wood":
			_generate_wood_pattern(image)
		"water":
			_generate_water_pattern(image)
		"sand":
			_generate_sand_pattern(image)
		"brick":
			_generate_brick_pattern(image)
		_:
			_generate_default_pattern(image)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

## 草地纹理
static func _generate_grass_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	var base_color = Color(0.2, 0.5, 0.15)
	var highlight_color = Color(0.35, 0.65, 0.2)
	var shadow_color = Color(0.12, 0.35, 0.1)
	
	for y in range(height):
		for x in range(width):
			var noise = randf()
			var color = base_color
			
			# 添加像素化细节
			if noise > 0.7:
				color = highlight_color
			elif noise < 0.25:
				color = shadow_color
			
			# 八方旅人风格的像素块
			if int(x / 4) % 2 == 0 and int(y / 4) % 2 == 0:
				color = color.lightened(0.08)
			
			image.set_pixel(x, y, color)

## 石头纹理
static func _generate_stone_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	var base_color = Color(0.4, 0.4, 0.45)
	var highlight_color = Color(0.55, 0.55, 0.58)
	var shadow_color = Color(0.28, 0.28, 0.32)
	
	for y in range(height):
		for x in range(width):
			var color = base_color
			
			var block_x = int(x / 8)
			var block_y = int(y / 8)
			var noise = randf()
			
			if noise > 0.6:
				color = highlight_color
			elif noise < 0.3:
				color = shadow_color
			
			# 石块边缘
			if x % 8 == 0 or y % 8 == 0:
				color = shadow_color.darkened(0.15)
			
			image.set_pixel(x, y, color)

## 木头纹理
static func _generate_wood_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	var base_color = Color(0.5, 0.35, 0.2)
	var ring_color = Color(0.4, 0.28, 0.15)
	
	for y in range(height):
		for x in range(width):
			var color = base_color
			var stripe = sin(y * 0.35 + x * 0.1) * 0.12
			color = color.lightened(stripe)
			
			# 木纹
			if x % 4 == 0:
				color = color.darkened(0.08)
			
			image.set_pixel(x, y, color)

## 水面纹理
static func _generate_water_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	var base_color = Color(0.2, 0.45, 0.75)
	var highlight_color = Color(0.4, 0.6, 0.85)
	
	for y in range(height):
		for x in range(width):
			var wave = sin((x + y) * 0.25) * 0.18
			var color = base_color.lightened(wave)
			
			# 波光效果
			if sin(x * 0.3 + y * 0.2) > 0.8:
				color = highlight_color
			
			image.set_pixel(x, y, color)

## 沙地纹理
static func _generate_sand_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	var base_color = Color(0.85, 0.75, 0.55)
	var shadow_color = Color(0.7, 0.6, 0.45)
	
	for y in range(height):
		for x in range(width):
			var noise = randf()
			var color = base_color
			
			if noise < 0.3:
				color = shadow_color
			
			image.set_pixel(x, y, color)

## 砖块纹理
static func _generate_brick_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	var brick_color = Color(0.6, 0.35, 0.3)
	var mortar_color = Color(0.5, 0.5, 0.45)
	
	for y in range(height):
		for x in range(width):
			var color = brick_color
			
			# 砖块大小 8x4
			var brick_y = int(y / 4)
			var offset = 0 if brick_y % 2 == 0 else 4
			var brick_x = int((x + offset) / 8)
			
			# 灰浆线
			if y % 4 == 0 or (x + offset) % 8 == 0:
				color = mortar_color
			else:
				# 砖块颜色变化
				var noise = randf()
				if noise > 0.7:
					color = color.lightened(0.1)
				elif noise < 0.2:
					color = color.darkened(0.1)
			
			image.set_pixel(x, y, color)

## 默认纹理
static func _generate_default_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	for y in range(height):
		for x in range(width):
			var color = Color(randf_range(0.3, 0.7), randf_range(0.3, 0.7), randf_range(0.3, 0.7))
			image.set_pixel(x, y, color)
