## card_draw_system.gd
## 球员卡牌抽取系统 (Autoload Singleton)
## 功能：抽卡获得球员、卡包系统、稀有度系统
extends Node

signal card_drawn(player_id: String, rarity: String)
signal pack_opened(pack_id: String, results: Array)

# 稀有度
enum Rarity {
	COMMON,     # 普通（白卡）60%
	RARE,       # 稀有（蓝卡）25%
	EPIC,       # 史诗（紫卡）10%
	LEGENDARY,  # 传奇（金卡）4%
	ICON        # 时刻（彩虹卡）1%
}

# 卡包定义
const PACKS = {
	"bronze_pack": {
		"name": "青铜卡包",
		"cost": 500,
		"cards": 3,
		"rarity_weights": {Rarity.COMMON: 80, Rarity.RARE: 18, Rarity.EPIC: 2, Rarity.LEGENDARY: 0, Rarity.ICON: 0},
	},
	"silver_pack": {
		"name": "白银卡包",
		"cost": 1500,
		"cards": 3,
		"rarity_weights": {Rarity.COMMON: 50, Rarity.RARE: 35, Rarity.EPIC: 12, Rarity.LEGENDARY: 3, Rarity.ICON: 0},
	},
	"gold_pack": {
		"name": "黄金卡包",
		"cost": 3000,
		"cards": 5,
		"rarity_weights": {Rarity.COMMON: 30, Rarity.RARE: 40, Rarity.EPIC: 20, Rarity.LEGENDARY: 8, Rarity.ICON: 2},
	},
	"icon_pack": {
		"name": "时刻卡包",
		"cost": 8000,
		"cards": 3,
		"rarity_weights": {Rarity.COMMON: 0, Rarity.RARE: 30, Rarity.EPIC: 40, Rarity.LEGENDARY: 25, Rarity.ICON: 5},
	},
}

# 稀有度对应的评分范围
const RARITY_RATING_RANGE = {
	Rarity.COMMON: [60, 74],
	Rarity.RARE: [75, 82],
	Rarity.EPIC: [83, 87],
	Rarity.LEGENDARY: [88, 92],
	Rarity.ICON: [93, 99],
}

# 稀有度颜色
const RARITY_COLORS = {
	Rarity.COMMON: Color(0.8, 0.8, 0.8),
	Rarity.RARE: Color(0.3, 0.5, 1.0),
	Rarity.EPIC: Color(0.7, 0.3, 0.9),
	Rarity.LEGENDARY: Color(1.0, 0.84, 0.0),
	Rarity.ICON: Color(1.0, 0.4, 0.7),
}

# 稀有度名称
const RARITY_NAMES = {
	Rarity.COMMON: "普通",
	Rarity.RARE: "稀有",
	Rarity.EPIC: "史诗",
	Rarity.LEGENDARY: "传奇",
	Rarity.ICON: "时刻",
}

## 开卡包
func open_pack(pack_id: String) -> Array:
	if not PACKS.has(pack_id):
		return []

	var pack = PACKS[pack_id]
	if TransferMarket.get_budget() < pack.cost:
		print("[CardDraw] 金币不足，需要 %d" % pack.cost)
		return []

	# 扣除金币
	TransferMarket.add_budget(-pack.cost)

	# 抽卡
	var results = []
	for i in range(pack.cards):
		var rarity = _roll_rarity(pack.rarity_weights)
		var player_id = _pick_player_by_rarity(rarity)
		if not player_id.is_empty():
			results.append({
				"player_id": player_id,
				"rarity": rarity,
				"rarity_name": RARITY_NAMES[rarity],
				"rating": PlayerDatabase.get_player_rating(player_id),
			})
			card_drawn.emit(player_id, RARITY_NAMES[rarity])

			# 添加到玩家拥有的球员
			if not TransferMarket.owned_players.has(player_id):
				TransferMarket.owned_players.append(player_id)

	pack_opened.emit(pack_id, results)
	print("[CardDraw] 开启 %s，获得 %d 张卡" % [pack.name, results.size()])
	return results

## 按权重随机稀有度
func _roll_rarity(weights: Dictionary) -> int:
	var total = 0
	for w in weights.values():
		total += w
	var roll = randi() % total
	var cumulative = 0
	for rarity in weights:
		cumulative += weights[rarity]
		if roll < cumulative:
			return rarity
	return Rarity.COMMON

## 按稀有度选择球员
func _pick_player_by_rarity(rarity: int) -> String:
	var rating_range = RARITY_RATING_RANGE[rarity]
	var candidates = []

	for pid in PlayerDatabase.players_data:
		var rating = PlayerDatabase.get_player_rating(pid)
		if rating >= rating_range[0] and rating <= rating_range[1]:
			candidates.append(pid)

	if candidates.is_empty():
		# 降级查找
		for pid in PlayerDatabase.players_data:
			candidates.append(pid)

	if candidates.is_empty():
		return ""

	return candidates[randi() % candidates.size()]

## 获取卡包列表
func get_all_packs() -> Dictionary:
	return PACKS

## 获取卡包信息
func get_pack(pack_id: String) -> Dictionary:
	return PACKS.get(pack_id, {})

## 获取稀有度颜色
func get_rarity_color(rarity: int) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

## 获取稀有度名称
func get_rarity_name(rarity: int) -> String:
	return RARITY_NAMES.get(rarity, "未知")
