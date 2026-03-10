extends Node3D

class_name HD2DEnvironment3D

# HD-2D环境管理器 - 创建3D场景中的2D像素角色效果

var sub_viewport: SubViewport
var world_2d: Node2D

func _ready():
	setup_3d_scene()
	create_pixel_world()
	setup_lighting()

func setup_3d_scene():
	# 创建基础3D地面
	var ground_mesh = PlaneMesh.new()
	ground_mesh.size = Vector2(40, 40)
	
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.2, 0.4, 0.2)
	ground_material.shading_mode = StandardMaterial3D.SHADING_UNSHADED
	ground_mesh.material = ground_material
	
	var ground = MeshInstance3D.new()
	ground.mesh = ground_mesh
	add_child(ground)
	
	# 创建一些3D立方体装饰
	for i in range(10):
		var cube = MeshInstance3D.new()
		cube.mesh = BoxMesh.new()
		cube.position = Vector3(randf_range(-15, 15), 1, randf_range(-15, 15))
		cube.scale = Vector3(randf_range(0.5, 2), randf_range(1, 3), randf_range(0.5, 2))
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.3, 0.4)
		material.shading_mode = StandardMaterial3D.SHADING_UNSHADED
		cube.mesh.surface_set_material(0, material)
		
		add_child(cube)

func create_pixel_world():
	# 创建SubViewport来渲染2D像素内容
	sub_viewport = SubViewport.new()
	sub_viewport.size = Vector2(1280, 720)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.transparent_bg = true
	add_child(sub_viewport)
	
	# 在SubViewport中创建2D世界
	world_2d = Node2D.new()
	world_2d.name = "World2D"
	sub_viewport.add_child(world_2d)

func setup_lighting():
	# 创建主光源
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 45, 0)
	sun.light_color = Color(1, 0.95, 0.9)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)
	
	# 环境光
	var world_environment = WorldEnvironment.new()
	var environment = Environment.new()
	
	# 设置背景
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.15, 0.25)
	
	# 添加雾效果增加深度感
	environment.fog_enabled = true
	environment.fog_color = Color(0.1, 0.15, 0.25)
	environment.fog_density = 0.01
	
	world_environment.environment = environment
	add_child(world_environment)

func update_world_2d():
	# 同步2D世界中的对象位置
	if world_2d:
		var player = get_tree().current_scene.get_node_or_null("Player")
		if player:
			# 将3D位置转换为2D位置
			var viewport_pos = sub_viewport.world_to_canvas(player.global_position)
			# 更新2D精灵位置
			for child in world_2d.get_children():
				if child.is_in_group("pixel_sprite"):
					child.position = viewport_pos
