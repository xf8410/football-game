## league_manager.gd
## 联赛管理器 (Autoload Singleton)
## 管理联赛赛程、积分榜、比赛结果、赛季进度
extends Node

signal standings_updated()
signal match_completed(result: Dictionary)

# 联赛状态
var current_league_id: String = ""
var current_season: Dictionary = {}
var league_standings: Array = []  # 积分榜
var fixtures: Array = []          # 赛程
var current_matchday: int = 0     # 当前轮次
var total_matchdays: int = 0      # 总轮次
var player_team_id: String = ""   # 玩家选择的球队

## 开始新联赛
func start_league(league_id: String, player_team: String) -> void:
        current_league_id = league_id
        player_team_id = player_team

        # 获取联赛中的所有球队
        var teams = TeamDatabase.get_clubs_by_league(league_id)
        var team_ids = teams.keys()
        team_ids.sort()  # 确保顺序一致

        # 生成赛程（双循环，主客场各一次）
        fixtures = _generate_fixtures(team_ids)
        total_matchdays = fixtures.size()
        current_matchday = 0

        # 初始化积分榜
        _init_standings(team_ids)

        # 保存赛季
        _save_season()
        print("[League] 联赛开始: %s, 球队数: %d, 总轮次: %d" % [league_id, team_ids.size(), total_matchdays])

## 生成双循环赛程（Round-Robin算法）
func _generate_fixtures(team_ids: Array) -> Array:
        var teams = team_ids.duplicate()
        # 如果球队数为奇数，添加一个"轮空"
        if teams.size() % 2 != 0:
                teams.append("bye")

        var n = teams.size()
        var half = n / 2
        var rounds = []

        # 固定第一支球队，其余轮转
        var fixed = teams[0]
        var rotating = teams.slice(1, n - 1)

        for round_num in range(n - 1):
                var matches = []
                var current = [fixed] + rotating

                for i in range(half):
                        var home = current[i]
                        var away = current[n - 1 - i]
                        if home != "bye" and away != "bye":
                                # 交替主客场
                                if round_num % 2 == 0:
                                        matches.append({"home": home, "away": away, "played": false, "result": null})
                                else:
                                        matches.append({"home": away, "away": home, "played": false, "result": null})

                rounds.append(matches)
                # 轮转
                rotating = [rotating[rotating.size() - 1]] + rotating.slice(0, rotating.size() - 2)

        # 第二循环（主客场对调）
        var second_half = []
        for round_num in range(n - 1):
                var matches = []
                var first_round = rounds[round_num]
                for m in first_round:
                        matches.append({"home": m.away, "away": m.home, "played": false, "result": null})
                second_half.append(matches)

        return rounds + second_half

## 初始化积分榜
func _init_standings(team_ids: Array):
        league_standings = []
        for tid in team_ids:
                league_standings.append({
                        "team_id": tid,
                        "played": 0,
                        "won": 0,
                        "drawn": 0,
                        "lost": 0,
                        "goals_for": 0,
                        "goals_against": 0,
                        "goal_diff": 0,
                        "points": 0,
                })

## 获取当前轮次的比赛
func get_current_fixtures_list() -> Array:
        if current_matchday < fixtures.size():
                return fixtures[current_matchday]
        return []

## 记录玩家比赛结果并推进到下一轮
func record_player_match_result(home_goals: int, away_goals: int) -> void:
        var player_match = get_next_player_match()
        if player_match.is_empty():
                return

        var result = {"home_goals": home_goals, "away_goals": away_goals}
        simulate_matchday(result)
        print("[League] 比赛结果已记录: %d-%d, 当前轮次: %d/%d" % [home_goals, away_goals, current_matchday, total_matchdays])

## 模拟一轮比赛（除玩家比赛外，其他AI vs AI自动模拟）
func simulate_matchday(player_match_result: Dictionary = {}) -> void:
        if current_matchday >= fixtures.size():
                return

        var current_fixtures = fixtures[current_matchday]

        for match in current_fixtures:
                if match.played:
                        continue

                var result
                if match.home == player_team_id or match.away == player_team_id:
                        # 玩家的比赛使用实际结果
                        result = player_match_result
                else:
                        # AI vs AI 自动模拟
                        result = _simulate_ai_match(match.home, match.away)

                match.played = true
                match.result = result
                _update_standings(match.home, match.away, result)

        current_matchday += 1
        _sort_standings()
        standings_updated.emit()
        _save_season()

## 模拟AI比赛结果
func _simulate_ai_match(home_id: String, away_id: String) -> Dictionary:
        var home_rating = TeamDatabase.get_team_rating(home_id)
        var away_rating = TeamDatabase.get_team_rating(away_id)

        # 主场优势
        home_rating += 5

        # 基于评分差计算预期进球
        var rating_diff = home_rating - away_rating
        var home_expected = 1.5 + rating_diff * 0.03
        var away_expected = 1.3 - rating_diff * 0.03

        # 随机波动
        var home_goals = max(0, int(round(home_expected + randf_range(-1.2, 1.2))))
        var away_goals = max(0, int(round(away_expected + randf_range(-1.2, 1.2))))

        # 避免极端比分
        home_goals = min(home_goals, 6)
        away_goals = min(away_goals, 6)

        return {
                "home_score": home_goals,
                "away_score": away_goals,
                "home_team": home_id,
                "away_team": away_id,
                "scorers": [],  # AI比赛不记录进球者
        }

## 更新积分榜
func _update_standings(home_id: String, away_id: String, result: Dictionary):
        var home_score = result.get("home_score", 0)
        var away_score = result.get("away_score", 0)

        for team in league_standings:
                if team.team_id == home_id:
                        team.played += 1
                        team.goals_for += home_score
                        team.goals_against += away_score
                        if home_score > away_score:
                                team.won += 1
                                team.points += 3
                        elif home_score == away_score:
                                team.drawn += 1
                                team.points += 1
                        else:
                                team.lost += 1
                elif team.team_id == away_id:
                        team.played += 1
                        team.goals_for += away_score
                        team.goals_against += home_score
                        if away_score > home_score:
                                team.won += 1
                                team.points += 3
                        elif home_score == away_score:
                                team.drawn += 1
                                team.points += 1
                        else:
                                team.lost += 1

        for team in league_standings:
                team.goal_diff = team.goals_for - team.goals_against

## 排序积分榜
func _sort_standings():
        league_standings.sort_custom(func(a, b):
                if a.points != b.points:
                        return a.points > b.points
                if a.goal_diff != b.goal_diff:
                        return a.goal_diff > b.goal_diff
                if a.goals_for != b.goals_for:
                        return a.goals_for > b.goals_for
                return a.team_id < b.team_id
        )

## 获取积分榜
func get_standings() -> Array:
        return league_standings

## 获取玩家排名
func get_player_rank() -> int:
        for i in range(league_standings.size()):
                if league_standings[i].team_id == player_team_id:
                        return i + 1
        return 0

## 联赛是否结束
func is_league_finished() -> bool:
        return current_matchday >= total_matchdays

## 获取联赛冠军
func get_champion() -> String:
        if not is_league_finished():
                return ""
        if league_standings.size() > 0:
                return league_standings[0].team_id
        return ""

## 保存赛季到本地存档
func _save_season():
        var data = {
                "league_id": current_league_id,
                "player_team": player_team_id,
                "current_matchday": current_matchday,
                "total_matchdays": total_matchdays,
                "standings": league_standings,
                "fixtures": fixtures,
        }
        var file = FileAccess.open("user://league_save.json", FileAccess.WRITE)
        if file:
                file.store_string(JSON.stringify(data, "  "))
                file.close()

## 加载赛季
func load_season() -> bool:
        var file = FileAccess.open("user://league_save.json", FileAccess.READ)
        if not file:
                return false
        var json = JSON.new()
        if json.parse(file.get_as_text()) != OK:
                return false
        file.close()

        var data = json.data
        current_league_id = data.get("league_id", "")
        player_team_id = data.get("player_team", "")
        current_matchday = data.get("current_matchday", 0)
        total_matchdays = data.get("total_matchdays", 0)
        league_standings = data.get("standings", [])
        fixtures = data.get("fixtures", [])
        return current_league_id != ""

## 清除赛季存档
func clear_season():
        current_league_id = ""
        player_team_id = ""
        current_matchday = 0
        total_matchdays = 0
        league_standings = []
        fixtures = []
        DirAccess.remove_absolute_or_empty("user://league_save.json")

## 获取玩家下一场比赛
func get_next_player_match() -> Dictionary:
        if current_matchday >= fixtures.size():
                return {}
        for match in fixtures[current_matchday]:
                if match.home == player_team_id or match.away == player_team_id:
                        return match
        return {}

## 获取联赛名称
func get_league_name() -> String:
        var league = TeamDatabase.get_league(current_league_id)
        return league.get("name", current_league_id)

## 获取积分榜
func get_standings() -> Array:
        return league_standings

## 获取当前轮次赛程
func get_current_fixtures() -> Array:
        if current_matchday < fixtures.size():
                return fixtures[current_matchday]
        return []

## 获取所有赛程
func get_all_fixtures() -> Array:
        return fixtures

## 联赛是否结束
func is_season_finished() -> bool:
        return current_matchday >= total_matchdays

## 获取联赛冠军
func get_champion() -> String:
        if not is_season_finished() or league_standings.is_empty():
                return ""
        return league_standings[0].team_id

## 获取玩家排名
func get_player_rank() -> int:
        for i in range(league_standings.size()):
                if league_standings[i].team_id == player_team_id:
                        return i + 1
        return -1
