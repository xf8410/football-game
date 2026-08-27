## match.gd
## 比赛核心控制器
## 负责：球场搭建、球队生成、计时、比分、进球判定、出界判定、
##       摄像机、UI、玩家控制切换、AI调度、比赛流程管理
##
## 视角：俯视角3D（类似最佳球会的斜俯视角）
## 球场坐标系：
##   - 原点在球场中心
##   - X轴：左右（-34 到 +34）
##   - Z轴：前后（-52.5 到 +52.5）
##   - 主队球门在 Z = -52.5（防守 -Z 方向）
##   - 客队球门在 Z = +52.5（防守 +Z 方向）
extends Node3D

# ---- 场景节点 ----
var camera: Camera3D
var field: MeshInstance3D
var ball: CharacterBody3D
var ball_mesh: MeshInstance3D
var ball_shadow: MeshInstance3D

# ---- 球队数据 ----
var home_players: Array = []  # Array of CharacterBody3D
var away_players: Array = []
var home_score: int = 0
var away_score: int = 0

# ---- 当前控制 ----
var active_player: CharacterBody3D = null
var player_side: int = GameState.TeamSide.HOME  # 玩家控制哪一方

# ---- 比赛状态 ----
var match_phase: int = GameState.MatchPhase.KICKOFF
var match_time: float = 0.0          # 当前半场已用时间（秒）
var current_half: int = 1             # 1=上半场, 2=下半场
var half_duration: float = 180.0      # 每半场时长
var goal_celebration_time: float = 0.0
var out_of_bounds_time: float = 0.0
var last_touch_team: int = -1         # 最后触球的队伍

# ---- 比赛配置 ----
var config: Dictionary
var ai_params: Dictionary

# ---- UI节点 ----
var ui_canvas: CanvasLayer
var score_label: Label
var time_label: Label
var phase_label: Label
var control_hint: Label
var pause_panel: Panel
var result_panel: Panel

# ---- 输入缓冲 ----
var input_vector: Vector2 = Vector2.ZERO
var is_sprinting: bool = false

# ---- 球的物理状态 ----
var ball_velocity: Vector3 = Vector3.ZERO
var ball_height: float = 0.0          # 球离地高度
var ball_height_velocity: float = 0.0 # 垂直速度
var ball_owner: CharacterBody3D = null # 当前控球者

# ---- 常量 ----
const PLAYER_SCENE_PATH = "res://scripts/player_controller.gd"
const BALL_RADIUS: float = 0.11
const PLAYER_RADIUS: float = 0.4
const BALL_FRICTION: float = 0.5       # 地面摩擦（每秒衰减比例）
const BALL_AIR_DRAG: float = 0.15
const BALL_GRAVITY: float = 9.8
const PASS_SPEED: float = 18.0
const SHOT_SPEED: float = 28.0
const LOB_SPEED: float = 12.0
const CAMERA_HEIGHT: float = 45.0
const CAMERA_DISTANCE: float = 30.0
const CAMERA_ANGLE: float = 55.0  # 俯视角角度

func _ready():
	# 加载配置
	config = GameState.current_match_config
	ai_params = GameState.get_ai_params()
	half_duration = config.get("half_duration", 180.0)
	player_side = config.get("player_controls", GameState.TeamSide.HOME)
	home_score = config.get("initial_score", [0, 0])[0]
	away_score = config.get("initial_score", [0, 0])[1]

	# 构建场景
	_setup_lighting()
	_setup_field()
	_setup_camera()
	_setup_teams()
	_setup_ball()
	_setup_ui()

	# 开始比赛
	_kickoff()

	# 设置网络输入处理器（局域网模式）
	if config.get("is_lan_match", false):
		NetworkManager.set_remote_input_handler(_handle_remote_input)

	print("[Match] 比赛开始！%s vs %s" % [config.home_team_name, config.away_team_name])

func _process(delta):
	match match_phase:
		GameState.MatchPhase.PLAYING:
			_update_timer(delta)
			_update_ball(delta)
			_update_active_player_control()
			_update_ai(delta)
			_update_camera(delta)
			_check_goal()
			_check_out_of_bounds()
			_update_stamina(delta)
		GameState.MatchPhase.GOAL:
			goal_celebration_time -= delta
			if goal_celebration_time <= 0:
				_kickoff()
		GameState.MatchPhase.BALL_OUT:
			out_of_bounds_time -= delta
			if out_of_bounds_time <= 0:
				_resume_from_out()
		GameState.MatchPhase.KICKOFF:
			# 短暂等待后开始
			pass

	_update_ui()

func _physics_process(delta):
	if match_phase == GameState.MatchPhase.PLAYING:
		_update_ball_physics(delta)

# ============================================================
# 场景搭建
# ============================================================

func _setup_lighting():
	# 环境光
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.4, 0.6, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.7, 0.8)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.5, 0.7, 0.9)
	env.fog_light_energy = 0.3
	env.fog_density = 0.005

	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# 方向光（太阳）
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.shadow_map_resolution = 2048
	add_child(sun)

func _setup_field():
	# 球场地面
	field = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(GameState.FIELD_LENGTH + 10, GameState.FIELD_WIDTH + 10)
	plane.material = _create_field_material()
	field.mesh = plane
	field.position = Vector3(0, 0, 0)
	add_child(field)

	# 球场线条（用细长的Box）
	_create_field_lines()

	# 球门
	_create_goal(Vector3(0, 0, -GameState.FIELD_LENGTH / 2), GameState.TeamSide.HOME)
	_create_goal(Vector3(0, 0, GameState.FIELD_LENGTH / 2), GameState.TeamSide.AWAY)

	# 球场周围的看台（简单装饰）
	_create_stands()

func _create_field_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.45, 0.15)  # 草地绿
	mat.roughness = 0.9
	mat.metalness = 0.0

	# 创建条纹纹理（用代码生成）
	var img = Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in range(256):
		for x in range(256):
			var stripe = (int(y / 32) % 2) == 0
			if stripe:
				img.set_pixel(x, y, Color(0.15, 0.48, 0.15))
			else:
				img.set_pixel(x, y, Color(0.13, 0.42, 0.13))
	var tex = ImageTexture.create_from_image(img)
	mat.albedo_texture = tex
	return mat

func _create_field_lines():
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color.WHITE
	line_mat.emission_enabled = true
	line_mat.emission = Color(0.8, 0.8, 0.8)
	line_mat.emission_energy_multiplier = 0.3

	# 边线
	_create_line(Vector3(0, 0.01, -GameState.FIELD_LENGTH/2), Vector3(GameState.FIELD_WIDTH, 0.1, 0.15), line_mat)
	_create_line(Vector3(0, 0.01, GameState.FIELD_LENGTH/2), Vector3(GameState.FIELD_WIDTH, 0.1, 0.15), line_mat)
	_create_line(Vector3(-GameState.FIELD_WIDTH/2, 0.01, 0), Vector3(0.15, 0.1, GameState.FIELD_LENGTH), line_mat)
	_create_line(Vector3(GameState.FIELD_WIDTH/2, 0.01, 0), Vector3(0.15, 0.1, GameState.FIELD_LENGTH), line_mat)

	# 中线
	_create_line(Vector3(0, 0.01, 0), Vector3(GameState.FIELD_WIDTH, 0.1, 0.15), line_mat)

	# 中圈
	var circle = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 9.05
	torus.outer_radius = 9.15
	circle.mesh = torus
	circle.material_override = line_mat
	circle.position = Vector3(0, 0.02, 0)
	circle.rotation_degrees.x = 90
	add_child(circle)

	# 中点
	var center_dot = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	center_dot.mesh = sphere
	center_dot.material_override = line_mat
	center_dot.position = Vector3(0, 0.03, 0)
	add_child(center_dot)

	# 禁区（两端）
	for side_z in [-1, 1]:
		var z = side_z * (GameState.FIELD_LENGTH / 2 - GameState.PENALTY_AREA_DEPTH)
		# 禁区线
		_create_line(Vector3(0, 0.01, z), Vector3(GameState.PENALTY_AREA_WIDTH, 0.1, 0.15), line_mat)
		_create_line(Vector3(-GameState.PENALTY_AREA_WIDTH/2, 0.01, z), Vector3(0.15, 0.1, GameState.PENALTY_AREA_DEPTH), line_mat)
		_create_line(Vector3(GameState.PENALTY_AREA_WIDTH/2, 0.01, z), Vector3(0.15, 0.1, GameState.PENALTY_AREA_DEPTH), line_mat)

		# 点球点
		var penalty_spot = MeshInstance3D.new()
		var ps_sphere = SphereMesh.new()
		ps_sphere.radius = 0.25
		ps_sphere.height = 0.5
		penalty_spot.mesh = ps_sphere
		penalty_spot.material_override = line_mat
		penalty_spot.position = Vector3(0, 0.03, z + side_z * 2.5)
		add_child(penalty_spot)

func _create_line(pos: Vector3, size: Vector3, mat: Material):
	var line = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	line.mesh = box
	line.material_override = mat
	line.position = pos
	add_child(line)

func _create_goal(pos: Vector3, side: int):
	var goal_mat = StandardMaterial3D.new()
	goal_mat.albedo_color = Color.WHITE
	goal_mat.emission_enabled = true
	goal_mat.emission = Color(0.9, 0.9, 0.9)
	goal_mat.emission_energy_multiplier = 0.5

	# 球门柱
	var post_left = MeshInstance3D.new()
	var post_mesh = CylinderMesh.new()
	post_mesh.top_radius = 0.08
	post_mesh.bottom_radius = 0.08
	post_mesh.height = GameState.GOAL_HEIGHT
	post_left.mesh = post_mesh
	post_left.material_override = goal_mat
	post_left.position = pos + Vector3(-GameState.GOAL_WIDTH/2, GameState.GOAL_HEIGHT/2, 0)
	add_child(post_left)

	var post_right = MeshInstance3D.new()
	post_right.mesh = post_mesh
	post_right.material_override = goal_mat
	post_right.position = pos + Vector3(GameState.GOAL_WIDTH/2, GameState.GOAL_HEIGHT/2, 0)
	add_child(post_right)

	# 横梁
	var crossbar = MeshInstance3D.new()
	var cb_mesh = CylinderMesh.new()
	cb_mesh.top_radius = 0.08
	cb_mesh.bottom_radius = 0.08
	cb_mesh.height = GameState.GOAL_WIDTH
	crossbar.mesh = cb_mesh
	crossbar.material_override = goal_mat
	crossbar.position = pos + Vector3(0, GameState.GOAL_HEIGHT, 0)
	crossbar.rotation_degrees.z = 90
	add_child(crossbar)

	# 球网（简单半透明面）
	var net = MeshInstance3D.new()
	var net_plane = PlaneMesh.new()
	net_plane.size = Vector2(GameState.GOAL_WIDTH, GameState.GOAL_HEIGHT)
	var net_mat = StandardMaterial3D.new()
	net_mat.albedo_color = Color(1, 1, 1, 0.15)
	net_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	net_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	net_plane.material = net_mat
	net.mesh = net_plane
	net.position = pos + Vector3(0, GameState.GOAL_HEIGHT/2, -2 if side == GameState.TeamSide.HOME else 2)
	net.rotation_degrees.x = 90
	add_child(net)

func _create_stands():
	# 简单看台装饰
	var stand_mat = StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.2, 0.2, 0.25)

	for i in range(4):
		var stand = MeshInstance3D.new()
		var box = BoxMesh.new()
		match i:
			0: # 北看台
				box.size = Vector3(GameState.FIELD_WIDTH + 20, 8, 5)
				stand.position = Vector3(0, 4, -GameState.FIELD_LENGTH/2 - 10)
			1: # 南看台
				box.size = Vector3(GameState.FIELD_WIDTH + 20, 8, 5)
				stand.position = Vector3(0, 4, GameState.FIELD_LENGTH/2 + 10)
			2: # 东看台
				box.size = Vector3(5, 8, GameState.FIELD_LENGTH + 20)
				stand.position = Vector3(GameState.FIELD_WIDTH/2 + 10, 4, 0)
			3: # 西看台
				box.size = Vector3(5, 8, GameState.FIELD_LENGTH + 20)
				stand.position = Vector3(-GameState.FIELD_WIDTH/2 - 10, 4, 0)
		stand.mesh = box
		stand.material_override = stand_mat
		add_child(stand)

func _setup_camera():
	camera = Camera3D.new()
	camera.fov = 50
	camera.near = 0.5
	camera.far = 500
	add_child(camera)
	_position_camera(Vector3.ZERO)

func _position_camera(target: Vector3):
	# 斜俯视角（类似最佳球会）
	var angle_rad = deg_to_rad(CAMERA_ANGLE)
	var offset = Vector3(0, CAMERA_HEIGHT, -CAMERA_DISTANCE * cos(angle_rad))
	# 摄像机在目标后方上方
	camera.position = target + Vector3(0, CAMERA_HEIGHT, -CAMERA_DISTANCE)
	camera.look_at(target + Vector3(0, 0, 5), Vector3.UP)

func _setup_teams():
	var formation = GameState.get_formation(config.get("formation", "4-4-2"))

	# 主队（防守 -Z 方向）
	home_players = _create_team(formation, GameState.TeamSide.HOME, config.home_color)
	# 客队（防守 +Z 方向，镜像坐标）
	away_players = _create_team(formation, GameState.TeamSide.AWAY, config.away_color)

	# 设置初始活跃球员（最靠近球的非门将球员）
	_switch_active_player()

func _create_team(formation: Array, side: int, color: Color) -> Array:
	var players = []
	var team_name = config.home_team_name if side == GameState.TeamSide.HOME else config.away_team_name

	for i in range(formation.size()):
		var role_data = formation[i]
		var role = role_data[0]
		var x = role_data[1]
		var z = role_data[2]

		# 客队镜像坐标
		if side == GameState.TeamSide.AWAY:
			z = -z
			x = -x

		var player = _create_player_node(side, color, team_name, role, i, x, z)
		players.append(player)
		add_child(player)

	return players

func _create_player_node(side: int, color: Color, team_name: String, role: String, index: int, x: float, z: float) -> CharacterBody3D:
	var player = CharacterBody3D.new()
	player.script = load(PLAYER_SCENE_PATH)

	# 球员身体（胶囊）
	var body = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = 1.8
	body.mesh = capsule
	body.position = Vector3(0, 0.9, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	body.material_override = mat
	player.add_child(body)

	# 球员编号（用不同颜色的小球表示）
	var num_marker = MeshInstance3D.new()
	var num_sphere = SphereMesh.new()
	num_sphere.radius = 0.2
	num_sphere.height = 0.4
	num_marker.mesh = num_sphere
	var num_mat = StandardMaterial3D.new()
	num_mat.albedo_color = Color.WHITE if index % 2 == 0 else Color.YELLOW
	num_mat.emission_enabled = true
	num_mat.emission = num_mat.albedo_color
	num_mat.emission_energy_multiplier = 0.5
	num_marker.material_override = num_mat
	num_marker.position = Vector3(0, 2.0, 0)
	player.add_child(num_marker)

	# 方向指示器（小箭头）
	var arrow = MeshInstance3D.new()
	var arrow_box = BoxMesh.new()
	arrow_box.size = Vector3(0.15, 0.1, 0.5)
	arrow.mesh = arrow_box
	var arrow_mat = StandardMaterial3D.new()
	arrow_mat.albedo_color = Color.YELLOW
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color.YELLOW
	arrow_mat.emission_energy_multiplier = 0.8
	arrow.material_override = arrow_mat
	arrow.position = Vector3(0, 0.3, 0.6)
	player.add_child(arrow)

	# 阴影
	var shadow = MeshInstance3D.new()
	var shadow_circle = CircleMesh.new()
	shadow_circle.radius = 0.6
	shadow.mesh = shadow_circle
	var shadow_mat = StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.3)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shadow.material_override = shadow_mat
	shadow.position = Vector3(0, 0.02, 0)
	shadow.rotation_degrees.x = -90
	player.add_child(shadow)

	# 初始化球员属性
	player.set("team_side", side)
	player.set("team_name", team_name)
	player.set("role", role)
	player.set("player_index", index)
	player.set("home_position", Vector3(x, 0, z))
	player.position = Vector3(x, 0, z)
	player.set("stats", GameState.BASE_PLAYER_STATS.duplicate())
	player.set("is_active", false)
	player.set("is_goalkeeper", role == "GK")

	# 门将不同颜色
	if role == "GK":
		var gk_mat = StandardMaterial3D.new()
		gk_mat.albedo_color = Color(0.9, 0.7, 0.1)
		body.material_override = gk_mat

	return player

func _setup_ball():
	ball = CharacterBody3D.new()

	ball_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = BALL_RADIUS
	sphere.height = BALL_RADIUS * 2
	ball_mesh.mesh = sphere

	var ball_mat = StandardMaterial3D.new()
	ball_mat.albedo_color = Color.WHITE
	ball_mat.roughness = 0.4
	ball_mat.metalness = 0.1
	ball_mesh.material_override = ball_mat
	ball.add_child(ball_mesh)

	# 球的阴影
	ball_shadow = MeshInstance3D.new()
	var shadow_circle = CircleMesh.new()
	shadow_circle.radius = BALL_RADIUS * 1.5
	ball_shadow.mesh = shadow_circle
	var shadow_mat = StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.4)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ball_shadow.material_override = shadow_mat
	ball_shadow.rotation_degrees.x = -90
	add_child(ball_shadow)

	ball.position = Vector3(0, BALL_RADIUS, 0)
	add_child(ball)

# ============================================================
# UI
# ============================================================

func _setup_ui():
	ui_canvas = CanvasLayer.new()
	add_child(ui_canvas)

	# 比分牌
	score_label = Label.new()
	score_label.text = "0 - 0"
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 60, 20)
	score_label.size = Vector2(120, 60)
	ui_canvas.add_child(score_label)

	# 队名
	var team_names = Label.new()
	team_names.text = "%s  vs  %s" % [config.home_team_name, config.away_team_name]
	team_names.add_theme_font_size_override("font_size", 18)
	team_names.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	team_names.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_names.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 150, 75)
	team_names.size = Vector2(300, 25)
	ui_canvas.add_child(team_names)

	# 时间
	time_label = Label.new()
	time_label.text = "00:00"
	time_label.add_theme_font_size_override("font_size", 36)
	time_label.add_theme_color_override("font_color", Color.YELLOW)
	time_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	time_label.add_theme_constant_override("shadow_offset_x", 2)
	time_label.add_theme_constant_override("shadow_offset_y", 2)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 50, 100)
	time_label.size = Vector2(100, 45)
	ui_canvas.add_child(time_label)

	# 半场指示
	phase_label = Label.new()
	phase_label.text = "上半场"
	phase_label.add_theme_font_size_override("font_size", 16)
	phase_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 50, 145)
	phase_label.size = Vector2(100, 20)
	ui_canvas.add_child(phase_label)

	# 操作提示
	control_hint = Label.new()
	control_hint.text = "WASD移动 | J传球 | 空格射门 | K切换球员 | L抢断 | Shift冲刺"
	control_hint.add_theme_font_size_override("font_size", 14)
	control_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	control_hint.position = Vector2(20, get_viewport().get_visible_rect().size.y - 30)
	ui_canvas.add_child(control_hint)

	# 暂停面板
	_create_pause_panel()
	_create_result_panel()

func _create_pause_panel():
	pause_panel = Panel.new()
	pause_panel.size = Vector2(400, 300)
	pause_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - 400) / 2,
		(get_viewport().get_visible_rect().size.y - 300) / 2
	)
	pause_panel.visible = false
	ui_canvas.add_child(pause_panel)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(50, 30)
	vbox.size = Vector2(300, 240)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_panel.add_child(vbox)

	var title = Label.new()
	title.text = "比赛暂停"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume_btn = Button.new()
	resume_btn.text = "继续比赛"
	resume_btn.pressed.connect(func():
		match_phase = GameState.MatchPhase.PLAYING
		pause_panel.visible = false
	)
	vbox.add_child(resume_btn)

	var restart_btn = Button.new()
	restart_btn.text = "重新开始"
	restart_btn.pressed.connect(func():
		get_tree().reload_current_scene()
	)
	vbox.add_child(restart_btn)

	var quit_btn = Button.new()
	quit_btn.text = "返回主菜单"
	quit_btn.pressed.connect(func():
		if config.get("is_lan_match", false):
			NetworkManager.close_connection()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	vbox.add_child(quit_btn)

func _create_result_panel():
	result_panel = Panel.new()
	result_panel.size = Vector2(500, 400)
	result_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - 500) / 2,
		(get_viewport().get_visible_rect().size.y - 400) / 2
	)
	result_panel.visible = false
	ui_canvas.add_child(result_panel)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(50, 30)
	vbox.size = Vector2(400, 340)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	result_panel.add_child(vbox)

	var title = Label.new()
	title.name = "ResultTitle"
	title.text = "比赛结束"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var score = Label.new()
	score.name = "ResultScore"
	score.text = "0 - 0"
	score.add_theme_font_size_override("font_size", 48)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score)

	var stats = Label.new()
	stats.name = "ResultStats"
	stats.text = ""
	stats.add_theme_font_size_override("font_size", 16)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)

	var rematch_btn = Button.new()
	rematch_btn.text = "再赛一场"
	rematch_btn.pressed.connect(func():
		get_tree().reload_current_scene()
	)
	vbox.add_child(rematch_btn)

	var menu_btn = Button.new()
	menu_btn.text = "返回主菜单"
	menu_btn.pressed.connect(func():
		if config.get("is_lan_match", false):
			NetworkManager.close_connection()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	vbox.add_child(menu_btn)

# ============================================================
# 比赛流程
# ============================================================

func _kickoff():
	match_phase = GameState.MatchPhase.KICKOFF

	# 重置球员位置到阵型
	_reset_positions()

	# 球放中圈
	ball.position = Vector3(0, BALL_RADIUS, 0)
	ball_velocity = Vector3.ZERO
	ball_height = 0
	ball_height_velocity = 0
	ball_owner = null

	# 开球方：上半场主队开球，下半场客队开球
	var kickoff_side = GameState.TeamSide.HOME if current_half == 1 else GameState.TeamSide.AWAY
	var kickoff_team = home_players if kickoff_side == GameState.TeamSide.HOME else away_players

	# 开球球员站到中圈
	if kickoff_team.size() > 9:
		kickoff_team[9].position = Vector3(-2, 0, 0)
		kickoff_team[10].position = Vector3(2, 0, 0)

	# 短暂延迟后开始
	await get_tree().create_timer(1.5).timeout
	match_phase = GameState.MatchPhase.PLAYING

	# 切换到最合适的球员
	_switch_active_player()

func _reset_positions():
	var formation = GameState.get_formation(config.get("formation", "4-4-2"))
	for i in range(home_players.size()):
		var p = home_players[i]
		var role_data = formation[i]
		p.position = Vector3(role_data[1], 0, role_data[2])
		p.set("velocity", Vector3.ZERO)
		p.set("current_stamina", p.get("stats").stamina)

	for i in range(away_players.size()):
		var p = away_players[i]
		var role_data = formation[i]
		p.position = Vector3(-role_data[1], 0, -role_data[2])
		p.set("velocity", Vector3.ZERO)
		p.set("current_stamina", p.get("stats").stamina)

func _update_timer(delta):
	match_time += delta
	if match_time >= half_duration:
		if current_half == 1:
			# 半场休息
			current_half = 2
			match_time = 0
			phase_label.text = "下半场"
			_kickoff()
		else:
			# 比赛结束
			_end_match()

func _end_match():
	match_phase = GameState.MatchPhase.FULLTIME

	# 更新存档
	var player_score = home_score if player_side == GameState.TeamSide.HOME else away_score
	var opponent_score = away_score if player_side == GameState.TeamSide.HOME else home_score
	var won = player_score > opponent_score
	var drawn = player_score == opponent_score
	SaveManager.update_match_result(won, drawn, player_score, opponent_score)

	# 显示结果
	result_panel.visible = true
	var title = result_panel.get_node("VBoxContainer/ResultTitle")
	var score = result_panel.get_node("VBoxContainer/ResultScore")
	var stats = result_panel.get_node("VBoxContainer/ResultStats")

	if won:
		title.text = "🎉 胜利！"
		title.add_theme_color_override("font_color", Color.GREEN)
	elif drawn:
		title.text = "🤝 平局"
		title.add_theme_color_override("font_color", Color.YELLOW)
	else:
		title.text = "😢 失败"
		title.add_theme_color_override("font_color", Color.RED)

	score.text = "%d - %d" % [home_score, away_score]
	stats.text = "%s %d - %d %s\n%s vs %s" % [
		config.home_team_name, home_score, away_score, config.away_team_name,
		config.home_team_name, config.away_team_name
	]

# ============================================================
# 球的物理
# ============================================================

func _update_ball(delta):
	# 如果有控球者，球跟随控球者
	if ball_owner != null and is_instance_valid(ball_owner):
		var owner_pos = ball_owner.position
		var forward = -ball_owner.get("facing_direction") if ball_owner.get("facing_direction") != null else Vector3.FORWARD
		# 球在球员脚下前方
		ball.position = owner_pos + Vector3(forward.x, 0, forward.z) * 0.8 + Vector3(0, BALL_RADIUS, 0)
		ball_velocity = Vector3.ZERO
		ball_height = 0
		ball_height_velocity = 0
	else:
		_update_ball_physics(delta)

	# 更新球的视觉位置（高度）
	ball_mesh.position = Vector3(0, ball_height, 0)
	ball_shadow.position = Vector3(ball.position.x, 0.02, ball.position.z)
	# 阴影随高度变大变淡
	var shadow_scale = 1.0 + ball_height * 0.1
	ball_shadow.scale = Vector3(shadow_scale, shadow_scale, shadow_scale)
	var shadow_mat = ball_shadow.material_override
	if shadow_mat:
		shadow_mat.albedo_color.a = max(0.1, 0.4 - ball_height * 0.02)

func _update_ball_physics(delta):
	# 水平移动
	ball.position.x += ball_velocity.x * delta
	ball.position.z += ball_velocity.z * delta

	# 摩擦
	var friction = BALL_FRICTION * delta
	ball_velocity.x *= max(0, 1 - friction)
	ball_velocity.z *= max(0, 1 - friction)

	# 如果速度很小，停止
	if ball_velocity.length() < 0.5:
		ball_velocity = Vector3.ZERO

	# 垂直运动（弹跳）
	if ball_height > 0 or ball_height_velocity != 0:
		ball_height += ball_height_velocity * delta
		ball_height_velocity -= BALL_GRAVITY * delta

		if ball_height <= 0:
			ball_height = 0
			ball_height_velocity = -ball_height_velocity * 0.5  # 弹跳衰减
			if abs(ball_height_velocity) < 1.0:
				ball_height_velocity = 0

	# 球的旋转效果
	if ball_velocity.length() > 0.1:
		ball_mesh.rotate_axis(Vector3(-ball_velocity.z, 0, ball_velocity.x).normalized(),
			ball_velocity.length() * delta * 0.5)

# ============================================================
# 进球和出界判定
# ============================================================

func _check_goal():
	if ball_owner != null:
		return  # 有人控球时不判定

	var ball_pos = ball.position

	# 主队球门在 Z = -52.5，客队进球（客队得分）
	if ball_pos.z < -GameState.FIELD_LENGTH / 2 + 1:
		if abs(ball_pos.x) < GameState.GOAL_WIDTH / 2 and ball_height < GameState.GOAL_HEIGHT:
			# 客队进球
			away_score += 1
			_on_goal_scored(GameState.TeamSide.AWAY)
			return

	# 客队球门在 Z = +52.5，主队进球（主队得分）
	if ball_pos.z > GameState.FIELD_LENGTH / 2 - 1:
		if abs(ball_pos.x) < GameState.GOAL_WIDTH / 2 and ball_height < GameState.GOAL_HEIGHT:
			# 主队进球
			home_score += 1
			_on_goal_scored(GameState.TeamSide.HOME)
			return

func _on_goal_scored(scoring_side: int):
	match_phase = GameState.MatchPhase.GOAL
	goal_celebration_time = 3.0
	ball_owner = null

	var scorer = config.away_team_name if scoring_side == GameState.TeamSide.AWAY else config.home_team_name
	print("[Match] 进球！%s 得分  比分 %d-%d" % [scorer, home_score, away_score])

	# 显示进球提示
	var goal_label = Label.new()
	goal_label.text = "⚽ 进球！\n%s" % scorer
	goal_label.add_theme_font_size_override("font_size", 64)
	goal_label.add_theme_color_override("font_color", Color.YELLOW)
	goal_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	goal_label.add_theme_constant_override("shadow_offset_x", 3)
	goal_label.add_theme_constant_override("shadow_offset_y", 3)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal_label.size = get_viewport().get_visible_rect().size
	ui_canvas.add_child(goal_label)

	# 3秒后移除
	get_tree().create_timer(3.0).timeout.connect(func():
		goal_label.queue_free()
	)

func _check_out_of_bounds():
	if ball_owner != null:
		return

	var ball_pos = ball.position
	var half_w = GameState.FIELD_WIDTH / 2
	var half_l = GameState.FIELD_LENGTH / 2

	# 出边线（左右）
	if abs(ball_pos.x) > half_w:
		_on_ball_out("sideline")
		return

	# 出底线（前后）但不是进球
	if ball_pos.z < -half_l or ball_pos.z > half_l:
		_on_ball_out("goal_line")
		return

func _on_ball_out(line_type: String):
	match_phase = GameState.MatchPhase.BALL_OUT
	out_of_bounds_time = 1.5
	ball_owner = null

	# 简化处理：直接把球放回出界位置附近
	var ball_pos = ball.position
	var half_w = GameState.FIELD_WIDTH / 2
	var half_l = GameState.FIELD_LENGTH / 2

	# 限制球在球场内
	ball_pos.x = clamp(ball_pos.x, -half_w + 1, half_w - 1)
	ball_pos.z = clamp(ball_pos.z, -half_l + 1, half_l - 1)
	ball.position = ball_pos + Vector3(0, BALL_RADIUS, 0)
	ball_velocity = Vector3.ZERO
	ball_height = 0
	ball_height_velocity = 0

	print("[Match] 球出界 (%s)" % line_type)

func _resume_from_out():
	match_phase = GameState.MatchPhase.PLAYING
	_switch_active_player()

# ============================================================
# 玩家控制
# ============================================================

func _update_active_player_control():
	if active_player == null or not is_instance_valid(active_player):
		_switch_active_player()
		return

	# 读取输入
	input_vector = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1

	is_sprinting = Input.is_action_pressed("sprint")
	input_vector = input_vector.normalized()

	# 转换为3D方向（屏幕Y对应Z轴）
	var move_dir = Vector3(input_vector.x, 0, input_vector.y)

	# 设置活跃球员的输入
	active_player.set("input_direction", move_dir)
	active_player.set("is_sprinting", is_sprinting)
	active_player.set("is_player_controlled", true)

	# 动作按钮
	if Input.is_action_just_pressed("pass"):
		_do_pass()
	if Input.is_action_just_pressed("shoot"):
		_do_shoot()
	if Input.is_action_just_pressed("through_ball"):
		_do_through_ball()
	if Input.is_action_just_pressed("tackle"):
		_do_tackle()
	if Input.is_action_just_pressed("switch_player"):
		_switch_active_player()
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()

func _toggle_pause():
	if match_phase == GameState.MatchPhase.PLAYING:
		match_phase = GameState.MatchPhase.PAUSED
		pause_panel.visible = true
	elif match_phase == GameState.MatchPhase.PAUSED:
		match_phase = GameState.MatchPhase.PLAYING
		pause_panel.visible = false

func _switch_active_player():
	var team = home_players if player_side == GameState.TeamSide.HOME else away_players
	if team.is_empty():
		return

	# 找到最靠近球的非门将球员
	var best_player = null
	var best_dist = INF

	for p in team:
		if p.get("is_goalkeeper"):
			continue
		var dist = p.position.distance_to(ball.position)
		if dist < best_dist:
			best_dist = dist
			best_player = p

	# 如果没有非门将球员（异常情况），选门将
	if best_player == null and team.size() > 0:
		best_player = team[0]

	# 取消上一个活跃球员
	if active_player != null and is_instance_valid(active_player):
		active_player.set("is_active", false)
		active_player.set("is_player_controlled", false)

	active_player = best_player
	if active_player != null:
		active_player.set("is_active", true)
		# 高亮活跃球员
		_highlight_active_player()

func _highlight_active_player():
	# 给活跃球员加一个光环
	for p in home_players + away_players:
		var marker = p.get_node_or_null("ActiveMarker")
		if marker:
			marker.queue_free()

	if active_player:
		var marker = MeshInstance3D.new()
		marker.name = "ActiveMarker"
		var ring = TorusMesh.new()
		ring.inner_radius = 0.8
		ring.outer_radius = 1.0
		marker.mesh = ring
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.YELLOW
		mat.emission_enabled = true
		mat.emission = Color.YELLOW
		mat.emission_energy_multiplier = 1.5
		marker.material_override = mat
		marker.position = Vector3(0, 0.05, 0)
		marker.rotation_degrees.x = 90
		active_player.add_child(marker)

# ============================================================
# 球员动作
# ============================================================

func _do_pass():
	if ball_owner == null or ball_owner != active_player:
		return

	# 找最佳传球目标（同队最前方的球员）
	var team = home_players if ball_owner.get("team_side") == GameState.TeamSide.HOME else away_players
	var best_target = null
	var best_score = -INF

	for p in team:
		if p == ball_owner:
			continue
		# 优先向前传球
		var forward_dir = 1 if ball_owner.get("team_side") == GameState.TeamSide.HOME else -1
		var forward_score = (p.position.z - ball_owner.position.z) * forward_dir
		var dist = ball_owner.position.distance_to(p.position)

		# 距离适中（5-30米）且前方
		if dist > 3 and dist < 35:
			var score = forward_score - dist * 0.3
			if score > best_score:
				best_score = score
				best_target = p

	if best_target == null:
		# 没有好的传球目标，短传给最近的队友
		var min_dist = INF
		for p in team:
			if p == ball_owner:
				continue
			var dist = ball_owner.position.distance_to(p.position)
			if dist < min_dist and dist > 2:
				min_dist = dist
				best_target = p

	if best_target:
		var dir = (best_target.position - ball_owner.position)
		dir.y = 0
		dir = dir.normalized()

		# 加入一些提前量（传到目标前方）
		var target_pos = best_target.position + dir * 2
		var pass_dir = (target_pos - ball_owner.position)
		pass_dir.y = 0
		pass_dir = pass_dir.normalized()

		ball_velocity = pass_dir * PASS_SPEED
		ball_height_velocity = 2.0  # 轻微挑起
		ball_owner = null
		last_touch_team = ball_owner.get("team_side") if ball_owner else -1

		# 统计
		var stats = SaveManager.load_data().get("stats", {})
		stats["total_passes"] = stats.get("total_passes", 0) + 1
		SaveManager.save_data({"stats": stats} if false else SaveManager.load_data())

func _do_shoot():
	if ball_owner == null or ball_owner != active_player:
		return

	# 射门方向：朝对方球门
	var target_goal_z = GameState.FIELD_LENGTH / 2 if ball_owner.get("team_side") == GameState.TeamSide.HOME else -GameState.FIELD_LENGTH / 2
	var dir = Vector3(
		randf_range(-3, 3) - ball_owner.position.x * 0.1,  # 瞄准球门中心附近
		0,
		target_goal_z - ball_owner.position.z
	)
	dir = dir.normalized()

	# 射门力度受距离影响
	var dist_to_goal = abs(ball_owner.position.z - target_goal_z)
	var power = SHOT_SPEED
	if dist_to_goal > 25:
		power *= 1.1  # 远射加力

	ball_velocity = dir * power
	ball_height_velocity = 3.0  # 射门球会飞起
	ball_owner = null

	# 统计
	var data = SaveManager.load_data()
	data["stats"]["total_shots"] = data["stats"].get("total_shots", 0) + 1
	SaveManager.save_data(data)

	print("[Match] 射门！力度=%.1f 方向=%s" % [power, dir])

func _do_through_ball():
	if ball_owner == null or ball_owner != active_player:
		return

	# 直塞球：传到队友前方空当
	var team = home_players if ball_owner.get("team_side") == GameState.TeamSide.HOME else away_players
	var forward_dir = 1 if ball_owner.get("team_side") == GameState.TeamSide.HOME else -1

	var best_target = null
	var best_score = -INF

	for p in team:
		if p == ball_owner:
			continue
		var forward_score = (p.position.z - ball_owner.position.z) * forward_dir
		var dist = ball_owner.position.distance_to(p.position)
		if dist > 5 and dist < 40 and forward_score > 5:
			if forward_score > best_score:
				best_score = forward_score
				best_target = p

	if best_target:
		# 传到队友前方更远的位置
		var lead = Vector3(0, 0, forward_dir * 5)
		var target_pos = best_target.position + lead
		var dir = (target_pos - ball_owner.position)
		dir.y = 0
		dir = dir.normalized()

		ball_velocity = dir * (PASS_SPEED * 1.2)
		ball_height_velocity = 1.0
		ball_owner = null

func _do_tackle():
	if active_player == null:
		return

	# 检查附近是否有对方控球者
	var opp_team = away_players if active_player.get("team_side") == GameState.TeamSide.HOME else home_players
	var tackle_radius = active_player.get("stats").tackle_radius

	for p in opp_team:
		var dist = active_player.position.distance_to(p.position)
		if dist < tackle_radius:
			# 抢断判定
			var success_chance = ai_params.tackle_success
			if randf() < success_chance:
				# 抢断成功
				if ball_owner == p:
					ball_owner = null
				# 球弹向抢断者前方
				var dir = (ball.position - active_player.position)
				dir.y = 0
				dir = dir.normalized()
				ball_velocity = dir * 8.0
				ball_height_velocity = 1.0

				# 统计
				var data = SaveManager.load_data()
				data["stats"]["total_tackles"] = data["stats"].get("total_tackles", 0) + 1
				SaveManager.save_data(data)

				print("[Match] 抢断成功！")
				return
			else:
				print("[Match] 抢断失败")
				return

# ============================================================
# AI 更新
# ============================================================

func _update_ai(delta):
	# 更新所有非玩家控制的球员
	_update_team_ai(home_players, GameState.TeamSide.HOME, delta)
	_update_team_ai(away_players, GameState.TeamSide.AWAY, delta)

func _update_team_ai(team: Array, side: int, delta: int):
	var has_ball = _team_has_ball(side)
	var ball_side = _get_ball_side()

	# 球队战术决策
	var tactic = _decide_tactic(side, has_ball, ball_side)

	for p in team:
		if p == active_player and p.get("is_player_controlled"):
			continue  # 玩家控制的球员跳过AI
		if not is_instance_valid(p):
			continue

		_update_player_ai(p, side, has_ball, tactic, delta)

func _team_has_ball(side: int) -> bool:
	if ball_owner == null:
		return false
	return ball_owner.get("team_side") == side

func _get_ball_side() -> int:
	# 返回球更靠近哪一方
	if ball.position.z < 0:
		return GameState.TeamSide.HOME
	return GameState.TeamSide.AWAY

func _decide_tactic(side: int, has_ball: bool, ball_side: int) -> Dictionary:
	# 球队战术：进攻、平衡、防守
	var tactic = {
		"mode": "balance",  # attack / balance / defend
		"press": false,     # 是否高位逼抢
	}

	var forward_dir = 1 if side == GameState.TeamSide.HOME else -1
	var ball_in_own_half = (ball.position.z * forward_dir) < 0

	if has_ball:
		tactic.mode = "attack"
	elif ball_side == side:
		# 球在本方半场但没控球
		tactic.mode = "defend"
		tactic.press = true
	else:
		# 球在对方半场
		tactic.mode = "balance"
		tactic.press = ai_params.press_intensity > 0.5

	# 活动修正：落后时增加压迫
	var event_mods = GameState.current_event.get("modifiers", {})
	if event_mods.get("ai_defensive_mode", false):
		tactic.mode = "defend"

	return tactic

func _update_player_ai(player: Node, side: int, team_has_ball: bool, tactic: Dictionary, delta: float):
	var home_pos = player.get("home_position")
	if side == GameState.TeamSide.AWAY:
		home_pos = Vector3(-home_pos.x, 0, -home_pos.z)

	var ball_pos = ball.position
	var to_ball = ball_pos - player.position
	to_ball.y = 0
	var dist_to_ball = to_ball.length()

	var stats = player.get("stats")
	var speed = stats.speed * ai_params.chase_speed_mult
	var is_gk = player.get("is_goalkeeper")

	# 控球检测
	if ball_owner == null and dist_to_ball < stats.control_radius and ball_height < 1.5:
		# 检查谁更近
		var nearest = _get_nearest_player_to_ball()
		if nearest == player:
			ball_owner = player
			player.set("has_ball", true)
			last_touch_team = side

	var move_dir = Vector3.ZERO

	if ball_owner == player:
		# 控球AI
		move_dir = _ai_dribble(player, side, tactic)
		player.set("input_direction", move_dir)
		player.set("is_sprinting", false)

		# AI传球/射门决策
		_ai_decide_action(player, side, tactic)
	elif is_gk:
		# 门将AI
		move_dir = _ai_goalkeeper(player, side)
		player.set("input_direction", move_dir)
		player.set("is_sprinting", false)
	else:
		# 非控球球员AI
		if team_has_ball:
			# 本队有球：跑位
			move_dir = _ai_off_ball_attack(player, side, tactic)
		else:
			# 本队无球：防守
			if _is_closest_defender(player, side) and dist_to_ball < 20:
				# 最近的球员去追球
				move_dir = to_ball.normalized()
				player.set("is_sprinting", dist_to_ball > 5)
			else:
				# 其他球员回防或保持阵型
				move_dir = _ai_defend_position(player, side, tactic)

		player.set("input_direction", move_dir)

func _ai_dribble(player: Node, side: int, tactic: Dictionary) -> Vector3:
	# 控球时带球前进
	var forward_dir = 1 if side == GameState.TeamSide.HOME else -1
	var target_goal_z = GameState.FIELD_LENGTH / 2 * forward_dir

	# 朝对方球门方向移动
	var to_goal = Vector3(0, 0, target_goal_z) - player.position
	to_goal.y = 0

	# 避开对方球员
	var opp_team = away_players if side == GameState.TeamSide.HOME else home_players
	var avoid = Vector3.ZERO
	for opp in opp_team:
		var to_opp = opp.position - player.position
		to_opp.y = 0
		var d = to_opp.length()
		if d < 5 and d > 0:
			avoid -= to_opp.normalized() * (5 - d) / 5

	var move = to_goal.normalized() + avoid * 0.5
	return move.normalized()

func _ai_decide_action(player: Node, side: int, tactic: Dictionary):
	# AI决策：传球、射门或继续带球
	var target_goal_z = GameState.FIELD_LENGTH / 2 * (1 if side == GameState.TeamSide.HOME else -1)
	var dist_to_goal = abs(player.position.z - target_goal_z)

	# 射门判定
	if dist_to_goal < 25 and abs(player.position.x) < 25:
		if randf() < 0.02 * (1 + (25 - dist_to_goal) / 25):
			_ai_shoot(player, side)
			return

	# 传球判定
	if randf() < 0.015:
		_ai_pass(player, side)
		return

func _ai_shoot(player: Node, side: int):
	var target_goal_z = GameState.FIELD_LENGTH / 2 * (1 if side == GameState.TeamSide.HOME else -1)
	var dir = Vector3(
		randf_range(-3, 3) - player.position.x * 0.05,
		0,
		target_goal_z - player.position.z
	).normalized()

	var accuracy = ai_params.shot_accuracy
	var power = SHOT_SPEED * randf_range(0.8, 1.0)
	# 不准时偏移
	if randf() > accuracy:
		dir.x += randf_range(-0.3, 0.3)
		dir = dir.normalized()

	ball_velocity = dir * power
	ball_height_velocity = 3.0
	ball_owner = null
	last_touch_team = side

func _ai_pass(player: Node, side: int):
	var team = home_players if side == GameState.TeamSide.HOME else away_players
	var forward_dir = 1 if side == GameState.TeamSide.HOME else -1

	var best_target = null
	var best_score = -INF

	for p in team:
		if p == player:
			continue
		var forward_score = (p.position.z - player.position.z) * forward_dir
		var dist = player.position.distance_to(p.position)
		if dist > 3 and dist < 35:
			var score = forward_score - dist * 0.2
			if score > best_score:
				best_score = score
				best_target = p

	if best_target:
		var dir = (best_target.position - player.position)
		dir.y = 0
		# 传球准确率
		if randf() > ai_params.pass_accuracy:
			dir.x += randf_range(-0.3, 0.3)
			dir.z += randf_range(-0.3, 0.3)
		dir = dir.normalized()

		ball_velocity = dir * PASS_SPEED
		ball_height_velocity = 1.5
		ball_owner = null
		last_touch_team = side

func _ai_goalkeeper(player: Node, side: int) -> Vector3:
	# 门将守在球门前，跟随球的横向位置
	var goal_z = -GameState.FIELD_LENGTH / 2 if side == GameState.TeamSide.HOME else GameState.FIELD_LENGTH / 2
	var target_x = clamp(ball.position.x * 0.3, -GameState.GOAL_WIDTH, GameState.GOAL_WIDTH)
	var target = Vector3(target_x, 0, goal_z + (3 if side == GameState.TeamSide.HOME else -3))

	# 如果球很近且在禁区，出击
	var dist_to_ball = player.position.distance_to(ball.position)
	if dist_to_ball < 8 and ball_height < 2:
		target = ball.position

	var dir = target - player.position
	dir.y = 0
	return dir.normalized() if dir.length() > 0.5 else Vector3.ZERO

func _ai_off_ball_attack(player: Node, side: int, tactic: Dictionary) -> Vector3:
	# 无球进攻：向前跑位
	var forward_dir = 1 if side == GameState.TeamSide.HOME else -1
	var home_pos = player.get("home_position")
	if side == GameState.TeamSide.AWAY:
		home_pos = Vector3(-home_pos.x, 0, -home_pos.z)

	# 向前压上
	var target = home_pos + Vector3(0, 0, forward_dir * 10)
	var dir = target - player.position
	dir.y = 0
	return dir.normalized() if dir.length() > 1 else Vector3.ZERO

func _ai_defend_position(player: Node, side: int, tactic: Dictionary) -> Vector3:
	# 防守站位：回到本方半场，在球和球门之间
	var home_pos = player.get("home_position")
	if side == GameState.TeamSide.AWAY:
		home_pos = Vector3(-home_pos.x, 0, -home_pos.z)

	# 根据球的位置调整站位
	var target = home_pos
	target.x = lerp(home_pos.x, ball.position.x * 0.5, 0.3)

	var dir = target - player.position
	dir.y = 0
	return dir.normalized() if dir.length() > 1 else Vector3.ZERO

func _is_closest_defender(player: Node, side: int) -> bool:
	var team = home_players if side == GameState.TeamSide.HOME else away_players
	var min_dist = INF
	var closest = null
	for p in team:
		if p.get("is_goalkeeper"):
			continue
		var d = p.position.distance_to(ball.position)
		if d < min_dist:
			min_dist = d
			closest = p
	return closest == player

func _get_nearest_player_to_ball() -> Node:
	var all_players = home_players + away_players
	var nearest = null
	var min_dist = INF
	for p in all_players:
		if not is_instance_valid(p):
			continue
		var d = p.position.distance_to(ball.position)
		if d < min_dist:
			min_dist = d
			nearest = p
	return nearest

# ============================================================
# 体力系统
# ============================================================

func _update_stamina(delta):
	for p in home_players + away_players:
		if not is_instance_valid(p):
			continue
		var stats = p.get("stats")
		var current = p.get("current_stamina", stats.stamina)
		if p.get("is_sprinting", false):
			current -= stats.stamina_drain * delta
		else:
			current += stats.stamina_recover * delta
		current = clamp(current, 0, stats.stamina)
		p.set("current_stamina", current)

# ============================================================
# 摄像机
# ============================================================

func _update_camera(delta):
	# 摄像机跟随球或活跃球员
	var target = ball.position
	if active_player and is_instance_valid(active_player):
		# 在球和活跃球员之间取中点
		target = (ball.position + active_player.position) / 2

	# 平滑移动
	var cam_settings = SaveManager.get_settings()
	var cam_mode = cam_settings.get("camera_mode", "follow")

	match cam_mode:
		"follow":
			var desired_pos = target + Vector3(0, CAMERA_HEIGHT, -CAMERA_DISTANCE)
			camera.position = camera.position.lerp(desired_pos, delta * 3)
			camera.look_at(target + Vector3(0, 0, 5), Vector3.UP)
		"fixed":
			camera.position = Vector3(0, CAMERA_HEIGHT, -CAMERA_DISTANCE - 10)
			camera.look_at(Vector3(0, 0, 0), Vector3.UP)
		"broadcast":
			# 广播视角：更高更远
			var desired_pos = target + Vector3(0, CAMERA_HEIGHT * 1.5, -CAMERA_DISTANCE * 1.3)
			camera.position = camera.position.lerp(desired_pos, delta * 2)
			camera.look_at(target, Vector3.UP)

# ============================================================
# UI 更新
# ============================================================

func _update_ui():
	score_label.text = "%d - %d" % [home_score, away_score]

	var remaining = max(0, half_duration - match_time)
	var minutes = int(remaining / 60)
	var seconds = int(remaining) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

	# 接近结束时显示加时
	if remaining < 30 and match_phase == GameState.MatchPhase.PLAYING:
		time_label.add_theme_color_override("font_color", Color.RED)
	else:
		time_label.add_theme_color_override("font_color", Color.YELLOW)

# ============================================================
# 局域网输入处理
# ============================================================

func _handle_remote_input(sender_id: int, input_data: Dictionary):
	# 房主收到客户端的输入
	# 简化实现：客户端控制客队
	if not config.get("is_lan_match", false) or not NetworkManager.is_host:
		return

	# 将远程输入应用到客队活跃球员
	var remote_input = input_data.get("input_vector", Vector2.ZERO)
	var remote_sprint = input_data.get("sprint", false)
	var remote_actions = input_data.get("actions", [])

	# 找到客队最靠近球的球员作为活跃球员
	var away_active = null
	var min_dist = INF
	for p in away_players:
		if p.get("is_goalkeeper"):
			continue
		var d = p.position.distance_to(ball.position)
		if d < min_dist:
			min_dist = d
			away_active = p

	if away_active:
		var move_dir = Vector3(remote_input.x, 0, remote_input.y)
		away_active.set("input_direction", move_dir)
		away_active.set("is_sprinting", remote_sprint)
		away_active.set("is_player_controlled", true)

		# 处理动作
		for action in remote_actions:
			match action:
				"pass": _do_pass_for(away_active)
				"shoot": _do_shoot_for(away_active)
				"tackle": _do_tackle_for(away_active)

func _do_pass_for(player: Node):
	if ball_owner != player:
		return
	var team = away_players if player.get("team_side") == GameState.TeamSide.AWAY else home_players
	var best_target = null
	var best_score = -INF
	for p in team:
		if p == player:
			continue
		var forward_dir = 1 if player.get("team_side") == GameState.TeamSide.HOME else -1
		var forward_score = (p.position.z - player.position.z) * forward_dir
		var dist = player.position.distance_to(p.position)
		if dist > 3 and dist < 35:
			var score = forward_score - dist * 0.3
			if score > best_score:
				best_score = score
				best_target = p
	if best_target:
		var dir = (best_target.position - player.position)
		dir.y = 0
		dir = dir.normalized()
		ball_velocity = dir * PASS_SPEED
		ball_height_velocity = 2.0
		ball_owner = null

func _do_shoot_for(player: Node):
	if ball_owner != player:
		return
	var target_goal_z = GameState.FIELD_LENGTH / 2 if player.get("team_side") == GameState.TeamSide.HOME else -GameState.FIELD_LENGTH / 2
	var dir = Vector3(randf_range(-3, 3) - player.position.x * 0.1, 0, target_goal_z - player.position.z).normalized()
	ball_velocity = dir * SHOT_SPEED
	ball_height_velocity = 3.0
	ball_owner = null

func _do_tackle_for(player: Node):
	var opp_team = home_players if player.get("team_side") == GameState.TeamSide.AWAY else away_players
	var tackle_radius = player.get("stats").tackle_radius
	for p in opp_team:
		var dist = player.position.distance_to(p.position)
		if dist < tackle_radius:
			if randf() < ai_params.tackle_success:
				if ball_owner == p:
					ball_owner = null
				var dir = (ball.position - player.position)
				dir.y = 0
				dir = dir.normalized()
				ball_velocity = dir * 8.0
				ball_height_velocity = 1.0
				return
