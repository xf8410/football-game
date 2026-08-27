## icon_generator.gd
## 特性/技能图标生成器
## 程序化生成金银铜分级图标（无需外部图片资源）
extends Node

## 生成特性图标
func generate_trait_icon(trait_id: String, tier: String) -> ImageTexture:
	var trait = TeamSpecialties.get_trait(trait_id)
	var icon_color = Color.from_string(trait.get("icon_color", "#FFFFFF"), Color.WHITE)
	var tier_color = TeamSpecialties.get_tier_color(tier)

	var size = 128
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	# 绘制背景圆（等级颜色）
	_draw_circle(image, size/2, size/2, size/2 - 4, tier_color)

	# 绘制内圆（特性颜色）
	_draw_circle(image, size/2, size/2, size/2 - 12, icon_color)

	# 绘制图标符号（根据特性类型）
	_draw_trait_symbol(image, trait_id, size)

	# 绘制等级边框装饰
	_draw_tier_decoration(image, tier, size)

	var texture = ImageTexture.create_from_image(image)
	return texture

## 绘制圆形
func _draw_circle(image: Image, cx: int, cy: int, radius: int, color: Color):
	for y in range(max(0, cy - radius), min(image.get_height(), cy + radius + 1)):
		for x in range(max(0, cx - radius), min(image.get_width(), cx + radius + 1)):
			var dx = x - cx
			var dy = y - cy
			if dx * dx + dy * dy <= radius * radius:
				image.set_pixel(x, y, color)

## 绘制特性符号
func _draw_trait_symbol(image: Image, trait_id: String, size: int):
	var center = size / 2
	var white = Color.WHITE

	match trait_id:
		"long_shot":
			# 闪电符号
			_draw_lightning(image, center, center, white)
		"free_kick":
			# 球+弧线
			_draw_circle(image, center, center, 20, white)
			_draw_arc(image, center, center, 30, white)
		"header":
			# 球+向下箭头
			_draw_circle(image, center, center - 10, 18, white)
			_draw_arrow_down(image, center, center + 15, white)
		"speedster":
			# 双箭头
			_draw_double_arrow(image, center, center, white)
		"playmaker":
			# 棋盘格（战术）
			_draw_grid(image, center, center, white)
		"finisher":
			# 靶心
			_draw_target(image, center, center, white)
		"wall":
			# 盾牌
			_draw_shield(image, center, center, white)
		"interceptor":
			# 手掌
			_draw_hand(image, center, center, white)
		"acrobatic":
			# 星星
			_draw_star(image, center, center, white)
		"leader":
			# 皇冠
			_draw_crown(image, center, center, white)
		"super_sub":
			# 闪电+S
			_draw_lightning(image, center, center, white)
		_:
			_draw_circle(image, center, center, 25, white)

## 绘制等级装饰
func _draw_tier_decoration(image: Image, tier: String, size: int):
	var tier_color = TeamSpecialties.get_tier_color(tier)
	match tier:
		"bronze":
			# 铜级：简单边框
			_draw_ring(image, size/2, size/2, size/2 - 2, 2, tier_color)
		"silver":
			# 银级：边框+小星星
			_draw_ring(image, size/2, size/2, size/2 - 2, 3, tier_color)
			_draw_small_star(image, size/4, size/4, tier_color)
			_draw_small_star(image, size*3/4, size/4, tier_color)
			_draw_small_star(image, size/4, size*3/4, tier_color)
			_draw_small_star(image, size*3/4, size*3/4, tier_color)
		"gold":
			# 金级：华丽边框+光芒
			_draw_ring(image, size/2, size/2, size/2 - 2, 4, tier_color)
			_draw_rays(image, size/2, size/2, tier_color)

## 绘制环形
func _draw_ring(image: Image, cx: int, cy: int, radius: int, thickness: int, color: Color):
	for y in range(max(0, cy - radius - thickness), min(image.get_height(), cy + radius + thickness + 1)):
		for x in range(max(0, cx - radius - thickness), min(image.get_width(), cx + radius + thickness + 1)):
			var dx = x - cx
			var dy = y - cy
			var dist = sqrt(dx * dx + dy * dy)
			if dist <= radius and dist >= radius - thickness:
				image.set_pixel(x, y, color)

## 绘制闪电
func _draw_lightning(image: Image, cx: int, cy: int, color: Color):
	var points = [
		Vector2(cx - 8, cy - 20),
		Vector2(cx + 5, cy - 20),
		Vector2(cx - 2, cy - 5),
		Vector2(cx + 8, cy - 5),
		Vector2(cx - 5, cy + 20),
		Vector2(cx + 2, cy + 5),
		Vector2(cx - 8, cy + 5),
	]
	_fill_polygon(image, points, color)

## 绘制弧线
func _draw_arc(image: Image, cx: int, cy: int, radius: int, color: Color):
	for angle in range(0, 180, 3):
		var rad = deg_to_rad(angle)
		var x = int(cx + cos(rad) * radius)
		var y = int(cy + sin(rad) * radius)
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)
			if x + 1 < image.get_width():
				image.set_pixel(x + 1, y, color)

## 绘制向下箭头
func _draw_arrow_down(image: Image, cx: int, cy: int, color: Color):
	for y in range(cy - 10, cy + 10):
		var half_width = 3 if y < cy + 5 else (y - cy - 5 + 3)
		for x in range(cx - half_width, cx + half_width + 1):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)

## 绘制双箭头
func _draw_double_arrow(image: Image, cx: int, cy: int, color: Color):
	for i in range(-1, 2):
		var offset = i * 12
		for y in range(cy - 15, cy + 15):
			var half_width = 4 - abs(y - cy) / 4
			for x in range(cx + offset - half_width, cx + offset + half_width + 1):
				if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
					image.set_pixel(x, y, color)

## 绘制网格
func _draw_grid(image: Image, cx: int, cy: int, color: Color):
	for i in range(-2, 3):
		for j in range(-2, 3):
			if (i + j) % 2 == 0:
				for y in range(cy + j * 8 - 3, cy + j * 8 + 4):
					for x in range(cx + i * 8 - 3, cx + i * 8 + 4):
						if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
							image.set_pixel(x, y, color)

## 绘制靶心
func _draw_target(image: Image, cx: int, cy: int, color: Color):
	_draw_ring(image, cx, cy, 22, 3, color)
	_draw_ring(image, cx, cy, 14, 3, color)
	_draw_circle(image, cx, cy, 5, color)

## 绘制盾牌
func _draw_shield(image: Image, cx: int, cy: int, color: Color):
	var points = [
		Vector2(cx, cy - 22),
		Vector2(cx + 18, cy - 15),
		Vector2(cx + 18, cy + 5),
		Vector2(cx, cy + 22),
		Vector2(cx - 18, cy + 5),
		Vector2(cx - 18, cy - 15),
	]
	_fill_polygon(image, points, color)

## 绘制手掌
func _draw_hand(image: Image, cx: int, cy: int, color: Color):
	# 简化手掌
	_draw_circle(image, cx, cy + 5, 12, color)
	for i in range(5):
		var angle = -90 + i * 25
		var rad = deg_to_rad(angle)
		var fx = cx + cos(rad) * 15
		var fy = cy + 5 + sin(rad) * 15
		_draw_circle(image, int(fx), int(fy), 4, color)

## 绘制星星
func _draw_star(image: Image, cx: int, cy: int, color: Color):
	var points = []
	for i in range(10):
		var angle = -PI/2 + i * PI / 5
		var radius = 22 if i % 2 == 0 else 10
		points.append(Vector2(cx + cos(angle) * radius, cy + sin(angle) * radius))
	_fill_polygon(image, points, color)

## 绘制小星星
func _draw_small_star(image: Image, cx: int, cy: int, color: Color):
	var points = []
	for i in range(10):
		var angle = -PI/2 + i * PI / 5
		var radius = 8 if i % 2 == 0 else 4
		points.append(Vector2(cx + cos(angle) * radius, cy + sin(angle) * radius))
	_fill_polygon(image, points, color)

## 绘制皇冠
func _draw_crown(image: Image, cx: int, cy: int, color: Color):
	var points = [
		Vector2(cx - 20, cy + 10),
		Vector2(cx - 20, cy - 5),
		Vector2(cx - 12, cy - 15),
		Vector2(cx - 6, cy - 5),
		Vector2(cx, cy - 20),
		Vector2(cx + 6, cy - 5),
		Vector2(cx + 12, cy - 15),
		Vector2(cx + 20, cy - 5),
		Vector2(cx + 20, cy + 10),
	]
	_fill_polygon(image, points, color)

## 绘制光芒
func _draw_rays(image: Image, cx: int, cy: int, color: Color):
	for angle in range(0, 360, 45):
		var rad = deg_to_rad(angle)
		for r in range(40, 55):
			var x = int(cx + cos(rad) * r)
			var y = int(cy + sin(rad) * r)
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)

## 填充多边形
func _fill_polygon(image: Image, points: Array, color: Color):
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y
	for p in points:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	for y in range(int(min_y), int(max_y) + 1):
		for x in range(int(min_x), int(max_x) + 1):
			if _point_in_polygon(Vector2(x, y), points):
				if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
					image.set_pixel(x, y, color)

## 点是否在多边形内
func _point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var inside = false
	var j = polygon.size() - 1
	for i in range(polygon.size()):
		if ((polygon[i].y > point.y) != (polygon[j].y > point.y)) and \
		   (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / (polygon[j].y - polygon[i].y) + polygon[i].x):
			inside = not inside
		j = i
	return inside
