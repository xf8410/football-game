## card_trade_system.gd
## 球员卡牌交易系统
## 与AI交易不同版本的球员卡
extends Node

signal trade_completed(give: String, receive: String)

# 交易市场
var trade_offers: Array = []

## 生成AI交易报价
func generate_trade_offers(count: int = 5) -> Array:
	trade_offers.clear()
	var all_players = PlayerDatabase.players_data.keys()
	var owned = TransferMarket.get_owned_players()

	for i in range(count):
		# AI提供的球员（随机）
		var ai_offer = all_players[randi() % all_players.size()]
		while owned.has(ai_offer):
			ai_offer = all_players[randi() % all_players.size()]

		# AI想要的球员（从玩家拥有的中选）
		var ai_want = ""
		if owned.size() > 0:
			ai_want = owned[randi() % owned.size()]

		# 计算交易价值差
		var offer_rating = PlayerDatabase.get_player_rating(ai_offer)
		var want_rating = PlayerDatabase.get_player_rating(ai_want) if not ai_want.is_empty() else 0
		var value_diff = offer_rating - want_rating

		# 补差价
		var coin_compensation = 0
		if value_diff < 0:
			# AI提供的评分低，需要玩家补金币
			coin_compensation = abs(value_diff) * 200
		elif value_diff > 0:
			# AI提供的评分高，AI补金币
			coin_compensation = -value_diff * 100

		trade_offers.append({
			"ai_offer": ai_offer,
			"ai_want": ai_want,
			"coin_compensation": coin_compensation,  # 正数=玩家付, 负数=AI付
			"offer_rating": offer_rating,
			"want_rating": want_rating,
		})

	return trade_offers

## 执行交易
func execute_trade(trade_index: int) -> bool:
	if trade_index < 0 or trade_index >= trade_offers.size():
		return false

	var trade = trade_offers[trade_index]
	var ai_offer = trade.ai_offer
	var ai_want = trade.ai_want
	var coins = trade.coin_compensation

	# 检查金币
	if coins > 0 and TransferMarket.get_budget() < coins:
		print("[Trade] 金币不足")
		return false

	# 检查是否拥有要交易的球员
	if not ai_want.is_empty() and not TransferMarket.owned_players.has(ai_want):
		print("[Trade] 你没有这名球员")
		return false

	# 执行交易
	if not ai_want.is_empty():
		TransferMarket.owned_players.erase(ai_want)
	TransferMarket.owned_players.append(ai_offer)

	# 金币
	if coins != 0:
		TransferMarket.add_budget(-coins)

	trade_completed.emit(ai_want, ai_offer)
	print("[Trade] 交易完成: 用 %s 换得 %s" % [
		PlayerDatabase.get_player_name(ai_want) if not ai_want.is_empty() else "无",
		PlayerDatabase.get_player_name(ai_offer)
	])
	return true

## 获取交易报价
func get_trade_offers() -> Array:
	return trade_offers

## 获取交易价值评估
func evaluate_trade(trade_index: int) -> String:
	if trade_index < 0 or trade_index >= trade_offers.size():
		return "无效交易"
	var trade = trade_offers[trade_index]
	var diff = trade.offer_rating - trade.want_rating
	if diff > 5:
		return "划算 ⬆"
	elif diff > 0:
		return "略赚"
	elif diff == 0:
		return "公平"
	elif diff > -5:
		return "略亏"
	else:
		return "亏本 ⬇"
