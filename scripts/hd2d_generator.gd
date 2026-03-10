extends Node

# HD-2D素材生成器 - 创建八方旅人风格的像素纹理

static func generate_pixel_texture(width: int, height: int, pattern_type: String) -> ImageTexture:
	var image = Image.new()
	image.create(width, height, false, Image.FORMAT_RGBA8)
	
	image.lock()
	
	match pattern_type:
		"grass":
			_generate_grass_pattern(image)
		"stone":
			_generate_stone_pattern(image)
		"wood":
			_generate_wood_pattern(image)
		"water":
			_generate_water_pattern(image)
		_:
			_generate_default_pattern(image)
	
	image.unlock()
	
	var texture = ImageTexture.new()
	texture.create_from_image(image, 0)
	return texture

static func _generate_grass_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	# 基础草地颜色
	var base_color = Color(0.2, 0.5, 0.15)
	var highlight_color = Color(0.3, 0.6, 0.2)
	var shadow_color = Color(0.15, 0.4, 0.1)
	
	for y in range(height):
		for x in range(width):
			var noise = randf()
			var color = base_color
			
			# 添加像素化细节
			if noise > 0.7:
				color = highlight_color
			elif noise < 0.3:
				color = shadow_color
			
			# 八方旅人风格的像素块
			if int(x / 4) % 2 == 0 and int(y / 4) % 2 == 0:
				color = color.lightened(0.1)
			
			image.set_pixel(x, y, color)

static func _generate_stone_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	var base_color = Color(0.4, 0.4, 0.45)
	var highlight_color = Color(0.5, 0.5, 0.55)
	var shadow_color = Color(0.3, 0.3, 0.35)
	
	for y in range(height):
		for x in range(width):
			var color = base_color
			
			# 石头纹理
			var block_x = int(x / 8)
			var block_y = int(y / 8)
			var noise = randf()
			
			if noise > 0.6:
				color = highlight_color
			elif noise < 0.3:
				color = shadow_color
			
			# 石块边缘
			if x % 8 == 0 or y % 8 == 0:
				color = shadow_color
			
			image.set_pixel(x, y, color)

static func _generate_wood_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	var base_color = Color(0.45, 0.35, 0.2)
	
	for y in range(height):
		for x in range(width):
			var color = base_color
			var stripe = sin(y * 0.3) * 0.1
			color = color.lightened(stripe)
			
			# 木纹
			if x % 3 == 0:
				color = color.darkened(0.05)
			
			image.set_pixel(x, y, color)

static func _generate_water_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	var base_color = Color(0.2, 0.4, 0.7)
	
	for y in range(height):
		for x in range(width):
			var wave = sin((x + y) * 0.2) * 0.15
			var color = base_color.lightened(wave)
			image.set_pixel(x, y, color)

static func _generate_default_pattern(image: Image):
	var width = image.get_width()
	var height = image.get_height()
	
	for y in range(height):
		for x in range(width):
			var color = Color(randf(), randf(), randf())
			image.set_pixel(x, y, color)
