## player_model.gd
## 程序化3D球员模型（v2 - 个性化外观）
## 根据球员ID生成不同外观：身高/体型/发型/肤色
## 例如哈兰德：高大(195cm)、金发、白皮肤
extends Node3D

# 身体部件
var head: MeshInstance3D
var hair: MeshInstance3D
var body: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var jersey_number_label: Label3D

# 材质
var skin_material: StandardMaterial3D
var hair_material: StandardMaterial3D
var kit_material: StandardMaterial3D
var shorts_material: StandardMaterial3D
var shoe_material: StandardMaterial3D

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
	"haaland": {
		"height_mult": 1.15, "body_type": "muscular",
		"skin_tone": Color(0.95, 0.78, 0.6), "hair_style": "short_blonde",
		"hair_color": Color(0.85, 0.75, 0.5),
	},
	"c_ronaldo": {
		"height_mult": 1.08, "body_type": "athletic",
		"skin_tone": Color(0.85, 0.65, 0.5), "hair_style": "slick_back",
		"hair_color": Color(0.15, 0.1, 0.08),
	},
	"messi": {
		"height_mult": 0.92, "body_type": "stocky",
		"skin_tone": Color(0.9, 0.72, 0.55), "hair_style": "medium_brown",
		"hair_color": Color(0.35, 0.25, 0.15),
	},
	"mbappe": {
		"height_mult": 1.05, "body_type": "athletic",
		"skin_tone": Color(0.55, 0.35, 0.25), "hair_style": "short_curly",
		"hair_color": Color(0.1, 0.08, 0.06),
	},
	"vinicius": {
		"height_mult": 1.0, "body_type": "slim",
		"skin_tone": Color(0.4, 0.25, 0.18), "hair_style": "long_dreads",
		"hair_color": Color(0.08, 0.06, 0.05),
	},
	"de_bruyne": {
		"height_mult": 1.05, "body_type": "athletic",
		"skin_tone": Color(0.92, 0.75, 0.58), "hair_style": "short_red",
		"hair_color": Color(0.65, 0.3, 0.15),
	},
	"salah": {
		"height_mult": 1.02, "body_type": "slim",
		"skin_tone": Color(0.75, 0.58, 0.42), "hair_style": "short_black",
		"hair_color": Color(0.1, 0.08, 0.06),
	},
	"vandijk": {
		"height_mult": 1.12, "body_type": "muscular",
		"skin_tone": Color(0.2, 0.12, 0.08), "hair_style": "short_black",
		"hair_color": Color(0.05, 0.03, 0.02),
	},
}

## 默认外观
const DEFAULT_APPEARANCE = {
	"height_mult": 1.0, "body_type": "normal",
	"skin_tone": Color(0.88, 0.7, 0.52), "hair_style": "short_black",
	"hair_color": Color(0.12, 0.1, 0.08),
}

## 创建球员模型
func create_model(player_id: String, kit_color: Color, shorts_color: Color = Color(0.1, 0.1, 0.1)):
	# 获取外观参数
	appearance = PLAYER_APPEARANCES.get(player_id, DEFAULT_APPEARANCE).duplicate()

	var skin_tone = appearance.get("skin_tone", Color(0.88, 0.7, 0.52))
	var hair_color = appearance.get("hair_color", Color(0.12, 0.1, 0.08))
	var height_mult = appearance.get("height_mult", 1.0)
	var body_type = appearance.get("body_type", "normal")

	# 体型参数
	var body_width = 0.35
	var body_depth = 0.35
	match body_type:
		"slim": body_width = 0.3; body_depth = 0.3
		"athletic": body_width = 0.36; body_depth = 0.36
		"muscular": body_width = 0.42; body_depth = 0.4
		"stocky": body_width = 0.4; body_depth = 0.42

	# 创建材质
	skin_material = StandardMaterial3D.new()
	skin_material.albedo_color = skin_tone
	skin_material.roughness = 0.65

	hair_material = StandardMaterial3D.new()
	hair_material.albedo_color = hair_color
	hair_material.roughness = 0.8

	kit_material = StandardMaterial3D.new()
	kit_material.albedo_color = kit_color
	kit_material.roughness = 0.55

	shorts_material = StandardMaterial3D.new()
	shorts_material.albedo_color = shorts_color
	shorts_material.roughness = 0.7

	shoe_material = StandardMaterial3D.new()
	shoe_material.albedo_color = Color(0.05, 0.05, 0.05)
	shoe_material.roughness = 0.4

	var h = height_mult

	# 头部
	head = _create_part(SphereMesh.new(), Vector3(0, 1.7 * h, 0), Vector3(0.22, 0.22, 0.22), skin_material)
	add_child(head)

	# 发型
	_create_hair(h)

	# 身体（躯干）
	body = _create_part(CapsuleMesh.new(), Vector3(0, 1.2 * h, 0), Vector3(body_width, 0.4, body_depth), kit_material)
	add_child(body)

	# 左臂
	left_arm = _create_part(CapsuleMesh.new(), Vector3(-body_width - 0.1, 1.2 * h, 0), Vector3(0.12, 0.35, 0.12), skin_material)
	add_child(left_arm)

	# 右臂
	right_arm = _create_part(CapsuleMesh.new(), Vector3(body_width + 0.1, 1.2 * h, 0), Vector3(0.12, 0.35, 0.12), skin_material)
	add_child(right_arm)

	# 左腿
	left_leg = _create_part(CapsuleMesh.new(), Vector3(-0.15, 0.55 * h, 0), Vector3(0.14, 0.4, 0.14), shorts_material)
	add_child(left_leg)

	# 右腿
	right_leg = _create_part(CapsuleMesh.new(), Vector3(0.15, 0.55 * h, 0), Vector3(0.14, 0.4, 0.14), shorts_material)
	add_child(right_leg)

	# 球鞋
	var left_shoe = _create_part(BoxMesh.new(), Vector3(-0.15, 0.08 * h, 0.1), Vector3(0.16, 0.1, 0.3), shoe_material)
	add_child(left_shoe)
	var right_shoe = _create_part(BoxMesh.new(), Vector3(0.15, 0.08 * h, 0.1), Vector3(0.16, 0.1, 0.3), shoe_material)
	add_child(right_shoe)

	# 球衣号码
	jersey_number_label = Label3D.new()
	jersey_number_label.position = Vector3(0, 1.25 * h, body_depth + 0.01)
	jersey_number_label.font_size = 48
	jersey_number_label.modulate = Color.WHITE
	jersey_number_label.outline_modulate = Color.BLACK
	jersey_number_label.outline_size = 4
	jersey_number_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(jersey_number_label)

## 创建发型
func _create_hair(h: float):
	var style = appearance.get("hair_style", "short_black")
	var head_top = Vector3(0, 1.88 * h, 0)

	match style:
		"short_blonde", "short_red", "short_black":
			# 短发：半球覆盖头顶
			hair = _create_part(SphereMesh.new(), head_top, Vector3(0.24, 0.15, 0.24), hair_material)
			hair.position.y = 1.85 * h
			add_child(hair)
		"medium_brown":
			# 中长发
			hair = _create_part(SphereMesh.new(), head_top, Vector3(0.25, 0.18, 0.25), hair_material)
			hair.position.y = 1.86 * h
			add_child(hair)
		"slick_back":
			# 大背头
			hair = _create_part(BoxMesh.new(), head_top, Vector3(0.24, 0.08, 0.26), hair_material)
			hair.position.y = 1.84 * h
			add_child(hair)
		"short_curly":
			# 卷发
			hair = _create_part(SphereMesh.new(), head_top, Vector3(0.26, 0.16, 0.26), hair_material)
			hair.position.y = 1.87 * h
			add_child(hair)
		"long_dreads":
			# 脏辫
			hair = _create_part(SphereMesh.new(), head_top, Vector3(0.28, 0.2, 0.28), hair_material)
			hair.position.y = 1.85 * h
			add_child(hair)
			# 后面延伸
			var back_hair = _create_part(CapsuleMesh.new(), Vector3(0, 1.7 * h, -0.18), Vector3(0.2, 0.25, 0.1), hair_material)
			add_child(back_hair)

func _create_part(mesh: Mesh, pos: Vector3, scale: Vector3, mat: Material) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	instance.scale = scale
	instance.material_override = mat
	return instance

func _process(delta):
	anim_time += delta

	if is_kicking:
		_animate_kick(delta)
	elif is_tackling:
		_animate_tackle(delta)
	elif is_running:
		_animate_run(delta)
	else:
		_animate_idle(delta)

## 设置球衣号码
func set_jersey_number(num: int):
	if jersey_number_label:
		jersey_number_label.text = str(num)

## 待机动画
func _animate_idle(delta):
	var breathe = sin(anim_time * 2) * 0.02
	body.position.y = 1.2 * appearance.get("height_mult", 1.0) + breathe
	head.position.y = 1.7 * appearance.get("height_mult", 1.0) + breathe
	left_arm.rotation_x = sin(anim_time * 2) * 0.05
	right_arm.rotation_x = -sin(anim_time * 2) * 0.05

## 跑步动画
func _animate_run(delta):
	var run_speed = 10.0
	var h = appearance.get("height_mult", 1.0)
	var bounce = abs(sin(anim_time * run_speed)) * 0.08
	body.position.y = 1.2 * h + bounce
	head.position.y = 1.7 * h + bounce

	left_arm.rotation_x = sin(anim_time * run_speed) * 0.6
	right_arm.rotation_x = -sin(anim_time * run_speed) * 0.6
	left_leg.rotation_x = -sin(anim_time * run_speed) * 0.5
	right_leg.rotation_x = sin(anim_time * run_speed) * 0.5
	body.rotation_x = 0.1

## 踢球动画
func _animate_kick(delta):
	kick_timer += delta
	var h = appearance.get("height_mult", 1.0)
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

## 铲球动画
func _animate_tackle(delta):
	tackle_timer += delta
	var h = appearance.get("height_mult", 1.0)
	var phase = tackle_timer / 0.6

	if phase < 0.4:
		# 身体下蹲
		body.position.y = lerp(1.2 * h, 0.6 * h, phase / 0.4)
		body.rotation_x = lerp(0, 0.5, phase / 0.4)
		left_leg.rotation_x = lerp(0, -0.8, phase / 0.4)
		right_leg.rotation_x = lerp(0, 0.3, phase / 0.4)
	elif phase < 0.7:
		# 铲出
		left_leg.rotation_x = lerp(-0.8, 0.5, (phase - 0.4) / 0.3)
		body.position.y = lerp(0.6 * h, 0.4 * h, (phase - 0.4) / 0.3)
	else:
		# 起身
		body.position.y = lerp(0.4 * h, 1.2 * h, (phase - 0.7) / 0.3)
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
