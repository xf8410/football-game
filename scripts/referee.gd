## referee.gd
## 裁判系统
## 处理：犯规判定、黄红牌、任意球、点球、人墙、角球、界外球
## 参考 IFAB 足球规则 (Law 12: 犯规与不当行为, Law 13: 任意球, Law 14: 点球, Law 15: 界外球, Law 16: 球门球, Law 17: 角球)
extends Node

# 犯规类型
enum FoulType {
	NONE,
	PUSH,           # 推人
	TRIP,           # 绊人
	SLIDE_TACKLE,   # 铲球犯规
	HAND_BALL,      # 手球
	DANGEROUS_PLAY, # 危险动作
	OFFSIDE,        # 越位（简化版）
}

# 处罚类型
enum CardType {
	NONE,
	YELLOW,  # 黄牌
	RED,     # 红牌
}

# 定位球类型
enum SetPieceType {
	NONE,
	DIRECT_FREE_KICK,    # 直接任意球
	INDIRECT_FREE_KICK,  # 间接任意球
	PENALTY,             # 点球
	CORNER_KICK,         # 角球
	GOAL_KICK,           # 球门球
	THROW_IN,            # 界外球
	KICKOFF,             # 开球
}

signal foul_committed(foul_data: Dictionary)
signal card_shown(player_id: int, card: int, reason: String)
signal set_piece_awarded(piece_type: int, team_id: int, position: Vector3)
signal goal_scored(team_id: int, scorer_id: int, is_own_goal: bool, goal_type: String)

# 裁判参数
var foul_detection_radius: float = 2.5
var card_threshold: float = 0.5  # 犯规严重度超过此值给黄牌
var red_card_threshold: float = 0.85  # 超过此值给红牌
var penalty_area_foul_threshold: float = 0.3  # 禁区内犯规给点球的阈值

# 比赛统计
var match_stats: Dictionary = {
	"fouls": {"home": 0, "away": 0},
	"yellow_cards": {"home": 0, "away": 0},
	"red_cards": {"home": 0, "away": 0},
	"corners": {"home": 0, "away": 0},
	"free_kicks": {"home": 0, "away": 0},
	"penalties": {"home": 0, "away": 0},
	"shots": {"home": 0, "away": 0},
	"shots_on_target": {"home": 0, "away": 0},
}

# 球员黄牌记录（防止同一场比赛两张黄牌）
var yellow_cards: Dictionary = {}  # player_id -> count

## 检查抢断是否犯规
func check_tackle_foul(tackler: Node, victim: Node, ball_pos: Vector3) -> Dictionary:
	var tackler_pos = tackler.position
	var victim_pos = victim.position
	var dist = tackler_pos.distance_to(victim_pos)

	# 距离太远不算犯规
	if dist > foul_detection_radius:
		return {"is_foul": false}

	# 计算犯规严重度（0-1）
	var severity = 0.0
	var foul_type = FoulType.NONE

	# 从背后铲球 = 严重犯规
	var tackler_to_victim = (victim_pos - tackler_pos).normalized()
	var victim_facing = victim.get("facing_direction")
	if victim_facing:
		var dot = tackler_to_victim.dot(victim_facing)
		if dot < -0.3:  # 从背后
			severity += 0.4
			foul_type = FoulType.SLIDE_TACKLE

	# 铲球力度（基于速度差）
	var tackler_speed = tackler.get("velocity", Vector3.ZERO).length()
	if tackler_speed > 8.0:
		severity += 0.3
		foul_type = FoulType.SLIDE_TACKLE

	# 距离越近越可能犯规
	if dist < 1.0:
		severity += 0.2
		if foul_type == FoulType.NONE:
			foul_type = FoulType.PUSH

	# 随机因素
	severity += randf_range(-0.1, 0.2)
	severity = clamp(severity, 0.0, 1.0)

	if severity < 0.3:
		return {"is_foul": false}

	# 判定犯规
	var is_foul = true
	var card = CardType.NONE
	var reason = ""

	# 判定黄红牌
	if severity >= red_card_threshold:
		card = CardType.RED
		reason = "严重犯规"
	elif severity >= card_threshold:
		# 检查是否已有黄牌
		var tackler_id = tackler.get_instance_id()
		if yellow_cards.get(tackler_id, 0) >= 1:
			card = CardType.RED
			reason = "两黄变一红"
		else:
			card = CardType.YELLOW
			reason = "犯规"
	else:
		reason = "轻微犯规"

	# 记录黄牌
	if card == CardType.YELLOW:
		var tid = tackler.get_instance_id()
		yellow_cards[tid] = yellow_cards.get(tid, 0) + 1
	elif card == CardType.RED:
		yellow_cards[tackler.get_instance_id()] = 2

	# 判定是否在禁区内 -> 点球
	var is_in_penalty_area = _is_in_penalty_area(ball_pos, victim.get("team_side"))
	var set_piece = SetPieceType.DIRECT_FREE_KICK
	if is_in_penalty_area and severity > penalty_area_foul_threshold:
		set_piece = SetPieceType.PENALTY
		if card == CardType.NONE:
			card = CardType.YELLOW

	# 受害方获得定位球
	var fouling_team = tackler.get("team_side")
	var awarded_team = 1 - fouling_team  # 对方

	var foul_data = {
		"is_foul": is_foul,
		"severity": severity,
		"foul_type": foul_type,
		"card": card,
		"reason": reason,
		"tackler": tackler,
		"victim": victim,
		"position": tackler_pos,
		"fouling_team": fouling_team,
		"awarded_team": awarded_team,
		"set_piece": set_piece,
		"is_penalty": set_piece == SetPieceType.PENALTY,
	}

	foul_committed.emit(foul_data)

	# 更新统计
	var team_key = "home" if fouling_team == 0 else "away"
	match_stats.fouls[team_key] += 1
	if card == CardType.YELLOW:
		match_stats.yellow_cards[team_key] += 1
	elif card == CardType.RED:
		match_stats.red_cards[team_key] += 1

	return foul_data

## 检查是否在禁区内
func _is_in_penalty_area(pos: Vector3, defending_team: int) -> bool:
	# 禁区尺寸：40.3m x 16.5m
	var pa_width = GameState.PENALTY_AREA_WIDTH / 2  # 20.15
	var pa_depth = GameState.PENALTY_AREA_DEPTH      # 16.5
	var field_half = GameState.FIELD_LENGTH / 2      # 52.5

	if defending_team == GameState.TeamSide.HOME:
		# 主队禁区在 -Z 方向
		return abs(pos.x) < pa_width and pos.z < (-field_half + pa_depth) and pos.z > -field_half
	else:
		# 客队禁区在 +Z 方向
		return abs(pos.x) < pa_width and pos.z > (field_half - pa_depth) and pos.z < field_half

## 判定进球（含乌龙球判定）
func check_goal(ball_pos: Vector3, last_touch_team: int, last_touch_player: Node, shooter_team: int, shooter_player: Node) -> Dictionary:
	var goal_width = GameState.GOAL_WIDTH / 2  # 3.66
	var field_half = GameState.FIELD_LENGTH / 2

	# 检查是否进入球门范围
	var is_home_goal = ball_pos.z < -field_half and abs(ball_pos.x) < goal_width
	var is_away_goal = ball_pos.z > field_half and abs(ball_pos.x) < goal_width

	if not is_home_goal and not is_away_goal:
		return {"is_goal": false}

	# 判定进球方
	var scoring_team = -1
	var is_own_goal = false
	var scorer = null

	if is_home_goal:
		# 球进主队球门 -> 客队得分
		scoring_team = GameState.TeamSide.AWAY
		if last_touch_team == GameState.TeamSide.AWAY:
			# 客队最后触球 -> 正常进球
			is_own_goal = false
			scorer = last_touch_player
		else:
			# 主队最后触球 -> 乌龙球
			is_own_goal = true
			scorer = last_touch_player
	else:
		# 球进客队球门 -> 主队得分
		scoring_team = GameState.TeamSide.HOME
		if last_touch_team == GameState.TeamSide.HOME:
			is_own_goal = false
			scorer = last_touch_player
		else:
			is_own_goal = true
			scorer = last_touch_player

	# 判定进球类型
	var goal_type = _classify_goal(ball_pos, scorer, is_own_goal)

	var goal_data = {
		"is_goal": true,
		"scoring_team": scoring_team,
		"scorer": scorer,
		"is_own_goal": is_own_goal,
		"goal_type": goal_type,
		"position": ball_pos,
	}
	goal_scored.emit(scoring_team, scorer.get_instance_id() if scorer else -1, is_own_goal, goal_type)
	return goal_data

## 进球分类（世界波、头球、远射等）
func _classify_goal(ball_pos: Vector3, scorer: Node, is_own_goal: bool) -> String:
	if is_own_goal:
		return "乌龙球"

	# 根据射门距离分类
	var field_half = GameState.FIELD_LENGTH / 2
	var shooter_z = scorer.position.z if scorer else 0
	var shot_distance = abs(shooter_z - ball_pos.z)

	if shot_distance > 30:
		return "世界波"  # 超远距离
	elif shot_distance > 22:
		return "远射"
	elif shot_distance > 15:
		return "中距离射门"
	else:
		return "近距离射门"

## 判定球出界（角球/球门球/界外球）
func check_out_of_bounds(ball_pos: Vector3, last_touch_team: int) -> Dictionary:
	var field_half_l = GameState.FIELD_LENGTH / 2
	var field_half_w = GameState.FIELD_WIDTH / 2
	var goal_half = GameState.GOAL_WIDTH / 2

	# 球门线出界（Z轴）
	if ball_pos.z < -field_half_l or ball_pos.z > field_half_l:
		# 检查是否在球门范围内（进球由check_goal处理）
		if abs(ball_pos.x) < goal_half:
			return {"out": false}  # 是进球，不是出界

		# 球门线出界 -> 球门球或角球
		var is_home_goal_line = ball_pos.z < -field_half_l
		# 如果攻方最后触球后出界 -> 角球给攻方
		# 如果守方最后触球后出界 -> 球门球给守方
		if is_home_goal_line:
			# 球出主队底线
			if last_touch_team == GameState.TeamSide.AWAY:
				# 客队最后触球 -> 主队球门球
				return {
					"out": true,
					"type": SetPieceType.GOAL_KICK,
					"team": GameState.TeamSide.HOME,
					"position": Vector3(0, 0, -field_half_l + 5),
				}
			else:
				# 主队最后触球 -> 客队角球
				var corner_x = -field_half_w if ball_pos.x < 0 else field_half_w
				return {
					"out": true,
					"type": SetPieceType.CORNER_KICK,
					"team": GameState.TeamSide.AWAY,
					"position": Vector3(corner_x, 0, -field_half_l + 1),
				}
		else:
			# 球出客队底线
			if last_touch_team == GameState.TeamSide.HOME:
				# 主队最后触球 -> 客队球门球
				return {
					"out": true,
					"type": SetPieceType.GOAL_KICK,
					"team": GameState.TeamSide.AWAY,
					"position": Vector3(0, 0, field_half_l - 5),
				}
			else:
				# 客队最后触球 -> 主队角球
				var corner_x = -field_half_w if ball_pos.x < 0 else field_half_w
				return {
					"out": true,
					"type": SetPieceType.CORNER_KICK,
					"team": GameState.TeamSide.HOME,
					"position": Vector3(corner_x, 0, field_half_l - 1),
				}

	# 边线出界（X轴）
	if ball_pos.x < -field_half_w or ball_pos.x > field_half_w:
		var throw_x = clamp(ball_pos.x, -field_half_w, field_half_w)
		var throw_z = ball_pos.z
		return {
			"out": true,
			"type": SetPieceType.THROW_IN,
			"team": 1 - last_touch_team,  # 对方掷界外球
			"position": Vector3(throw_x, 0, throw_z),
		}

	return {"out": false}

## 获取任意球人墙位置
func get_free_kick_wall_positions(ball_pos: Vector3, defending_team: int, num_players: int = 4) -> Array:
	var wall_positions = []
	var goal_z = -GameState.FIELD_LENGTH / 2 if defending_team == GameState.TeamSide.HOME else GameState.FIELD_LENGTH / 2

	# 人墙距离球9.15米
	var to_goal = (Vector3(0, 0, goal_z) - ball_pos)
	to_goal.y = 0
	var wall_dir = to_goal.normalized()
	var wall_center = ball_pos + wall_dir * 9.15

	# 人墙横向排列
	var spacing = 0.6  # 球员间距
	for i in range(num_players):
		var offset = (i - (num_players - 1) / 2.0) * spacing
		var perp = Vector3(-wall_dir.z, 0, wall_dir.x) * offset
		wall_positions.append(wall_center + perp)

	return wall_positions

## 获取点球位置
func get_penalty_spot(defending_team: int) -> Vector3:
	var field_half = GameState.FIELD_LENGTH / 2
	var penalty_z = -field_half + 11.0 if defending_team == GameState.TeamSide.HOME else field_half - 11.0
	return Vector3(0, 0, penalty_z)

## 重置比赛统计
func reset_match_stats():
	match_stats = {
		"fouls": {"home": 0, "away": 0},
		"yellow_cards": {"home": 0, "away": 0},
		"red_cards": {"home": 0, "away": 0},
		"corners": {"home": 0, "away": 0},
		"free_kicks": {"home": 0, "away": 0},
		"penalties": {"home": 0, "away": 0},
		"shots": {"home": 0, "away": 0},
		"shots_on_target": {"home": 0, "away": 0},
	}
	yellow_cards.clear()

## 记录射门
func record_shot(team: int, on_target: bool):
	var key = "home" if team == 0 else "away"
	match_stats.shots[key] += 1
	if on_target:
		match_stats.shots_on_target[key] += 1

## 获取定位球类型名称
func get_set_piece_name(piece_type: int) -> String:
	match piece_type:
		SetPieceType.DIRECT_FREE_KICK: return "直接任意球"
		SetPieceType.INDIRECT_FREE_KICK: return "间接任意球"
		SetPieceType.PENALTY: return "点球"
		SetPieceType.CORNER_KICK: return "角球"
		SetPieceType.GOAL_KICK: return "球门球"
		SetPieceType.THROW_IN: return "界外球"
		SetPieceType.KICKOFF: return "开球"
		_: return "未知"

## 获取牌的名称
func get_card_name(card: int) -> String:
	match card:
		CardType.YELLOW: return "黄牌"
		CardType.RED: return "红牌"
		_: return "无"
