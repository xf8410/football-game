## team_ai.gd
## 球队战术AI（第二层）
## 管理球队整体战术：进攻/平衡/防守、高位逼抢/退守、短传/长传/反击
## 根据比分、时间、球权决定战术模式
extends Node

# ---- 战术模式 ----
enum TacticMode {
	ATTACKING,     # 进攻：全员压上
	BALANCED,      # 平衡：正常阵型
	DEFENSIVE,     # 防守：退守
	HIGH_PRESS,    # 高位逼抢
	COUNTER,       # 快速反击
	TIME_WASTE     # 拖延时间（领先时）
}

# ---- 进攻策略 ----
enum AttackStyle {
	SHORT_PASS,    # 短传渗透
	LONG_PASS,     # 长传冲吊
	WING_PLAY,     # 边路进攻
	COUNTER        # 快速反击
}

# ---- 当前战术状态 ----
var current_mode: TacticMode = TacticMode.BALANCED
var current_attack_style: AttackStyle = AttackStyle.SHORT_PASS
var team_side: int = 0
var team_players: Array = []
var opponent_players: Array = []
var ball: Node3D = null
var match_ref: Node = null

## 初始化
func setup(side: int, players: Array, opponents: Array, ball_node: Node3D, match: Node):
	team_side = side
	team_players = players
	opponent_players = opponents
	ball = ball_node
	match_ref = match

## 每帧更新战术决策
func update_tactics(score_for: int, score_against: int, time_remaining: float, has_possession: bool):
	var goal_diff = score_for - score_against

	# 根据比分和时间决定战术
	if has_possession:
		# 有球权时的战术
		if goal_diff > 0 and time_remaining < 60:
			# 领先且时间不多：拖延时间
			current_mode = TacticMode.TIME_WASTE
			current_attack_style = AttackStyle.SHORT_PASS
		elif goal_diff < 0 and time_remaining < 120:
			# 落后且时间不多：全力进攻
			current_mode = TacticMode.ATTACKING
			current_attack_style = AttackStyle.LONG_PASS
		elif goal_diff < 0:
			# 落后：进攻
			current_mode = TacticMode.ATTACKING
			current_attack_style = AttackStyle.WING_PLAY
		else:
			# 平衡
			current_mode = TacticMode.BALANCED
			current_attack_style = AttackStyle.SHORT_PASS
	else:
		# 无球权时的战术
		if goal_diff > 0 and time_remaining < 60:
			# 领先且时间不多：退守
			current_mode = TacticMode.DEFENSIVE
		elif goal_diff <= 0 and time_remaining < 120:
			# 落后或平局且时间不多：高位逼抢
			current_mode = TacticMode.HIGH_PRESS
		else:
			# 平衡
			current_mode = TacticMode.BALANCED

	# 应用活动修正
	_apply_event_modifiers()

## 应用活动修正（第三层）
func _apply_event_modifiers():
	var event = GameState.current_event
	if not event.has("modifiers"):
		return
	var mods = event["modifiers"]

	# AI最后几分钟全力防守
	if mods.get("ai_defensive_mode", false):
		current_mode = TacticMode.DEFENSIVE

	# AI不能进入特定区域
	# （在球员AI层处理）

## 获取阵型偏移（根据战术模式调整站位）
func get_formation_offset() -> Vector3:
	match current_mode:
		TacticMode.ATTACKING:
			return Vector3(0, 0, 8) if team_side == GameState.TeamSide.HOME else Vector3(0, 0, -8)
		TacticMode.DEFENSIVE:
			return Vector3(0, 0, -8) if team_side == GameState.TeamSide.HOME else Vector3(0, 0, 8)
		TacticMode.HIGH_PRESS:
			return Vector3(0, 0, 15) if team_side == GameState.TeamSide.HOME else Vector3(0, 0, -15)
		TacticMode.COUNTER:
			return Vector3(0, 0, -3) if team_side == GameState.TeamSide.HOME else Vector3(0, 0, 3)
		TacticMode.TIME_WASTE:
			return Vector3(0, 0, -5) if team_side == GameState.TeamSide.HOME else Vector3(0, 0, 5)
		_:
			return Vector3.ZERO

## 获取逼抢强度（0-1）
func get_press_intensity() -> float:
	match current_mode:
		TacticMode.HIGH_PRESS:
			return 1.0
		TacticMode.ATTACKING:
			return 0.7
		TacticMode.BALANCED:
			return 0.5
		TacticMode.DEFENSIVE:
			return 0.3
		TacticMode.TIME_WASTE:
			return 0.2
		_:
			return 0.5

## 获取传球偏好（0=短传, 1=长传）
func get_pass_preference() -> float:
	match current_attack_style:
		AttackStyle.SHORT_PASS:
			return 0.2
		AttackStyle.LONG_PASS:
			return 0.8
		AttackStyle.WING_PLAY:
			return 0.5
		AttackStyle.COUNTER:
			return 0.6
		_:
			return 0.4

## 获取当前战术名称（用于UI显示）
func get_tactic_name() -> String:
	var mode_names = {
		TacticMode.ATTACKING: "进攻",
		TacticMode.BALANCED: "平衡",
		TacticMode.DEFENSIVE: "防守",
		TacticMode.HIGH_PRESS: "高位逼抢",
		TacticMode.COUNTER: "快速反击",
		TacticMode.TIME_WASTE: "控制节奏",
	}
	var style_names = {
		AttackStyle.SHORT_PASS: "短传",
		AttackStyle.LONG_PASS: "长传",
		AttackStyle.WING_PLAY: "边路",
		AttackStyle.COUNTER: "反击",
	}
	return mode_names.get(current_mode, "平衡") + "/" + style_names.get(current_attack_style, "短传")
