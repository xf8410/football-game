## match_controller.gd
## 比赛控制器（完善版）
## 整合所有系统：触屏操作、球员模型、动画、音效、体力、裁判
## 实现实际可玩的比赛
extends Node3D

# 场景节点
var camera: Camera3D
var field: MeshInstance3D
var ball: RigidBody3D
var ball_mesh: MeshInstance3D

# 球队
var home_players: Array = []
var away_players: Array = []
var home_score: int = 0
var away_score: int = 0

# 当前控制
var active_player: CharacterBody3D = null
var player_side: int = 0

# 比赛状态
var match_time: float = 0.0
var half_duration: float = 180.0
var current_half: int = 1
var is_playing: bool = false

# 触屏操作
var touch_controls: CanvasLayer
var move_input: Vector2 = Vector2.ZERO
var is_sprinting: bool = false

# 球的物理
var ball_velocity: Vector3 = Vector3.ZERO
var ball_height: float = 0.0
var ball_height_velocity: float = 0.0
var ball_owner: Node = null

# 常量
const BALL_RADIUS: float = 0.11
const BALL_FRICTION: float = 0.5
const BALL_GRAVITY: float = 9.8
const PASS_SPEED: float = 18.0
const SHOT_SPEED: float = 28.0
const CAMERA_HEIGHT: float = 45.0
const CAMERA_DISTANCE: float = 30.0

func _ready():
	_setup_scene()
	_setup_camera()
	_setup_field()
	_setup_teams()
	_setup_ball()
	_setup_touch_controls()
	_setup_ui()
	_kickoff()

func _setup_scene():
	# 环境光
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.4, 0.6, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.7, 0.8)
	env.ambient_light_energy = 0.6

	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# 方向光
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

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

func _setup_field():
	field = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(GameState.FIELD_LENGTH + 10, GameState.FIELD_WIDTH + 10)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.45, 0.15)
	plane.material = mat
	field.mesh = plane
	add_child(field)

	# 球场线条
	_create_field_lines()
	# 球门
	_create_goals()

func _create_field_lines():
	# 边线
	_create_line(Vector3(0, 0.01, -GameState.FIELD_WIDTH/2), Vector2(GameState.FIELD_LENGTH, 0.2))
	_create_line(Vector3(0, 0.01, GameState.FIELD_WIDTH/2), Vector2(GameState.FIELD_LENGTH, 0.2))
	_create_line(Vector3(-GameState.FIELD_LENGTH/2, 0.01, 0), Vector2(0.2, GameState.FIELD_WIDTH))
	_create_line(Vector3(GameState.FIELD_LENGTH/2, 0.01, 0), Vector2(0.2, GameState.FIELD_WIDTH))
	# 中线
	_create_line(Vector3(0, 0.01, 0), Vector2(0.2, GameState.FIELD_WIDTH))
	# 中圈
	var circle = MeshInstance3D.new()
	var circle_mesh = CylinderMesh.new()
	circle_mesh.top_radius = 9.15
	circle_mesh.bottom_radius = 9.15
	circle_mesh.height = 0.02
	circle.mesh = circle_mesh
	var circle_mat = StandardMaterial3D.new()
	circle_mat.albedo_color = Color(1, 1, 1, 0.3)
	circle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	circle.material_override = circle_mat
	add_child(circle)

func _create_line(pos: Vector3, size: Vector2):
	var line = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(size.x, 0.02, size.y)
	line.mesh = box
	line.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.8)
	line.material_override = mat
	add_child(line)

func _create_goals():
	# 主队球门
	_create_goal(Vector3(0, 0, -GameState.FIELD_LENGTH/2))
	# 客队球门
	_create_goal(Vector3(0, 0, GameState.FIELD_LENGTH/2))

func _create_goal(pos: Vector3):
	# 球门柱
	for x in [-GameState.GOAL_WIDTH/2, GameState.GOAL_WIDTH/2]:
		var post = MeshInstance3D.new()
		var post_mesh = CylinderMesh.new()
		post_mesh.radius = 0.06
		post_mesh.height = GameState.GOAL_HEIGHT
		post.mesh = post_mesh
		post.position = pos + Vector3(x, GameState.GOAL_HEIGHT/2, 0)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 1)
		post.material_override = mat
		add_child(post)

	# 横梁
	var bar = MeshInstance3D.new()
	var bar_mesh = CylinderMesh.new()
	bar_mesh.radius = 0.06
	bar_mesh.height = GameState.GOAL_WIDTH
	bar.mesh = bar_mesh
	bar.position = pos + Vector3(0, GameState.GOAL_HEIGHT, 0)
	bar.rotation_degrees = Vector3(0, 0, 90)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1)
	bar.material_override = mat
	add_child(bar)

func _setup_teams():
	var formation = GameState.get_formation("4-4-2")
	home_players = _create_team(formation, 0, Color(0.9, 0.15, 0.15))
	away_players = _create_team(formation, 1, Color(0.15, 0.3, 0.9))
	_switch_active_player()

func _create_team(formation: Array, side: int, color: Color) -> Array:
	var players = []
	for i in range(formation.size()):
		var role_data = formation[i]
		var role = role_data[0]
		var x = role_data[1]
		var z = role_data[2]
		if side == 1:
			z = -z

		var player = CharacterBody3D.new()
		player.position = Vector3(x, 0, z)

		# 球员模型
		var body = MeshInstance3D.new()
		var body_mesh = CapsuleMesh.new()
		body_mesh.radius = 0.35
		body_mesh.height = 1.8
		body.mesh = body_mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		body.material_override = mat
		body.position = Vector3(0, 0.9, 0)
		player.add_child(body)

		# 号码标签
		var number_label = Label3D.new()
		number_label.text = str(i + 1)
		number_label.position = Vector3(0, 2.2, 0)
		number_label.font_size = 32
		player.add_child(number_label)

		# 方向箭头（活跃球员）
		if i == 0:
			var arrow = MeshInstance3D.new()
			var arrow_mesh = ConeMesh.new()
			arrow_mesh.radius = 0.3
			arrow_mesh.height = 0.5
			arrow.mesh = arrow_mesh
			arrow.position = Vector3(0, 2.5, 0)
			var arrow_mat = StandardMaterial3D.new()
			arrow_mat.albedo_color = Color(1, 1, 0)
			arrow_mat.emission_enabled = true
			arrow_mat.emission = Color(1, 1, 0)
			arrow_mat.emission_energy_multiplier = 0.5
			arrow.material_override = arrow_mat
			player.add_child(arrow)

		player.set("team_side", side)
		player.set("is_goalkeeper", role == "GK")
		player.set("home_position", Vector3(x, 0, z))
		player.set("player_index", i + 1)
		player.set("current_stamina", 100.0)

		add_child(player)
		players.append(player)

	return players

func _setup_ball():
	ball = RigidBody3D.new()
	ball_mesh = MeshInstance3D.new()
	var ball_sphere = SphereMesh.new()
	ball_sphere.radius = BALL_RADIUS
	ball_sphere.height = BALL_RADIUS * 2
	ball_mesh.mesh = ball_sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1)
	ball_mesh.material_override = mat
	ball.add_child(ball_mesh)

	# 球的碰撞
	var shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = BALL_RADIUS
	shape.shape = sphere_shape
	ball.add_child(shape)

	ball.position = Vector3(0, BALL_RADIUS, 0)
	add_child(ball)

func _setup_touch_controls():
	# 加载触屏操作场景
	var touch_scene = load("res://scripts/touch_controls.gd")
	touch_controls = CanvasLayer.new()
	touch_controls.set_script(touch_scene)
	add_child(touch_controls)

	touch_controls.move_input_changed.connect(_on_move_input)
	touch_controls.action_pressed.connect(_on_action_pressed)

func _setup_ui():
	var ui = CanvasLayer.new()

	# 比分
	var score_label = Label.new()
	score_label.text = "0 - 0"
	score_label.add_theme_font_size_override("font_size", 36)
	score_label.add_theme_color_override("font_color", Color.YELLOW)
	score_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 50, 20)
	score_label.size = Vector2(100, 45)
	ui.add_child(score_label)
	score_label.set_meta("score", true)

	# 时间
	var time_label = Label.new()
	time_label.text = "00:00"
	time_label.add_theme_font_size_override("font_size", 24)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 50, 70)
	time_label.size = Vector2(100, 30)
	ui.add_child(time_label)
	time_label.set_meta("time", true)

	add_child(ui)

func _kickoff():
	ball.position = Vector3(0, BALL_RADIUS, 0)
	ball_velocity = Vector3.ZERO
	ball_height = 0
	ball_height_velocity = 0
	ball_owner = null
	is_playing = true
	match_time = 0
	Commentary.trigger("kickoff")

func _process(delta):
	if is_playing:
		match_time += delta
		_update_ball(delta)
		_update_players(delta)
		_update_camera()
		_check_goals()
		_check_out_of_bounds()
		_update_ui()

func _update_ball(delta):
	if ball_owner != null and is_instance_valid(ball_owner):
		# 球跟随控球者
		var forward = -ball_owner.global_transform.basis.z
		ball.global_position = ball_owner.global_position + forward * 0.8 + Vector3(0, BALL_RADIUS, 0)
		ball_velocity = Vector3.ZERO
		ball_height = 0
		ball_height_velocity = 0
	else:
		# 球的物理
		ball_velocity *= (1.0 - BALL_FRICTION * delta)
		ball.global_position += ball_velocity * delta

		# 高度物理
		ball_height += ball_height_velocity * delta
		ball_height_velocity -= BALL_GRAVITY * delta
		if ball_height < 0:
			ball_height = 0
			ball_height_velocity *= -0.5  # 弹跳
			if abs(ball_height_velocity) < 0.5:
				ball_height_velocity = 0

		ball_mesh.position.y = ball_height

		# 检查控球
		_check_ball_possession()

func _check_ball_possession():
	var nearest_player = null
	var nearest_dist = 1.5  # 控球半径

	for p in home_players + away_players:
		if p == null or not is_instance_valid(p):
			continue
		var dist = p.global_position.distance_to(ball.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_player = p

	if nearest_player != null:
		ball_owner = nearest_player
		# 如果是玩家球队，切换活跃球员
		if nearest_player.get("team_side") == player_side:
			active_player = nearest_player

func _update_players(delta):
	# 更新玩家控制的活跃球员
	if active_player != null and is_instance_valid(active_player):
		var move_dir = Vector3(move_input.x, 0, move_input.y)
		active_player.velocity = move_dir * (8.0 if is_sprinting else 5.0)
		active_player.move_and_slide()

		# 体力消耗
		var stamina = active_player.get("current_stamina")
		if is_sprinting:
			stamina -= 2.5 * delta
		elif move_dir.length() > 0.1:
			stamina -= 0.8 * delta
		else:
			stamina += 3.0 * delta
		active_player.set("current_stamina", clamp(stamina, 0, 100))

	# 更新AI球员
	for p in home_players + away_players:
		if p == null or not is_instance_valid(p):
			continue
		if p == active_player:
			continue
		_update_ai_player(p, delta)

func _update_ai_player(player: Node, delta: float):
	var team_side = player.get("team_side")
	var is_gk = player.get("is_goalkeeper")

	if ball_owner == player:
		# AI控球：简单向前带球
		var target_goal_z = GameState.FIELD_LENGTH / 2 if team_side == 0 else -GameState.FIELD_LENGTH / 2
		var dir = Vector3(0, 0, target_goal_z - player.position.z).normalized()
		player.velocity = dir * 5.0
		player.move_and_slide()

		# 偶尔传球或射门
		if randf() < 0.01:
			_ai_shoot(player, team_side)
		elif randf() < 0.02:
			_ai_pass(player, team_side)
	elif not is_gk:
		# 追球或回位
		var dist_to_ball = player.position.distance_to(ball.position)
		if dist_to_ball < 15.0:
			# 追球
			var dir = (ball.position - player.position)
			dir.y = 0
			player.velocity = dir.normalized() * 6.0
		else:
			# 回位
			var home_pos = player.get("home_position")
			var dir = (home_pos - player.position)
			dir.y = 0
			if dir.length() > 1.0:
				player.velocity = dir.normalized() * 4.0
			else:
				player.velocity = Vector3.ZERO
		player.move_and_slide()

func _ai_shoot(player: Node, side: int):
	var target_goal_z = GameState.FIELD_LENGTH / 2 if side == 0 else -GameState.FIELD_LENGTH / 2
	var dir = Vector3(randf_range(-3, 3), 0, target_goal_z - player.position.z).normalized()
	ball_velocity = dir * SHOT_SPEED
	ball_height_velocity = 3.0
	ball_owner = null
	AudioManager.play_sfx(AudioManager.SFX.KICK_HEAVY)
	Commentary.trigger("shot_on_target")

func _ai_pass(player: Node, side: int):
	var team = home_players if side == 0 else away_players
	var forward_dir = 1 if side == 0 else -1
	var best_target = null
	var best_score = -INF

	for p in team:
		if p == player:
			continue
		var forward_score = (p.position.z - player.position.z) * forward_dir
		var dist = player.position.distance_to(p.position)
		if dist > 5 and dist < 35 and forward_score > 0:
			var score = forward_score - dist * 0.2
			if score > best_score:
				best_score = score
				best_target = p

	if best_target:
		var dir = (best_target.position - player.position)
		dir.y = 0
		dir = dir.normalized()
		ball_velocity = dir * PASS_SPEED
		ball_owner = null
		AudioManager.play_sfx(AudioManager.SFX.PASS)

func _update_camera():
	if active_player != null and is_instance_valid(active_player):
		_position_camera(active_player.position)

func _check_goals():
	var ball_pos = ball.global_position

	# 主队球门（Z = -FIELD_LENGTH/2）
	if ball_pos.z < -GameState.FIELD_LENGTH / 2 and abs(ball_pos.x) < GameState.GOAL_WIDTH / 2:
		away_score += 1
		_on_goal(1)
	# 客队球门（Z = +FIELD_LENGTH/2）
	elif ball_pos.z > GameState.FIELD_LENGTH / 2 and abs(ball_pos.x) < GameState.GOAL_WIDTH / 2:
		home_score += 1
		_on_goal(0)

func _on_goal(scoring_team: int):
	AudioManager.play_sfx(AudioManager.SFX.GOAL)
	AudioManager.play_sfx(AudioManager.SFX.CROWD_CHEER)
	Commentary.trigger("goal")
	print("[Match] 进球！比分 %d - %d" % [home_score, away_score])
	_kickoff()

func _check_out_of_bounds():
	var ball_pos = ball.global_position

	# 出界
	if abs(ball_pos.x) > GameState.FIELD_WIDTH / 2 or abs(ball_pos.z) > GameState.FIELD_LENGTH / 2:
		# 简化：重置到中圈
		ball.position = Vector3(0, BALL_RADIUS, 0)
		ball_velocity = Vector3.ZERO
		ball_owner = null

func _update_ui():
	var ui = get_child(get_child_count() - 1)
	for child in ui.get_children():
		if child.has_meta("score"):
			child.text = "%d - %d" % [home_score, away_score]
		elif child.has_meta("time"):
			var minutes = int(match_time / 60)
			var seconds = int(match_time) % 60
			child.text = "%02d:%02d" % [minutes, seconds]

	# 检查半场结束
	if match_time >= half_duration:
		if current_half == 1:
			current_half = 2
			match_time = 0
			Commentary.trigger("halftime")
		else:
			_end_match()

func _end_match():
	is_playing = false
	Commentary.trigger("fulltime")
	print("[Match] 比赛结束！最终比分 %d - %d" % [home_score, away_score])

	# 更新存档
	var player_score = home_score if player_side == 0 else away_score
	var opponent_score = away_score if player_side == 0 else home_score
	var won = player_score > opponent_score
	var drawn = player_score == opponent_score
	SaveManager.update_match_result(won, drawn, player_score, opponent_score)

func _on_move_input(direction: Vector2):
	move_input = direction

func _on_action_pressed(action: String):
	match action:
		"pass":
			_do_pass()
		"shoot":
			_do_shoot()
		"through":
			_do_through_ball()
		"tackle":
			_do_tackle()
		"switch":
			_switch_active_player()
		"sprint":
			is_sprinting = !is_sprinting
		"cross":
			_do_cross()
		"press":
			_do_press()

func _do_pass():
	if ball_owner != active_player:
		return
	var team = home_players if player_side == 0 else away_players
	var best_target = null
	var best_score = -INF
	for p in team:
		if p == active_player:
			continue
		var forward_dir = 1 if player_side == 0 else -1
		var forward_score = (p.position.z - active_player.position.z) * forward_dir
		var dist = active_player.position.distance_to(p.position)
		if dist > 3 and dist < 35 and forward_score > 0:
			var score = forward_score - dist * 0.2
			if score > best_score:
				best_score = score
				best_target = p
	if best_target:
		var dir = (best_target.position - active_player.position)
		dir.y = 0
		dir = dir.normalized()
		ball_velocity = dir * PASS_SPEED
		ball_owner = null
		AudioManager.play_sfx(AudioManager.SFX.PASS)

func _do_shoot():
	if ball_owner != active_player:
		return
	var target_goal_z = GameState.FIELD_LENGTH / 2 if player_side == 0 else -GameState.FIELD_LENGTH / 2
	var dir = Vector3(randf_range(-3, 3), 0, target_goal_z - active_player.position.z).normalized()
	ball_velocity = dir * SHOT_SPEED
	ball_height_velocity = 3.0
	ball_owner = null
	AudioManager.play_sfx(AudioManager.SFX.KICK_HEAVY)
	Commentary.trigger("shot_on_target")

func _do_through_ball():
	if ball_owner != active_player:
		return
	var team = home_players if player_side == 0 else away_players
	var forward_dir = 1 if player_side == 0 else -1
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
		var lead = Vector3(0, 0, forward_dir * 5)
		var target_pos = best_target.position + lead
		var dir = (target_pos - active_player.position)
		dir.y = 0
		dir = dir.normalized()
		ball_velocity = dir * (PASS_SPEED * 1.2)
		ball_height_velocity = 1.0
		ball_owner = null
		AudioManager.play_sfx(AudioManager.SFX.PASS)

func _do_tackle():
	if active_player == null:
		return
	var opp_team = away_players if player_side == 0 else home_players
	for p in opp_team:
		var dist = active_player.position.distance_to(p.position)
		if dist < 2.0:
			if randf() < 0.6:
				if ball_owner == p:
					ball_owner = null
				var dir = (ball.position - active_player.position)
				dir.y = 0
				dir = dir.normalized()
				ball_velocity = dir * 8.0
				ball_height_velocity = 1.0
				AudioManager.play_sfx(AudioManager.SFX.TACKLE)
				Commentary.trigger("tackle")
				return

func _do_cross():
	if ball_owner != active_player:
		return
	var team = home_players if player_side == 0 else away_players
	var target_goal_z = GameState.FIELD_LENGTH / 2 if player_side == 0 else -GameState.FIELD_LENGTH / 2
	var best_target = null
	var best_dist = INF
	for p in team:
		if p == active_player or p.get("is_goalkeeper"):
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
		ball_velocity = dir * 15.0
		ball_height_velocity = 6.0
		ball_owner = null
		AudioManager.play_sfx(AudioManager.SFX.KICK_LIGHT)

func _do_press():
	# 压迫：向球的方向加速
	if active_player == null:
		return
	var dir = (ball.position - active_player.position)
	dir.y = 0
	if dir.length() > 0.1:
		active_player.velocity = dir.normalized() * 10.0

func _switch_active_player():
	var team = home_players if player_side == 0 else away_players
	if team.is_empty():
		return

	var best_player = null
	var best_dist = INF
	for p in team:
		if p.get("is_goalkeeper"):
			continue
		var dist = p.position.distance_to(ball.position)
		if dist < best_dist:
			best_dist = dist
			best_player = p

	if best_player == null and team.size() > 0:
		best_player = team[0]

	if active_player != null and is_instance_valid(active_player):
		# 移除旧箭头
		for child in active_player.get_children():
			if child is MeshInstance3D and child.name == "Arrow":
				child.queue_free()

	active_player = best_player

	if active_player != null:
		# 添加新箭头
		var arrow = MeshInstance3D.new()
		arrow.name = "Arrow"
		var arrow_mesh = ConeMesh.new()
		arrow_mesh.radius = 0.3
		arrow_mesh.height = 0.5
		arrow.mesh = arrow_mesh
		arrow.position = Vector3(0, 2.5, 0)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 0)
		mat.emission_enabled = true
		mat.emission = Color(1, 1, 0)
		mat.emission_energy_multiplier = 0.5
		arrow.material_override = mat
		active_player.add_child(arrow)

func _input(event):
	if event.is_action_pressed("switch_player"):
		_switch_active_player()
	if event.is_action_pressed("pause"):
		is_playing = !is_playing
