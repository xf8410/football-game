## skill_icon_generator.gd
## 技能图标生成器
## 为每个被动技能生成对应的图标
## 根据触发情境使用不同符号和颜色
extends Node

# 情境对应的颜色
const CONTEXT_COLORS = {
	0: Color(0.2, 0.8, 0.4),   # RUNNING - 绿色
	1: Color(0.3, 0.6, 1.0),   # POSITIONING - 蓝色
	2: Color(0.9, 0.3, 0.2),   # DEFENDING - 红色
	3: Color(0.9, 0.6, 0.1),   # TURNING - 橙色
	4: Color(0.6, 0.3, 0.9),   # RETREATING - 紫色
	5: Color(1.0, 0.4, 0.3),   # PRESSING - 亮红
	6: Color(1.0, 0.8, 0.2),   # SHOOTING - 金色
	7: Color(0.2, 0.9, 0.9),   # GK_RUSH - 青色
	8: Color(0.8, 0.5, 0.2),   # HEADER - 棕色
	9: Color(0.7, 0.7, 0.3),   # TACKLING - 橄榄色
	10: Color(0.4, 0.7, 0.4),  # PASSING - 浅绿
	11: Color(0.5, 0.5, 0.8),  # RECEIVING - 浅蓝
}

# 技能图标符号映射
const SKILL_SYMBOLS = {
	"speed_burst": "lightning",
	"endless_runner": "infinity",
	"ghost_movement": "ghost",
	"smart_positioning": "target",
	"iron_wall": "shield",
	"interceptor": "hand",
	"quick_turn": "rotate",
	"fast_retreat": "arrow_down",
	"mad_dog": "fang",
	"power_shot": "explosion",
	"curve_shot": "curve",
	"sweeper_keeper": "broom",
	"gk_1v1_master": "glove",
	"gk_reflex_save": "flash",
	"air_dominance": "wings",
	"precise_tackle": "scissors",
	"pinpoint_pass": "arrow",
	"first_touch": "diamond",
	"clutch_player": "star",
	"wall_defense": "wall",
	"vision_pass": "eye",
	"ghost_dribble": "wave",
}

## 生成技能图标
func generate_skill_icon(skill_id: String, size: int = 64) -> ImageTexture:
	var skill = SkillSystem.get_skill_info(skill_id)
	if skill.is_empty():
		return _generate_default_icon(size)

	var context = skill.get("trigger", 0)
	var bg_color = CONTEXT_COLORS.get(context, Color.GRAY)
	var symbol = SKILL_SYMBOLS.get(skill_id, "default")

	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	# 绘制圆角背景
	_draw_rounded_rect(image, 2, 2, size - 4, size - 4, 8, bg_color)

	# 绘制内圈
	_draw_rounded_rect(image, 5, 5, size - 10, size - 10, 6, bg_color.darkened(0.3))

	# 绘制符号
	_draw_symbol(image, symbol, size, Color.WHITE)

	return ImageTexture.create_from_image(image)

## 生成默认图标
func _generate_default_icon(size: int) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.4, 0.4, 0.4, 1))
	return ImageTexture.create_from_image(image)

## 绘制圆角矩形
func _draw_rounded_rect(image: Image, x: int, y: int, w: int, h: int, radius: int, color: Color):
	for py in range(y, y + h):
		for px in range(x, x + w):
			# 检查是否在圆角内
			var in_corner = false
			var corner_dist = 0.0

			# 四个角的检查
			if px < x + radius and py < y + radius:
				corner_dist = Vector2(x + radius - px, y + radius - py).length()
				in_corner = true
			elif px > x + w - radius - 1 and py < y + radius:
				corner_dist = Vector2(px - (x + w - radius - 1), y + radius - py).length()
				in_corner = true
			elif px < x + radius and py > y + h - radius - 1:
				corner_dist = Vector2(x + radius - px, py - (y + h - radius - 1)).length()
				in_corner = true
			elif px > x + w - radius - 1 and py > y + h - radius - 1:
				corner_dist = Vector2(px - (x + w - radius - 1), py - (y + h - radius - 1)).length()
				in_corner = true

			if in_corner and corner_dist > radius:
				continue

			image.set_pixel(px, py, color)

## 绘制符号
func _draw_symbol(image: Image, symbol: String, size: int, color: Color):
	var cx = size / 2
	var cy = size / 2

	match symbol:
		"lightning":
			_draw_lightning(image, cx, cy, color)
		"infinity":
			_draw_infinity(image, cx, cy, color)
		"ghost":
			_draw_ghost(image, cx, cy, color)
		"target":
			_draw_target(image, cx, cy, color)
		"shield":
			_draw_shield(image, cx, cy, color)
		"hand":
			_draw_hand(image, cx, cy, color)
		"rotate":
			_draw_rotate(image, cx, cy, color)
		"arrow_down":
			_draw_arrow_down(image, cx, cy, color)
		"fang":
			_draw_fang(image, cx, cy, color)
		"explosion":
			_draw_explosion(image, cx, cy, color)
		"curve":
			_draw_curve(image, cx, cy, color)
		"broom":
			_draw_broom(image, cx, cy, color)
		"glove":
			_draw_glove(image, cx, cy, color)
		"flash":
			_draw_flash(image, cx, cy, color)
		"wings":
			_draw_wings(image, cx, cy, color)
		"scissors":
			_draw_scissors(image, cx, cy, color)
		"arrow":
			_draw_arrow(image, cx, cy, color)
		"diamond":
			_draw_diamond(image, cx, cy, color)
		"star":
			_draw_star(image, cx, cy, color)
		"wall":
			_draw_wall(image, cx, cy, color)
		"eye":
			_draw_eye(image, cx, cy, color)
		"wave":
			_draw_wave(image, cx, cy, color)
		_:
			_draw_circle(image, cx, cy, 15, color)

func _draw_circle(image: Image, cx: int, cy: int, radius: int, color: Color):
	for y in range(max(0, cy - radius), min(image.get_height(), cy + radius + 1)):
		for x in range(max(0, cx - radius), min(image.get_width(), cx + radius + 1)):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= radius * radius:
				image.set_pixel(x, y, color)

func _draw_lightning(image: Image, cx: int, cy: int, color: Color):
	var points = [
		Vector2(cx + 5, cy - 18),
		Vector2(cx - 8, cy + 2),
		Vector2(cx, cy + 2),
		Vector2(cx - 5, cy + 18),
		Vector2(cx + 8, cy - 2),
		Vector2(cx, cy - 2),
	]
	_fill_polygon(image, points, color)

func _draw_infinity(image: Image, cx: int, cy: int, color: Color):
	# 两个圆圈组成无限符号
	_draw_circle_outline(image, cx - 10, cy, 8, color)
	_draw_circle_outline(image, cx + 10, cy, 8, color)

func _draw_circle_outline(image: Image, cx: int, cy: int, radius: int, color: Color):
	for angle in range(0, 360, 5):
		var rad = deg_to_rad(angle)
		var x = int(cx + cos(rad) * radius)
		var y = int(cy + sin(rad) * radius)
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)
			image.set_pixel(x + 1, y, color)
			image.set_pixel(x, y + 1, color)

func _draw_ghost(image: Image, cx: int, cy: int, color: Color):
	# 上半圆
	for angle in range(0, 180, 3):
		var rad = deg_to_rad(angle)
		var x = int(cx + cos(rad) * 15)
		var y = int(cy + sin(rad) * 15 - 5)
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)
	# 下半波浪
	for x in range(cx - 15, cx + 16):
		var wave = sin((x - cx) * 0.8) * 3
		var y = int(cy + 10 + wave)
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)

func _draw_target(image: Image, cx: int, cy: int, color: Color):
	_draw_circle_outline(image, cx, cy, 16, color)
	_draw_circle_outline(image, cx, cy, 10, color)
	_draw_circle_outline(image, cx, cy, 4, color)
	image.set_pixel(cx, cy, color)

func _draw_shield(image: Image, cx: int, cy: int, color: Color):
	var points = [
		Vector2(cx, cy - 18),
		Vector2(cx + 14, cy - 12),
		Vector2(cx + 14, cy + 5),
		Vector2(cx, cy + 18),
		Vector2(cx - 14, cy + 5),
		Vector2(cx - 14, cy - 12),
	]
	_fill_polygon(image, points, color)

func _draw_hand(image: Image, cx: int, cy: int, color: Color):
	# 简化手掌
	_draw_circle(image, cx, cy - 5, 8, color)
	for i in range(4):
		var x = cx - 6 + i * 4
		for y in range(cy + 2, cy + 15):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)

func _draw_rotate(image: Image, cx: int, cy: int, color: Color):
	# 圆弧+箭头
	for angle in range(0, 270, 5):
		var rad = deg_to_rad(angle)
		var x = int(cx + cos(rad) * 14)
		var y = int(cy + sin(rad) * 14)
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)
	# 箭头
	_fill_polygon(image, [Vector2(cx + 14, cy), Vector2(cx + 18, cy - 5), Vector2(cx + 18, cy + 5)], color)

func _draw_arrow_down(image: Image, cx: int, cy: int, color: Color):
	# 向下箭头
	for y in range(cy - 15, cy + 5):
		image.set_pixel(cx, y, color)
		image.set_pixel(cx - 1, y, color)
	var points = [Vector2(cx - 8, cy + 2), Vector2(cx + 8, cy + 2), Vector2(cx, cy + 15)]
	_fill_polygon(image, points, color)

func _draw_fang(image: Image, cx: int, cy: int, color: Color):
	# 牙齿形状
	var points = [Vector2(cx - 10, cy - 10), Vector2(cx + 10, cy - 10), Vector2(cx + 5, cy + 15), Vector2(cx - 5, cy + 15)]
	_fill_polygon(image, points, color)

func _draw_explosion(image: Image, cx: int, cy: int, color: Color):
	# 爆炸星形
	for angle in range(0, 360, 45):
		var rad = deg_to_rad(angle)
		var x1 = int(cx + cos(rad) * 18)
		var y1 = int(cy + sin(rad) * 18)
		var x2 = int(cx + cos(rad) * 8)
		var y2 = int(cy + sin(rad) * 8)
		_draw_line(image, cx, cy, x1, y1, color)
	_draw_circle(image, cx, cy, 6, color)

func _draw_line(image: Image, x1: int, y1: int, x2: int, y2: int, color: Color):
	var dx = abs(x2 - x1)
	var dy = abs(y2 - y1)
	var sx = 1 if x1 < x2 else -1
	var sy = 1 if y1 < y2 else -1
	var err = dx - dy
	while true:
		if x1 >= 0 and x1 < image.get_width() and y1 >= 0 and y1 < image.get_height():
			image.set_pixel(x1, y1, color)
		if x1 == x2 and y1 == y2:
			break
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x1 += sx
		if e2 < dx:
			err += dx
			y1 += sy

func _draw_curve(image: Image, cx: int, cy: int, color: Color):
	# 弧线
	for t in range(0, 100):
		var progress = t / 100.0
		var x = int(cx - 15 + progress * 30)
		var y = int(cy + sin(progress * PI) * 15)
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)
			image.set_pixel(x, y + 1, color)

func _draw_broom(image: Image, cx: int, cy: int, color: Color):
	# 扫帚柄
	for y in range(cy - 15, cy + 5):
		image.set_pixel(cx, y, color)
	# 扫帚头
	var points = [Vector2(cx - 10, cy + 5), Vector2(cx + 10, cy + 5), Vector2(cx + 8, cy + 18), Vector2(cx - 8, cy + 18)]
	_fill_polygon(image, points, color)

func _draw_glove(image: Image, cx: int, cy: int, color: Color):
	# 手套形状
	var points = [
		Vector2(cx - 10, cy - 5), Vector2(cx + 10, cy - 5),
		Vector2(cx + 12, cy + 10), Vector2(cx + 5, cy + 15),
		Vector2(cx - 5, cy + 15), Vector2(cx - 12, cy + 10),
	]
	_fill_polygon(image, points, color)

func _draw_flash(image: Image, cx: int, cy: int, color: Color):
	# 闪光
	for angle in range(0, 360, 30):
		var rad = deg_to_rad(angle)
		_draw_line(image, cx, cy, int(cx + cos(rad) * 18), int(cy + sin(rad) * 18), color)
	_draw_circle(image, cx, cy, 5, color)

func _draw_wings(image: Image, cx: int, cy: int, color: Color):
	# 左翅膀
	var left_wing = [Vector2(cx, cy), Vector2(cx - 18, cy - 8), Vector2(cx - 15, cy + 5), Vector2(cx, cy + 3)]
	_fill_polygon(image, left_wing, color)
	# 右翅膀
	var right_wing = [Vector2(cx, cy), Vector2(cx + 18, cy - 8), Vector2(cx + 15, cy + 5), Vector2(cx, cy + 3)]
	_fill_polygon(image, right_wing, color)

func _draw_scissors(image: Image, cx: int, cy: int, color: Color):
	# 两条交叉线
	_draw_line(image, cx - 12, cy - 12, cx + 12, cy + 12, color)
	_draw_line(image, cx - 12, cy + 12, cx + 12, cy - 12, color)
	_draw_circle(image, cx - 12, cy - 12, 4, color)
	_draw_circle(image, cx - 12, cy + 12, 4, color)

func _draw_arrow(image: Image, cx: int, cy: int, color: Color):
	# 向右箭头
	for x in range(cx - 15, cx + 5):
		image.set_pixel(x, cy, color)
		image.set_pixel(x, cy - 1, color)
	var points = [Vector2(cx + 5, cy - 8), Vector2(cx + 15, cy), Vector2(cx + 5, cy + 8)]
	_fill_polygon(image, points, color)

func _draw_diamond(image: Image, cx: int, cy: int, color: Color):
	var points = [Vector2(cx, cy - 16), Vector2(cx + 12, cy), Vector2(cx, cy + 16), Vector2(cx - 12, cy)]
	_fill_polygon(image, points, color)

func _draw_star(image: Image, cx: int, cy: int, color: Color):
	var points = []
	for i in range(10):
		var angle = -90 + i * 36
		var rad = deg_to_rad(angle)
		var r = 18 if i % 2 == 0 else 8
		points.append(Vector2(cx + cos(rad) * r, cy + sin(rad) * r))
	_fill_polygon(image, points, color)

func _draw_wall(image: Image, cx: int, cy: int, color: Color):
	# 砖墙
	for y in range(cy - 14, cy + 14, 7):
		for x in range(cx - 14, cx + 14, 7):
			_fill_rect(image, x, y, 6, 6, color)

func _fill_rect(image: Image, x: int, y: int, w: int, h: int, color: Color):
	for py in range(y, y + h):
		for px in range(x, x + w):
			if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
				image.set_pixel(px, py, color)

func _draw_eye(image: Image, cx: int, cy: int, color: Color):
	# 眼睛形状
	var points = []
	for angle in range(0, 360, 10):
		var rad = deg_to_rad(angle)
		var r = 14 if abs(sin(rad)) > 0.5 else 8
		points.append(Vector2(cx + cos(rad) * 16, cy + sin(rad) * r))
	_fill_polygon(image, points, color)
	_draw_circle(image, cx, cy, 5, color.darkened(0.5))

func _draw_wave(image: Image, cx: int, cy: int, color: Color):
	for x in range(cx - 16, cx + 17):
		var y = int(cy + sin((x - cx) * 0.4) * 8)
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)
			image.set_pixel(x, y + 1, color)

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

func _point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var inside = false
	var j = polygon.size() - 1
	for i in range(polygon.size()):
		if ((polygon[i].y > point.y) != (polygon[j].y > point.y)) and \
		   (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / (polygon[j].y - polygon[i].y) + polygon[i].x):
			inside = not inside
		j = i
	return inside
