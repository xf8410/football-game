## player_controller.gd
## 球员控制器（增强版）
## 处理：移动、朝向、动画、冲刺、体力
## 新增动作：传中、挑球、挑射、远射、搓射、电梯球、2过1、门将出击
extends CharacterBody3D

# ---- 球员属性 ----
@export var team_side: int = 0
@export var team_id: String = ""
@export var team_name: String = ""
@export var player_id: String = ""       # 球员数据库ID
@export var role: String = "ST"
@export var player_index: int = 0
@export var is_goalkeeper: bool = false
@export var is_active: bool = false
@export var is_player_controlled: bool = false

# ---- 球员数据 ----
var stats: Dictionary = {}
var home_position: Vector3 = Vector3.ZERO
var current_stamina: float = 100.0
var attributes: Dictionary = {}  # 来自球员数据库的属性

# ---- 运动状态 ----
var velocity: Vector3 = Vector3.ZERO
var input_direction: Vector3 = Vector3.ZERO
var is_sprinting: bool = false
var facing_direction: Vector3 = Vector3.FORWARD
var has_ball: bool = false

# ---- 动作状态 ----
enum AnimState { IDLE, WALK, RUN, SPRINT, KICK, TACKLE, HEADER, DIVE, CELEBRATE }
var current_anim: int = AnimState.IDLE
var anim_timer: float = 0.0
var action_cooldown: float = 0.0  # 动作冷却时间

# ---- 2过1状态 ----
var one_two_partner: Node = null    # 2过1配合的队友
var one_two_timer: float = 0.0      # 2过1计时器

# ---- 门将状态 ----
var gk_rushing: bool = false        # 门将是否正在出击
var gk_rush_target: Vector3 = Vector3.ZERO

# ---- 视觉节点 ----
var body_mesh: MeshInstance3D
var number_marker: Label3D
var direction_arrow: MeshInstance3D

func _ready():
	body_mesh = get_node_or_null("MeshInstance3D")
	number_marker = get_node_or_null("Label3D")
	direction_arrow = get_node_or_null("MeshInstance3D3")

	if stats.is_empty():
		stats = GameState.BASE_PLAYER_STATS.duplicate()
	current_stamina = stats.get("stamina", 100.0)

	# 从数据库加载属性
	if player_id != "":
		attributes = PlayerDatabase.get_player_attributes(player_id)
		_apply_attributes_to_stats()

func _apply_attributes_to_stats():
	# 将数据库属性映射到游戏内stats
	if attributes.is_empty():
		return
	stats["speed"] = 5.0 + attributes.get("pace", 70) / 10.0
	stats["acceleration"] = 15.0 + attributes.get("pace", 70) / 5.0
	stats["pass_power"] = 12.0 + attributes.get("passing", 70) / 8.0
	stats["shot_power"] = 15.0 + attributes.get("shooting", 70) / 6.0
	stats["control_radius"] = 1.2 + attributes.get("dribbling", 70) / 100.0
	stats["tackle_radius"] = 1.5 + attributes.get("defending", 70) / 100.0

func _physics_process(delta):
	_update_movement(delta)
	_update_facing(delta)
	_update_animation(delta)
	_update_stamina(delta)
	_update_visuals()
	_update_one_two(delta)
	_update_goalkeeper(delta)
	_update_cooldown(delta)

func _update_movement(delta):
	var speed = stats.get("speed", 7.0)
	var accel = stats.get("acceleration", 25.0)

	# 体力影响速度
	var stamina_factor = 0.5 + (current_stamina / stats.get("stamina", 100.0)) * 0.5

	# 门将出击时速度更快
	if gk_rushing:
		speed *= 1.3

	# 冲刺
	if is_sprinting and current_stamina > 5:
		speed *= 1.4
	else:
		is_sprinting = false

	speed *= stamina_factor

	# 目标速度
	var target_velocity = input_direction * speed
	velocity = velocity.lerp(target_velocity, delta * accel)

	# 应用移动
	position += velocity * delta

	# 球员间碰撞避让（简易寻路）
	position = _avoid_other_players(position)

func _avoid_other_players(pos: Vector3) -> Vector3:
	# 避免与其他球员重叠（碰撞逻辑）
	if not get_parent():
		return pos
	for sibling in get_parent().get_children():
		if sibling == self or not sibling is CharacterBody3D:
			continue
		if not sibling.get("is_active") and not is_active:
			# 非活跃球员之间也需要避让
			pass
		var dist = pos.distance_to(sibling.position)
		var min_dist = 1.2  # 球员间最小距离
		if dist < min_dist and dist > 0.01:
			var push_dir = (pos - sibling.position).normalized()
			pos = sibling.position + push_dir * min_dist
			pos.y = 0
	return pos

func _update_facing(delta):
	if input_direction.length() > 0.1:
		facing_direction = input_direction.normalized()
	# 平滑旋转到面向方向
	if body_mesh:
		var target_angle = atan2(facing_direction.x, facing_direction.z)
		body_mesh.rotation.y = lerp_angle(body_mesh.rotation.y, target_angle, delta * 10)

func _update_animation(delta):
	anim_timer += delta
	var speed = velocity.length()

	if action_cooldown > 0:
		current_anim = AnimState.KICK
	elif speed < 0.5:
		current_anim = AnimState.IDLE
	elif speed < 3.0:
		current_anim = AnimState.WALK
	elif speed < 6.0:
		current_anim = AnimState.RUN
	else:
		current_anim = AnimState.SPRINT

	# 程序化动画（简单上下浮动）
	if body_mesh:
		var bounce = 0.0
		match current_anim:
			AnimState.WALK:
				bounce = sin(anim_timer * 6) * 0.05
			AnimState.RUN:
				bounce = sin(anim_timer * 10) * 0.08
			AnimState.SPRINT:
				bounce = sin(anim_timer * 14) * 0.12
		body_mesh.position.y = 0.9 + bounce

		var lean = 0.0
		match current_anim:
			AnimState.RUN: lean = 0.1
			AnimState.SPRINT: lean = 0.2
		body_mesh.rotation.x = lerp(body_mesh.rotation.x, lean, delta * 5)

func _update_stamina(delta):
	var max_stamina = stats.get("stamina", 100.0)
	if is_sprinting and input_direction.length() > 0.1:
		current_stamina -= stats.get("stamina_drain", 2.0) * delta
	else:
		current_stamina += stats.get("stamina_recover", 5.0) * delta
	current_stamina = clamp(current_stamina, 0, max_stamina)

func _update_visuals():
	# 活跃球员高亮
	if is_active and direction_arrow:
		direction_arrow.visible = true
		var pulse = 0.7 + sin(anim_timer * 5) * 0.3
		var mat = direction_arrow.material_override
		if mat is StandardMaterial3D:
			mat.emission_energy_multiplier = pulse
	else:
		if direction_arrow:
			direction_arrow.visible = false

	# 显示球衣号码
	if number_marker:
		number_marker.text = str(player_index)
		number_marker.modulate = Color.WHITE if is_active else Color(0.8, 0.8, 0.8)

func _update_one_two(delta):
	if one_two_timer > 0:
		one_two_timer -= delta
		if one_two_timer <= 0:
			one_two_partner = null

func _update_goalkeeper(delta):
	if not is_goalkeeper:
		return
	if gk_rushing:
		# 向出击目标移动
		var to_target = gk_rush_target - position
		to_target.y = 0
		if to_target.length() > 1.0:
			input_direction = to_target.normalized()
			is_sprinting = true
		else:
			gk_rushing = false
			input_direction = Vector3.ZERO

func _update_cooldown(delta):
	if action_cooldown > 0:
		action_cooldown -= delta

## 设置2过1配合
func start_one_two(partner: Node):
	one_two_partner = partner
	one_two_timer = 3.0  # 3秒内完成2过1

## 门将出击
func goalkeeper_rush(target: Vector3):
	if is_goalkeeper:
		gk_rushing = true
		gk_rush_target = target

## 门将回防
func goalkeeper_return():
	gk_rushing = false
	var target_goal_z = -GameState.FIELD_LENGTH / 2 if team_side == GameState.TeamSide.HOME else GameState.FIELD_LENGTH / 2
	gk_rush_target = Vector3(0, 0, target_goal_z + (5 if team_side == 0 else -5))
	gk_rushing = true

## 触发动作动画
func play_action(anim: int, duration: float = 0.5):
	current_anim = anim
	action_cooldown = duration

## 重置球员状态
func reset_to_home():
	position = home_position
	velocity = Vector3.ZERO
	input_direction = Vector3.ZERO
	has_ball = false
	current_stamina = stats.get("stamina", 100.0)
	gk_rushing = false
	one_two_partner = null
	one_two_timer = 0
	action_cooldown = 0

## 获取球员信息
func get_info() -> Dictionary:
	return {
		"team": team_name,
		"role": role,
		"number": player_index,
		"is_gk": is_goalkeeper,
		"stamina": current_stamina,
		"max_stamina": stats.get("stamina", 100.0),
		"position": position,
		"player_id": player_id,
		"name": PlayerDatabase.get_player_name(player_id) if player_id != "" else "Player %d" % player_index,
	}
