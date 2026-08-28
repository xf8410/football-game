## daily_checkin.gd
## 每日签到系统 (Autoload Singleton)
## 功能：每天登录签到、连续签到奖励递增、7天循环
extends Node

signal checkin_completed(day: int, reward: Dictionary)
signal streak_updated(streak: int)

# 签到数据
var checkin_data: Dictionary = {
	"last_checkin_date": "",    # 上次签到日期 YYYY-MM-DD
	"current_streak": 0,        # 当前连续签到天数
	"total_checkins": 0,        # 总签到次数
	"claimed_today": false,     # 今天是否已签到
}

# 7天签到奖励表
const DAILY_REWARDS = [
	{"day": 1, "coins": 500, "item": "", "name": "500金币"},
	{"day": 2, "coins": 800, "item": "", "name": "800金币"},
	{"day": 3, "coins": 1000, "item": "bronze_pack", "name": "青铜卡包"},
	{"day": 4, "coins": 1200, "item": "", "name": "1200金币"},
	{"day": 5, "coins": 1500, "item": "", "name": "1500金币"},
	{"day": 6, "coins": 2000, "item": "silver_pack", "name": "白银卡包"},
	{"day": 7, "coins": 3000, "item": "gold_pack", "name": "黄金卡包"},
]

const SAVE_FILE = "user://daily_checkin.json"

func _ready():
	load_data()
	_check_date_rollover()

## 检查日期是否过了一天
func _check_date_rollover():
	var today = _get_today_string()
	if checkin_data.last_checkin_date != today:
		checkin_data.claimed_today = false

		# 检查是否断签（上次签到不是昨天）
		if not checkin_data.last_checkin_date.is_empty():
			var yesterday = _get_yesterday_string()
			if checkin_data.last_checkin_date != yesterday:
				# 断签，重置连续天数
				checkin_data.current_streak = 0
				print("[Checkin] 断签，连续签到重置")
		save_data()

## 获取今天的日期字符串
func _get_today_string() -> String:
	var date = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]

## 获取昨天的日期字符串
func _get_yesterday_string() -> String:
	var yesterday = Time.get_unix_time_from_system() - 86400
	var date = Time.get_datetime_dict_from_unix_time(int(yesterday))
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]

## 今天是否可以签到
func can_checkin_today() -> bool:
	return not checkin_data.claimed_today

## 签到
func checkin() -> Dictionary:
	if not can_checkin_today():
		print("[Checkin] 今天已签到")
		return {}

	# 更新连续签到
	checkin_data.current_streak += 1
	if checkin_data.current_streak > 7:
		checkin_data.current_streak = 1  # 7天后重新循环

	checkin_data.total_checkins += 1
	checkin_data.last_checkin_date = _get_today_string()
	checkin_data.claimed_today = true

	# 获取奖励
	var day = checkin_data.current_streak
	var reward = DAILY_REWARDS[day - 1]

	# 发放金币
	if reward.coins > 0:
		TransferMarket.add_budget(reward.coins)

	# 发放卡包（标记，玩家需要去抽卡界面使用）
	if not reward.item.is_empty():
		# 直接开包
		var pack = CardDrawSystem.get_pack(reward.item)
		if not pack.is_empty():
			var results = CardDrawSystem.open_pack(reward.item)
			# 将抽到的卡加入图鉴
			for card in results:
				CardCollection.add_card(card.player_id, card.rarity)
			print("[Checkin] 签到奖励卡包: %s，抽到 %d 张卡" % [reward.item, results.size()])

	save_data()
	checkin_completed.emit(day, reward)
	streak_updated.emit(checkin_data.current_streak)
	print("[Checkin] 签到成功！第%d天，获得: %s" % [day, reward.name])
	return reward

## 获取当前连续签到天数
func get_current_streak() -> int:
	return checkin_data.current_streak

## 获取总签到次数
func get_total_checkins() -> int:
	return checkin_data.total_checkins

## 获取7天奖励表
func get_reward_table() -> Array:
	return DAILY_REWARDS

## 获取今天签到状态
func get_today_status() -> Dictionary:
	var day = checkin_data.current_streak
	if checkin_data.claimed_today:
		return {"claimed": true, "day": day, "reward": DAILY_REWARDS[day - 1] if day > 0 else {}}
	else:
		var next_day = day + 1
		if next_day > 7:
			next_day = 1
		return {"claimed": false, "day": next_day, "reward": DAILY_REWARDS[next_day - 1]}

## 保存数据
func save_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(checkin_data, "  "))
		file.close()

## 加载数据
func load_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			checkin_data = json.data
		file.close()
	print("[Checkin] 已加载签到数据: 连续%d天, 总%d次" % [
		checkin_data.current_streak, checkin_data.total_checkins
	])
