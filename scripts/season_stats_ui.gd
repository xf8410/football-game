## season_stats_ui.gd
## 赛季统计界面
## 显示：积分榜 / 射手榜 / 助攻榜 / 球队战绩
extends Control

@onready var tab_container = $TabContainer
@onready var table_container = $TabContainer/积分榜/ScrollContainer/TableVBox
@onready var scorers_container = $TabContainer/射手榜/ScrollContainer/ScorersVBox
@onready var assists_container = $TabContainer/助攻榜/ScrollContainer/AssistsVBox
@onready var summary_label = $VBox/SummaryLabel
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	SeasonStats.load_season()
	_update_ui()

func _update_ui():
	_update_summary()
	_update_league_table()
	_update_top_scorers()
	_update_top_assists()

func _update_summary():
	var total_matches = SeasonStats.get_total_matches()
	var total_goals = SeasonStats.get_total_goals()
	var avg_goals = SeasonStats.get_avg_goals_per_match()
	summary_label.text = "本赛季: %d场比赛 | %d个进球 | 场均%.1f球" % [
		total_matches, total_goals, avg_goals
	]

func _update_league_table():
	for child in table_container.get_children():
		child.queue_free()

	# 表头
	var header = HBoxContainer.new()
	for col in ["排名", "球队", "赛", "胜", "平", "负", "进", "失", "净", "分", "近5场"]:
		var label = Label.new()
		label.text = col
		label.custom_minimum_size = Vector2(55, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		header.add_child(label)
	table_container.add_child(header)

	var table = SeasonStats.get_league_table()
	for i in range(table.size()):
		var stat = table[i]
		var row = HBoxContainer.new()

		# 排名颜色（前4名欧冠，5-6名欧联）
		var rank_color = Color.WHITE
		if i < 4:
			rank_color = Color(0.2, 0.8, 0.3)  # 欧冠区
		elif i < 6:
			rank_color = Color(0.8, 0.6, 0.2)  # 欧联区

		var team_name = TeamDatabase.get_team_name(stat.team_id)
		var gd = stat.goals_for - stat.goals_against
		var form_str = " ".join(stat.form)

		var data = [
			str(i + 1), team_name, str(stat.played), str(stat.won),
			str(stat.drawn), str(stat.lost), str(stat.goals_for),
			str(stat.goals_against), str(gd), str(stat.points), form_str
		]

		for j in range(data.size()):
			var label = Label.new()
			label.text = data[j]
			label.custom_minimum_size = Vector2(55, 0)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 13)
			if j == 0:
				label.add_theme_color_override("font_color", rank_color)
			row.add_child(label)

		table_container.add_child(row)

func _update_top_scorers():
	for child in scorers_container.get_children():
		child.queue_free()

	var scorers = SeasonStats.get_top_scorers(20)
	if scorers.is_empty():
		var label = Label.new()
		label.text = "暂无数据"
		scorers_container.add_child(label)
		return

	# 表头
	var header = HBoxContainer.new()
	for col in ["排名", "球员", "球队", "进球数"]:
		var label = Label.new()
		label.text = col
		label.custom_minimum_size = Vector2(120, 0)
		label.add_theme_font_size_override("font_size", 14)
		header.add_child(label)
	scorers_container.add_child(header)

	for i in range(scorers.size()):
		var s = scorers[i]
		var row = HBoxContainer.new()
		var player_name = PlayerDatabase.get_player_name(s.player_id)
		var team_name = TeamDatabase.get_team_name(s.team_id)

		var data = [str(i + 1), player_name, team_name, str(s.goals)]
		for d in data:
			var label = Label.new()
			label.text = d
			label.custom_minimum_size = Vector2(120, 0)
			label.add_theme_font_size_override("font_size", 13)
			row.add_child(label)
		scorers_container.add_child(row)

func _update_top_assists():
	for child in assists_container.get_children():
		child.queue_free()

	var assisters = SeasonStats.get_top_assists(20)
	if assisters.is_empty():
		var label = Label.new()
		label.text = "暂无数据"
		assists_container.add_child(label)
		return

	var header = HBoxContainer.new()
	for col in ["排名", "球员", "球队", "助攻数"]:
		var label = Label.new()
		label.text = col
		label.custom_minimum_size = Vector2(120, 0)
		label.add_theme_font_size_override("font_size", 14)
		header.add_child(label)
	assists_container.add_child(header)

	for i in range(assisters.size()):
		var a = assisters[i]
		var row = HBoxContainer.new()
		var player_name = PlayerDatabase.get_player_name(a.player_id)
		var team_name = TeamDatabase.get_team_name(a.team_id)

		var data = [str(i + 1), player_name, team_name, str(a.assists)]
		for d in data:
			var label = Label.new()
			label.text = d
			label.custom_minimum_size = Vector2(120, 0)
			label.add_theme_font_size_override("font_size", 13)
			row.add_child(label)
		assists_container.add_child(row)
