## achievement_system.gd
## 成就系统 (Autoload Singleton)
## 功能：解锁成就、获得奖励、成就进度追踪
extends Node

signal achievement_unlocked(achievement_id: String)
signal progress_updated(achievement_id: String, progress: int, target: int)

# 成就数据
var achievements: Dictionary = {}
var achievement_progress: Dictionary = {}  # achievement_id -> current_progress

const SAVE_FILE = "user://achievements.json"

func _ready():
	_init_achievements()
	load_data()

## 初始化所有成就定义
func _init_achievements():
	achievements = {
		# ---- 比赛类 ----
		"first_win": {
			"name": "首场胜利", "description": "赢得第一场比赛",
			"category": "match", "target": 1, "reward": {"coins": 500},
		},
		"win_10": {
			"name": "十战十胜", "description": "累计赢得10场比赛",
			"category": "match", "target": 10, "reward": {"coins": 2000},
		},
		"win_50": {
			"name": "常胜将军", "description": "累计赢得50场比赛",
			"category": "match", "target": 50, "reward": {"coins": 5000, "item": "gold_pack"},
		},
		"win_100": {
			"name": "百战不殆", "description": "累计赢得100场比赛",
			"category": "match", "target": 100, "reward": {"coins": 10000, "item": "icon_pack"},
		},
		"hat_trick": {
			"name": "帽子戏法", "description": "单场比赛进3球",
			"category": "match", "target": 1, "reward": {"coins": 1000},
		},
		"big_win": {
			"name": "大胜", "description": "以5球以上优势获胜",
			"category": "match", "target": 1, "reward": {"coins": 1500},
		},
		"clean_sheet": {
			"name": "零封对手", "description": "不失球赢得比赛",
			"category": "match", "target": 10, "reward": {"coins": 3000},
		},
		"comeback": {
			"name": "逆转之王", "description": "从落后2球以上逆转获胜",
			"category": "match", "target": 1, "reward": {"coins": 2000},
		},

		# ---- 进球类 ----
		"goal_10": {
			"name": "初露锋芒", "description": "累计进10球",
			"category": "goal", "target": 10, "reward": {"coins": 500},
		},
		"goal_100": {
			"name": "百球里程碑", "description": "累计进100球",
			"category": "goal", "target": 100, "reward": {"coins": 3000},
		},
		"goal_500": {
			"name": "神射手", "description": "累计进500球",
			"category": "goal", "target": 500, "reward": {"coins": 10000, "item": "icon_pack"},
		},
		"long_shot_goal": {
			"name": "远射大师", "description": "25米外进球10次",
			"category": "goal", "target": 10, "reward": {"coins": 2000},
		},
		"header_goal": {
			"name": "空霸", "description": "头球进球10次",
			"category": "goal", "target": 10, "reward": {"coins": 1500},
		},
		"world_wave": {
			"name": "世界波", "description": "打进世界波5次",
			"category": "goal", "target": 5, "reward": {"coins": 2500},
		},

		# ---- 收集类 ----
		"collect_10": {
			"name": "初入收藏", "description": "收集10名不同球员",
			"category": "collection", "target": 10, "reward": {"coins": 500},
		},
		"collect_50": {
			"name": "收藏家", "description": "收集50名不同球员",
			"category": "collection", "target": 50, "reward": {"coins": 3000},
		},
		"collect_100": {
			"name": "图鉴大师", "description": "收集100名不同球员",
			"category": "collection", "target": 100, "reward": {"coins": 8000, "item": "icon_pack"},
		},
		"first_legendary": {
			"name": "传奇降临", "description": "获得第一张传奇卡",
			"category": "collection", "target": 1, "reward": {"coins": 2000},
		},
		"first_icon": {
			"name": "时刻之星", "description": "获得第一张时刻卡",
			"category": "collection", "target": 1, "reward": {"coins": 5000},
		},

		# ---- 联赛类 ----
		"league_champion": {
			"name": "联赛冠军", "description": "赢得一次联赛冠军",
			"category": "league", "target": 1, "reward": {"coins": 5000, "item": "gold_pack"},
		},
		"league_undefeated": {
			"name": "不败赛季", "description": "整个联赛赛季不败",
			"category": "league", "target": 1, "reward": {"coins": 10000, "item": "icon_pack"},
		},
		"league_top_scorer": {
			"name": "金靴奖", "description": "联赛射手榜第一",
			"category": "league", "target": 1, "reward": {"coins": 3000},
		},

		# ---- 杯赛类 ----
		"cup_champion": {
			"name": "杯赛之王", "description": "赢得一次杯赛冠军",
			"category": "cup", "target": 1, "reward": {"coins": 5000, "item": "gold_pack"},
		},
		"cup_no_goal": {
			"name": "钢铁防线", "description": "整个杯赛不失球夺冠",
			"category": "cup", "target": 1, "reward": {"coins": 8000, "item": "icon_pack"},
		},

		# ---- 特殊类 ----
		"penalty_save": {
			"name": "点球终结者", "description": "扑出5个点球",
			"category": "special", "target": 5, "reward": {"coins": 2000},
		},
		"own_goal": {
			"name": "不幸的一天", "description": "打进1个乌龙球",
			"category": "special", "target": 1, "reward": {"coins": 100},
		},
		"red_card": {
			"name": "冲动是魔鬼", "description": "获得1张红牌",
			"category": "special", "target": 1, "reward": {"coins": 100},
		},
		"checkin_7": {
			"name": "坚持签到", "description": "连续签到7天",
			"category": "special", "target": 7, "reward": {"coins": 1000},
		},
		"checkin_30": {
			"name": "月度全勤", "description": "累计签到30天",
			"category": "special", "target": 30, "reward": {"coins": 5000, "item": "gold_pack"},
		},
	}

## 更新成就进度
func update_progress(achievement_id: String, increment: int = 1):
	if not achievements.has(achievement_id):
		return
	if achievement_progress.has(achievement_id) and achievement_progress[achievement_id].get("unlocked", false):
		return  # 已解锁

	var current = achievement_progress.get(achievement_id, {}).get("progress", 0)
	current += increment
	var target = achievements[achievement_id].target

	if not achievement_progress.has(achievement_id):
		achievement_progress[achievement_id] = {}
	achievement_progress[achievement_id].progress = current

	progress_updated.emit(achievement_id, current, target)

	if current >= target:
		_unlock(achievement_id)
	else:
		save_data()

## 直接设置进度（用于绝对值类型的成就）
func set_progress(achievement_id: String, value: int):
	if not achievements.has(achievement_id):
		return
	if achievement_progress.has(achievement_id) and achievement_progress[achievement_id].get("unlocked", false):
		return

	var target = achievements[achievement_id].target
	if not achievement_progress.has(achievement_id):
		achievement_progress[achievement_id] = {}
	achievement_progress[achievement_id].progress = min(value, target)

	progress_updated.emit(achievement_id, min(value, target), target)

	if value >= target:
		_unlock(achievement_id)
	else:
		save_data()

## 解锁成就
func _unlock(achievement_id: String):
	if not achievements.has(achievement_id):
		return
	if achievement_progress.has(achievement_id) and achievement_progress[achievement_id].get("unlocked", false):
		return

	if not achievement_progress.has(achievement_id):
		achievement_progress[achievement_id] = {}
	achievement_progress[achievement_id].unlocked = true
	achievement_progress[achievement_id].unlocked_date = Time.get_datetime_string_from_system()

	# 发放奖励
	var reward = achievements[achievement_id].reward
	if reward.has("coins"):
		TransferMarket.add_budget(reward.coins)
	if reward.has("item"):
		var pack = CardDrawSystem.get_pack(reward.item)
		if not pack.is_empty():
			var results = CardDrawSystem.open_pack(reward.item)
			for card in results:
				CardCollection.add_card(card.player_id, card.rarity)

	achievement_unlocked.emit(achievement_id)
	print("[Achievement] 解锁成就: %s！" % achievements[achievement_id].name)
	save_data()

## 检查成就是否已解锁
func is_unlocked(achievement_id: String) -> bool:
	return achievement_progress.has(achievement_id) and achievement_progress[achievement_id].get("unlocked", false)

## 获取成就进度
func get_progress(achievement_id: String) -> int:
	return achievement_progress.get(achievement_id, {}).get("progress", 0)

## 获取所有成就
func get_all_achievements() -> Dictionary:
	return achievements

## 获取已解锁数量
func get_unlocked_count() -> int:
	var count = 0
	for aid in achievement_progress:
		if achievement_progress[aid].get("unlocked", false):
			count += 1
	return count

## 获取分类成就
func get_achievements_by_category(category: String) -> Array:
	var result = []
	for aid in achievements:
		if achievements[aid].category == category:
			result.append(aid)
	return result

## 保存数据
func save_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(achievement_progress, "  "))
		file.close()

## 加载数据
func load_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			achievement_progress = json.data
		file.close()
	print("[Achievement] 已加载成就: %d/%d 解锁" % [get_unlocked_count(), achievements.size()])
