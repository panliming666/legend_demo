extends Node2D

class_name HD2DSceneManager

# HD-2D场景管理器 - 管理像素纹理和场景效果

var tile_textures: Dictionary = {}
var character_textures: Dictionary = {}

func _ready():
	# 生成所有需要的纹理
	_generate_tile_textures()
	_generate_character_textures()
	
	# 应用到场景
	_apply_textures_to_scene()

func _generate_tile_textures():
	# 环境纹理（32x32）
	var patterns = ["grass", "stone", "wood", "water"]
	for pattern in patterns:
		var texture = HD2DGenerator.generate_pixel_texture(32, 32, pattern)
		tile_textures[pattern] = texture

func _generate_character_textures():
	# 角色纹理
	character_textures["warrior"] = CharacterGenerator.generate_character_sprite(32)
	character_textures["slime"] = CharacterGenerator.generate_enemy_sprite(32)

func _apply_textures_to_scene():
	# 获取主场景
	var main = get_tree().current_scene
	if main == null:
		return
	
	# 替换玩家颜色矩形为精灵
	var player = main.get_node_or_null("Player")
	if player and player.has_node("ColorRect"):
		var color_rect = player.get_node("ColorRect")
		
		# 创建精灵节点
		var sprite = Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = character_textures.get("warrior")
		sprite.scale = Vector2(2, 2)  # 放大显示
		
		# 替换颜色矩形
		color_rect.replace_by(sprite)
		if color_rect.get_parent():
			color_rect.get_parent().add_child(sprite)
			color_rect.queue_free()
	
	# 替换敌人颜色矩形为精灵
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_node("ColorRect"):
			var color_rect = enemy.get_node("ColorRect")
			
			var sprite = Sprite2D.new()
			sprite.name = "Sprite"
			sprite.texture = character_textures.get("slime")
			sprite.scale = Vector2(2, 2)
			
			color_rect.replace_by(sprite)
			if color_rect.get_parent():
				color_rect.get_parent().add_child(sprite)
				color_rect.queue_free()

# 创建TileMap用的贴图
func create_tile_set() -> TileSet:
	var tile_set = TileSet.new()
	
	# 创建草地瓦片源
	var terrain = TileSetSource.new()
	terrain.name = "Terrain"
	terrain.tile_set = tile_set
	
	for i in range(16):
		var tile_data = TileSetCellNew().create()
		# 可以在这里添加tile_data的纹理
		terrain.add_tile_data(tile_data)
	
	tile_set.add_source(terrain)
	
	return tile_set
