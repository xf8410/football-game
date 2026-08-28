## world_cup_ui.gd
## 世界杯模式界面
extends Control

@onready var stage_label = $VBox/StageLabel
@onready var groups_container = $VBox/ScrollContainer/GroupsVBox
@onready var knockout_label = $VBox/ScrollContainer/KnockoutLabel
@onready var start_button = $VBox/StartButton
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	start_button.pressed.connect(_on_start)
	_update_ui()

func _update_ui():
	var data = WorldCupMode.get_world_cup_data()
	stage_label.text = "当前阶段: %s" % WorldCupMode.get_stage_name()

	if data.stage == "not_started":
		start_button.text = "🌍 开始世界杯"
		start_button.disabled = false
		groups_container.visible = false
		knockout_label.visible = false
		return

	start_button.visible = false

	# 显示小组
	for child in groups_container.get_children():
		child.queue_free()

	groups_container.visible = true
	for group in data.groups:
		var group_label = Label.new()
		group_label.text = "=== %s ===" % group.name
		group_label.add_theme_font_size_override("font_size", 18)
		group_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		groups_container.add_child(group_label)

		# 按积分排序
		var standings = group.standings.duplicate()
		standings.sort_custom(func(a, b): return a.points > b.points)

		for i in range(standings.size()):
			var s = standings[i]
			var team_name = TeamDatabase.get_team_name(s.team_id)
			var is_player = s.team_id == data.player_team
			var prefix = "👉 " if is_player else "   "
			var rank_icon = "🟢" if i < 2 else "⚪"  # 前2名出线
			var text = "%s%s %s  %d分 (%d胜%d平%d负 进%d失%d)" % [
				prefix, rank_icon, team_name,
				s.points, s.won, s.drawn, s.lost, s.goals_for, s.goals_against
			]
			var label = Label.new()
			label.text = text
			label.add_theme_font_size_override("font_size", 13)
			if is_player:
				label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			groups_container.add_child(label)

		groups_container.add_child(_create_spacer(10))

func _create_spacer(height: int) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer

func _on_start():
	# 选择玩家国家队
	var national_teams = TeamDatabase.get_all_national_teams()
	var team_ids = national_teams.keys()
	if team_ids.is_empty():
		return

	# 简化：随机选一个强队
	team_ids.shuffle()
	var player_team = team_ids[0]

	if WorldCupMode.start_world_cup(player_team):
		_update_ui()
