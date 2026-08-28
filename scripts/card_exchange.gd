## card_exchange.gd
## 球员卡牌交易系统
## 不同联赛有专属货币，只能兑换对应联赛的球员
## 例如：英格兰联赛货币只能兑换英格兰俱乐部的C罗，不能兑换皇马时期的C罗
extends Node

signal exchange_made(player_id: String, league_currency: String)
signal currency_earned(league_id: String, amount: int)

# 联赛专属货币
var league_currencies: Dictionary = {
	"premier_league": {"name": "英超代币", "amount": 0, "color": "#3D195B"},
	"la_liga": {"name": "西甲代币", "amount": 0, "color": "#FF6B00"},
	"bundesliga": {"name": "德甲代币", "amount": 0, "color": "#D20515"},
	"serie_a": {"name": "意甲代币", "amount": 0, "color": "#008FD7"},
	"ligue_1": {"name": "法甲代币", "amount": 0, "color": "#091C3E"},
	"primeira_liga": {"name": "葡超代币", "amount": 0, "color": "#006600"},
	"eredivisie": {"name": "荷甲代币", "amount": 0, "color": "#FF6600"},
	"super_lig": {"name": "土超代币", "amount": 0, "color": "#E30A17"},
	"mls": {"name": "美职联代币", "amount": 0, "color": "#3D195B"},
	"saudi_pro_league": {"name": "沙特联代币", "amount": 0, "color": "#006C35"},
	"csl": {"name": "中超代币", "amount": 0, "color": "#DE2910"},
	"argentine_league": {"name": "阿甲代币", "amount": 0, "color": "#75AADB"},
	"brasileirao": {"name": "巴甲代币", "amount": 0, "color": "#009C3B"},
	"national": {"name": "国家队代币", "amount": 0, "color": "#1A1A2E"},
}

# 通用金币（可兑换任何球员，但价格更高）
var universal_coins: int = 5000

const SAVE_FILE = "user://card_exchange.json"

func _ready():
	load_state()

## 打比赛获得联赛专属货币
func earn_league_currency(league_id: String, amount: int):
	if league_currencies.has(league_id):
		league_currencies[league_id].amount += amount
		currency_earned.emit(league_id, amount)
		print("[Exchange] 获得 %s: +%d (总计: %d)" % [
			league_currencies[league_id].name, amount, league_currencies[league_id].amount
		])
		save_state()

## 获取联赛货币数量
func get_currency(league_id: String) -> int:
	if league_currencies.has(league_id):
		return league_currencies[league_id].amount
	return 0

## 获取所有货币信息
func get_all_currencies() -> Dictionary:
	return league_currencies

## 计算球员兑换价格（联赛专属货币）
func get_player_price(player_id: String) -> Dictionary:
	var player = PlayerDatabase.get_player(player_id)
	if player.is_empty():
		return {}

	var rating = PlayerDatabase.get_player_rating(player_id)
	var club = player.get("club", "")
	var is_national = player.get("is_national", false)
	var is_legend = player.get("is_legend", false)
	var is_ambassador = player.get("is_ambassador", false)

	# 确定所属联赛
	var league_id = ""
	if is_national:
		league_id = "national"
	else:
		var team = TeamDatabase.get_team(club)
		league_id = team.get("league", "")

	# 基础价格（根据评分）
	var base_price = pow(rating - 60, 2) * 10

	# 特殊版本加价
	if is_ambassador:
		base_price *= 3
	elif is_legend:
		base_price *= 2

	# 联赛专属货币价格（较便宜）
	var league_price = int(base_price)

	# 通用金币价格（较贵，1.5倍）
	var universal_price = int(base_price * 1.5)

	return {
		"league_id": league_id,
		"league_price": league_price,
		"universal_price": universal_price,
		"rating": rating,
	}

## 兑换球员（用联赛专属货币）
func exchange_with_league_currency(player_id: String) -> bool:
	var price = get_player_price(player_id)
	if price.is_empty():
		return false

	var league_id = price.league_id
	var league_price = price.league_price

	if not league_currencies.has(league_id):
		print("[Exchange] 未知联赛: " + league_id)
		return false

	if league_currencies[league_id].amount < league_price:
		print("[Exchange] %s 不足！需要 %d，当前 %d" % [
			league_currencies[league_id].name, league_price, league_currencies[league_id].amount
		])
		return false

	# 扣除货币
	league_currencies[league_id].amount -= league_price

	# 添加球员到收藏
	CardCollection.add_card(player_id, _get_rarity_by_rating(price.rating))

	# 添加到拥有的球员
	if not TransferMarket.owned_players.has(player_id):
		TransferMarket.owned_players.append(player_id)

	exchange_made.emit(player_id, league_id)
	print("[Exchange] ✅ 用 %s 兑换成功: %s" % [
		league_currencies[league_id].name, PlayerDatabase.get_player_name(player_id)
	])
	save_state()
	return true

## 兑换球员（用通用金币）
func exchange_with_universal_coins(player_id: String) -> bool:
	var price = get_player_price(player_id)
	if price.is_empty():
		return false

	if universal_coins < price.universal_price:
		print("[Exchange] 通用金币不足！需要 %d，当前 %d" % [
			price.universal_price, universal_coins
		])
		return false

	# 扣除金币
	universal_coins -= price.universal_price

	# 添加球员
	CardCollection.add_card(player_id, _get_rarity_by_rating(price.rating))
	if not TransferMarket.owned_players.has(player_id):
		TransferMarket.owned_players.append(player_id)

	print("[Exchange] ✅ 用通用金币兑换成功: %s" % PlayerDatabase.get_player_name(player_id))
	save_state()
	return true

## 根据评分获取稀有度
func _get_rarity_by_rating(rating: int) -> int:
	if rating >= 93:
		return 4  # 时刻
	elif rating >= 88:
		return 3  # 传奇
	elif rating >= 83:
		return 2  # 史诗
	elif rating >= 75:
		return 1  # 稀有
	else:
		return 0  # 普通

## 获取可兑换的球员列表（按联赛分类）
func get_exchangeable_players(league_id: String) -> Array:
	var result = []
	for pid in PlayerDatabase.players_data:
		var player = PlayerDatabase.players_data[pid]
		var club = player.get("club", "")
		var is_national = player.get("is_national", false)

		var player_league = ""
		if is_national:
			player_league = "national"
		else:
			var team = TeamDatabase.get_team(club)
			player_league = team.get("league", "")

		if player_league == league_id:
			var price = get_player_price(pid)
			result.append({
				"player_id": pid,
				"name": player.get("name", pid),
				"position": PlayerDatabase.get_player_primary_position(pid),
				"rating": price.rating,
				"league_price": price.league_price,
				"universal_price": price.universal_price,
				"era": player.get("era", ""),
				"jersey_number": player.get("jersey_number", 0),
			})

	# 按评分排序
	result.sort_custom(func(a, b): return a.rating > b.rating)
	return result

## 保存状态
func save_state():
	var data = {
		"league_currencies": {},
		"universal_coins": universal_coins,
	}
	for lid in league_currencies:
		data.league_currencies[lid] = league_currencies[lid].amount
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.close()

## 加载状态
func load_state():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			universal_coins = json.data.get("universal_coins", 5000)
			var saved = json.data.get("league_currencies", {})
			for lid in saved:
				if league_currencies.has(lid):
					league_currencies[lid].amount = saved[lid]
		file.close()
