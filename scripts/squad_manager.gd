## squad_manager.gd
## 阵容管理系统 (Autoload Singleton)
## 每支球队18人名单：11首发 + 7替补（含门将）
##
## 阵容结构：
##   首发11人：GK×1 + 后卫×4 + 中场×4(或3) + 前锋×2(或3)
##   替补7人：GK×1 + 外场球员×6
extends Node

# 阵型与位置对应
const FORMATION_SLOTS = {
	"4-4-2": ["GK", "LB", "CB", "CB", "RB", "LM", "CM", "CM", "RM", "ST", "ST"],
	"4-3-3": ["GK", "LB", "CB", "CB", "RB", "CM", "CM", "CM", "LW", "ST", "RW"],
	"4-2-3-1": ["GK", "LB", "CB", "CB", "RB", "CDM", "CDM", "LW", "CAM", "RW", "ST"],
	"3-5-2": ["GK", "CB", "CB", "CB", "LM", "CM", "CM", "CM", "RM", "ST", "ST"],
	"5-3-2": ["GK", "LB", "CB", "CB", "CB", "RB", "CM", "CM", "CM", "ST", "ST"],
	"4-1-4-1": ["GK", "LB", "CB", "CB", "RB", "CDM", "LM", "CM", "CM", "RM", "ST"],
}

# 当前阵容
var current_squad: Dictionary = {
	"starting_11": [],      # 首发球员ID列表
	"substitutes": [],      # 替补球员ID列表
	"formation": "4-4-2",   # 当前阵型
	"team_id": "",          # 球队ID
}

## 设置球队阵容
func set_squad(team_id: String, formation: String, starting_11: Array, substitutes: Array) -> bool:
	if starting_11.size() != 11:
		push_error("[Squad] 首发必须11人，当前: %d" % starting_11.size())
		return false
	if substitutes.size() > 7:
		push_error("[Squad] 替补最多7人，当前: %d" % substitutes.size())
		return false

	# 检查门将数量
	var starting_gk = _count_goalkeepers(starting_11)
	var sub_gk = _count_goalkeepers(substitutes)
	if starting_gk != 1:
		push_error("[Squad] 首发必须有1名门将，当前: %d" % starting_gk)
		return false
	if sub_gk < 1:
		print("[Squad] 警告：替补没有门将")

	current_squad = {
		"starting_11": starting_11,
		"substitutes": substitutes,
		"formation": formation,
		"team_id": team_id,
	}
	print("[Squad] 阵容已设置: %s, 阵型: %s" % [team_id, formation])
	return true

## 自动生成默认阵容（从球队球员列表中选18人）
func auto_generate_squad(team_id: String) -> Dictionary:
	var team = TeamDatabase.get_team(team_id)
	var player_ids = team.get("players", [])
	var formation = team.get("formation", "4-4-2")

	if player_ids.size() < 11:
		print("[Squad] 警告：球队球员不足11人: %s (%d人)" % [team_id, player_ids.size()])
		# 补充默认球员
		while player_ids.size() < 18:
			player_ids.append("default_player")

	# 按位置分类
	var by_position = {
		"GK": [], "CB": [], "LB": [], "RB": [],
		"CDM": [], "CM": [], "CAM": [],
		"LW": [], "RW": [], "ST": [], "CF": [],
		"LM": [], "RM": [],
	}

	for pid in player_ids:
		var player = PlayerDatabase.get_player(pid)
		if player.is_empty():
			# 默认球员按ST处理
			by_position["ST"].append(pid)
			continue
		var positions = player.get("positions", ["ST"])
		var primary = positions[0]
		if by_position.has(primary):
			by_position[primary].append(pid)
		else:
			by_position["ST"].append(pid)

	# 根据阵型选择首发
	var slots = FORMATION_SLOTS.get(formation, FORMATION_SLOTS["4-4-2"])
	var starting_11 = []
	var used_players = []

	for slot in slots:
		var selected = _select_player_for_slot(slot, by_position, used_players)
		if selected == "":
			# 没有合适位置球员，从剩余中选
			selected = _select_any_available(player_ids, used_players)
		if selected != "":
			starting_11.append(selected)
			used_players.append(selected)

	# 选择替补（7人，含1门将）
	var substitutes = []
	var backup_gk = _select_player_for_slot("GK", by_position, used_players)
	if backup_gk != "":
		substitutes.append(backup_gk)
		used_players.append(backup_gk)

	# 剩余位置选6人
	for pid in player_ids:
		if substitutes.size() >= 7:
			break
		if not used_players.has(pid):
			substitutes.append(pid)
			used_players.append(pid)

	# 不足7人时补充
	while substitutes.size() < 7:
		substitutes.append("default_player")

	set_squad(team_id, formation, starting_11, substitutes)
	return current_squad

## 为位置槽选择球员
func _select_player_for_slot(slot: String, by_position: Dictionary, used: Array) -> String:
	# 优先选对应位置
	if by_position.has(slot) and by_position[slot].size() > 0:
		for pid in by_position[slot]:
			if not used.has(pid):
				return pid

	# 兼容位置
	var compat = _get_compatible_positions(slot)
	for pos in compat:
		if by_position.has(pos) and by_position[pos].size() > 0:
			for pid in by_position[pos]:
				if not used.has(pid):
					return pid

	return ""

## 获取兼容位置
func _get_compatible_positions(slot: String) -> Array:
	match slot:
		"GK": return []
		"CB": return ["CB", "LB", "RB", "CDM"]
		"LB": return ["LB", "CB", "LM", "LW"]
		"RB": return ["RB", "CB", "RM", "RW"]
		"CDM": return ["CDM", "CM", "CB"]
		"CM": return ["CM", "CDM", "CAM"]
		"CAM": return ["CAM", "CM", "LW", "RW"]
		"LW": return ["LW", "LM", "RW", "ST"]
		"RW": return ["RW", "RM", "LW", "ST"]
		"LM": return ["LM", "LW", "CM"]
		"RM": return ["RM", "RW", "CM"]
		"ST": return ["ST", "CF", "LW", "RW", "CAM"]
		"CF": return ["CF", "ST", "CAM"]
		_: return ["ST"]

## 选择任意可用球员
func _select_any_available(all_players: Array, used: Array) -> String:
	for pid in all_players:
		if not used.has(pid):
			return pid
	return "default_player"

## 统计门将数量
func _count_goalkeepers(player_ids: Array) -> int:
	var count = 0
	for pid in player_ids:
		var player = PlayerDatabase.get_player(pid)
		if player.is_empty():
			continue
		if player.get("positions", []).has("GK"):
			count += 1
	return count

## 获取首发阵容
func get_starting_11() -> Array:
	return current_squad.get("starting_11", [])

## 获取替补
func get_substitutes() -> Array:
	return current_squad.get("substitutes", [])

## 获取阵型
func get_formation() -> String:
	return current_squad.get("formation", "4-4-2")

## 获取球队ID
func get_team_id() -> String:
	return current_squad.get("team_id", "")

## 换人
func substitute(out_player_id: String, in_player_id: String) -> bool:
	var starting = current_squad.starting_11
	var subs = current_squad.substitutes

	var out_idx = starting.find(out_player_id)
	var in_idx = subs.find(in_player_id)

	if out_idx == -1 or in_idx == -1:
		return false

	starting[out_idx] = in_player_id
	subs[in_idx] = out_player_id

	current_squad.starting_11 = starting
	current_squad.substitutes = subs
	print("[Squad] 换人: %s 下, %s 上" % [out_player_id, in_player_id])
	return true

## 获取阵容中所有球员ID（18人）
func get_all_squad_players() -> Array:
	return current_squad.starting_11 + current_squad.substitutes

## 获取阵容总评分
func get_squad_rating() -> int:
	var total = 0
	var count = 0
	for pid in current_squad.starting_11:
		var rating = PlayerDatabase.get_player_rating(pid)
		total += rating
		count += 1
	if count == 0:
		return 0
	return int(total / count)
