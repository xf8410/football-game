## kit_select_ui.gd
## 球衣选择界面
## 玩家可以选择主队和客队穿主场/客场/第三球衣
extends Control

@onready var team_option = $VBox/HBox/LeftPanel/TeamOption
@onready var kit_container = $VBox/HBox/LeftPanel/ScrollContainer/KitContainer
@onready var preview_label = $VBox/HBox/RightPanel/PreviewLabel
@onready var detail_label = $VBox/HBox/RightPanel/DetailLabel
@onready var back_button = $BackButton

var current_team: String = ""

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	team_option.item_selected.connect(_on_team_selected)
	_populate_teams()

func _populate_teams():
	team_option.clear()
	var clubs = TeamDatabase.get_all_clubs()
	var idx = 0
	for tid in clubs:
		var team = clubs[tid]
		team_option.add_item("%s (%s)" % [team.get("name", tid), team.get("short_name", "")], idx)
		team_option.set_item_metadata(idx, tid)
		idx += 1
	if idx > 0:
		team_option.select(0)
		_on_team_selected(0)

func _on_team_selected(idx: int):
	current_team = team_option.get_item_metadata(idx)
	_populate_kits()
	_update_detail()

func _populate_kits():
	for child in kit_container.get_children():
		child.queue_free()

	var available = KitSystem.get_available_kits(current_team)
	if available.is_empty():
		var label = Label.new()
		label.text = "该球队无球衣数据"
		kit_container.add_child(label)
		return

	var kit_names = {"home": "主场球衣", "away": "客场球衣", "third": "第三球衣"}
	for kit_type in available:
		var btn = Button.new()
		btn.text = kit_names.get(kit_type, kit_type)
		btn.custom_minimum_size = Vector2(0, 60)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(func(): _select_kit(kit_type))
		kit_container.add_child(btn)

func _select_kit(kit_type: String):
	KitSystem.set_kit_choice(current_team, kit_type)
	_update_detail()
	preview_label.text = "已选择: %s" % kit_type
	preview_label.modulate = Color(0.3, 1.0, 0.3)

func _update_detail():
	if current_team.is_empty():
		return

	var team = TeamDatabase.get_team(current_team)
	var text = "=== 球队信息 ===\n\n"
	text += "球队: %s\n" % team.get("name", current_team)
	text += "城市: %s\n" % team.get("city", "")
	text += "球场: %s\n\n" % team.get("stadium", "")

	text += "=== 球衣选择 ===\n\n"
	var current_choice = KitSystem.current_kit_choice.get(current_team, "home")
	var kit_names = {"home": "主场", "away": "客场", "third": "第三"}
	text += "当前选择: %s球衣\n\n" % kit_names.get(current_choice, "主场")

	var available = KitSystem.get_available_kits(current_team)
	for kit_type in available:
		var kit = KitSystem.get_kit(current_team, kit_type)
		text += "--- %s球衣 ---\n" % kit_names.get(kit_type, kit_type)
		text += "  主色: %s\n" % kit.get("primary", "")
		text += "  副色: %s\n" % kit.get("secondary", "")
		text += "  图案: %s\n" % kit.get("pattern", "纯色")
		text += "  赞助商: %s\n\n" % kit.get("sponsor", "无")

	# 显示该球队球员的球衣号码
	text += "=== 球员球衣号码 ===\n\n"
	var players = team.get("players", [])
	for pid in players:
		var player = PlayerDatabase.get_player(pid)
		if player.is_empty():
			continue
		var jersey = player.get("jersey_number", 0)
		var name = player.get("name", pid)
		var pos = PlayerDatabase.get_player_primary_position(pid)
		text += "  #%d %s (%s)\n" % [jersey, name, pos]

	detail_label.text = text
