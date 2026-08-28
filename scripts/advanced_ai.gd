## advanced_ai.gd
## 高级比赛AI系统
## 优化点：
##   1. 动态战术调整（根据比分/时间/球权）
##   2. 球员角色化AI（不同位置不同行为）
##   3. 跑位智能（寻找空当/拉开空间）
##   4. 防守协同（补位/协防/越位陷阱）
##   5. 进攻套路（边路渗透/中路突破/反击）
extends Node

# 战术风格
enum TacticStyle {
	POSSESSION,   # 控球打法
	COUNTER,      # 防守反击
	HIGH_PRESS,   # 高位逼抢
	PARK_BUS,     # 摆大巴
	BALANCED,     # 平衡
}

# 进攻套路
enum AttackPattern {
	WING_PLAY,        # 边路进攻
	CENTRAL_THROUGH,  # 中路渗透
	LONG_BALL,        # 长传冲吊
	TIKI_TAKA,        # 短传配合
	COUNTER_ATTACK,   # 快速反击
}

# 当前战术
var current_style: TacticStyle = TacticStyle.BALANCED
var current_attack_pattern: AttackPattern = AttackPattern.CENTRAL_THROUGH

# AI参数
var ai_params: Dictionary = {
	"reaction_time": 0.3,
	"pass_accuracy": 0.8,
	"shot_accuracy": 0.7,
	"press_intensity": 0.5,
	"formation_discipline": 0.7,
	"offside_trap": false,
	"counter_speed": 1.0,
}

## 根据比赛情况动态调整战术
func update_tactics(score_for: int, score_against: int, time_remaining: float, has_possession: bool, is_late_game: bool = false):
	var goal_diff = score_for - score_against

	if has_possession:
		# 有球权
		if goal_diff > 1 and time_remaining < 120:
			current_style = TacticStyle.POSSESSION
			current_attack_pattern = AttackPattern.TIKI_TAKA
			ai_params.formation_discipline = 0.9
		elif goal_diff < 0 and time_remaining < 180:
			current_style = TacticStyle.HIGH_PRESS
			current_attack_pattern = AttackPattern.CENTRAL_THROUGH
			ai_params.press_intensity = 0.9
		elif goal_diff < 0:
			current_style = TacticStyle.POSSESSION
			current_attack_pattern = AttackPattern.WING_PLAY
		else:
			current_style = TacticStyle.BALANCED
			current_attack_pattern = AttackPattern.CENTRAL_THROUGH
	else:
		# 无球权
		if goal_diff > 0 and time_remaining < 120:
			current_style = TacticStyle.PARK_BUS
			ai_params.formation_discipline = 0.95
			ai_params.offside_trap = false
		elif goal_diff <= 0:
			current_style = TacticStyle.HIGH_PRESS
			current_attack_pattern = AttackPattern.COUNTER_ATTACK
			ai_params.press_intensity = 0.8
			ai_params.counter_speed = 1.2
		else:
			current_style = TacticStyle.COUNTER
			ai_params.offside_trap = true

## 获取球员角色化决策
func get_player_decision(player: Node, ball: Node3D, has_ball: bool, teammates: Array, opponents: Array) -> Dictionary:
	var role = player.get("role") if player.get("role") else "ST"
	var decision = {"action": "idle", "target": Vector3.ZERO}

	match role:
		"GK":
			decision = _goalkeeper_ai(player, ball, opponents)
		"CB":
			decision = _center_back_ai(player, ball, has_ball, opponents)
		"LB", "RB":
			decision = _fullback_ai(player, ball, has_ball, opponents)
		"CDM":
			decision = _defensive_mid_ai(player, ball, has_ball, opponents)
		"CM":
			decision = _central_mid_ai(player, ball, has_ball, teammates, opponents)
		"CAM":
			decision = _attacking_mid_ai(player, ball, has_ball, teammates, opponents)
		"LW", "RW":
			decision = _winger_ai(player, ball, has_ball, opponents)
		"ST", "CF":
			decision = _striker_ai(player, ball, has_ball, opponents)

	return decision

## 门将AI
func _goalkeeper_ai(player: Node, ball: Node3D, opponents: Array) -> Dictionary:
	var team_side = player.get("team_side")
	var target_goal_z = -GameState.FIELD_LENGTH / 2 if team_side == 0 else GameState.FIELD_LENGTH / 2
	var ball_pos = ball.position

	# 判断是否需要出击
	var dist_to_ball = abs(ball_pos.z - target_goal_z)
	if dist_to_ball < 15 and abs(ball_pos.x) < 10:
		# 球很近，出击
		return {"action": "gk_rush", "target": ball_pos}

	# 跟随球的横向位置
	var gk_x = clamp(ball_pos.x * 0.3, -3.0, 3.0)
	var gk_z = target_goal_z + (5.0 if team_side == 0 else -5.0)
	return {"action": "position", "target": Vector3(gk_x, 0, gk_z)}

## 中后卫AI
func _center_back_ai(player: Node, ball: Node3D, has_ball: bool, opponents: Array) -> Dictionary:
	var home_pos = player.get("home_position")
	var ball_pos = ball.position

	if has_ball:
		# 有球时：短传给中场或边路
		return {"action": "pass_short", "target": home_pos + Vector3(0, 0, 10)}

	# 无球时：盯防对方前锋，保持防线
	var nearest_opponent = _find_nearest_opponent(player.position, opponents)
	if nearest_opponent:
		var dist = player.position.distance_to(nearest_opponent.position)
		if dist < 8:
			# 紧逼
			return {"action": "mark", "target": nearest_opponent.position}

	# 保持防线位置
	var ball_to_home = home_pos - ball_pos
	if ball_to_home.length() < 25:
		return {"action": "press", "target": ball_pos + ball_to_home.normalized() * 5}
	return {"action": "position", "target": home_pos}

## 边后卫AI
func _fullback_ai(player: Node, ball: Node3D, has_ball: bool, opponents: Array) -> Dictionary:
	var home_pos = player.get("home_position")
	var ball_pos = ball.position

	if has_ball:
		# 有球时：套边插上
		var wing_target = Vector3(home_pos.x * 1.5, 0, home_pos.z + 15)
		return {"action": "run_wing", "target": wing_target}

	# 无球时：根据球的位置决定是否插上
	if abs(ball_pos.x - home_pos.x) < 15:
		# 球在自己一侧，上前逼抢
		return {"action": "press", "target": ball_pos}
	else:
		# 球在远端，保持位置
		return {"action": "position", "target": home_pos}

## 后腰AI
func _defensive_mid_ai(player: Node, ball: Node3D, has_ball: bool, opponents: Array) -> Dictionary:
	var home_pos = player.get("home_position")
	var ball_pos = ball.position

	if has_ball:
		# 有球时：分球给前场
		return {"action": "pass_forward", "target": home_pos + Vector3(0, 0, 20)}

	# 无球时：保护防线，拦截传球路线
	if ball_pos.z < home_pos.z:
		# 球在本方半场，回防
		return {"action": "position", "target": home_pos + Vector3(0, 0, -5)}
	else:
		# 球在前场，跟进
		return {"action": "position", "target": home_pos + Vector3(0, 0, 10)}

## 中场AI
func _central_mid_ai(player: Node, ball: Node3D, has_ball: bool, teammates: Array, opponents: Array) -> Dictionary:
	var home_pos = player.get("home_position")
	var ball_pos = ball.position

	if has_ball:
		# 有球时：根据战术选择传球或带球
		match current_attack_pattern:
			AttackPattern.TIKI_TAKA:
				return {"action": "pass_short", "target": _find_best_pass_target(player, teammates, opponents, 15)}
			AttackPattern.LONG_BALL:
				return {"action": "pass_long", "target": _find_best_pass_target(player, teammates, opponents, 35)}
			AttackPattern.WING_PLAY:
				return {"action": "pass_wing", "target": _find_wing_target(player, teammates)}
			_:
				return {"action": "dribble", "target": ball_pos + Vector3(0, 0, 5)}

	# 无球时：寻找空当
	var space = _find_space(player.position, opponents, teammates)
	return {"action": "position", "target": space}

## 前腰AI
func _attacking_mid_ai(player: Node, ball: Node3D, has_ball: bool, teammates: Array, opponents: Array) -> Dictionary:
	var home_pos = player.get("home_position")
	var ball_pos = ball.position

	if has_ball:
		# 有球时：直塞或射门
		var dist_to_goal = abs(ball_pos.z - (GameState.FIELD_LENGTH / 2 if player.get("team_side") == 0 else -GameState.FIELD_LENGTH / 2))
		if dist_to_goal < 25:
			return {"action": "shoot", "target": Vector3(0, 0, GameState.FIELD_LENGTH / 2)}
		else:
			return {"action": "through_ball", "target": _find_best_through_target(player, teammates, opponents)}

	# 无球时：在禁区前沿寻找空当
	var target_goal_z = GameState.FIELD_LENGTH / 2 if player.get("team_side") == 0 else -GameState.FIELD_LENGTH / 2
	var attack_pos = Vector3(randf_range(-10, 10), 0, target_goal_z - 25)
	return {"action": "position", "target": attack_pos}

## 边锋AI
func _winger_ai(player: Node, ball: Node3D, has_ball: bool, opponents: Array) -> Dictionary:
	var home_pos = player.get("home_position")
	var ball_pos = ball.position

	if has_ball:
		# 有球时：突破或传中
		var target_goal_z = GameState.FIELD_LENGTH / 2 if player.get("team_side") == 0 else -GameState.FIELD_LENGTH / 2
		var dist_to_goal = abs(ball_pos.z - target_goal_z)

		if dist_to_goal < 20 and abs(ball_pos.x) > 15:
			# 在禁区两侧，传中
			return {"action": "cross", "target": Vector3(0, 0, target_goal_z - 5)}
		elif dist_to_goal < 30:
			# 接近禁区，内切射门
			return {"action": "cut_inside", "target": Vector3(0, 0, target_goal_z)}
		else:
			# 远离禁区，带球推进
			return {"action": "dribble", "target": ball_pos + Vector3(0, 0, 10)}

	# 无球时：拉边接应
	return {"action": "position", "target": home_pos}

## 前锋AI
func _striker_ai(player: Node, ball: Node3D, has_ball: bool, opponents: Array) -> Dictionary:
	var home_pos = player.get("home_position")
	var ball_pos = ball.position
	var team_side = player.get("team_side")
	var target_goal_z = GameState.FIELD_LENGTH / 2 if team_side == 0 else -GameState.FIELD_LENGTH / 2

	if has_ball:
		var dist_to_goal = abs(ball_pos.z - target_goal_z)
		if dist_to_goal < 25:
			# 在射程内，射门
			return {"action": "shoot", "target": Vector3(randf_range(-3, 3), 0, target_goal_z)}
		else:
			# 带球向前
			return {"action": "dribble", "target": ball_pos + Vector3(0, 0, 8)}

	# 无球时：寻找空当，准备接球
	var best_pos = _find_striker_space(player.position, opponents, target_goal_z)
	return {"action": "position", "target": best_pos}

## 寻找最佳传球目标
func _find_best_pass_target(player: Node, teammates: Array, opponents: Array, max_dist: float) -> Vector3:
	var best_target = null
	var best_score = -INF
	var forward_dir = 1 if player.get("team_side") == 0 else -1

	for t in teammates:
		if t == player:
			continue
		var dist = player.position.distance_to(t.position)
		if dist > max_dist or dist < 5:
			continue
		var forward_score = (t.position.z - player.position.z) * forward_dir
		var opponent_pressure = _count_nearby_opponents(t.position, opponents, 10)
		var score = forward_score - opponent_pressure * 5 - dist * 0.2
		if score > best_score:
			best_score = score
			best_target = t

	if best_target:
		return best_target.position
	return player.position + Vector3(0, 0, 10 * forward_dir)

## 寻找边路传球目标
func _find_wing_target(player: Node, teammates: Array) -> Vector3:
	var forward_dir = 1 if player.get("team_side") == 0 else -1
	for t in teammates:
		if t == player:
			continue
		if abs(t.position.x) > 15 and (t.position.z - player.position.z) * forward_dir > 5:
			return t.position
	return Vector3(20 * forward_dir, 0, player.position.z + 15)

## 寻找直塞目标
func _find_best_through_target(player: Node, teammates: Array, opponents: Array) -> Vector3:
	var forward_dir = 1 if player.get("team_side") == 0 else -1
	var best_target = null
	var best_score = -INF

	for t in teammates:
		if t == player:
			continue
		if t.get("role") not in ["ST", "CF", "LW", "RW"]:
			continue
		var dist = player.position.distance_to(t.position)
		if dist > 35 or dist < 10:
			continue
		var forward_score = (t.position.z - player.position.z) * forward_dir
		var through_pos = t.position + Vector3(0, 0, forward_dir * 5)
		var opponent_pressure = _count_nearby_opponents(through_pos, opponents, 8)
		var score = forward_score - opponent_pressure * 3
		if score > best_score:
			best_score = score
			best_target = through_pos

	if best_target:
		return best_target
	return player.position + Vector3(0, 0, 20 * forward_dir)

## 寻找空当
func _find_space(pos: Vector3, opponents: Array, teammates: Array) -> Vector3:
	var best_space = pos
	var best_score = -INF

	for _i in range(8):
		var angle = _i * TAU / 8
		var test_pos = pos + Vector3(cos(angle), 0, sin(angle)) * 10
		var opp_dist = _min_distance_to_opponents(test_pos, opponents)
		var teammate_dist = _min_distance_to_teammates(test_pos, teammates)
		var score = opp_dist + teammate_dist * 0.5
		if score > best_score:
			best_score = score
			best_space = test_pos

	return best_space

## 寻找前锋空当
func _find_striker_space(pos: Vector3, opponents: Array, target_goal_z: float) -> Vector3:
	var best_pos = pos
	var best_score = -INF

	for _i in range(10):
		var test_x = randf_range(-15, 15)
		var test_z = target_goal_z - randf_range(10, 25)
		var test_pos = Vector3(test_x, 0, test_z)
		var opp_dist = _min_distance_to_opponents(test_pos, opponents)
		var goal_dist = abs(test_z - target_goal_z)
		var score = opp_dist - goal_dist * 0.3
		if score > best_score:
			best_score = score
			best_pos = test_pos

	return best_pos

## 找到最近的对方球员
func _find_nearest_opponent(pos: Vector3, opponents: Array) -> Node:
	var nearest = null
	var min_dist = INF
	for o in opponents:
		var d = pos.distance_to(o.position)
		if d < min_dist:
			min_dist = d
			nearest = o
	return nearest

## 统计附近对方球员数量
func _count_nearby_opponents(pos: Vector3, opponents: Array, radius: float) -> int:
	var count = 0
	for o in opponents:
		if pos.distance_to(o.position) < radius:
			count += 1
	return count

## 到最近对方球员的距离
func _min_distance_to_opponents(pos: Vector3, opponents: Array) -> float:
	var min_dist = INF
	for o in opponents:
		var d = pos.distance_to(o.position)
		if d < min_dist:
			min_dist = d
	return min_dist

## 到最近队友的距离
func _min_distance_to_teammates(pos: Vector3, teammates: Array) -> float:
	var min_dist = INF
	for t in teammates:
		var d = pos.distance_to(t.position)
		if d > 0.1 and d < min_dist:
			min_dist = d
	return min_dist

## 获取战术名称
func get_tactic_name() -> String:
	var style_names = {
		TacticStyle.POSSESSION: "控球",
		TacticStyle.COUNTER: "反击",
		TacticStyle.HIGH_PRESS: "高位逼抢",
		TacticStyle.PARK_BUS: "密集防守",
		TacticStyle.BALANCED: "平衡",
	}
	var pattern_names = {
		AttackPattern.WING_PLAY: "边路",
		AttackPattern.CENTRAL_THROUGH: "中路渗透",
		AttackPattern.LONG_BALL: "长传冲吊",
		AttackPattern.TIKI_TAKA: "短传配合",
		AttackPattern.COUNTER_ATTACK: "快速反击",
	}
	return style_names.get(current_style, "平衡") + "/" + pattern_names.get(current_attack_pattern, "中路")
