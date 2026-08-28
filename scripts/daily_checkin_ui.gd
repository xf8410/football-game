## daily_checkin_ui.gd
## 每日签到界面
extends Control

@onready var streak_label = $VBox/StreakLabel
@onready var rewards_container = $VBox/ScrollContainer/RewardsVBox
@onready var checkin_button = $VBox/CheckinButton
@onready var result_label = $VBox/ResultLabel
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	checkin_button.pressed.connect(_on_checkin)
	_update_ui()

func _update_ui():
	var streak = DailyCheckin.get_current_streak()
	var total = DailyCheckin.get_total_checkins()
	streak_label.text = "🔥 连续签到: %d 天  |  累计签到: %d 次" % [streak, total]

	# 显示7天奖励表
	for child in rewards_container.get_children():
		child.queue_free()

	var rewards = DailyCheckin.get_reward_table()
	var today_status = DailyCheckin.get_today_status()

	for reward in rewards:
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 50)
		row.theme_override_constants/separation = 10

		# 天数
		var day_label = Label.new()
		day_label.text = "第%d天" % reward.day
		day_label.custom_minimum_size = Vector2(80, 0)
		day_label.add_theme_font_size_override("font_size", 16)
		row.add_child(day_label)

		# 奖励内容
		var reward_label = Label.new()
		reward_label.text = reward.name
		reward_label.custom_minimum_size = Vector2(200, 0)
		reward_label.add_theme_font_size_override("font_size", 14)
		row.add_child(reward_label)

		# 状态标记
		var status_label = Label.new()
		status_label.custom_minimum_size = Vector2(100, 0)
		status_label.add_theme_font_size_override("font_size", 14)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if reward.day < today_status.day:
			status_label.text = "✓ 已领"
			status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		elif reward.day == today_status.day:
			if today_status.claimed:
				status_label.text = "✓ 今日已领"
				status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
			else:
				status_label.text = "🎁 今日可领"
				status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		else:
			status_label.text = "未解锁"
			status_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

		row.add_child(status_label)
		rewards_container.add_child(row)

	# 更新签到按钮状态
	if DailyCheckin.can_checkin_today():
		checkin_button.disabled = false
		checkin_button.text = "🎁 立即签到"
		result_label.text = "今天还未签到，点击领取奖励！"
		result_label.modulate = Color(1, 0.9, 0.5)
	else:
		checkin_button.disabled = true
		checkin_button.text = "✓ 今日已签到"
		result_label.text = "明天再来吧！"
		result_label.modulate = Color(0.6, 0.6, 0.6)

func _on_checkin():
	var reward = DailyCheckin.checkin()
	if reward.is_empty():
		return

	var text = "🎉 签到成功！\n\n"
	text += "第 %d 天签到奖励：\n" % reward.day
	text += "💰 %d 金币\n" % reward.coins
	if not reward.item.is_empty():
		var pack = CardDrawSystem.get_pack(reward.item)
		text += "🎴 %s（已自动开启）\n" % pack.get("name", reward.item)
	result_label.text = text
	result_label.modulate = Color(0.5, 1.0, 0.5)

	_update_ui()
