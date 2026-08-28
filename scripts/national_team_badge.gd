## national_team_badge.gd
## 国家队图标生成器（世界杯版本）
## 为每支国家队生成世界杯风格的图标
extends Node

## 生成国家队图标
func generate_badge(nationality: String, size: int = 128) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	# 获取国旗颜色
	var colors = _get_flag_colors(nationality)

	# 绘制盾形背景
	_draw_shield(image, size, colors)

	# 绘制世界杯奖杯小图标
	_draw_mini_trophy(image, size)

	return ImageTexture.create_from_image(image)

## 获取国旗颜色
func _get_flag_colors(nationality: String) -> Dictionary:
	var flag_colors = {
		"挪威": {"top": Color(0.8, 0.1, 0.2), "bottom": Color(0.1, 0.2, 0.5), "cross": Color(1, 1, 1)},
		"英格兰": {"top": Color(1, 1, 1), "bottom": Color(0.8, 0.1, 0.2), "cross": Color(0.8, 0.1, 0.2)},
		"法国": {"top": Color(0, 0.2, 0.6), "middle": Color(1, 1, 1), "bottom": Color(0.8, 0.1, 0.2)},
		"西班牙": {"top": Color(0.9, 0.2, 0.2), "bottom": Color(0.9, 0.7, 0.1), "cross": Color(1, 1, 1)},
		"巴西": {"top": Color(0.2, 0.6, 0.2), "bottom": Color(0.9, 0.7, 0.1), "cross": Color(0, 0.4, 0.2)},
		"阿根廷": {"top": Color(0.2, 0.4, 0.8), "bottom": Color(0.2, 0.4, 0.8), "cross": Color(1, 1, 1)},
		"葡萄牙": {"top": Color(0.8, 0.1, 0.2), "bottom": Color(0, 0.2, 0.4), "cross": Color(0.9, 0.7, 0.1)},
		"德国": {"top": Color(0, 0, 0), "middle": Color(0.8, 0.1, 0.2), "bottom": Color(0.9, 0.7, 0.1)},
		"意大利": {"top": Color(0, 0.6, 0.3), "middle": Color(1, 1, 1), "bottom": Color(0.8, 0.1, 0.2)},
		"荷兰": {"top": Color(0.8, 0.1, 0.2), "middle": Color(1, 1, 1), "bottom": Color(0.2, 0.2, 0.6)},
	}
	return flag_colors.get(nationality, {"top": Color(0.5, 0.5, 0.5), "bottom": Color(0.3, 0.3, 0.3), "cross": Color(1, 1, 1)})

## 绘制盾形背景
func _draw_shield(image: Image, size: int, colors: Dictionary):
	var cx = size / 2
	var top = 10
	var bottom = size - 10
	var half_w = size / 2 - 10

	# 绘制盾形
	for y in range(top, bottom):
		var t = float(y - top) / (bottom - top)
		# 盾形宽度变化
		var w = half_w
		if t > 0.7:
			# 底部收窄
			w = half_w * (1.0 - (t - 0.7) / 0.3 * 0.6)

		# 颜色渐变
		var color = colors.top.lerp(colors.bottom, t)

		for x in range(int(cx - w), int(cx + w)):
			if x >= 0 and x < size and y >= 0 and y < size:
				image.set_pixel(x, y, color)

	# 绘制盾形边框（金色）
	_draw_shield_outline(image, size, Color(1.0, 0.84, 0.0))

## 绘制盾形轮廓
func _draw_shield_outline(image: Image, size: int, color: Color):
	var cx = size / 2
	var top = 10
	var bottom = size - 10
	var half_w = size / 2 - 10

	for y in range(top, bottom):
		var t = float(y - top) / (bottom - top)
		var w = half_w
		if t > 0.7:
			w = half_w * (1.0 - (t - 0.7) / 0.3 * 0.6)

		# 左右边框
		for x in [int(cx - w), int(cx + w - 1)]:
			if x >= 0 and x < size and y >= 0 and y < size:
				image.set_pixel(x, y, color)
				if x + 1 < size:
					image.set_pixel(x + 1, y, color)

	# 顶部边框
	for x in range(int(cx - half_w), int(cx + half_w)):
		if x >= 0 and x < size:
			image.set_pixel(x, top, color)
			image.set_pixel(x, top + 1, color)

## 绘制迷你世界杯奖杯
func _draw_mini_trophy(image: Image, size: int):
	var cx = size / 2
	var cy = size / 2
	var gold = Color(1.0, 0.84, 0.0, 1.0)
	var gold_dark = Color(0.7, 0.5, 0.0, 1.0)

	# 奖杯球体
	_draw_circle_filled(image, cx, cy - 8, 10, gold)

	# 奖杯颈部
	for y in range(cy - 2, cy + 6):
		for x in range(cx - 3, cx + 3):
			if x >= 0 and x < size and y >= 0 and y < size:
				image.set_pixel(x, y, gold)

	# 奖杯底座
	for y in range(cy + 6, cy + 14):
		var w = 6 + (y - cy - 6)
		for x in range(cx - w, cx + w):
			if x >= 0 and x < size and y >= 0 and y < size:
				image.set_pixel(x, y, gold_dark)

## 绘制实心圆
func _draw_circle_filled(image: Image, cx: int, cy: int, radius: int, color: Color):
	for y in range(max(0, cy - radius), min(image.get_height(), cy + radius + 1)):
		for x in range(max(0, cx - radius), min(image.get_width(), cx + radius + 1)):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= radius * radius:
				image.set_pixel(x, y, color)
