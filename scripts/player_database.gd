## player_database.gd
## 球员数据库 (Autoload Singleton)
## 从 JSON 加载所有球员数据，支持按球队/位置/时代查询
extends Node

var players_data: Dictionary = {}

# 位置中英文映射
const POSITION_NAMES = {
	"GK": "门将", "CB": "中后卫", "LB": "左后卫", "RB": "右后卫",
	"CDM": "后腰", "CM": "中场", "CAM": "前腰",
	"LW": "左边锋", "RW": "右边锋", "ST": "前锋", "CF": "中锋",
	"LM": "左前卫", "RM": "右前卫",
}

func _ready():
	_load_data()

func _load_data():
	var file = FileAccess.open("res://data/players.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			players_data = json.data.get("players", {})
		file.close()
	print("[PlayerDB] 已加载 %d 名球员" % players_data.size())

## 获取球员数据
func get_player(player_id: String) -> Dictionary:
	return players_data.get(player_id, {})

## 获取球员姓名
func get_player_name(player_id: String) -> String:
	var p = get_player(player_id)
	return p.get("name", player_id)

## 获取球员短名
func get_player_short_name(player_id: String) -> String:
	var p = get_player(player_id)
	return p.get("short_name", p.get("name", player_id))

## 获取球员位置列表
func get_player_positions(player_id: String) -> Array:
	var p = get_player(player_id)
	return p.get("positions", ["ST"])

## 获取球员首选位置
func get_player_primary_position(player_id: String) -> String:
	var positions = get_player_positions(player_id)
	return positions[0] if positions.size() > 0 else "ST"

## 获取球员属性
func get_player_attributes(player_id: String) -> Dictionary:
	var p = get_player(player_id)
	return p.get("attributes", {})

## 获取球员特征
func get_player_traits(player_id: String) -> Array:
	var p = get_player(player_id)
	return p.get("traits", [])

## 获取球员在某俱乐部的时代数据
func get_player_at_club(player_id: String, club_id: String) -> Dictionary:
	var p = get_player(player_id)
	var career = p.get("career", [])
	for era in career:
		if era.get("club") == club_id:
			return era
	return {}

## 检查球员是否属于某球队（当前或历史）
func is_player_in_team(player_id: String, team_id: String) -> bool:
	var p = get_player(player_id)
	var career = p.get("career", [])
	for era in career:
		if era.get("club") == team_id:
			return true
	return false

## 获取球员的"特殊版本"（如年度C罗、时刻C罗等）
func get_player_special_versions(player_id: String) -> Dictionary:
	var p = get_player(player_id)
	return p.get("special_versions", {})

## 获取球员巅峰期所在俱乐部
func get_player_peak_club(player_id: String) -> String:
	var p = get_player(player_id)
	return p.get("era_peak", "")

## 根据球队ID获取球员列表（含位置信息）
func get_players_for_team(team_id: String) -> Array:
	var result = []
	for pid in players_data:
		if is_player_in_team(pid, team_id):
			var p = players_data[pid]
			result.append({
				"id": pid,
				"name": p.get("name", pid),
				"short_name": p.get("short_name", p.get("name", pid)),
				"positions": p.get("positions", ["ST"]),
				"attributes": p.get("attributes", {}),
				"traits": p.get("traits", []),
				"nationality": p.get("nationality", ""),
			})
	return result

## 获取位置中文名
func get_position_name(pos_code: String) -> String:
	return POSITION_NAMES.get(pos_code, pos_code)

## 计算球员总体评分（基于属性）
func get_player_overall(player_id: String) -> int:
	var attrs = get_player_attributes(player_id)
	if attrs.is_empty():
		return 75
	# 门将特殊计算
	if attrs.has("gk_diving"):
		var gk_avg = (attrs.get("gk_diving", 80) + attrs.get("gk_handling", 80) +
					  attrs.get("gk_kicking", 80) + attrs.get("gk_reflexes", 80) +
					  attrs.get("gk_positioning", 80)) / 5.0
		return int(gk_avg)
	# 场上球员
	var pace = attrs.get("pace", 70)
	var shooting = attrs.get("shooting", 70)
	var passing = attrs.get("passing", 70)
	var dribbling = attrs.get("dribbling", 70)
	var defending = attrs.get("defending", 70)
	var physical = attrs.get("physical", 70)
	# 根据位置加权
	var pos = get_player_primary_position(player_id)
	match pos:
		"ST", "CF":
			return int(shooting * 0.3 + pace * 0.2 + dribbling * 0.2 + physical * 0.15 + passing * 0.15)
		"LW", "RW":
			return int(pace * 0.25 + dribbling * 0.25 + shooting * 0.2 + passing * 0.15 + physical * 0.15)
		"CAM":
			return int(passing * 0.3 + dribbling * 0.25 + shooting * 0.2 + pace * 0.15 + physical * 0.1)
		"CM":
			return int(passing * 0.25 + dribbling * 0.2 + defending * 0.2 + physical * 0.2 + pace * 0.15)
		"CDM":
			return int(defending * 0.3 + physical * 0.25 + passing * 0.2 + dribbling * 0.15 + pace * 0.1)
		"CB":
			return int(defending * 0.35 + physical * 0.25 + pace * 0.15 + passing * 0.15 + dribbling * 0.1)
		"LB", "RB":
			return int(pace * 0.25 + defending * 0.25 + physical * 0.2 + passing * 0.15 + dribbling * 0.15)
		_:
			return int((pace + shooting + passing + dribbling + defending + physical) / 6.0)

## 搜索球员
func search_players(query: String) -> Array:
	var results = []
	query = query.to_lower()
	for pid in players_data:
		var p = players_data[pid]
		if p.get("name", "").to_lower().find(query) >= 0 or \
		   p.get("short_name", "").to_lower().find(query) >= 0 or \
		   pid.find(query) >= 0:
			results.append({"id": pid, "data": p})
	return results
