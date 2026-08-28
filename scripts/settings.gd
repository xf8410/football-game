## settings.gd
## 设置界面
## AI难度、比赛时长、音量、控制方式
extends Control

@onready var difficulty_option = $ScrollContainer/VBox/DifficultyBox/DifficultyOption
@onready var duration_option = $ScrollContainer/VBox/DurationBox/DurationOption
@onready var sound_slider = $ScrollContainer/VBox/SoundBox/SoundSlider
@onready var music_slider = $ScrollContainer/VBox/MusicBox/MusicSlider
@onready var camera_option = $ScrollContainer/VBox/CameraBox/CameraOption
@onready var control_option = $ScrollContainer/VBox/ControlBox/ControlOption
@onready var back_button = $BackButton
@onready var reset_button = $ScrollContainer/VBox/ResetButton

var settings: Dictionary

func _ready():
	settings = SaveManager.get_settings()
	_setup_ui()
	_load_settings()

	back_button.pressed.connect(_on_back)
	reset_button.pressed.connect(_on_reset)

	# 连接变更信号
	difficulty_option.item_selected.connect(_on_setting_changed)
	duration_option.item_selected.connect(_on_setting_changed)
	sound_slider.value_changed.connect(_on_setting_changed)
	music_slider.value_changed.connect(_on_setting_changed)
	camera_option.item_selected.connect(_on_setting_changed)
	control_option.item_selected.connect(_on_setting_changed)

func _setup_ui():
	# AI难度选项
	difficulty_option.clear()
	difficulty_option.add_item("简单", GameState.AIDifficulty.EASY)
	difficulty_option.add_item("普通", GameState.AIDifficulty.NORMAL)
	difficulty_option.add_item("困难", GameState.AIDifficulty.HARD)
	difficulty_option.add_item("传奇", GameState.AIDifficulty.LEGEND)

	# 比赛时长选项（分钟）
	duration_option.clear()
	duration_option.add_item("3分钟（快速）", 3)
	duration_option.add_item("6分钟（标准）", 6)
	duration_option.add_item("10分钟（完整）", 10)
	duration_option.add_item("15分钟（长局）", 15)

	# 摄像机模式
	camera_option.clear()
	camera_option.add_item("跟随摄像机", 0)
	camera_option.add_item("固定摄像机", 1)
	camera_option.add_item("广播视角", 2)

	# 控制方式
	control_option.clear()
	control_option.add_item("经典模式", 0)
	control_option.add_item("滑动模式", 1)
	control_option.add_item("双摇杆模式", 2)

func _load_settings():
	# AI难度
	var diff = GameState.string_to_difficulty(settings.get("difficulty", "normal"))
	difficulty_option.select(diff)

	# 比赛时长
	var duration = settings.get("match_duration", 6)
	var duration_idx = [3, 6, 10, 15].find(duration)
	if duration_idx == -1:
		duration_idx = 1
	duration_option.select(duration_idx)

	# 音量
	sound_slider.value = settings.get("sound_volume", 80)
	music_slider.value = settings.get("music_volume", 70)

	# 摄像机
	var cam_modes = ["follow", "fixed", "broadcast"]
	var cam_idx = cam_modes.find(settings.get("camera_mode", "follow"))
	if cam_idx == -1:
		cam_idx = 0
	camera_option.select(cam_idx)

	# 控制方式
	var ctrl_modes = ["classic", "swipe", "dual_stick"]
	var ctrl_idx = ctrl_modes.find(settings.get("control_scheme", "classic"))
	if ctrl_idx == -1:
		ctrl_idx = 0
	control_option.select(ctrl_idx)

func _on_setting_changed(_value = null):
	# 保存当前设置
	var diff_idx = difficulty_option.selected
	var diff_strings = ["easy", "normal", "hard", "legend"]
	settings["difficulty"] = diff_strings[diff_idx]

	var duration_values = [3, 6, 10, 15]
	settings["match_duration"] = duration_values[duration_option.selected]

	settings["sound_volume"] = int(sound_slider.value)
	settings["music_volume"] = int(music_slider.value)

	var cam_modes = ["follow", "fixed", "broadcast"]
	settings["camera_mode"] = cam_modes[camera_option.selected]

	var ctrl_modes = ["classic", "swipe", "dual_stick"]
	settings["control_scheme"] = ctrl_modes[control_option.selected]

	SaveManager.save_settings(settings)
	print("[Settings] 设置已保存")

func _on_back():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_reset():
	# 确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "重置存档"
	dialog.dialog_text = "确定要重置所有存档吗？此操作不可撤销！"
	add_child(dialog)
	dialog.confirmed.connect(func():
		SaveManager.reset_save()
		settings = SaveManager.get_settings()
		_load_settings()
		print("[Settings] 存档已重置")
	)
	dialog.popup_centered()
