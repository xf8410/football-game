## team_select.gd
## 球队选择界面 - 选择玩家控制的球队
extends Control

var selected_league: String = ""
var selected_team: String = ""

@onready var team_container = $ScrollContainer/VBox/TeamContainer
@onready var league_label = $ScrollContainer/VBox/LeagueLabel
@onready var start_button = $StartButton
@onready var back_button = $BackButton
@onready var team_info = $TeamInfoPanel

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/LeagueMenu.tscn")
	)
	start_button.pressed.connect(_on_start)
	start_button.disabled = true

	selected_league = GameState.get("selected_league", "premier_league")
	var league = TeamDatabase.get_league(selected_league)
	league_label.text = "选择球队 - %s" % league.get("name", selected_league)

	_populate_teams()

func _populate_teams():
	for child in team_container.get_children():
		child.queue_free()

	var teams: Dictionary
	if selected_league == "national":
		teams = TeamDatabase.get_all_national_teams()
	else:
		teams = TeamDatabase.get_clubs_by_league(selected_league)

	# 按评分排序
	var sorted_teams = []
	for tid in teams:
		sorted_teams.append({"id": tid, "data": teams[tid]})
	sorted_teams.sort_custom(func(a, b): return a.data.rating > b.data.rating)

	for entry in sorted_teams:
		var tid = entry.id
		var team = entry.data
		var btn = Button.new()
		btn.text = "%s (%d)" % [team.get("name", tid), team.get("rating", 75)]
		btn.custom_minimum_size = Vector2(400, 50)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(func(): _select_team(tid))
		team_container.add_child(btn)

func _select_team(team_id: String):
	selected_team = team_id
	var team = TeamDatabase.get_team(team_id)
	var colors = TeamDatabase.get_team_colors(team_id)
	team_info.text = "已选择: %s\n阵型: %s\n评分: %d\n球员数: %d" % [
		team.get("name", team_id),
		team.get("formation", "4-4-2"),
		team.get("rating", 75),
		team.get("players", []).size(),
	]
	team_info.modulate = colors.primary
	start_button.disabled = false
	print("[TeamSelect] 选择球队: " + team_id)

func _on_start():
	if selected_team == "":
		return
	print("[TeamSelect] 开始联赛: %s, 球队: %s" % [selected_league, selected_team])
	LeagueManager.start_league(selected_league, selected_team)
	get_tree().change_scene_to_file("res://scenes/LeagueHub.tscn")
