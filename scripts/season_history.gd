## season_history.gd
## 赛季历史系统
## 记录每个赛季的最终排名、冠军、射手榜等
extends Node

# 历史记录
var season_history: Array = []  # [{season_id, league_id, year, standings, top_scorer, champion, ...}]

const SAVE_FILE = "user://season_history.json"

## 记录赛季结束
func record_season_end(league_id: String, standings: Array, top_scorer: Dictionary, player_team: String, player_rank: int):
	var record = {
		"season_id": "season_" + str(season_history.size() + 1),
		"league_id": league_id,
		"league_name": TeamDatabase.get_league(league_id).get("name", league_id),
		"year": Time.get_datetime_string_from_system().split(" ")[0],
		"champion": standings[0].team_id if standings.size() > 0 else "",
		"champion_name": TeamDatabase.get_team_name(standings[0].team_id) if standings.size() > 0 else "",
		"player_team": player_team,
		"player_team_name": TeamDatabase.get_team_name(player_team),
		"player_rank": player_rank,
		"standings": standings,
		"top_scorer": top_scorer,
		"total_matches": standings.size() * (standings.size() - 1),
		"total_goals": 0,
	}

	# 计算总进球
	for s in standings:
		record.total_goals += s.goals_for

	season_history.append(record)
	save_history()
	print("[SeasonHistory] 赛季已记录: %s %s, 冠军: %s, 玩家排名: %d" % [
		record.year, record.league_name, record.champion_name, player_rank
	])

## 获取所有赛季历史
func get_all_history() -> Array:
	return season_history

## 获取指定赛季
func get_season(season_id: String) -> Dictionary:
	for s in season_history:
		if s.season_id == season_id:
			return s
	return {}

## 获取玩家冠军次数
func get_player_championships() -> int:
	var count = 0
	for s in season_history:
		if s.player_team == s.champion:
			count += 1
	return count

## 获取玩家总排名记录
func get_player_rank_history() -> Array:
	var ranks = []
	for s in season_history:
		ranks.append(s.player_rank)
	return ranks

## 获取最佳排名
func get_best_rank() -> int:
	var ranks = get_player_rank_history()
	if ranks.is_empty():
		return -1
	ranks.sort()
	return ranks[0]

## 获取赛季总数
func get_total_seasons() -> int:
	return season_history.size()

## 获取历史射手榜（所有赛季）
func get_all_time_top_scorers(limit: int = 10) -> Array:
	var scorer_totals = {}
	for season in season_history:
		var ts = season.top_scorer
		if ts.is_empty():
			continue
		var pid = ts.get("player_id", "")
		if pid.is_empty():
			continue
		if not scorer_totals.has(pid):
			scorer_totals[pid] = {
				"player_id": pid,
				"player_name": ts.get("player_name", pid),
				"total_goals": 0,
				"seasons": 0,
			}
		scorer_totals[pid].total_goals += ts.get("goals", 0)
		scorer_totals[pid].seasons += 1

	var result = scorer_totals.values()
	result.sort_custom(func(a, b): return a.total_goals > b.total_goals)
	return result.slice(0, min(limit, result.size()))

## 保存历史
func save_history():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(season_history, "  "))
		file.close()

## 加载历史
func load_history():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			season_history = json.data
		file.close()
	print("[SeasonHistory] 已加载 %d 个赛季历史" % season_history.size())
