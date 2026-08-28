## player_model_v2.gd
## 3D球员模型（优化版 v2）
## 更精细的角色：头部/面部/身体/四肢/球鞋/球衣号码
extends Node3D

# 身体部件
var head: MeshInstance3D
var hair: MeshInstance3D
var left_eye: MeshInstance3D
var right_eye: MeshInstance3D
var nose: MeshInstance3D
var mouth: MeshInstance3D
var body: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var left_shoe: MeshInstance3D
var right_shoe: MeshInstance3D
var jersey_number_label: Label3D
var direction_arrow: MeshInstance3D

# 材质
var skin_material: StandardMaterial3D
var hair_material: StandardMaterial3D
var kit_material: StandardMaterial3D
var shorts_material: StandardMaterial3D
var shoe_material: StandardMaterial3D

# 外观参数
var appearance: Dictionary = {}

# 动画状态
var anim_time: float = 0.0
var current_anim: String = "idle"
var is_running: bool = false
var is_kicking: bool = false
var kick_timer: float = 0.0

## 创建精细球员模型
func create_model(kit_color: Color = Color(0.9, 0.15, 0.15), shorts_color: Color = Color(0.1, 0.1, 0.1), skin_tone: Color = Color(0.9, 0.7, 0.5), hair_color: Color = Color(0.2, 0.15, 0.1), hair_style: String = "short"):
	# 创建材质
	skin_material = StandardMaterial3D.new()
	skin_material.albedo_color = skin_tone
	skin_material.roughness = 0.7

	hair_material = StandardMaterial3D.new()
	hair_material.albedo_color = hair_color
	hair_material.roughness = 0.8

	kit_material = StandardMaterial3D.new()
	kit_material.albedo_color = kit_color
	kit_material.roughness = 0.6

	shorts_material = StandardMaterial3D.new()
	shorts_material.albedo_color = shorts_color
	shorts_material.roughness = 0.7

	shoe_material = StandardMaterial3D.new()
	shoe_material.albedo_color = Color(0.05, 0.05, 0.05)
	shoe_material.roughness = 0.5

	# 头部
	head = _create_part(SphereMesh.new(), Vector3(0, 1.75, 0), Vector3(0.22, 0.22, 0.22), skin_material)
	add_child(head)

	# 头发（根据发型）
	_create_hair(hair_style)

	# 眼睛
	left_eye = _create_part(SphereMesh.new(), Vector3(-0.08, 1.78, 0.18), Vector3(0.03, 0.03, 0.03), _create_material(Color(1, 1, 1)))
	add_child(left_eye)
	right_eye = _create_part(SphereMesh.new(), Vector3(0.08, 1.78, 0.18), Vector3(0.03, 0.03, 0.03), _create_material(Color(1, 1, 1)))
	add_child(right_eye)

	# 瞳孔
	var left_pupil = _create_part(SphereMesh.new(), Vector3(-0.08, 1.78, 0.2), Vector3(0.015, 0.015, 0.015), _create_material(Color(0.1, 0.1, 0.1)))
	add_child(left_pupil)
	var right_pupil = _create_part(SphereMesh.new(), Vector3(0.08, 1.78, 0.2), Vector3(0.015, 0.015, 0.015), _create_material(Color(0.1, 0.1, 0.1)))
	add_child(right_pupil)

	# 鼻子
	nose = _create_part(BoxMesh.new(), Vector3(0, 1.72, 0.2), Vector3(0.04, 0.06, 0.04), skin_material)
	add_child(nose)

	# 嘴
	mouth = _create_part(BoxMesh.new(), Vector3(0, 1.65, 0.2), Vector3(0.08, 0.02, 0.02), _create_material(Color(0.6, 0.3, 0.3)))
	add_child(mouth)

	# 身体（躯干）
	body = _create_part(CapsuleMesh.new(), Vector3(0, 1.15, 0), Vector3(0.35, 0.4, 0.35), kit_material)
	add_child(body)

	# 左臂
	left_arm = _create_part(CapsuleMesh.new(), Vector3(-0.45, 1.15, 0), Vector3(0.1, 0.35, 0.1), skin_material)
	add_child(left_arm)

	# 右臂
	right_arm = _create_part(CapsuleMesh.new(), Vector3(0.45, 1.15, 0), Vector3(0.1, 0.35, 0.1), skin_material)
	add_child(right_arm)

	# 左腿
	left_leg = _create_part(CapsuleMesh.new(), Vector3(-0.15, 0.45, 0), Vector3(0.13, 0.4, 0.13), skin_material)
	add_child(left_leg)

	# 右腿
	right_leg = _create_part(CapsuleMesh.new(), Vector3(0.15, 0.45, 0), Vector3(0.13, 0.4, 0.13), skin_material)
	add_child(right_leg)

	# 左鞋
	left_shoe = _create_part(BoxMesh.new(), Vector3(-0.15, 0.08, 0.1), Vector3(0.15, 0.08, 0.25), shoe_material)
	add_child(left_shoe)

	# 右鞋
	right_shoe = _create_part(BoxMesh.new(), Vector3(0.15, 0.08, 0.1), Vector3(0.15, 0.08, 0.25), shoe_material)
	add_child(right_shoe)

	# 球衣号码
	jersey_number_label = Label3D.new()
	jersey_number_label.text = "9"
	jersey_number_label.position = Vector3(0, 1.15, -0.36)
	jersey_number_label.rotation = Vector3(0, PI, 0)
	jersey_number_label.font_size = 48
	jersey_number_label.modulate = _get_contrast_color(kit_color)
	add_child(jersey_number_label)

	# 方向箭头
	direction_arrow = MeshInstance3D.new()
	var arrow_mesh = ConeMesh.new()
	arrow_mesh.radius = 0.25
	arrow_mesh.height = 0.4
	direction_arrow.mesh = arrow_mesh
	direction_arrow.position = Vector3(0, 2.3, 0)
	var arrow_mat = StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(1, 1, 0, 0.8)
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color(1, 1, 0)
	arrow_mat.emission_energy_multiplier = 0.5
	arrow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	direction_arrow.material_override = arrow_mat
	direction_arrow.visible = false
	add_child(direction_arrow)

## 创建头发
func _create_hair(style: String):
	match style:
		"short":
			hair = _create_part(SphereMesh.new(), Vector3(0, 1.88, -0.02), Vector3(0.24, 0.15, 0.24), hair_material)
		"short_blonde":
			hair = _create_part(SphereMesh.new(), Vector3(0, 1.88, -0.02), Vector3(0.24, 0.15, 0.24), hair_material)
		"medium_brown":
			hair = _create_part(SphereMesh.new(), Vector3(0, 1.9, 0), Vector3(0.26, 0.2, 0.26), hair_material)
		"curly_black":
			hair = _create_part(SphereMesh.new(), Vector3(0, 1.9, 0), Vector3(0.28, 0.18, 0.28), hair_material)
		"slick_back":
			hair = _create_part(BoxMesh.new(), Vector3(0, 1.9, -0.05), Vector3(0.4, 0.1, 0.35), hair_material)
		"bald":
			return  # 光头
		_:
			hair = _create_part(SphereMesh.new(), Vector3(0, 1.88, -0.02), Vector3(0.24, 0.15, 0.24), hair_material)

	if hair:
		add_child(hair)

## 创建身体部件
func _create_part(mesh: Mesh, pos: Vector3, scale: Vector3, material: Material) -> MeshInstance3D:
	var part = MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	part.scale = scale
	part.material_override = material
	return part

## 创建材质
func _create_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	return mat

## 获取对比色
func _get_contrast_color(color: Color) -> Color:
	var brightness = color.r * 0.299 + color.g * 0.587 + color.b * 0.114
	if brightness > 0.5:
		return Color.BLACK
	else:
		return Color.WHITE

## 设置球衣号码
func set_jersey_number(number: int):
	if jersey_number_label:
		jersey_number_label.text = str(number)

## 设置活跃状态
func set_active(active: bool):
	if direction_arrow:
		direction_arrow.visible = active

## 设置跑步状态
func set_running(running: bool):
	is_running = running
	if running:
		current_anim = "run"
	else:
		current_anim = "idle"

## 触发踢球动画
func play_kick():
	is_kicking = true
	kick_timer = 0
	current_anim = "kick"

## 更新动画
func _process(delta):
	anim_time += delta

	match current_anim:
		"idle":
			_animate_idle(delta)
		"run":
			_animate_run(delta)
		"kick":
			_animate_kick(delta)

## 待机动画
func _animate_idle(delta):
	var breathe = sin(anim_time * 2) * 0.02
	if body:
		body.position.y = 1.15 + breathe
	if head:
		head.position.y = 1.75 + breathe

## 跑步动画
func _animate_run(delta):
	var run_speed = 12.0
	var bounce = abs(sin(anim_time * run_speed)) * 0.08
	if body:
		body.position.y = 1.15 + bounce
	if head:
		head.position.y = 1.75 + bounce

	# 手臂摆动
	if left_arm:
		left_arm.rotation_x = sin(anim_time * run_speed) * 0.6
	if right_arm:
		right_arm.rotation_x = -sin(anim_time * run_speed) * 0.6

	# 腿部摆动
	if left_leg:
		left_leg.rotation_x = -sin(anim_time * run_speed) * 0.5
	if right_leg:
		right_leg.rotation_x = sin(anim_time * run_speed) * 0.5

	# 身体前倾
	if body:
		body.rotation_x = 0.1

## 踢球动画
func _animate_kick(delta):
	kick_timer += delta
	var phase = kick_timer / 0.4

	if phase < 0.5:
		if right_leg:
			right_leg.rotation_x = lerp(0, -1.2, phase * 2)
		if right_arm:
			right_arm.rotation_x = lerp(0, 0.8, phase * 2)
	else:
		if right_leg:
			right_leg.rotation_x = lerp(-1.2, 0.8, (phase - 0.5) * 2)
		if right_arm:
			right_arm.rotation_x = lerp(0.8, -0.5, (phase - 0.5) * 2)

	if phase >= 1.0:
		is_kicking = false
		kick_timer = 0
		current_anim = "idle"
		if right_leg:
			right_leg.rotation_x = 0
		if right_arm:
			right_arm.rotation_x = 0

## 设置朝向
func face_direction(dir: Vector3):
	if dir.length() > 0.01:
		var angle = atan2(dir.x, dir.z)
		rotation.y = angle
