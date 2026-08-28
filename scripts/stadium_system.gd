## stadium_system.gd
## 球场自定义系统 (Autoload Singleton)
## 功能：不同球场环境、天气、时间段、球场尺寸
extends Node

# 球场数据库
const STADIUMS = {
	"etihad": {"name": "阿提哈德球场", "team": "man_city", "capacity": 53400, "city": "曼彻斯特", "color": "#6CABDD"},
	"old_trafford": {"name": "老特拉福德", "team": "man_united", "capacity": 74310, "city": "曼彻斯特", "color": "#DA291C"},
	"anfield": {"name": "安菲尔德", "team": "liverpool", "capacity": 61000, "city": "利物浦", "color": "#C8102E"},
	"emirates": {"name": "酋长球场", "team": "arsenal", "capacity": 60704, "city": "伦敦", "color": "#EF0107"},
	"stamford_bridge": {"name": "斯坦福桥", "team": "chelsea", "capacity": 40341, "city": "伦敦", "color": "#034694"},
	"bernabeu": {"name": "伯纳乌", "team": "real_madrid", "capacity": 81044, "city": "马德里", "color": "#FFFFFF"},
	"camp_nou": {"name": "诺坎普", "team": "barcelona", "capacity": 99354, "city": "巴塞罗那", "color": "#A50044"},
	"allianz_arena": {"name": "安联球场", "team": "bayern_munich", "capacity": 75000, "city": "慕尼黑", "color": "#DC052D"},
	"signal_iduna": {"name": "威斯特法伦", "team": "dortmund", "capacity": 81365, "city": "多特蒙德", "color": "#FDE100"},
	"san_siro": {"name": "圣西罗", "team": "ac_milan", "capacity": 80018, "city": "米兰", "color": "#FB090B"},
	"allianz_stadium": {"name": "安联球场", "team": "juventus", "capacity": 41507, "city": "都灵", "color": "#000000"},
	"parc_des_princes": {"name": "王子公园", "team": "psg", "capacity": 47929, "city": "巴黎", "color": "#004170"},
	"maracana": {"name": "马拉卡纳", "team": "flamengo", "capacity": 78838, "city": "里约热内卢", "color": "#C8102E"},
	"bombonera": {"name": "糖果盒", "team": "boca_juniors", "capacity": 54000, "city": "布宜诺斯艾利斯", "color": "#003F87"},
	"generic_1": {"name": "社区球场", "team": "", "capacity": 10000, "city": "默认", "color": "#1a7a3a"},
	"generic_2": {"name": "市政球场", "team": "", "capacity": 20000, "city": "默认", "color": "#2a5a2a"},
}

# 天气类型
enum Weather {
	SUNNY,       # 晴天
	CLOUDY,      # 多云
	RAIN,        # 小雨
	HEAVY_RAIN,  # 大雨
	SNOW,        # 下雪
	FOG,         # 雾天
	NIGHT,       # 夜场
}

# 天气参数
const WEATHER_PARAMS = {
	Weather.SUNNY: {"name": "晴天", "ball_speed_mult": 1.0, "player_speed_mult": 1.0, "visibility": 1.0, "grass_color": Color(0.15, 0.5, 0.15)},
	Weather.CLOUDY: {"name": "多云", "ball_speed_mult": 1.0, "player_speed_mult": 1.0, "visibility": 0.95, "grass_color": Color(0.13, 0.45, 0.13)},
	Weather.RAIN: {"name": "小雨", "ball_speed_mult": 0.9, "player_speed_mult": 0.95, "visibility": 0.85, "grass_color": Color(0.1, 0.4, 0.1)},
	Weather.HEAVY_RAIN: {"name": "大雨", "ball_speed_mult": 0.8, "player_speed_mult": 0.9, "visibility": 0.7, "grass_color": Color(0.08, 0.35, 0.08)},
	Weather.SNOW: {"name": "下雪", "ball_speed_mult": 0.7, "player_speed_mult": 0.85, "visibility": 0.75, "grass_color": Color(0.7, 0.75, 0.7)},
	Weather.FOG: {"name": "雾天", "ball_speed_mult": 1.0, "player_speed_mult": 1.0, "visibility": 0.5, "grass_color": Color(0.12, 0.42, 0.12)},
	Weather.NIGHT: {"name": "夜场", "ball_speed_mult": 1.0, "player_speed_mult": 1.0, "visibility": 0.9, "grass_color": Color(0.08, 0.3, 0.08)},
}

# 当前球场设置
var current_stadium: String = "generic_1"
var current_weather: int = Weather.SUNNY
var current_time_of_day: float = 14.0  # 0-24小时

## 获取球场信息
func get_stadium(stadium_id: String) -> Dictionary:
	return STADIUMS.get(stadium_id, STADIUMS.generic_1)

## 获取所有球场
func get_all_stadiums() -> Dictionary:
	return STADIUMS

## 根据球队获取球场
func get_stadium_by_team(team_id: String) -> String:
	for sid in STADIUMS:
		if STADIUMS[sid].team == team_id:
			return sid
	return "generic_1"

## 设置当前球场
func set_stadium(stadium_id: String):
	current_stadium = stadium_id
	print("[Stadium] 球场设置为: %s" % get_stadium(stadium_id).name)

## 设置天气
func set_weather(weather: int):
	current_weather = weather
	print("[Stadium] 天气设置为: %s" % WEATHER_PARAMS[weather].name)

## 设置时间
func set_time_of_day(hour: float):
	current_time_of_day = clamp(hour, 0.0, 24.0)
	print("[Stadium] 时间设置为: %02d:00" % int(current_time_of_day))

## 获取天气参数
func get_weather_params() -> Dictionary:
	return WEATHER_PARAMS.get(current_weather, WEATHER_PARAMS[Weather.SUNNY])

## 获取天气名称
func get_weather_name() -> String:
	return WEATHER_PARAMS[current_weather].name

## 获取球场名称
func get_stadium_name() -> String:
	return get_stadium(current_stadium).name

## 获取环境光颜色（根据时间）
func get_ambient_light() -> Color:
	var hour = current_time_of_day
	if hour >= 6 and hour < 8:
		# 日出
		return Color(1.0, 0.7, 0.5, 0.6)
	elif hour >= 8 and hour < 17:
		# 白天
		return Color(0.8, 0.85, 0.9, 0.7)
	elif hour >= 17 and hour < 19:
		# 日落
		return Color(1.0, 0.6, 0.4, 0.5)
	elif hour >= 19 and hour < 21:
		# 黄昏
		return Color(0.4, 0.4, 0.6, 0.4)
	else:
		# 夜晚
		return Color(0.2, 0.2, 0.4, 0.3)

## 获取草地颜色
func get_grass_color() -> Color:
	var weather_params = get_weather_params()
	return weather_params.get("grass_color", Color(0.15, 0.5, 0.15))

## 获取球场容量（影响观众声效）
func get_stadium_capacity() -> int:
	return get_stadium(current_stadium).capacity

## 随机天气
func random_weather():
	var weathers = [Weather.SUNNY, Weather.SUNNY, Weather.CLOUDY, Weather.RAIN, Weather.HEAVY_RAIN, Weather.NIGHT]
	current_weather = weathers[randi() % weathers.size()]

## 随机时间
func random_time():
	current_time_of_day = randf_range(10.0, 22.0)

## 获取环境设置（用于比赛场景）
func get_environment_settings() -> Dictionary:
	return {
		"stadium": current_stadium,
		"stadium_name": get_stadium_name(),
		"weather": current_weather,
		"weather_name": get_weather_name(),
		"time_of_day": current_time_of_day,
		"ambient_light": get_ambient_light(),
		"grass_color": get_grass_color(),
		"ball_speed_mult": get_weather_params().ball_speed_mult,
		"player_speed_mult": get_weather_params().player_speed_mult,
		"visibility": get_weather_params().visibility,
		"capacity": get_stadium_capacity(),
	}
