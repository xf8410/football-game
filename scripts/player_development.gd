## player_development.gd
## 球员成长系统 (Autoload Singleton)
## 管理：球员等级、经验、属性升级、特性升级、技能解锁
extends Node

# 球员成长数据：player_id -> development_data
var development_data: Dictionary = {}

const MAX_LEVEL = 50
const MAX_TRAIT_LEVEL = 3  # 铜→银→金

## 获取球员成长数据
func get_development(player_id: String) -> Dictionary:
	if not development_data.has(player_id):
		development_data[player_id] = _create_default_development(player_id)
	return development_data[player_id]

## 创建默认成长数据
func _create_default_development(player_id: String) -> Dictionary:
	var player = PlayerDatabase.get_player(player_id)
	var traits = player.get("traits", [])
	var skills = player.get("skills", [])

	# 初始化特性（默认铜级）
	var trait_levels = {}
	for trait_id in traits:
		trait_levels[trait_id] = "bronze"

	# 初始化技能（默认锁定）
	var skill_unlocked = {}
	for skill_id in skills:
		skill_unlocked[skill_id] = false

	return {
		"player_id": player_id,
		"level": 1,
		"xp": 0,
		"xp_to_next": _calc_xp_for_level(1),
		"stat_upgrades": {},  # 属性升级点数分配
		"trait_levels": trait_levels,  # 特性等级
		"skill_unlocked": skill_unlocked,  # 技能解锁状态
		"skill_cooldowns": {},  # 技能冷却时间
		"matches_played": 0,
		"goals_scored": 0,
		"assists": 0,
	}

## 计算升级所需经验
func _calc_xp_for_level(level: int) -> int:
	return int(100 * pow(1.15, level - 1))

## 获取球员当前总评分（含升级加成）
func get_player_rating_with_dev(player_id: String) -> int:
	var base_rating = PlayerDatabase.get_player_rating(player_id)
	var dev = get_development(player_id)
	var level_bonus = (dev.level - 1) * 2
	var stat_bonus = 0
	for stat in dev.stat_upgrades:
		stat_bonus += dev.stat_upgrades[stat]
	return min(99, base_rating + level_bonus + stat_bonus)

## 获取球员当前属性（含升级加成）
func get_attributes_with_dev(player_id: String) -> Dictionary:
	var base_attrs = PlayerDatabase.get_player_attributes(player_id)
	var dev = get_development(player_id)

	var result = base_attrs.duplicate()
	for stat in dev.stat_upgrades:
		if result.has(stat):
			result[stat] = min(99, result[stat] + dev.stat_upgrades[stat])
		else:
			result[stat] = dev.stat_upgrades[stat]

	# 等级加成（每级+1全属性）
	var level_bonus = dev.level - 1
	for stat in result:
		result[stat] = min(99, result[stat] + level_bonus)

	return result

## 获取特性buff（含等级）
func get_trait_buffs(player_id: String) -> Dictionary:
	var dev = get_development(player_id)
	var buffs = {}
	for trait_id in dev.trait_levels:
		var tier = dev.trait_levels[trait_id]
		var buff = TeamSpecialties.get_trait_buff(trait_id, tier)
		if not buff.is_empty():
			buffs[trait_id] = buff
	return buffs

## 添加经验
func add_xp(player_id: String, amount: int) -> bool:
	var dev = get_development(player_id)
	dev.xp += amount
	var leveled_up = false

	while dev.xp >= dev.xp_to_next and dev.level < MAX_LEVEL:
		dev.xp -= dev.xp_to_next
		dev.level += 1
		dev.xp_to_next = _calc_xp_for_level(dev.level)
		leveled_up = true
		print("[Dev] %s 升级到 %d 级!" % [PlayerDatabase.get_player_name(player_id), dev.level])

	return leveled_up

## 升级属性
func upgrade_stat(player_id: String, stat: String) -> bool:
	var dev = get_development(player_id)
	# 每级获得1个属性点
	var total_points = dev.level - 1
	var used_points = 0
	for s in dev.stat_upgrades:
		used_points += dev.stat_upgrades[s]

	if used_points >= total_points:
		return false  # 没有可用点数

	if not dev.stat_upgrades.has(stat):
		dev.stat_upgrades[stat] = 0

	# 检查属性上限
	var current = get_attributes_with_dev(player_id).get(stat, 0)
	if current >= 99:
		return false

	dev.stat_upgrades[stat] += 1
	print("[Dev] %s 的 %s 提升到 %d" % [PlayerDatabase.get_player_name(player_id), stat, dev.stat_upgrades[stat]])
	return true

## 升级特性（铜→银→金）
func upgrade_trait(player_id: String, trait_id: String) -> bool:
	var dev = get_development(player_id)
	if not dev.trait_levels.has(trait_id):
		return false

	var current_tier = dev.trait_levels[trait_id]
	var next_tier = ""
	match current_tier:
		"bronze": next_tier = "silver"
		"silver": next_tier = "gold"
		"gold": return false  # 已满级

	# 检查等级要求
	var required_level = {"bronze": 1, "silver": 10, "gold": 25}
	if dev.level < required_level.get(current_tier, 1):
		print("[Dev] 等级不足，需要 %d 级" % required_level[current_tier])
		return false

	dev.trait_levels[trait_id] = next_tier
	print("[Dev] %s 的特性 %s 升级到 %s" % [
		PlayerDatabase.get_player_name(player_id), trait_id, next_tier
	])
	return true

## 解锁技能
func unlock_skill(player_id: String, skill_id: String) -> bool:
	var dev = get_development(player_id)
	if not dev.skill_unlocked.has(skill_id):
		dev.skill_unlocked[skill_id] = true
		print("[Dev] %s 解锁技能: %s" % [PlayerDatabase.get_player_name(player_id), skill_id])
		return true
	return false

## 检查技能是否可用（已解锁且冷却结束）
func is_skill_ready(player_id: String, skill_id: String) -> bool:
	var dev = get_development(player_id)
	if not dev.skill_unlocked.get(skill_id, false):
		return false
	var cooldown = dev.skill_cooldowns.get(skill_id, 0.0)
	return cooldown <= 0

## 设置技能冷却
func set_skill_cooldown(player_id: String, skill_id: String, time: float):
	var dev = get_development(player_id)
	dev.skill_cooldowns[skill_id] = time

## 更新技能冷却
func update_cooldowns(delta: float):
	for pid in development_data:
		var dev = development_data[pid]
		for skill_id in dev.skill_cooldowns:
			if dev.skill_cooldowns[skill_id] > 0:
				dev.skill_cooldowns[skill_id] -= delta

## 记录比赛数据
func record_match(player_id: String, goals: int, assists: int):
	var dev = get_development(player_id)
	dev.matches_played += 1
	dev.goals_scored += goals
	dev.assists += assists

	# 根据表现给经验
	var xp = 50  # 基础经验
	xp += goals * 100
	xp += assists * 50
	add_xp(player_id, xp)

## 获取球员拥有的特性数量
func get_trait_count(player_id: String) -> int:
	var dev = get_development(player_id)
	return dev.trait_levels.size()

## 获取球员特性列表（含等级）
func get_traits(player_id: String) -> Dictionary:
	var dev = get_development(player_id)
	return dev.trait_levels

## 获取球员技能列表（含解锁状态）
func get_skills(player_id: String) -> Dictionary:
	var dev = get_development(player_id)
	return dev.skill_unlocked

## 保存成长数据
func save_development():
	var file = FileAccess.open("user://player_development.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(development_data, "  "))
		file.close()

## 加载成长数据
func load_development():
	var file = FileAccess.open("user://player_development.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			development_data = json.data
		file.close()
	print("[Dev] 已加载 %d 名球员的成长数据" % development_data.size())
