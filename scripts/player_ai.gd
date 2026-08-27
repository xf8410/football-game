## player_ai.gd
## 单个球员AI（第一层）
## 处理：接近球、选择站位、传球/射门/抢断、避开队友和边界、回到所属区域
##
## 三层AI架构：
##   1. 球员AI（本文件）- 单个球员的行为决策
##   2. 球队战术AI（team_ai.gd）- 球队整体战术
##   3. 活动修正（game_state.gd中的event modifiers）- 特殊活动规则
extends Node

# AI决策频率（不需要每帧决策）
const DECISION_INTERVAL: float = 0.15
var decision_timer: float = 0.0

var player: CharacterBody3D = null
var team_side: int = 0
var ball: Node3D = null
var match_ref: Node = null
var team_ai: Node = null  # 引用球队战术AI

# AI参数（从GameState获取）
var ai_params: Dictionary = {}

# 当前决策状态
var current_target: Vector3 = Vector3.ZERO
var current_action: String = "idle"
var is_chasing_ball: bool = false
var mark_target: CharacterBody3D = null

## 初始化
func setup(p: CharacterBody3D, side: int, ball_node: Node3D, match: Node, tactics: Node):
	player = p
	team_side = side
	ball = ball_node
	match_ref = match
	team_ai = tactics
	ai_params = GameState.get_ai_params()

## 每帧更新
func update(delta: float, has_ball: bool, is_nearest_to_ball: bool):
	decision_timer += delta

	# 限制决策频率（性能优化）
	if decision_timer < DECISION_INTERVAL:
		_apply_movement(delta)
		return
	decision_timer = 0.0

	# 根据情况决策
	if has_ball:
		_decide_with_ball()
	elif is_nearest_to_ball:
		_decide_chase_ball()
	else:
		_decide_off_ball()

	_apply_movement(delta)

# ---- 有球时的决策 ----

func _decide_with_ball():
	var pos = player.position
	var target_goal_z = GameState.FIELD_LENGTH / 2 if team_side == GameState.TeamSide.HOME else -GameState.FIELD_LENGTH / 2
	var dist_to_goal = abs(pos.z - target_goal_z)

	# 射门判定
	if dist_to_goal < 25.0:
		if randf() < ai_params.get("shoot_probability", 0.3):
			current_action = "shoot"
			match_ref.ai_shoot(player)
			return

	# 传球判定
	var pass_pref = team_ai.get_pass_preference() if team_ai else 0.4
	if randf() < ai_params.get("pass_probability", 0.2) * (1.0 + pass_pref):
		# 寻找最佳传球目标
		var best_target = _find_best_pass_target()
		if best_target:
			current_action = "pass"
			match_ref.ai_pass(player, best_target)
			return

	# 带球前进
	var goal_dir = Vector3(0, 0, target_goal_z - pos.z).normalized()
	# 避开对手
	var avoid = _avoid_opponents()
	current_target = pos + (goal_dir + avoid * 2).normalized() * 5
	current_action = "dribble"

# ---- 追球时的决策 ----

func _decide_chase_ball():
	is_chasing_ball = true
	current_target = ball.position
	current_action = "chase"

	# 如果接近球，尝试抢断
	if player.position.distance_to(ball.position) < 2.0:
		current_action = "tackle"
		match_ref.ai_tackle(player)

# ---- 无球时的决策 ----

func _decide_off_ball():
	is_chasing_ball = false

	# 回到阵型位置 + 战术偏移
	var home_pos = player.home_position
	var offset = team_ai.get_formation_offset() if team_ai else Vector3.ZERO
	var press_intensity = team_ai.get_press_intensity() if team_ai else 0.5

	# 根据球的位置调整站位
	var ball_pos = ball.position
	var ball_to_home = (home_pos - ball_pos)

	# 如果球离自己近且需要逼抢，向球靠近
	if ball_to_home.length() < 20.0 and randf() < press_intensity:
		# 向球的方向移动，但保持一定距离
		var press_pos = ball_pos + ball_to_home.normalized() * 5
		current_target = press_pos
		current_action = "press"
	else:
		# 回到阵型位置
		current_target = home_pos + offset
		current_action = "position"

	# 门将特殊行为
	if player.is_goalkeeper:
		_goalkeeper_ai()

# ---- 门将AI ----

func _goalkeeper_ai():
	var target_goal_z = -GameState.FIELD_LENGTH / 2 if team_side == GameState.TeamSide.HOME else GameState.FIELD_LENGTH / 2
	var ball_pos = ball.position

	# 门将在小禁区内移动，跟随球的横向位置
	var gk_x = clamp(ball_pos.x * 0.3, -3.0, 3.0)
	var gk_z = target_goal_z + (5.0 if team_side == GameState.TeamSide.HOME else -5.0)
	current_target = Vector3(gk_x, 0, gk_z)

	# 如果球很近，冲出来
	if abs(ball_pos.z - target_goal_z) < 15.0 and ball_pos.distance_to(Vector3(gk_x, 0, gk_z)) < 8.0:
		current_target = ball_pos
		current_action = "gk_rush"

# ---- 寻找最佳传球目标 ----

func _find_best_pass_target() -> CharacterBody3D:
	var teammates = match_ref.home_players if team_side == GameState.TeamSide.HOME else match_ref.away_players
	var best_target = null
	var best_score = -999.0

	var target_goal_z = GameState.FIELD_LENGTH / 2 if team_side == GameState.TeamSide.HOME else -GameState.FIELD_LENGTH / 2
	var forward_dir = 1 if team_side == GameState.TeamSide.HOME else -1

	for teammate in teammates:
		if teammate == player or teammate.is_goalkeeper:
			continue

		var dist = player.position.distance_to(teammate.position)
		if dist < 5 or dist > 40:
			continue

		# 评分：向前传球优先 + 距离适中 + 附近无对手
		var forward_score = (teammate.position.z - player.position.z) * forward_dir * 0.5
		var dist_score = -abs(dist - 20) * 0.2  # 20米左右最佳
		var opponent_pressure = _count_nearby_opponents(teammate.position, 8.0)
		var pressure_score = -opponent_pressure * 3.0

		# 加入随机性（AI失误）
		var random_factor = randf_range(-ai_params.get("error_rate", 0.1), ai_params.get("error_rate", 0.1)) * 10

		var total_score = forward_score + dist_score + pressure_score + random_factor

		if total_score > best_score:
			best_score = total_score
			best_target = teammate

	return best_target

# ---- 辅助函数 ----

func _avoid_opponents() -> Vector3:
	var opponents = match_ref.away_players if team_side == GameState.TeamSide.HOME else match_ref.home_players
	var avoid_dir = Vector3.ZERO
	for opp in opponents:
		var dist = player.position.distance_to(opp.position)
		if dist < 4.0 and dist > 0.1:
			avoid_dir += (player.position - opp.position).normalized() / dist
	return avoid_dir.normalized()

func _count_nearby_opponents(pos: Vector3, radius: float) -> int:
	var opponents = match_ref.away_players if team_side == GameState.TeamSide.HOME else match_ref.home_players
	var count = 0
	for opp in opponents:
		if pos.distance_to(opp.position) < radius:
			count += 1
	return count

func _apply_movement(delta: float):
	# 向目标移动
	var to_target = current_target - player.position
	to_target.y = 0

	if to_target.length() > 0.5:
		player.input_direction = to_target.normalized()
		# 根据距离决定是否冲刺
		player.is_sprinting = to_target.length() > 10.0 and current_action in ["chase", "press", "dribble"]
	else:
		player.input_direction = Vector3.ZERO
		player.is_sprinting = false

	# 检查活动修正：AI不能进入特定区域
	_check_zone_restrictions()

func _check_zone_restrictions():
	var event = GameState.current_event
	if not event.has("modifiers"):
		return
	var mods = event["modifiers"]
	var no_enter_zones = mods.get("ai_no_enter_zones", [])

	for zone in no_enter_zones:
		# zone格式: {center: Vector3, radius: float}
		if zone is Dictionary:
			var center = zone.get("center", Vector3.ZERO)
			var radius = zone.get("radius", 10.0)
			if player.position.distance_to(center) < radius:
				# 推离禁区
				var push_dir = (player.position - center).normalized()
				player.input_direction = push_dir
				current_target = player.position + push_dir * 5
