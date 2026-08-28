## kit_system.gd
## 球衣系统 (Autoload Singleton)
## 功能：球衣数据加载、球衣渲染、主客场选择
extends Node

var kits_data: Dictionary = {}
var current_kit_choice: Dictionary = {}  # team_id -> "home"/"away"/"third"

func _ready():
	_load_kits()

func _load_kits():
	var file = FileAccess.open("res://data/kits.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			kits_data = json.data.get("kits", {})
		file.close()
	print("[KitSystem] 已加载 %d 支球队的球衣" % kits_data.size())

## 获取球队球衣数据
func get_kits(team_id: String) -> Dictionary:
	return kits_data.get(team_id, {})

## 获取指定类型球衣
func get_kit(team_id: String, kit_type: String = "home") -> Dictionary:
	var kits = get_kits(team_id)
	if kits.is_empty():
		# 返回默认球衣
		return {
			"primary": Color(0.5, 0.5, 0.5),
			"secondary": Color(0.3, 0.3, 0.3),
			"pattern": "solid",
			"sponsor": "",
		}
	return kits.get(kit_type, kits.get("home", {}))

## 设置球队球衣选择
func set_kit_choice(team_id: String, kit_type: String):
	current_kit_choice[team_id] = kit_type

## 获取球队当前选择的球衣
func get_current_kit(team_id: String) -> Dictionary:
	var choice = current_kit_choice.get(team_id, "home")
	return get_kit(team_id, choice)

## 获取球衣颜色
func get_kit_colors(team_id: String, kit_type: String = "home") -> Dictionary:
	var kit = get_kit(team_id, kit_type)
	return {
		"primary": Color.from_string(kit.get("primary", "#888888"), Color.GRAY),
		"secondary": Color.from_string(kit.get("secondary", "#444444"), Color.DIM_GRAY),
	}

## 获取球衣图案
func get_kit_pattern(team_id: String, kit_type: String = "home") -> String:
	var kit = get_kit(team_id, kit_type)
	return kit.get("pattern", "solid")

## 获取赞助商
func get_kit_sponsor(team_id: String, kit_type: String = "home") -> String:
	var kit = get_kit(team_id, kit_type)
	return kit.get("sponsor", "")

## 获取所有可用球衣类型
func get_available_kits(team_id: String) -> Array:
	var kits = get_kits(team_id)
	var result = []
	if kits.has("home"):
		result.append("home")
	if kits.has("away"):
		result.append("away")
	if kits.has("third"):
		result.append("third")
	return result

## 生成球衣预览图（用于UI显示）
func generate_kit_preview(team_id: String, kit_type: String, jersey_number: int = 0) -> ImageTexture:
	var kit = get_kit(team_id, kit_type)
	var primary = Color.from_string(kit.get("primary", "#888888"), Color.GRAY)
	var secondary = Color.from_string(kit.get("secondary", "#444444"), Color.DIM_GRAY)
	var pattern = kit.get("pattern", "solid")

	var size = 128
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	# 绘制球衣形状（简化版T恤）
	_draw_jersey(image, size, primary, secondary, pattern)

	# 绘制号码
	if jersey_number > 0:
		_draw_number(image, size, jersey_number, secondary)

	return ImageTexture.create_from_image(image)

## 绘制球衣
func _draw_jersey(image: Image, size: int, primary: Color, secondary: Color, pattern: String):
	var cx = size / 2
	var cy = size / 2

	# 球衣主体（矩形）
	var body_left = cx - 35
	var body_right = cx + 35
	var body_top = cy - 30
	var body_bottom = cy + 40

	# 根据图案绘制
	match pattern:
		"stripes":
			# 竖条纹
			for y in range(body_top, body_bottom):
				for x in range(body_left, body_right):
					if (x - body_left) % 10 < 5:
						image.set_pixel(x, y, primary)
					else:
						image.set_pixel(x, y, secondary)
		"hoops":
			# 横条纹
			for y in range(body_top, body_bottom):
				for x in range(body_left, body_right):
					if (y - body_top) % 10 < 5:
						image.set_pixel(x, y, primary)
					else:
						image.set_pixel(x, y, secondary)
		"sash":
			# 斜带
			for y in range(body_top, body_bottom):
				for x in range(body_left, body_right):
					if abs(x - cx + (y - cy)) < 8:
						image.set_pixel(x, y, secondary)
					else:
						image.set_pixel(x, y, primary)
		_:
			# 纯色
			for y in range(body_top, body_bottom):
				for x in range(body_left, body_right):
					image.set_pixel(x, y, primary)

	# 绘制袖子
	for y in range(body_top - 5, body_top + 15):
		for x in range(body_left - 15, body_left + 5):
			image.set_pixel(x, y, primary)
		for x in range(body_right - 5, body_right + 15):
			image.set_pixel(x, y, primary)

	# 绘制领口
	for y in range(body_top - 3, body_top + 3):
		for x in range(cx - 8, cx + 8):
			if abs(x - cx) < 8 - (y - body_top + 3):
				if x >= 0 and x < size and y >= 0 and y < size:
					image.set_pixel(x, y, secondary)

## 绘制号码
func _draw_number(image: Image, size: int, number: int, color: Color):
	var cx = size / 2
	var cy = size / 2 + 5
	var num_str = str(number)

	# 简化版：用大字号绘制数字
	# 这里用简单的点阵方式
	var digit_size = 3
	var digit_spacing = 8

	for i in range(num_str.length()):
		var digit = int(num_str[i])
		var offset_x = cx + (i - (num_str.length() - 1) / 2.0) * digit_spacing
		_draw_digit(image, digit, int(offset_x), cy, digit_size, color)

## 绘制单个数字（点阵）
func _draw_digit(image: Image, digit: int, cx: int, cy: int, size: int, color: Color):
	# 0-9的点阵定义（7段显示风格）
	var segments = {
		0: [true, true, true, true, true, false, true],
		1: [false, false, true, true, false, false, false],
		2: [true, false, true, true, true, true, false],
		3: [true, false, true, true, true, false, true],
		4: [false, true, true, true, false, true, false],
		5: [true, true, false, true, true, false, true],
		6: [true, true, false, true, true, true, true],
		7: [true, false, true, true, false, false, false],
		8: [true, true, true, true, true, true, true],
		9: [true, true, true, true, true, false, true],
	}

	var seg = segments.get(digit, segments[0])
	var w = size * 2
	var h = size * 4

	# 水平段
	for i in [0, 3, 6]:
		if seg[i]:
			var y = cy - h/2 if i == 0 else (cy if i == 3 else cy + h/2)
			for x in range(cx - w/2, cx + w/2):
				for dy in range(-size/2, size/2 + 1):
					if x >= 0 and x < image.get_width() and y + dy >= 0 and y + dy < image.get_height():
						image.set_pixel(x, y + dy, color)

	# 垂直段
	for i in [1, 2, 4, 5]:
		if seg[i]:
			var x = cx - w/2 if i in [1, 4] else cx + w/2
			var y_start = cy - h/2 if i in [1, 2] else cy
			var y_end = cy if i in [1, 2] else cy + h/2
			for y in range(y_start, y_end):
				for dx in range(-size/2, size/2 + 1):
					if x + dx >= 0 and x + dx < image.get_width() and y >= 0 and y < image.get_height():
						image.set_pixel(x + dx, y, color)
