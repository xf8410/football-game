## player_model.gd
## 程序化3D球员模型生成器
## 使用Godot内置基本几何体组装成人形模型
## 参考《最佳球会》的写实风格（简化版）
extends Node3D

# 身体部件
var head: MeshInstance3D
var body: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var jersey_number: Label3D

# 材质
var skin_material: StandardMaterial3D
var kit_material: StandardMaterial3D
var shorts_material: StandardMaterial3D

# 动画状态
var anim_time: float = 0.0
var is_running: bool = false
var is_kicking: bool = false
var kick_timer: float = 0.0

## 创建球员模型
func create_model(kit_color: Color, shorts_color: Color = Color(0.1, 0.1, 0.1), skin_tone: Color = Color(0.9, 0.7, 0.5)):
	# 创建材质
	skin_material = StandardMaterial3D.new()
	skin_material.albedo_color = skin_tone
	skin_material.roughness = 0.7

	kit_material = StandardMaterial3D.new()
	kit_material.albedo_color = kit_color
	kit_material.roughness = 0.6

	shorts_material = StandardMaterial3D.new()
	shorts_material.albedo_color = shorts_color
	shorts_material.roughness = 0.7

	# 头部
	head = _create_body_part(
		SphereMesh.new(),
		Vector3(0, 1.7, 0),
		Vector3(0.22, 0.22, 0.22),
		skin_material
	)
	add_child(head)

	# 身体（躯干）
	body = _create_body_part(
		CapsuleMesh.new(),
		Vector3(0, 1.2, 0),
		Vector3(0.35, 0.4, 0.35),
		kit_material
	)
	add_child(body)

	# 左臂
	left_arm = _create_body_part(
		CapsuleMesh.new(),
		Vector3(-0.45, 1.2, 0),
		Vector3(0.12, 0.35, 0.12),
		skin_material
	)
	add_child(left_arm)

	# 右臂
	right_arm = _create_body_part(
		CapsuleMesh.new(),
		Vector3(0.45, 1.2, 0),
		Vector3(0.12, 0.35, 0.12),
		skin_material
	)
	add_child(right_arm)

	# 左腿
	left_leg = _create_body_part(
		CapsuleMesh.new(),
		Vector3(-0.18, 0.5, 0),
		Vector3(0.14, 0.4, 0.14),
		shorts_material
	)
	add_child(left_leg)

	# 右腿
	right_leg = _create_body_part(
		CapsuleMesh.new(),
		Vector3(0.18, 0.5, 0),
		Vector3(0.14, 0.4, 0.14),
		shorts_material
	)
	add_child(right_leg)

	# 球衣号码（3D文字）
	jersey_number = Label3D.new()
	jersey_number.text = "10"
	jersey_number.font_size = 64
	jersey_number.position = Vector3(0, 1.25, 0.36)
	jersey_number.modulate = Color.WHITE
	jersey_number.outline_modulate = Color.BLACK
	jersey_number.outline_size = 4
	add_child(jersey_number)

## 创建身体部件
func _create_body_part(mesh: Mesh, pos: Vector3, scale: Vector3, material: Material) -> MeshInstance3D:
	var part = MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	part.scale = scale
	part.material_override = material
	return part

## 设置球衣号码
func set_jersey_number(num: int):
	if jersey_number:
		jersey_number.text = str(num)

## 设置球衣颜色
func set_kit_color(color: Color):
	if kit_material:
		kit_material.albedo_color = color

## 设置门将服装（不同颜色）
func set_goalkeeper_kit(color: Color):
	set_kit_color(color)
	if shorts_material:
		shorts_material.albedo_color = color.darkened(0.3)

## 更新动画
func _process(delta):
	anim_time += delta

	if is_kicking:
		_animate_kick(delta)
	elif is_running:
		_animate_run(delta)
	else:
		_animate_idle(delta)

## 待机动画
func _animate_idle(delta):
	var breathe = sin(anim_time * 2) * 0.02
	body.position.y = 1.2 + breathe
	head.position.y = 1.7 + breathe

	# 手臂轻微摆动
	left_arm.rotation_x = sin(anim_time * 2) * 0.05
	right_arm.rotation_x = -sin(anim_time * 2) * 0.05

## 跑步动画
func _animate_run(delta):
	var run_speed = 10.0
	var bounce = abs(sin(anim_time * run_speed)) * 0.08
	body.position.y = 1.2 + bounce
	head.position.y = 1.7 + bounce

	# 手臂前后摆动
	left_arm.rotation_x = sin(anim_time * run_speed) * 0.6
	right_arm.rotation_x = -sin(anim_time * run_speed) * 0.6

	# 腿部交替摆动
	left_leg.rotation_x = -sin(anim_time * run_speed) * 0.5
	right_leg.rotation_x = sin(anim_time * run_speed) * 0.5

	# 身体前倾
	body.rotation_x = 0.1

## 踢球动画
func _animate_kick(delta):
	kick_timer += delta
	var kick_phase = kick_timer / 0.4  # 0.4秒踢球动画

	if kick_phase < 0.5:
		# 抬腿
		right_leg.rotation_x = lerp(0, -1.2, kick_phase * 2)
		right_arm.rotation_x = lerp(0, 0.8, kick_phase * 2)
	else:
		# 踢出
		right_leg.rotation_x = lerp(-1.2, 0.8, (kick_phase - 0.5) * 2)
		right_arm.rotation_x = lerp(0.8, -0.5, (kick_phase - 0.5) * 2)

	if kick_phase >= 1.0:
		is_kicking = false
		kick_timer = 0
		right_leg.rotation_x = 0
		right_arm.rotation_x = 0

## 触发踢球动画
func play_kick():
	is_kicking = true
	kick_timer = 0

## 设置跑步状态
func set_running(running: bool):
	is_running = running
	if not running:
		left_leg.rotation_x = 0
		right_leg.rotation_x = 0
		left_arm.rotation_x = 0
		right_arm.rotation_x = 0
		body.rotation_x = 0

## 设置朝向
func face_direction(dir: Vector3):
	if dir.length() > 0.01:
		var angle = atan2(dir.x, dir.z)
		rotation.y = angle
