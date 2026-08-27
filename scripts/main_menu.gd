## main_menu.gd
## 主菜单控制器
## 功能：快速比赛、玩家档案、设置、局域网联机、退出
extends Control

# UI节点引用
@onready var title_label = $VBoxContainer/TitleLabel
@onready var play_button = $VBoxContainer/MenuContainer/PlayButton
@onready var league_button = $VBoxContainer/MenuContainer/LeagueButton
@onready var profile_button = $VBoxContainer/MenuContainer/ProfileButton
@onready var lan_button = $VBoxContainer/MenuContainer/LANButton
@onready var settings_button = $VBoxContainer/MenuContainer/SettingsButton
@onready var quit_button = $VBoxContainer/MenuContainer/QuitButton
@onready var profile_info = $VBoxContainer/ProfileInfo
@onready var version_label = $VersionLabel

func _ready():
        # 连接按钮信号
        play_button.pressed.connect(_on_play_pressed)
        league_button.pressed.connect(_on_league_pressed)
        profile_button.pressed.connect(_on_profile_pressed)
        lan_button.pressed.connect(_on_lan_pressed)
        settings_button.pressed.connect(_on_settings_pressed)
        quit_button.pressed.connect(_on_quit_pressed)

        # 显示玩家信息
        _update_profile_display()
        version_label.text = "v0.2.0-alpha | Godot 4.3"

        # 检查是否有进行中的联赛
        if LeagueManager.load_season():
                league_button.text = "🏆 联赛模式 (继续)"

        # 随机标题副文本
        var subtitles = [
                "绿茵场上，谁与争锋",
                "11v11 真实足球体验",
                "五大联赛 + 国家队",
                "单机畅玩，局域对战",
        ]
        title_label.text = "⚽ 足球游戏"
        $VBoxContainer/SubtitleLabel.text = subtitles[randi() % subtitles.size()]

func _update_profile_display():
        var profile = SaveManager.get_profile()
        profile_info.text = "教练：%s  |  等级：%d  |  金币：%d  |  战绩：%d胜%d平%d负" % [
                profile.get("name", "Player"),
                profile.get("level", 1),
                profile.get("coins", 0),
                profile.get("matches_won", 0),
                profile.get("matches_drawn", 0),
                profile.get("matches_lost", 0),
        ]

# ---- 按钮回调 ----

func _on_play_pressed():
        print("[MainMenu] 开始快速比赛")
        # 设置默认比赛配置
        GameState.set_match_config({
                "home_team_name": "红队",
                "away_team_name": "蓝队",
                "home_color": Color(0.9, 0.15, 0.15),
                "away_color": Color(0.15, 0.3, 0.9),
                "formation": "4-4-2",
                "difficulty": GameState.AIDifficulty.NORMAL,
                "half_duration": 180.0,
                "player_controls": GameState.TeamSide.HOME,
                "initial_score": [0, 0],
        })
        GameState.set_event({
                "name": "快速比赛",
                "type": "quick_match",
                "modifiers": {}
        })
        get_tree().change_scene_to_file("res://scenes/Match.tscn")

func _on_league_pressed():
        print("[MainMenu] 打开联赛模式")
        if LeagueManager.load_season() and LeagueManager.current_league_id != "":
                # 继续已有联赛
                get_tree().change_scene_to_file("res://scenes/LeagueHub.tscn")
        else:
                # 开始新联赛
                get_tree().change_scene_to_file("res://scenes/LeagueMenu.tscn")

func _on_profile_pressed():
        print("[MainMenu] 打开玩家档案")
        get_tree().change_scene_to_file("res://scenes/Profile.tscn")

func _on_lan_pressed():
        print("[MainMenu] 打开局域网联机")
        get_tree().change_scene_to_file("res://scenes/LANLobby.tscn")

func _on_settings_pressed():
        print("[MainMenu] 打开设置")
        get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_quit_pressed():
        print("[MainMenu] 退出游戏")
        get_tree().quit()
