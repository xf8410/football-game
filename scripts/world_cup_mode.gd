## world_cup_mode.gd
## 世界杯模式
## 32支球队参赛，小组赛+淘汰赛
extends Node

signal world_cup_started()
signal group_stage_completed()
signal world_cup_finished(champion: String)

# 世界杯数据
var world_cup_data: Dictionary = {
	"stage": "not_started",  # not_started / group_stage / round_of_16 / qf / sf / final / finished
	"groups": [],            # 8个小组，每组4队
	"knockout": {},          # 淘汰赛对阵
	"champion": "",
	"player_team": "",
}

## 开始世界杯
func start_world_cup(player_team: String) -> bool:
	# 获取所有国家队
	var all_national = TeamDatabase.get_all_national_teams()
	var team_ids = all_national.keys()

	if team_ids.size() < 8:
		print("[WorldCup] 国家队数量不足")
		return false

	# 如果不足32队，循环添加
	while team_ids.size() < 32:
		team_ids.append(team_ids[randi() % team_ids.size()])

	# 随机选32队
	team_ids.shuffle()
	team_ids = team_ids.slice(0, 32)

	world_cup_data.player_team = player_team
	world_cup_data.stage = "group_stage"

	# 分8组，每组4队
	world_cup_data.groups = []
	for i in range(8):
		var group = {
			"name": "Group " + char(65 + i),  # Group A, B, C...
			"teams": team_ids.slice(i * 4, (i + 1) * 4),
			"standings": [],
		}
		# 初始化积分榜
		for tid in group.teams:
			group.standings.append({
				"team_id": tid,
				"played": 0, "won": 0, "drawn": 0, "lost": 0,
				"goals_for": 0, "goals_against": 0, "points": 0,
			})
		world_cup_data.groups.append(group)

	world_cup_started.emit()
	print("[WorldCup] 世界杯开始！%d支球队，%d个小组" % [team_ids.size(), world_cup_data.groups.size()])
	return true

## 模拟小组赛
func simulate_group_stage():
	for group in world_cup_data.groups:
		# 每组6场比赛（单循环）
		var teams = group.teams
		var matches = [
			[0, 1], [2, 3], [0, 2], [1, 3], [0, 3], [1, 2]
		]

		for m in matches:
			var home = teams[m[0]]
			var away = teams[m[1]]

			# 玩家的比赛跳过（由玩家手动踢）
			if home == world_cup_data.player_team or away == world_cup_data.player_team:
				continue

			# 模拟AI比赛
			var result = _simulate_match(home, away)
			_update_group_standing(group, home, away, result.home_goals, result.away_goals)

	# 排序积分榜
	for group in world_cup_data.groups:
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
	print("[WorldCup] 小组赛结束，16强产生")

## 模拟比赛
func _simulate_match(home_id: String, away_id: String) -> Dictionary:
	var home_rating = TeamDatabase.get_team_rating(home_id)
	var away_rating = TeamDatabase.get_team_rating(away_id)
	home_rating += 5  # 主场优势

	var diff = home_rating - away_rating
	var home_expected = 1.4 + diff * 0.03
	var away_expected = 1.1 - diff * 0.03

	var home_goals = max(0, int(round(home_expected + randf_range(-1.2, 1.2))))
	var away_goals = max(0, int(round(away_expected + randf_range(-1.2, 1.2))))

	return {"home_goals": home_goals, "away_goals": away_goals}

## 更新小组积分榜
func _update_group_standing(group: Dictionary, home_id: String, away_id: String, home_goals: int, away_goals: int):
	for s in group.standings:
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

## 获取16强
func get_round_of_16() -> Array:
	var r16 = []
	for group in world_cup_data.groups:
		if group.standings.size() >= 2:
			r16.append(group.standings[0].team_id)  # 小组第一
			r16.append(group.standings[1].team_id)  # 小组第二
	return r16

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
		"quarter_final": return "四分之一决赛"
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

## 清除世界杯
func clear_world_cup():
	world_cup_data = {
		"stage": "not_started",
		"groups": [],
		"knockout": {},
		"champion": "",
		"player_team": "",
	}
