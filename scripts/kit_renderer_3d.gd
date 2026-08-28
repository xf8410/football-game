## kit_renderer_3d.gd
## 3D球衣渲染器（优化版）
## 在3D球员模型上显示真实球衣颜色、图案和号码
extends Node3D

# 球衣部件
var jersey: MeshInstance3D
var shorts: MeshInstance3D
var socks: MeshInstance3D
var number_label: Label3D
var name_label: Label3D
var sponsor_label: Label3D

# 球衣数据
var kit_data: Dictionary = {}
var jersey_number: int = 0
var player_name: String = ""

## 创建球衣（优化版）
func create_kit(kit: Dictionary, number: int, p_name: String = ""):
	kit_data = kit
	jersey_number = number
	player_name = p_name

	var primary = Color.from_string(kit.get("primary", "#888888"), Color.GRAY)
	var secondary = Color.from_string(kit.get("secondary", "#444444"), Color.DIM_GRAY)

	# 球衣材质（优化：添加细节）
	var jersey_mat = StandardMaterial3D.new()
	jersey_mat.albedo_color = primary
	jersey_mat.roughness = 0.55
	jersey_mat.metallic = 0.05

	# 短裤材质
	var shorts_mat = StandardMaterial3D.new()
	shorts_mat.albedo_color = secondary
	shorts_mat.roughness = 0.7

	# 球袜材质
	var socks_mat = StandardMaterial3D.new()
	socks_mat.albedo_color = primary
	socks_mat.roughness = 0.7

	# 创建球衣（躯干）
	jersey = MeshInstance3D.new()
	var jersey_mesh = CapsuleMesh.new()
	jersey_mesh.radius = 0.38
	jersey_mesh.height = 0.85
	jersey.mesh = jersey_mesh
	jersey.material_override = jersey_mat
	jersey.position = Vector3(0, 1.2, 0)
	add_child(jersey)

	# 应用图案
	_apply_pattern(kit.get("pattern", "solid"), primary, secondary)

	# 短裤
	shorts = MeshInstance3D.new()
	var shorts_mesh = BoxMesh.new()
	shorts_mesh.size = Vector3(0.55, 0.35, 0.45)
	shorts.mesh = shorts_mesh
	shorts.material_override = shorts_mat
	shorts.position = Vector3(0, 0.7, 0)
	add_child(shorts)

	# 球袜（左右）
	socks = MeshInstance3D.new()
	var socks_mesh = BoxMesh.new()
	socks_mesh.size = Vector3(0.5, 0.3, 0.3)
	socks.mesh = socks_mesh
	socks.material_override = socks_mat
	socks.position = Vector3(0, 0.15, 0)
	add_child(socks)

	# 号码标签（背面）
	number_label = Label3D.new()
	number_label.text = str(number)
	number_label.font_size = 80
	number_label.position = Vector3(0, 1.3, -0.39)
	number_label.rotation = Vector3(0, PI, 0)
	number_label.modulate = _get_number_color(primary)
	number_label.outline_size = 3
	number_label.outline_modulate = Color.BLACK
	add_child(number_label)

	# 球员姓名（背面，号码下方）
	if not player_name.is_empty():
		name_label = Label3D.new()
		name_label.text = player_name.to_upper()
		name_label.font_size = 32
		name_label.position = Vector3(0, 0.85, -0.39)
		name_label.rotation = Vector3(0, PI, 0)
		name_label.modulate = _get_number_color(primary)
		name_label.outline_size = 2
		name_label.outline_modulate = Color.BLACK
		add_child(name_label)

	# 赞助商（正面）
	var sponsor = kit.get("sponsor", "")
	if not sponsor.is_empty():
		sponsor_label = Label3D.new()
		sponsor_label.text = sponsor
		sponsor_label.font_size = 28
		sponsor_label.position = Vector3(0, 1.3, 0.39)
		sponsor_label.modulate = _get_number_color(primary)
		sponsor_label.outline_size = 2
		sponsor_label.outline_modulate = Color.BLACK
		add_child(sponsor_label)

## 应用球衣图案
func _apply_pattern(pattern: String, primary: Color, secondary: Color):
	match pattern:
		"stripes":
			# 竖条纹：创建多个细条
			for i in range(5):
				var stripe = MeshInstance3D.new()
				var stripe_mesh = BoxMesh.new()
				stripe_mesh.size = Vector3(0.08, 0.85, 0.02)
				stripe.mesh = stripe_mesh
				var mat = StandardMaterial3D.new()
				mat.albedo_color = secondary
				stripe.material_override = mat
				stripe.position = Vector3(-0.16 + i * 0.08, 1.2, 0.38)
				add_child(stripe)
		"horizontal_stripes":
			# 横条纹
			for i in range(4):
				var stripe = MeshInstance3D.new()
				var stripe_mesh = BoxMesh.new()
				stripe_mesh.size = Vector3(0.76, 0.12, 0.02)
				stripe.mesh = stripe_mesh
				var mat = StandardMaterial3D.new()
				mat.albedo_color = secondary
				stripe.material_override = mat
				stripe.position = Vector3(0, 0.9 + i * 0.2, 0.38)
				add_child(stripe)
		_:
			pass

## 获取号码颜色（与球衣颜色对比）
func _get_number_color(kit_color: Color) -> Color:
	var brightness = kit_color.r * 0.299 + kit_color.g * 0.587 + kit_color.b * 0.114
	if brightness > 0.5:
		return Color.BLACK
	else:
		return Color.WHITE

## 更新球衣
func update_kit(kit: Dictionary, number: int, p_name: String = ""):
	if jersey:
		jersey.queue_free()
	if shorts:
		shorts.queue_free()
	if socks:
		socks.queue_free()
	if number_label:
		number_label.queue_free()
	if name_label:
		name_label.queue_free()
	if sponsor_label:
		sponsor_label.queue_free()

	# 清除图案条纹
	for child in get_children():
		if child is MeshInstance3D and child != jersey and child != shorts and child != socks:
			child.queue_free()

	create_kit(kit, number, p_name)

## 获取球衣颜色
func get_kit_colors() -> Dictionary:
	return {
		"primary": Color.from_string(kit_data.get("primary", "#888888"), Color.GRAY),
		"secondary": Color.from_string(kit_data.get("secondary", "#444444"), Color.DIM_GRAY),
	}
