## lan_match.gd
## 局域网1v1联机比赛控制器
## 两个玩家各控制一支球队的11人
##
## 架构：
##   房主（Host）：
##   ├─ 运行完整比赛模拟（物理、AI、规则）
##   ├─ 控制主队11人（接收本地输入）
##   ├─ 接收客户端输入，控制客队11人
##   └─ 广播比赛状态给客户端
##
##   客户端（Client）：
##   ├─ 发送本地输入给房主
##   ├─ 接收比赛状态并渲染
##   └─ 不运行物理/AI计算
extends Node

signal match_state_received(state: Dictionary)
signal connection_ready()

# 网络状态
var is_host: bool = false
var is_client: bool = false
var peer_id: int = 0

# 输入同步
const INPUT_SEND_RATE: float = 0.033  # 30fps发送输入
var input_send_timer: float = 0.0

# 本地输入缓冲
var local_input: Dictionary = {
	"move_vector": Vector2.ZERO,
	"sprint": false,
	"actions": [],  # ["pass", "shoot", "tackle", "switch", "cross", "through"]
	"switch_target": -1,  # 切换到哪个球员
}

# 远程输入缓冲
var remote_input: Dictionary = {}

func _ready():
	# 连接网络信号
	NetworkManager.connection_succeeded.connect(_on_connected)
	NetworkManager.player_joined.connect(_on_player_joined)

## 设置为主机
func setup_as_host():
	is_host = true
	is_client = false
	print("[LANMatch] 作为房主运行")

## 设置为客户端
func setup_as_client():
	is_host = false
	is_client = true
	print("[LANMatch] 作为客户端运行")

## 每帧收集本地输入
func collect_local_input(move_vec: Vector2, sprint: bool, actions: Array, switch_target: int = -1):
	local_input = {
		"move_vector": move_vec,
		"sprint": sprint,
		"actions": actions,
		"switch_target": switch_target,
	}

	# 客户端：发送输入给房主
	if is_client:
		input_send_timer += get_process_delta_time()
		if input_send_timer >= INPUT_SEND_RATE:
			input_send_timer = 0.0
			_send_input_to_host.rpc_id(1, local_input)

## 房主：获取远程玩家输入
func get_remote_input() -> Dictionary:
	return remote_input

## 房主：广播比赛状态给客户端
func broadcast_match_state(state: Dictionary):
	if is_host:
		_receive_match_state.rpc(state)

## 客户端：接收比赛状态
@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_match_state(state: Dictionary):
	if is_client:
		match_state_received.emit(state)

## 房主：接收客户端输入
@rpc("any_peer", "call_remote", "unreliable")
func _send_input_to_host(input_data: Dictionary):
	if is_host:
		var sender_id = multiplayer.get_remote_sender_id()
		remote_input = input_data
		remote_input["sender_id"] = sender_id

## 连接成功
func _on_connected():
	connection_ready.emit()
	print("[LANMatch] 连接成功")

## 玩家加入
func _on_player_joined(id: int):
	print("[LANMatch] 玩家加入: %d" % id)
	if is_host:
		# 通知客户端可以开始
		_notify_ready.rpc_id(id)

@rpc("authority", "call_remote", "reliable")
func _notify_ready():
	print("[LANMatch] 房主已就绪")

## 开始联机比赛
func start_lan_match(home_team_id: String, away_team_id: String):
	var config = {
		"home_team_id": home_team_id,
		"away_team_id": away_team_id,
		"is_lan_match": true,
	}

	if is_host:
		config["player_controls"] = GameState.TeamSide.HOME
		config["home_team_name"] = TeamDatabase.get_team_name(home_team_id)
		config["away_team_name"] = TeamDatabase.get_team_name(away_team_id)
	else:
		config["player_controls"] = GameState.TeamSide.AWAY
		config["home_team_name"] = TeamDatabase.get_team_name(home_team_id)
		config["away_team_name"] = TeamDatabase.get_team_name(away_team_id)

	GameState.set_match_config(config)
	get_tree().change_scene_to_file("res://scenes/Match.tscn")

## 断开连接
func disconnect():
	NetworkManager.close_connection()
	is_host = false
	is_client = false
