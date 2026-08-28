## match_flow.gd
## 比赛流程管理器
## 管理：上半场 → 中场休息 → 下半场 → 加时赛 → 点球大战
extends Node

# 比赛阶段
enum Phase {
	PRE_MATCH,        # 赛前
	FIRST_HALF,       # 上半场
	HALF_TIME,        # 中场休息
	SECOND_HALF,      # 下半场
	FULL_TIME,        # 常规时间结束
	EXTRA_TIME_FIRST, # 加时赛上半场
	EXTRA_TIME_BREAK, # 加时赛休息
	EXTRA_TIME_SECOND,# 加时赛下半场
	PENALTY_SHOOTOUT, # 点球大战
	MATCH_END         # 比赛结束
}

# 当前阶段
var current_phase: int = Phase.PRE_MATCH

# 时间设置（游戏内秒数）
const HALF_DURATION: float = 180.0         # 每半场3分钟
const HALF_TIME_BREAK: float = 10.0        # 中场休息10秒
const EXTRA_TIME_HALF_DURATION: float = 90.0  # 加时赛每半场1.5分钟
const EXTRA_TIME_BREAK: float = 5.0        # 加时赛休息5秒

# 当前阶段剩余时间
var phase_time_remaining: float = 0.0
var match_time: float = 0.0  # 当前半场已用时间

# 比分
var home_score: int = 0
var away_score: int = 0

# 是否需要加时赛（杯赛淘汰赛）
var need_extra_time: bool = false
var need_penalty: bool = false

# 点球大战数据
var penalty_shootout: Dictionary = {
	"home_taken": 0,
	"away_taken": 0,
	"home_scored": 0,
	"away_scored": 0,
	"home_history": [],  # [true/false, ...] 进球记录
	"away_history": [],
	"current_team": 0,   # 0=主队, 1=客队
	"round": 1,
	"is_sudden_death": false,
}

signal phase_changed(phase: int)
signal goal_scored(team: int, scorer: String, minute: int)
signal penalty_taken(team: int, scored: bool)
signal match_finished(result: Dictionary)

## 开始比赛
func start_match(extra_time: bool = false, penalty: bool = false):
	need_extra_time = extra_time
	need_penalty = penalty
	home_score = 0
	away_score = 0
	_set_phase(Phase.FIRST_HALF)

## 设置阶段
func _set_phase(phase: int):
	current_phase = phase
	match phase:
		Phase.FIRST_HALF:
			phase_time_remaining = HALF_DURATION
			match_time = 0.0
			Commentary.trigger("kickoff")
		Phase.HALF_TIME:
			phase_time_remaining = HALF_TIME_BREAK
			Commentary.trigger("halftime")
		Phase.SECOND_HALF:
			phase_time_remaining = HALF_DURATION
			match_time = 0.0
			Commentary.trigger("kickoff", "下半场开始！")
		Phase.FULL_TIME:
			_check_match_end()
		Phase.EXTRA_TIME_FIRST:
			phase_time_remaining = EXTRA_TIME_HALF_DURATION
			match_time = 0.0
			Commentary.trigger("kickoff", "加时赛开始！")
		Phase.EXTRA_TIME_BREAK:
			phase_time_remaining = EXTRA_TIME_BREAK
		Phase.EXTRA_TIME_SECOND:
			phase_time_remaining = EXTRA_TIME_HALF_DURATION
			match_time = 0.0
			Commentary.trigger("kickoff", "加时赛下半场！")
		Phase.PENALTY_SHOOTOUT:
			_init_penalty_shootout()
			Commentary.trigger("penalty", "点球大战！")
		Phase.MATCH_END:
			_finish_match()

	phase_changed.emit(phase)

## 更新比赛时间
func update(delta: float):
	if current_phase in [Phase.PRE_MATCH, Phase.FULL_TIME, Phase.MATCH_END]:
		return

	phase_time_remaining -= delta
	match_time += delta

	if phase_time_remaining <= 0:
		_advance_phase()

## 推进到下一阶段
func _advance_phase():
	match current_phase:
		Phase.FIRST_HALF:
			_set_phase(Phase.HALF_TIME)
		Phase.HALF_TIME:
			_set_phase(Phase.SECOND_HALF)
		Phase.SECOND_HALF:
			_set_phase(Phase.FULL_TIME)
		Phase.EXTRA_TIME_FIRST:
			_set_phase(Phase.EXTRA_TIME_BREAK)
		Phase.EXTRA_TIME_BREAK:
			_set_phase(Phase.EXTRA_TIME_SECOND)
		Phase.EXTRA_TIME_SECOND:
			_set_phase(Phase.FULL_TIME)

## 检查比赛是否结束
func _check_match_end():
	if home_score != away_score:
		# 常规时间分出胜负
		_set_phase(Phase.MATCH_END)
	elif need_extra_time and current_phase == Phase.FULL_TIME:
		# 需要加时赛
		_set_phase(Phase.EXTRA_TIME_FIRST)
	elif need_penalty:
		# 需要点球大战
		_set_phase(Phase.PENALTY_SHOOTOUT)
	else:
		# 平局结束
		_set_phase(Phase.MATCH_END)

## 初始化点球大战
func _init_penalty_shootout():
	penalty_shootout = {
		"home_taken": 0,
		"away_taken": 0,
		"home_scored": 0,
		"away_scored": 0,
		"home_history": [],
		"away_history": [],
		"current_team": 0,
		"round": 1,
		"is_sudden_death": false,
	}

## 执行一次点球
func take_penalty(scored: bool) -> bool:
	if current_phase != Phase.PENALTY_SHOOTOUT:
		return false

	var team = penalty_shootout.current_team
	if team == 0:
		penalty_shootout.home_taken += 1
		penalty_shootout.home_history.append(scored)
		if scored:
			penalty_shootout.home_scored += 1
		penalty_shootout.current_team = 1
	else:
		penalty_shootout.away_taken += 1
		penalty_shootout.away_history.append(scored)
		if scored:
			penalty_shootout.away_scored += 1
		penalty_shootout.current_team = 0
		penalty_shootout.round += 1

	penalty_taken.emit(team, scored)

	if scored:
		Commentary.trigger("goal", "点球命中！")
	else:
		Commentary.trigger("save_penalty", "点球被扑出来了！")

	# 检查点球大战是否结束
	_check_penalty_end()
	return true

## 检查点球大战是否结束
func _check_penalty_end():
	var ps = penalty_shootout
	var home_remaining = 5 - ps.home_taken
	var away_remaining = 5 - ps.away_taken

	# 前5轮
	if ps.home_taken <= 5 or ps.away_taken <= 5:
		# 检查是否已经分出胜负
		if ps.home_taken >= 5 and ps.away_taken >= 5:
			if ps.home_scored != ps.away_scored:
				_set_phase(Phase.MATCH_END)
				return
		# 检查是否一方已经无法追平
		if ps.home_taken >= 5 and ps.home_scored > ps.away_scored + away_remaining:
			_set_phase(Phase.MATCH_END)
			return
		if ps.away_taken >= 5 and ps.away_scored > ps.home_scored + home_remaining:
			_set_phase(Phase.MATCH_END)
			return
	else:
		# 突然死亡法
		ps.is_sudden_death = true
		if ps.home_taken == ps.away_taken and ps.home_taken > 5:
			if ps.home_scored != ps.away_scored:
				_set_phase(Phase.MATCH_END)
				return

## 结束比赛
func _finish_match():
	var result = {
		"home_score": home_score,
		"away_score": away_score,
		"winner": "home" if home_score > away_score else ("away" if away_score > home_score else "draw"),
		"went_extra_time": current_phase >= Phase.EXTRA_TIME_FIRST,
		"went_penalties": current_phase == Phase.PENALTY_SHOOTOUT,
		"penalty_home": penalty_shootout.home_scored if current_phase == Phase.PENALTY_SHOOTOUT else 0,
		"penalty_away": penalty_shootout.away_scored if current_phase == Phase.PENALTY_SHOOTOUT else 0,
	}
	match_finished.emit(result)
	Commentary.trigger("fulltime")

## 获取当前比赛分钟数（模拟）
func get_match_minute() -> int:
	var total_time = 0.0
	match current_phase:
		Phase.FIRST_HALF:
			total_time = match_time
		Phase.HALF_TIME:
			return 45
		Phase.SECOND_HALF:
			total_time = 45.0 + match_time
		Phase.FULL_TIME:
			return 90
		Phase.EXTRA_TIME_FIRST:
			total_time = 90.0 + match_time
		Phase.EXTRA_TIME_BREAK:
			return 105
		Phase.EXTRA_TIME_SECOND:
			total_time = 105.0 + match_time
		Phase.PENALTY_SHOOTOUT:
			return 120
		Phase.MATCH_END:
			return 120
	# 将游戏内时间映射到真实比赛时间（3分钟=45分钟）
	return int(total_time / HALF_DURATION * 45.0)

## 获取阶段名称
func get_phase_name() -> String:
	match current_phase:
		Phase.PRE_MATCH: return "赛前"
		Phase.FIRST_HALF: return "上半场"
		Phase.HALF_TIME: return "中场休息"
		Phase.SECOND_HALF: return "下半场"
		Phase.FULL_TIME: return "常规时间结束"
		Phase.EXTRA_TIME_FIRST: return "加时赛上半场"
		Phase.EXTRA_TIME_BREAK: return "加时赛休息"
		Phase.EXTRA_TIME_SECOND: return "加时赛下半场"
		Phase.PENALTY_SHOOTOUT: return "点球大战"
		Phase.MATCH_END: return "比赛结束"
		_: return "未知"

## 获取点球大战当前轮次显示
func get_penalty_display() -> String:
	if current_phase != Phase.PENALTY_SHOOTOUT:
		return ""
	var ps = penalty_shootout
	var text = "点球大战\n"
	text += "主队 %d - %d 客队\n" % [ps.home_scored, ps.away_scored]
	text += "主队: "
	for h in ps.home_history:
		text += "✓" if h else "✗"
	text += "\n客队: "
	for a in ps.away_history:
		text += "✓" if a else "✗"
	if ps.is_sudden_death:
		text += "\n(突然死亡法)"
	return text
