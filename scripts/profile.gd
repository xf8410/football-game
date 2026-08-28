## profile.gd
## 玩家档案界面
## 显示玩家信息、比赛统计、解锁内容
extends Control

@onready var name_label = $ScrollContainer/VBox/ProfileHeader/NameLabel
@onready var level_label = $ScrollContainer/VBox/ProfileHeader/LevelLabel
@onready var coins_label = $ScrollContainer/VBox/ProfileHeader/CoinsLabel
@onready var stats_container = $ScrollContainer/VBox/StatsContainer
@onready var unlocks_container = $ScrollContainer/VBox/UnlocksContainer
@onready var back_button = $BackButton
@onready var rename_dialog = $RenameDialog
@onready var rename_edit = $RenameDialog/LineEdit

var profile: Dictionary
var team_edit: LineEdit
var team_dialog: ConfirmationDialog

func _ready():
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

	# 加载档案
	profile = SaveManager.get_profile()
	_display_profile()

	# 添加改名按钮
	var rename_btn = Button.new()
	rename_btn.text = "修改教练名"
	rename_btn.pressed.connect(func(): rename_dialog.popup_centered())
	$ScrollContainer/VBox/ProfileHeader.add_child(rename_btn)

	# 添加修改球队名按钮
	var team_btn = Button.new()
	team_btn.text = "修改球队名"
	team_btn.pressed.connect(_open_team_rename)
	$ScrollContainer/VBox/ProfileHeader.add_child(team_btn)

	# 确认改名
	rename_dialog.confirmed.connect(_on_rename_confirmed)

	# 球队改名弹窗（只创建一次，复用）
	team_dialog = ConfirmationDialog.new()
	team_dialog.title = "修改球队名"
	team_dialog.ok_button_text = "确定"
	team_dialog.cancel_button_text = "取消"
	team_edit = LineEdit.new()
	team_edit.placeholder_text = "输入球队名"
	team_edit.custom_minimum_size = Vector2(280, 40)
	var vbox = VBoxContainer.new()
	vbox.add_child(team_edit)
	team_dialog.add_child(vbox)
	add_child(team_dialog)
	team_dialog.confirmed.connect(_on_team_rename_confirmed)

func _open_team_rename():
	var my = SaveManager.get_my_team()
	team_edit.text = my.get("name", "我的球队")
	team_dialog.popup_centered()

func _on_team_rename_confirmed():
	var new_name = team_edit.text.strip_edges()
	if new_name.length() > 0 and new_name.length() <= 16:
		var my = SaveManager.get_my_team()
		my["name"] = new_name
		my["short_name"] = new_name
		SaveManager.save_my_team(my)
		print("[Profile] 球队名已修改为: " + new_name)

func _display_profile():
	name_label.text = "教练：" + str(profile.get("name", "Player"))
	level_label.text = "等级：%d  (经验：%d)" % [profile.get("level", 1), profile.get("xp", 0)]
	coins_label.text = "金币：%d" % profile.get("coins", 0)

	# 清空旧内容
	for child in stats_container.get_children():
		child.queue_free()
	for child in unlocks_container.get_children():
		child.queue_free()

	# 比赛统计
	var stats_title = Label.new()
	stats_title.text = "📊 比赛统计"
	stats_title.add_theme_font_size_override("font_size", 22)
	stats_container.add_child(stats_title)

	var stats_data = [
		["总比赛数", profile.get("matches_played", 0)],
		["胜场", profile.get("matches_won", 0)],
		["平场", profile.get("matches_drawn", 0)],
		["负场", profile.get("matches_lost", 0)],
		["进球数", profile.get("goals_scored", 0)],
		["失球数", profile.get("goals_conceded", 0)],
	]
	for item in stats_data:
		var row = _create_stat_row(item[0], str(item[1]))
		stats_container.add_child(row)

	# 胜率
	var win_rate = 0.0
	if profile.get("matches_played", 0) > 0:
		win_rate = float(profile.get("matches_won", 0)) / float(profile.get("matches_played", 0)) * 100.0
	var wr_row = _create_stat_row("胜率", "%.1f%%" % win_rate)
	stats_container.add_child(wr_row)

	# 全局统计
	var global_stats = SaveManager.load_data().get("stats", {})
	var gs_title = Label.new()
	gs_title.text = "🏆 生涯统计"
	gs_title.add_theme_font_size_override("font_size", 22)
	stats_container.add_child(gs_title)

	var gs_data = [
		["总进球", global_stats.get("total_goals", 0)],
		["总射门", global_stats.get("total_shots", 0)],
		["总传球", global_stats.get("total_passes", 0)],
		["总抢断", global_stats.get("total_tackles", 0)],
		["最高连胜", global_stats.get("best_win_streak", 0)],
		["当前连胜", global_stats.get("current_win_streak", 0)],
	]
	for item in gs_data:
		var row = _create_stat_row(item[0], str(item[1]))
		stats_container.add_child(row)

	# 解锁内容
	var unlocks_title = Label.new()
	unlocks_title.text = "🔓 已解锁内容"
	unlocks_title.add_theme_font_size_override("font_size", 22)
	unlocks_container.add_child(unlocks_title)

	var unlocks = SaveManager.load_data().get("unlocks", {})
	for category in unlocks:
		var cat_label = Label.new()
		cat_label.text = "  " + category + ": " + ", ".join(unlocks[category])
		unlocks_container.add_child(cat_label)

func _create_stat_row(label_text: String, value_text: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	var l = Label.new()
	l.text = label_text + "："
	l.custom_minimum_size = Vector2(200, 0)
	var v = Label.new()
	v.text = value_text
	row.add_child(l)
	row.add_child(v)
	return row

func _on_rename_confirmed():
	var new_name = rename_edit.text.strip_edges()
	if new_name.length() > 0 and new_name.length() <= 16:
		profile["name"] = new_name
		SaveManager.save_profile(profile)
		_display_profile()
		print("[Profile] 教练名已修改为: " + new_name)
