## save_manager.gd
## 本地存档管理器 (Autoload Singleton)
## 完全不依赖互联网，所有数据保存在本地 user:// 目录
## 使用 JSON 格式存储，方便调试和迁移
extends Node

const SAVE_FILE = "user://save_data.json"

## 默认存档数据结构
func _get_default_data() -> Dictionary:
	return {
		"profile": {
			"name": "Player",
			"level": 1,
			"xp": 0,
			"coins": 500,
			"created_at": Time.get_unix_time_from_system(),
			"matches_played": 0,
			"matches_won": 0,
			"matches_drawn": 0,
			"matches_lost": 0,
			"goals_scored": 0,
			"goals_conceded": 0,
		},
		"settings": {
			"difficulty": "normal",      # easy / normal / hard / legend
			"match_duration": 6,          # 比赛总时长（分钟），实际游戏内会加速
			"sound_volume": 80,
			"music_volume": 70,
			"camera_mode": "follow",      # follow / fixed / broadcast
			"control_scheme": "classic",  # classic / swipe / dual_stick
		},
		"unlocks": {
			"teams": ["home", "away"],
			"formations": ["4-4-2"],
			"difficulties": ["easy", "normal"],
			"events": ["quick_match"],
		},
		"progress": {
			"completed_events": [],
			"achievements": [],
			"tutorial_done": false,
		},
		"roster": {
			# 球员成长数据：球员ID -> {level, xp, stats}
		},
		"stats": {
			"total_goals": 0,
			"total_shots": 0,
			"total_passes": 0,
			"total_tackles": 0,
			"best_win_streak": 0,
			"current_win_streak": 0,
		}
	}

## 读取存档
func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE):
		print("[SaveManager] 未找到存档，创建默认存档")
		var default_data = _get_default_data()
		save_data(default_data)
		return default_data

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] 无法打开存档文件: " + SAVE_FILE)
		return _get_default_data()

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("[SaveManager] 存档解析失败: " + json.get_error_message())
		return _get_default_data()

	var data = json.data
	if not data is Dictionary:
		push_error("[SaveManager] 存档格式错误")
		return _get_default_data()

	# 合并默认值，防止旧存档缺少新字段
	return _merge_defaults(data, _get_default_data())

## 保存存档
func save_data(data: Dictionary) -> bool:
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] 无法写入存档文件: " + SAVE_FILE)
		return false

	var json_text = JSON.stringify(data, "  ")
	file.store_string(json_text)
	file.close()
	print("[SaveManager] 存档已保存")
	return true

## 递归合并默认值，确保旧存档兼容新字段
func _merge_defaults(current: Dictionary, defaults: Dictionary) -> Dictionary:
	var result = current.duplicate(true)
	for key in defaults:
		if not result.has(key):
			result[key] = defaults[key]
		elif result[key] is Dictionary and defaults[key] is Dictionary:
			result[key] = _merge_defaults(result[key], defaults[key])
	return result

## 快捷方法：获取玩家档案
func get_profile() -> Dictionary:
	return load_data().get("profile", {})

## 快捷方法：保存玩家档案
func save_profile(profile: Dictionary) -> bool:
	var data = load_data()
	data["profile"] = profile
	return save_data(data)

## 快捷方法：获取设置
func get_settings() -> Dictionary:
	return load_data().get("settings", {})

## 快捷方法：保存设置
func save_settings(settings: Dictionary) -> bool:
	var data = load_data()
	data["settings"] = settings
	return save_data(data)

## 更新比赛统计
func update_match_result(won: bool, drawn: bool, goals_for: int, goals_against: int) -> void:
	var data = load_data()
	var profile = data["profile"]
	profile["matches_played"] += 1
	if won:
		profile["matches_won"] += 1
	elif drawn:
		profile["matches_drawn"] += 1
	else:
		profile["matches_lost"] += 1
	profile["goals_scored"] += goals_for
	profile["goals_conceded"] += goals_against

	var stats = data["stats"]
	stats["total_goals"] += goals_for
	if won:
		stats["current_win_streak"] += 1
		if stats["current_win_streak"] > stats["best_win_streak"]:
			stats["best_win_streak"] = stats["current_win_streak"]
	else:
		stats["current_win_streak"] = 0

	data["profile"] = profile
	data["stats"] = stats
	save_data(data)

## 解锁内容
func unlock(category: String, item: String) -> void:
	var data = load_data()
	if not data["unlocks"].has(category):
		data["unlocks"][category] = []
	if not data["unlocks"][category].has(item):
		data["unlocks"][category].append(item)
		save_data(data)
		print("[SaveManager] 解锁: %s/%s" % [category, item])

## 检查是否已解锁
func is_unlocked(category: String, item: String) -> bool:
	var data = load_data()
	if not data["unlocks"].has(category):
		return false
	return data["unlocks"][category].has(item)

## 重置存档（危险操作）
func reset_save() -> void:
	save_data(_get_default_data())
	print("[SaveManager] 存档已重置")
