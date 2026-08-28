## league_hub.gd
## 联赛中心 - 显示积分榜、赛程、下一场比赛
extends Control

@onready var standings_container = $TabContainer/积分榜/ScrollContainer/StandingsVBox
@onready var fixtures_container = $TabContainer/赛程/ScrollContainer/FixturesVBox
@onready var next_match_label = $VBox/NextMatchLabel
@onready var play_button = $VBox/PlayButton
@onready var back_button = $BackButton
@onready var league_title = $VBox/LeagueTitle

func _ready():
	back_button.pressed.connect(func():
		LeagueManager.clear_season()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	play_button.pressed.connect(_on_play_next)

	league_title.text = LeagueManager.get_league_name()
	_update_ui()

func _update_ui():
	_update_standings()
	_update_fixtures()
	_update_next_match()

func _update_standings():
	for child in standings_container.get_children():
		child.queue_free()

	var standings = LeagueManager.get_standings()
	# 表头
	var header = HBoxContainer.new()
	for col in ["排名", "球队", "赛", "胜", "平", "负", "进", "失", "净", "分"]:
		var label = Label.new()
		label.text = col
		label.custom_minimum_size = Vector2(50, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_child(label)
	standings_container.add_child(header)

	for i in range(standings.size()):
		var s = standings[i]
		var row = HBoxContainer.new()
		var team_name = TeamDatabase.get_team_name(s.team_id)
		var data = [
			str(i + 1),
			team_name,
			str(s.played),
			str(s.won),
			str(s.drawn),
			str(s.lost),
			str(s.goals_for),
			str(s.goals_against),
			str(s.goals_for - s.goals_against),
			str(s.points),
		]
		for val in data:
			var label = Label.new()
			label.text = val
			label.custom_minimum_size = Vector2(50, 0)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if s.team_id == LeagueManager.player_team_id:
				label.add_theme_color_override("font_color", Color.YELLOW)
			row.add_child(label)
		standings_container.add_child(row)

func _update_fixtures():
	for child in fixtures_container.get_children():
		child.queue_free()

	var fixtures = LeagueManager.fixtures
	for round_idx in range(fixtures.size()):
		var round_label = Label.new()
		round_label.text = "第 %d 轮" % (round_idx + 1)
		round_label.add_theme_font_size_override("font_size", 18)
		fixtures_container.add_child(round_label)

		for match in fixtures[round_idx]:
			var match_label = Label.new()
			var home_name = TeamDatabase.get_team_short_name(match.home)
			var away_name = TeamDatabase.get_team_short_name(match.away)
			var score_text = ""
			if match.has("result"):
				score_text = " %d - %d " % [match.result.home_score, match.result.away_score]
			else:
				score_text = " vs "
			match_label.text = "  %s %s %s" % [home_name, score_text, away_name]
			if match.home == LeagueManager.player_team_id or match.away == LeagueManager.player_team_id:
				match_label.add_theme_color_override("font_color", Color.YELLOW)
			fixtures_container.add_child(match_label)

func _update_next_match():
	var next_match = LeagueManager.get_next_player_match()
	if next_match.is_empty():
		next_match_label.text = "赛季已结束！"
		play_button.disabled = true
		play_button.text = "赛季结束"
		return

	var home_name = TeamDatabase.get_team_name(next_match.home)
	var away_name = TeamDatabase.get_team_name(next_match.away)
	next_match_label.text = "下一场: 第%d轮  %s (主) vs %s (客)" % [
		LeagueManager.current_matchday + 1, home_name, away_name
	]
	play_button.disabled = false
	play_button.text = "开始比赛"

func _on_play_next():
	var next_match = LeagueManager.get_next_player_match()
	if next_match.is_empty():
		return

	# 设置比赛配置
	var home_team = TeamDatabase.get_team(next_match.home)
	var away_team = TeamDatabase.get_team(next_match.away)
	var home_colors = TeamDatabase.get_team_colors(next_match.home)
	var away_colors = TeamDatabase.get_team_colors(next_match.away)

	var player_is_home = next_match.home == LeagueManager.player_team_id

	GameState.set_match_config({
		"home_team_name": home_team.get("name", "主队"),
		"away_team_name": away_team.get("name", "客队"),
		"home_team_id": next_match.home,
		"away_team_id": next_match.away,
		"home_color": home_colors.primary,
		"away_color": away_colors.primary,
		"formation": home_team.get("formation", "4-4-2") if player_is_home else away_team.get("formation", "4-4-2"),
		"difficulty": GameState.AIDifficulty.NORMAL,
		"half_duration": 180.0,
		"player_controls": GameState.TeamSide.HOME if player_is_home else GameState.TeamSide.AWAY,
		"initial_score": [0, 0],
		"is_league_match": true,
	})

	GameState.set_event({
		"name": "联赛第%d轮" % (LeagueManager.current_matchday + 1),
		"type": "league",
		"modifiers": {}
	})

	get_tree().change_scene_to_file("res://scenes/Match.tscn")
