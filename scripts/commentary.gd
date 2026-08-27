## commentary.gd
## 解说系统 (Autoload Singleton)
## 在比赛关键时刻播放文字解说 + 语音提示
##
## 解说类型：进球、射门、扑救、犯规、黄红牌、角球、任意球、开球、半场、终场
extends Node

signal commentary_triggered(text: String, type: String)

# 解说文本库
var commentary_texts: Dictionary = {
	"goal": [
		"进球了！精彩的射门！",
		"球进了！漂亮的进球！",
		"GOAL！一记势大力沉的射门！",
		"破门得分！门将毫无反应！",
		"进球！完美的终结！",
		"球应声入网！观众沸腾了！",
		"世界波！这球太精彩了！",
		"帽子戏法！他今天状态火热！",
	],
	"goal_header": [
		"头球破门！完美的传中！",
		"强力头球！门将无能为力！",
		"高高跃起，头球得分！",
	],
	"goal_own": [
		"乌龙球！不幸的自摆乌龙！",
		"哎呀！球打进了自家球门！",
		"乌龙！这真是太不走运了！",
	],
	"shot_on_target": [
		"射门！门将扑了出来！",
		"精彩的扑救！",
		"射门被挡出！",
		"门将神勇化解！",
	],
	"shot_off_target": [
		"射门偏出了！",
		"球打高了！",
		"差之毫厘！",
		"射门稍稍偏出立柱！",
	],
	"shot_crossbar": [
		"击中横梁！太可惜了！",
		"球打在横梁上弹出！",
		"就差那么一点点！横梁立功了！",
	],
	"shot_post": [
		"击中立柱！",
		"球打在立柱上！运气不佳！",
	],
	"save": [
		"世界级扑救！",
		"门将飞身扑救！",
		"不可思议的扑救！",
		"门将立功了！",
	],
	"foul": [
		"犯规了！裁判鸣哨！",
		"这个动作太大了！",
		"裁判判罚犯规！",
		"危险动作！",
	],
	"yellow_card": [
		"黄牌！裁判出示黄牌！",
		"这个犯规值得一张黄牌！",
		"黄牌警告！",
	],
	"red_card": [
		"红牌！直接红牌罚下！",
		"严重犯规！红牌！",
		"他被罚下了！",
	],
	"corner": [
		"角球！",
		"获得角球机会！",
		"角球开出！",
	],
	"free_kick": [
		"任意球机会！",
		"危险的任意球位置！",
		"任意球直接射门！",
	],
	"penalty": [
		"点球！裁判判罚点球！",
		"禁区内犯规！点球！",
		"十二码点！点球！",
	],
	"kickoff": [
		"比赛开始！",
		"开球！上半场开始！",
		"下半场开始！",
		"比赛重新开始！",
	],
	"halftime": [
		"上半场结束！",
		"中场休息！",
	],
	"fulltime": [
		"全场比赛结束！",
		"终场哨响！比赛结束！",
		"比赛结束了！",
	],
	"tackle": [
		"漂亮的抢断！",
		"成功断球！",
		"精准的铲球！",
	],
	"pass": [
		"精准的传球！",
		"漂亮的直塞！",
		"精彩的配合！",
	],
	"cross": [
		"传中！",
		"边路传中！",
		"精准的传中球！",
	],
	"hat_trick": [
		"帽子戏法！他打进了第三个球！",
		"帽子戏法！全场最佳！",
		"三球入账！帽子戏法达成！",
	],
	"save_penalty": [
		"点球被扑出来了！",
		"门将扑出点球！不可思议！",
		"点球不进！门将立功！",
	],
}

var last_commentary_time: float = 0.0
const COMMENTARY_COOLDOWN: float = 1.5  # 解说冷却时间

## 触发解说
func trigger(type: String, custom_text: String = ""):
	if Time.get_ticks_msec() / 1000.0 - last_commentary_time < COMMENTARY_COOLDOWN:
		return

	last_commentary_time = Time.get_ticks_msec() / 1000.0

	var text = custom_text
	if text.is_empty() and commentary_texts.has(type):
		var texts = commentary_texts[type]
		text = texts[randi() % texts.size()]

	if not text.is_empty():
		commentary_triggered.emit(text, type)
		print("[解说] %s" % text)

		# 根据类型播放音效
		match type:
			"goal", "goal_header":
				AudioManager.play_sfx(AudioManager.SFX.GOAL)
				AudioManager.play_sfx(AudioManager.SFX.CROWD_CHEER)
			"goal_own":
				AudioManager.play_sfx(AudioManager.SFX.CROWD_BOO)
			"shot_crossbar":
				AudioManager.play_sfx(AudioManager.SFX.CROSSBAR)
			"shot_post":
				AudioManager.play_sfx(AudioManager.SFX.POST)
			"foul", "yellow_card", "red_card":
				AudioManager.play_sfx(AudioManager.SFX.WHISTLE_SHORT)
			"halftime", "fulltime":
				AudioManager.play_sfx(AudioManager.SFX.WHISTLE_LONG)
			"save":
				AudioManager.play_sfx(AudioManager.SFX.CATCH)
			"tackle":
				AudioManager.play_sfx(AudioManager.SFX.TACKLE)

## 获取随机解说文本
func get_random_text(type: String) -> String:
	if commentary_texts.has(type):
		var texts = commentary_texts[type]
		return texts[randi() % texts.size()]
	return ""
