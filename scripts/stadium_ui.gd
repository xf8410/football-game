## stadium_ui.gd
## 球场自定义界面
extends Control

@onready var stadium_list = $VBox/HBox/LeftPanel/ScrollContainer/StadiumList
@onready var weather_option = $VBox/HBox/RightPanel/WeatherBox/WeatherOption
@onready var time_slider = $VBox/HBox/RightPanel/TimeBox/TimeSlider
@onready var time_label = $VBox/HBox/RightPanel/TimeBox/TimeLabel
@onready var detail_label = $VBox/HBox/RightPanel/DetailLabel
@onready var random_button = $VBox/HBox/RightPanel/RandomButton
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	random_button.pressed.connect(_on_random)
	weather_option.item_selected.connect(_on_weather_changed)
	time_slider.value_changed.connect(_on_time_changed)
	_populate_stadiums()
	_populate_weather()
	_load_current_settings()

func _populate_stadiums():
	for child in stadium_list.get_children():
		child.queue_free()

	var stadiums = StadiumSystem.get_all_stadiums()
	for sid in stadiums:
		var stadium = stadiums[sid]
		var btn = Button.new()
		btn.text = "%s\n%s  容量:%d" % [stadium.name, stadium.city, stadium.capacity]
		btn.custom_minimum_size = Vector2(0, 60)
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(func(): _select_stadium(sid))
		stadium_list.add_child(btn)

func _populate_weather():
	weather_option.clear()
	weather_option.add_item("晴天", StadiumSystem.Weather.SUNNY)
	weather_option.add_item("多云", StadiumSystem.Weather.CLOUDY)
	weather_option.add_item("小雨", StadiumSystem.Weather.RAIN)
	weather_option.add_item("大雨", StadiumSystem.Weather.HEAVY_RAIN)
	weather_option.add_item("下雪", StadiumSystem.Weather.SNOW)
	weather_option.add_item("雾天", StadiumSystem.Weather.FOG)
	weather_option.add_item("夜场", StadiumSystem.Weather.NIGHT)

func _load_current_settings():
	weather_option.select(StadiumSystem.current_weather)
	time_slider.value = StadiumSystem.current_time_of_day
	_update_time_label()
	_update_detail()

func _select_stadium(sid: String):
	StadiumSystem.set_stadium(sid)
	_update_detail()

func _on_weather_changed(idx: int):
	StadiumSystem.set_weather(idx)
	_update_detail()

func _on_time_changed(value: float):
	StadiumSystem.set_time_of_day(value)
	_update_time_label()
	_update_detail()

func _update_time_label():
	var hour = int(StadiumSystem.current_time_of_day)
	var minute = int((StadiumSystem.current_time_of_day - hour) * 60)
	time_label.text = "时间: %02d:%02d" % [hour, minute]

func _on_random():
	StadiumSystem.random_weather()
	StadiumSystem.random_time()
	_load_current_settings()

func _update_detail():
	var env = StadiumSystem.get_environment_settings()
	var text = "=== 球场环境 ===\n\n"
	text += "球场: %s\n" % env.stadium_name
	text += "天气: %s\n" % env.weather_name
	text += "时间: %02d:00\n" % int(env.time_of_day)
	text += "容量: %d人\n\n" % env.capacity

	text += "=== 环境影响 ===\n"
	text += "球速倍率: %.2fx\n" % env.ball_speed_mult
	text += "球员速度: %.2fx\n" % env.player_speed_mult
	text += "能见度: %.0f%%\n\n" % (env.visibility * 100)

	text += "=== 草地颜色 ===\n"
	var grass = env.grass_color
	text += "R:%d G:%d B:%d\n" % [int(grass.r * 255), int(grass.g * 255), int(grass.b * 255)]

	detail_label.text = text
