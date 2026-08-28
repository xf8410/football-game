## awards_ui.gd
## 奖项界面
extends Control

@onready var awards_container = $VBox/ScrollContainer/AwardsVBox
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	AwardSystem.load_data()
	_update_ui()

func _update_ui():
	for child in awards_container.get_children():
		child.queue_free()

	var awards = AwardSystem.get_all_awards()

	# 按类别分组
	var categories = {
		"individual_annual": "个人年度奖项",
		"team_tournament": "团队赛事奖项",
		"tournament_individual": "赛事个人奖项",
		"league": "联赛奖项",
	}

	for cat_key in categories:
		var cat_title = Label.new()
		cat_title.text = "=== " + categories[cat_key] + " ==="
		cat_title.add_theme_font_size_override("font_size", 18)
		cat_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
		awards_container.add_child(cat_title)

		for aid in awards:
			var award = awards[aid]
			if award.category != cat_key:
				continue

			var row = HBoxContainer.new()
			row.custom_minimum_size = Vector2(0, 50)
			row.theme_override_constants/separation = 10

			# 奖项图标（颜色块）
			var icon = ColorRect.new()
			icon.custom_minimum_size = Vector2(30, 30)
			icon.color = Color.from_string(award.icon_color, Color.GRAY)
			row.add_child(icon)

			var vbox = VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var name_label = Label.new()
			name_label.text = award.name
			name_label.add_theme_font_size_override("font_size", 15)
			vbox.add_child(name_label)

			var desc_label = Label.new()
			desc_label.text = award.description + " | " + award.criteria
			desc_label.add_theme_font_size_override("font_size", 11)
			desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			vbox.add_child(desc_label)

			row.add_child(vbox)

			# 声望
			var prestige_label = Label.new()
			prestige_label.text = "声望:%d" % award.prestige
			prestige_label.custom_minimum_size = Vector2(80, 0)
			prestige_label.add_theme_font_size_override("font_size", 12)
			prestige_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
			row.add_child(prestige_label)

			awards_container.add_child(row)

		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		awards_container.add_child(spacer)
