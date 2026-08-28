## team_specialties.gd
## 球队特性系统 (Autoload Singleton)
## 参考《FC足球世界》/《最佳球会》的球队特性界面
##
## 4大分类：
##   1. 俱乐部 (Club) - 同俱乐部球员数量激活buff
##   2. 国家 (National) - 同国籍球员数量激活buff
##   3. 联赛 (League) - 同联赛球员数量激活buff
##   4. 球员主题 (Player Theme) - 年度之星/欧战之星/世界杯等
##
## 宿敌系统 (Rivalry)：
##   对阵宿敌球队时，全队属性获得额外加成
##   例如：曼城 vs 曼联 → 双方所有球员+5全属性
extends Node

signal specialty_activated(category: String, item_id: String, buff: Dictionary)
signal rivalry_triggered(rivalry_id: String, team_a: String, team_b: String)

# 特性分类
enum Category {
	CLUB,         # 俱乐部
	NATIONAL,     # 国家
	LEAGUE,       # 联赛
	PLAYER_THEME  # 球员主题
}

# 当前激活的特性
var active_specialties: Dictionary = {
	Category.CLUB: "",
	Category.NATIONAL: "",
	Category.LEAGUE: "",
	Category.PLAYER_THEME: "",
}

# 特性数据
var traits_data: Dictionary = {}
var rivalries: Dictionary = {}

# buff阶梯（根据人数激活不同等级）
const BUFF_TIERS = [
	{"min_players": 3, "buff": {"all_stats": 1}, "stars": 1},
	{"min_players": 5, "buff": {"all_stats": 2}, "stars": 2},
	{"min_players": 7, "buff": {"all_stats": 3}, "stars": 3},
	{"min_players": 9, "buff": {"all_stats": 4}, "stars": 4},
	{"min_players": 11, "buff": {"all_stats": 5}, "stars": 5},
]

func _ready():
	_load_data()

func _load_data():
	var file = FileAccess.open("res://data/traits.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			traits_data = json.data
			rivalries = traits_data.get("rivalries", {})
		file.close()
	print("[Specialties] 已加载 %d 个特性, %d 个宿敌关系" % [
		traits_data.get("traits", {}).size(), rivalries.size()
	])

## 获取当前阵容中各分类的球员统计
func analyze_squad(squad_player_ids: Array) -> Dictionary:
	var result = {
		Category.CLUB: {},
		Category.NATIONAL: {},
		Category.LEAGUE: {},
		Category.PLAYER_THEME: {},
	}

	for pid in squad_player_ids:
		var player = PlayerDatabase.get_player(pid)
		if player.is_empty():
			continue

		# 俱乐部统计
		var club = player.get("current_club", "")
		if club != "":
			result[Category.CLUB][club] = result[Category.CLUB].get(club, 0) + 1

		# 国家统计
		var nation = player.get("nationality", "")
		if nation != "":
			result[Category.NATIONAL][nation] = result[Category.NATIONAL].get(nation, 0) + 1

		# 联赛统计
		var league = player.get("league", "")
		if league != "":
			result[Category.LEAGUE][league] = result[Category.LEAGUE].get(league, 0) + 1

		# 主题统计
		var themes = player.get("themes", [])
		for theme in themes:
			result[Category.PLAYER_THEME][theme] = result[Category.PLAYER_THEME].get(theme, 0) + 1

	return result

## 获取某项特性的buff（根据球员数量）
func get_specialty_buff(category: int, item_id: String, player_count: int) -> Dictionary:
	var buff = {"all_stats": 0, "stars": 0}
	for tier in BUFF_TIERS:
		if player_count >= tier.min_players:
			buff = {"all_stats": tier.buff.all_stats, "stars": tier.stars}
		else:
			break

	# 球员主题有额外buff
	if category == Category.PLAYER_THEME:
		var theme = traits_data.get("player_themes", {}).get(item_id, {})
		if not theme.is_empty() and player_count >= 3:
			var theme_buff = theme.get("buff", {})
			buff.all_stats += theme_buff.get("all_stats", 0)

	return buff

## 激活特性
func activate_specialty(category: int, item_id: String):
	active_specialties[category] = item_id
	print("[Specialties] 激活特性: 类别%d, 项目: %s" % [category, item_id])

## 获取当前激活的所有buff
func get_active_buffs(squad_player_ids: Array) -> Dictionary:
	var total_buff = {"all_stats": 0, "details": []}
	var analysis = analyze_squad(squad_player_ids)

	for category in active_specialties:
		var item_id = active_specialties[category]
		if item_id == "":
			continue
		var count = analysis.get(category, {}).get(item_id, 0)
		if count >= 3:
			var buff = get_specialty_buff(category, item_id, count)
			total_buff.all_stats += buff.all_stats
			total_buff.details.append({
				"category": category,
				"item_id": item_id,
				"count": count,
				"buff": buff,
			})

	return total_buff

## 检查宿敌关系
func check_rivalry(team_a: String, team_b: String) -> Dictionary:
	for rid in rivalries:
		var r = rivalries[rid]
		if (r.team_a == team_a and r.team_b == team_b) or \
		   (r.team_a == team_b and r.team_b == team_a):
			return {"id": rid, "name": r.name, "buff": r.buff}
	return {}

## 获取宿敌列表
func get_rivals(team_id: String) -> Array:
	var rivals = []
	for rid in rivalries:
		var r = rivalries[rid]
		if r.team_a == team_id:
			rivals.append(r.team_b)
		elif r.team_b == team_id:
			rivals.append(r.team_a)
	return rivals

## 获取所有特性
func get_all_traits() -> Dictionary:
	return traits_data.get("traits", {})

## 获取所有技能
func get_all_skills() -> Dictionary:
	return traits_data.get("skills", {})

## 获取所有球员主题
func get_all_themes() -> Dictionary:
	return traits_data.get("player_themes", {})

## 获取特性信息
func get_trait(trait_id: String) -> Dictionary:
	return traits_data.get("traits", {}).get(trait_id, {})

## 获取技能信息
func get_skill(skill_id: String) -> Dictionary:
	return traits_data.get("skills", {}).get(skill_id, {})

## 获取特性buff（根据等级）
func get_trait_buff(trait_id: String, tier: String) -> Dictionary:
	var trait = get_trait(trait_id)
	if trait.is_empty():
		return {}
	return trait.get("tiers", {}).get(tier, {})

## 分类名称
func get_category_name(category: int) -> String:
	match category:
		Category.CLUB: return "俱乐部"
		Category.NATIONAL: return "国家"
		Category.LEAGUE: return "联赛"
		Category.PLAYER_THEME: return "球员主题"
		_: return "未知"

## 等级名称
func get_tier_name(tier: String) -> String:
	match tier:
		"bronze": return "铜"
		"silver": return "银"
		"gold": return "金"
		_: return tier

## 等级颜色
func get_tier_color(tier: String) -> Color:
	match tier:
		"bronze": return Color(0.8, 0.5, 0.2)
		"silver": return Color(0.8, 0.8, 0.85)
		"gold": return Color(1.0, 0.84, 0.0)
		_: return Color.WHITE
