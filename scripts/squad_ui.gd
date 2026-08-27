## squad_ui.gd
## 阵容/背包界面
## 显示18人名单（11首发+7替补），支持换人、查看球员详情
extends Control

@onready var starting_container = $VBox/HBox/StartingPanel/ScrollContainer/StartingVBox
@onready var sub_container = $VBox/HBox/SubPanel/ScrollContainer/SubVBox
@onready var player_detail = $VBox/HBox/DetailPanel/DetailLabel
@onready var formation_option = $VBox/FormationBox/FormationOption
@onready var back_button = $BackButton

var selected_player_id: String = ""
var selected_slot: String = ""  # "starting" or "sub"

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	formation_option.item_selected.connect(_on_formation_changed)
	_setup_formation_option()
	_populate_squad()

func _setup_formation_option():
	formation_option.clear()
	for f in GameState.FORMATIONS.keys():
		formation_option.add_item(f)
	# 选中当前阵型
	var current = SquadManager.get_formation()
	for i in range(formation_option.item_count):
		if formation_option.get_item_text(i) == current:
			formation_option.select(i)
			break

func _on_formation_changed(index: int):
	var formation = formation_option.get_item_text(index)
	SquadManager.current_squad.formation = formation
	print("[Squad] 阵型切换为: " + formation)
	_populate_squad()

func _populate_squad():
	# 清空
	for child in starting_container.get_children():
		child.queue_free()
	for child in sub_container.get_children():
		child.queue_free()

	var starting = SquadManager.get_starting_11()
	var subs = SquadManager.get_substitutes()
	var formation_slots = GameState.FORMATIONS.get(SquadManager.get_formation(), GameState.FORMATIONS["4-4-2"])

	# 首发球员
	var header1 = Label.new()
	header1.text = "首发 11 人"
	header1.add_theme_font_size_override("font_size", 22)
	starting_container.add_child(header1)

	for i in range(starting.size()):
		var pid = starting[i]
		var slot = formation_slots[i] if i < formation_slots.size() else "ST"
		var btn = _create_player_button(pid, slot, "starting", i)
		starting_container.add_child(btn)

	# 替补球员
	var header2 = Label.new()
	header2.text = "替补席 (%d/7)" % subs.size()
	header2.add_theme_font_size_override("font_size", 22)
	sub_container.add_child(header2)

	for i in range(subs.size()):
		var pid = subs[i]
		var btn = _create_player_button(pid, "SUB", "sub", i)
		sub_container.add_child(btn)

	# 阵容评分
	var rating = SquadManager.get_squad_rating()
	var rating_label = Label.new()
	rating_label.text = "阵容总评分: %d" % rating
	rating_label.add_theme_font_size_override("font_size", 20)
	rating_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	sub_container.add_child(rating_label)

func _create_player_button(player_id: String, slot: String, group: String, index: int) -> Button:
	var player = PlayerDatabase.get_player(player_id)
	var btn = Button.new()
	var name = player.get("short_name", player.get("name", player_id))
	var positions = player.get("positions", ["ST"])
	var pos_str = "/".join(positions)
	var rating = PlayerDatabase.get_player_rating(player_id)
	btn.text = "[%s] %s (%d) - %s" % [slot, name, rating, pos_str]
	btn.custom_minimum_size = Vector2(350, 45)
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(func(): _select_player(player_id, group, index))
	return btn

func _select_player(player_id: String, group: String, index: int):
	selected_player_id = player_id
	selected_slot = group
	_update_player_detail(player_id)

func _update_player_detail(player_id: String):
	var player = PlayerDatabase.get_player(player_id)
	if player.is_empty():
		player_detail.text = "球员数据不存在"
		return

	var text = ""
	text += "=== 球员详情 ===\n\n"
	text += "姓名: %s\n" % player.get("name", "")
	text += "国籍: %s\n" % player.get("nationality", "")
	text += "位置: %s\n" % "/".join(player.get("positions", []))
	text += "惯用脚: %s\n\n" % player.get("preferred_foot", "right")

	# 属性
	text += "=== 六维属性 ===\n"
	var attrs = player.get("attributes", {})
	for attr_name in ["pace", "shooting", "passing", "dribbling", "defending", "physical"]:
		var val = attrs.get(attr_name, 70)
		var bar = _make_bar(val)
		text += "%-12s %s %d\n" % [attr_name, bar, val]

	# 特性
	text += "\n=== 特性 (%d/3) ===\n" % PlayerDevelopment.get_trait_count(player_id)
	var traits = PlayerDevelopment.get_traits(player_id)
	if traits.is_empty():
		var player_traits = player.get("traits", [])
		text += "无特性\n"
		for t in player_traits:
			var trait = TeamSpecialties.get_trait(t)
			text += "  [铜] %s - %s\n" % [trait.get("name", t), trait.get("description", "")]
	else:
		for tid in traits:
			var tier = traits[tid]
			var trait = TeamSpecialties.get_trait(tid)
			text += "  [%s] %s - %s\n" % [
				TeamSpecialties.get_tier_name(tier),
				trait.get("name", tid),
				trait.get("description", "")
			]

	# 职业生涯
	text += "\n=== 职业生涯 ===\n"
	for career in player.get("career", []):
		text += "  %s (%s)\n" % [career.get("club", ""), career.get("years", "")]

	# 特殊版本
	if player.has("special_versions"):
		text += "\n=== 特殊版本 ===\n"
		for ver_name in player.get("special_versions", {}):
			text += "  %s: %s\n" % [ver_name, player.special_versions[ver_name]]

	player_detail.text = text

func _make_bar(value: int) -> String:
	var bar_length = 20
	var filled = int(value / 100.0 * bar_length)
	return "█".repeat(filled) + "░".repeat(bar_length - filled)
