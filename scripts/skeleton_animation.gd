## skeleton_animation.gd
## 骨骼动画系统
## 使用Skeleton3D + AnimationPlayer实现骨骼动画
## 替代程序化简单动画
extends Node3D

var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var current_animation: String = "idle"

# 骨骼定义
const BONE_NAMES = {
	"root": 0,
	"hips": 1,
	"spine": 2,
	"chest": 3,
	"neck": 4,
	"head": 5,
	"left_shoulder": 6,
	"left_arm": 7,
	"left_hand": 8,
	"right_shoulder": 9,
	"right_arm": 10,
	"right_hand": 11,
	"left_thigh": 12,
	"left_shin": 13,
	"left_foot": 14,
	"right_thigh": 15,
	"right_shin": 16,
	"right_foot": 17,
}

## 创建骨骼
func create_skeleton():
	skeleton = Skeleton3D.new()

	# 定义骨骼层级
	var bones = [
		{"name": "root", "parent": -1},
		{"name": "hips", "parent": 0},
		{"name": "spine", "parent": 1},
		{"name": "chest", "parent": 2},
		{"name": "neck", "parent": 3},
		{"name": "head", "parent": 4},
		{"name": "left_shoulder", "parent": 3},
		{"name": "left_arm", "parent": 6},
		{"name": "left_hand", "parent": 7},
		{"name": "right_shoulder", "parent": 3},
		{"name": "right_arm", "parent": 9},
		{"name": "right_hand", "parent": 10},
		{"name": "left_thigh", "parent": 1},
		{"name": "left_shin", "parent": 12},
		{"name": "left_foot", "parent": 13},
		{"name": "right_thigh", "parent": 1},
		{"name": "right_shin", "parent": 15},
		{"name": "right_foot", "parent": 16},
	]

	# 添加骨骼
	for bone in bones:
		skeleton.add_bone(bone.name)
		skeleton.set_bone_parent(skeleton.find_bone(bone.name), bone.parent)

	# 设置骨骼初始位置
	_set_bone_rest("hips", Vector3(0, 1.0, 0))
	_set_bone_rest("spine", Vector3(0, 0.2, 0))
	_set_bone_rest("chest", Vector3(0, 0.2, 0))
	_set_bone_rest("neck", Vector3(0, 0.15, 0))
	_set_bone_rest("head", Vector3(0, 0.15, 0))
	_set_bone_rest("left_shoulder", Vector3(-0.2, 0.1, 0))
	_set_bone_rest("left_arm", Vector3(-0.25, 0, 0))
	_set_bone_rest("left_hand", Vector3(-0.25, 0, 0))
	_set_bone_rest("right_shoulder", Vector3(0.2, 0.1, 0))
	_set_bone_rest("right_arm", Vector3(0.25, 0, 0))
	_set_bone_rest("right_hand", Vector3(0.25, 0, 0))
	_set_bone_rest("left_thigh", Vector3(-0.12, -0.1, 0))
	_set_bone_rest("left_shin", Vector3(0, -0.4, 0))
	_set_bone_rest("left_foot", Vector3(0, -0.4, 0.05))
	_set_bone_rest("right_thigh", Vector3(0.12, -0.1, 0))
	_set_bone_rest("right_shin", Vector3(0, -0.4, 0))
	_set_bone_rest("right_foot", Vector3(0, -0.4, 0.05))

	add_child(skeleton)

	# 创建动画播放器
	animation_player = AnimationPlayer.new()
	add_child(animation_player)

	# 创建动画
	_create_idle_animation()
	_create_run_animation()
	_create_kick_animation()
	_create_tackle_animation()

## 设置骨骼静止位置
func _set_bone_rest(bone_name: String, pos: Vector3):
	var idx = skeleton.find_bone(bone_name)
	if idx >= 0:
		var rest = skeleton.get_bone_rest(idx)
		rest.origin = pos
		skeleton.set_bone_rest(idx, rest)

## 创建待机动画
func _create_idle_animation():
	var anim = Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 2.0

	# 呼吸动画
	var track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(track, "Skeleton3D:chest")

	for i in range(5):
		var t = i * 0.5
		var rot = Quaternion.from_euler(Vector3(deg_to_rad(1 * sin(t * PI)), 0, 0))
		anim.rotation_track_insert_key(track, t, rot)

	animation_player.get_animation_library("").add_animation("idle", anim)

## 创建跑步动画
func _create_run_animation():
	var anim = Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 0.6

	# 左臂摆动
	var left_arm_track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(left_arm_track, "Skeleton3D:left_arm")

	# 右臂摆动
	var right_arm_track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(right_arm_track, "Skeleton3D:right_arm")

	# 左腿摆动
	var left_thigh_track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(left_thigh_track, "Skeleton3D:left_thigh")

	# 右腿摆动
	var right_thigh_track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(right_thigh_track, "Skeleton3D:right_thigh")

	# 关键帧
	for i in range(9):
		var t = i * 0.075
		var phase = t / 0.6 * TAU

		# 手臂前后摆动
		anim.rotation_track_insert_key(left_arm_track, t, Quaternion.from_euler(Vector3(sin(phase) * 0.8, 0, 0)))
		anim.rotation_track_insert_key(right_arm_track, t, Quaternion.from_euler(Vector3(-sin(phase) * 0.8, 0, 0)))

		# 腿部交替摆动
		anim.rotation_track_insert_key(left_thigh_track, t, Quaternion.from_euler(Vector3(-sin(phase) * 0.6, 0, 0)))
		anim.rotation_track_insert_key(right_thigh_track, t, Quaternion.from_euler(Vector3(sin(phase) * 0.6, 0, 0)))

	animation_player.get_animation_library("").add_animation("run", anim)

## 创建踢球动画
func _create_kick_animation():
	var anim = Animation.new()
	anim.length = 0.5

	# 右腿踢球
	var right_thigh_track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(right_thigh_track, "Skeleton3D:right_thigh")

	var right_shin_track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(right_shin_track, "Skeleton3D:right_shin")

	# 右臂平衡
	var right_arm_track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(right_arm_track, "Skeleton3D:right_arm")

	# 关键帧：抬腿→踢出→收回
	anim.rotation_track_insert_key(right_thigh_track, 0.0, Quaternion.from_euler(Vector3(0, 0, 0)))
	anim.rotation_track_insert_key(right_thigh_track, 0.2, Quaternion.from_euler(Vector3(-1.2, 0, 0)))
	anim.rotation_track_insert_key(right_thigh_track, 0.35, Quaternion.from_euler(Vector3(0.8, 0, 0)))
	anim.rotation_track_insert_key(right_thigh_track, 0.5, Quaternion.from_euler(Vector3(0, 0, 0)))

	anim.rotation_track_insert_key(right_shin_track, 0.0, Quaternion.from_euler(Vector3(0, 0, 0)))
	anim.rotation_track_insert_key(right_shin_track, 0.2, Quaternion.from_euler(Vector3(1.5, 0, 0)))
	anim.rotation_track_insert_key(right_shin_track, 0.35, Quaternion.from_euler(Vector3(-0.3, 0, 0)))
	anim.rotation_track_insert_key(right_shin_track, 0.5, Quaternion.from_euler(Vector3(0, 0, 0)))

	anim.rotation_track_insert_key(right_arm_track, 0.0, Quaternion.from_euler(Vector3(0, 0, 0)))
	anim.rotation_track_insert_key(right_arm_track, 0.2, Quaternion.from_euler(Vector3(0.8, 0, 0)))
	anim.rotation_track_insert_key(right_arm_track, 0.35, Quaternion.from_euler(Vector3(-0.5, 0, 0)))
	anim.rotation_track_insert_key(right_arm_track, 0.5, Quaternion.from_euler(Vector3(0, 0, 0)))

	animation_player.get_animation_library("").add_animation("kick", anim)

## 创建铲球动画
func _create_tackle_animation():
	var anim = Animation.new()
	anim.length = 0.8

	# 身体下蹲
	var spine_track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(spine_track, "Skeleton3D:spine")

	# 左腿铲出
	var left_thigh_track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(left_thigh_track, "Skeleton3D:left_thigh")

	# 关键帧
	anim.rotation_track_insert_key(spine_track, 0.0, Quaternion.from_euler(Vector3(0, 0, 0)))
	anim.rotation_track_insert_key(spine_track, 0.3, Quaternion.from_euler(Vector3(0.8, 0, 0)))
	anim.rotation_track_insert_key(spine_track, 0.6, Quaternion.from_euler(Vector3(0.8, 0, 0)))
	anim.rotation_track_insert_key(spine_track, 0.8, Quaternion.from_euler(Vector3(0, 0, 0)))

	anim.rotation_track_insert_key(left_thigh_track, 0.0, Quaternion.from_euler(Vector3(0, 0, 0)))
	anim.rotation_track_insert_key(left_thigh_track, 0.3, Quaternion.from_euler(Vector3(-0.8, 0, 0)))
	anim.rotation_track_insert_key(left_thigh_track, 0.5, Quaternion.from_euler(Vector3(0.5, 0, 0)))
	anim.rotation_track_insert_key(left_thigh_track, 0.8, Quaternion.from_euler(Vector3(0, 0, 0)))

	animation_player.get_animation_library("").add_animation("tackle", anim)

## 播放动画
func play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
		current_animation = anim_name

## 获取当前动画
func get_current_animation() -> String:
	return current_animation

## 设置动画速度
func set_animation_speed(speed: float):
	if animation_player:
		animation_player.speed_scale = speed
