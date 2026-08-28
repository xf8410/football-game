## youth_academy.gd
## 青训系统 (Autoload Singleton)
## 功能：培养年轻球员、青训营升级、球探搜索
extends Node

signal youth_player_generated(player_data: Dictionary)
signal youth_player_promoted(player_id: String)

# 青训营数据
var academy_data: Dictionary = {
	"level": 1,                    # 青训营等级（1-10）
	"max_slots": 5,                # 最大青训名额
	"youth_players": [],           # 青训球员列表
	"scout_level": 1,              # 球探等级
	"upgrade_cost": 2000,          # 升级费用
}

# 青训球员生成参数
const YOUTH_NAMES_FIRST = ["张", "李", "王", "刘", "陈", "杨", "赵", "黄", "周", "吴",
							"James", "John", "Michael", "David", "Robert", "Thomas",
							"Carlos", "Diego", "Marco", "Luca", "Antonio", "Pablo"]
const YOUTH_NAMES_LAST = ["伟", "强", "磊", "洋", "勇", "军", "杰", "涛", "明", "超",
						  "Smith", "Johnson", "Brown", "Taylor", "Anderson",
						  "Garcia", "Rodriguez", "Silva", "Rossi", "Ferrari"]
const YOUTH_NATIONALITIES = ["中国", "英格兰", "西班牙", "德国", "法国", "巴西", "阿根廷", "葡萄牙", "意大利", "荷兰"]
const YOUTH_POSITIONS = ["GK", "CB", "LB", "RB", "CDM", "CM", "CAM", "LW", "RW", "ST"]

## 升级青训营
func upgrade_academy() -> bool:
	var cost = academy_data.upgrade_cost
	if TransferMarket.get_budget() < cost:
		print("[Academy] 升级青训营需要 %d 金币" % cost)
		return false

	TransferMarket.add_budget(-cost)
	academy_data.level += 1
	academy_data.max_slots = 5 + academy_data.level
	academy_data.upgrade_cost = int(academy_data.upgrade_cost * 1.5)
	print("[Academy] 青训营升级到 %d 级" % academy_data.level)
	return true

## 搜索青训球员（花费金币）
func scout_youth_player() -> Dictionary:
	var scout_cost = 500 * academy_data.scout_level
	if TransferMarket.get_budget() < scout_cost:
		print("[Academy] 球探需要 %d 金币" % scout_cost)
		return {}

	TransferMarket.add_budget(-scout_cost)

	# 生成青训球员
	var player = _generate_youth_player()
	academy_data.youth_players.append(player)
	youth_player_generated.emit(player)
	print("[Academy] 发现青训球员: %s (%d岁, %s)" % [player.name, player.age, player.position])
	return player

## 生成青训球员
func _generate_youth_player() -> Dictionary:
	var first_name = YOUTH_NAMES_FIRST.pick_random()
	var last_name = YOUTH_NAMES_LAST.pick_random()
	var name = first_name + last_name if first_name.length() <= 2 else first_name + " " + last_name
	var nationality = YOUTH_NATIONALITIES.pick_random()
	var position = YOUTH_POSITIONS.pick_random()
	var age = randi_range(15, 18)

	# 根据青训营等级决定潜力
	var potential_base = 60 + academy_data.level * 3
	var potential = potential_base + randi_range(-5, 15)

	# 初始属性（较低）
	var base_attrs = _generate_base_attributes(position, potential)

	# 生成唯一ID
	var player_id = "youth_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

	return {
		"player_id": player_id,
		"name": name,
		"nationality": nationality,
		"position": position,
		"age": age,
		"potential": potential,
		"current_rating": int(potential * 0.7),
		"attributes": base_attrs,
		"training_progress": 0,
		"weeks_trained": 0,
		"traits": [],
		"skills": [],
	}

## 生成基础属性
func _generate_base_attributes(position: String, potential: int) -> Dictionary:
	var base = potential * 0.7
	var variation = 10

	match position:
		"GK":
			return {
				"gk_diving": int(base + randf_range(-variation, variation)),
				"gk_handling": int(base + randf_range(-variation, variation)),
				"gk_kicking": int(base + randf_range(-variation, variation)),
				"gk_reflexes": int(base + randf_range(-variation, variation)),
				"gk_positioning": int(base + randf_range(-variation, variation)),
			}
		"CB":
			return {"pace": int(base-5), "shooting": int(base-15), "passing": int(base-5), "dribbling": int(base-5), "defending": int(base+10), "physical": int(base+5)}
		"LB", "RB":
			return {"pace": int(base+5), "shooting": int(base-10), "passing": int(base), "dribbling": int(base), "defending": int(base+5), "physical": int(base)}
		"CDM":
			return {"pace": int(base-5), "shooting": int(base-5), "passing": int(base+5), "dribbling": int(base), "defending": int(base+10), "physical": int(base+5)}
		"CM":
			return {"pace": int(base), "shooting": int(base), "passing": int(base+10), "dribbling": int(base+5), "defending": int(base), "physical": int(base)}
		"CAM":
			return {"pace": int(base+5), "shooting": int(base+5), "passing": int(base+10), "dribbling": int(base+10), "defending": int(base-10), "physical": int(base-5)}
		"LW", "RW":
			return {"pace": int(base+15), "shooting": int(base+5), "passing": int(base), "dribbling": int(base+10), "defending": int(base-15), "physical": int(base-5)}
		"ST":
			return {"pace": int(base+5), "shooting": int(base+15), "passing": int(base-5), "dribbling": int(base+5), "defending": int(base-15), "physical": int(base+5)}
		_:
			return {"pace": int(base), "shooting": int(base), "passing": int(base), "dribbling": int(base), "defending": int(base), "physical": int(base)}

## 训练青训球员（每周调用）
func train_youth_players():
	for player in academy_data.youth_players:
		# 每周训练进度+10
		player.training_progress += 10
		player.weeks_trained += 1

		# 训练进度满100时提升属性
		if player.training_progress >= 100:
			player.training_progress = 0
			_improve_player_attributes(player)
			player.current_rating = _calculate_rating(player)

		# 年龄增长（每4周+1岁）
		if player.weeks_trained % 4 == 0:
			player.age += 1

	print("[Academy] 青训球员训练完成")

## 提升球员属性
func _improve_player_attributes(player: Dictionary):
	var growth = randi_range(1, 3)
	var attrs = player.attributes
	if attrs.has("pace"):
		for key in attrs:
			if randf() < 0.5:
				attrs[key] += growth
	else:
		# 门将属性
		for key in attrs:
			if randf() < 0.5:
				attrs[key] += growth

	# 随机解锁特性/技能
	if randf() < 0.1 and player.traits.size() < 3:
		var all_traits = TeamSpecialties.get_all_traits().keys()
		player.traits.append(all_traits.pick_random())

## 计算球员评分
func _calculate_rating(player: Dictionary) -> int:
	var attrs = player.attributes
	if attrs.has("pace"):
		return int((attrs.pace + attrs.shooting + attrs.passing + attrs.dribbling + attrs.defending + attrs.physical) / 6.0)
	else:
		return int((attrs.gk_diving + attrs.gk_handling + attrs.gk_kicking + attrs.gk_reflexes + attrs.gk_positioning) / 5.0)

## 提拔青训球员到一线队
func promote_youth_player(player_id: String) -> bool:
	for i in range(academy_data.youth_players.size()):
		if academy_data.youth_players[i].player_id == player_id:
			var player = academy_data.youth_players[i]
			# 添加到球员数据库
			PlayerDatabase.players_data[player_id] = {
				"name": player.name,
				"short_name": player.name,
				"nationality": player.nationality,
				"positions": [player.position],
				"preferred_foot": "right",
				"attributes": player.attributes,
				"traits": player.traits,
				"skills": player.skills,
				"career": [{"club": "youth", "years": "青训"}],
			}
			# 添加到玩家拥有的球员
			TransferMarket.owned_players.append(player_id)
			# 从青训营移除
			academy_data.youth_players.remove_at(i)
			youth_player_promoted.emit(player_id)
			print("[Academy] 提拔青训球员: %s (评分%d)" % [player.name, player.current_rating])
			return true
	return false

## 释放青训球员
func release_youth_player(player_id: String):
	for i in range(academy_data.youth_players.size()):
		if academy_data.youth_players[i].player_id == player_id:
			academy_data.youth_players.remove_at(i)
			print("[Academy] 释放青训球员: %s" % player_id)
			return

## 获取青训营数据
func get_academy_data() -> Dictionary:
	return academy_data

## 获取青训球员列表
func get_youth_players() -> Array:
	return academy_data.youth_players

## 保存/加载
func save_state():
	var file = FileAccess.open("user://youth_academy.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(academy_data, "  "))
		file.close()

func load_state():
	var file = FileAccess.open("user://youth_academy.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			academy_data = json.data
		file.close()
