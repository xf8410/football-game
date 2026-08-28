## continental_cup_ui.gd
## 欧冠/欧联/欧协联界面
extends Control

@onready var tab_container = $VBox/TabContainer
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	ContinentalCup.load_state()
	_update_ui()

func _update_ui():
	_update_cup_tab("欧冠", CupType.CHAMPIONS_LEAGUE)
	_update_cup_tab("欧联", CupType.EUROPA_LEAGUE)
	_update_cup_tab("欧协联", CupType.CONFERENCE_LEAGUE)

func _update_cup_tab(tab_name: String, cup_type: int):
	var tab = tab_container.get_node_or_null(tab_name)
	if tab == null:
		return

	var info_label = tab.get_node_or_null("InfoLabel")
	var teams_label = tab.get_node_or_null("ScrollContainer/TeamsLabel")

	var cup = ContinentalCup.cups[cup_type]
	var config = ContinentalCup.CUP_CONFIG[cup_type]

	var text = "=== %s ===\n\n" % config.name
	text += "参赛球队: %d支\n" % config.team_count
	text += "联赛阶段: %d场\n" % config.league_phase_matches
	text += "直接晋级16强: 前%d名\n" % config.direct_knockout_spots
	text += "附加赛: 第%d-%d名\n\n" % [config.direct_knockout_spots + 1, config.direct_knockout_spots + config.playoff_spots]

	text += "当前阶段: %s\n" % ContinentalentalCup_get_stage_name(cup.stage)
	text += "已获得资格球队: %d支\n" % cup.qualified_teams.size()

	if not cup.champion.is_empty():
		text += "🏆 卫冕冠军: %s\n" % TeamDatabase.get_team_name(cup.champion)

	info_label.text = text

	# 显示已获得资格的球队
	var teams_text = "=== 已获得资格的球队 ===\n\n"
	if cup.qualified_teams.is_empty():
		teams_text += "暂无球队获得资格\n"
		teams_text += "\n需要先完成联赛才能获得资格：\n"
		teams_text += "• 联赛冠军 → 欧冠\n"
		teams_text += "• 联赛2-4名 → 欧冠\n"
		teams_text += "• 联赛5-6名 → 欧联\n"
		teams_text += "• 联赛7-8名 → 欧协联\n"
	else:
		for i in range(cup.qualified_teams.size()):
			var tid = cup.qualified_teams[i]
			teams_text += "%d. %s\n" % [i + 1, TeamDatabase.get_team_name(tid)]
	teams_label.text = teams_text

func ContinentalentalCup_get_stage_name(stage: int) -> String:
	match stage:
		ContinentalCup.Stage.NOT_STARTED: return "未开始"
		ContinentalCup.Stage.LEAGUE_PHASE: return "联赛阶段"
		ContinentalCup.Stage.KNOCKOUT_PLAYOFFS: return "淘汰赛附加赛"
		ContinentalCup.Stage.ROUND_OF_16: return "十六强"
		ContinentalCup.Stage.QUARTER_FINAL: return "八强"
		ContinentalCup.Stage.SEMI_FINAL: return "半决赛"
		ContinentalCup.Stage.FINAL: return "决赛"
		ContinentalCup.Stage.FINISHED: return "已结束"
		_: return "未知"
