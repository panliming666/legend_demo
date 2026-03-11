extends Node3D

class_name HD2DEnvironment3D

## HD-2D环境管理器 - 纯正HD-2D实现
## 核心理念：2D像素精灵直接渲染在3D空间中，参与深度测试和光影计算
## 参考《八方旅人》的渲染方案

# 3D相机引用
var main_camera: Camera3D

# 光源引用
var sun_light: DirectionalLight3D
var world_environment: WorldEnvironment

# 相机参数（经典JRPG俯视45度视角）
const CAMERA_DISTANCE: float = 25.0
const CAMERA_ANGLE_X: float = -30.0  # 俯视角度
const CAMERA_ANGLE_Y: float = 45.0   # 水平旋转
const CAMERA_FOV: float = 30.0       # 小FOV模拟正交投影效果

func _ready():
	setup_3d_scene()
	setup_camera()
	setup_lighting()
	setup_post_processing()

## 创建3D场景基础元素
func setup_3d_scene():
	# 创建地面网格
	var ground_mesh = PlaneMesh.new()
	ground_mesh.size = Vector2(60, 60)
	ground_mesh.orientation = PlaneMesh.FACE_Y  # 面向上
	
	# 地面材质 - 接受光影和阴影
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.25, 0.45, 0.25)  # 草地绿色
	ground_material.roughness = 0.9
	ground_material.metallic = 0.0
	# 启用纹理过滤保持像素锐利
	ground_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	ground_mesh.material = ground_material
	
	var ground = MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = ground_mesh
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # 地面不投射阴影
	ground.receive_shadow = true  # 但接收阴影
	add_child(ground)
	
	# 创建环境装饰物（树木、岩石等3D元素）
	_create_environment_decorations()

## 创建环境装饰物
func _create_environment_decorations():
	# 创建一些低多边形风格的装饰物，增强3D深度感
	for i in range(15):
		var decoration_type = randi() % 3
		
		match decoration_type:
			0:  # 树木
				_create_tree(Vector3(randf_range(-25, 25), 0, randf_range(-25, 25)))
			1:  # 岩石
				_create_rock(Vector3(randf_range(-25, 25), 0, randf_range(-25, 25)))
			2:  # 灌木
				_create_bush(Vector3(randf_range(-25, 25), 0, randf_range(-25, 25)))

## 创建树木装饰
func _create_tree(pos: Vector3):
	var tree = Node3D.new()
	tree.position = pos
	
	# 树干
	var trunk = MeshInstance3D.new()
	trunk.mesh = CylinderMesh.new()
	trunk.mesh.top_radius = 0.3
	trunk.mesh.bottom_radius = 0.4
	trunk.mesh.height = 2.0
	trunk.position.y = 1.0
	
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.4, 0.25, 0.15)
	trunk_mat.roughness = 0.9
	trunk.mesh.material = trunk_mat
	trunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	tree.add_child(trunk)
	
	# 树冠
	var foliage = MeshInstance3D.new()
	foliage.mesh = SphereMesh.new()
	foliage.mesh.radius = 1.5
	foliage.mesh.height = 3.0
	foliage.position.y = 3.0
	
	var foliage_mat = StandardMaterial3D.new()
	foliage_mat.albedo_color = Color(0.2, 0.5, 0.2)
	foliage_mat.roughness = 0.8
	foliage.mesh.material = foliage_mat
	foliage.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	tree.add_child(foliage)
	
	add_child(tree)

## 创建岩石装饰
func _create_rock(pos: Vector3):
	var rock = MeshInstance3D.new()
	rock.mesh = BoxMesh.new()
	rock.position = pos + Vector3(0, randf_range(0.3, 0.8), 0)
	rock.scale = Vector3(randf_range(0.5, 1.2), randf_range(0.4, 1.0), randf_range(0.5, 1.2))
	rock.rotation_degrees = Vector3(randf_range(-10, 10), randf_range(0, 360), randf_range(-10, 10))
	
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.35, 0.35, 0.4)
	rock_mat.roughness = 0.95
	rock.mesh.material = rock_mat
	rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	rock.receive_shadow = true
	
	add_child(rock)

## 创建灌木装饰
func _create_bush(pos: Vector3):
	var bush = MeshInstance3D.new()
	bush.mesh = SphereMesh.new()
	bush.mesh.radius = 0.5
	bush.position = pos + Vector3(0, 0.4, 0)
	bush.scale = Vector3(randf_range(0.8, 1.2), randf_range(0.6, 1.0), randf_range(0.8, 1.2))
	
	var bush_mat = StandardMaterial3D.new()
	bush_mat.albedo_color = Color(0.15, 0.4, 0.15)
	bush_mat.roughness = 0.85
	bush.mesh.material = bush_mat
	bush.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	add_child(bush)

## 设置相机 - 经典JRPG视角
func setup_camera():
	main_camera = Camera3D.new()
	main_camera.name = "HD2DCamera"
	
	# 使用透视投影，但设置小FOV模拟正交效果
	# 这样可以保留3D深度感同时避免透视畸变
	main_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	main_camera.fov = CAMERA_FOV
	main_camera.near = 0.1
	main_camera.far = 100.0
	
	# 计算相机位置（俯视45度）
	var cam_x = CAMERA_DISTANCE * sin(deg_to_rad(CAMERA_ANGLE_Y)) * cos(deg_to_rad(-CAMERA_ANGLE_X))
	var cam_y = CAMERA_DISTANCE * sin(deg_to_rad(-CAMERA_ANGLE_X))
	var cam_z = CAMERA_DISTANCE * cos(deg_to_rad(CAMERA_ANGLE_Y)) * cos(deg_to_rad(-CAMERA_ANGLE_X))
	
	main_camera.position = Vector3(cam_x, cam_y, cam_z)
	
	# 相机朝向原点
	main_camera.look_at(Vector3.ZERO, Vector3.UP)
	
	add_child(main_camera)
	
	print("HD-2D相机已设置 - 位置:", main_camera.position, " FOV:", CAMERA_FOV)

## 设置光照系统
func setup_lighting():
	# 主光源（太阳光）
	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	
	# 光照角度 - 从右上方照射，产生漂亮的阴影
	sun_light.rotation_degrees = Vector3(-45, 45, 0)
	
	# 温暖的阳光色调
	sun_light.light_color = Color(1.0, 0.95, 0.85)
	sun_light.light_energy = 1.2
	sun_light.light_indirect_energy = 0.5
	
	# 开启阴影
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.01
	sun_light.shadow_blur = 1.5
	sun_light.shadow_normal_bias = 1.0
	
	# 高质量阴影设置
	sun_light.directional_shadow_max_distance = 50.0
	sun_light.directional_shadow_split_1 = 0.25
	sun_light.directional_shadow_split_2 = 0.5
	sun_light.directional_shadow_split_3 = 0.75
	
	add_child(sun_light)
	
	# 环境光（补光）
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.rotation_degrees = Vector3(-30, -135, 0)
	fill_light.light_color = Color(0.7, 0.8, 1.0)  # 冷色调补光
	fill_light.light_energy = 0.3
	fill_light.shadow_enabled = false  # 补光不投射阴影
	add_child(fill_light)
	
	# 创建世界环境（后处理效果）
	_setup_world_environment()

## 设置世界环境和后处理
func _setup_world_environment():
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	
	var environment = Environment.new()
	
	# === 背景设置 ===
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.15, 0.2, 0.35)  # 深蓝色天空
	
	# === 环境光（Ambient） ===
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.3, 0.35, 0.45)
	environment.ambient_light_energy = 0.4
	
	# === 雾效果（增强深度感） ===
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_density = 0.008
	environment.fog_color = Color(0.15, 0.2, 0.35)
	environment.fog_depth_begin = 20.0
	environment.fog_depth_end = 60.0
	environment.fog_aerial_perspective = 0.5
	
	# === Glow（发光/泛光效果）- HD-2D核心视觉特征 ===
	environment.glow_enabled = true
	environment.glow_levels = Vector2i(1, 7)  # 高斯模糊级别范围
	environment.glow_intensity = 0.5
	environment.glow_strength = 1.0
	environment.glow_bloom = 0.3  # Bloom阈值
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	environment.glow_hdr_threshold = 1.0
	environment.glow_hdr_scale = 2.0
	environment.glow_bicubic_upscale = true  # 高质量上采样
	
	# === DOF 景深（模拟倾斜移轴效果）- HD-2D标志性视觉 ===
	# 这会让远处的景物微微模糊，像微缩模型一样
	environment.dof_blur_far_enabled = true
	environment.dof_blur_far_distance = 35.0
	environment.dof_blur_far_transition = 15.0
	environment.dof_blur_near_enabled = true
	environment.dof_blur_near_distance = 2.0
	environment.dof_blur_near_transition = 1.0
	environment.dof_blur_amount = 0.15  # 轻微的模糊效果
	
	# === SSAO（屏幕空间环境光遮蔽）===
	environment.ssr_enabled = false  # 反射不需要
	environment.sao_enabled = true
	environment.sao_intensity = 0.5
	environment.sao_radius = 1.0
	environment.sao_bias = 0.01
	
	# === 色彩校正 ===
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.0
	environment.adjustment_contrast = 1.1  # 轻微增加对比度
	environment.adjustment_saturation = 1.15  # 轻微增加饱和度
	
	world_environment.environment = environment
	add_child(world_environment)
	
	print("HD-2D环境光照已设置 - 包含Glow、DOF景深")

## 设置后处理（屏幕空间效果）
func setup_post_processing():
	# 额外的色彩分级可以通过Compositor实现
	# 这里我们已经通过Environment完成了大部分后处理
	# 如果需要更复杂的色彩分级，可以添加ColorRect + Shader
	pass

## 获取相机引用（供其他脚本使用）
func get_camera() -> Camera3D:
	return main_camera

## 获取环境引用（供其他脚本使用）
func get_environment() -> WorldEnvironment:
	return world_environment

## 相机跟随目标（用于游戏中的相机控制）
func camera_follow(target: Node3D, smoothing: float = 5.0):
	if main_camera and target:
		var offset = main_camera.position - Vector3.ZERO
		var target_pos = target.global_position + offset
		main_camera.position = main_camera.position.lerp(target_pos, smoothing * get_process_delta_time())
		main_camera.look_at(target.global_position, Vector3.UP)

## 设置相机目标位置（带平滑过渡）
func set_camera_target(target_position: Vector3, duration: float = 1.0):
	if main_camera:
		var tween = create_tween()
		var offset = main_camera.position - Vector3.ZERO
		tween.tween_property(main_camera, "position", target_position + offset, duration)
		tween.parallel().tween_method(
			func(pos): main_camera.look_at(pos, Vector3.UP),
			Vector3.ZERO,
			target_position,
			duration
		)
