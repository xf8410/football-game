## season_history_ui.gd
## 赛季历史界面
extends Control

@onready var stats_label = $VBox/StatsLabel
@onready var history_container = $VBox/ScrollContainer/HistoryVBox
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	SeasonHistory.load_history()
	_update_ui()

func _update_ui():
	var total = SeasonHistory.get_total_seasons()
	var titles = SeasonHistory.get_player_titles()
	var best_rank = SeasonHistory.get_best_rank()

	stats_label.text = "总赛季: %d  |  冠军数: %d  |  最佳排名: %d" % [
		total, titles, best_rank if best_rank > 0 else 0
	]

	for child in history_container.get_children():
		child.queue_free()

	var history = SeasonHistory.get_all_history()
	if history.is_empty():
		var label = Label.new()
		label.text = "暂无赛季历史\n\n完成一个联赛赛季后，历史记录会显示在这里"
		label.add_theme_font_size_override("font_size", 16)
		history_container.add_child(label)
		return

	# 倒序显示（最新在最前）
	history.reverse()
	for season in history:
		var panel = _create_season_panel(season)
		history_container.add_child(panel)

func _create_season_panel(season: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 120)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 5)
	vbox.size = Vector2(540, 110)
	vbox.theme_override_constants_separation = 3

	# 赛季标题
	var title = Label.new()
	var rank_text = "第%d名" % season.player_rank
	if season.player_rank == 1:
		rank_text = "🏆 冠军！"
	elif season.player_rank <= 3:
		rank_text = "🥉 第%d名" % season.player_rank
	title.text = "%s %s - %s (%s)" % [
		season.year, season.league_name, season.player_team_name, rank_text
	]
	title.add_theme_font_size_override("font_size", 16)
	if season.player_rank == 1:
		title.add_theme_color_override("font_color", Color(1, 0.84, 0.0))
	vbox.add_child(title)

	# 冠军信息
	var champ = Label.new()
	champ.text = "冠军: %s" % season.champion_name
	champ.add_theme_font_size_override("font_size", 13)
	champ.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
	vbox.add_child(champ)

	# 数据
	var stats = Label.new()
	stats.text = "比赛: %d场 | 总进球: %d" % [season.total_matches, season.total_goals]
	stats.add_theme_font_size_override("font_size", 12)
	stats.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(stats)

	# 射手榜
	if not season.top_scorer.is_empty():
		var ts = season.top_scorer
		var scorer = Label.new()
		scorer.text = "👟 最佳射手: %s (%d球)" % [ts.get("player_name", ""), ts.get("goals", 0)]
		scorer.add_theme_font_size_override("font_size", 12)
		scorer.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
		vbox.add_child(scorer)

	panel.add_child(vbox)
	return panel
