## lan_lobby.gd
## 局域网联机大厅
## 功能：创建房间、加入房间、显示房间码和IP
extends Control

@onready var host_button = $VBox/HostSection/HostButton
@onready var room_code_label = $VBox/HostSection/RoomCodeLabel
@onready var ip_label = $VBox/HostSection/IPLabel
@onready var status_label = $VBox/HostSection/StatusLabel

@onready var join_ip_edit = $VBox/JoinSection/JoinIPBox/JoinIPEdit
@onready var join_code_edit = $VBox/JoinSection/JoinCodeBox/JoinCodeEdit
@onready var join_button = $VBox/JoinSection/JoinButton
@onready var join_status = $VBox/JoinSection/JoinStatus

@onready var start_button = $VBox/StartButton
@onready var back_button = $BackButton

func _ready():
	host_button.pressed.connect(_on_host)
	join_button.pressed.connect(_on_join)
	start_button.pressed.connect(_on_start)
	back_button.pressed.connect(func(): 
		NetworkManager.close_connection()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)

	# 连接网络信号
	NetworkManager.connection_succeeded.connect(_on_conn_success)
	NetworkManager.connection_failed.connect(_on_conn_failed)
	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.player_left.connect(_on_player_left)

	start_button.disabled = true
	start_button.text = "等待对手加入..."

	# 显示本机IP
	ip_label.text = "本机IP: " + NetworkManager.get_local_ip()

func _on_host():
	if NetworkManager.host_game():
		host_button.disabled = true
		room_code_label.text = "房间码: " + NetworkManager.room_code
		status_label.text = "✅ 房间已创建，等待对手加入..."
		status_label.modulate = Color.GREEN
		start_button.disabled = false
		start_button.text = "开始比赛（房主）"

func _on_join():
	var ip = join_ip_edit.text.strip_edges()
	if ip.is_empty():
		join_status.text = "❌ 请输入房主IP"
		join_status.modulate = Color.RED
		return

	join_status.text = "正在连接..."
	join_status.modulate = Color.YELLOW
	join_button.disabled = true

	if not NetworkManager.join_game(ip):
		join_status.text = "❌ 仅允许局域网地址"
		join_status.modulate = Color.RED
		join_button.disabled = false

func _on_conn_success():
	if NetworkManager.is_host:
		status_label.text = "✅ 对手已连接！"
	else:
		join_status.text = "✅ 已连接到房主！"
		join_status.modulate = Color.GREEN
		start_button.disabled = true
		start_button.text = "等待房主开始..."

func _on_conn_failed(reason: String):
	join_status.text = "❌ " + reason
	join_status.modulate = Color.RED
	join_button.disabled = false

func _on_player_joined(id: int):
	if NetworkManager.is_host:
		status_label.text = "✅ 对手已加入 (ID: %d)" % id
		status_label.modulate = Color.GREEN

func _on_player_left(id: int):
	if NetworkManager.is_host:
		status_label.text = "⚠️ 对手已离开"
		status_label.modulate = Color.YELLOW

func _on_start():
	if not NetworkManager.is_host:
		return

	# 房主开始比赛，通知客户端
	_start_match.rpc()

	# 设置联机比赛配置
	GameState.set_match_config({
		"home_team_name": "红队（房主）",
		"away_team_name": "蓝队（访客）",
		"home_color": Color(0.9, 0.15, 0.15),
		"away_color": Color(0.15, 0.3, 0.9),
		"formation": "4-4-2",
		"difficulty": GameState.AIDifficulty.NORMAL,
		"half_duration": 180.0,
		"player_controls": GameState.TeamSide.HOME,
		"initial_score": [0, 0],
		"is_lan_match": true,
	})
	get_tree().change_scene_to_file("res://scenes/Match.tscn")

@rpc("authority", "call_remote", "reliable")
func _start_match():
	# 客户端收到开始比赛通知
	GameState.set_match_config({
		"home_team_name": "红队（房主）",
		"away_team_name": "蓝队（访客）",
		"home_color": Color(0.9, 0.15, 0.15),
		"away_color": Color(0.15, 0.3, 0.9),
		"formation": "4-4-2",
		"difficulty": GameState.AIDifficulty.NORMAL,
		"half_duration": 180.0,
		"player_controls": GameState.TeamSide.AWAY,  # 客户端控制客队
		"initial_score": [0, 0],
		"is_lan_match": true,
	})
	get_tree().change_scene_to_file("res://scenes/Match.tscn")
