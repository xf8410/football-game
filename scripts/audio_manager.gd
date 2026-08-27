## audio_manager.gd
## 音频管理器 (Autoload Singleton)
## 管理：踢球音效、传球音效、接球音效、哨声、铲球音效、解说
##
## 音效通过程序化生成（无需外部音频文件）
extends Node

var audio_players: Array = []
const MAX_AUDIO_PLAYERS = 8

# 音效类型
enum SFX {
	KICK_LIGHT,     # 轻踢
	KICK_HEAVY,     # 重踢
	PASS,           # 传球
	CATCH,          # 接球
	TACKLE,         # 铲球
	WHISTLE_SHORT,  # 短哨
	WHISTLE_LONG,   # 长哨
	GOAL,           # 进球
	CROWD_CHEER,    # 观众欢呼
	CROWD_BOO,      # 观众嘘声
	CROSSBAR,       # 击中横梁
	POST,           # 击中立柱
}

var sfx_cache: Dictionary = {}

func _ready():
	_preload_sfx()

func _preload_sfx():
	# 程序化生成所有音效
	sfx_cache[SFX.KICK_LIGHT] = _generate_kick_sound(0.15, 800)
	sfx_cache[SFX.KICK_HEAVY] = _generate_kick_sound(0.3, 400)
	sfx_cache[SFX.PASS] = _generate_kick_sound(0.12, 600)
	sfx_cache[SFX.CATCH] = _generate_catch_sound()
	sfx_cache[SFX.TACKLE] = _generate_tackle_sound()
	sfx_cache[SFX.WHISTLE_SHORT] = _generate_whistle(0.3)
	sfx_cache[SFX.WHISTLE_LONG] = _generate_whistle(1.0)
	sfx_cache[SFX.GOAL] = _generate_goal_sound()
	sfx_cache[SFX.CROWD_CHEER] = _generate_crowd_sound(true)
	sfx_cache[SFX.CROWD_BOO] = _generate_crowd_sound(false)
	sfx_cache[SFX.CROSSBAR] = _generate_crossbar_sound()
	sfx_cache[SFX.POST] = _generate_post_sound()
	print("[Audio] 已生成 %d 个音效" % sfx_cache.size())

## 播放音效
func play_sfx(sfx_type: int, volume_db: float = 0.0):
	if not sfx_cache.has(sfx_type):
		return
	var stream = sfx_cache[sfx_type]
	var player = _get_available_player()
	player.stream = stream
	player.volume_db = volume_db
	player.play()

## 获取可用的音频播放器
func _get_available_player() -> AudioStreamPlayer:
	for p in audio_players:
		if not p.playing:
			return p
	# 创建新的
	var player = AudioStreamPlayer.new()
	add_child(player)
	audio_players.append(player)
	return player

# ============================================================
# 音效生成函数
# ============================================================

## 生成踢球音效（短促的冲击声）
func _generate_kick_sound(duration: float, base_freq: int) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 30)  # 快速衰减
		var noise = (randf() * 2 - 1) * 0.3
		var tone = sin(t * base_freq * TAU) * 0.5
		var sample = int((tone + noise) * env * 32767 * 0.5)
		sample = clamp(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成接球音效（闷响）
func _generate_catch_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.2
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 15)
		var noise = (randf() * 2 - 1) * 0.6
		var tone = sin(t * 150 * TAU) * 0.3
		var sample = int((tone + noise) * env * 32767 * 0.4)
		sample = clamp(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成铲球音效（摩擦+冲击）
func _generate_tackle_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.5
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 5)
		# 摩擦声（高频噪声）
		var scrape = (randf() * 2 - 1) * 0.4 * sin(t * 3000)
		# 冲击声
		var impact = sin(t * 200 * TAU) * exp(-t * 20) * 0.5
		var sample = int((scrape + impact) * env * 32767 * 0.5)
		sample = clamp(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成哨声
func _generate_whistle(duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		# 哨声主频（约2000Hz）+ 谐波
		var fundamental = sin(t * 2000 * TAU)
		var harmonic1 = sin(t * 4000 * TAU) * 0.3
		var harmonic2 = sin(t * 6000 * TAU) * 0.15
		# 颤音
		var vibrato = 1.0 + sin(t * 15 * TAU) * 0.05
		# 包络（渐入渐出）
		var env = 1.0
		if t < 0.05:
			env = t / 0.05
		elif t > duration - 0.1:
			env = (duration - t) / 0.1
		var sample = int((fundamental + harmonic1 + harmonic2) * vibrato * env * 32767 * 0.3)
		sample = clamp(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成进球音效（上升音调）
func _generate_goal_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 1.5
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		# 上升音调
		var freq = 400 + t * 600
		var tone = sin(t * freq * TAU) * 0.5
		var harmonic = sin(t * freq * 2 * TAU) * 0.2
		var env = exp(-t * 1.5) * (1 - exp(-t * 10))
		var sample = int((tone + harmonic) * env * 32767 * 0.5)
		sample = clamp(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成观众声（欢呼或嘘声）
func _generate_crowd_sound(cheer: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 3.0
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	# 生成多个噪声层模拟人群
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env: float
		if cheer:
			env = (1 - exp(-t * 3)) * exp(-t * 0.3)  # 渐入慢衰减
		else:
			env = (1 - exp(-t * 5)) * exp(-t * 0.8)  # 嘘声更快衰减

		# 多层噪声
		var noise1 = (randf() * 2 - 1) * 0.4
		var noise2 = (randf() * 2 - 1) * 0.3
		var noise3 = (randf() * 2 - 1) * 0.2

		# 欢呼时有低频调制
		var modulation = 1.0
		if cheer:
			modulation = 1.0 + sin(t * 4 * TAU) * 0.1

		var sample = int((noise1 + noise2 + noise3) * env * modulation * 32767 * 0.3)
		sample = clamp(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成击中横梁音效（金属共鸣）
func _generate_crossbar_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.8
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 4)
		# 金属共鸣声（多个高频谐波）
		var tone1 = sin(t * 1200 * TAU) * 0.4
		var tone2 = sin(t * 2400 * TAU) * 0.2
		var tone3 = sin(t * 3600 * TAU) * 0.1
		var sample = int((tone1 + tone2 + tone3) * env * 32767 * 0.5)
		sample = clamp(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成击中立柱音效
func _generate_post_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.6
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 5)
		var tone1 = sin(t * 800 * TAU) * 0.4
		var tone2 = sin(t * 1600 * TAU) * 0.2
		var sample = int((tone1 + tone2) * env * 32767 * 0.5)
		sample = clamp(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
