## continental_cup.gd
## 洲际杯赛系统（欧冠/欧联/欧协联）
## 与现有71支俱乐部关联
##
## 真实赛制（2024-25新规则）：
##   欧冠：36支球队，瑞士模式联赛阶段（8场），前8直接进16强，9-24踢附加赛
##   欧联：36支球队，同样瑞士模式
##   欧协联：第三级别
##
## 晋级资格分配：
##   联赛冠军 → 欧冠正赛
##   联赛2-4名 → 欧冠
##   联赛5-6名 → 欧联
##   联赛7-8名 → 欧协联
##
## 必须踢赢联赛才能打欧冠
extends Node

signal qualification_earned(cup_type: int, team_id: String)
signal cup_stage_advanced(cup_type: int, new_stage: String)
signal cup_finished(cup_type: int, champion: String)

# 杯赛类型
enum CupType {
	CHAMPIONS_LEAGUE,  # 欧冠
	EUROPA_LEAGUE,     # 欧联
	CONFERENCE_LEAGUE, # 欧协联
}

# 杯赛阶段
enum Stage {
	NOT_STARTED,
	LEAGUE_PHASE,      # 联赛阶段（瑞士模式）
	KNOCKOUT_PLAYOFFS, # 淘汰赛附加赛
	ROUND_OF_16,       # 十六强
	QUARTER_FINAL,     # 八强
	SEMI_FINAL,        # 四强
	FINAL,             # 决赛
	FINISHED,          # 已结束
}

# 杯赛配置
const CUP_CONFIG = {
	CupType.CHAMPIONS_LEAGUE: {
		"name": "欧洲冠军联赛",
		"short_name": "欧冠",
		"prestige": 100,
		"prize_money": 50000,
		"team_count": 36,
		"league_phase_matches": 8,
		"direct_knockout_spots": 8,  # 前8直接进16强
		"playoff_spots": 16,         # 9-24踢附加赛
	},
	CupType.EUROPA_LEAGUE: {
		"name": "欧罗巴联赛",
		"short_name": "欧联",
		"prestige": 70,
		"prize_money": 25000,
		"team_count": 36,
		"league_phase_matches": 8,
		"direct_knockout_spots": 8,
		"playoff_spots": 16,
	},
	CupType.CONFERENCE_LEAGUE: {
		"name": "欧洲协会联赛",
		"short_name": "欧协联",
		"prestige": 40,
		"prize_money": 10000,
		"team_count": 36,
		"league_phase_matches": 6,
		"direct_knockout_spots": 8,
		"playoff_spots": 16,
	},
}

# 杯赛运行时数据
var cups: Dictionary = {}
var qualifications: Dictionary = {}  # team_id -> [cup_types]

func _ready():
	_init_cups()

func _init_cups():
	for cup_type in CupType.values():
		cups[cup_type] = {
			"stage": Stage.NOT_STARTED,
			"qualified_teams": [],
			"league_phase_table": [],  # 联赛阶段积分榜
			"knockout_bracket": [],    # 淘汰赛对阵表
			"champion": "",
			"matches_played": [],
		}

## 根据联赛最终排名分配杯赛资格
## standings: LeagueManager的积分榜
func process_league_finish(league_id: String, standings: Array) -> Dictionary:
	var result = {
		"champions_league": [],
		"europa_league": [],
		"conference_league": [],
	}

	if standings.is_empty():
		return result

	# 根据排名分配资格
	for i in range(standings.size()):
		var team_id = standings[i].team_id
		var rank = i + 1

		if rank == 1:
			# 冠军 → 欧冠
			result.champions_league.append(team_id)
			_add_qualification(team_id, CupType.CHAMPIONS_LEAGUE)
			qualification_earned.emit(CupType.CHAMPIONS_LEAGUE, team_id)
		elif rank <= 4:
			# 2-4名 → 欧冠
			result.champions_league.append(team_id)
			_add_qualification(team_id, CupType.CHAMPIONS_LEAGUE)
			qualification_earned.emit(CupType.CHAMPIONS_LEAGUE, team_id)
		elif rank <= 6:
			# 5-6名 → 欧联
			result.europa_league.append(team_id)
			_add_qualification(team_id, CupType.EUROPA_LEAGUE)
			qualification_earned.emit(CupType.EUROPA_LEAGUE, team_id)
		elif rank <= 8:
			# 7-8名 → 欧协联
			result.conference_league.append(team_id)
			_add_qualification(team_id, CupType.CONFERENCE_LEAGUE)
			qualification_earned.emit(CupType.CONFERENCE_LEAGUE, team_id)

	print("[ContinentalCup] 联赛资格分配完成:")
	print("  欧冠: %d队" % result.champions_league.size())
	print("  欧联: %d队" % result.europa_league.size())
	print("  欧协联: %d队" % result.conference_league.size())

	return result

## 添加资格
func _add_qualification(team_id: String, cup_type: int):
	if not qualifications.has(team_id):
		qualifications[team_id] = []
	if not qualifications[team_id].has(cup_type):
		qualifications[team_id].append(cup_type)
	# 添加到杯赛参赛队
	cups[cup_type].qualified_teams.append(team_id)

## 检查球队是否有欧冠资格
func has_champions_league_qualification(team_id: String) -> bool:
	return qualifications.has(team_id) and qualifications[team_id].has(CupType.CHAMPIONS_LEAGUE)

## 检查球队是否有欧联资格
func has_europa_league_qualification(team_id: String) -> bool:
	return qualifications.has(team_id) and qualifications[team_id].has(CupType.EUROPA_LEAGUE)

## 检查球队是否有欧协联资格
func has_conference_league_qualification(team_id: String) -> bool:
	return qualifications.has(team_id) and qualifications[team_id].has(CupType.CONFERENCE_LEAGUE)

## 获取球队的杯赛资格
func get_team_qualifications(team_id: String) -> Array:
	return qualifications.get(team_id, [])

## 开始欧冠（需要先有资格）
func start_champions_league(player_team: String) -> bool:
	if not has_champions_league_qualification(player_team):
		print("[ContinentalCup] %s 没有欧冠资格！必须先赢得联赛前4名" % player_team)
		return false

	# 如果参赛队不足36，从其他联赛补充
	var teams = cups[CupType.CHAMPIONS_LEAGUE].qualified_teams.duplicate()
	_fill_teams_to_count(teams, 36)

	cups[CupType.CHAMPIONS_LEAGUE].stage = Stage.LEAGUE_PHASE
	cups[CupType.CHAMPIONS_LEAGUE].league_phase_table = _init_league_table(teams)

	print("[ContinentalCup] 欧冠开始！%d支球队参赛" % teams.size())
	return true

## 填充球队到指定数量（从所有俱乐部中补充）
func _fill_teams_to_count(teams: Array, target_count: int):
	while teams.size() < target_count:
		var all_clubs = TeamDatabase.get_all_clubs().keys()
		all_clubs.shuffle()
		for tid in all_clubs:
			if not teams.has(tid):
				teams.append(tid)
				if teams.size() >= target_count:
					break
		break

## 初始化联赛阶段积分榜
func _init_league_table(teams: Array) -> Array:
	var table = []
	for tid in teams:
		table.append({
			"team_id": tid,
			"team_name": TeamDatabase.get_team_name(tid),
			"played": 0, "won": 0, "drawn": 0, "lost": 0,
			"goals_for": 0, "goals_against": 0, "goal_diff": 0,
			"points": 0,
		})
	return table

## 模拟联赛阶段（瑞士模式，简化为随机对阵）
func simulate_league_phase(cup_type: int):
	var cup = cups[cup_type]
	var table = cup.league_phase_table
	var config = CUP_CONFIG[cup_type]
	var match_count = config.league_phase_matches

	# 每队踢match_count场
	for team in table:
		for i in range(match_count):
			# 随机选对手
			var opponent = table[randi() % table.size()]
			if opponent.team_id == team.team_id:
				continue

			var home_goals = randi_range(0, 4)
			var away_goals = randi_range(0, 4)

			team.played += 1
			team.goals_for += home_goals
			team.goals_against += away_goals
			opponent.played += 1
			opponent.goals_for += away_goals
			opponent.goals_against += home_goals

			if home_goals > away_goals:
				team.won += 1
				team.points += 3
				opponent.lost += 1
			elif home_goals == away_goals:
				team.drawn += 1
				team.points += 1
				opponent.drawn += 1
				opponent.points += 1
			else:
				team.lost += 1
				opponent.won += 1
				opponent.points += 3

	# 排序
	table.sort_custom(func(a, b):
		if a.points != b.points:
			return a.points > b.points
		return a.goal_diff > b.goal_diff
	)

	# 更新goal_diff
	for team in table:
		team.goal_diff = team.goals_for - team.goals_against

	cup.stage = Stage.KNOCKOUT_PLAYOFFS
	cup_stage_advanced.emit(cup_type, "knockout_playoffs")
	print("[ContinentalCup] %s 联赛阶段结束" % config.short_name)

## 获取联赛阶段排名
func get_league_phase_ranking(cup_type: int) -> Array:
	return cups[cup_type].league_phase_table

## 获取直接晋级16强的球队（前8）
func get_direct_knockout_teams(cup_type: int) -> Array:
	var table = cups[cup_type].league_phase_table
	var config = CUP_CONFIG[cup_type]
	return table.slice(0, config.direct_knockout_spots)

## 获取需要踢附加赛的球队（9-24）
func get_playoff_teams(cup_type: int) -> Array:
	var table = cups[cup_type].league_phase_table
	var config = CUP_CONFIG[cup_type]
	return table.slice(config.direct_knockout_spots, config.direct_knockout_spots + config.playoff_spots)

## 模拟淘汰赛
func simulate_knockout(cup_type: int):
	var cup = cups[cup_type]
	var config = CUP_CONFIG[cup_type]

	# 获取16强
	var r16 = get_direct_knockout_teams(cup_type)
	# 附加赛胜者加入（简化：随机选8个）
	var playoff_teams = get_playoff_teams(cup_type)
	playoff_teams.shuffle()
	r16.append_array(playoff_teams.slice(0, 8))

	# 16强 → 8强 → 4强 → 决赛
	var current_round = r16
	var stages = [Stage.ROUND_OF_16, Stage.QUARTER_FINAL, Stage.SEMI_FINAL, Stage.FINAL]

	for stage in stages:
		cup.stage = stage
		cup_stage_advanced.emit(cup_type, get_stage_name(stage))

		var next_round = []
		for i in range(0, current_round.size(), 2):
			if i + 1 >= current_round.size():
				next_round.append(current_round[i])
				break
			var team_a = current_round[i]
			var team_b = current_round[i + 1]

			# 两回合（简化为一场）
			var a_goals = randi_range(0, 3)
			var b_goals = randi_range(0, 3)
			if a_goals > b_goals:
				next_round.append(team_a)
			elif b_goals > a_goals:
				next_round.append(team_b)
			else:
				# 平局随机
				next_round.append(team_a if randf() > 0.5 else team_b)

		current_round = next_round

	# 冠军
	cup.champion = current_round[0].team_id
	cup.stage = Stage.FINISHED
	cup_finished.emit(cup_type, cup.champion)
	print("[ContinentalCup] %s 冠军: %s" % [config.short_name, TeamDatabase.get_team_name(cup.champion)])

## 获取杯赛数据
func get_cup_data(cup_type: int) -> Dictionary:
	return cups[cup_type]

## 获取所有杯赛
func get_all_cups() -> Dictionary:
	return cups

## 获取阶段名称
func get_stage_name(stage: int) -> String:
	match stage:
		Stage.NOT_STARTED: return "未开始"
		Stage.LEAGUE_PHASE: return "联赛阶段"
		Stage.KNOCKOUT_PLAYOFFS: return "淘汰赛附加赛"
		Stage.ROUND_OF_16: return "十六强"
		Stage.QUARTER_FINAL: return "四分之一决赛"
		Stage.SEMI_FINAL: return "半决赛"
		Stage.FINAL: return "决赛"
		Stage.FINISHED: return "已结束"
		_: return "未知"

## 获取杯赛名称
func get_cup_name(cup_type: int) -> String:
	return CUP_CONFIG[cup_type].name

## 获取杯赛短名
func get_cup_short_name(cup_type: int) -> String:
	return CUP_CONFIG[cup_type].short_name

## 清除所有资格（新赛季开始时）
func clear_qualifications():
	qualifications.clear()
	for cup_type in cups:
		cups[cup_type].stage = Stage.NOT_STARTED
		cups[cup_type].qualified_teams.clear()
		cups[cup_type].league_phase_table.clear()
		cups[cup_type].knockout_bracket.clear()
		cups[cup_type].champion = ""
		cups[cup_type].matches_played.clear()

## 保存/加载
func save_state():
	var data = {
		"qualifications": qualifications,
		"cups": {},
	}
	for cup_type in cups:
		data.cups[str(cup_type)] = {
			"stage": cups[cup_type].stage,
			"qualified_teams": cups[cup_type].qualified_teams,
			"champion": cups[cup_type].champion,
		}
	var file = FileAccess.open("user://continental_cup.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.close()

func load_state():
	var file = FileAccess.open("user://continental_cup.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			qualifications = json.data.get("qualifications", {})
			var saved_cups = json.data.get("cups", {})
			for cup_str in saved_cups:
				var cup_type = int(cup_str)
				if cups.has(cup_type):
					cups[cup_type].stage = saved_cups[cup_str].get("stage", Stage.NOT_STARTED)
					cups[cup_type].qualified_teams = saved_cups[cup_str].get("qualified_teams", [])
					cups[cup_type].champion = saved_cups[cup_str].get("champion", "")
		file.close()
