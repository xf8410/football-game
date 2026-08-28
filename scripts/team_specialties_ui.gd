## team_specialties_ui.gd
## 球队特性界面
## 参考《FC足球世界》/《最佳球会》的球队特性界面
## 4个标签页：俱乐部 / 国家 / 联赛 / 球员主题
extends Control

var current_category: int = 0  # 0=俱乐部, 1=国家, 2=联赛, 3=球员主题
var selected_item: String = ""

@onready var tab_container = $VBox/TabBar
@onready var left_panel = $VBox/HBox/LeftPanel/ScrollContainer/ItemList
@onready var right_panel = $VBox/HBox/RightPanel
@onready var detail_label = $VBox/HBox/RightPanel/ScrollContainer/DetailLabel
@onready var apply_button = $VBox/HBox/RightPanel/ApplyButton
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	apply_button.pressed.connect(_on_apply)

	# 连接标签切换
	for i in range(tab_container.get_tab_count()):
		pass  # TabBar信号在下方手动连接

	tab_container.tab_changed.connect(_on_tab_changed)

	_populate_items()

func _on_tab_changed(tab: int):
	current_category = tab
	_populate_items()

func _populate_items():
	# 清空
	for child in left_panel.get_children():
		child.queue_free()

	var squad_players = SquadManager.get_all_squad_players()

	match current_category:
		0:  # 俱乐部
			_populate_clubs(squad_players)
		1:  # 国家
			_populate_nations(squad_players)
		2:  # 联赛
			_populate_leagues(squad_players)
		3:  # 球员主题
			_populate_themes(squad_players)

func _populate_clubs(squad_players: Array):
	# 统计每个俱乐部的球员数
	var club_counts = {}
	for pid in squad_players:
		var player = PlayerDatabase.get_player(pid)
		if player.is_empty():
			continue
		for career in player.get("career", []):
			var club = career.get("club", "")
			if club != "":
				club_counts[club] = club_counts.get(club, 0) + 1

	# 显示俱乐部列表
	for club_id in club_counts:
		var club = TeamDatabase.get_team(club_id)
		if club.is_empty():
			continue
		var count = club_counts[club_id]
		var btn = Button.new()
		btn.text = "%s (%d人)" % [club.get("name", club_id), count]
		btn.custom_minimum_size = Vector2(280, 50)
		btn.pressed.connect(func(): _select_item(club_id, count))
		left_panel.add_child(btn)

func _populate_nations(squad_players: Array):
	var nation_counts = {}
	for pid in squad_players:
		var player = PlayerDatabase.get_player(pid)
		if player.is_empty():
			continue
		var nation = player.get("nationality", "")
		if nation != "":
			nation_counts[nation] = nation_counts.get(nation, 0) + 1

	for nation in nation_counts:
		var count = nation_counts[nation]
		var btn = Button.new()
		btn.text = "%s (%d人)" % [nation, count]
		btn.custom_minimum_size = Vector2(280, 50)
		btn.pressed.connect(func(): _select_item(nation, count))
		left_panel.add_child(btn)

func _populate_leagues(squad_players: Array):
	var league_counts = {}
	for pid in squad_players:
		var player = PlayerDatabase.get_player(pid)
		if player.is_empty():
			continue
		for career in player.get("career", []):
			var club_id = career.get("club", "")
			var club = TeamDatabase.get_team(club_id)
			var league = club.get("league", "")
			if league != "":
				league_counts[league] = league_counts.get(league, 0) + 1

	for league_id in league_counts:
		var league = TeamDatabase.get_league(league_id)
		var count = league_counts[league_id]
		var btn = Button.new()
		btn.text = "%s (%d人)" % [league.get("name", league_id), count]
		btn.custom_minimum_size = Vector2(280, 50)
		btn.pressed.connect(func(): _select_item(league_id, count))
		left_panel.add_child(btn)

func _populate_themes(squad_players: Array):
	var themes = TeamSpecialties.get_all_themes()
	for theme_id in themes:
		var theme = themes[theme_id]
		var btn = Button.new()
		btn.text = "%s" % theme.get("name", theme_id)
		btn.custom_minimum_size = Vector2(280, 50)
		btn.pressed.connect(func(): _select_item(theme_id, 0))
		left_panel.add_child(btn)

func _select_item(item_id: String, player_count: int):
	selected_item = item_id
	_update_detail(item_id, player_count)

func _update_detail(item_id: String, player_count: int):
	var text = ""
	text += "=== 特性详情 ===\n\n"

	if current_category == 0:  # 俱乐部
		var club = TeamDatabase.get_team(item_id)
		text += "俱乐部: %s\n" % club.get("name", item_id)
		text += "当前阵容该俱乐部球员: %d人\n\n" % player_count

		# 宿敌信息
		var rivals = TeamSpecialties.get_rivals(item_id)
		if rivals.size() > 0:
			text += "宿敌球队:\n"
			for rid in rivals:
				var rteam = TeamDatabase.get_team(rid)
				text += "  - %s\n" % rteam.get("name", rid)
			text += "\n宿敌加成: 对阵宿敌时全队+5全属性\n\n"

	elif current_category == 1:  # 国家
		text += "国家: %s\n" % item_id
		text += "当前阵容该国籍球员: %d人\n\n" % player_count

	elif current_category == 2:  # 联赛
		var league = TeamDatabase.get_league(item_id)
		text += "联赛: %s\n" % league.get("name", item_id)
		text += "当前阵容该联赛球员: %d人\n\n" % player_count

	elif current_category == 3:  # 球员主题
		var theme = TeamSpecialties.get_all_themes().get(item_id, {})
		text += "主题: %s\n" % theme.get("name", item_id)
		text += "描述: %s\n" % theme.get("description", "")
		text += "加成: 全属性+%d\n\n" % theme.get("buff", {}).get("all_stats", 0)

	# 显示buff阶梯
	text += "=== 人数加成阶梯 ===\n"
	for tier in TeamSpecialties.BUFF_TIERS:
		text += "  %d人: 全属性+%d (%d星)\n" % [
			tier.min_players,
			tier.buff.all_stats,
			tier.stars
		]

	detail_label.text = text

func _on_apply():
	if selected_item == "":
		return
	TeamSpecialties.active_specialties[current_category] = selected_item
	print("[Specialties] 已应用特性: %s (分类: %d)" % [selected_item, current_category])
	# 显示确认
	detail_label.text += "\n\n✅ 特性已应用！"
