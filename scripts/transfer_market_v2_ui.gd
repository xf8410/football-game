## transfer_market_v2_ui.gd
## 转会市场界面 v2
## 显示球员转会路径和市场价值
extends Control

@onready var market_list = $VBox/HBox/LeftPanel/ScrollContainer/MarketList
@onready var detail_label = $VBox/HBox/RightPanel/DetailLabel
@onready var budget_label = $VBox/BudgetLabel
@onready var refresh_button = $VBox/RefreshButton
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		TransferMarket.save_state()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	refresh_button.pressed.connect(_on_refresh)
	TransferMarket.load_state()
	_update_ui()

func _on_refresh():
	TransferMarket.refresh_market_manual()
	_update_ui()

func _update_ui():
	budget_label.text = "💰 预算: %d 金币" % TransferMarket.get_budget()

	for child in market_list.get_children():
		child.queue_free()

	var market_players = TransferMarket.get_market_players()
	# 按评分排序
	market_players.sort_custom(func(a, b): return a.rating > b.rating)

	for p in market_players:
		var btn = Button.new()
		btn.text = "%s  %s  %d  💰%d" % [
			p.name, p.position, p.rating, p.price
		]
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(func(): _show_detail(p))
		market_list.add_child(btn)

func _show_detail(market_player: Dictionary):
	var player = PlayerDatabase.get_player(market_player.player_id)
	var text = "=== 球员详情 ===\n\n"
	text += "姓名: %s\n" % market_player.name
	text += "位置: %s\n" % market_player.position
	text += "评分: %d\n" % market_player.rating
	text += "转会费: %d 金币\n" % market_player.price
	text += "周薪: %d 金币\n" % market_player.weekly_wage
	text += "合同: %d 周\n" % market_player.contract_weeks
	text += "年龄: %d 岁\n\n" % market_player.age

	# 显示当前俱乐部
	var club = player.get("club", "")
	var is_national = player.get("is_national", false)
	if not club.is_empty():
		if is_national:
			text += "当前: 🌍 %s\n" % club
		else:
			var team = TeamDatabase.get_team(club)
			text += "当前: %s\n" % team.get("name", club)
		text += "球衣号码: #%d\n" % player.get("jersey_number", 0)
		text += "时期: %s\n" % player.get("era", "")
		text += "年份: %s\n\n" % player.get("years", "")

	# 显示转会路径
	text += "=== 转会路径 ===\n\n"
	var base_id = player.get("base_player_id", market_player.player_id)
	var all_versions = []
	for pid in PlayerDatabase.players_data:
		var p = PlayerDatabase.get_player(pid)
		if p.get("base_player_id", "") == base_id:
			all_versions.append(pid)

	# 按version_index排序
	all_versions.sort_custom(func(a, b):
		var pa = PlayerDatabase.get_player(a)
		var pb = PlayerDatabase.get_player(b)
		return pa.get("version_index", 0) < pb.get("version_index", 0)
	)

	for i in range(all_versions.size()):
		var pid = all_versions[i]
		var p = PlayerDatabase.get_player(pid)
		var p_club = p.get("club", "")
		var p_is_national = p.get("is_national", false)
		var club_name = p_club
		if p_is_national:
			club_name = "🌍 " + p_club
		else:
			var team = TeamDatabase.get_team(p_club)
			club_name = team.get("name", p_club)

		var arrow = ""
		if i > 0:
			arrow = "    ↓\n"
		var current_marker = " ← 当前" if pid == market_player.player_id else ""
		text += "%s%s #%d (%s)%s\n" % [
			arrow, club_name, p.get("jersey_number", 0), p.get("years", ""), current_marker
		]

	# 属性
	text += "\n=== 六维属性 ===\n"
	var attrs = player.get("attributes", {})
	for attr in ["pace", "shooting", "passing", "dribbling", "defending", "physical"]:
		var val = attrs.get(attr, 70)
		var bar_len = int(val / 5)
		var bar = "█".repeat(bar_len) + "░".repeat(20 - bar_len)
		text += "%-10s %s %d\n" % [attr, bar, val]

	detail_label.text = text
