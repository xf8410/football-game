## cup_manager.gd
## 杯赛管理器 (Autoload Singleton)
## 支持两种模式：
##   1. 淘汰赛 (Knockout) - 单场淘汰，含16强/8强/4强/决赛
##   2. 小组赛 (Group Stage) - 分组循环+淘汰赛
extends Node

signal cup_round_completed(results: Array)
signal cup_finished(champion: String)

var cup_type: String = ""  # "knockout" or "group_stage"
var cup_name: String = ""
var teams: Array = []  # 参赛球队ID列表
var player_team: String = ""
var current_round: int = 0
var bracket: Array = []  # 淘汰赛对阵表
var groups: Array = []   # 小组赛分组
var is_finished: bool = false

## 开始淘汰赛
func start_knockout_cup(name: String, team_ids: Array, player: String) -> void:
	cup_type = "knockout"
	cup_name = name
	teams = team_ids.duplicate()
	player_team = player
	current_round = 0
	is_finished = false

	# 确保球队数为2的幂
	var size = _next_power_of_2(teams.size())
	while teams.size() < size:
		teams.append("bye")

	# 生成对阵
	bracket = _generate_bracket(teams)
	print("[Cup] 淘汰赛开始: %s, %d支球队" % [name, teams.size()])

## 开始小组赛
func start_group_cup(name: String, team_ids: Array, player: String) -> void:
	cup_type = "group_stage"
	cup_name = name
	teams = team_ids.duplicate()
	player_team = player
	current_round = 0
	is_finished = false

	# 分组（每组4队）
	groups = _generate_groups(teams, 4)
	print("[Cup] 小组赛开始: %s, %d支球队, %d组" % [name, teams.size(), groups.size()])

## 生成淘汰赛对阵表
func _generate_bracket(team_list: Array) -> Array:
	var round_matches = []
	for i in range(0, team_list.size(), 2):
		round_matches.append({
			"home": team_list[i],
			"away": team_list[i + 1],
			"played": false,
			"home_goals": 0,
			"away_goals": 0,
			"winner": "",
		})
	return [round_matches]

## 生成分组
func _generate_groups(team_list: Array, group_size: int) -> Array:
	var shuffled = team_list.duplicate()
	shuffled.shuffle()

	var result = []
	var num_groups = ceil(float(shuffled.size()) / group_size)
	for g in range(num_groups):
		var group = []
		for i in range(group_size):
			var idx = g * group_size + i
			if idx < shuffled.size():
				group.append({
					"team_id": shuffled[idx],
					"played": 0,
					"won": 0,
					"drawn": 0,
					"lost": 0,
					"gf": 0,
					"ga": 0,
					"points": 0,
				})
		result.append({"teams": group, "matches": _generate_group_matches(group)})
	return result

## 生成小组赛比赛
func _generate_group_matches(group: Array) -> Array:
	var matches = []
	for i in range(group.size()):
		for j in range(i + 1, group.size()):
			matches.append({
				"home": group[i].team_id,
				"away": group[j].team_id,
				"played": false,
				"home_goals": 0,
				"away_goals": 0,
			})
	return matches

## 获取当前轮次比赛
func get_current_round_matches() -> Array:
	if cup_type == "knockout":
		if current_round < bracket.size():
			return bracket[current_round]
	elif cup_type == "group_stage":
		# 返回所有小组的当前轮次
		var all_matches = []
		for group in groups:
			# 简化：返回所有未比赛的小组赛
			for match in group.matches:
				if not match.played:
					all_matches.append(match)
					break  # 每组只返回一场
		return all_matches
	return []

## 获取玩家下一场杯赛
func get_next_player_match() -> Dictionary:
	var matches = get_current_round_matches()
	for match in matches:
		if match.home == player_team or match.away == player_team:
			return match
	return {}

## 记录玩家比赛结果
func record_player_result(home_goals: int, away_goals: int) -> void:
	var player_match = get_next_player_match()
	if player_match.is_empty():
		return

	player_match.played = true
	player_match.home_goals = home_goals
	player_match.away_goals = away_goals

	if home_goals > away_goals:
		player_match.winner = player_match.home
	elif away_goals > home_goals:
		player_match.winner = player_match.away
	else:
		# 平局，随机晋级（简化处理）
		player_match.winner = player_match.home if randf() > 0.5 else player_match.away

	# 模拟其他比赛
	_simulate_other_matches()

	# 检查是否进入下一轮
	_advance_round()

## 模拟其他比赛
func _simulate_other_matches():
	var matches = get_current_round_matches()
	for match in matches:
		if match.played:
			continue
		if match.home == "bye" or match.away == "bye":
			match.winner = match.home if match.home != "bye" else match.away
			match.played = true
			continue

		var home_rating = TeamDatabase.get_team_rating(match.home) + 5  # 主场优势
		var away_rating = TeamDatabase.get_team_rating(match.away)
		var diff = home_rating - away_rating
		var hg = max(0, int(round(1.5 + diff * 0.03 + randf_range(-1.2, 1.2))))
		var ag = max(0, int(round(1.3 - diff * 0.03 + randf_range(-1.2, 1.2))))

		match.home_goals = hg
		match.away_goals = ag
		match.played = true
		if hg > ag:
			match.winner = match.home
		elif ag > hg:
			match.winner = match.away
		else:
			match.winner = match.home if randf() > 0.5 else match.away

## 推进到下一轮
func _advance_round():
	if cup_type == "knockout":
		var current_matches = bracket[current_round]
		var all_played = true
		for match in current_matches:
			if not match.played:
				all_played = false
				break

		if all_played:
			var winners = []
			for match in current_matches:
				winners.append(match.winner)

			if winners.size() <= 1:
				# 比赛结束
				is_finished = true
				cup_finished.emit(winners[0] if winners.size() == 1 else "")
				return

			# 生成下一轮
			var next_round = []
			for i in range(0, winners.size(), 2):
				if i + 1 < winners.size():
					next_round.append({
						"home": winners[i],
						"away": winners[i + 1],
						"played": false,
						"home_goals": 0,
						"away_goals": 0,
						"winner": "",
					})
			bracket.append(next_round)
			current_round += 1
			cup_round_completed.emit(next_round)

## 获取当前轮次名称
func get_round_name() -> String:
	if cup_type != "knockout":
		return "小组赛"
	var teams_in_round = 1
	for i in range(current_round + 1, 10):
		teams_in_round = pow(2, i)
		if teams_in_round >= bracket[current_round].size() * 2:
			break
	var num = bracket[current_round].size() * 2
	match num:
		2: return "决赛"
		4: return "半决赛"
		8: return "四分之一决赛"
		16: return "八分之一决赛"
		32: return "三十二强"
		_: return "第%d轮" % (current_round + 1)

## 下一个2的幂
func _next_power_of_2(n: int) -> int:
	var p = 1
	while p < n:
		p *= 2
	return p

## 清除杯赛
func clear_cup():
	cup_type = ""
	cup_name = ""
	teams = []
	player_team = ""
	current_round = 0
	bracket = []
	groups = []
	is_finished = false
