## player_controller.gd
## 球员控制器
## 处理单个球员的移动、朝向、动画状态
## 被Match.gd创建并控制
extends CharacterBody3D

# ---- 球员属性 ----
@export var team_side: int = 0           # 队伍：0=主队, 1=客队
@export var team_name: String = ""       # 队名
@export var role: String = "ST"          # 位置角色：GK/DL/DC/DC/DR/ML/MC/MC/MR/ST/ST
@export var player_index: int = 0        # 球衣号码
@export var is_goalkeeper: bool = false  # 是否门将
@export var is_active: bool = false      # 是否当前活跃球员
@export var is_player_controlled: bool = false  # 是否被玩家控制

# ---- 球员数据 ----
var stats: Dictionary = {}
var home_position: Vector3 = Vector3.ZERO
var current_stamina: float = 100.0

# ---- 运动状态 ----
var velocity: Vector3 = Vector3.ZERO
var input_direction: Vector3 = Vector3.ZERO
var is_sprinting: bool = false
var facing_direction: Vector3 = Vector3.FORWARD
var has_ball: bool = false

# ---- 动画状态 ----
enum AnimState { IDLE, WALK, RUN, SPRINT, KICK, TACKLE }
var current_anim: int = AnimState.IDLE
var anim_timer: float = 0.0

# ---- 视觉节点引用 ----
var body_mesh: MeshInstance3D
var number_marker: MeshInstance3D
var direction_arrow: MeshInstance3D

func _ready():
	# 获取子节点引用
	body_mesh = get_node_or_null("MeshInstance3D")
	number_marker = get_node_or_null("MeshInstance3D2")
	direction_arrow = get_node_or_null("MeshInstance3D3")

	# 初始化体力
	if stats.is_empty():
		stats = GameState.BASE_PLAYER_STATS.duplicate()
	current_stamina = stats.get("stamina", 100.0)

func _physics_process(delta):
	_update_movement(delta)
	_update_facing(delta)
	_update_animation(delta)
	_update_visuals()

func _update_movement(delta):
	var speed = stats.get("speed", 7.0)

	# 体力影响速度
	var stamina_ratio = current_stamina / stats.get("stamina", 100.0)
	if is_sprinting and stamina_ratio > 0.1:
		speed *= 1.3  # 冲刺加速30%
	else:
		speed *= 0.8 + stamina_ratio * 0.2  # 体力低时减速

	# 如果没有输入方向，减速
	if input_direction.length() > 0.1:
		var target_velocity = input_direction * speed
		# 平滑加速
		var accel = stats.get("acceleration", 25.0)
		velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)
	else:
		# 减速到停止
		var decel = stats.get("acceleration", 25.0) * 1.5
		velocity.x = move_toward(velocity.x, 0, decel * delta)
		velocity.z = move_toward(velocity.z, 0, decel * delta)

	# 应用移动
	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()

	# 限制在球场范围内（防止跑出界太远）
	var half_w = GameState.FIELD_WIDTH / 2 + 5
	var half_l = GameState.FIELD_LENGTH / 2 + 5
	position.x = clamp(position.x, -half_w, half_w)
	position.z = clamp(position.z, -half_l, half_l)
	position.y = 0

func _update_facing(delta):
	# 根据移动方向更新朝向
	if velocity.length() > 0.5:
		var target_facing = velocity.normalized()
		# 平滑转向
		facing_direction = facing_direction.lerp(target_facing, delta * 10).normalized()

	# 旋转身体朝向移动方向
	if facing_direction.length() > 0.1:
		var angle = atan2(facing_direction.x, facing_direction.z)
		rotation.y = lerp_angle(rotation.y, angle, delta * 10)

func _update_animation(delta):
	# 根据速度决定动画状态
	var speed = velocity.length()
	if speed < 0.5:
		current_anim = AnimState.IDLE
	elif speed < 3.0:
		current_anim = AnimState.WALK
	elif speed < 6.0:
		current_anim = AnimState.RUN
	else:
		current_anim = AnimState.SPRINT

	anim_timer += delta

	# 简单的动画效果：身体上下浮动
	if body_mesh:
		var bounce = 0.0
		match current_anim:
			AnimState.IDLE:
				bounce = sin(anim_timer * 2) * 0.02
			AnimState.WALK:
				bounce = sin(anim_timer * 6) * 0.05
			AnimState.RUN:
				bounce = sin(anim_timer * 10) * 0.08
			AnimState.SPRINT:
				bounce = sin(anim_timer * 14) * 0.12
		body_mesh.position.y = 0.9 + bounce

		# 奔跑时身体前倾
		var lean = 0.0
		match current_anim:
			AnimState.RUN:
				lean = 0.1
			AnimState.SPRINT:
				lean = 0.2
		body_mesh.rotation.x = lerp(body_mesh.rotation.x, lean, delta * 5)

func _update_visuals():
	# 活跃球员高亮
	if is_active and direction_arrow:
		direction_arrow.visible = true
		# 箭头闪烁
		var pulse = 0.7 + sin(anim_timer * 5) * 0.3
		direction_arrow.material_override.emission_energy_multiplier = pulse
	else:
		if direction_arrow:
			direction_arrow.visible = false

	# 体力低时身体变红
	if body_mesh and body_mesh.material_override:
		var stamina_ratio = current_stamina / stats.get("stamina", 100.0)
		if stamina_ratio < 0.3:
			var mat = body_mesh.material_override
			if mat is StandardMaterial3D:
				mat.emission_enabled = true
				mat.emission = Color(0.5, 0, 0)
				mat.emission_energy_multiplier = (0.3 - stamina_ratio) * 2

## 重置球员状态（开球时调用）
func reset_to_home():
	position = home_position
	velocity = Vector3.ZERO
	input_direction = Vector3.ZERO
	has_ball = false
	current_stamina = stats.get("stamina", 100.0)

## 获取球员信息（用于UI显示）
func get_info() -> Dictionary:
	return {
		"team": team_name,
		"role": role,
		"number": player_index,
		"is_gk": is_goalkeeper,
		"stamina": current_stamina,
		"max_stamina": stats.get("stamina", 100.0),
		"position": position,
	}
