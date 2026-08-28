## trophy_room_ui.gd
## 奖杯陈列室
## 展示玩家获得的所有奖杯和奖项
extends Control

@onready var stats_label = $VBox/StatsLabel
@onready var trophies_container = $VBox/ScrollContainer/TrophiesVBox
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	AwardSystem.load_awards()
	_update_ui()

func _update_ui():
	var total = AwardSystem.get_total_awards()
	stats_label.text = "🏆 已获得 %d 个奖项" % total

	for child in trophies_container.get_children():
		child.queue_free()

	var awards = AwardSystem.get_all_awards()
	var earned = AwardSystem.get_earned_awards()

	# 按分类分组
	var categories = {
		"individual_annual": "个人年度奖项",
		"team_world_cup": "世界杯奖项",
		"tournament_individual": "赛事个人奖项",
		"league": "联赛奖项",
		"continental": "洲际杯赛奖项",
	}

	for cat_key in categories:
		var cat_title = Label.new()
		cat_title.text = "=== " + categories[cat_key] + " ==="
		cat_title.add_theme_font_size_override("font_size", 20)
		cat_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
		trophies_container.add_child(cat_title)

		var has_any = false
		for aid in awards:
			var award = awards[aid]
			if award.category != cat_key:
				continue

			# 检查是否已获得
			var count = AwardSystem.get_award_count(aid)
			var is_earned = count > 0
			has_any = has_any or is_earned

			var row = HBoxContainer.new()
			row.custom_minimum_size = Vector2(0, 60)
			row.theme_override_constants/separation = 15

			# 奖杯图标
			var icon = Label.new()
			icon.text = award.icon if is_earned else "🔒"
			icon.add_theme_font_size_override("font_size", 32)
			icon.custom_minimum_size = Vector2(50, 0)
			icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(icon)

			var vbox = VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var name_label = Label.new()
			var count_text = " ×%d" % count if count > 1 else ""
			name_label.text = award.name + count_text if is_earned else award.name
			name_label.add_theme_font_size_override("font_size", 16)
			if is_earned:
				name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
			else:
				name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			vbox.add_child(name_label)

			var desc_label = Label.new()
			desc_label.text = award.description
			desc_label.add_theme_font_size_override("font_size", 12)
			desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			vbox.add_child(desc_label)

			row.add_child(vbox)

			# 声望
			var prestige_label = Label.new()
			prestige_label.text = "声望\n%d" % award.prestige
			prestige_label.custom_minimum_size = Vector2(60, 0)
			prestige_label.add_theme_font_size_override("font_size", 12)
			prestige_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if is_earned:
				prestige_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
			row.add_child(prestige_label)

			trophies_container.add_child(row)

		if not has_any:
			var empty = Label.new()
			empty.text = "  （暂未获得）"
			empty.add_theme_font_size_override("font_size", 13)
			empty.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			trophies_container.add_child(empty)

		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 15)
		trophies_container.add_child(spacer)
