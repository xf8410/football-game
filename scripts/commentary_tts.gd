## commentary_tts.gd
## TTS解说语音系统
## 使用 z-ai-web-dev-sdk 生成中文解说语音
## 在比赛关键时刻自动播放解说语音
extends Node

signal tts_played(text: String)

# 预生成的语音缓存
var voice_cache: Dictionary = {}
var cache_dir: String = "user://tts_cache/"

# 是否启用TTS
var tts_enabled: bool = true

# 当前正在播放的音频
var current_player: AudioStreamPlayer = null
var playback_queue: Array = []

func _ready():
	# 创建缓存目录
	DirAccess.make_dir_recursive_absolute(cache_dir)
	# 预加载常用解说语音
	_preload_common_voices()

## 预加载常用解说语音
func _preload_common_voices():
	var common_phrases = [
		"goal_cheer": "进球了！",
		"goal_great": "漂亮的进球！",
		"goal_world": "世界波！这球太精彩了！",
		"save_great": "精彩的扑救！",
		"foul_whistle": "犯规！裁判鸣哨！",
		"yellow_card": "黄牌！",
		"red_card": "红牌！直接罚下！",
		"corner": "角球！",
		"penalty": "点球！裁判判罚点球！",
		"kickoff": "比赛开始！",
		"halftime": "上半场结束！",
		"fulltime": "全场比赛结束！",
		"hat_trick": "帽子戏法！他今天状态火热！",
		"own_goal": "乌龙球！太不走运了！",
		"miss": "射门偏出了！太可惜了！",
		"crossbar": "击中横梁！",
	]

	for key in common_phrases:
		var text = common_phrases[key]
		var file_path = cache_dir + key + ".wav"
		if FileAccess.file_exists(file_path):
			# 已缓存
			voice_cache[key] = file_path
		else:
			# 需要生成（标记为待生成）
			voice_cache[key] = ""

	print("[TTS] 预加载了 %d 条解说语音" % voice_cache.size())

## 生成TTS语音（调用外部脚本）
func generate_voice(text: String, cache_key: String) -> String:
	var file_path = cache_dir + cache_key + ".wav"
	if FileAccess.file_exists(file_path):
		return file_path

	# 调用Python脚本生成TTS
	var script_path = "res://scripts/generate_tts.py"
	var output = []
	var exit_code = OS.execute("python3", [script_path, text, ProjectSettings.globalize_path(file_path)], output)

	if exit_code == 0 and FileAccess.file_exists(file_path):
		voice_cache[cache_key] = file_path
		print("[TTS] 生成语音: %s -> %s" % [cache_key, file_path])
		return file_path
	else:
		print("[TTS] 生成失败: %s" % cache_key)
		return ""

## 播放解说语音
func play_commentary_voice(key: String, text: String = ""):
	if not tts_enabled:
		return

	var voice_path = voice_cache.get(key, "")
	if voice_path.is_empty() and not text.is_empty():
		# 实时生成
		voice_path = generate_voice(text, key)

	if voice_path.is_empty():
		return

	# 加载并播放
	var stream = AudioStreamWAV.new()
	var file = FileAccess.open(voice_path, FileAccess.READ)
	if file:
		stream.data = file.get_buffer(file.get_length())
		file.close()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050

		var player = AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = -3.0
		add_child(player)
		player.play()
		player.finished.connect(func():
			player.queue_free()
			_play_next_in_queue()
		)

		tts_played.emit(text if not text.is_empty() else key)
		print("[TTS] 播放: %s" % key)

## 将语音加入播放队列
func queue_voice(key: String, text: String = ""):
	playback_queue.append({"key": key, "text": text})
	if current_player == null:
		_play_next_in_queue()

func _play_next_in_queue():
	if playback_queue.is_empty():
		return
	var next = playback_queue.pop_front()
	play_commentary_voice(next.key, next.text)

## 触发解说（文字+语音）
func trigger_with_voice(type: String, custom_text: String = ""):
	# 先触发文字解说
	Commentary.trigger(type, custom_text)

	# 再播放语音
	var voice_key = type
	var voice_text = custom_text if not custom_text.is_empty() else Commentary.get_random_text(type)
	queue_voice(voice_key, voice_text)

## 设置TTS开关
func set_tts_enabled(enabled: bool):
	tts_enabled = enabled

## 清理缓存
func clear_cache():
	DirAccess.remove_absolute_or_empty(cache_dir)
	DirAccess.make_dir_recursive_absolute(cache_dir)
	voice_cache.clear()
	print("[TTS] 缓存已清理")
