## network_manager.gd
## 局域网联机管理器 (Autoload Singleton)
## 采用房主权威模式 (Host-Authoritative)
##
## 架构说明：
##   房主设备：
##   ├─ 运行比赛规则（计时、比分、进球判定）
##   ├─ 控制 AI
##   ├─ 判定碰撞、进球和比分
##   └─ 向其他设备同步比赛状态
##
##   加入设备：
##   ├─ 发送操作输入
##   └─ 接收并显示房主状态
##
## 安全和范围：
##   - 仅允许局域网地址
##   - 不接入官方服务器或任何公网服务
##   - 不做账号注册
##   - 不自动打开路由器端口
##   - 房间使用四至六位房间码
##   - 单机模式不启动网络监听
extends Node

signal player_joined(id: int)
signal player_left(id: int)
signal connection_succeeded()
signal connection_failed(reason: String)
signal match_state_received(state: Dictionary)

const DEFAULT_PORT: int = 24815
const MAX_PLAYERS: int = 2  # 足球游戏最多2个设备对战
const ROOM_CODE_LENGTH: int = 4

var peer: ENetMultiplayerPeer = null
var is_host: bool = false
var is_online: bool = false
var room_code: String = ""

## 生成房间码（4位数字+字母）
func generate_room_code() -> String:
	var chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  # 去掉容易混淆的字符
	var code = ""
	for i in range(ROOM_CODE_LENGTH):
		code += chars[randi() % chars.length()]
	return code

## 创建房间（作为房主）
func host_game(port: int = DEFAULT_PORT) -> bool:
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		connection_failed.emit("创建房间失败，错误码: %d" % err)
		return false

	multiplayer.multiplayer_peer = peer
	is_host = true
	is_online = true
	room_code = generate_room_code()

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("[Network] 房间已创建，端口: %d，房间码: %s" % [port, room_code])
	connection_succeeded.emit()
	return true

## 加入房间（作为客户端）
func join_game(ip: String, port: int = DEFAULT_PORT) -> bool:
	# 安全检查：仅允许局域网地址
	if not _is_lan_address(ip):
		connection_failed.emit("仅允许局域网地址连接")
		return false

	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		connection_failed.emit("连接失败，错误码: %d" % err)
		return false

	multiplayer.multiplayer_peer = peer
	is_host = false
	is_online = true

	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

	print("[Network] 正在连接 %s:%d..." % [ip, port])
	return true

## 断开连接
func close_connection() -> void:
	if peer != null:
		peer.close()
		peer = null
	is_host = false
	is_online = false
	room_code = ""
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	print("[Network] 连接已关闭")

## 检查是否为局域网地址
## 允许：127.x（本机）、10.x、172.16-31.x、192.168.x
func _is_lan_address(ip: String) -> bool:
	if ip == "localhost" or ip == "127.0.0.1":
		return true
	var parts = ip.split(".")
	if parts.size() != 4:
		return false
	var a = int(parts[0])
	var b = int(parts[1])
	if a == 10:
		return true
	if a == 172 and b >= 16 and b <= 31:
		return true
	if a == 192 and b == 168:
		return true
	return false

## 获取本机局域网IP
func get_local_ip() -> String:
	var addresses = IP.get_local_addresses()
	for addr in addresses:
		if _is_lan_address(addr) and addr != "127.0.0.1":
			return addr
	return "127.0.0.1"

# ---- 回调 ----

func _on_peer_connected(id: int) -> void:
	print("[Network] 玩家已加入: %d" % id)
	player_joined.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("[Network] 玩家已离开: %d" % id)
	player_left.emit(id)

func _on_connected_to_server() -> void:
	print("[Network] 已连接到房主")
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	print("[Network] 连接失败")
	connection_failed.emit("无法连接到房主")
	close_connection()

# ---- 同步方法（RPC）----

## 房主：广播比赛状态给所有客户端
@rpc("authority", "call_remote", "unreliable_ordered")
func sync_match_state(state: Dictionary) -> void:
	match_state_received.emit(state)

## 客户端：发送输入给房主
@rpc("any_peer", "call_remote", "unreliable")
func send_input(input_data: Dictionary) -> void:
	var sender = multiplayer.get_remote_sender_id()
	# 房主收到客户端输入后处理
	# 具体处理在 Match 场景中实现
	if is_host:
		_handle_remote_input(sender, input_data)

## 房主处理远程输入（由Match场景覆盖）
var _remote_input_handler: Callable = Callable()
func set_remote_input_handler(handler: Callable) -> void:
	_remote_input_handler = handler

func _handle_remote_input(sender_id: int, input_data: Dictionary) -> void:
	if _remote_input_handler.is_valid():
		_remote_input_handler.call(sender_id, input_data)
