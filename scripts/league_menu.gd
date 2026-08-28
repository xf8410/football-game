## league_menu.gd
## 联赛模式入口 - 选择联赛
extends Control

@onready var league_container = $ScrollContainer/VBox/LeagueContainer
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	_populate_leagues()

func _populate_leagues():
	# 清空
	for child in league_container.get_children():
		child.queue_free()

	var leagues = TeamDatabase.get_all_leagues()
	for league_id in leagues:
		var league = leagues[league_id]
		var btn = Button.new()
		btn.text = "%s (%s)" % [league.get("name", league_id), league.get("short_name", "")]
		btn.custom_minimum_size = Vector2(400, 60)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(func(): _select_league(league_id))
		league_container.add_child(btn)

func _select_league(league_id: String):
	print("[LeagueMenu] 选择联赛: " + league_id)
	GameState.set("selected_league", league_id)
	# 跳转到球队选择
	get_tree().change_scene_to_file("res://scenes/TeamSelect.tscn")
