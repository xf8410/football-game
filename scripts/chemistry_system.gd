## chemistry_system.gd
## 球员化学反应系统 (Autoload Singleton)
## 功能：同俱乐部/同国籍/同联赛球员配合加成
##
## 化学反应类型：
##   1. 俱乐部默契 - 同俱乐部球员越多，配合越好
##   2. 国家队默契 - 同国籍球员越多，配合越好
##   3. 联赛默契 - 同联赛球员越多，配合越好
##   4. 位置配合 - 相邻位置球员配合加成
##   5. 宿敌激励 - 阵容中有宿敌球队的球员，全队加成
extends Node

# 化学反应加成
var team_chemistry: Dictionary = {
	"club": {},        # club_id -> count
	"nationality": {}, # nationality -> count
	"league": {},      # league_id -> count
	"total_score": 0,  # 总化学反应分（0-100）
	"buffs": {},       # 激活的buff
}

## 计算阵容化学反应
func calculate_chemistry(player_ids: Array) -> Dictionary:
	var club_count = {}
	var nationality_count = {}
	var league_count = {}
	var clubs = []
	var total_score = 0.0
	var buffs = {}

	# 统计各分类数量
	for pid in player_ids:
		var player = PlayerDatabase.get_player(pid)
		if player.is_empty():
			continue

		# 俱乐部
		var club_id = _get_player_club(pid)
		if not club_id.is_empty():
			club_count[club_id] = club_count.get(club_id, 0) + 1
			if not clubs.has(club_id):
				clubs.append(club_id)

		# 国籍
		var nationality = player.get("nationality", "")
		if not nationality.is_empty():
			nationality_count[nationality] = nationality_count.get(nationality, 0) + 1

		# 联赛
		var league_id = _get_club_league(club_id)
		if not league_id.is_empty():
			league_count[league_id] = league_count.get(league_id, 0) + 1

	# 计算俱乐部默契分（最多30分）
	var club_score = 0.0
	for cid in club_count:
		var count = club_count[cid]
		if count >= 11:
			club_score += 30
		elif count >= 9:
			club_score += 25
		elif count >= 7:
			club_score += 20
		elif count >= 5:
			club_score += 15
		elif count >= 3:
			club_score += 10
	club_score = min(club_score, 30.0)

	# 计算国籍默契分（最多25分）
	var nationality_score = 0.0
	for nat in nationality_count:
		var count = nationality_count[nat]
		if count >= 8:
			nationality_score += 25
		elif count >= 6:
			nationality_score += 20
		elif count >= 4:
			nationality_score += 15
		elif count >= 2:
			nationality_score += 8
	nationality_score = min(nationality_score, 25.0)

	# 计算联赛默契分（最多25分）
	var league_score = 0.0
	for lid in league_count:
		var count = league_count[lid]
		if count >= 11:
			league_score += 25
		elif count >= 9:
			league_score += 20
		elif count >= 7:
			league_score += 15
		elif count >= 5:
			league_score += 10
	league_score = min(league_score, 25.0)

	# 宿敌激励（最多20分）
	var rivalry_score = 0.0
	for cid in club_count:
		var rivals = TeamSpecialties.get_rivals(cid)
		for rid in rivals:
			if club_count.has(rid):
				rivalry_score += 10
	rivalry_score = min(rivalry_score, 20.0)

	total_score = club_score + nationality_score + league_score + rivalry_score

	# 生成buff
	if club_score >= 20:
		buffs["club_synergy"] = {"all_stats": int(club_score / 5), "desc": "俱乐部默契"}
	if nationality_score >= 15:
		buffs["national_synergy"] = {"all_stats": int(nationality_score / 5), "desc": "国家队默契"}
	if league_score >= 15:
		buffs["league_synergy"] = {"all_stats": int(league_score / 5), "desc": "联赛默契"}
	if rivalry_score > 0:
		buffs["rivalry_motivation"] = {"all_stats": int(rivalry_score / 5), "desc": "宿敌激励"}

	team_chemistry = {
		"club": club_count,
		"nationality": nationality_count,
		"league": league_count,
		"total_score": int(total_score),
		"buffs": buffs,
		"club_score": int(club_score),
		"nationality_score": int(nationality_score),
		"league_score": int(league_score),
		"rivalry_score": int(rivalry_score),
	}

	return team_chemistry

## 获取球员当前俱乐部
func _get_player_club(player_id: String) -> String:
	var player = PlayerDatabase.get_player(player_id)
	if player.is_empty():
		return ""
	var career = player.get("career", [])
	if career.is_empty():
		return ""
	# 返回最后一个俱乐部（当前俱乐部）
	return career[-1].get("club", "")

## 获取俱乐部所属联赛
func _get_club_league(club_id: String) -> String:
	if club_id.is_empty():
		return ""
	var team = TeamDatabase.get_team(club_id)
	return team.get("league", "")

## 获取化学反应总分
func get_total_chemistry() -> int:
	return team_chemistry.get("total_score", 0)

## 获取化学反应等级
func get_chemistry_grade() -> String:
	var score = get_total_chemistry()
	if score >= 90:
		return "S+ 完美"
	elif score >= 80:
		return "S 优秀"
	elif score >= 70:
		return "A 良好"
	elif score >= 50:
		return "B 一般"
	elif score >= 30:
		return "C 较差"
	else:
		return "D 很差"

## 获取所有激活的buff
func get_active_buffs() -> Dictionary:
	return team_chemistry.get("buffs", {})

## 获取化学反应对球员属性的加成
func get_player_buff(player_id: String) -> Dictionary:
	var buff = {"all_stats": 0}
	var player = PlayerDatabase.get_player(player_id)
	if player.is_empty():
		return buff

	var club_id = _get_player_club(player_id)
	var nationality = player.get("nationality", "")
	var league_id = _get_club_league(club_id)

	# 俱乐部加成
	if team_chemistry.club.has(club_id):
		var count = team_chemistry.club[club_id]
		if count >= 11:
			buff.all_stats += 5
		elif count >= 9:
			buff.all_stats += 4
		elif count >= 7:
			buff.all_stats += 3
		elif count >= 5:
			buff.all_stats += 2
		elif count >= 3:
			buff.all_stats += 1

	# 国籍加成
	if team_chemistry.nationality.has(nationality):
		var count = team_chemistry.nationality[nationality]
		if count >= 8:
			buff.all_stats += 4
		elif count >= 6:
			buff.all_stats += 3
		elif count >= 4:
			buff.all_stats += 2
		elif count >= 2:
			buff.all_stats += 1

	# 联赛加成
	if team_chemistry.league.has(league_id):
		var count = team_chemistry.league[league_id]
		if count >= 11:
			buff.all_stats += 4
		elif count >= 9:
			buff.all_stats += 3
		elif count >= 7:
			buff.all_stats += 2
		elif count >= 5:
			buff.all_stats += 1

	# 宿敌激励（全队加成）
	for cid in team_chemistry.club:
		var rivals = TeamSpecialties.get_rivals(cid)
		for rid in rivals:
			if team_chemistry.club.has(rid):
				buff.all_stats += 2
				break

	return buff

## 获取化学反应详情文本
func get_chemistry_detail() -> String:
	var text = "=== 阵容化学反应 ===\n\n"
	text += "总分: %d/100 (%s)\n\n" % [get_total_chemistry(), get_chemistry_grade()]

	text += "俱乐部默契: %d分\n" % team_chemistry.get("club_score", 0)
	for cid in team_chemistry.club:
		var team = TeamDatabase.get_team(cid)
		text += "  %s: %d人\n" % [team.get("name", cid), team_chemistry.club[cid]]

	text += "\n国籍默契: %d分\n" % team_chemistry.get("nationality_score", 0)
	for nat in team_chemistry.nationality:
		text += "  %s: %d人\n" % [nat, team_chemistry.nationality[nat]]

	text += "\n联赛默契: %d分\n" % team_chemistry.get("league_score", 0)
	for lid in team_chemistry.league:
		var league = TeamDatabase.get_league(lid)
		text += "  %s: %d人\n" % [league.get("name", lid), team_chemistry.league[lid]]

	text += "\n宿敌激励: %d分\n" % team_chemistry.get("rivalry_score", 0)

	text += "\n=== 激活的Buff ===\n"
	var buffs = get_active_buffs()
	if buffs.is_empty():
		text += "无\n"
	for bid in buffs:
		text += "  %s: 全属性+%d\n" % [buffs[bid].desc, buffs[bid].all_stats]

	return text
