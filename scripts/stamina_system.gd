## stamina_system.gd
## 球员体力消耗系统
## 功能：跑动消耗体力、冲刺额外消耗、体力影响表现、休息恢复
extends Node

# 体力参数
const BASE_STAMINA: float = 100.0          # 基础体力
const RUN_DRAIN_RATE: float = 0.8          # 跑步时每秒消耗
const SPRINT_DRAIN_RATE: float = 2.5       # 冲刺时每秒消耗
const STAND_RECOVER_RATE: float = 3.0      # 站立时每秒恢复
const WALK_RECOVER_RATE: float = 1.5       # 走动时每秒恢复
const MIN_STAMINA: float = 0.0             # 最低体力
const MAX_STAMINA: float = 100.0           # 最高体力

# 体力阈值
const STAMINA_THRESHOLD_EXHAUSTED: float = 15.0   # 精疲力竭
const STAMINA_THRESHOLD_TIRED: float = 35.0       # 疲劳
const STAMINA_THRESHOLD_NORMAL: float = 60.0      # 正常

# 体力对表现的影响
const SPEED_MULT_EXHAUSTED: float = 0.6    # 精疲力竭时速度
const SPEED_MULT_TIRED: float = 0.8        # 疲劳时速度
const SPEED_MULT_NORMAL: float = 1.0       # 正常速度

const SHOT_ACCURACY_MULT_EXHAUSTED: float = 0.5
const SHOT_ACCURACY_MULT_TIRED: float = 0.75
const SHOT_ACCURACY_MULT_NORMAL: float = 1.0

const PASS_ACCURACY_MULT_EXHAUSTED: float = 0.6
const PASS_ACCURACY_MULT_TIRED: float = 0.85
const PASS_ACCURACY_MULT_NORMAL: float = 1.0

# 体力状态
enum StaminaState {
	FRESH,       # 充沛 (>60)
	NORMAL,      # 正常 (35-60)
	TIRED,       # 疲劳 (15-35)
	EXHAUSTED    # 精疲力竭 (<15)
}

## 更新球员体力
func update_stamina(player: Node, delta: float, is_moving: bool, is_sprinting: bool):
	if player == null or not player.has_method("get"):
		return

	var current_stamina = player.get("current_stamina")
	if current_stamina == null:
		current_stamina = BASE_STAMINA

	var max_stamina = BASE_STAMINA
	if player.has_method("get") and player.get("stats") != null:
		max_stamina = player.stats.get("stamina", BASE_STAMINA)

	# 计算体力变化
	var stamina_change = 0.0
	if is_sprinting and is_moving:
		stamina_change = -SPRINT_DRAIN_RATE * delta
	elif is_moving:
		stamina_change = -RUN_DRAIN_RATE * delta
	else:
		# 站立恢复
		stamina_change = STAND_RECOVER_RATE * delta

	# 应用体力变化
	current_stamina = clamp(current_stamina + stamina_change, MIN_STAMINA, max_stamina)
	player.set("current_stamina", current_stamina)

	# 强制停止冲刺（体力太低）
	if current_stamina < STAMINA_THRESHOLD_EXHAUSTED and is_sprinting:
		player.set("is_sprinting", false)

## 获取体力状态
func get_stamina_state(stamina: float) -> int:
	if stamina < STAMINA_THRESHOLD_EXHAUSTED:
		return StaminaState.EXHAUSTED
	elif stamina < STAMINA_THRESHOLD_TIRED:
		return StaminaState.TIRED
	elif stamina < STAMINA_THRESHOLD_NORMAL:
		return StaminaState.NORMAL
	else:
		return StaminaState.FRESH

## 获取速度倍率（根据体力）
func get_speed_multiplier(stamina: float) -> float:
	var state = get_stamina_state(stamina)
	match state:
		StaminaState.EXHAUSTED: return SPEED_MULT_EXHAUSTED
		StaminaState.TIRED: return SPEED_MULT_TIRED
		StaminaState.NORMAL: return SPEED_MULT_NORMAL
		_: return SPEED_MULT_NORMAL

## 获取射门准确率倍率（根据体力）
func get_shot_accuracy_multiplier(stamina: float) -> float:
	var state = get_stamina_state(stamina)
	match state:
		StaminaState.EXHAUSTED: return SHOT_ACCURACY_MULT_EXHAUSTED
		StaminaState.TIRED: return SHOT_ACCURACY_MULT_TIRED
		StaminaState.NORMAL: return SHOT_ACCURACY_MULT_NORMAL
		_: return SHOT_ACCURACY_MULT_NORMAL

## 获取传球准确率倍率（根据体力）
func get_pass_accuracy_multiplier(stamina: float) -> float:
	var state = get_stamina_state(stamina)
	match state:
		StaminaState.EXHAUSTED: return PASS_ACCURACY_MULT_EXHAUSTED
		StaminaState.TIRED: return PASS_ACCURACY_MULT_TIRED
		StaminaState.NORMAL: return PASS_ACCURACY_MULT_NORMAL
		_: return PASS_ACCURACY_MULT_NORMAL

## 获取体力状态名称
func get_stamina_state_name(stamina: float) -> String:
	var state = get_stamina_state(stamina)
	match state:
		StaminaState.FRESH: return "充沛"
		StaminaState.NORMAL: return "正常"
		StaminaState.TIRED: return "疲劳"
		StaminaState.EXHAUSTED: return "精疲力竭"
		_: return "正常"

## 获取体力状态颜色（用于UI显示）
func get_stamina_color(stamina: float) -> Color:
	var state = get_stamina_state(stamina)
	match state:
		StaminaState.FRESH: return Color(0.2, 0.9, 0.3)    # 绿色
		StaminaState.NORMAL: return Color(0.9, 0.9, 0.2)    # 黄色
		StaminaState.TIRED: return Color(0.9, 0.6, 0.1)     # 橙色
		StaminaState.EXHAUSTED: return Color(0.9, 0.2, 0.2) # 红色
		_: return Color.WHITE

## 获取体力百分比（0-1）
func get_stamina_ratio(stamina: float) -> float:
	return clamp(stamina / MAX_STAMINA, 0.0, 1.0)

## 半场休息恢复体力
func halftime_recovery(player: Node):
	if player == null:
		return
	var current = player.get("current_stamina")
	if current == null:
		current = BASE_STAMINA
	# 半场恢复50%体力
	current = clamp(current + 50.0, 0, BASE_STAMINA)
	player.set("current_stamina", current)

## 换人时新上场球员体力满
func reset_stamina_for_substitute(player: Node):
	if player == null:
		return
	player.set("current_stamina", BASE_STAMINA)

## 获取体力对综合表现的影响（用于AI决策）
func get_overall_performance_modifier(stamina: float) -> float:
	# 返回0-1的倍率，表示当前表现相对于满体力的比例
	var state = get_stamina_state(stamina)
	match state:
		StaminaState.FRESH: return 1.0
		StaminaState.NORMAL: return 0.9
		StaminaState.TIRED: return 0.7
		StaminaState.EXHAUSTED: return 0.5
		_: return 1.0
