extends Node

class_name HD2DSceneManager

## HD-2D场景管理器 - 纯正HD-2D精灵管理
## 核心理念：使用Sprite3D让2D像素角色正确参与3D渲染管线
## 包括深度测试、阴影投射、光照接收

# 精灵纹理缓存
var tile_textures: Dictionary = {}
var character_textures: Dictionary = {}

# 3D场景根节点引用
var environment_3d: HD2DEnvironment3D

# 精灵配置
const SPRITE_PIXEL_SIZE: float = 32.0  # 像素精灵基础尺寸
const SPRITE_SCALE: float = 0.0625     # 1像素 = 0.0625世界单位（32像素 = 2单位）
const SPRITE_BILLBOARD_MODE: bool = true  # 启用看板模式

func _ready():
	# 等待场景加载完成
	await get_tree().process_frame
	
	# 初始化纹理
	_generate_tile_textures()
	_generate_character_textures()
	
	# 查找3D环境
	_find_3d_environment()
	
	# 应用精灵到场景
	_apply_textures_to_scene()

## 生成环境瓦片纹理
func _generate_tile_textures():
	var patterns = ["grass", "stone", "wood", "water", "sand", "brick"]
	for pattern in patterns:
		var texture = HD2DGenerator.generate_pixel_texture(32, 32, pattern)
		tile_textures[pattern] = texture

## 生成角色纹理
func _generate_character_textures():
	# 玩家职业纹理
	character_textures["warrior"] = CharacterGenerator.generate_character_sprite(32, Color(0.8, 0.3, 0.3))
	character_textures["mage"] = CharacterGenerator.generate_character_sprite(32, Color(0.3, 0.3, 0.8))
	character_textures["taoist"] = CharacterGenerator.generate_character_sprite(32, Color(0.3, 0.8, 0.3))
	
	# 敌人纹理
	character_textures["slime"] = CharacterGenerator.generate_enemy_sprite(32, Color(0.3, 0.7, 0.3))
	character_textures["demon"] = CharacterGenerator.generate_enemy_sprite(32, Color(0.8, 0.2, 0.2))
	character_textures["ghost"] = CharacterGenerator.generate_enemy_sprite(32, Color(0.6, 0.6, 0.9))

## 查找3D环境节点
func _find_3d_environment():
	environment_3d = get_tree().current_scene.get_node_or_null("HD2DEnvironment3D")
	if environment_3d == null:
		# 尝试在父节点中查找
		for child in get_tree().current_scene.get_children():
			if child is HD2DEnvironment3D:
				environment_3d = child
				break
	
	if environment_3d:
		print("HD-2D场景管理器已连接3D环境")
	else:
		push_warning("未找到HD2DEnvironment3D节点，部分功能可能受限")

## 将2D场景元素转换为3D精灵
## 这是HD-2D的核心转换逻辑
func _apply_textures_to_scene():
	var main_scene = get_tree().current_scene
	if main_scene == null:
		return
	
	# === 转换玩家 ===
	var player = main_scene.get_node_or_null("Player")
	if player:
		_convert_entity_to_sprite3d(player, "warrior")
	
	# === 转换敌人 ===
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var texture_key = _get_enemy_texture_key(enemy)
		_convert_entity_to_sprite3d(enemy, texture_key)
	
	# === 转换掉落物 ===
	var drops = get_tree().get_nodes_in_group("drops")
	for drop in drops:
		_convert_drop_to_sprite3d(drop)
	
	print("HD-2D场景转换完成")

## 获取敌人对应的纹理键
func _get_enemy_texture_key(enemy: Node) -> String:
	var enemy_name = enemy.name.to_lower()
	
	if "slime" in enemy_name:
		return "slime"
	elif "demon" in enemy_name or "boss" in enemy_name:
		return "demon"
	elif "ghost" in enemy_name:
		return "ghost"
	else:
		return "slime"  # 默认

## 将实体转换为Sprite3D（HD-2D核心方法）
func _convert_entity_to_sprite3d(entity: Node, texture_key: String):
	# 检查是否已经有Sprite3D
	if entity.has_node("Sprite3D"):
		return  # 已经转换过
	
	# 获取或创建纹理
	var texture = character_textures.get(texture_key)
	if texture == null:
		texture = CharacterGenerator.generate_character_sprite(32)
		character_textures[texture_key] = texture
	
	# 创建Sprite3D节点
	var sprite_3d = Sprite3D.new()
	sprite_3d.name = "Sprite3D"
	
	# === 设置纹理 ===
	sprite_3d.texture = texture
	
	# === 设置像素完美渲染 ===
	# 使用最近邻过滤保持像素锐利
	sprite_3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	# === 设置透明度裁剪 ===
	# 这对于深度测试和阴影非常重要！
	# ALPHA_CUT_DISCARD 会完全丢弃透明像素，让它们不参与深度测试
	sprite_3d.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite_3d.alpha_scissor_threshold = 0.5
	
	# === 设置精灵大小 ===
	# 确保精灵在世界空间中有合适的尺寸
	sprite_3d.pixel_size = SPRITE_SCALE
	sprite_3d.offset = Vector2(0, SPRITE_PIXEL_SIZE * 0.5)  # 底部对齐
	
	# === 启用看板模式 ===
	# 让精灵始终面向相机，但保持正确的深度位置
	if SPRITE_BILLBOARD_MODE:
		sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# === 启用阴影投射 ===
	# 让精灵能够投射和接收阴影，这是HD-2D深度的关键
	sprite_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	sprite_3d.receive_shadow = true
	
	# === 设置渲染层 ===
	# 确保精灵在正确的渲染层
	sprite_3d.layers = 1  # 默认层
	
	# === 材质增强 ===
	# 可以添加自定义材质来增强光影效果
	_setup_sprite_material(sprite_3d)
	
	# === 添加到实体 ===
	entity.add_child(sprite_3d)
	
	# 隐藏原有的ColorRect或其他2D显示节点
	for child in entity.get_children():
		if child is ColorRect or (child is Sprite2D and child.name != "Sprite3D"):
			child.hide()
	
	# 如果实体是CharacterBody2D，需要设置其位置映射
	if entity is CharacterBody2D:
		# 保持原有的移动逻辑，只是显示用3D精灵
		sprite_3d.position = Vector3(0, 1, 0)  # 精灵在实体上方

## 设置精灵材质（增强光影效果）
func _setup_sprite_material(sprite: Sprite3D):
	# 获取或创建材质
	var material: StandardMaterial3D
	
	if sprite.material_override:
		material = sprite.material_override
	else:
		material = StandardMaterial3D.new()
	
	# 材质设置
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL  # 逐像素光照
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.7
	material.metallic = 0.0
	
	# 确保正确的深度测试
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # 双面渲染
	
	# 背面光照（看板模式需要）
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.billboard_keep_scale = true
	
	sprite.material_override = material

## 转换掉落物为Sprite3D
func _convert_drop_to_sprite3d(drop: Node):
	# 掉落物使用简单的发光效果
	var sprite_3d = Sprite3D.new()
	sprite_3d.name = "Sprite3D"
	
	# 创建发光的圆形纹理
	var texture = _create_glow_texture()
	sprite_3d.texture = texture
	
	sprite_3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite_3d.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite_3d.pixel_size = SPRITE_SCALE * 0.5
	sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	drop.add_child(sprite_3d)

## 创建发光纹理（用于掉落物）
func _create_glow_texture() -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(8, 8)
	for x in range(16):
		for y in range(16):
			var dist = Vector2(x, y).distance_to(center)
			var alpha = max(0, 1.0 - dist / 8.0)
			var color = Color(1.0, 0.9, 0.3, alpha)  # 金色发光
			img.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(img)
	return texture

## 创建地面瓦片（用于TileMap转换）
func create_ground_tilemap(width: int, height: int, parent: Node3D):
	# 创建基于3D平面的地面瓦片系统
	for x in range(width):
		for z in range(height):
			var tile = MeshInstance3D.new()
			tile.mesh = PlaneMesh.new()
			tile.mesh.size = Vector2(1, 1)
			
			# 随机选择纹理
			var pattern = ["grass", "stone", "sand"][randi() % 3]
			var texture = tile_textures.get(pattern)
			
			if texture:
				var material = StandardMaterial3D.new()
				material.albedo_texture = texture
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				material.roughness = 0.9
				tile.mesh.material = material
			
			tile.position = Vector3(x - width/2.0, 0, z - height/2.0)
			tile.receive_shadow = true
			
			parent.add_child(tile)

## 创建动态光照（用于技能特效）
func create_dynamic_light(position: Vector3, color: Color, energy: float = 1.0, duration: float = 0.5) -> OmniLight:
	var light = OmniLight.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 10.0
	light.omni_attenuation = 2.0
	
	if environment_3d:
		environment_3d.add_child(light)
	
	# 自动消失
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		var tween = create_tween()
		tween.tween_property(light, "light_energy", 0.0, 0.3)
		tween.tween_callback(light.queue_free)
	
	return light

## 更新精灵动画（配合动画系统）
func update_sprite_animation(entity: Node, animation_name: String, frame: int = 0):
	if entity.has_node("Sprite3D"):
		var sprite = entity.get_node("Sprite3D")
		# 这里可以集成AnimationPlayer或SpriteFrames
		# 根据动画名和帧数更新纹理区域
		pass

## 获取实体对应的Sprite3D
func get_entity_sprite(entity: Node) -> Sprite3D:
	if entity.has_node("Sprite3D"):
		return entity.get_node("Sprite3D")
	return null

## 设置精灵透明度（用于淡入淡出效果）
func set_sprite_opacity(entity: Node, opacity: float):
	var sprite = get_entity_sprite(entity)
	if sprite and sprite.material_override:
		var material = sprite.material_override as StandardMaterial3D
		# 可以通过修改alpha来实现
		material.albedo_color.a = opacity

## 创建3D粒子效果（替代2D粒子）
func create_3d_particles(position: Vector3, color: Color, count: int = 10):
	var particles = GPUParticles3D.new()
	particles.position = position
	particles.amount = count
	particles.lifetime = 1.0
	particles.explosiveness = 0.8
	
	# 创建简单的粒子材质
	var process_material = ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = 45.0
	process_material.initial_velocity_min = 2.0
	process_material.initial_velocity_max = 4.0
	process_material.gravity = Vector3(0, -5, 0)
	
	particles.process_material = process_material
	
	# 创建简单的四边形网格
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.1, 0.1)
	particles.draw_pass_1 = quad_mesh
	
	if environment_3d:
		environment_3d.add_child(particles)
		# 自动清理
		await get_tree().create_timer(2.0).timeout
		particles.queue_free()
	
	return particles
