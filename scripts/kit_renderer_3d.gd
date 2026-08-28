## kit_renderer_3d.gd
## 3D球衣渲染器
## 在3D球员模型上显示真实球衣颜色和号码
extends Node3D

# 球衣部件
var jersey: MeshInstance3D
var shorts: MeshInstance3D
var number_label: Label3D
var socks: MeshInstance3D

# 球衣数据
var kit_data: Dictionary = {}
var jersey_number: int = 0

## 创建球衣
func create_kit(kit: Dictionary, number: int):
	kit_data = kit
	jersey_number = number

	var primary = Color.from_string(kit.get("primary", "#888888"), Color.GRAY)
	var secondary = Color.from_string(kit.get("secondary", "#444444"), Color.DIM_GRAY)

	# 球衣材质
	var jersey_mat = StandardMaterial3D.new()
	jersey_mat.albedo_color = primary
	jersey_mat.roughness = 0.6

	# 短裤材质
	var shorts_mat = StandardMaterial3D.new()
	shorts_mat.albedo_color = secondary
	shorts_mat.roughness = 0.7

	# 球袜材质
	var socks_mat = StandardMaterial3D.new()
	socks_mat.albedo_color = primary
	socks_mat.roughness = 0.7

	# 创建球衣网格（躯干部分）
	jersey = MeshInstance3D.new()
	var jersey_mesh = CapsuleMesh.new()
	jersey_mesh.radius = 0.35
	jersey_mesh.height = 0.8
	jersey.mesh = jersey_mesh
	jersey.material_override = jersey_mat
	jersey.position = Vector3(0, 1.2, 0)
	add_child(jersey)

	# 根据图案调整球衣
	var pattern = kit.get("pattern", "solid")
	_apply_pattern(pattern, primary, secondary)

	# 创建短裤
	shorts = MeshInstance3D.new()
	var shorts_mesh = BoxMesh.new()
	shorts_mesh.size = Vector3(0.5, 0.3, 0.4)
	shorts.mesh = shorts_mesh
	shorts.material_override = shorts_mat
	shorts.position = Vector3(0, 0.7, 0)
	add_child(shorts)

	# 创建球袜
	socks = MeshInstance3D.new()
	var socks_mesh = CylinderMesh.new()
	socks_mesh.top_radius = 0.12
	socks_mesh.bottom_radius = 0.1
	socks_mesh.height = 0.3
	socks.mesh = socks_mesh
	socks.material_override = socks_mat
	socks.position = Vector3(0, 0.15, 0)
	add_child(socks)

	# 创建号码标签
	number_label = Label3D.new()
	number_label.text = str(number)
	number_label.font_size = 64
	number_label.position = Vector3(0, 1.2, -0.36)
	number_label.rotation = Vector3(0, PI, 0)  # 背面
	number_label.modulate = _get_number_color(primary)
	add_child(number_label)

## 应用球衣图案
func _apply_pattern(pattern: String, primary: Color, secondary: Color):
	match pattern:
		"stripes":
			# 竖条纹：创建条纹材质
			var mat = StandardMaterial3D.new()
			mat.albedo_color = primary
			jersey.material_override = mat
		"horizontal_stripes":
			# 横条纹
			var mat = StandardMaterial3D.new()
			mat.albedo_color = primary
			jersey.material_override = mat
		_:
			# 纯色
			pass

## 获取号码颜色（与球衣颜色对比）
func _get_number_color(kit_color: Color) -> Color:
	# 计算亮度
	var brightness = kit_color.r * 0.299 + kit_color.g * 0.587 + kit_color.b * 0.114
	if brightness > 0.5:
		return Color.BLACK  # 浅色球衣用黑色号码
	else:
		return Color.WHITE  # 深色球衣用白色号码

## 更新球衣
func update_kit(kit: Dictionary, number: int):
	# 移除旧球衣
	if jersey:
		jersey.queue_free()
	if shorts:
		shorts.queue_free()
	if socks:
		socks.queue_free()
	if number_label:
		number_label.queue_free()

	# 创建新球衣
	create_kit(kit, number)

## 获取球衣颜色
func get_kit_colors() -> Dictionary:
	return {
		"primary": Color.from_string(kit_data.get("primary", "#888888"), Color.GRAY),
		"secondary": Color.from_string(kit_data.get("secondary", "#444444"), Color.DIM_GRAY),
	}
