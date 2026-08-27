## transfer_market.gd
## 转会市场系统 (Autoload Singleton)
## 功能：球员买卖、薪资、合同、转会费计算
##
## 经济系统：
##   - 玩家拥有金币（初始500）
##   - 每场比赛获得奖金（胜3000/平1000/负500）
##   - 球员有转会费和周薪
##   - 球员有合同期（周数）
extends Node

signal player_purchased(player_id: String, price: int)
signal player_sold(player_id: String, price: int)
signal market_refreshed()

# 转会市场数据
var market_players: Array = []  # 当前市场上的球员
var owned_players: Array = []   # 玩家拥有的球员
var player_budget: int = 5000   # 玩家预算

# 市场刷新周期
const MARKET_SIZE = 20          # 每次刷新20名球员
const REFRESH_COST = 500        # 刷新市场花费

## 初始化市场
func _ready():
	_refresh_market()

## 刷新转会市场
func _refresh_market():
	market_players.clear()
	var all_players = PlayerDatabase.players_data.keys()
	all_players.shuffle()

	for pid in all_players.slice(0, MARKET_SIZE):
		var player = PlayerDatabase.get_player(pid)
		if player.is_empty():
			continue
		var price = _calculate_price(pid)
		market_players.append({
			"player_id": pid,
			"name": player.get("name", pid),
			"position": PlayerDatabase.get_player_primary_position(pid),
			"rating": PlayerDatabase.get_player_rating(pid),
			"price": price,
			"weekly_wage": int(price * 0.02),  # 周薪 = 转会费×2%
			"contract_weeks": randi_range(12, 52),  # 合同12-52周
			"age": randi_range(18, 35),
		})

	market_refreshed.emit()
	print("[Market] 市场已刷新，%d名球员可购买" % market_players.size())

## 计算球员转会费
func _calculate_price(player_id: String) -> int:
	var rating = PlayerDatabase.get_player_rating(player_id)
	# 评分越高价格越高（指数增长）
	var base_price = pow(rating - 60, 2) * 100
	if base_price < 100:
		base_price = 100
	return int(base_price)

## 购买球员
func purchase_player(player_id: String) -> bool:
	# 查找市场球员
	var market_player = null
	for p in market_players:
		if p.player_id == player_id:
			market_player = p
			break

	if market_player == null:
		print("[Market] 球员不在市场上")
		return false

	if player_budget < market_player.price:
		print("[Market] 金币不足，需要 %d，拥有 %d" % [market_player.price, player_budget])
		return false

	# 扣款
	player_budget -= market_player.price
	owned_players.append(player_id)

	# 从市场移除
	market_players.erase(market_player)

	player_purchased.emit(player_id, market_player.price)
	print("[Market] 购买成功: %s (花费 %d)" % [market_player.name, market_player.price])
	return true

## 出售球员
func sell_player(player_id: String) -> bool:
	var idx = owned_players.find(player_id)
	if idx == -1:
		print("[Market] 你没有这名球员")
		return false

	var price = int(_calculate_price(player_id) * 0.7)  # 出售价为购买价的70%
	player_budget += price
	owned_players.remove_at(idx)

	player_sold.emit(player_id, price)
	print("[Market] 出售成功: %s (获得 %d)" % [PlayerDatabase.get_player_name(player_id), price])
	return true

## 手动刷新市场（花费金币）
func refresh_market_manual() -> bool:
	if player_budget < REFRESH_COST:
		print("[Market] 刷新市场需要 %d 金币" % REFRESH_COST)
		return false
	player_budget -= REFRESH_COST
	_refresh_market()
	return true

## 获取市场球员列表
func get_market_players() -> Array:
	return market_players

## 获取已拥有球员列表
func get_owned_players() -> Array:
	return owned_players

## 获取预算
func get_budget() -> int:
	return player_budget

## 增加预算（比赛奖金）
func add_budget(amount: int):
	player_budget += amount
	print("[Market] 获得金币: +%d (总计: %d)" % [amount, player_budget])

## 保存/加载
func save_state():
	var data = {
		"budget": player_budget,
		"owned_players": owned_players,
	}
	var file = FileAccess.open("user://transfer_market.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.close()

func load_state():
	var file = FileAccess.open("user://transfer_market.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			player_budget = json.data.get("budget", 5000)
			owned_players = json.data.get("owned_players", [])
		file.close()
