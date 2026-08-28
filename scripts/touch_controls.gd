## touch_controls.gd
## 触屏操作系统（v2 - 情境化按钮）
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
var joystick_base: Control
var joystick_knob: Control
var joystick_center: Vector2
var joystick_active: bool = false
var joystick_vector: Vector2 = Vector2.ZERO

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
	visible = OS.has_feature("mobile") or true

func _create_joystick():
	joystick_base = Control.new()
	joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick_base.offset_left = 40
	joystick_base.offset_top = -180
	joystick_base.offset_right = 40 + int(JOYSTICK_RADIUS * 2)
	joystick_base.offset_bottom = -40
	add_child(joystick_base)

	var base_draw = Control.new()
	base_draw.draw.connect(func():
		base_draw.draw_circle(
			Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS),
			JOYSTICK_RADIUS,
			Color(1, 1, 1, 0.15)
		)
	)
	base_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	joystick_base.add_child(base_draw)

	joystick_knob = Control.new()
	joystick_knob.position = Vector2(JOYSTICK_RADIUS - KNOB_RADIUS, JOYSTICK_RADIUS - KNOB_RADIUS)
	joystick_knob.custom_minimum_size = Vector2(KNOB_RADIUS * 2, KNOB_RADIUS * 2)
	joystick_knob.draw.connect(func():
		joystick_knob.draw_circle(
			Vector2(KNOB_RADIUS, KNOB_RADIUS),
			KNOB_RADIUS,
			Color(1, 1, 1, 0.4)
		)
		joystick_knob.draw_circle(
			Vector2(KNOB_RADIUS, KNOB_RADIUS),
			KNOB_RADIUS - 8,
			Color(1, 1, 1, 0.6)
		)
	)
	joystick_base.add_child(joystick_knob)
	joystick_center = Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)

func _create_button_container():
	button_container = VBoxContainer.new()
	button_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button_container.offset_left = -260
	button_container.offset_top = -280
	button_container.offset_right = -30
	button_container.offset_bottom = -30
	button_container.alignment = BoxContainer.ALIGNMENT_END
	button_container.theme_override_constants_separation = 12
	add_child(button_container)

	# 创建所有按钮（初始隐藏）
	for btn_id in BUTTON_DEFS:
		var def = BUTTON_DEFS[btn_id]
		var btn = Button.new()
		btn.text = def.label
		btn.custom_minimum_size = Vector2(def.size, def.size)
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.modulate = def.color
		btn.visible = false
		btn.pressed.connect(func(): _on_button_pressed(btn_id))
		buttons[btn_id] = btn
		button_container.add_child(btn)

func _on_button_pressed(action: String):
	action_pressed.emit(action)

## 更新按钮可见性（根据情境）
func update_context(p_has_ball: bool, p_opponent_nearby: bool, p_in_cross_zone: bool):
	has_ball = p_has_ball
	opponent_nearby = p_opponent_nearby
	in_cross_zone = p_in_cross_zone
	_update_button_visibility()

func _update_button_visibility():
	# 先全部隐藏
	for btn in buttons.values():
		btn.visible = false

	if has_ball:
		# 有球时：传球 / 直塞(或传中) / 射门 / 冲刺
		buttons["pass"].visible = true
		if in_cross_zone:
			buttons["cross"].visible = true
		else:
			buttons["through"].visible = true
		buttons["shoot"].visible = true
		buttons["sprint"].visible = true
	else:
		# 无球时
		buttons["sprint"].visible = true
		buttons["switch"].visible = true
		if opponent_nearby:
			# 对方靠近显示压迫
			buttons["press"].visible = true

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

func get_move_vector() -> Vector2:
	return joystick_vector
