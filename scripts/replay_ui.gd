## replay_ui.gd
## 回放控制面板
## 功能：播放/暂停/快进/快退/跳转到进球/速度调节
extends CanvasLayer

@onready var root = $Control
@onready var play_button = $Control/Panel/VBox/Controls/PlayButton
@onready var pause_button = $Control/Panel/VBox/Controls/PauseButton
@onready var restart_button = $Control/Panel/VBox/Controls/RestartButton
@onready var speed_option = $Control/Panel/VBox/Controls/SpeedOption
@onready var progress_bar = $Control/Panel/VBox/ProgressBar
@onready var time_label = $Control/Panel/VBox/TimeLabel
@onready var events_list = $Control/Panel/VBox/EventsScroll/EventsList
@onready var close_button = $Control/Panel/VBox/TitleBar/CloseButton
@onready var title_label = $Control/Panel/VBox/TitleBar/TitleLabel

var is_visible: bool = false

func _ready():
	layer = 20
	root.visible = false
	play_button.pressed.connect(_on_play)
	pause_button.pressed.connect(_on_pause)
	restart_button.pressed.connect(_on_restart)
	close_button.pressed.connect(_on_close)
	speed_option.item_selected.connect(_on_speed_changed)
	progress_bar.value_changed.connect(_on_seek)

	# 速度选项
	speed_option.clear()
	speed_option.add_item("0.25x", 0)
	speed_option.add_item("0.5x", 1)
	speed_option.add_item("1x", 2)
	speed_option.add_item("2x", 3)
	speed_option.add_item("4x", 4)
	speed_option.select(2)

## 显示回放面板
func show_replay():
	is_visible = true
	root.visible = true
	_populate_events()
	_update_progress()

## 隐藏回放面板
func hide_replay():
	is_visible = false
	root.visible = false
	ReplaySystem.stop_replay()

func _on_play():
	ReplaySystem.is_playing = true
	print("[ReplayUI] 播放")

func _on_pause():
	ReplaySystem.is_playing = false
	print("[ReplayUI] 暂停")

func _on_restart():
	ReplaySystem.playback_frame = 0
	ReplaySystem.is_playing = true
	print("[ReplayUI] 重新播放")

func _on_speed_changed(index: int):
	var speeds = [0.25, 0.5, 1.0, 2.0, 4.0]
	# 注：实际播放速度需要在Match中应用
	print("[ReplayUI] 速度: %sx" % speeds[index])

func _on_seek(value: float):
	var total = ReplaySystem.recorded_frames.size()
	if total > 0:
		ReplaySystem.playback_frame = int(value * total / 100.0)
		print("[ReplayUI] 跳转到帧 %d/%d" % [ReplaySystem.playback_frame, total])

func _on_close():
	hide_replay()

## 填充事件列表
func _populate_events():
	for child in events_list.get_children():
		child.queue_free()

	var events = ReplaySystem.get_key_events()
	if events.is_empty():
		var label = Label.new()
		label.text = "无关键事件"
		events_list.add_child(label)
		return

	for i in range(events.size()):
		var event = events[i]
		var btn = Button.new()
		var type_names = {
			"goal": "⚽ 进球",
			"goal_header": "⚽ 头球进球",
			"goal_own": "🚫 乌龙球",
			"shot_on_target": "🎯 射正",
			"save": "🧤 扑救",
			"foul": "🟨 犯规",
			"yellow_card": "🟨 黄牌",
			"red_card": "🟥 红牌",
		}
		var icon = type_names.get(event.type, "📌 " + event.type)
		btn.text = "%s  %s" % [icon, event.get("description", "")]
		btn.custom_minimum_size = Vector2(0, 35)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func(): ReplaySystem.seek_to_event(i))
		events_list.add_child(btn)

## 更新进度条
func _update_progress():
	var progress = ReplaySystem.get_playback_progress()
	progress_bar.value = progress * 100.0

	var current = ReplaySystem.playback_frame
	var total = ReplaySystem.recorded_frames.size()
	var current_time = current * 0.05  # 20fps
	var total_time = total * 0.05
	time_label.text = "%d:%02d / %d:%02d" % [
		int(current_time / 60), int(current_time) % 60,
		int(total_time / 60), int(total_time) % 60
	]

func _process(delta):
	if is_visible:
		_update_progress()
