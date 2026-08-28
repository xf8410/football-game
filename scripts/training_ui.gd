## training_ui.gd
## 训练/升级界面
## 参考《FC足球世界》的训练界面
## 功能：选择球员 → 消耗经验卡 → 升级 → 属性提升
extends Control

var selected_player_id: String = ""
var player_card_scene = preload("res://scenes/PlayerCard.tscn")
var current_card: Control = null

@onready var player_list = $HBox/LeftPanel/ScrollContainer/PlayerList
@onready var card_container = $HBox/CenterPanel/CardContainer
@onready var detail_panel = $HBox/RightPanel/DetailLabel
@onready var level_label = $HBox/RightPanel/LevelLabel
@onready var xp_bar = $HBox/RightPanel/XPBar
@onready var upgrade_button = $HBox/RightPanel/UpgradeButton
@onready var back_button = $BackButton
@onready var xp_cards_label = $HBox/RightPanel/XPCardsLabel

# 经验卡数量
var xp_cards: Dictionary = {
	"small": 10,   # +100 XP
	"medium": 5,   # +500 XP
	"large": 2,    # +2000 XP
}

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	upgrade_button.pressed.connect(_on_upgrade)
	_populate_player_list()

func _populate_player_list():
	for child in player_list.get_children():
		child.queue_free()

	# 获取阵容中所有球员
	var squad = SquadManager.get_all_squad_players()
	if squad.is_empty():
		# 如果没有阵容，显示所有球员
		var all_players = PlayerDatabase.players_data
		for pid in all_players:
			_add_player_button(pid)
	else:
		for pid in squad:
			_add_player_button(pid)

func _add_player_button(pid: String):
	var player = PlayerDatabase.get_player(pid)
	if player.is_empty():
		return
	var btn = Button.new()
	btn.text = "%s (%d)" % [player.get("short_name", pid), PlayerDatabase.get_player_rating(pid)]
	btn.custom_minimum_size = Vector2(200, 40)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(func(): _select_player(pid))
	player_list.add_child(btn)

func _select_player(pid: String):
	selected_player_id = pid
	_show_player_card()
	_update_detail()

func _show_player_card():
	# 清除旧卡片
	if current_card:
		current_card.queue_free()

	# 创建新卡片
	current_card = player_card_scene.instantiate()
	current_card.set_player(selected_player_id)
	card_container.add_child(current_card)

func _update_detail():
	if selected_player_id == "":
		return

	var dev = PlayerDevelopment.get_development(selected_player_id)
	var player = PlayerDatabase.get_player(selected_player_id)

	level_label.text = "等级: %d / %d" % [dev.level, PlayerDevelopment.MAX_LEVEL]
	xp_bar.min_value = 0
	xp_bar.max_value = dev.xp_to_next
	xp_bar.value = dev.xp
	xp_bar.tooltip_text = "%d / %d XP" % [dev.xp, dev.xp_to_next]

	xp_cards_label.text = "经验卡: 小×%d(+100) 中×%d(+500) 大×%d(+2000)" % [
		xp_cards.small, xp_cards.medium, xp_cards.large
	]

	var text = "=== 球员信息 ===\n"
	text += "姓名: %s\n" % player.get("name", "")
	text += "国籍: %s\n" % player.get("nationality", "")
	text += "位置: %s\n" % ", ".join(PlayerDatabase.get_player_positions(selected_player_id))
	text += "惯用脚: %s\n\n" % player.get("preferred_foot", "right")

	text += "=== 成长数据 ===\n"
	text += "等级: %d\n" % dev.level
	text += "经验: %d / %d\n" % [dev.xp, dev.xp_to_next]
	text += "比赛: %d场\n" % dev.matches_played
	text += "进球: %d\n" % dev.goals_scored
	text += "助攻: %d\n\n" % dev.assists

	text += "=== 属性升级 ===\n"
	for attr in dev.stat_upgrades:
		text += "  %s: +%d\n" % [attr, dev.stat_upgrades[attr]]

	text += "\n=== 操作说明 ===\n"
	text += "点击「升级」消耗经验卡提升等级\n"
	text += "每升1级获得1个属性点\n"
	text += "可在下方分配属性点\n"

	detail_panel.text = text

	# 升级按钮状态
	upgrade_button.disabled = (xp_cards.small + xp_cards.medium + xp_cards.large) == 0

func _on_upgrade():
	if selected_player_id == "":
		return

	# 优先使用大卡
	var xp_gain = 0
	if xp_cards.large > 0:
		xp_gain = 2000
		xp_cards.large -= 1
	elif xp_cards.medium > 0:
		xp_gain = 500
		xp_cards.medium -= 1
	elif xp_cards.small > 0:
		xp_gain = 100
		xp_cards.small -= 1
	else:
		return

	PlayerDevelopment.add_xp(selected_player_id, xp_gain)
	print("[Training] %s 获得 %d XP" % [selected_player_id, xp_gain])

	_update_detail()
	_show_player_card()
