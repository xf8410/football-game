## mod_system.gd
## Mod支持系统 (Autoload Singleton)
## 允许玩家自定义球员、球队、联赛
## Mod文件放在 user://mods/ 目录下，JSON格式
extends Node

signal mod_loaded(mod_id: String)
signal mod_unloaded(mod_id: String)

var loaded_mods: Dictionary = {}  # mod_id -> mod_data
var mods_dir: String = "user://mods/"

func _ready():
	DirAccess.make_dir_recursive_absolute(mods_dir)
	_load_all_mods()

## 加载所有mod
func _load_all_mods():
	var dir = DirAccess.open(mods_dir)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var mod_path = mods_dir + file_name
			var mod = _load_mod_file(mod_path)
			if not mod.is_empty():
				var mod_id = file_name.get_basename()
				loaded_mods[mod_id] = mod
				_apply_mod(mod)
				mod_loaded.emit(mod_id)
				print("[Mod] 已加载: %s (%s)" % [mod_id, mod.get("name", "未知")])
		file_name = dir.get_next()
	dir.list_dir_end()
	print("[Mod] 共加载 %d 个mod" % loaded_mods.size())

## 加载单个mod文件
func _load_mod_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		print("[Mod] 解析失败: %s" % path)
		return {}
	file.close()
	return json.data

## 应用mod到游戏数据库
func _apply_mod(mod: Dictionary):
	# 应用自定义球员
	if mod.has("players"):
		for pid in mod.players:
			if not PlayerDatabase.players_data.has(pid):
				PlayerDatabase.players_data[pid] = mod.players[pid]
				print("[Mod] 添加球员: %s" % mod.players[pid].get("name", pid))

	# 应用自定义球队
	if mod.has("teams"):
		for tid in mod.teams:
			if not TeamDatabase.clubs.has(tid):
				TeamDatabase.clubs[tid] = mod.teams[tid]
				print("[Mod] 添加球队: %s" % mod.teams[tid].get("name", tid))

	# 应用自定义联赛
	if mod.has("leagues"):
		for lid in mod.leagues:
			if not TeamDatabase.leagues.has(lid):
				TeamDatabase.leagues[lid] = mod.leagues[lid]
				print("[Mod] 添加联赛: %s" % mod.leagues[lid].get("name", lid))

## 创建mod模板
func create_mod_template(mod_id: String, mod_name: String) -> String:
	var mod_data = {
		"name": mod_name,
		"version": "1.0",
		"author": "Player",
		"description": "自定义mod",
		"players": {
			"custom_player_1": {
				"name": "自定义球员",
				"short_name": "自定义",
				"nationality": "中国",
				"positions": ["ST"],
				"preferred_foot": "right",
				"attributes": {"pace": 80, "shooting": 80, "passing": 75, "dribbling": 80, "defending": 40, "physical": 75},
				"traits": ["long_shot"],
				"skills": ["speed_burst"],
				"career": [{"club": "custom_team", "years": "2024"}]
			}
		},
		"teams": {
			"custom_team": {
				"name": "自定义球队",
				"short_name": "自定义",
				"league": "custom_league",
				"city": "自定义城市",
				"country": "中国",
				"stadium": "自定义球场",
				"primary_color": "#FF0000",
				"secondary_color": "#FFFFFF",
				"formation": "4-4-2",
				"rating": 80,
				"players": ["custom_player_1"]
			}
		},
		"leagues": {
			"custom_league": {
				"name": "自定义联赛",
				"short_name": "自定义",
				"country": "中国",
				"tier": 1,
				"team_count": 1,
				"color": "#FF0000"
			}
		}
	}

	var path = mods_dir + mod_id + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(mod_data, "  "))
		file.close()
		print("[Mod] 已创建mod模板: %s" % path)
	return path

## 获取已加载的mod列表
func get_loaded_mods() -> Dictionary:
	return loaded_mods

## 重新加载所有mod
func reload_all_mods():
	loaded_mods.clear()
	_load_all_mods()

## 获取mod目录路径
func get_mods_dir() -> String:
	return mods_dir
