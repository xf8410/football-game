## player_model.gd
## 程序化3D球员模型（v3 - 精细面部版）
## 新增：面部特征（眼睛/鼻子/嘴/眉毛）、球衣号码、球鞋
extends Node3D

# 身体部件
var head: MeshInstance3D
var face: MeshInstance3D
var left_eye: MeshInstance3D
var right_eye: MeshInstance3D
var nose: MeshInstance3D
var mouth: MeshInstance3D
var left_eyebrow: MeshInstance3D
var right_eyebrow: MeshInstance3D
var hair: MeshInstance3D
var body: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var left_shoe: MeshInstance3D
var right_shoe: MeshInstance3D
var jersey_number_label: Label3D

# 材质
var skin_material: StandardMaterial3D
var hair_material: StandardMaterial3D
var kit_material: StandardMaterial3D
var shorts_material: StandardMaterial3D
var shoe_material: StandardMaterial3D
var eye_material: StandardMaterial3D
var mouth_material: StandardMaterial3D

# 球员外观参数
var appearance: Dictionary = {}

# 动画状态
var anim_time: float = 0.0
var is_running: bool = false
var is_kicking: bool = false
var kick_timer: float = 0.0
var is_tackling: bool = false
var tackle_timer: float = 0.0

## 知名球员外观预设
const PLAYER_APPEARANCES = {
	"haaland": {"height_mult": 1.15, "body_type": "muscular", "skin_tone": Color(0.95, 0.78, 0.6), "hair_style": "short_blonde", "hair_color": Color(0.85, 0.75, 0.5), "eye_color": Color(0.3, 0.4, 0.6)},
	"c_ronaldo": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": Color(0.85, 0.65, 0.5), "hair_style": "slick_back", "hair_color": Color(0.15, 0.1, 0.08), "eye_color": Color(0.4, 0.3, 0.2)},
	"messi": {"height_mult": 0.92, "body_type": "stocky", "skin_tone": Color(0.9, 0.72, 0.55), "hair_style": "medium_brown", "hair_color": Color(0.35, 0.25, 0.15), "eye_color": Color(0.3, 0.4, 0.5)},
	"mbappe": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": Color(0.55, 0.35, 0.25), "hair_style": "short_curly", "hair_color": Color(0.1, 0.08, 0.06), "eye_color": Color(0.2, 0.2, 0.2)},
	"de_bruyne": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": Color(0.9, 0.75, 0.6), "hair_style": "short_red", "hair_color": Color(0.75, 0.35, 0.2), "eye_color": Color(0.3, 0.4, 0.5)},
	"vinicius": {"height_mult": 1.0, "body_type": "slim", "skin_tone": Color(0.4, 0.25, 0.15), "hair_style": "long_curly", "hair_color": Color(0.1, 0.08, 0.06), "eye_color": Color(0.2, 0.2, 0.2)},
	"salah": {"height_mult": 1.0, "body_type": "muscular", "skin_tone": Color(0.75, 0.55, 0.4), "hair_style": "short_black", "hair_color": Color(0.1, 0.08, 0.06), "eye_color": Color(0.2, 0.2, 0.2)},
	"bellingham": {"height_mult": 1.1, "body_type": "athletic", "skin_tone": Color(0.6, 0.45, 0.35), "hair_style": "short_curly", "hair_color": Color(0.1, 0.08, 0.06), "eye_color": Color(0.2, 0.2, 0.2)},
	"neuer": {"height_mult": 1.15, "body_type": "athletic", "skin_tone": Color(0.9, 0.75, 0.6), "hair_style": "short_brown", "hair_color": Color(0.3, 0.2, 0.1), "eye_color": Color(0.3, 0.4, 0.5)},
}

## 创建球员模型
func create_model(kit_color: Color, shorts_color: Color = Color(0.1, 0.1, 0.1), skin_tone: Color = Color(0.9, 0.7, 0.5), player_id: String = ""):
	# 获取外观参数
	if PLAYER_APPEARANCES.has(player_id):
		appearance = PLAYER_APPEARANCES[player_id]
	else:
		appearance = {
			"height_mult": randf_range(0.95, 1.1),
			"body_type": "normal",
			"skin_tone": skin_tone,
			"hair_style": ["short_black", "short_brown", "medium_brown"].pick_random(),
			"hair_color": Color(0.2, 0.15, 0.1),
			"eye_color": Color(0.3, 0.3, 0.3),
		}

	var h = appearance.get("height_mult", 1.0)

	# 创建材质
	skin_material = StandardMaterial3D.new()
	skin_material.albedo_color = appearance.get("skin_tone", skin_tone)
	skin_material.roughness = 0.7

	hair_material = StandardMaterial3D.new()
	hair_material.albedo_color = appearance.get("hair_color", Color(0.2, 0.15, 0.1))
	hair_material.roughness = 0.8

	kit_material = StandardMaterial3D.new()
	kit_material.albedo_color = kit_color
	kit_material.roughness = 0.6

	shorts_material = StandardMaterial3D.new()
	shorts_material.albedo_color = shorts_color
	shorts_material.roughness = 0.7

	shoe_material = StandardMaterial3D.new()
	shoe_material.albedo_color = Color(0.05, 0.05, 0.05)
	shoe_material.roughness = 0.4
	shoe_material.metallic = 0.1

	eye_material = StandardMaterial3D.new()
	eye_material.albedo_color = appearance.get("eye_color", Color(0.3, 0.3, 0.3))
	eye_material.roughness = 0.3

	mouth_material = StandardMaterial3D.new()
	mouth_material.albedo_color = Color(0.5, 0.2, 0.2)
	mouth_material.roughness = 0.6

	# 创建身体部件
	_create_head(h)
	_create_face_features(h)
	_create_hair(h)
	_create_body(h)
	_create_limbs(h)
	_create_jersey_number(kit_color)

## 创建头部
func _create_head(h: float):
	head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.18
	head_mesh.height = 0.36
	head.mesh = head_mesh
	head.position = Vector3(0, 1.7 * h, 0)
	head.material_override = skin_material
	add_child(head)

	# 脖子
	var neck = MeshInstance3D.new()
	var neck_mesh = CylinderMesh.new()
	neck_mesh.top_radius = 0.08
	neck_mesh.bottom_radius = 0.1
	neck_mesh.height = 0.12
	neck.mesh = neck_mesh
	neck.position = Vector3(0, 1.5 * h, 0)
	neck.material_override = skin_material
	add_child(neck)

## 创建面部特征
func _create_face_features(h: float):
	# 眼睛
	var eye_y = 1.72 * h
	var eye_z = 0.15
	var eye_offset_x = 0.06

	left_eye = MeshInstance3D.new()
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = 0.025
	eye_mesh.height = 0.05
	left_eye.mesh = eye_mesh
	left_eye.position = Vector3(-eye_offset_x, eye_y, eye_z)
	left_eye.material_override = eye_material
	add_child(left_eye)

	right_eye = MeshInstance3D.new()
	right_eye.mesh = eye_mesh.duplicate()
	right_eye.position = Vector3(eye_offset_x, eye_y, eye_z)
	right_eye.material_override = eye_material
	add_child(right_eye)

	# 眉毛
	var brow_y = 1.76 * h
	var brow_mesh = BoxMesh.new()
	brow_mesh.size = Vector3(0.06, 0.015, 0.02)

	left_eyebrow = MeshInstance3D.new()
	left_eyebrow.mesh = brow_mesh
	left_eyebrow.position = Vector3(-eye_offset_x, brow_y, eye_z - 0.005)
	left_eyebrow.material_override = hair_material
	add_child(left_eyebrow)

	right_eyebrow = MeshInstance3D.new()
	right_eyebrow.mesh = brow_mesh.duplicate()
	right_eyebrow.position = Vector3(eye_offset_x, brow_y, eye_z - 0.005)
	right_eyebrow.material_override = hair_material
	add_child(right_eyebrow)

	# 鼻子
	nose = MeshInstance3D.new()
	var nose_mesh = BoxMesh.new()
	nose_mesh.size = Vector3(0.04, 0.06, 0.04)
	nose.mesh = nose_mesh
	nose.position = Vector3(0, 1.68 * h, eye_z + 0.02)
	nose.material_override = skin_material
	add_child(nose)

	# 嘴
	mouth = MeshInstance3D.new()
	var mouth_mesh = BoxMesh.new()
	mouth_mesh.size = Vector3(0.08, 0.02, 0.02)
	mouth.mesh = mouth_mesh
	mouth.position = Vector3(0, 1.62 * h, eye_z + 0.01)
	mouth.material_override = mouth_material
	add_child(mouth)

## 创建头发
func _create_hair(h: float):
	hair = MeshInstance3D.new()
	var hair_style = appearance.get("hair_style", "short_black")

	match hair_style:
		"short_black", "short_brown", "short_red":
			var hair_mesh = SphereMesh.new()
			hair_mesh.radius = 0.19
			hair_mesh.height = 0.2
			hair.mesh = hair_mesh
			hair.position = Vector3(0, 1.78 * h, -0.02)
		"short_blonde":
			var hair_mesh = SphereMesh.new()
			hair_mesh.radius = 0.185
			hair_mesh.height = 0.18
			hair.mesh = hair_mesh
			hair.position = Vector3(0, 1.77 * h, -0.02)
		"slick_back":
			var hair_mesh = SphereMesh.new()
			hair_mesh.radius = 0.19
			hair_mesh.height = 0.16
			hair.mesh = hair_mesh
			hair.position = Vector3(0, 1.76 * h, -0.03)
		"medium_brown":
			var hair_mesh = SphereMesh.new()
			hair_mesh.radius = 0.2
			hair_mesh.height = 0.24
			hair.mesh = hair_mesh
			hair.position = Vector3(0, 1.79 * h, -0.02)
		"short_curly":
			var hair_mesh = SphereMesh.new()
			hair_mesh.radius = 0.21
			hair_mesh.height = 0.22
			hair.mesh = hair_mesh
			hair.position = Vector3(0, 1.78 * h, -0.01)
		"long_curly":
			var hair_mesh = SphereMesh.new()
			hair_mesh.radius = 0.22
			hair_mesh.height = 0.3
			hair.mesh = hair_mesh
			hair.position = Vector3(0, 1.8 * h, -0.02)
		_:
			var hair_mesh = SphereMesh.new()
			hair_mesh.radius = 0.19
			hair_mesh.height = 0.2
			hair.mesh = hair_mesh
			hair.position = Vector3(0, 1.78 * h, -0.02)

	hair.material_override = hair_material
	add_child(hair)

## 创建身体
func _create_body(h: float):
	body = MeshInstance3D.new()
	var body_mesh = CapsuleMesh.new()
	var body_type = appearance.get("body_type", "normal")
	match body_type:
		"muscular":
			body_mesh.radius = 0.22
			body_mesh.height = 0.5
		"athletic":
			body_mesh.radius = 0.2
			body_mesh.height = 0.5
		"stocky":
			body_mesh.radius = 0.24
			body_mesh.height = 0.45
		"slim":
			body_mesh.radius = 0.18
			body_mesh.height = 0.52
		_:
			body_mesh.radius = 0.2
			body_mesh.height = 0.5
	body.mesh = body_mesh
	body.position = Vector3(0, 1.15 * h, 0)
	body.material_override = kit_material
	add_child(body)

## 创建四肢
func _create_limbs(h: float):
	# 手臂
	var arm_y = 1.2 * h
	var arm_offset = 0.28
	var arm_mesh = CapsuleMesh.new()
	arm_mesh.radius = 0.07
	arm_mesh.height = 0.35

	left_arm = MeshInstance3D.new()
	left_arm.mesh = arm_mesh
	left_arm.position = Vector3(-arm_offset, arm_y, 0)
	left_arm.material_override = kit_material
	add_child(left_arm)

	right_arm = MeshInstance3D.new()
	right_arm.mesh = arm_mesh.duplicate()
	right_arm.position = Vector3(arm_offset, arm_y, 0)
	right_arm.material_override = kit_material
	add_child(right_arm)

	# 腿
	var leg_y = 0.7 * h
	var leg_offset = 0.1
	var leg_mesh = CapsuleMesh.new()
	leg_mesh.radius = 0.09
	leg_mesh.height = 0.5

	left_leg = MeshInstance3D.new()
	left_leg.mesh = leg_mesh
	left_leg.position = Vector3(-leg_offset, leg_y, 0)
	left_leg.material_override = shorts_material
	add_child(left_leg)

	right_leg = MeshInstance3D.new()
	right_leg.mesh = leg_mesh.duplicate()
	right_leg.position = Vector3(leg_offset, leg_y, 0)
	right_leg.material_override = shorts_material
	add_child(right_leg)

	# 球鞋
	var shoe_y = 0.4 * h
	var shoe_mesh = BoxMesh.new()
	shoe_mesh.size = Vector3(0.12, 0.08, 0.25)

	left_shoe = MeshInstance3D.new()
	left_shoe.mesh = shoe_mesh
	left_shoe.position = Vector3(-leg_offset, shoe_y, 0.05)
	left_shoe.material_override = shoe_material
	add_child(left_shoe)

	right_shoe = MeshInstance3D.new()
	right_shoe.mesh = shoe_mesh.duplicate()
	right_shoe.position = Vector3(leg_offset, shoe_y, 0.05)
	right_shoe.material_override = shoe_material
	add_child(right_shoe)

## 创建球衣号码
func _create_jersey_number(kit_color: Color):
	jersey_number_label = Label3D.new()
	jersey_number_label.text = "10"
	jersey_number_label.font_size = 64
	jersey_number_label.outline_size = 12
	jersey_number_label.outline_modulate = Color.BLACK
	jersey_number_label.modulate = Color.WHITE if kit_color.get_luminance() < 0.5 else Color.BLACK
	jersey_number_label.position = Vector3(0, 1.15, -0.25)
	jersey_number_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(jersey_number_label)

## 设置球衣号码
func set_jersey_number(num: int):
	if jersey_number_label:
		jersey_number_label.text = str(num)

func _physics_process(delta):
	anim_time += delta

	if is_kicking:
		_animate_kick(delta)
	elif is_tackling:
		_animate_tackle(delta)
	elif is_running:
		_animate_run(delta)
	else:
		_animate_idle(delta)

func _animate_idle(delta):
	var h = appearance.get("height_mult", 1.0)
	var breathe = sin(anim_time * 2) * 0.02
	body.position.y = 1.15 * h + breathe
	head.position.y = 1.7 * h + breathe
	left_arm.rotation_x = sin(anim_time * 2) * 0.05
	right_arm.rotation_x = -sin(anim_time * 2) * 0.05

func _animate_run(delta):
	var h = appearance.get("height_mult", 1.0)
	var run_speed = 10.0
	var bounce = abs(sin(anim_time * run_speed)) * 0.08
	body.position.y = 1.15 * h + bounce
	head.position.y = 1.7 * h + bounce

	left_arm.rotation_x = sin(anim_time * run_speed) * 0.6
	right_arm.rotation_x = -sin(anim_time * run_speed) * 0.6
	left_leg.rotation_x = -sin(anim_time * run_speed) * 0.5
	right_leg.rotation_x = sin(anim_time * run_speed) * 0.5
	body.rotation_x = 0.1

func _animate_kick(delta):
	var h = appearance.get("height_mult", 1.0)
	kick_timer += delta
	var kick_phase = kick_timer / 0.4

	if kick_phase < 0.5:
		right_leg.rotation_x = lerp(0, -1.2, kick_phase * 2)
		right_arm.rotation_x = lerp(0, 0.8, kick_phase * 2)
	else:
		right_leg.rotation_x = lerp(-1.2, 0.8, (kick_phase - 0.5) * 2)
		right_arm.rotation_x = lerp(0.8, -0.5, (kick_phase - 0.5) * 2)

	if kick_phase >= 1.0:
		is_kicking = false
		kick_timer = 0
		right_leg.rotation_x = 0
		right_arm.rotation_x = 0

func _animate_tackle(delta):
	var h = appearance.get("height_mult", 1.0)
	tackle_timer += delta
	var phase = tackle_timer / 0.6

	if phase < 0.4:
		body.position.y = lerp(1.15 * h, 0.6 * h, phase / 0.4)
		body.rotation_x = lerp(0, 0.5, phase / 0.4)
		left_leg.rotation_x = lerp(0, -0.8, phase / 0.4)
		right_leg.rotation_x = lerp(0, 0.3, phase / 0.4)
	elif phase < 0.7:
		left_leg.rotation_x = lerp(-0.8, 0.5, (phase - 0.4) / 0.3)
		body.position.y = lerp(0.6 * h, 0.4 * h, (phase - 0.4) / 0.3)
	else:
		body.position.y = lerp(0.4 * h, 1.15 * h, (phase - 0.7) / 0.3)
		body.rotation_x = lerp(0.5, 0, (phase - 0.7) / 0.3)
		left_leg.rotation_x = lerp(0.5, 0, (phase - 0.7) / 0.3)
		right_leg.rotation_x = lerp(0.3, 0, (phase - 0.7) / 0.3)

	if phase >= 1.0:
		is_tackling = false
		tackle_timer = 0

func play_kick():
	is_kicking = true
	kick_timer = 0

func play_tackle():
	is_tackling = true
	tackle_timer = 0

func set_running(running: bool):
	is_running = running
	if not running and not is_kicking and not is_tackling:
		left_leg.rotation_x = 0
		right_leg.rotation_x = 0
		left_arm.rotation_x = 0
		right_arm.rotation_x = 0
		body.rotation_x = 0

func face_direction(dir: Vector3):
	if dir.length() > 0.01:
		var angle = atan2(dir.x, dir.z)
		rotation.y = angle
