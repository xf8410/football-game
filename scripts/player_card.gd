## player_card.gd
## 球员卡片（竖版设计）
## 参考《FC足球世界》/《最佳球会》的竖版球员卡
## 布局：顶部球员模型/头像 → 总评+位置 → 球员名 → 六维属性 → 特性/技能图标
extends Control

var player_id: String = ""
var card_data: Dictionary = {}

@onready var bg = $CardBG
@onready var portrait_bg = $CardBG/PortraitBG
@onready var rating_label = $CardBG/RatingLabel
@onready var position_label = $CardBG/PositionLabel
@onready var name_label = $CardBG/NameLabel
@onready var nation_label = $CardBG/NationLabel
@onready var attrs_container = $CardBG/AttrsContainer
@onready var traits_container = $CardBG/TraitsContainer
@onready var skills_container = $CardBG/SkillsContainer

## 设置球员
func set_player(pid: String):
	player_id = pid
	card_data = PlayerDatabase.get_player(pid)
	if card_data.is_empty():
		return
	_update_display()

func _update_display():
	# 总评
	var rating = PlayerDatabase.get_player_rating(player_id)
	rating_label.text = str(rating)

	# 位置
	var pos = PlayerDatabase.get_player_primary_position(player_id)
	position_label.text = pos

	# 球员名
	name_label.text = card_data.get("name", player_id)

	# 国籍
	nation_label.text = card_data.get("nationality", "")

	# 卡片背景颜色（根据评分分级）
	_set_card_color(rating)

	# 六维属性
	_display_attributes()

	# 特性
	_display_traits()

	# 技能
	_display_skills()

## 设置卡片颜色（根据评分）
func _set_card_color(rating: int):
	var color = Color(0.4, 0.4, 0.4)  # 默认灰色
	if rating >= 90:
		color = Color(0.85, 0.65, 0.0)  # 金色（传奇）
	elif rating >= 85:
		color = Color(0.75, 0.75, 0.8)  # 银色（精英）
	elif rating >= 80:
		color = Color(0.8, 0.5, 0.2)  # 铜色（优秀）
	elif rating >= 75:
		color = Color(0.3, 0.5, 0.8)  # 蓝色（良好）
	else:
		color = Color(0.3, 0.6, 0.3)  # 绿色（普通）

	bg.color = color
	bg.modulate = Color(1, 1, 1, 0.9)

## 显示六维属性
func _display_attributes():
	for child in attrs_container.get_children():
		child.queue_free()

	var attrs = card_data.get("attributes", {})
	var attr_names = {
		"pace": "速度", "shooting": "射门", "passing": "传球",
		"dribbling": "盘带", "defending": "防守", "physical": "身体"
	}

	for attr_key in ["pace", "shooting", "passing", "dribbling", "defending", "physical"]:
		var val = attrs.get(attr_key, 70)
		var row = HBoxContainer.new()

		var name_lbl = Label.new()
		name_lbl.text = attr_names[attr_key]
		name_lbl.custom_minimum_size = Vector2(50, 0)
		name_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(name_lbl)

		# 进度条
		var bar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 99
		bar.value = val
		bar.custom_minimum_size = Vector2(100, 12)
		bar.show_percentage = false
		# 颜色根据值
		if val >= 85:
			bar.modulate = Color(0.2, 0.9, 0.2)
		elif val >= 75:
			bar.modulate = Color(0.9, 0.9, 0.2)
		else:
			bar.modulate = Color(0.9, 0.5, 0.2)
		row.add_child(bar)

		var val_lbl = Label.new()
		val_lbl.text = str(val)
		val_lbl.custom_minimum_size = Vector2(30, 0)
		val_lbl.add_theme_font_size_override("font_size", 12)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(val_lbl)

		attrs_container.add_child(row)

## 显示特性
func _display_traits():
	for child in traits_container.get_children():
		child.queue_free()

	var traits = card_data.get("traits", [])
	if traits.is_empty():
		return

	var title = Label.new()
	title.text = "特性 (%d/3)" % traits.size()
	title.add_theme_font_size_override("font_size", 11)
	traits_container.add_child(title)

	for tid in traits:
		var trait = TeamSpecialties.get_trait(tid)
		var lbl = Label.new()
		lbl.text = "• " + trait.get("name", tid)
		lbl.add_theme_font_size_override("font_size", 10)
		traits_container.add_child(lbl)

## 显示技能
func _display_skills():
	for child in skills_container.get_children():
		child.queue_free()

	var skills = card_data.get("skills", [])
	if skills.is_empty():
		return

	var title = Label.new()
	title.text = "被动技能 (%d)" % skills.size()
	title.add_theme_font_size_override("font_size", 11)
	skills_container.add_child(title)

	for sid in skills:
		var skill = SkillSystem.get_skill_info(sid)
		if skill.is_empty():
			continue
		var lbl = Label.new()
		lbl.text = "• " + skill.get("name", sid)
		lbl.add_theme_font_size_override("font_size", 10)
		# 显示触发情境
		var ctx = SkillSystem.get_context_name(skill.get("trigger", 0))
		lbl.tooltip_text = "%s\n触发: %s\n%s" % [skill.get("name", ""), ctx, skill.get("description", "")]
		skills_container.add_child(lbl)
