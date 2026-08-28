## match.gd
## 比赛核心控制器（增强版 v0.2）
##
## 新增功能：
##   - 乌龙球判定
##   - 门将可出击踢球
##   - 改进的球员切换（11v11任意切换）
##   - 传中、挑球、挑射、远射、搓射、电梯球
##   - 2过1配合
##   - 任意球（含人墙）、角球、界外球、球门球
##   - 裁判系统（犯规、黄红牌、点球）
##   - 开球序列
##   - 帽子戏法/世界波追踪
##   - 改进的碰撞和寻路逻辑
##
## 视角：俯视角3D（类似最佳球会的斜俯视角）
extends Node3D

# ---- 场景节点 ----
var camera: Camera3D
var field: MeshInstance3D
var ball: CharacterBody3D
var ball_mesh: MeshInstance3D
var ball_shadow: MeshInstance3D

# ---- 球队数据 ----
var home_players: Array = []
var away_players: Array = []
var home_score: int = 0
var away_score: int = 0
var home_team_id: String = ""
var away_team_id: String = ""

# ---- 进球追踪 ----
var home_scorers: Array = []  # [{player_id, minute, type, is_own_goal}]
var away_scorers: Array = []
var hat_trick_tracker: Dictionary = {}  # player_id -> goal_count

# ---- 当前控制 ----
var active_player: CharacterBody3D = null
var player_side: int = GameState.TeamSide.HOME
var active_player_index: int = 0  # 玩家手动切换的球员索引

# ---- 比赛状态 ----
var match_phase: int = GameState.MatchPhase.KICKOFF
var match_time: float = 0.0
var current_half: int = 1
var half_duration: float = 180.0
var goal_celebration_time: float = 0.0
var out_of_bounds_time: float = 0.0
var last_touch_team: int = -1
var last_touch_player: CharacterBody3D = null

# ---- 定位球状态 ----
var set_piece_type: int = Referee.SetPieceType.NONE
var set_piece_team: int = -1
var set_piece_position: Vector3 = Vector3.ZERO
var set_piece_ready: bool = false
var wall_players: Array = []  # 人墙球员列表

# ---- 比赛配置 ----
var config: Dictionary
var ai_params: Dictionary

# ---- 球的物理状态 ----
var ball_velocity: Vector3 = Vector3.ZERO
var ball_height: float = 0.0
var ball_height_velocity: float = 0.0
var ball_owner: CharacterBody3D = null
var ball_spin: float = 0.0  # 球的旋转（用于搓射/电梯球）
var ball_shot_type: String = ""  # 射门类型记录

# ---- UI节点 ----
var ui_canvas: CanvasLayer
var score_label: Label
var time_label: Label
var phase_label: Label
var control_hint: Label
var pause_panel: Panel
var result_panel: Panel
var event_notification: Label  # 事件通知（进球、犯规等）
var scorer_list_label: Label   # 进球名单
var stats_label: Label         # 比赛统计

# ---- 输入 ----
var input_vector: Vector2 = Vector2.ZERO
var is_sprinting: bool = false

# ---- 常量 ----
const BALL_RADIUS: float = 0.11
const PLAYER_RADIUS: float = 0.4
const BALL_FRICTION: float = 0.5
const BALL_AIR_DRAG: float = 0.15
const BALL_GRAVITY: float = 9.8
const PASS_SPEED: float = 18.0
const SHOT_SPEED: float = 28.0
const LOB_SPEED: float = 12.0
const CROSS_SPEED: float = 20.0
const LONG_SHOT_SPEED: float = 32.0
const CAMERA_HEIGHT: float = 45.0
const CAMERA_DISTANCE: float = 30.0
const CAMERA_ANGLE: float = 55.0

func _ready():
	config = GameState.current_match_config
	ai_params = GameState.get_ai_params()
	half_duration = config.get("half_duration", 180.0)
	player_side = config.get("player_controls", GameState.TeamSide.HOME)
	home_score = config.get("initial_score", [0, 0])[0]
	away_score = config.get("initial_score", [0, 0])[1]
	home_team_id = config.get("home_team_id", "home")
	away_team_id = config.get("away_team_id", "away")

	Referee.reset_match_stats()

	_setup_lighting()
	_setup_field()
	_setup_camera()
	_setup_teams()
	_setup_ball()
	_setup_ui()

	# 设置网络输入处理器
	NetworkManager.set_remote_input_handler(_handle_remote_input)

	# 开球
	_kickoff()

func _process(delta):
	match match_phase:
		GameState.MatchPhase.PLAYING:
			match_time += delta
			if match_time >= half_duration:
				_end_half()
			_update_player_input()
			_update_ai(delta)
		GameState.MatchPhase.GOAL:
			goal_celebration_time -= delta
			if goal_celebration_time <= 0:
				_kickoff()
		GameState.MatchPhase.BALL_OUT:
			out_of_bounds_time -= delta
			if out_of_bounds_time <= 0:
				_resume_from_out()
		GameState.MatchPhase.KICKOFF:
			# 开球前短暂等待
			out_of_bounds_time -= delta
			if out_of_bounds_time <= 0:
				match_phase = GameState.MatchPhase.PLAYING
		GameState.MatchPhase.PAUSED:
			pass

	_update_camera(delta)
	_update_ui()

func _physics_process(delta):
	if match_phase == GameState.MatchPhase.PLAYING or match_phase == GameState.MatchPhase.KICKOFF:
		_update_ball_physics(delta)
		_check_collisions()
		_check_bounds_and_goals()

# ============================================================
# 场景搭建
# ============================================================

func _setup_lighting():
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

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.shadow_map_resolution = 2048
	add_child(sun)

func _setup_field():
	field = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(GameState.FIELD_LENGTH + 10, GameState.FIELD_WIDTH + 10)
	plane.material = _create_field_material()
	field.mesh = plane
	add_child(field)
	_create_field_lines()
	_create_goal(Vector3(0, 0, -GameState.FIELD_LENGTH / 2), GameState.TeamSide.HOME)
	_create_goal(Vector3(0, 0, GameState.FIELD_LENGTH / 2), GameState.TeamSide.AWAY)
	_create_stands()

func _create_field_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.45, 0.15)
	mat.roughness = 0.9
	return mat

func _create_field_lines():
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color.WHITE
	line_mat.emission_enabled = true
	line_mat.emission = Color(0.8, 0.8, 0.8)
	line_mat.emission_energy_multiplier = 0.3

	# 球场边界
	_create_line(Vector3(0, 0.01, -GameState.FIELD_WIDTH/2), Vector3(GameState.FIELD_LENGTH, 0.1, 0.15), line_mat)
	_create_line(Vector3(0, 0.01, GameState.FIELD_WIDTH/2), Vector3(GameState.FIELD_LENGTH, 0.1, 0.15), line_mat)
	_create_line(Vector3(-GameState.FIELD_LENGTH/2, 0.01, 0), Vector3(0.15, 0.1, GameState.FIELD_WIDTH), line_mat)
	_create_line(Vector3(GameState.FIELD_LENGTH/2, 0.01, 0), Vector3(0.15, 0.1, GameState.FIELD_WIDTH), line_mat)

	# 中线
	_create_line(Vector3(0, 0.01, 0), Vector3(0.15, 0.1, GameState.FIELD_WIDTH), line_mat)

	# 中圈
	var circle = MeshInstance3D.new()
	var circle_mesh = CylinderMesh.new()
	circle_mesh.top_radius = 9.15
	circle_mesh.bottom_radius = 9.15
	circle_mesh.height = 0.05
	circle.mesh = circle_mesh
	circle.material_override = line_mat
	circle.position = Vector3(0, 0.01, 0)
	# 只显示圆环（简化处理）
	add_child(circle)

	# 禁区
	var pa_depth = GameState.PENALTY_AREA_DEPTH
	var pa_width = GameState.PENALTY_AREA_WIDTH
	# 主队禁区
	_create_line(Vector3(-pa_width/2, 0.01, -GameState.FIELD_LENGTH/2), Vector3(pa_width, 0.1, 0.15), line_mat)
	_create_line(Vector3(-pa_width/2, 0.01, -GameState.FIELD_LENGTH/2 + pa_depth), Vector3(pa_width, 0.1, 0.15), line_mat)
	_create_line(Vector3(-pa_width/2, 0.01, -GameState.FIELD_LENGTH/2), Vector3(0.15, 0.1, pa_depth), line_mat)
	_create_line(Vector3(pa_width/2, 0.01, -GameState.FIELD_LENGTH/2), Vector3(0.15, 0.1, pa_depth), line_mat)
	# 客队禁区
	_create_line(Vector3(-pa_width/2, 0.01, GameState.FIELD_LENGTH/2), Vector3(pa_width, 0.1, 0.15), line_mat)
	_create_line(Vector3(-pa_width/2, 0.01, GameState.FIELD_LENGTH/2 - pa_depth), Vector3(pa_width, 0.1, 0.15), line_mat)
	_create_line(Vector3(-pa_width/2, 0.01, GameState.FIELD_LENGTH/2), Vector3(0.15, 0.1, pa_depth), line_mat)
	_create_line(Vector3(pa_width/2, 0.01, GameState.FIELD_LENGTH/2), Vector3(0.15, 0.1, pa_depth), line_mat)

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
	goal_mat.emission = Color.WHITE
	goal_mat.emission_energy_multiplier = 0.5

	# 球门柱
	var post_left = MeshInstance3D.new()
	var post_mesh = CylinderMesh.new()
	post_mesh.top_radius = 0.06
	post_mesh.bottom_radius = 0.06
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
	var bar_mesh = CylinderMesh.new()
	bar_mesh.top_radius = 0.06
	bar_mesh.bottom_radius = 0.06
	bar_mesh.height = GameState.GOAL_WIDTH
	crossbar.mesh = bar_mesh
	crossbar.material_override = goal_mat
	crossbar.position = pos + Vector3(0, GameState.GOAL_HEIGHT, 0)
	crossbar.rotate_x(deg_to_rad(90))
	add_child(crossbar)

	# 球网（简化）
	var net = MeshInstance3D.new()
	var net_mesh = BoxMesh.new()
	net_mesh.size = Vector3(GameState.GOAL_WIDTH, GameState.GOAL_HEIGHT, 2.0)
	net.mesh = net_mesh
	var net_mat = StandardMaterial3D.new()
	net_mat.albedo_color = Color(1, 1, 1, 0.2)
	net_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	net.material_override = net_mat
	var net_z = 1.5 if side == GameState.TeamSide.HOME else -1.5
	net.position = pos + Vector3(0, GameState.GOAL_HEIGHT/2, net_z)
	add_child(net)

func _create_stands():
	var stand_mat = StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.2, 0.2, 0.25)
	for i in range(4):
		var stand = MeshInstance3D.new()
		var box = BoxMesh.new()
		match i:
			0:
				box.size = Vector3(GameState.FIELD_WIDTH + 20, 8, 5)
				stand.position = Vector3(0, 4, -GameState.FIELD_LENGTH/2 - 10)
			1:
				box.size = Vector3(GameState.FIELD_WIDTH + 20, 8, 5)
				stand.position = Vector3(0, 4, GameState.FIELD_LENGTH/2 + 10)
			2:
				box.size = Vector3(5, 8, GameState.FIELD_LENGTH + 20)
				stand.position = Vector3(GameState.FIELD_WIDTH/2 + 10, 4, 0)
			3:
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
	camera.position = target + Vector3(0, CAMERA_HEIGHT, -CAMERA_DISTANCE)
	camera.look_at(target + Vector3(0, 0, 5), Vector3.UP)

func _update_camera(delta):
	# 摄像机跟随球
	if ball:
		var target = ball.position
		var desired_pos = target + Vector3(0, CAMERA_HEIGHT, -CAMERA_DISTANCE)
		camera.position = camera.position.lerp(desired_pos, delta * 3)
		camera.look_at(target + Vector3(0, 0, 5), Vector3.UP)

func _setup_teams():
	var formation = GameState.get_formation(config.get("formation", "4-4-2"))
	home_players = _create_team(formation, GameState.TeamSide.HOME, home_team_id)
	away_players = _create_team(formation, GameState.TeamSide.AWAY, away_team_id)
	_switch_active_player()

func _create_team(formation: Array, side: int, team_id: String) -> Array:
	var players = []
	var team_data = TeamDatabase.get_team(team_id)
	var team_name = team_data.get("name", "Team")
	var team_colors = TeamDatabase.get_team_colors(team_id)
	var player_ids = team_data.get("players", [])

	for i in range(formation.size()):
		var role_data = formation[i]
		var role = role_data[0]
		var x = role_data[1]
		var z = role_data[2]

		if side == GameState.TeamSide.AWAY:
			z = -z

		var player = CharacterBody3D.new()
		player.set_script(load("res://scripts/player_controller.gd"))

		# 设置球员属性
		player.team_side = side
		player.team_id = team_id
		player.team_name = team_name
		player.role = role
		player.player_index = i + 1
		player.is_goalkeeper = (role == "GK")

		# 从数据库加载球员ID
		if i < player_ids.size():
			player.player_id = player_ids[i]

		# 创建视觉
		_create_player_visual(player, team_colors, side)

		player.position = Vector3(x, 0, z)
		player.home_position = Vector3(x, 0, z)
		add_child(player)
		players.append(player)

	return players

func _create_player_visual(player: CharacterBody3D, colors: Dictionary, side: int):
	# 身体（胶囊体）
	var body = MeshInstance3D.new()
	var body_mesh = CapsuleMesh.new()
	body_mesh.radius = 0.4
	body_mesh.height = 1.8
	body.mesh = body_mesh
	body.name = "MeshInstance3D"

	var mat = StandardMaterial3D.new()
	mat.albedo_color = colors.primary
	mat.emission_enabled = true
	mat.emission = colors.primary
	mat.emission_energy_multiplier = 0.2
	body.material_override = mat
	body.position = Vector3(0, 0.9, 0)
	player.add_child(body)

	# 号码标签
	var number_label = Label3D.new()
	number_label.name = "Label3D"
	number_label.text = str(player.player_index)
	number_label.font_size = 48
	number_label.outline_size = 12
	number_label.outline_modulate = Color.BLACK
	number_label.position = Vector3(0, 2.2, 0)
	number_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	player.add_child(number_label)

	# 方向箭头（活跃球员指示）
	var arrow = MeshInstance3D.new()
	var arrow_mesh = ConeMesh.new()
	arrow_mesh.top_radius = 0
	arrow_mesh.bottom_radius = 0.3
	arrow_mesh.height = 0.6
	arrow.mesh = arrow_mesh
	arrow.name = "MeshInstance3D3"
	var arrow_mat = StandardMaterial3D.new()
	arrow_mat.albedo_color = Color.YELLOW
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color.YELLOW
	arrow_mat.emission_energy_multiplier = 1.0
	arrow.material_override = arrow_mat
	arrow.position = Vector3(0, 2.5, 0)
	arrow.visible = false
	player.add_child(arrow)

func _setup_ball():
	ball = CharacterBody3D.new()
	ball.name = "Ball"

	ball_mesh = MeshInstance3D.new()
	var ball_m = SphereMesh.new()
	ball_m.radius = BALL_RADIUS
	ball_m.height = BALL_RADIUS * 2
	ball_mesh.mesh = ball_m
	var ball_mat = StandardMaterial3D.new()
	ball_mat.albedo_color = Color.WHITE
	ball_mat.emission_enabled = true
	ball_mat.emission = Color(0.9, 0.9, 0.9)
	ball_mat.emission_energy_multiplier = 0.3
	ball_mesh.material_override = ball_mat
	ball.add_child(ball_mesh)

	ball_shadow = MeshInstance3D.new()
	var shadow_m = CircleMesh.new()
	shadow_m.radius = BALL_RADIUS * 1.5
	ball_shadow.mesh = shadow_m
	var shadow_mat = StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.4)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ball_shadow.material_override = shadow_mat
	ball_shadow.position = Vector3(0, 0.01, 0)
	ball_shadow.rotation = Vector3(deg_to_rad(90), 0, 0)
	add_child(ball_shadow)

	ball.position = Vector3(0, 0, 0)
	add_child(ball)

# ============================================================
# UI
# ============================================================

func _setup_ui():
	ui_canvas = CanvasLayer.new()
	add_child(ui_canvas)

	# 比分
	score_label = Label.new()
	score_label.text = "0 - 0"
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vp_size = get_viewport().get_visible_rect().size
	score_label.position = Vector2(vp_size.x / 2 - 60, 10)
	score_label.size = Vector2(120, 60)
	ui_canvas.add_child(score_label)

	# 队名
	var team_names = Label.new()
	team_names.text = "%s  vs  %s" % [
		TeamDatabase.get_team_short_name(home_team_id),
		TeamDatabase.get_team_short_name(away_team_id)
	]
	team_names.add_theme_font_size_override("font_size", 20)
	team_names.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	team_names.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_names.position = Vector2(vp_size.x / 2 - 150, 70)
	team_names.size = Vector2(300, 25)
	ui_canvas.add_child(team_names)

	# 时间
	time_label = Label.new()
	time_label.text = "00:00"
	time_label.add_theme_font_size_override("font_size", 36)
	time_label.add_theme_color_override("font_color", Color.YELLOW)
	time_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.position = Vector2(vp_size.x / 2 - 50, 95)
	time_label.size = Vector2(100, 45)
	ui_canvas.add_child(time_label)

	# 半场指示
	phase_label = Label.new()
	phase_label.text = "上半场"
	phase_label.add_theme_font_size_override("font_size", 16)
	phase_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.position = Vector2(vp_size.x / 2 - 50, 140)
	phase_label.size = Vector2(100, 20)
	ui_canvas.add_child(phase_label)

	# 事件通知（进球、犯规等）
	event_notification = Label.new()
	event_notification.text = ""
	event_notification.add_theme_font_size_override("font_size", 32)
	event_notification.add_theme_color_override("font_color", Color.YELLOW)
	event_notification.add_theme_color_override("font_shadow_color", Color.BLACK)
	event_notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_notification.position = Vector2(vp_size.x / 2 - 200, 180)
	event_notification.size = Vector2(400, 50)
	event_notification.visible = false
	ui_canvas.add_child(event_notification)

	# 进球名单
	scorer_list_label = Label.new()
	scorer_list_label.text = ""
	scorer_list_label.add_theme_font_size_override("font_size", 14)
	scorer_list_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	scorer_list_label.position = Vector2(10, 10)
	scorer_list_label.size = Vector2(200, 300)
	ui_canvas.add_child(scorer_list_label)

	# 比赛统计
	stats_label = Label.new()
	stats_label.text = ""
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_label.position = Vector2(vp_size.x - 210, 10)
	stats_label.size = Vector2(200, 300)
	ui_canvas.add_child(stats_label)

	# 操作提示
	control_hint = Label.new()
	control_hint.text = "WASD移动 | J传球 | 空格射门 | K切换 | L抢断 | A传中 | Q挑球 | E二过一 | G门将出击"
	control_hint.add_theme_font_size_override("font_size", 13)
	control_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	control_hint.position = Vector2(20, vp_size.y - 25)
	ui_canvas.add_child(control_hint)

	_create_pause_panel()
	_create_result_panel()

func _create_pause_panel():
	pause_panel = Panel.new()
	pause_panel.size = Vector2(400, 300)
	var vp_size = get_viewport().get_visible_rect().size
	pause_panel.position = Vector2((vp_size.x - 400) / 2, (vp_size.y - 300) / 2)
	pause_panel.visible = false
	ui_canvas.add_child(pause_panel)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(50, 30)
	vbox.size = Vector2(300, 240)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.theme_override_constants_separation = 15
	pause_panel.add_child(vbox)

	var title = Label.new()
	title.text = "比赛暂停"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume_btn = Button.new()
	resume_btn.text = "继续比赛"
	resume_btn.add_theme_font_size_override("font_size", 20)
	resume_btn.pressed.connect(_toggle_pause)
	vbox.add_child(resume_btn)

	var quit_btn = Button.new()
	quit_btn.text = "退出比赛"
	quit_btn.add_theme_font_size_override("font_size", 20)
	quit_btn.pressed.connect(func():
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
	vbox.theme_override_constants_separation = 15
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

	var scorers = Label.new()
	scorers.name = "ResultScorers"
	scorers.text = ""
	scorers.add_theme_font_size_override("font_size", 14)
	scorers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(scorers)

	var btn = Button.new()
	btn.text = "返回"
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(func():
		# 如果是联赛模式，返回联赛界面
		if LeagueManager.current_league_id != "":
			get_tree().change_scene_to_file("res://scenes/LeagueHub.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	vbox.add_child(btn)

# ============================================================
# 比赛流程
# ============================================================

func _kickoff():
	# 重置所有球员到起始位置
	for p in home_players:
		p.reset_to_home()
	for p in away_players:
		p.reset_to_home()

	# 球放中圈
	ball.position = Vector3(0, 0, 0)
	ball_velocity = Vector3.ZERO
	ball_height = 0
	ball_height_velocity = 0
	ball_owner = null
	ball_spin = 0
	ball_shot_type = ""

	# 开球方（失球方或上半场主队）
	var kickoff_side = GameState.TeamSide.HOME
	if home_score + away_score > 0:
		# 失球方开球
		kickoff_side = GameState.TeamSide.AWAY if home_score > away_score else GameState.TeamSide.HOME
	if current_half == 2 and home_score == 0 and away_score == 0:
		kickoff_side = GameState.TeamSide.AWAY

	# 让开球方的一名前锋靠近球
	var kickoff_team = home_players if kickoff_side == GameState.TeamSide.HOME else away_players
	for p in kickoff_team:
		if p.role in ["ST", "CF", "CAM"]:
			p.position = Vector3(0, 0, 0.5 if kickoff_side == GameState.TeamSide.HOME else -0.5)
			break

	match_phase = GameState.MatchPhase.KICKOFF
	out_of_bounds_time = 1.5  # 1.5秒后开始

	_show_event("开球！", 1.5)

func _end_half():
	if current_half == 1:
		current_half = 2
		match_time = 0
		phase_label.text = "下半场"
		_show_event("中场休息", 2.0)
		_kickoff()
	else:
		_end_match()

func _end_match():
	match_phase = GameState.MatchPhase.FULLTIME

	# 更新存档
	var player_score = home_score if player_side == GameState.TeamSide.HOME else away_score
	var opponent_score = away_score if player_side == GameState.TeamSide.HOME else home_score
	var won = player_score > opponent_score
	var drawn = player_score == opponent_score
	SaveManager.update_match_result(won, drawn, player_score, opponent_score)

	# 如果是联赛模式，记录结果
	if LeagueManager.current_league_id != "":
		_record_league_result()

	# 显示结果
	result_panel.visible = true
	var title = result_panel.get_node("VBoxContainer/ResultTitle")
	var score = result_panel.get_node("VBoxContainer/ResultScore")
	var stats = result_panel.get_node("VBoxContainer/ResultStats")
	var scorers = result_panel.get_node("VBoxContainer/ResultScorers")

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

	# 统计
	var ref_stats = Referee.match_stats
	stats.text = "射门 %d-%d | 射正 %d-%d | 犯规 %d-%d | 角球 %d-%d | 黄牌 %d-%d" % [
		ref_stats.shots.home, ref_stats.shots.away,
		ref_stats.shots_on_target.home, ref_stats.shots_on_target.away,
		ref_stats.fouls.home, ref_stats.fouls.away,
		ref_stats.corners.home, ref_stats.corners.away,
		ref_stats.yellow_cards.home, ref_stats.yellow_cards.away,
	]

	# 进球名单
	var scorer_text = ""
	for s in home_scorers:
		var name = PlayerDatabase.get_player_short_name(s.player_id) if s.player_id != "" else "球员%d" % s.number
		if s.is_own_goal:
			name += "(乌龙)"
		scorer_text += "%s %d' %s\n" % [TeamDatabase.get_team_short_name(home_team_id), s.minute, name]
	for s in away_scorers:
		var name = PlayerDatabase.get_player_short_name(s.player_id) if s.player_id != "" else "球员%d" % s.number
		if s.is_own_goal:
			name += "(乌龙)"
		scorer_text += "%s %d' %s\n" % [TeamDatabase.get_team_short_name(away_team_id), s.minute, name]
	scorers.text = scorer_text

func _record_league_result():
	var home_goals = home_score
	var away_goals = away_score
	LeagueManager.record_match_result(home_team_id, away_team_id, home_goals, away_goals)

# ============================================================
# 球的物理
# ============================================================

func _update_ball_physics(delta):
	# 如果有控球者，球跟随控球者
	if ball_owner != null and is_instance_valid(ball_owner):
		var owner_pos = ball_owner.position
		var forward = ball_owner.facing_direction if ball_owner.facing_direction else Vector3.FORWARD
		ball.position = owner_pos + Vector3(forward.x, 0, forward.z) * 0.8 + Vector3(0, BALL_RADIUS, 0)
		ball_velocity = Vector3.ZERO
		ball_height = 0
		ball_height_velocity = 0
	else:
		# 地面摩擦
		var friction = BALL_FRICTION * delta
		ball_velocity = ball_velocity * (1.0 - friction)

		# 空气阻力（球在空中时）
		if ball_height > 0.1:
			ball_velocity = ball_velocity * (1.0 - BALL_AIR_DRAG * delta)

		# 旋转效应（搓射/电梯球）
		if abs(ball_spin) > 0.01 and ball_height > 0.1:
			# Magnus效应：旋转产生侧向力
			var perp = Vector3(-ball_velocity.z, 0, ball_velocity.x).normalized()
			ball_velocity += perp * ball_spin * delta * 3.0
			ball_spin *= (1.0 - delta * 0.5)  # 旋转衰减

		# 重力
		if ball_height > 0 or ball_height_velocity > 0:
			ball_height_velocity -= BALL_GRAVITY * delta
			ball_height += ball_height_velocity * delta
			if ball_height < 0:
				ball_height = 0
				# 弹跳
				if abs(ball_height_velocity) > 1.0:
					ball_height_velocity = -ball_height_velocity * 0.5
				else:
					ball_height_velocity = 0
		else:
			ball_height = 0
			ball_height_velocity = 0

		# 应用速度
		ball.position += ball_velocity * delta
		ball.position.y = 0

		# 检查控球
		_check_ball_possession()

	# 更新球的视觉位置
	ball_mesh.position = Vector3(0, ball_height, 0)
	ball_shadow.position = Vector3(ball.position.x, 0.01, ball.position.z)
	# 阴影随高度缩小
	var shadow_scale = 1.0 - min(ball_height / 10.0, 0.5)
	ball_shadow.scale = Vector3(shadow_scale, shadow_scale, shadow_scale)

func _check_ball_possession():
	if ball_owner != null:
		return

	var all_players = home_players + away_players
	var nearest_player = null
	var nearest_dist = INF

	for p in all_players:
		if not is_instance_valid(p):
			continue
		# 球在空中时，只有高度低于1.5米才能控球
		if ball_height > 1.5:
			continue
		var dist = p.position.distance_to(ball.position)
		var control_radius = p.stats.get("control_radius", 1.5)
		if dist < control_radius and dist < nearest_dist:
			nearest_dist = dist
			nearest_player = p

	if nearest_player:
		ball_owner = nearest_player
		nearest_player.has_ball = true
		last_touch_team = nearest_player.team_side
		last_touch_player = nearest_player

		# 如果是玩家控制的队伍，切换到控球者
		if nearest_player.team_side == player_side and not nearest_player.is_goalkeeper:
			_switch_to_player(nearest_player)

func _check_collisions():
	# 球员间碰撞和抢断检测
	for p in home_players + away_players:
		if not is_instance_valid(p):
			continue
		var opp_team = away_players if p.team_side == GameState.TeamSide.HOME else home_players
		for opp in opp_team:
			if not is_instance_valid(opp):
				continue
			var dist = p.position.distance_to(opp.position)
			if dist < 1.0:
				# 碰撞推开
				var push_dir = (p.position - opp.position).normalized()
				p.position += push_dir * 0.02
				opp.position -= push_dir * 0.02

				# 抢断检测
				if p.is_player_controlled or p.get("is_active"):
					if dist < p.stats.get("tackle_radius", 2.0):
						_check_tackle(p, opp)

func _check_tackle(tackler: CharacterBody3D, target: CharacterBody3D):
	if ball_owner == target:
		var success_chance = ai_params.get("tackle_success", 0.6)
		# 根据防守属性调整
		var tackle_attr = PlayerDatabase.get_player_attributes(tackler.player_id).get("defending", 70) / 100.0
		success_chance = success_chance * (0.5 + tackle_attr * 0.5)

		if randf() < success_chance:
			# 抢断成功
			ball_owner = null
			target.has_ball = false
			var dir = (ball.position - tackler.position)
			dir.y = 0
			dir = dir.normalized()
			ball_velocity = dir * 8.0
			ball_height_velocity = 1.0
			tackler.play_action(AnimState.TACKLE if typeof(AnimState) == TYPE_INT else 4, 0.3)

			# 统计
			var data = SaveManager.load_data()
			data["stats"]["total_tackles"] = data["stats"].get("total_tackles", 0) + 1
			SaveManager.save_data(data)
		else:
			# 抢断犯规检测
			var foul_severity = randf()
			if foul_severity > 0.7:
				# 犯规
				Referee.check_foul(tackler, target, ball.position, foul_severity)

# ============================================================
# 边界和进球判定
# ============================================================

func _check_bounds_and_goals():
	if match_phase != GameState.MatchPhase.PLAYING:
		return

	var ball_pos = ball.position
	var half_l = GameState.FIELD_LENGTH / 2
	var half_w = GameState.FIELD_WIDTH / 2
	var goal_half = GameState.GOAL_WIDTH / 2

	# 进球判定（球在球门内且高度低于横梁）
	if ball_pos.z < -half_l and abs(ball_pos.x) < goal_half and ball_height < GameState.GOAL_HEIGHT:
		# 进了主队球门 -> 客队得分
		# 判断是否乌龙球
		var is_own_goal = (last_touch_team == GameState.TeamSide.AWAY)
		_score_goal(GameState.TeamSide.AWAY, is_own_goal)
		return

	if ball_pos.z > half_l and abs(ball_pos.x) < goal_half and ball_height < GameState.GOAL_HEIGHT:
		# 进了客队球门 -> 主队得分
		var is_own_goal = (last_touch_team == GameState.TeamSide.HOME)
		_score_goal(GameState.TeamSide.HOME, is_own_goal)
		return

	# 球门柱碰撞（简化）
	if abs(ball_pos.z) > half_l - 0.1 and abs(ball_pos.z) < half_l + 0.1:
		if abs(ball_pos.x - goal_half) < 0.2 or abs(ball_pos.x + goal_half) < 0.2:
			if ball_height < GameState.GOAL_HEIGHT:
				# 击中门柱，反弹
				ball_velocity.x = -ball_velocity.x * 0.5

	# 出界判定
	if abs(ball_pos.x) > half_w:
		# 边线出界 -> 界外球
		var throw_in_side = GameState.TeamSide.AWAY if last_touch_team == GameState.TeamSide.HOME else GameState.TeamSide.HOME
		var throw_pos = Vector3(clamp(ball_pos.x, -half_w + 1, half_w - 1), 0, ball_pos.z)
		_setup_set_piece(Referee.SetPieceType.THROW_IN, throw_in_side, throw_pos)
		return

	if ball_pos.z < -half_l and abs(ball_pos.x) > goal_half:
		# 主队底线出界
		if last_touch_team == GameState.TeamSide.AWAY:
			# 客队最后触球 -> 主队球门球
			_setup_set_piece(Referee.SetPieceType.GOAL_KICK, GameState.TeamSide.HOME, Vector3(0, 0, -half_l + 5))
		else:
			# 主队最后触球 -> 客队角球
			var corner_x = -half_w if ball_pos.x < 0 else half_w
			_setup_set_piece(Referee.SetPieceType.CORNER_KICK, GameState.TeamSide.AWAY, Vector3(corner_x, 0, -half_l))
		return

	if ball_pos.z > half_l and abs(ball_pos.x) > goal_half:
		# 客队底线出界
		if last_touch_team == GameState.TeamSide.HOME:
			_setup_set_piece(Referee.SetPieceType.GOAL_KICK, GameState.TeamSide.AWAY, Vector3(0, 0, half_l - 5))
		else:
			var corner_x = -half_w if ball_pos.x < 0 else half_w
			_setup_set_piece(Referee.SetPieceType.CORNER_KICK, GameState.TeamSide.HOME, Vector3(corner_x, 0, half_l))
		return

func _score_goal(scoring_team: int, is_own_goal: bool):
	if scoring_team == GameState.TeamSide.HOME:
		home_score += 1
	else:
		away_score += 1

	# 记录进球者
	var scorer = last_touch_player
	var scorer_id = scorer.player_id if scorer else ""
	var scorer_number = scorer.player_index if scorer else 0
	var minute = int(match_time / (half_duration / 45.0)) + (45 if current_half == 2 else 0)

	# 判断进球类型
	var goal_type = "普通进球"
	if ball_shot_type != "":
		goal_type = ball_shot_type
		ball_shot_type = ""

	# 帽子戏法追踪
	if scorer_id != "":
		hat_trick_tracker[scorer_id] = hat_trick_tracker.get(scorer_id, 0) + 1
		if hat_trick_tracker[scorer_id] == 3:
			goal_type = "帽子戏法！"
		elif hat_trick_tracker[scorer_id] > 3:
			goal_type = "大四喜！" if hat_trick_tracker[scorer_id] == 4 else "独中五元！"

	# 世界波判定（远射）
	if scorer and abs(scorer.position.z - (GameState.FIELD_LENGTH/2 if scoring_team == 0 else -GameState.FIELD_LENGTH/2)) > 25:
		if goal_type == "普通进球":
			goal_type = "世界波！"

	var goal_record = {
		"player_id": scorer_id,
		"number": scorer_number,
		"minute": minute,
		"type": goal_type,
		"is_own_goal": is_own_goal,
	}

	if scoring_team == GameState.TeamSide.HOME:
		home_scorers.append(goal_record)
	else:
		away_scorers.append(goal_record)

	# 显示进球通知
	var scorer_name = PlayerDatabase.get_player_short_name(scorer_id) if scorer_id != "" else "球员%d" % scorer_number
	if is_own_goal:
		scorer_name += "(乌龙球)"
	var event_text = "⚽ 进球！%s %d'\n%s — %s" % [
		TeamDatabase.get_team_short_name(home_team_id if scoring_team == 0 else away_team_id),
		minute, scorer_name, goal_type
	]
	_show_event(event_text, 3.0)

	# 统计
	Referee.record_shot(scoring_team, true)

	match_phase = GameState.MatchPhase.GOAL
	goal_celebration_time = 3.0
	ball_owner = null

# ============================================================
# 定位球
# ============================================================

func _setup_set_piece(piece_type: int, team: int, pos: Vector3):
	set_piece_type = piece_type
	set_piece_team = team
	set_piece_position = pos
	set_piece_ready = true

	# 将球放到定位球位置
	ball.position = pos
	ball_velocity = Vector3.ZERO
	ball_height = 0
	ball_height_velocity = 0
	ball_owner = null

	match_phase = GameState.MatchPhase.BALL_OUT
	out_of_bounds_time = 2.0

	# 统计
	match piece_type:
		Referee.SetPieceType.CORNER_KICK:
			var key = "home" if team == 0 else "away"
			Referee.match_stats.corners[key] += 1
			_show_event("角球 — %s" % TeamDatabase.get_team_short_name(home_team_id if team == 0 else away_team_id), 2.0)
		Referee.SetPieceType.DIRECT_FREE_KICK, Referee.SetPieceType.INDIRECT_FREE_KICK:
			var key = "home" if team == 0 else "away"
			Referee.match_stats.free_kicks[key] += 1
			_show_event("任意球 — %s" % TeamDatabase.get_team_short_name(home_team_id if team == 0 else away_team_id), 2.0)
		Referee.SetPieceType.PENALTY:
			var key = "home" if team == 0 else "away"
			Referee.match_stats.penalties[key] += 1
			_show_event("点球！— %s" % TeamDatabase.get_team_short_name(home_team_id if team == 0 else away_team_id), 2.0)
		Referee.SetPieceType.THROW_IN:
			_show_event("界外球", 1.5)
		Referee.SetPieceType.GOAL_KICK:
			_show_event("球门球", 1.5)

	# 设置人墙（如果是任意球）
	if piece_type in [Referee.SetPieceType.DIRECT_FREE_KICK, Referee.SetPieceType.INDIRECT_FREE_KICK]:
		_setup_free_kick_wall(team, pos)

	# 让一名球员靠近球准备发球
	var team_players = home_players if team == GameState.TeamSide.HOME else away_players
	var nearest = null
	var nearest_dist = INF
	for p in team_players:
		if p.is_goalkeeper:
			continue
		var d = p.position.distance_to(pos)
		if d < nearest_dist:
			nearest_dist = d
			nearest = p
	if nearest:
		nearest.position = pos + Vector3(1, 0, 0)
		if team == player_side:
			_switch_to_player(nearest)

func _setup_free_kick_wall(attacking_team: int, ball_pos: Vector3):
	wall_players.clear()
	var defending_team = GameState.TeamSide.AWAY if attacking_team == GameState.TeamSide.HOME else GameState.TeamSide.HOME
	var def_players = home_players if defending_team == GameState.TeamSide.HOME else away_players

	# 找到目标球门方向
	var target_goal_z = GameState.FIELD_LENGTH / 2 if attacking_team == GameState.TeamSide.HOME else -GameState.FIELD_LENGTH / 2
	var wall_dir = (Vector3(0, 0, target_goal_z) - ball_pos)
	wall_dir.y = 0
	wall_dir = wall_dir.normalized()

	# 人墙位置：球前方9.15米
	var wall_center = ball_pos + wall_dir * 9.15
	# 人墙人数：3-5人
	var wall_count = 4

	# 选择防守球员组成人墙
	var selected = []
	for p in def_players:
		if p.is_goalkeeper:
			continue
		if p.role in ["CB", "LB", "RB", "CDM", "CM"]:
			selected.append(p)
		if selected.size() >= wall_count:
			break

	# 排列人墙
	var spacing = 0.8
	for i in range(selected.size()):
		var offset = (i - (selected.size() - 1) / 2.0) * spacing
		var perp = Vector3(-wall_dir.z, 0, wall_dir.x) * offset
		selected[i].position = wall_center + perp
		selected[i].home_position = wall_center + perp  # 临时改变home position
		wall_players.append(selected[i])

func _resume_from_out():
	# 恢复比赛
	match_phase = GameState.MatchPhase.PLAYING
	set_piece_type = Referee.SetPieceType.NONE

	# 恢复人墙球员的home position
	for p in wall_players:
		var formation = GameState.get_formation(config.get("formation", "4-4-2"))
		var idx = p.player_index - 1
		if idx >= 0 and idx < formation.size():
			var role_data = formation[idx]
			var x = role_data[1]
			var z = role_data[2]
			if p.team_side == GameState.TeamSide.AWAY:
				z = -z
			p.home_position = Vector3(x, 0, z)
	wall_players.clear()

# ============================================================
# 玩家输入
# ============================================================

func _update_player_input():
	if active_player == null or not is_instance_valid(active_player):
		_switch_active_player()
		return

	if match_phase != GameState.MatchPhase.PLAYING:
		active_player.input_direction = Vector3.ZERO
		return

	# 读取移动输入
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

	var move_dir = Vector3(input_vector.x, 0, input_vector.y)
	active_player.input_direction = move_dir
	active_player.is_sprinting = is_sprinting
	active_player.is_player_controlled = true

	# 动作按钮
	if Input.is_action_just_pressed("pass"):
		_do_pass()
	if Input.is_action_just_pressed("shoot"):
		_do_shoot()
	if Input.is_action_just_pressed("through_ball"):
		_do_through_ball()
	if Input.is_action_just_pressed("cross"):
		_do_cross()
	if Input.is_action_just_pressed("lob"):
		_do_lob()
	if Input.is_action_just_pressed("one_two"):
		_do_one_two()
	if Input.is_action_just_pressed("tackle"):
		_do_tackle()
	if Input.is_action_just_pressed("switch_player"):
		_switch_active_player_manual()
	if Input.is_action_just_pressed("gk_rush"):
		_do_gk_rush()
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()

	# 射门类型：长按空格=远射，短按=普通射门
	# 搓射：Shift+空格
	# 电梯球：Ctrl+空格
	# （这些在_do_shoot中根据修饰键判断）

func _toggle_pause():
	if match_phase == GameState.MatchPhase.PLAYING:
		match_phase = GameState.MatchPhase.PAUSED
		pause_panel.visible = true
	elif match_phase == GameState.MatchPhase.PAUSED:
		match_phase = GameState.MatchPhase.PLAYING
		pause_panel.visible = false

# ============================================================
# 球员切换
# ============================================================

func _switch_active_player():
	# 自动切换到最靠近球的球员
	var team = home_players if player_side == GameState.TeamSide.HOME else away_players
	if team.is_empty():
		return

	var best_player = null
	var best_dist = INF

	for p in team:
		if p.is_goalkeeper:
			continue
		var dist = p.position.distance_to(ball.position)
		if dist < best_dist:
			best_dist = dist
			best_player = p

	if best_player == null and team.size() > 0:
		best_player = team[0]

	_switch_to_player(best_player)

func _switch_active_player_manual():
	# 手动切换：循环切换到下一个球员
	var team = home_players if player_side == GameState.TeamSide.HOME else away_players
	if team.is_empty():
		return

	var current_idx = team.find(active_player) if active_player in team else -1

	# 找下一个非门将球员
	for i in range(1, team.size() + 1):
		var idx = (current_idx + i) % team.size()
		if not team[idx].is_goalkeeper:
			_switch_to_player(team[idx])
			return

func _switch_to_player(player: CharacterBody3D):
	if active_player and is_instance_valid(active_player):
		active_player.is_active = false
		active_player.is_player_controlled = false

	active_player = player
	if active_player:
		active_player.is_active = true
		active_player.is_player_controlled = true

# ============================================================
# 动作：传球、射门、传中、挑球、2过1、抢断、门将出击
# ============================================================

func _do_pass():
	if active_player == null or ball_owner != active_player:
		return

	var team = home_players if active_player.team_side == GameState.TeamSide.HOME else away_players
	var forward_dir = 1 if active_player.team_side == GameState.TeamSide.HOME else -1

	# 寻找最佳传球目标
	var best_target = null
	var best_score = -INF

	for p in team:
		if p == active_player:
			continue
		var forward_score = (p.position.z - active_player.position.z) * forward_dir
		var dist = active_player.position.distance_to(p.position)
		if dist > 3 and dist < 40:
			var score = forward_score - dist * 0.2
			# 传球属性影响选择
			var pass_attr = PlayerDatabase.get_player_attributes(active_player.player_id).get("passing", 70) / 100.0
			score *= (0.7 + pass_attr * 0.3)
			if score > best_score:
				best_score = score
				best_target = p

	if best_target:
		var dir = (best_target.position - active_player.position)
		dir.y = 0
		# 传球准确率
		var pass_acc = ai_params.get("pass_accuracy", 0.8)
		var pass_attr = PlayerDatabase.get_player_attributes(active_player.player_id).get("passing", 70) / 100.0
		pass_acc = pass_acc * (0.5 + pass_attr * 0.5)
		if randf() > pass_acc:
			dir.x += randf_range(-0.2, 0.2)
			dir.z += randf_range(-0.2, 0.2)
		dir = dir.normalized()

		ball_velocity = dir * PASS_SPEED
		ball_height_velocity = 0.5
		ball_owner = null
		active_player.has_ball = false
		active_player.play_action(4, 0.3)  # KICK动画
		ball_shot_type = ""

		# 统计
		var data = SaveManager.load_data()
		data["stats"]["total_passes"] = data["stats"].get("total_passes", 0) + 1
		SaveManager.save_data(data)

func _do_through_ball():
	if active_player == null or ball_owner != active_player:
		return

	var team = home_players if active_player.team_side == GameState.TeamSide.HOME else away_players
	var forward_dir = 1 if active_player.team_side == GameState.TeamSide.HOME else -1

	var best_target = null
	var best_score = -INF

	for p in team:
		if p == active_player:
			continue
		var forward_score = (p.position.z - active_player.position.z) * forward_dir
		var dist = active_player.position.distance_to(p.position)
		if dist > 5 and dist < 40 and forward_score > 5:
			if forward_score > best_score:
				best_score = forward_score
				best_target = p

	if best_target:
		# 传到队友前方更远的位置（直塞）
		var lead = Vector3(0, 0, forward_dir * 8)
		var target_pos = best_target.position + lead
		var dir = (target_pos - active_player.position)
		dir.y = 0
		dir = dir.normalized()

		ball_velocity = dir * (PASS_SPEED * 1.3)
		ball_height_velocity = 0.3
		ball_owner = null
		active_player.has_ball = false
		active_player.play_action(4, 0.3)
		ball_shot_type = ""

func _do_cross():
	if active_player == null or ball_owner != active_player:
		return

	# 传中：向禁区方向高弧线传球
	var team = home_players if active_player.team_side == GameState.TeamSide.HOME else away_players
	var target_goal_z = GameState.FIELD_LENGTH / 2 if active_player.team_side == GameState.TeamSide.HOME else -GameState.FIELD_LENGTH / 2

	# 寻找禁区内队友
	var best_target = null
	var best_dist = INF
	for p in team:
		if p == active_player or p.is_goalkeeper:
			continue
		if abs(p.position.z - target_goal_z) < 20:
			var d = abs(p.position.x)
			if d < best_dist:
				best_dist = d
				best_target = p

	if best_target:
		var dir = (best_target.position - active_player.position)
		dir.y = 0
		dir = dir.normalized()

		ball_velocity = dir * CROSS_SPEED
		ball_height_velocity = 6.0  # 高弧线
		ball_spin = 0.3  # 搓弧线
		ball_owner = null
		active_player.has_ball = false
		active_player.play_action(4, 0.4)
		ball_shot_type = "传中"

func _do_lob():
	if active_player == null or ball_owner != active_player:
		return

	# 挑球：球高高挑起，越过前方防守球员
	var forward = active_player.facing_direction if active_player.facing_direction else Vector3.FORWARD
	ball_velocity = Vector3(forward.x, 0, forward.z) * LOB_SPEED
	ball_height_velocity = 8.0  # 高挑
	ball_owner = null
	active_player.has_ball = false
	active_player.play_action(4, 0.3)
	ball_shot_type = "挑球"

func _do_one_two():
	if active_player == null or ball_owner != active_player:
		return

	# 2过1：传球给队友，然后前插等待回传
	var team = home_players if active_player.team_side == GameState.TeamSide.HOME else away_players
	var forward_dir = 1 if active_player.team_side == GameState.TeamSide.HOME else -1

	# 找前方最近的队友
	var best_target = null
	var best_dist = INF
	for p in team:
		if p == active_player:
			continue
		var forward_score = (p.position.z - active_player.position.z) * forward_dir
		var dist = active_player.position.distance_to(p.position)
		if dist > 5 and dist < 20 and forward_score > 0:
			if dist < best_dist:
				best_dist = dist
				best_target = p

	if best_target:
		# 传球
		var dir = (best_target.position - active_player.position)
		dir.y = 0
		dir = dir.normalized()
		ball_velocity = dir * PASS_SPEED
		ball_height_velocity = 0.3
		ball_owner = null
		active_player.has_ball = false

		# 设置2过1状态
		active_player.start_one_two(best_target)

		# 让队友在前插方向等待回传
		var run_target = active_player.position + Vector3(0, 0, forward_dir * 15)
		active_player.home_position = run_target  # 临时改变跑位

		ball_shot_type = "二过一"

func _do_shoot():
	if active_player == null or ball_owner != active_player:
		return

	var side = active_player.team_side
	var target_goal_z = GameState.FIELD_LENGTH / 2 if side == GameState.TeamSide.HOME else -GameState.FIELD_LENGTH / 2
	var dist_to_goal = abs(active_player.position.z - target_goal_z)

	# 判断射门类型
	var is_long_shot = dist_to_goal > 25
	var is_curled = Input.is_action_pressed("sprint")  # Shift+空格 = 搓射
	var is_knuckle = Input.is_action_pressed("tackle")  # L+空格 = 电梯球（简化）

	var dir = Vector3(
		randf_range(-3, 3) - active_player.position.x * 0.05,
		0,
		target_goal_z - active_player.position.z
	).normalized()

	# 射门属性影响
	var shoot_attr = PlayerDatabase.get_player_attributes(active_player.player_id).get("shooting", 70) / 100.0
	var accuracy = ai_params.get("shot_accuracy", 0.7) * (0.5 + shoot_attr * 0.5)

	if randf() > accuracy:
		dir.x += randf_range(-0.3, 0.3)
		dir = dir.normalized()

	var power = SHOT_SPEED * randf_range(0.85, 1.0)
	if is_long_shot:
		power = LONG_SHOT_SPEED
		ball_shot_type = "远射"
	elif is_curled:
		ball_shot_type = "搓射"
		ball_spin = 0.5  # 强旋转
	elif is_knuckle:
		ball_shot_type = "电梯球"
		ball_spin = 0.0
		ball_height_velocity = 4.0
		power *= 1.1
	else:
		ball_shot_type = ""

	ball_velocity = dir * power
	if not is_knuckle:
		ball_height_velocity = 2.0 + randf() * 2.0
	ball_owner = null
	active_player.has_ball = false
	active_player.play_action(4, 0.5)

	# 统计
	Referee.record_shot(side, true)
	var data = SaveManager.load_data()
	data["stats"]["total_shots"] = data["stats"].get("total_shots", 0) + 1
	SaveManager.save_data(data)

func _do_tackle():
	if active_player == null:
		return

	var opp_team = away_players if active_player.team_side == GameState.TeamSide.HOME else home_players
	var tackle_radius = active_player.stats.get("tackle_radius", 2.0)

	for p in opp_team:
		var dist = active_player.position.distance_to(p.position)
		if dist < tackle_radius:
			_check_tackle(active_player, p)
			return

func _do_gk_rush():
	# 门将出击
	var team = home_players if player_side == GameState.TeamSide.HOME else away_players
	for p in team:
		if p.is_goalkeeper:
			# 向球的位置出击
			p.goalkeeper_rush(ball.position)
			_show_event("门将出击！", 1.0)
			return

# ============================================================
# AI 更新
# ============================================================

func _update_ai(delta):
	# 更新所有非玩家控制的球员AI
	for p in home_players + away_players:
		if not is_instance_valid(p):
			continue
		if p == active_player and p.is_player_controlled:
			continue
		if p.is_goalkeeper:
			_update_goalkeeper_ai(p, delta)
		else:
			_update_player_ai(p, delta)

func _update_goalkeeper_ai(gk: CharacterBody3D, delta: float):
	if gk.gk_rushing:
		return  # 出击中，由player_controller处理

	var target_goal_z = -GameState.FIELD_LENGTH / 2 if gk.team_side == GameState.TeamSide.HOME else GameState.FIELD_LENGTH / 2
	var ball_pos = ball.position

	# 门将在小禁区内移动，跟随球的横向位置
	var gk_x = clamp(ball_pos.x * 0.3, -3.0, 3.0)
	var gk_z = target_goal_z + (5.0 if gk.team_side == GameState.TeamSide.HOME else -5.0)
	var target = Vector3(gk_x, 0, gk_z)

	# 如果球很近且向球门方向，冲出来
	var ball_to_goal = abs(ball_pos.z - target_goal_z)
	if ball_to_goal < 15 and abs(ball_pos.z - target_goal_z) < 15:
		# 检查球是否向球门移动
		var goal_dir = sign(target_goal_z - ball_pos.z)
		if sign(ball_velocity.z) == goal_dir and ball_velocity.length() > 5:
			gk.goalkeeper_rush(ball_pos)
			return

	# 移动到目标位置
	var to_target = target - gk.position
	to_target.y = 0
	if to_target.length() > 0.5:
		gk.input_direction = to_target.normalized()
	else:
		gk.input_direction = Vector3.ZERO

func _update_player_ai(p: CharacterBody3D, delta: float):
	# 简化AI：根据球的位置和阵型决定行为
	var ball_pos = ball.position
	var home_pos = p.home_position

	# 判断是否是离球最近的队友
	var team = home_players if p.team_side == GameState.TeamSide.HOME else away_players
	var is_nearest = true
	var my_dist = p.position.distance_to(ball_pos)
	for teammate in team:
		if teammate == p or teammate.is_goalkeeper:
			continue
		if teammate.position.distance_to(ball_pos) < my_dist:
			is_nearest = false
			break

	# 有球时
	if ball_owner == p:
		_ai_with_ball(p, delta)
	# 离球最近时追球
	elif ball_owner == null and is_nearest:
		var to_ball = ball_pos - p.position
		to_ball.y = 0
		p.input_direction = to_ball.normalized()
		p.is_sprinting = to_ball.length() > 10
	# 无球时回到阵型位置
	else:
		var to_home = home_pos - p.position
		to_home.y = 0
		if to_home.length() > 1.0:
			p.input_direction = to_home.normalized()
			p.is_sprinting = to_home.length() > 15
		else:
			p.input_direction = Vector3.ZERO
			p.is_sprinting = false

func _ai_with_ball(p: CharacterBody3D, delta: float):
	var side = p.team_side
	var target_goal_z = GameState.FIELD_LENGTH / 2 if side == GameState.TeamSide.HOME else -GameState.FIELD_LENGTH / 2
	var dist_to_goal = abs(p.position.z - target_goal_z)

	# 射门判定
	if dist_to_goal < 25 and abs(p.position.x) < 25:
		if randf() < 0.02 * (1 + (25 - dist_to_goal) / 25):
			_ai_shoot(p, side)
			return

	# 传球判定
	if randf() < 0.015:
		_ai_pass(p, side)
		return

	# 带球前进
	var goal_dir = Vector3(0, 0, target_goal_z - p.position.z).normalized()
	# 避开对手
	var avoid = Vector3.ZERO
	var opp_team = away_players if side == GameState.TeamSide.HOME else home_players
	for opp in opp_team:
		var d = p.position.distance_to(opp.position)
		if d < 4 and d > 0.1:
			avoid += (p.position - opp.position).normalized() / d
	avoid = avoid.normalized()

	p.input_direction = (goal_dir + avoid * 2).normalized()
	p.is_sprinting = false

func _ai_shoot(p: Node, side: int):
	var target_goal_z = GameState.FIELD_LENGTH / 2 if side == GameState.TeamSide.HOME else -GameState.FIELD_LENGTH / 2
	var dir = Vector3(
		randf_range(-3, 3) - p.position.x * 0.05,
		0,
		target_goal_z - p.position.z
	).normalized()

	var accuracy = ai_params.get("shot_accuracy", 0.7)
	if randf() > accuracy:
		dir.x += randf_range(-0.3, 0.3)
		dir = dir.normalized()

	var power = SHOT_SPEED * randf_range(0.8, 1.0)
	ball_velocity = dir * power
	ball_height_velocity = 2.0 + randf() * 2.0
	ball_owner = null
	p.has_ball = false
	last_touch_team = side
	last_touch_player = p
	ball_shot_type = "远射" if abs(p.position.z - target_goal_z) > 25 else ""
	Referee.record_shot(side, true)

func _ai_pass(p: Node, side: int):
	var team = home_players if side == GameState.TeamSide.HOME else away_players
	var forward_dir = 1 if side == GameState.TeamSide.HOME else -1

	var best_target = null
	var best_score = -INF

	for teammate in team:
		if teammate == p:
			continue
		var forward_score = (teammate.position.z - p.position.z) * forward_dir
		var dist = p.position.distance_to(teammate.position)
		if dist > 3 and dist < 35:
			var score = forward_score - dist * 0.2
			if score > best_score:
				best_score = score
				best_target = teammate

	if best_target:
		var dir = (best_target.position - p.position)
		dir.y = 0
		if randf() > ai_params.get("pass_accuracy", 0.8):
			dir.x += randf_range(-0.3, 0.3)
			dir.z += randf_range(-0.3, 0.3)
		dir = dir.normalized()

		ball_velocity = dir * PASS_SPEED
		ball_height_velocity = 0.5
		ball_owner = null
		p.has_ball = false
		last_touch_team = side
		last_touch_player = p
		ball_shot_type = ""

# ============================================================
# UI 更新
# ============================================================

func _update_ui():
	score_label.text = "%d - %d" % [home_score, away_score]

	var display_time = match_time
	var minutes = int(display_time / (half_duration / 45.0))
	if current_half == 2:
		minutes += 45
	time_label.text = "%02d:%02d" % [minutes, int(display_time) % 60]

	# 进球名单
	var scorer_text = ""
	for s in home_scorers:
		var name = PlayerDatabase.get_player_short_name(s.player_id) if s.player_id != "" else "球员%d" % s.number
		if s.is_own_goal:
			name += "(乌龙)"
		scorer_text += "%d' %s %s\n" % [s.minute, name, s.type]
	scorer_text += "\n"
	for s in away_scorers:
		var name = PlayerDatabase.get_player_short_name(s.player_id) if s.player_id != "" else "球员%d" % s.number
		if s.is_own_goal:
			name += "(乌龙)"
		scorer_text += "%d' %s %s\n" % [s.minute, name, s.type]
	scorer_list_label.text = scorer_text

	# 统计
	var ref_stats = Referee.match_stats
	stats_label.text = "射门 %d-%d\n射正 %d-%d\n犯规 %d-%d\n角球 %d-%d\n黄牌 %d-%d" % [
		ref_stats.shots.home, ref_stats.shots.away,
		ref_stats.shots_on_target.home, ref_stats.shots_on_target.away,
		ref_stats.fouls.home, ref_stats.fouls.away,
		ref_stats.corners.home, ref_stats.corners.away,
		ref_stats.yellow_cards.home, ref_stats.yellow_cards.away,
	]

func _show_event(text: String, duration: float):
	event_notification.text = text
	event_notification.visible = true
	event_notification.modulate.a = 1.0

	# 创建Tween淡出
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(event_notification, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		event_notification.visible = false
	)

# ============================================================
# 网络联机
# ============================================================

func _handle_remote_input(sender_id: int, input_data: Dictionary):
	if not config.get("is_lan_match", false) or not NetworkManager.is_host:
		return

	var remote_input = input_data.get("input_vector", Vector2.ZERO)
	var remote_sprint = input_data.get("sprint", false)
	var remote_actions = input_data.get("actions", [])

	# 找到客队最靠近球的球员
	var away_active = null
	var min_dist = INF
	for p in away_players:
		if p.is_goalkeeper:
			continue
		var d = p.position.distance_to(ball.position)
		if d < min_dist:
			min_dist = d
			away_active = p

	if away_active:
		var move_dir = Vector3(remote_input.x, 0, remote_input.y)
		away_active.input_direction = move_dir
		away_active.is_sprinting = remote_sprint
		away_active.is_player_controlled = true

		for action in remote_actions:
			match action:
				"pass": _do_pass_for(away_active)
				"shoot": _do_shoot_for(away_active)
				"tackle": _do_tackle_for(away_active)
				"cross": _do_cross_for(away_active)
				"lob": _do_lob_for(away_active)

func _do_pass_for(player: Node):
	if ball_owner != player:
		return
	var team = away_players if player.team_side == GameState.TeamSide.AWAY else home_players
	var forward_dir = 1 if player.team_side == GameState.TeamSide.HOME else -1
	var best_target = null
	var best_score = -INF
	for p in team:
		if p == player:
			continue
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
		ball_height_velocity = 0.5
		ball_owner = null

func _do_shoot_for(player: Node):
	if ball_owner != player:
		return
	var target_goal_z = GameState.FIELD_LENGTH / 2 if player.team_side == GameState.TeamSide.HOME else -GameState.FIELD_LENGTH / 2
	var dir = Vector3(randf_range(-3, 3) - player.position.x * 0.1, 0, target_goal_z - player.position.z).normalized()
	ball_velocity = dir * SHOT_SPEED
	ball_height_velocity = 3.0
	ball_owner = null
	last_touch_team = player.team_side
	last_touch_player = player

func _do_tackle_for(player: Node):
	var opp_team = home_players if player.team_side == GameState.TeamSide.AWAY else away_players
	var tackle_radius = player.stats.get("tackle_radius", 2.0)
	for p in opp_team:
		var dist = player.position.distance_to(p.position)
		if dist < tackle_radius:
			if randf() < ai_params.get("tackle_success", 0.6):
				if ball_owner == p:
					ball_owner = null
				var dir = (ball.position - player.position)
				dir.y = 0
				dir = dir.normalized()
				ball_velocity = dir * 8.0
				ball_height_velocity = 1.0
				return

func _do_cross_for(player: Node):
	if ball_owner != player:
		return
	var team = away_players if player.team_side == GameState.TeamSide.AWAY else home_players
	var target_goal_z = GameState.FIELD_LENGTH / 2 if player.team_side == GameState.TeamSide.HOME else -GameState.FIELD_LENGTH / 2
	var best_target = null
	var best_dist = INF
	for p in team:
		if p == player or p.is_goalkeeper:
			continue
		if abs(p.position.z - target_goal_z) < 20:
			var d = abs(p.position.x)
			if d < best_dist:
				best_dist = d
				best_target = p
	if best_target:
		var dir = (best_target.position - player.position)
		dir.y = 0
		dir = dir.normalized()
		ball_velocity = dir * CROSS_SPEED
		ball_height_velocity = 6.0
		ball_spin = 0.3
		ball_owner = null

func _do_lob_for(player: Node):
	if ball_owner != player:
		return
	var forward = player.facing_direction if player.facing_direction else Vector3.FORWARD
	ball_velocity = Vector3(forward.x, 0, forward.z) * LOB_SPEED
	ball_height_velocity = 8.0
	ball_owner = null
