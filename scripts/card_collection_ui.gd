## card_collection_ui.gd
## 球员卡牌图鉴界面
## 显示：收集进度、按稀有度筛选、已收集/未收集球员
extends Control

var current_rarity_filter: int = -1  # -1=全部, 0-4=对应稀有度

@onready var stats_label = $VBox/StatsLabel
@onready var filter_container = $VBox/FilterContainer
@onready var grid_container = $VBox/ScrollContainer/GridContainer
@onready var back_button = $BackButton
@onready var detail_panel = $VBox/DetailPanel
@onready var detail_label = $VBox/DetailPanel/DetailLabel

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	_create_filter_buttons()
	_update_ui()

func _create_filter_buttons():
	for child in filter_container.get_children():
		child.queue_free()

	# "全部"按钮
	var all_btn = Button.new()
	all_btn.text = "全部"
	all_btn.custom_minimum_size = Vector2(100, 40)
	all_btn.add_theme_font_size_override("font_size", 14)
	all_btn.pressed.connect(func(): _set_filter(-1))
	filter_container.add_child(all_btn)

	# 各稀有度按钮
	var rarity_names = ["普通", "稀有", "史诗", "传奇", "时刻"]
	var rarity_colors = [
		Color(0.8, 0.8, 0.8),
		Color(0.3, 0.5, 1.0),
		Color(0.7, 0.3, 0.9),
		Color(1.0, 0.84, 0.0),
		Color(1.0, 0.4, 0.7),
	]
	for i in range(5):
		var btn = Button.new()
		btn.text = rarity_names[i]
		btn.custom_minimum_size = Vector2(100, 40)
		btn.add_theme_font_size_override("font_size", 14)
		btn.modulate = rarity_colors[i]
		var rarity = i
		btn.pressed.connect(func(): _set_filter(rarity))
		filter_container.add_child(btn)

func _set_filter(rarity: int):
	current_rarity_filter = rarity
	_update_grid()

func _update_ui():
	_update_stats()
	_update_grid()

func _update_stats():
	var stats = CardCollection.get_stats()
	var text = "📊 图鉴进度: %d / %d  (%.1f%%)  |  总卡数: %d\n" % [
		stats.total_unique, stats.total_available,
		stats.progress * 100, stats.total_cards
	]
	text += "稀有度分布: 普通%d | 稀有%d | 史诗%d | 传奇%d | 时刻%d" % [
		stats.by_rarity.get(0, 0),
		stats.by_rarity.get(1, 0),
		stats.by_rarity.get(2, 0),
		stats.by_rarity.get(3, 0),
		stats.by_rarity.get(4, 0),
	]
	stats_label.text = text

func _update_grid():
	for child in grid_container.get_children():
		child.queue_free()

	var all_players = PlayerDatabase.players_data.keys()
	var collected = CardCollection.get_collected_player_ids()

	# 筛选
	var display_list = []
	for pid in all_players:
		var is_collected = collected.has(pid)
		if current_rarity_filter == -1:
			display_list.append({"id": pid, "collected": is_collected})
		else:
			if is_collected:
				var card = CardCollection.get_card_info(pid)
				if card.best_rarity == current_rarity_filter:
					display_list.append({"id": pid, "collected": true})

	# 按评分排序
	display_list.sort_custom(func(a, b):
		var ra = PlayerDatabase.get_player_rating(a.id)
		var rb = PlayerDatabase.get_player_rating(b.id)
		return ra > rb
	)

	# 创建卡片
	for item in display_list:
		var card = _create_card_widget(item.id, item.collected)
		grid_container.add_child(card)

func _create_card_widget(player_id: String, is_collected: bool) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(180, 240)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 5
	vbox.offset_top = 5
	vbox.offset_right = -5
	vbox.offset_bottom = -5
	card.add_child(vbox)

	if is_collected:
		var player = PlayerDatabase.get_player(player_id)
		var card_info = CardCollection.get_card_info(player_id)
		var rating = PlayerDatabase.get_player_rating(player_id)
		var rarity = card_info.best_rarity

		# 卡片背景色（按稀有度）
		var rarity_colors = [
			Color(0.3, 0.3, 0.3),
			Color(0.15, 0.25, 0.5),
			Color(0.3, 0.15, 0.4),
			Color(0.4, 0.3, 0.05),
			Color(0.4, 0.15, 0.3),
		]
		card.modulate = rarity_colors[rarity]

		# 评分
		var rating_label = Label.new()
		rating_label.text = str(rating)
		rating_label.add_theme_font_size_override("font_size", 28)
		rating_label.add_theme_color_override("font_color", CardDrawSystem.get_rarity_color(rarity))
		rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(rating_label)

		# 位置
		var pos_label = Label.new()
		pos_label.text = PlayerDatabase.get_player_primary_position(player_id)
		pos_label.add_theme_font_size_override("font_size", 16)
		pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(pos_label)

		# 球员名
		var name_label = Label.new()
		name_label.text = player.get("short_name", player_id)
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(name_label)

		# 稀有度
		var rarity_label = Label.new()
		rarity_label.text = CardDrawSystem.get_rarity_name(rarity)
		rarity_label.add_theme_font_size_override("font_size", 12)
		rarity_label.add_theme_color_override("font_color", CardDrawSystem.get_rarity_color(rarity))
		rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(rarity_label)

		# 持有数量
		if card_info.count > 1:
			var count_label = Label.new()
			count_label.text = "×%d" % card_info.count
			count_label.add_theme_font_size_override("font_size", 12)
			count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(count_label)

		# 点击查看详情
		card.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				_show_detail(player_id)
		)
	else:
		# 未收集的球员显示为问号
		card.modulate = Color(0.15, 0.15, 0.15)

		var q_label = Label.new()
		q_label.text = "???"
		q_label.add_theme_font_size_override("font_size", 48)
		q_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
		q_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(q_label)

		var lock_label = Label.new()
		lock_label.text = "未收集"
		lock_label.add_theme_font_size_override("font_size", 12)
		lock_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lock_label)

	return card

func _show_detail(player_id: String):
	var player = PlayerDatabase.get_player(player_id)
	var card_info = CardCollection.get_card_info(player_id)
	var rating = PlayerDatabase.get_player_rating(player_id)

	var text = "=== 球员详情 ===\n\n"
	text += "姓名: %s\n" % player.get("name", "")
	text += "国籍: %s\n" % player.get("nationality", "")
	text += "位置: %s\n" % ", ".join(PlayerDatabase.get_player_positions(player_id))
	text += "评分: %d\n" % rating
	text += "稀有度: %s\n" % CardDrawSystem.get_rarity_name(card_info.best_rarity)
	text += "持有数量: %d\n" % card_info.count
	text += "首次获得: %s\n\n" % card_info.get("first_obtained", "")

	text += "=== 六维属性 ===\n"
	var attrs = player.get("attributes", {})
	for attr in ["pace", "shooting", "passing", "dribbling", "defending", "physical"]:
		var val = attrs.get(attr, 70)
		var bar_len = int(val / 5)
		var bar = "█".repeat(bar_len) + "░".repeat(20 - bar_len)
		text += "%-10s %s %d\n" % [attr, bar, val]

	text += "\n=== 特性 ===\n"
	for t in player.get("traits", []):
		var trait = TeamSpecialties.get_trait(t)
		text += "  %s\n" % trait.get("name", t)

	text += "\n=== 被动技能 ===\n"
	for s in player.get("skills", []):
		var skill = SkillSystem.get_skill_info(s)
		text += "  %s (%s)\n" % [skill.get("name", s), SkillSystem.get_context_name(skill.get("trigger", 0))]

	# 分解按钮（如果有重复）
	if card_info.count > 1:
		text += "\n⚠️ 持有 %d 张重复，可分解获得金币\n" % (card_info.count - 1)

	detail_label.text = text
