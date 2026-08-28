## team_database.gd
## 球队数据库 (Autoload Singleton)
## 从 JSON 加载所有俱乐部和国家队数据
extends Node

var teams_data: Dictionary = {}
var clubs: Dictionary = {}
var national_teams: Dictionary = {}
var leagues: Dictionary = {}

func _ready():
	_load_data()

func _load_data():
	# 加载联赛数据
	var league_file = FileAccess.open("res://data/leagues.json", FileAccess.READ)
	if league_file:
		var json = JSON.new()
		if json.parse(league_file.get_as_text()) == OK:
			leagues = json.data.get("leagues", {})
		league_file.close()

	# 加载球队数据
	var team_file = FileAccess.open("res://data/teams.json", FileAccess.READ)
	if team_file:
		var json = JSON.new()
		if json.parse(team_file.get_as_text()) == OK:
			teams_data = json.data
			clubs = teams_data.get("clubs", {})
			national_teams = teams_data.get("national_teams", {})
		team_file.close()

	print("[TeamDB] 已加载 %d 支俱乐部, %d 支国家队" % [clubs.size(), national_teams.size()])

## 获取球队数据（俱乐部或国家队）
func get_team(team_id: String) -> Dictionary:
	if clubs.has(team_id):
		return clubs[team_id]
	if national_teams.has(team_id):
		return national_teams[team_id]
	return {}

## 获取所有俱乐部
func get_all_clubs() -> Dictionary:
	return clubs

## 获取指定联赛的俱乐部
func get_clubs_by_league(league_id: String) -> Dictionary:
	var result = {}
	for id in clubs:
		if clubs[id].get("league") == league_id:
			result[id] = clubs[id]
	return result

## 获取所有国家队
func get_all_national_teams() -> Dictionary:
	return national_teams

## 获取联赛数据
func get_league(league_id: String) -> Dictionary:
	return leagues.get(league_id, {})

## 获取所有联赛
func get_all_leagues() -> Dictionary:
	return leagues

## 获取球队颜色
func get_team_colors(team_id: String) -> Dictionary:
	var team = get_team(team_id)
	return {
		"primary": Color.from_string(team.get("primary_color", "#FFFFFF"), Color.WHITE),
		"secondary": Color.from_string(team.get("secondary_color", "#000000"), Color.BLACK),
	}

## 获取球队球员列表
func get_team_players(team_id: String) -> Array:
	var team = get_team(team_id)
	return team.get("players", [])

## 获取球队阵型
func get_team_formation(team_id: String) -> String:
	var team = get_team(team_id)
	return team.get("formation", "4-4-2")

## 获取球队评分
func get_team_rating(team_id: String) -> int:
	var team = get_team(team_id)
	return int(team.get("rating", 75))

## 获取球队中文名
func get_team_name(team_id: String) -> String:
	var team = get_team(team_id)
	return team.get("name", team_id)

## 获取球队短名
func get_team_short_name(team_id: String) -> String:
	var team = get_team(team_id)
	return team.get("short_name", team_id)

## 搜索球队（按名称模糊匹配）
func search_teams(query: String) -> Array:
	var results = []
	query = query.to_lower()
	for id in clubs:
		var team = clubs[id]
		if team.get("name", "").to_lower().find(query) >= 0 or \
		   team.get("short_name", "").to_lower().find(query) >= 0 or \
		   id.find(query) >= 0:
			results.append({"id": id, "data": team})
	for id in national_teams:
		var team = national_teams[id]
		if team.get("name", "").to_lower().find(query) >= 0 or \
		   team.get("short_name", "").to_lower().find(query) >= 0:
			results.append({"id": id, "data": team})
	return results
