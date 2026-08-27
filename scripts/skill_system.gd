## skill_system.gd
## 被动技能系统 (Autoload Singleton)
##
## 核心理念：技能不是玩家主动按键释放的，而是在特定情境下自动触发
## 这才是真正的足球模拟，而不是"流水线网游"
##
## 触发情境：
##   1. 跑步时 (running)     - 无球跑动
##   2. 走位时 (positioning) - 调整站位
##   3. 防守时 (defending)   - 对方控球
##   4. 转身时 (turning)     - 改变方向
##   5. 后撤时 (retreating)  - 向本方半场移动
##   6. 前抢时 (pressing)    - 向对方逼抢
##   7. 射门时 (shooting)    - 起脚射门
##   8. 门将出击时 (gk_rush) - 门将冲出
extends Node

# 触发情境枚举
enum TriggerContext {
	RUNNING,       # 跑步时
	POSITIONING,   # 走位时
	DEFENDING,     # 防守时
	TURNING,       # 转身时
	RETREATING,    # 后撤时
	PRESSING,      # 前抢时
	SHOOTING,      # 射门时
	GK_RUSH,       # 门将出击时
	HEADER,        # 争顶头球时
	TACKLING,      # 抢断时
	PASSING,       # 传球时
	RECEIVING,     # 接球时
}

# 技能数据库（被动技能）
const PASSIVE_SKILLS = {
	# ---- 跑步时触发 ----
	"speed_burst": {
		"name": "加速冲刺",
		"trigger": TriggerContext.RUNNING,
		"description": "无球跑动时速度额外+8%",
		"effect": {"speed_mult": 1.08},
		"cooldown": 0,
		"probability": 1.0,  # 100%触发
	},
	"endless_runner": {
		"name": "永动机",
		"trigger": TriggerContext.RUNNING,
		"description": "跑步时体力消耗减半",
		"effect": {"stamina_drain_mult": 0.5},
		"cooldown": 0,
		"probability": 1.0,
	},

	# ---- 走位时触发 ----
	"ghost_movement": {
		"name": "幽灵跑位",
		"trigger": TriggerContext.POSITIONING,
		"description": "走位时不易被对方察觉，对方AI反应延迟+0.2秒",
		"effect": {"ai_reaction_delay": 0.2},
		"cooldown": 0,
		"probability": 0.8,
	},
	"smart_positioning": {
		"name": "智慧走位",
		"trigger": TriggerContext.POSITIONING,
		"description": "自动寻找对方防线空当",
		"effect": {"positioning_bonus": 1.0},
		"cooldown": 0,
		"probability": 1.0,
	},

	# ---- 防守时触发 ----
	"interceptor": {
		"name": "拦截者",
		"trigger": TriggerContext.DEFENDING,
		"description": "防守时传球拦截范围+30%",
		"effect": {"intercept_radius_mult": 1.3},
		"cooldown": 0,
		"probability": 1.0,
	},
	"wall_builder": {
		"name": "铜墙铁壁",
		"trigger": TriggerContext.DEFENDING,
		"description": "防守时对方传球成功率-10%",
		"effect": {"opp_pass_penalty": 0.1},
		"cooldown": 0,
		"probability": 1.0,
	},

	# ---- 转身时触发 ----
	"quick_turn": {
		"name": "灵活转身",
		"trigger": TriggerContext.TURNING,
		"description": "改变方向时速度不减",
		"effect": {"turn_speed_mult": 1.5},
		"cooldown": 0,
		"probability": 1.0,
	},
	"spin_master": {
		"name": "转身大师",
		"trigger": TriggerContext.TURNING,
		"description": "转身时有15%概率完全甩开防守",
		"effect": {"shake_off_chance": 0.15},
		"cooldown": 3.0,
		"probability": 0.15,
	},

	# ---- 后撤时触发 ----
	"counter_ready": {
		"name": "反击准备",
		"trigger": TriggerContext.RETREATING,
		"description": "后撤时随时准备反击，接球后第一脚传球速度+20%",
		"effect": {"first_pass_speed_mult": 1.2},
		"cooldown": 0,
		"probability": 1.0,
	},

	# ---- 前抢时触发 ----
	"aggressive_press": {
		"name": "凶猛逼抢",
		"trigger": TriggerContext.PRESSING,
		"description": "前抢时速度+10%，对方控球者慌乱概率+15%",
		"effect": {"press_speed_mult": 1.1, "opp_panic_chance": 0.15},
		"cooldown": 0,
		"probability": 1.0,
	},
	"ball_hunter": {
		"name": "猎球者",
		"trigger": TriggerContext.PRESSING,
		"description": "前抢时抢断范围+25%",
		"effect": {"press_tackle_radius_mult": 1.25},
		"cooldown": 0,
		"probability": 1.0,
	},

	# ---- 射门时触发 ----
	"clinical_finisher": {
		"name": "冷静终结",
		"trigger": TriggerContext.SHOOTING,
		"description": "射门时精度+15%",
		"effect": {"shot_accuracy_mult": 1.15},
		"cooldown": 0,
		"probability": 1.0,
	},
	"power_shot": {
		"name": "重炮手",
		"trigger": TriggerContext.SHOOTING,
		"description": "射门时力量+20%",
		"effect": {"shot_power_mult": 1.2},
		"cooldown": 0,
		"probability": 1.0,
	},
	"finesse_shot": {
		"name": "搓射大师",
		"trigger": TriggerContext.SHOOTING,
		"description": "禁区内射门时自动选择搓射，精度+25%",
		"effect": {"finesse_accuracy_mult": 1.25},
		"cooldown": 0,
		"probability": 0.7,
	},
	"long_range_sniper": {
		"name": "远射狙击手",
		"trigger": TriggerContext.SHOOTING,
		"description": "25米外射门精度不减反增+10%",
		"effect": {"long_shot_accuracy_mult": 1.1},
		"cooldown": 0,
		"probability": 1.0,
	},

	# ---- 门将出击时触发 ----
	"sweeper_keeper": {
		"name": "清道夫门将",
		"trigger": TriggerContext.GK_RUSH,
		"description": "门将出击时速度+15%，扑救范围+20%",
		"effect": {"gk_speed_mult": 1.15, "gk_save_radius_mult": 1.2},
		"cooldown": 0,
		"probability": 1.0,
	},
	"one_on_one_master": {
		"name": "单刀大师",
		"trigger": TriggerContext.GK_RUSH,
		"description": "门将出击时单刀扑救成功率+25%",
		"effect": {"gk_1v1_save_mult": 1.25},
		"cooldown": 0,
		"probability": 1.0,
	},

	# ---- 争顶头球时触发 ----
	"aerial_dominance": {
		"name": "制空权",
		"trigger": TriggerContext.HEADER,
		"description": "争顶时弹跳+20%，头球精度+15%",
		"effect": {"jump_mult": 1.2, "header_accuracy_mult": 1.15},
		"cooldown": 0,
		"probability": 1.0,
	},

	# ---- 抢断时触发 ----
	"clean_tackle": {
		"name": "干净利落",
		"trigger": TriggerContext.TACKLING,
		"description": "抢断时犯规概率-30%",
		"effect": {"foul_chance_mult": 0.7},
		"cooldown": 0,
		"probability": 1.0,
	},
	"ball_magnet": {
		"name": "吸球磁铁",
		"trigger": TriggerContext.TACKLING,
		"description": "抢断成功后球自动滚向自己脚下",
		"effect": {"ball_to_self": true},
		"cooldown": 0,
		"probability": 0.6,
	},

	# ---- 传球时触发 ----
	"pinpoint_pass": {
		"name": "精准传球",
		"trigger": TriggerContext.PASSING,
		"description": "传球精度+12%",
		"effect": {"pass_accuracy_mult": 1.12},
		"cooldown": 0,
		"probability": 1.0,
	},
	"vision_master": {
		"name": "视野大师",
		"trigger": TriggerContext.PASSING,
		"description": "传球时自动选择最佳接球者",
		"effect": {"auto_best_target": true},
		"cooldown": 0,
		"probability": 0.8,
	},

	# ---- 接球时触发 ----
	"first_touch": {
		"name": "完美停球",
		"trigger": TriggerContext.RECEIVING,
		"description": "接球后球不弹远，控球距离-40%",
		"effect": {"control_distance_mult": 0.6},
		"cooldown": 0,
		"probability": 1.0,
	},
	"no_touch_turn": {
		"name": "不停球转身",
		"trigger": TriggerContext.RECEIVING,
		"description": "接球时20%概率直接转身过人",
		"effect": {"instant_turn_chance": 0.2},
		"cooldown": 2.0,
		"probability": 0.2,
	},
}

# 球员技能冷却记录
var skill_cooldowns: Dictionary = {}  # player_id -> {skill_id -> remaining_time}

## 检查并触发技能
func check_trigger(player_id: String, context: int, player_data: Dictionary = {}) -> Dictionary:
	var triggered_effects = {}
	var player = PlayerDatabase.get_player(player_id)
	if player.is_empty():
		return triggered_effects

	var skills = player.get("skills", [])
	if skills.is_empty():
		return triggered_effects

	# 初始化冷却记录
	if not skill_cooldowns.has(player_id):
		skill_cooldowns[player_id] = {}

	for skill_id in skills:
		if not PASSIVE_SKILLS.has(skill_id):
			continue

		var skill = PASSIVE_SKILLS[skill_id]
		if skill.trigger != context:
			continue

		# 检查冷却
		if skill_cooldowns[player_id].has(skill_id):
			if skill_cooldowns[player_id][skill_id] > 0:
				continue

		# 概率检查
		if randf() > skill.probability:
			continue

		# 触发！
		triggered_effects.merge(skill.effect, true)

		# 设置冷却
		if skill.cooldown > 0:
			skill_cooldowns[player_id][skill_id] = skill.cooldown

		print("[Skill] %s 触发技能: %s" % [
			PlayerDatabase.get_player_short_name(player_id),
			skill.name
		])

	return triggered_effects

## 更新冷却时间
func update_cooldowns(delta: float):
	for pid in skill_cooldowns:
		for sid in skill_cooldowns[pid]:
			if skill_cooldowns[pid][sid] > 0:
				skill_cooldowns[pid][sid] -= delta

## 获取球员拥有的技能
func get_player_skills(player_id: String) -> Array:
	var player = PlayerDatabase.get_player(player_id)
	return player.get("skills", [])

## 获取技能信息
func get_skill_info(skill_id: String) -> Dictionary:
	return PASSIVE_SKILLS.get(skill_id, {})

## 获取情境名称
func get_context_name(context: int) -> String:
	match context:
		TriggerContext.RUNNING: return "跑步时"
		TriggerContext.POSITIONING: return "走位时"
		TriggerContext.DEFENDING: return "防守时"
		TriggerContext.TURNING: return "转身时"
		TriggerContext.RETREATING: return "后撤时"
		TriggerContext.PRESSING: return "前抢时"
		TriggerContext.SHOOTING: return "射门时"
		TriggerContext.GK_RUSH: return "门将出击时"
		TriggerContext.HEADER: return "争顶时"
		TriggerContext.TACKLING: return "抢断时"
		TriggerContext.PASSING: return "传球时"
		TriggerContext.RECEIVING: return "接球时"
		_: return "未知"

## 获取所有技能
func get_all_skills() -> Dictionary:
	return PASSIVE_SKILLS
