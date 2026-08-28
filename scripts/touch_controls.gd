## touch_controls.gd
## 触屏操作系统（完整版）
## 手机版专用：虚拟摇杆 + 情境化按钮
##
## 按钮逻辑：
##   有球时：[传球] [直塞] [射门] [冲刺]
##   无球+对方靠近：[压迫] [切换] [冲刺]
##   无球+对方不靠近：[切换] [冲刺]
##   在禁区两侧：自动显示[传中]按钮（替代直塞）
extends CanvasLayer

signal move_input_changed(direction: Vector2)
signal action_pressed(action: String)

# 虚拟摇杆
var joystick_base: Panel
var joystick_knob: Panel
var joystick_center: Vector2
var joystick_active: bool = false
var joystick_vector: Vector2 = Vector2.ZERO
var joystick_touch_id: int = -1

# 按钮容器
var button_container: VBoxContainer
var buttons: Dictionary = {}

# 按钮定义
const BUTTON_DEFS = {
	"pass": {"label": "传球", "color": Color(0.2, 0.6, 1.0), "size": 80},
	"through": {"label": "直塞", "color": Color(0.2, 0.8, 0.6), "size": 80},
	"shoot": {"label": "射门", "color": Color(1.0, 0.3, 0.2), "size": 90},
	"cross": {"label": "传中", "color": Color(1.0, 0.6, 0.2), "size": 80},
	"press": {"label": "压迫", "color": Color(1.0, 0.5, 0.1), "size": 80},
	"switch": {"label": "切换", "color": Color(0.8, 0.8, 0.2), "size": 70},
	"sprint": {"label": "冲刺", "color": Color(0.6, 0.6, 0.6), "size": 70},
	"tackle": {"label": "抢断", "color": Color(0.9, 0.3, 0.5), "size": 75},
	"lob": {"label": "挑球", "color": Color(0.5, 0.8, 0.9), "size": 70},
}

# 当前情境
var has_ball: bool = false
var opponent_nearby: bool = false
var in_cross_zone: bool = false

const JOYSTICK_RADIUS = 120.0
const KNOB_RADIUS = 50.0

func _ready():
	layer = 10
	_create_joystick()
	_create_button_container()
	_update_button_visibility()
	# 移动端自动显示，桌面端也显示（方便测试）
	visible = true

func _create_joystick():
	joystick_base = Panel.new()
	joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick_base.offset_left = 40
	joystick_base.offset_top = -180
	joystick_base.offset_right = 40 + int(JOYSTICK_RADIUS * 2)
	joystick_base.offset_bottom = -40
	add_child(joystick_base)

	# 摇杆底盘背景
	var base_style = StyleBoxFlat.new()
	base_style.bg_color = Color(1, 1, 1, 0.1)
	base_style.corner_radius_top_left = 60
	base_style.corner_radius_top_right = 60
	base_style.corner_radius_bottom_left = 60
	base_style.corner_radius_bottom_right = 60
	joystick_base.add_theme_stylebox_override("panel", base_style)

	# 摇杆旋钮
	joystick_knob = Panel.new()
	joystick_knob.size = Vector2(KNOB_RADIUS * 2, KNOB_RADIUS * 2)
	joystick_knob.position = Vector2(JOYSTICK_RADIUS - KNOB_RADIUS, JOYSTICK_RADIUS - KNOB_RADIUS)

	var knob_style = StyleBoxFlat.new()
	knob_style.bg_color = Color(1, 1, 1, 0.4)
	knob_style.corner_radius_top_left = 30
	knob_style.corner_radius_top_right = 30
	knob_style.corner_radius_bottom_left = 30
	knob_style.corner_radius_bottom_right = 30
	knob_style.border_width_left = 2
	knob_style.border_width_right = 2
	knob_style.border_width_top = 2
	knob_style.border_width_bottom = 2
	knob_style.border_color = Color(1, 1, 1, 0.6)
	joystick_knob.add_theme_stylebox_override("panel", knob_style)
	joystick_base.add_child(joystick_knob)

	joystick_center = Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)

func _create_button_container():
	button_container = VBoxContainer.new()
	button_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button_container.offset_left = -200
	button_container.offset_top = -200
	button_container.offset_right = -20
	button_container.offset_bottom = -20
	button_container.alignment = BoxContainer.ALIGNMENT_END
	button_container.theme_override_constants_separation = 8
	add_child(button_container)

	# 创建所有按钮
	for action_id in BUTTON_DEFS:
		var def = BUTTON_DEFS[action_id]
		var btn = _create_action_button(action_id, def)
		buttons[action_id] = btn
		button_container.add_child(btn)

func _create_action_button(action_id: String, def: Dictionary) -> Button:
	var btn = Button.new()
	btn.text = def.label
	btn.custom_minimum_size = Vector2(def.size, def.size)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.WHITE)

	# 按钮样式
	var style = StyleBoxFlat.new()
	style.bg_color = def.color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.5)
	btn.add_theme_stylebox_override("normal", style)

	# 按下样式
	var pressed_style = style.duplicate()
	pressed_style.bg_color = def.color.darkened(0.3)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.pressed.connect(func():
		action_pressed.emit(action_id)
	)

	return btn

## 更新按钮可见性（根据情境）
func _update_button_visibility():
	# 先隐藏所有按钮
	for action_id in buttons:
		buttons[action_id].visible = false

	if has_ball:
		# 有球时
		buttons["pass"].visible = true
		if in_cross_zone:
			buttons["cross"].visible = true
		else:
			buttons["through"].visible = true
		buttons["shoot"].visible = true
		buttons["sprint"].visible = true
		buttons["lob"].visible = true
	else:
		# 无球时
		buttons["sprint"].visible = true
		buttons["switch"].visible = true
		if opponent_nearby:
			buttons["press"].visible = true
			buttons["tackle"].visible = true

## 设置情境
func set_context(p_has_ball: bool, p_opponent_nearby: bool = false, p_in_cross_zone: bool = false):
	has_ball = p_has_ball
	opponent_nearby = p_opponent_nearby
	in_cross_zone = p_in_cross_zone
	_update_button_visibility()

## 处理触屏输入
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
			joystick_touch_id = event.index
		elif not event.pressed and event.index == joystick_touch_id:
			joystick_active = false
			joystick_touch_id = -1
			joystick_vector = Vector2.ZERO
			_reset_knob()
			move_input_changed.emit(Vector2.ZERO)

	if joystick_active and event is InputEventScreenDrag and event.index == joystick_touch_id:
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

## 是否为移动设备
func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
