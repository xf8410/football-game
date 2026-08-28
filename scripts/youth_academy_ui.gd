## youth_academy_ui.gd
## 青训营界面
extends Control

@onready var youth_list = $VBox/HBox/LeftPanel/ScrollContainer/YouthList
@onready var detail_label = $VBox/HBox/RightPanel/DetailLabel
@onready var level_label = $VBox/HBox/RightPanel/LevelLabel
@onready var scout_button = $VBox/HBox/RightPanel/ScoutButton
@onready var upgrade_button = $VBox/HBox/RightPanel/UpgradeButton
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		YouthAcademy.save_state()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	scout_button.pressed.connect(_on_scout)
	upgrade_button.pressed.connect(_on_upgrade)
	_update_ui()

func _update_ui():
	var data = YouthAcademy.get_academy_data()
	level_label.text = "青训营等级: %d / 10  |  名额: %d/%d  |  球探等级: %d" % [
		data.level, data.youth_players.size(), data.max_slots, data.scout_level
	]
	scout_button.text = "🔍 搜索球员 (花费%d)" % (500 * data.scout_level)
	upgrade_button.text = "⬆ 升级青训营 (%d金币)" % data.upgrade_cost

	# 更新青训球员列表
	for child in youth_list.get_children():
		child.queue_free()

	var youths = YouthAcademy.get_youth_players()
	if youths.is_empty():
		var label = Label.new()
		label.text = "暂无青训球员，点击「搜索球员」寻找新人"
		label.add_theme_font_size_override("font_size", 16)
		youth_list.add_child(label)
		return

	for youth in youths:
		var btn = Button.new()
		btn.text = "%s  %s  %d岁  评分%d" % [
			youth.name, youth.position, youth.age, youth.current_rating
		]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(func(): _show_detail(youth))
		youth_list.add_child(btn)

func _show_detail(youth: Dictionary):
	var text = "=== 青训球员 ===\n\n"
	text += "姓名: %s\n" % youth.name
	text += "国籍: %s\n" % youth.nationality
	text += "位置: %s\n" % youth.position
	text += "年龄: %d岁\n" % youth.age
	text += "当前评分: %d\n" % youth.current_rating
	text += "潜力评分: %d\n\n" % youth.potential_rating
	text += "=== 属性 ===\n"
	for attr in youth.attributes:
		text += "  %s: %d\n" % [attr, youth.attributes[attr]]
	text += "\n=== 特性 ===\n"
	for t in youth.traits:
		text += "  %s\n" % t
	text += "\n=== 技能 ===\n"
	for s in youth.skills:
		text += "  %s\n" % s
	text += "\n训练进度: %d/%d XP\n" % [youth.training_xp, youth.training_xp_needed]
	detail_label.text = text

func _on_scout():
	var youth = YouthAcademy.scout_youth_player()
	if youth.is_empty():
		detail_label.text = "❌ 搜索失败！\n\n金币不足或青训营已满"
	else:
		detail_label.text = "✅ 发现新球员！\n\n%s (%s)\n年龄: %d\n评分: %d (潜力: %d)" % [
			youth.name, youth.position, youth.age, youth.current_rating, youth.potential_rating
		]
	_update_ui()

func _on_upgrade():
	if YouthAcademy.upgrade_academy():
		detail_label.text = "✅ 青训营升级成功！"
	else:
		detail_label.text = "❌ 升级失败！\n\n金币不足"
	_update_ui()
