## touch_controls.gd
## 触屏操作系统
## 左侧虚拟摇杆：移动
## 右侧按钮组：传球/射门/冲刺/切换/抢断/传中/挑球/2过1/门将出击
extends CanvasLayer

signal move_input_changed(direction: Vector2)
signal action_pressed(action: String)

# 虚拟摇杆
var joystick_base: Control
var joystick_knob: Control
var joystick_center: Vector2
var joystick_active: bool = false
var joystick_vector: Vector2 = Vector2.ZERO

# 按钮组
var button_container: HBoxContainer
var buttons: Dictionary = {}

const JOYSTICK_RADIUS = 120.0
const KNOB_RADIUS = 50.0
const BUTTON_SIZE = 70

func _ready():
	layer = 10
	_create_joystick()
	_create_action_buttons()
	# 默认隐藏，在移动端显示
	visible = OS.has_feature("mobile") or true  # 调试时也显示

func _create_joystick():
	joystick_base = Control.new()
	joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick_base.offset_left = 40
	joystick_base.offset_top = -180
	joystick_base.offset_right = 40 + int(JOYSTICK_RADIUS * 2)
	joystick_base.offset_bottom = -40
	add_child(joystick_base)

	# 绘制摇杆底盘
	var base_draw = Control.new()
	base_draw.draw.connect(func():
		base_draw.draw_circle(
			Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS),
			JOYSTICK_RADIUS,
			Color(1, 1, 1, 0.15)
		)
		base_draw.draw_circle(
			Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS),
			JOYSTICK_RADIUS - 5,
			Color(1, 1, 1, 0.08)
		)
	)
	base_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	joystick_base.add_child(base_draw)

	# 摇杆旋钮
	joystick_knob = Control.new()
	joystick_knob.position = Vector2(JOYSTICK_RADIUS - KNOB_RADIUS, JOYSTICK_RADIUS - KNOB_RADIUS)
	joystick_knob.custom_minimum_size = Vector2(KNOB_RADIUS * 2, KNOB_RADIUS * 2)
	var knob_draw = Control.new()
	knob_draw.draw.connect(func():
		knob_draw.draw_circle(Vector2(KNOB_RADIUS, KNOB_RADIUS), KNOB_RADIUS, Color(1, 1, 1, 0.4))
		knob_draw.draw_circle(Vector2(KNOB_RADIUS, KNOB_RADIUS), KNOB_RADIUS - 8, Color(1, 1, 1, 0.6))
	)
	knob_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	joystick_knob.add_child(knob_draw)
	joystick_base.add_child(joystick_knob)

	joystick_center = Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)

func _create_action_buttons():
	button_container = HBoxContainer.new()
	button_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button_container.offset_left = -480
	button_container.offset_top = -120
	button_container.offset_right = -20
	button_container.offset_bottom = -20
	button_container.add_theme_constant_override("separation", 10)
	add_child(button_container)

	# 创建动作按钮
	var button_configs = [
		{"id": "pass", "label": "传", "color": Color(0.2, 0.6, 1.0, 0.8)},
		{"id": "shoot", "label": "射", "color": Color(1.0, 0.3, 0.2, 0.8)},
		{"id": "through_ball", "label": "塞", "color": Color(0.2, 0.9, 0.4, 0.8)},
		{"id": "cross", "label": "中", "color": Color(0.9, 0.7, 0.2, 0.8)},
		{"id": "sprint", "label": "冲", "color": Color(0.9, 0.9, 0.2, 0.8), "toggle": true},
		{"id": "switch_player", "label": "换", "color": Color(0.7, 0.3, 0.9, 0.8)},
	]

	for config in button_configs:
		var btn = _create_button(config)
		button_container.add_child(btn)
		buttons[config.id] = btn

	# 第二行按钮
	var button_container2 = HBoxContainer.new()
	button_container2.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button_container2.offset_left = -380
	button_container2.offset_top = -200
	button_container2.offset_right = -20
	button_container2.offset_bottom = -130
	button_container2.add_theme_constant_override("separation", 10)
	add_child(button_container2)

	var button_configs2 = [
		{"id": "tackle", "label": "铲", "color": Color(1.0, 0.5, 0.0, 0.8)},
		{"id": "lob", "label": "挑", "color": Color(0.5, 1.0, 0.8, 0.8)},
		{"id": "one_two", "label": "2过1", "color": Color(0.8, 0.5, 1.0, 0.8)},
		{"id": "gk_rush", "label": "门出", "color": Color(1.0, 0.8, 0.3, 0.8)},
		{"id": "pause", "label": "暂停", "color": Color(0.5, 0.5, 0.5, 0.8)},
	]

	for config in button_configs2:
		var btn = _create_button(config)
		button_container2.add_child(btn)
		buttons[config.id] = btn

func _create_button(config: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	btn.text = config.label
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", _create_button_style(config.color))
	btn.add_theme_stylebox_override("pressed", _create_button_style(config.color.darkened(0.3)))
	btn.add_theme_stylebox_override("hover", _create_button_style(config.color.lightened(0.2)))

	if config.get("toggle", false):
		btn.toggle_mode = true
		btn.toggled.connect(func(pressed):
			if pressed:
				action_pressed.emit(config.id)
		)
	else:
		btn.pressed.connect(func():
			action_pressed.emit(config.id)
		)

	return btn

func _create_button_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 35
	style.corner_radius_top_right = 35
	style.corner_radius_bottom_left = 35
	style.corner_radius_bottom_right = 35
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.5)
	return style

func _input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_handle_joystick_input(event)

func _handle_joystick_input(event):
	var joystick_rect = Rect2(
		joystick_base.global_position,
		joystick_base.size
	)

	if event is InputEventScreenTouch:
		if event.pressed and joystick_rect.has_point(event.position):
			joystick_active = true
		elif not event.pressed:
			joystick_active = false
			joystick_vector = Vector2.ZERO
			_reset_knob()
			move_input_changed.emit(Vector2.ZERO)

	if joystick_active and event is InputEventScreenDrag:
		var local_pos = event.position - joystick_base.global_position
		var offset = local_pos - joystick_center
		var distance = offset.length()

		if distance > JOYSTICK_RADIUS:
			offset = offset.normalized() * JOYSTICK_RADIUS

		joystick_knob.position = Vector2(
			JOYSTICK_RADIUS - KNOB_RADIUS + offset.x,
			JOYSTICK_RADIUS - KNOB_RADIUS + offset.y
		)

		joystick_vector = offset / JOYSTICK_RADIUS
		move_input_changed.emit(joystick_vector)

func _reset_knob():
	joystick_knob.position = Vector2(
		JOYSTICK_RADIUS - KNOB_RADIUS,
		JOYSTICK_RADIUS - KNOB_RADIUS
	)

## 获取当前摇杆方向
func get_move_vector() -> Vector2:
	return joystick_vector

## 设置按钮可见性
func set_buttons_visible(vis: bool):
	for btn in buttons.values():
		btn.visible = vis
