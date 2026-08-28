## audio_manager.gd
## 音频管理器（完善版）
## 程序化生成所有音效，无需外部文件
extends Node

var audio_players: Array = []
const MAX_AUDIO_PLAYERS = 16

# 音效类型
enum SFX {
	KICK_LIGHT,      # 轻踢
	KICK_HEAVY,      # 重踢
	PASS,            # 传球
	CATCH,           # 接球
	TACKLE,          # 铲球
	WHISTLE_SHORT,   # 短哨
	WHISTLE_LONG,    # 长哨
	GOAL,            # 进球
	CROWD_CHEER,     # 观众欢呼
	CROWD_BOO,       # 观众嘘声
	CROSSBAR,        # 击中横梁
	POST,            # 击中立柱
	# 新增音效
	BALL_BOUNCE,     # 球弹地
	SLIDE,           # 滑铲
	HEADER,          # 头球
	SAVE,            # 扑救
	HANDBALL,        # 手球
	FOUL,            # 犯规
	CARD_YELLOW,     # 黄牌
	CARD_RED,        # 红牌
	SUBSTITUTION,    # 换人
	CORNER_KICK,     # 角球
	THROW_IN,        # 界外球
	PENALTY_KICK,    # 点球
	MENU_CLICK,      # 菜单点击
	MENU_HOVER,      # 菜单悬停
	COIN,            # 金币
	LEVEL_UP,        # 升级
	ACHIEVEMENT,     # 成就解锁
	WHISTLE_START,   # 开球哨
	WHISTLE_HALF,    # 半场哨
	WHISTLE_FULL,    # 终场哨
}

var sfx_cache: Dictionary = {}

func _ready():
	_preload_sfx()

func _preload_sfx():
	# 原有音效
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

	# 新增音效
	sfx_cache[SFX.BALL_BOUNCE] = _generate_ball_bounce()
	sfx_cache[SFX.SLIDE] = _generate_slide_sound()
	sfx_cache[SFX.HEADER] = _generate_header_sound()
	sfx_cache[SFX.SAVE] = _generate_save_sound()
	sfx_cache[SFX.HANDBALL] = _generate_handball_sound()
	sfx_cache[SFX.FOUL] = _generate_foul_sound()
	sfx_cache[SFX.CARD_YELLOW] = _generate_card_sound(false)
	sfx_cache[SFX.CARD_RED] = _generate_card_sound(true)
	sfx_cache[SFX.SUBSTITUTION] = _generate_substitution_sound()
	sfx_cache[SFX.CORNER_KICK] = _generate_corner_sound()
	sfx_cache[SFX.THROW_IN] = _generate_throw_in_sound()
	sfx_cache[SFX.PENALTY_KICK] = _generate_penalty_sound()
	sfx_cache[SFX.MENU_CLICK] = _generate_menu_click()
	sfx_cache[SFX.MENU_HOVER] = _generate_menu_hover()
	sfx_cache[SFX.COIN] = _generate_coin_sound()
	sfx_cache[SFX.LEVEL_UP] = _generate_level_up_sound()
	sfx_cache[SFX.ACHIEVEMENT] = _generate_achievement_sound()
	sfx_cache[SFX.WHISTLE_START] = _generate_whistle_start()
	sfx_cache[SFX.WHISTLE_HALF] = _generate_whistle_half()
	sfx_cache[SFX.WHISTLE_FULL] = _generate_whistle_full()

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
	for player in audio_players:
		if not player.playing:
			return player

	# 创建新的播放器
	var player = AudioStreamPlayer.new()
	add_child(player)
	audio_players.append(player)
	return player

## 生成踢球音效
func _generate_kick_sound(duration: float, base_freq: int) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 8)
		var tone = sin(t * base_freq * TAU) * 0.5
		var noise = (randf() - 0.5) * 0.3
		var sample = int((tone + noise) * env * 32767 * 0.7)
		sample = clamp(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成接球音效
func _generate_catch_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.15
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 15)
		var tone = sin(t * 200 * TAU) * 0.3
		var noise = (randf() - 0.5) * 0.4
		var sample = int((tone + noise) * env * 32767 * 0.6)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成铲球音效
func _generate_tackle_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.4
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 5)
		# 摩擦声
		var noise = (randf() - 0.5) * 0.5
		# 低频成分
		var tone = sin(t * 100 * TAU) * 0.2
		var sample = int((noise + tone) * env * 32767 * 0.6)
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
		var env = min(1.0, t * 10) * min(1.0, (duration - t) * 10)
		# 哨声主频
		var freq = 2000 + sin(t * 30) * 200
		var tone = sin(t * freq * TAU) * 0.4
		# 谐波
		var tone2 = sin(t * freq * 2 * TAU) * 0.15
		var sample = int((tone + tone2) * env * 32767 * 0.5)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成进球音效
func _generate_goal_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 1.5
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 1.5)
		# 球网声
		var net = (randf() - 0.5) * 0.3 * exp(-t * 8)
		# 上升音调
		var freq = 400 + t * 200
		var tone = sin(t * freq * TAU) * 0.3
		var sample = int((net + tone) * env * 32767 * 0.6)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成观众声
func _generate_crowd_sound(cheer: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 2.0
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = min(1.0, t * 2) * min(1.0, (duration - t) * 2)
		# 观众噪声
		var noise = (randf() - 0.5) * 0.4
		if cheer:
			# 欢呼：上升音调
			var freq = 300 + t * 100
			noise += sin(t * freq * TAU) * 0.2
		else:
			# 嘘声：低频
			noise += sin(t * 150 * TAU) * 0.3
		var sample = int(noise * env * 32767 * 0.5)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成横梁音效
func _generate_crossbar_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.8
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 4)
		var tone1 = sin(t * 1200 * TAU) * 0.4
		var tone2 = sin(t * 2400 * TAU) * 0.2
		var tone3 = sin(t * 3600 * TAU) * 0.1
		var sample = int((tone1 + tone2 + tone3) * env * 32767 * 0.5)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 生成立柱音效
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
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

# ============ 新增音效 ============

## 球弹地
func _generate_ball_bounce() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.2
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 20)
		var tone = sin(t * 150 * TAU) * 0.4
		var noise = (randf() - 0.5) * 0.2
		var sample = int((tone + noise) * env * 32767 * 0.5)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 滑铲
func _generate_slide_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.5
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = min(1.0, t * 5) * exp(-t * 3)
		var noise = (randf() - 0.5) * 0.5
		# 摩擦高频
		var tone = sin(t * 3000 * TAU) * 0.1
		var sample = int((noise + tone) * env * 32767 * 0.4)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 头球
func _generate_header_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.15
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 12)
		var tone = sin(t * 300 * TAU) * 0.3
		var noise = (randf() - 0.5) * 0.4
		var sample = int((tone + noise) * env * 32767 * 0.6)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 扑救
func _generate_save_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.3
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 8)
		var tone = sin(t * 250 * TAU) * 0.3
		var noise = (randf() - 0.5) * 0.3
		var sample = int((tone + noise) * env * 32767 * 0.6)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 手球
func _generate_handball_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.2
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 15)
		var tone = sin(t * 500 * TAU) * 0.3
		var noise = (randf() - 0.5) * 0.3
		var sample = int((tone + noise) * env * 32767 * 0.5)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 犯规
func _generate_foul_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.5
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 4)
		var noise = (randf() - 0.5) * 0.4
		var tone = sin(t * 150 * TAU) * 0.2
		var sample = int((noise + tone) * env * 32767 * 0.5)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 黄/红牌
func _generate_card_sound(is_red: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.3
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 10)
		# 纸张声
		var noise = (randf() - 0.5) * 0.3
		# 音调（红牌更低）
		var freq = 300 if is_red else 500
		var tone = sin(t * freq * TAU) * 0.2
		var sample = int((noise + tone) * env * 32767 * 0.4)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 换人
func _generate_substitution_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.8
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = min(1.0, t * 3) * exp(-t * 2)
		# 电子音
		var freq = 400 + t * 400
		var tone = sin(t * freq * TAU) * 0.3
		var sample = int(tone * env * 32767 * 0.4)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 角球
func _generate_corner_sound() -> AudioStreamWAV:
	return _generate_whistle(0.2)

## 界外球
func _generate_throw_in_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.3
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 8)
		var tone = sin(t * 400 * TAU) * 0.3
		var sample = int(tone * env * 32767 * 0.4)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 点球
func _generate_penalty_sound() -> AudioStreamWAV:
	return _generate_whistle(0.5)

## 菜单点击
func _generate_menu_click() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.1
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 30)
		var tone = sin(t * 800 * TAU) * 0.3
		var sample = int(tone * env * 32767 * 0.4)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 菜单悬停
func _generate_menu_hover() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.05
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 50)
		var tone = sin(t * 1200 * TAU) * 0.2
		var sample = int(tone * env * 32767 * 0.3)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 金币
func _generate_coin_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.3
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 8)
		# 上升音调
		var freq = 600 + t * 600
		var tone = sin(t * freq * TAU) * 0.3
		var sample = int(tone * env * 32767 * 0.4)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 升级
func _generate_level_up_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.8
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = min(1.0, t * 5) * exp(-t * 2)
		# 上升音阶
		var freq = 400 + t * 800
		var tone = sin(t * freq * TAU) * 0.3
		var tone2 = sin(t * freq * 1.5 * TAU) * 0.15
		var sample = int((tone + tone2) * env * 32767 * 0.4)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 成就解锁
func _generate_achievement_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 1.0
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = min(1.0, t * 3) * exp(-t * 1.5)
		# 和弦
		var freq1 = 523  # C5
		var freq2 = 659  # E5
		var freq3 = 784  # G5
		var tone = sin(t * freq1 * TAU) * 0.2 + sin(t * freq2 * TAU) * 0.15 + sin(t * freq3 * TAU) * 0.15
		var sample = int(tone * env * 32767 * 0.4)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

## 开球哨
func _generate_whistle_start() -> AudioStreamWAV:
	return _generate_whistle(0.4)

## 半场哨
func _generate_whistle_half() -> AudioStreamWAV:
	return _generate_whistle(0.8)

## 终场哨
func _generate_whistle_full() -> AudioStreamWAV:
	return _generate_whistle(1.5)
