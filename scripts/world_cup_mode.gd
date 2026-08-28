## world_cup_mode.gd
## 世界杯模式（完善版）
## 32支球队，小组赛+淘汰赛，完整流程
extends Node

signal world_cup_started()
signal group_stage_completed()
signal knockout_stage_advanced(stage: String)
signal world_cup_finished(champion: String)

# 世界杯数据
var world_cup_data: Dictionary = {
	"stage": "not_started",
	"groups": [],
	"knockout": {
		"round_of_16": [],
		"quarter_final": [],
		"semi_final": [],
		"final": [],
	},
	"champion": "",
	"player_team": "",
	"matches_played": 0,
}

## 开始世界杯
func start_world_cup(player_team: String) -> bool:
	var all_national = TeamDatabase.get_all_national_teams()
	var team_ids = all_national.keys()

	if team_ids.size() < 8:
		print("[WorldCup] 国家队数量不足")
		return false

	# 如果不足32队，循环添加
	while team_ids.size() < 32:
		team_ids.append(team_ids[randi() % team_ids.size()])

	team_ids.shuffle()
	team_ids = team_ids.slice(0, 32)

	world_cup_data.player_team = player_team
	world_cup_data.stage = "group_stage"
	world_cup_data.matches_played = 0

	# 分8组
	world_cup_data.groups = []
	for i in range(8):
		var group = {
			"name": "Group " + char(65 + i),
			"teams": team_ids.slice(i * 4, (i + 1) * 4),
			"standings": [],
			"matches": [],
		}
		for tid in group.teams:
			group.standings.append({
				"team_id": tid,
				"played": 0, "won": 0, "drawn": 0, "lost": 0,
				"goals_for": 0, "goals_against": 0, "points": 0,
			})
		world_cup_data.groups.append(group)

	world_cup_started.emit()
	print("[WorldCup] 世界杯开始！32支球队，8个小组")
	return true

## 模拟小组赛
func simulate_group_stage():
	for group in world_cup_data.groups:
		var teams = group.teams
		# 每组6场比赛（单循环）
		for i in range(teams.size()):
			for j in range(i + 1, teams.size()):
				var home = teams[i]
				var away = teams[j]
				var result = _simulate_match(home, away)
				_update_standings(group.standings, home, away, result.home_goals, result.away_goals)
				group.matches.append({
					"home": home, "away": away,
					"home_goals": result.home_goals, "away_goals": result.away_goals,
				})
				world_cup_data.matches_played += 1

		# 排序积分榜
		group.standings.sort_custom(func(a, b):
			if a.points != b.points:
				return a.points > b.points
			var gd_a = a.goals_for - a.goals_against
			var gd_b = b.goals_for - b.goals_against
			if gd_a != gd_b:
				return gd_a > gd_b
			return a.goals_for > b.goals_for
		)

	world_cup_data.stage = "round_of_16"
	group_stage_completed.emit()

	# 生成16强对阵
	_generate_round_of_16()
	print("[WorldCup] 小组赛结束，进入16强")

## 生成16强对阵
func _generate_round_of_16():
	var r16 = []
	# 每组前2名出线
	for i in range(8):
		var group = world_cup_data.groups[i]
		r16.append(group.standings[0].team_id)  # 小组第一
	# 第二名交叉对阵
	var seconds = []
	for i in range(8):
		seconds.append(world_cup_data.groups[i].standings[1].team_id)

	# A1 vs B2, B1 vs A2, C1 vs D2...
	for i in range(8):
		var first = r16[i]
		var second_idx = (i + 1) % 8
		var second = seconds[second_idx]
		world_cup_data.knockout.round_of_16.append({
			"home": first, "away": second,
			"played": false, "winner": "",
		})

## 模拟淘汰赛
func simulate_knockout_round(stage: String) -> bool:
	var matches = []
	match stage:
		"round_of_16":
			matches = world_cup_data.knockout.round_of_16
		"quarter_final":
			matches = world_cup_data.knockout.quarter_final
		"semi_final":
			matches = world_cup_data.knockout.semi_final
		"final":
			matches = world_cup_data.knockout.final
		_:
			return false

	# 模拟比赛
	for match in matches:
		if match.played:
			continue
		var result = _simulate_match(match.home, match.away)
		# 淘汰赛不允许平局
		var home_goals = result.home_goals
		var away_goals = result.away_goals
		if home_goals == away_goals:
			# 加时赛/点球
			if randf() < 0.5:
				home_goals += 1
			else:
				away_goals += 1
		match.home_goals = home_goals
		match.away_goals = away_goals
		match.winner = match.home if home_goals > away_goals else match.away
		match.played = true
		world_cup_data.matches_played += 1

	# 推进到下一轮
	_advance_to_next_stage(stage)
	return true

## 推进到下一轮
func _advance_to_next_stage(current_stage: String):
	var winners = []
	var matches = []
	match current_stage:
		"round_of_16":
			matches = world_cup_data.knockout.round_of_16
		"quarter_final":
			matches = world_cup_data.knockout.quarter_final
		"semi_final":
			matches = world_cup_data.knockout.semi_final

	for m in matches:
		winners.append(m.winner)

	match current_stage:
		"round_of_16":
			# 生成8强
			for i in range(0, winners.size(), 2):
				world_cup_data.knockout.quarter_final.append({
					"home": winners[i], "away": winners[i + 1],
					"played": false, "winner": "",
				})
			world_cup_data.stage = "quarter_final"
		"quarter_final":
			# 生成4强
			for i in range(0, winners.size(), 2):
				world_cup_data.knockout.semi_final.append({
					"home": winners[i], "away": winners[i + 1],
					"played": false, "winner": "",
				})
			world_cup_data.stage = "semi_final"
		"semi_final":
			# 生成决赛
			for i in range(0, winners.size(), 2):
				world_cup_data.knockout.final.append({
					"home": winners[i], "away": winners[i + 1],
					"played": false, "winner": "",
				})
			world_cup_data.stage = "final"
		"final":
			# 比赛结束
			world_cup_data.champion = winners[0]
			world_cup_data.stage = "finished"
			world_cup_finished.emit(winners[0])
			print("[WorldCup] 世界杯结束！冠军: %s" % TeamDatabase.get_team_name(winners[0]))

	knockout_stage_advanced.emit(world_cup_data.stage)

## 模拟比赛
func _simulate_match(home_id: String, away_id: String) -> Dictionary:
	var home_rating = TeamDatabase.get_team_rating(home_id)
	var away_rating = TeamDatabase.get_team_rating(away_id)

	# 主场优势
	home_rating += 5

	var rating_diff = home_rating - away_rating
	var home_expected = 1.5 + rating_diff * 0.03
	var away_expected = 1.3 - rating_diff * 0.03

	var home_goals = max(0, int(round(home_expected + randf_range(-1.2, 1.2))))
	var away_goals = max(0, int(round(away_expected + randf_range(-1.2, 1.2))))

	return {"home_goals": home_goals, "away_goals": away_goals}

## 更新积分榜
func _update_standings(standings: Array, home_id: String, away_id: String, home_goals: int, away_goals: int):
	for s in standings:
		if s.team_id == home_id:
			s.played += 1
			s.goals_for += home_goals
			s.goals_against += away_goals
			if home_goals > away_goals:
				s.won += 1
				s.points += 3
			elif home_goals == away_goals:
				s.drawn += 1
				s.points += 1
			else:
				s.lost += 1
		elif s.team_id == away_id:
			s.played += 1
			s.goals_for += away_goals
			s.goals_against += home_goals
			if away_goals > home_goals:
				s.won += 1
				s.points += 3
			elif away_goals == home_goals:
				s.drawn += 1
				s.points += 1
			else:
				s.lost += 1

## 获取世界杯数据
func get_world_cup_data() -> Dictionary:
	return world_cup_data

## 获取当前阶段
func get_current_stage() -> String:
	return world_cup_data.stage

## 获取阶段名称
func get_stage_name() -> String:
	match world_cup_data.stage:
		"not_started": return "未开始"
		"group_stage": return "小组赛"
		"round_of_16": return "十六强"
		"quarter_final": return "八强"
		"semi_final": return "半决赛"
		"final": return "决赛"
		"finished": return "已结束"
		_: return "未知"

## 获取玩家所在小组
func get_player_group() -> Dictionary:
	for group in world_cup_data.groups:
		if group.teams.has(world_cup_data.player_team):
			return group
	return {}

## 获取淘汰赛对阵
func get_knockout_bracket(stage: String) -> Array:
	return world_cup_data.knockout.get(stage, [])

## 获取冠军
func get_champion() -> String:
	return world_cup_data.champion

## 清除世界杯
func clear_world_cup():
	world_cup_data = {
		"stage": "not_started",
		"groups": [],
		"knockout": {
			"round_of_16": [],
			"quarter_final": [],
			"semi_final": [],
			"final": [],
		},
		"champion": "",
		"player_team": "",
		"matches_played": 0,
	}
