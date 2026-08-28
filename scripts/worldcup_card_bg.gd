## worldcup_card_bg.gd
## 世界杯风格球员卡背景生成器
## 为球员卡生成世界杯主题的背景图
extends Node

## 生成世界杯风格背景
func generate_worldcup_bg(size: Vector2i = Vector2i(280, 480), is_national: bool = false) -> ImageTexture:
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)

	if is_national:
		_draw_national_card_bg(image, size)
	else:
		_draw_club_card_bg(image, size)

	return ImageTexture.create_from_image(image)

## 国家队卡背景（世界杯风格）
func _draw_national_card_bg(image: Image, size: Vector2i):
	var w = size.x
	var h = size.y

	# 背景渐变（深蓝→金色，世界杯奖杯色调）
	for y in range(h):
		var t = float(y) / h
		var color = Color(
			lerp(0.05, 0.15, t),
			lerp(0.08, 0.12, t),
			lerp(0.2, 0.05, t)
		)
		for x in range(w):
			image.set_pixel(x, y, color)

	# 顶部金色装饰条
	for y in range(0, 8):
		for x in range(w):
			image.set_pixel(x, y, Color(1.0, 0.84, 0.0, 1.0))

	# 底部金色装饰条
	for y in range(h - 8, h):
		for x in range(w):
			image.set_pixel(x, y, Color(1.0, 0.84, 0.0, 1.0))

	# 绘制世界杯奖杯轮廓（简化版）
	_draw_worldcup_trophy(image, w/2, 100, 40)

	# 绘制放射状光线
	_draw_radial_lines(image, w/2, 100, w)

	# 绘制世界杯标志文字
	_draw_text_watermark(image, w/2, h - 50, "WORLD CUP", Color(1.0, 0.84, 0.0, 0.3))

## 俱乐部卡背景
func _draw_club_card_bg(image: Image, size: Vector2i):
	var w = size.x
	var h = size.y

	# 背景渐变（深色）
	for y in range(h):
		var t = float(y) / h
		var color = Color(
			lerp(0.08, 0.03, t),
			lerp(0.1, 0.05, t),
			lerp(0.18, 0.1, t)
		)
		for x in range(w):
			image.set_pixel(x, y, color)

	# 顶部装饰
	for y in range(0, 4):
		for x in range(w):
			image.set_pixel(x, y, Color(0.3, 0.3, 0.4, 1.0))

	# 底部装饰
	for y in range(h - 4, h):
		for x in range(w):
			image.set_pixel(x, y, Color(0.3, 0.3, 0.4, 1.0))

## 绘制世界杯奖杯（简化轮廓）
func _draw_worldcup_trophy(image: Image, cx: int, cy: int, scale: int):
	var gold = Color(1.0, 0.84, 0.0, 0.8)
	var gold_dark = Color(0.8, 0.6, 0.0, 0.8)

	# 奖杯顶部（球形）
	_draw_circle_outline(image, cx, cy - scale, scale, gold)

	# 奖杯中部（细颈）
	for y in range(cy - scale//2, cy + scale//2):
		for x in range(cx - scale//4, cx + scale//4):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, gold)

	# 奖杯底部（底座）
	for y in range(cy + scale//2, cy + scale):
		var half_w = scale//2 + (y - cy - scale//2)
		for x in range(cx - half_w, cx + half_w):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, gold_dark)

## 绘制圆形轮廓
func _draw_circle_outline(image: Image, cx: int, cy: int, radius: int, color: Color):
	var segments = 64
	for i in range(segments):
		var angle1 = float(i) / segments * TAU
		var angle2 = float(i + 1) / segments * TAU
		var x1 = int(cx + cos(angle1) * radius)
		var y1 = int(cy + sin(angle1) * radius)
		var x2 = int(cx + cos(angle2) * radius)
		var y2 = int(cy + sin(angle2) * radius)
		_draw_line(image, x1, y1, x2, y2, color)

## 绘制直线
func _draw_line(image: Image, x1: int, y1: int, x2: int, y2: int, color: Color):
	var dx = abs(x2 - x1)
	var dy = abs(y2 - y1)
	var sx = 1 if x1 < x2 else -1
	var sy = 1 if y1 < y2 else -1
	var err = dx - dy
	var x = x1
	var y = y1
	while true:
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)
		if x == x2 and y == y2:
			break
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy

## 绘制放射状光线
func _draw_radial_lines(image: Image, cx: int, cy: int, max_radius: int):
	var gold_faint = Color(1.0, 0.84, 0.0, 0.1)
	for angle in range(0, 360, 30):
		var rad = deg_to_rad(angle)
		for r in range(50, max_radius, 2):
			var x = int(cx + cos(rad) * r)
			var y = int(cy + sin(rad) * r)
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, gold_faint)

## 绘制文字水印（简化版，用点阵）
func _draw_text_watermark(image: Image, cx: int, cy: int, text: String, color: Color):
	# 简化：在指定位置画一条装饰线
	for x in range(cx - 60, cx + 60):
		for y in range(cy - 1, cy + 2):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)
