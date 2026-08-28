## achievement_ui.gd
## 成就界面
extends Control

@onready var stats_label = $VBox/StatsLabel
@onready var tab_container = $VBox/TabContainer
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	_populate_achievements()

func _populate_achievements():
	var unlocked = AchievementSystem.get_unlocked_count()
	var total = AchievementSystem.get_all_achievements().size()
	stats_label.text = "已解锁: %d / %d" % [unlocked, total]

	var categories = {
		"比赛": "match",
		"进球": "goal",
		"收集": "collection",
		"联赛": "league",
		"杯赛": "cup",
		"特殊": "special",
	}

	var tab_idx = 0
	for display_name in categories:
		var category = categories[display_name]
		var container = _get_tab_container(tab_idx)
		if container == null:
			continue
		_populate_category(container, category)
		tab_idx += 1

func _get_tab_container(idx: int) -> VBoxContainer:
	var tab_name = ["比赛", "进球", "收集", "联赛", "杯赛", "特殊"][idx]
	var tab = tab_container.get_node_or_null(tab_name)
	if tab == null:
		return null
	var scroll = tab.get_node_or_null("ScrollContainer")
	if scroll == null:
		return null
	return scroll.get_node_or_null("VBox")

func _populate_category(container: VBoxContainer, category: String):
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()

	var ids = AchievementSystem.get_achievements_by_category(category)
	for aid in ids:
		var ach = AchievementSystem.get_all_achievements()[aid]
		var unlocked = AchievementSystem.is_unlocked(aid)
		var progress = AchievementSystem.get_progress(aid)

		var row = Panel.new()
		row.custom_minimum_size = Vector2(0, 70)

		var vbox = VBoxContainer.new()
		vbox.position = Vector2(10, 5)
		vbox.size = Vector2(540, 60)

		var title = Label.new()
		var status_icon = "✅" if unlocked else "🔒"
		title.text = "%s %s" % [status_icon, ach.name]
		title.add_theme_font_size_override("font_size", 16)
		if unlocked:
			title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		vbox.add_child(title)

		var desc = Label.new()
		desc.text = ach.description
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(desc)

		var progress_label = Label.new()
		if unlocked:
			progress_label.text = "✓ 已解锁"
			progress_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		else:
			progress_label.text = "进度: %d / %d" % [progress, ach.target]
			progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
		progress_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(progress_label)

		# 奖励
		var reward_text = "奖励: "
		if ach.reward.has("coins"):
			reward_text += "%d金币" % ach.reward.coins
		if ach.reward.has("item"):
			var pack = CardDrawSystem.get_pack(ach.reward.item)
			reward_text += " + %s" % pack.get("name", ach.reward.item)
		var reward_label = Label.new()
		reward_label.text = reward_text
		reward_label.add_theme_font_size_override("font_size", 11)
		reward_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		vbox.add_child(reward_label)

		row.add_child(vbox)
		container.add_child(row)
