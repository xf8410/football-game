## replay_system.gd
## 回放系统
## 记录比赛关键时刻（进球、精彩射门、扑救），支持回放
extends Node

# 回放帧数据
var recorded_frames: Array = []
var is_recording: bool = false
var record_timer: float = 0.0
const RECORD_INTERVAL: float = 0.05  # 每0.05秒记录一帧（20fps）
const MAX_FRAMES: int = 600  # 最多记录30秒

# 关键事件标记
var key_events: Array = []  # [{frame_index, type, description}]

# 回放播放状态
var is_playing: bool = false
var playback_frame: int = 0
var playback_speed: float = 1.0

## 开始录制
func start_recording():
	recorded_frames.clear()
	key_events.clear()
	is_recording = true
	record_timer = 0.0

## 停止录制
func stop_recording():
	is_recording = false

## 每帧记录比赛状态
func record_frame(match_state: Dictionary):
	if not is_recording:
		return

	record_timer += get_process_delta_time()
	if record_timer < RECORD_INTERVAL:
		return
	record_timer = 0.0

	# 记录关键位置
	var frame = {
		"ball_pos": match_state.get("ball_pos", Vector3.ZERO),
		"ball_height": match_state.get("ball_height", 0.0),
		"home_players": [],
		"away_players": [],
		"score": match_state.get("score", [0, 0]),
		"time": match_state.get("time", 0.0),
	}

	# 记录球员位置（简化）
	for p in match_state.get("home_players", []):
		frame.home_players.append({
			"pos": p.get("position", Vector3.ZERO),
			"anim": p.get("current_anim", 0),
		})
	for p in match_state.get("away_players", []):
		frame.away_players.append({
			"pos": p.get("position", Vector3.ZERO),
			"anim": p.get("current_anim", 0),
		})

	recorded_frames.append(frame)

	# 限制最大帧数
	if recorded_frames.size() > MAX_FRAMES:
		recorded_frames.pop_front()
		# 调整事件索引
		for event in key_events:
			event.frame_index -= 1

## 标记关键事件
func mark_event(event_type: String, description: String = ""):
	if not is_recording:
		return
	key_events.append({
		"frame_index": recorded_frames.size() - 1,
		"type": event_type,
		"description": description,
		"timestamp": Time.get_ticks_msec() / 1000.0,
	})
	print("[Replay] 标记事件: %s (帧 %d)" % [event_type, recorded_frames.size() - 1])

## 开始播放回放
func play_replay(start_frame: int = 0):
	if recorded_frames.is_empty():
		return
	is_playing = true
	playback_frame = start_frame
	print("[Replay] 开始回放，共 %d 帧" % recorded_frames.size())

## 停止回放
func stop_replay():
	is_playing = false
	playback_frame = 0

## 获取当前回放帧
func get_playback_frame() -> Dictionary:
	if not is_playing or playback_frame >= recorded_frames.size():
		is_playing = false
		return {}
	var frame = recorded_frames[playback_frame]
	playback_frame += 1
	return frame

## 获取关键事件列表
func get_key_events() -> Array:
	return key_events

## 获取进球事件
func get_goal_events() -> Array:
	var goals = []
	for event in key_events:
		if event.type in ["goal", "goal_header", "goal_own"]:
			goals.append(event)
	return goals

## 回放是否正在播放
func is_replay_playing() -> bool:
	return is_playing

## 获取回放进度（0-1）
func get_playback_progress() -> float:
	if recorded_frames.is_empty():
		return 0.0
	return float(playback_frame) / recorded_frames.size()

## 跳转到指定事件
func seek_to_event(event_index: int):
	if event_index < 0 or event_index >= key_events.size():
		return
	playback_frame = key_events[event_index].frame_index
