## transfer_market_ui.gd
## 转会市场界面
## 左侧：市场球员列表（可购买）
## 右侧：我的球员列表（可出售）+ 预算 + 刷新按钮
extends Control

@onready var market_list = $HBox/MarketPanel/ScrollContainer/MarketList
@onready var owned_list = $HBox/OwnedPanel/ScrollContainer/OwnedList
@onready var budget_label = $HBox/OwnedPanel/BudgetLabel
@onready var refresh_button = $HBox/OwnedPanel/RefreshButton
@onready var back_button = $BackButton
@onready var detail_label = $HBox/DetailPanel/DetailLabel

func _ready():
	back_button.pressed.connect(func():
		TransferMarket.save_state()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	refresh_button.pressed.connect(_on_refresh)
	TransferMarket.load_state()
	_update_ui()

func _update_ui():
	_update_market()
	_update_owned()
	budget_label.text = "💰 预算: %d 金币" % TransferMarket.get_budget()

func _update_market():
	for child in market_list.get_children():
		child.queue_free()

	var players = TransferMarket.get_market_players()
	# 按评分排序
	players.sort_custom(func(a, b): return a.rating > b.rating)

	for p in players:
		var btn = Button.new()
		btn.text = "%s  %s  %d  💰%d" % [
			p.name, p.position, p.rating, p.price
		]
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(func(): _on_buy_player(p))
		market_list.add_child(btn)

func _update_owned():
	for child in owned_list.get_children():
		child.queue_free()

	var owned = TransferMarket.get_owned_players()
	if owned.is_empty():
		var label = Label.new()
		label.text = "暂无球员\n去市场购买球员吧！"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owned_list.add_child(label)
		return

	for pid in owned:
		var player = PlayerDatabase.get_player(pid)
		if player.is_empty():
			continue
		var rating = PlayerDatabase.get_player_rating(pid)
		var sell_price = int(pow(rating - 60, 2) * 100 * 0.7)
		var btn = Button.new()
		btn.text = "%s  %s  %d  出售💰%d" % [
			player.get("name", pid),
			PlayerDatabase.get_player_primary_position(pid),
			rating,
			sell_price
		]
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(func(): _on_sell_player(pid))
		owned_list.add_child(btn)

func _on_buy_player(market_player: Dictionary):
	var success = TransferMarket.purchase_player(market_player.player_id)
	if success:
		_update_ui()
		detail_label.text = "✅ 购买成功！\n\n%s (%s)\n评分: %d\n花费: %d 金币\n周薪: %d\n合同: %d周" % [
			market_player.name, market_player.position, market_player.rating,
			market_player.price, market_player.weekly_wage, market_player.contract_weeks
		]
	else:
		detail_label.text = "❌ 购买失败！\n\n金币不足或球员不可购买"

func _on_sell_player(player_id: String):
	var success = TransferMarket.sell_player(player_id)
	if success:
		_update_ui()
		detail_label.text = "✅ 出售成功！\n\n%s\n获得转会费" % PlayerDatabase.get_player_name(player_id)
	else:
		detail_label.text = "❌ 出售失败！"

func _on_refresh():
	if TransferMarket.refresh_market_manual():
		_update_ui()
		detail_label.text = "✅ 市场已刷新！\n\n花费 %d 金币" % TransferMarket.REFRESH_COST
	else:
		detail_label.text = "❌ 刷新失败！\n\n需要 %d 金币" % TransferMarket.REFRESH_COST
