## player_portrait.gd
## 球员头像生成器
## 程序化生成球员头像（基于球员属性和外观参数）
## 生成不同肤色、发型、面部特征的卡通风格头像
extends Node

## 生成球员头像
func generate_portrait(player_id: String, size: int = 256) -> ImageTexture:
	var player = PlayerDatabase.get_player(player_id)
	if player.is_empty():
		return _generate_default_portrait(size)

	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.25, 0.35, 1))  # 背景色

	# 获取外观参数
	var appearance = _get_player_appearance(player_id)
	var skin_color = appearance.get("skin", Color(0.9, 0.72, 0.55))
	var hair_color = appearance.get("hair", Color(0.2, 0.15, 0.1))
	var hair_style = appearance.get("hair_style", "short")

	# 绘制头像
	_draw_background(image, size, appearance.get("team_color", Color(0.3, 0.3, 0.5)))
	_draw_neck(image, size, skin_color)
	_draw_face(image, size, skin_color)
	_draw_ears(image, size, skin_color)
	_draw_hair(image, size, hair_color, hair_style)
	_draw_eyes(image, size)
	_draw_eyebrows(image, size, hair_color)
	_draw_nose(image, size, skin_color)
	_draw_mouth(image, size)
	_draw_jersey(image, size, appearance.get("team_color", Color(0.3, 0.3, 0.5)))

	return ImageTexture.create_from_image(image)

## 获取球员外观参数
func _get_player_appearance(player_id: String) -> Dictionary:
	# 知名球员外观预设
	var presets = {
		"haaland": {"skin": Color(0.95, 0.78, 0.6), "hair": Color(0.85, 0.75, 0.5), "hair_style": "short_blonde"},
		"c_ronaldo": {"skin": Color(0.85, 0.65, 0.5), "hair": Color(0.15, 0.1, 0.08), "hair_style": "slick_back"},
		"messi": {"skin": Color(0.9, 0.72, 0.55), "hair": Color(0.35, 0.25, 0.15), "hair_style": "medium_brown"},
		"mbappe": {"skin": Color(0.55, 0.35, 0.25), "hair": Color(0.1, 0.08, 0.06), "hair_style": "short_curly"},
		"bellingham": {"skin": Color(0.8, 0.6, 0.45), "hair": Color(0.1, 0.08, 0.06), "hair_style": "short"},
		"vinicius": {"skin": Color(0.4, 0.25, 0.15), "hair": Color(0.1, 0.08, 0.06), "hair_style": "curly_long"},
		"salah": {"skin": Color(0.8, 0.62, 0.45), "hair": Color(0.15, 0.1, 0.08), "hair_style": "short"},
		"vandijk": {"skin": Color(0.3, 0.2, 0.12), "hair": Color(0.05, 0.04, 0.03), "hair_style": "bald"},
		"de_bruyne": {"skin": Color(0.92, 0.75, 0.58), "hair": Color(0.75, 0.65, 0.45), "hair_style": "short_blonde"},
		"kane": {"skin": Color(0.88, 0.7, 0.52), "hair": Color(0.2, 0.15, 0.1), "hair_style": "short"},
		"neuer": {"skin": Color(0.95, 0.78, 0.6), "hair": Color(0.25, 0.2, 0.15), "hair_style": "short"},
	}

	if presets.has(player_id):
		return presets[player_id]

	# 根据国籍生成默认外观
	var player = PlayerDatabase.get_player(player_id)
	var nationality = player.get("nationality", "")
	return _get_default_appearance(nationality)

## 根据国籍生成默认外观
func _get_default_appearance(nationality: String) -> Dictionary:
	var appearances = {
		"巴西": {"skin": Color(0.55, 0.35, 0.25), "hair": Color(0.1, 0.08, 0.06), "hair_style": "curly"},
		"阿根廷": {"skin": Color(0.8, 0.62, 0.45), "hair": Color(0.2, 0.15, 0.1), "hair_style": "medium"},
		"法国": {"skin": Color(0.7, 0.5, 0.38), "hair": Color(0.1, 0.08, 0.06), "hair_style": "short"},
		"英格兰": {"skin": Color(0.9, 0.72, 0.55), "hair": Color(0.3, 0.2, 0.15), "hair_style": "short"},
		"西班牙": {"skin": Color(0.85, 0.65, 0.5), "hair": Color(0.2, 0.15, 0.1), "hair_style": "short"},
		"德国": {"skin": Color(0.92, 0.75, 0.58), "hair": Color(0.3, 0.2, 0.15), "hair_style": "short"},
		"葡萄牙": {"skin": Color(0.82, 0.62, 0.45), "hair": Color(0.15, 0.1, 0.08), "hair_style": "short"},
		"意大利": {"skin": Color(0.85, 0.65, 0.5), "hair": Color(0.2, 0.15, 0.1), "hair_style": "short"},
		"荷兰": {"skin": Color(0.93, 0.76, 0.58), "hair": Color(0.75, 0.65, 0.45), "hair_style": "short"},
		"挪威": {"skin": Color(0.95, 0.8, 0.62), "hair": Color(0.8, 0.7, 0.5), "hair_style": "short_blonde"},
	}
	return appearances.get(nationality, {"skin": Color(0.85, 0.65, 0.5), "hair": Color(0.2, 0.15, 0.1), "hair_style": "short"})

## 绘制背景
func _draw_background(image: Image, size: int, color: Color):
	for y in range(size):
		for x in range(size):
			# 渐变背景
			var t = float(y) / size
			var c = color.lerp(Color(0.1, 0.1, 0.15), t * 0.5)
			image.set_pixel(x, y, c)

## 绘制脖子
func _draw_neck(image: Image, size: int, skin: Color):
	var cx = size / 2
	var neck_top = int(size * 0.75)
	var neck_bottom = int(size * 0.95)
	for y in range(neck_top, neck_bottom):
		for x in range(cx - 25, cx + 25):
			if x >= 0 and x < size and y >= 0 and y < size:
				image.set_pixel(x, y, skin.darkened(0.1))

## 绘制脸部
func _draw_face(image: Image, size: int, skin: Color):
	var cx = size / 2
	var cy = int(size * 0.45)
	var face_w = int(size * 0.28)
	var face_h = int(size * 0.32)

	for y in range(cy - face_h, cy + face_h):
		for x in range(cx - face_w, cx + face_w):
			var dx = float(x - cx) / face_w
			var dy = float(y - cy) / face_h
			if dx * dx + dy * dy <= 1.0:
				if x >= 0 and x < size and y >= 0 and y < size:
					# 脸部阴影
					var shade = 1.0 - dy * 0.15
					image.set_pixel(x, y, skin * shade)

## 绘制耳朵
func _draw_ears(image: Image, size: int, skin: Color):
	var cx = size / 2
	var cy = int(size * 0.45)
	var face_w = int(size * 0.28)
	_draw_circle(image, cx - face_w + 5, cy, 8, skin)
	_draw_circle(image, cx + face_w - 5, cy, 8, skin)

## 绘制头发
func _draw_hair(image: Image, size: int, hair_color: Color, style: String):
	var cx = size / 2
	var cy = int(size * 0.4)
	var face_w = int(size * 0.30)

	match style:
		"short", "short_blonde":
			# 短发
			for y in range(cy - int(size * 0.18), cy - int(size * 0.05)):
				for x in range(cx - face_w, cx + face_w):
					var dx = float(x - cx) / face_w
					var dy = float(y - cy) / (size * 0.18)
					if dx * dx + dy * dy <= 1.0:
						if x >= 0 and x < size and y >= 0 and y < size:
							image.set_pixel(x, y, hair_color)
		"medium", "medium_brown":
			# 中长发
			for y in range(cy - int(size * 0.20), cy + int(size * 0.02)):
				for x in range(cx - face_w - 5, cx + face_w + 5):
					var dx = float(x - cx) / (face_w + 5)
					var dy = float(y - cy) / (size * 0.20)
					if dx * dx + dy * dy <= 1.0:
						if x >= 0 and x < size and y >= 0 and y < size:
							image.set_pixel(x, y, hair_color)
		"curly", "short_curly":
			# 卷发
			for angle in range(0, 360, 15):
				var rad = deg_to_rad(angle)
				for r in range(0, int(size * 0.18), 3):
					var x = int(cx + cos(rad) * r)
					var y = int(cy - int(size * 0.1) + sin(rad) * r * 0.7)
					if x >= 0 and x < size and y >= 0 and y < size:
						_draw_circle(image, x, y, 4, hair_color)
		"curly_long":
			# 长卷发
			for y in range(cy - int(size * 0.20), cy + int(size * 0.15)):
				for x in range(cx - face_w - 10, cx + face_w + 10):
					var dx = float(x - cx) / (face_w + 10)
					var dy = float(y - cy) / (size * 0.25)
					if dx * dx + dy * dy <= 1.0 and dy < 0.3:
						if x >= 0 and x < size and y >= 0 and y < size:
							if randf() > 0.3:
								image.set_pixel(x, y, hair_color)
		"slick_back":
			# 背头
			for y in range(cy - int(size * 0.15), cy - int(size * 0.08)):
				for x in range(cx - face_w, cx + face_w):
					var dx = float(x - cx) / face_w
					var dy = float(y - cy) / (size * 0.15)
					if dx * dx + dy * dy <= 1.0:
						if x >= 0 and x < size and y >= 0 and y < size:
							image.set_pixel(x, y, hair_color)
		"bald":
			# 光头（不画头发）
			pass

## 绘制眼睛
func _draw_eyes(image: Image, size: int):
	var cx = size / 2
	var cy = int(size * 0.42)
	var eye_offset = int(size * 0.08)
	var eye_color = Color.WHITE
	var pupil_color = Color(0.1, 0.1, 0.15)

	# 左眼
	_draw_ellipse(image, cx - eye_offset, cy, 8, 5, eye_color)
	_draw_circle(image, cx - eye_offset, cy, 3, pupil_color)

	# 右眼
	_draw_ellipse(image, cx + eye_offset, cy, 8, 5, eye_color)
	_draw_circle(image, cx + eye_offset, cy, 3, pupil_color)

## 绘制眉毛
func _draw_eyebrows(image: Image, size: int, hair_color: Color):
	var cx = size / 2
	var cy = int(size * 0.36)
	var eye_offset = int(size * 0.08)

	# 左眉
	for x in range(cx - eye_offset - 10, cx - eye_offset + 5):
		for y in range(cy - 2, cy + 2):
			if x >= 0 and x < size and y >= 0 and y < size:
				image.set_pixel(x, y, hair_color)

	# 右眉
	for x in range(cx + eye_offset - 5, cx + eye_offset + 10):
		for y in range(cy - 2, cy + 2):
			if x >= 0 and x < size and y >= 0 and y < size:
				image.set_pixel(x, y, hair_color)

## 绘制鼻子
func _draw_nose(image: Image, size: int, skin: Color):
	var cx = size / 2
	var cy = int(size * 0.5)
	var nose_color = skin.darkened(0.15)

	# 鼻梁
	for y in range(cy - 8, cy + 8):
		image.set_pixel(cx, y, nose_color)
		image.set_pixel(cx - 1, y, nose_color)

	# 鼻头
	_draw_circle(image, cx, cy + 8, 4, nose_color)

## 绘制嘴巴
func _draw_mouth(image: Image, size: int):
	var cx = size / 2
	var cy = int(size * 0.58)
	var mouth_color = Color(0.6, 0.3, 0.3)

	# 嘴巴
	for x in range(cx - 12, cx + 13):
		image.set_pixel(x, cy, mouth_color)
		image.set_pixel(x, cy + 1, mouth_color.darkened(0.2))

## 绘制球衣
func _draw_jersey(image: Image, size: int, color: Color):
	var cx = size / 2
	var jersey_top = int(size * 0.85)

	for y in range(jersey_top, size):
		for x in range(0, size):
			# V领
			if y < jersey_top + 15:
				var neck_width = 15 - (y - jersey_top)
				if abs(x - cx) < neck_width:
					continue
			image.set_pixel(x, y, color)

	# 球衣领口
	for y in range(jersey_top, jersey_top + 15):
		for x in range(cx - 15, cx + 15):
			var dy = y - jersey_top
			if abs(x - cx) < 15 - dy:
				if x >= 0 and x < size and y >= 0 and y < size:
					image.set_pixel(x, y, color.darkened(0.3))

## 绘制圆形
func _draw_circle(image: Image, cx: int, cy: int, radius: int, color: Color):
	for y in range(max(0, cy - radius), min(image.get_height(), cy + radius + 1)):
		for x in range(max(0, cx - radius), min(image.get_width(), cx + radius + 1)):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= radius * radius:
				image.set_pixel(x, y, color)

## 绘制椭圆
func _draw_ellipse(image: Image, cx: int, cy: int, rx: int, ry: int, color: Color):
	for y in range(max(0, cy - ry), min(image.get_height(), cy + ry + 1)):
		for x in range(max(0, cx - rx), min(image.get_width(), cx + rx + 1)):
			var dx = float(x - cx) / rx
			var dy = float(y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				image.set_pixel(x, y, color)

## 生成默认头像
func _generate_default_portrait(size: int) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.3, 0.3, 0.3))
	_draw_circle(image, size/2, size/2, size/3, Color(0.6, 0.6, 0.6))
	return ImageTexture.create_from_image(image)
