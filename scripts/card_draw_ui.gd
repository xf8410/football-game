## card_draw_ui.gd
## 抽卡界面
extends Control

@onready var packs_container = $VBox/ScrollContainer/PacksVBox
@onready var result_label = $VBox/ResultLabel
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	_populate_packs()

func _populate_packs():
	for child in packs_container.get_children():
		child.queue_free()

	var packs = CardDrawSystem.get_all_packs()
	for pack_id in packs:
		var pack = packs[pack_id]
		var btn = Button.new()
		btn.text = "%s  (%d金币)  - %d张卡" % [pack.name, pack.cost, pack.cards]
		btn.custom_minimum_size = Vector2(0, 60)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(func(): _open_pack(pack_id))
		packs_container.add_child(btn)

func _open_pack(pack_id: String):
	var pack = CardDrawSystem.get_pack(pack_id)
	if pack.is_empty():
		return

	if TransferMarket.get_budget() < pack.cost:
		result_label.text = "❌ 金币不足！\n需要 %d 金币" % pack.cost
		return

	# 扣除金币
	TransferMarket.add_budget(-pack.cost)

	# 开包
	var results = CardDrawSystem.open_pack(pack_id)

	# 显示结果
	var text = "🎉 %s 开包结果：\n\n" % pack.name
	for i in range(results.size()):
		var card = results[i]
		var rarity_name = CardDrawSystem.get_rarity_name(card.rarity)
		var rarity_color = CardDrawSystem.get_rarity_color(card.rarity)
		text += "%d. [%s] %s  评分:%d\n" % [i + 1, rarity_name, card.name, card.rating]
	result_label.text = text
	result_label.modulate = Color(1, 0.9, 0.5)

	# 保存
	TransferMarket.save_state()
