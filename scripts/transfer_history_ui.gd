## transfer_history_ui.gd
## 球员转会历史界面
## 显示每个球员的转会路径（不同俱乐部版本）
extends Control

@onready var player_list = $VBox/HBox/LeftPanel/ScrollContainer/PlayerList
@onready var detail_label = $VBox/HBox/RightPanel/DetailLabel
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	_populate_players()

func _populate_players():
	for child in player_list.get_children():
		child.queue_free()

	# 按base_player_id分组
	var base_groups = {}
	for pid in PlayerDatabase.players_data:
		var player = PlayerDatabase.get_player(pid)
		if player.is_empty():
			continue
		var base_id = player.get("base_player_id", pid)
		if not base_groups.has(base_id):
			base_groups[base_id] = []
		base_groups[base_id].append(pid)

	# 按球员名排序
	var sorted_bases = base_groups.keys()
	sorted_bases.sort()

	for base_id in sorted_bases:
		var versions = base_groups[base_id]
		if versions.size() < 2:
			continue  # 只显示有多个版本的球员

		var first_player = PlayerDatabase.get_player(versions[0])
		var btn = Button.new()
		btn.text = "%s (%d个版本)" % [first_player.get("name", base_id), versions.size()]
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(func(): _show_transfer_history(base_id, versions))
		player_list.add_child(btn)

func _show_transfer_history(base_id: String, versions: Array):
	# 按version_index排序
	versions.sort_custom(func(a, b):
		var pa = PlayerDatabase.get_player(a)
		var pb = PlayerDatabase.get_player(b)
		return pa.get("version_index", 0) < pb.get("version_index", 0)
	)

	var text = "=== 转会历史 ===\n\n"
	var first_player = PlayerDatabase.get_player(versions[0])
	text += "球员: %s\n" % first_player.get("name", base_id)
	text += "国籍: %s\n" % first_player.get("nationality", "")
	text += "位置: %s\n" % ", ".join(PlayerDatabase.get_player_positions(versions[0]))
	text += "惯用脚: %s\n\n" % first_player.get("preferred_foot", "right")

	text += "=== 职业生涯路径 ===\n\n"

	for i in range(versions.size()):
		var pid = versions[i]
		var player = PlayerDatabase.get_player(pid)
		var club = player.get("club", "")
		var era = player.get("era", "")
		var years = player.get("years", "")
		var jersey = player.get("jersey_number", 0)
		var rating = PlayerDatabase.get_player_rating(pid)
		var is_national = player.get("is_national", false)

		var club_name = club
		if is_national:
			club_name = "🌍 " + club
		else:
			var team = TeamDatabase.get_team(club)
			club_name = team.get("name", club)

		# 转会箭头
		var arrow = ""
		if i > 0:
			arrow = "    ↓ 转会\n"

		text += "%s📅 %s\n" % [arrow, years]
		text += "  %s #%d (评分:%d)\n" % [club_name, jersey, rating]
		text += "  时期: %s\n\n" % era

	# 显示属性变化
	text += "=== 属性变化 ===\n\n"
	if versions.size() >= 2:
		var first = PlayerDatabase.get_player(versions[0])
		var last = PlayerDatabase.get_player(versions[-1])
		var first_attrs = first.get("attributes", {})
		var last_attrs = last.get("attributes", {})
		for attr in ["pace", "shooting", "passing", "dribbling", "defending", "physical"]:
			var v1 = first_attrs.get(attr, 0)
			var v2 = last_attrs.get(attr, 0)
			var diff = v2 - v1
			var sign = "+" if diff >= 0 else ""
			text += "  %-10s: %d → %d (%s%d)\n" % [attr, v1, v2, sign, diff]

	detail_label.text = text
