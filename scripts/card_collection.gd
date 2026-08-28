## card_collection.gd
## 球员卡牌图鉴系统 (Autoload Singleton)
## 功能：收集球员卡、查看图鉴、收集进度、稀有度统计
extends Node

signal card_collected(player_id: String, rarity: int)
signal collection_updated()

# 收集数据
var collection_data: Dictionary = {
	"collected": {},           # player_id -> {count, first_obtained, best_rarity}
	"total_unique": 0,         # 已收集不同球员数
	"total_cards": 0,          # 总卡数（含重复）
	"by_rarity": {0: 0, 1: 0, 2: 0, 3: 0, 4: 0},  # 各稀有度数量
}

const SAVE_FILE = "user://card_collection.json"

func _ready():
	load_collection()

## 添加卡牌到图鉴
func add_card(player_id: String, rarity: int):
	var is_new = not collection_data.collected.has(player_id)

	if is_new:
		collection_data.collected[player_id] = {
			"count": 1,
			"first_obtained": Time.get_datetime_string_from_system(),
			"best_rarity": rarity,
			"rarity_history": [rarity],
		}
		collection_data.total_unique += 1
		card_collected.emit(player_id, rarity)
		print("[Collection] 新收集: %s (%s)" % [
			PlayerDatabase.get_player_name(player_id),
			CardDrawSystem.get_rarity_name(rarity)
		])
	else:
		var card = collection_data.collected[player_id]
		card.count += 1
		if rarity > card.best_rarity:
			card.best_rarity = rarity
		card.rarity_history.append(rarity)

	collection_data.total_cards += 1
	collection_data.by_rarity[rarity] = collection_data.by_rarity.get(rarity, 0) + 1

	save_collection()
	collection_updated.emit()

## 获取收集进度（0-1）
func get_collection_progress() -> float:
	var total_players = PlayerDatabase.players_data.size()
	if total_players == 0:
		return 0.0
	return float(collection_data.total_unique) / total_players

## 获取已收集球员ID列表
func get_collected_player_ids() -> Array:
	return collection_data.collected.keys()

## 获取球员卡牌信息
func get_card_info(player_id: String) -> Dictionary:
	return collection_data.collected.get(player_id, {})

## 是否已收集
func is_collected(player_id: String) -> bool:
	return collection_data.collected.has(player_id)

## 获取收集统计
func get_stats() -> Dictionary:
	return {
		"total_unique": collection_data.total_unique,
		"total_cards": collection_data.total_cards,
		"total_available": PlayerDatabase.players_data.size(),
		"progress": get_collection_progress(),
		"by_rarity": collection_data.by_rarity,
	}

## 按稀有度筛选已收集球员
func get_collected_by_rarity(rarity: int) -> Array:
	var result = []
	for pid in collection_data.collected:
		var card = collection_data.collected[pid]
		if card.best_rarity == rarity:
			result.append(pid)
	return result

## 获取重复卡牌（可用于分解）
func get_duplicates() -> Array:
	var result = []
	for pid in collection_data.collected:
		var card = collection_data.collected[pid]
		if card.count > 1:
			result.append({"player_id": pid, "duplicates": card.count - 1})
	return result

## 分解重复卡牌获得金币
func decompose_duplicate(player_id: String) -> int:
	if not collection_data.collected.has(player_id):
		return 0
	var card = collection_data.collected[player_id]
	if card.count <= 1:
		return 0

	# 根据稀有度计算分解所得
	var value = 0
	match card.best_rarity:
		0: value = 50    # 普通
		1: value = 200   # 稀有
		2: value = 600   # 史诗
		3: value = 1500  # 传奇
		4: value = 4000  # 时刻

	card.count -= 1
	collection_data.total_cards -= 1
	TransferMarket.add_budget(value)
	save_collection()
	collection_updated.emit()
	print("[Collection] 分解 %s，获得 %d 金币" % [player_id, value])
	return value

## 保存收集数据
func save_collection():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(collection_data, "  "))
		file.close()

## 加载收集数据
func load_collection():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			collection_data = json.data
		file.close()
	print("[Collection] 已加载图鉴: %d/%d 球员" % [
		collection_data.total_unique, PlayerDatabase.players_data.size()
	])
