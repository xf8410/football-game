## card_trade_ui.gd
## 卡牌交易界面
extends Control

@onready var offers_container = $VBox/ScrollContainer/OffersVBox
@onready var refresh_button = $VBox/RefreshButton
@onready var budget_label = $VBox/BudgetLabel
@onready var back_button = $BackButton
@onready var result_label = $VBox/ResultLabel

func _ready():
	back_button.pressed.connect(func():
		TransferMarket.save_state()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	refresh_button.pressed.connect(_on_refresh)
	_update_ui()

func _on_refresh():
	CardTradeSystem.generate_trade_offers(5)
	_update_ui()

func _update_ui():
	budget_label.text = "💰 预算: %d 金币" % TransferMarket.get_budget()

	for child in offers_container.get_children():
		child.queue_free()

	var offers = CardTradeSystem.get_trade_offers()
	if offers.is_empty():
		CardTradeSystem.generate_trade_offers(5)
		offers = CardTradeSystem.get_trade_offers()

	for i in range(offers.size()):
		var trade = offers[i]
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(0, 100)

		var vbox = VBoxContainer.new()
		vbox.position = Vector2(10, 5)
		vbox.size = Vector2(540, 90)

		var offer_name = PlayerDatabase.get_player_name(trade.ai_offer)
		var offer_rating = trade.offer_rating
		var want_name = PlayerDatabase.get_player_name(trade.ai_want) if not trade.ai_want.is_empty() else "无"
		var want_rating = trade.want_rating

		var title = Label.new()
		title.text = "🤝 交易 #%d" % (i + 1)
		title.add_theme_font_size_override("font_size", 14)
		vbox.add_child(title)

		var detail = Label.new()
		var coin_text = ""
		if trade.coin_compensation > 0:
			coin_text = " (你付%d金币)" % trade.coin_compensation
		elif trade.coin_compensation < 0:
			coin_text = " (AI付%d金币)" % abs(trade.coin_compensation)
		detail.text = "AI提供: %s (%d)  ←→  你给: %s (%d)%s" % [
			offer_name, offer_rating, want_name, want_rating, coin_text
		]
		detail.add_theme_font_size_override("font_size", 13)
		vbox.add_child(detail)

		var eval_label = Label.new()
		eval_label.text = "评估: " + CardTradeSystem.evaluate_trade(i)
		eval_label.add_theme_font_size_override("font_size", 12)
		eval_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
		vbox.add_child(eval_label)

		var accept_btn = Button.new()
		accept_btn.text = "接受交易"
		accept_btn.add_theme_font_size_override("font_size", 13)
		accept_btn.pressed.connect(func(): _accept_trade(i))
		vbox.add_child(accept_btn)

		panel.add_child(vbox)
		offers_container.add_child(panel)

func _accept_trade(index: int):
	if CardTradeSystem.execute_trade(index):
		result_label.text = "✅ 交易成功！"
		result_label.modulate = Color(0.3, 1.0, 0.3)
		TransferMarket.save_state()
	else:
		result_label.text = "❌ 交易失败！金币不足或没有该球员"
		result_label.modulate = Color(1.0, 0.3, 0.3)
	_update_ui()
