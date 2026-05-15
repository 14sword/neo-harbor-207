extends Node2D

var _computer_timer: float = 0.0
var _window_timer: float = 0.0
var _balcony_timer: float = 0.0
var _room_timer: float = 0.0
var _player_near_balcony: bool = false
var _balcony_stay_timer: float = 0.0

var _computer_interval: float = 35.0
var _window_interval: float = 25.0
var _balcony_interval: float = 15.0
var _room_interval: float = 50.0

var _computer_pos = Vector2(600, 240)
var _window_pos = Vector2(836, 180)
var _balcony_pos = Vector2(836, 750)

var _bubble_scene: PackedScene = preload("res://scenes/ambient_bubble.tscn")

var _day_computer_texts = [
	"DATAWHALE: 系统正常运行",
	"新邮件: 本周数据报告已生成",
	"都市快讯: Neo Harbor 高架正常运行",
	"天气提醒: 今日晴，紫外线指数中等",
	"DATAWHALE: 安全扫描完成",
	"快递通知: 您的包裹已到达楼下",
	"外卖提醒: 附近餐厅优惠中",
	"都市论坛: 今日热帖更新",
]

var _night_computer_texts = [
	"检测到未识别信号...",
	"你已经被观测",
	"数据异常: 0x7F3A",
	"未知来源消息",
	"系统警告: 现实稳定度下降",
	"DATAWHALE: 异常登录尝试",
	"紫雨概率: 3%",
	"观测等级更新: ▓▓▓░░",
]

var _rain_computer_texts = [
	"深夜便利店: 新品上架",
	"电台广播: 今晚雨将持续",
	"DATAWHALE: 远程办公模式",
	"外卖提醒: 雨天配送延迟",
	"都市新闻: 地铁临时调整",
	"天气预警: 雷暴概率 67%",
]

var _day_window_texts = [
	"未来茶楼 新品上市",
	"DATAWHALE 数据安全周",
	"Neo Harbor 今日空气指数: 优",
	"新城区地铁 24h 运行中",
	"赛博药房 全天候服务",
	"云上居 招租中",
]

var _night_window_texts = [
	"▓▓▓ 异 ▓▓ 常 ▓▓▓",
	"观测站: 数据漂移",
	"你已被 ▓▓ 识别",
	"重复 重复 重复 重复",
	"异常天气预警",
	"▒▒▒ 信号丢失 ▒▒▒",
]

var _rain_window_texts = [
	"深夜食堂 营业中",
	"霓虹公寓 招租",
	"雨夜电台 97.3MHz",
	"便利店 全天候",
	"都市夜归人 注意安全",
]

var _balcony_texts = [
	"远处传来列车广播",
	"楼下似乎有人在争吵",
	"空气里有雨水与电子设备的味道",
	"城市今晚异常安静",
	"一架无人机从窗外掠过",
	"远处霓虹灯闪烁了一下",
	"高架列车正在进站",
	"楼下便利店灯光还亮着",
]

var _night_balcony_texts = [
	"天空似乎有一道裂缝...",
	"远处的楼突然熄灭了",
	"空气中弥漫着微弱的臭氧味",
	"某个方向传来低频嗡鸣",
	"你感觉有什么东西在注视你",
]

var _rain_balcony_texts = [
	"雨声掩盖了城市的喧嚣",
	"远处传来模糊的广播声",
	"霓虹灯在雨中模糊成光晕",
	"楼下传来关窗的声音",
	"雨夜的城市格外安静",
]

var _day_room_events = [
	{"text": "冰箱轻微震动了一下", "pos": Vector2(150, 230)},
	{"text": "电视自动切换到天气频道", "pos": Vector2(500, 180)},
	{"text": "窗外传来快递无人机的嗡鸣", "pos": Vector2(836, 300)},
	{"text": "手机震动了一下", "pos": Vector2(836, 500)},
]

var _night_room_events = [
	{"text": "电子符纸微微发光", "pos": Vector2(1100, 280)},
	{"text": "显示器自动亮起又熄灭", "pos": Vector2(600, 240)},
	{"text": "空气中出现紫色微粒", "pos": Vector2(836, 400)},
	{"text": "电视雪花屏一闪而过", "pos": Vector2(500, 180)},
	{"text": "冰箱发出低频嗡鸣", "pos": Vector2(150, 230)},
]

var _rain_room_events = [
	{"text": "电饭煲冒出热气", "pos": Vector2(200, 280)},
	{"text": "黑胶机自动播放了一段旋律", "pos": Vector2(1100, 350)},
	{"text": "窗外霓虹灯在地板上投下倒影", "pos": Vector2(836, 500)},
	{"text": "手机屏幕亮了一下", "pos": Vector2(836, 500)},
]

func _ready():
	_randomize_timers()

func _randomize_timers():
	_computer_timer = randf_range(10.0, _computer_interval)
	_window_timer = randf_range(5.0, _window_interval)
	_balcony_timer = randf_range(5.0, _balcony_interval)
	_room_timer = randf_range(20.0, _room_interval)

func _process(delta):
	var phase = _get_current_phase()

	_computer_timer -= delta
	_window_timer -= delta
	_balcony_timer -= delta
	_room_timer -= delta

	if _player_near_balcony:
		_balcony_stay_timer += delta

	if _computer_timer <= 0:
		_trigger_computer_event(phase)
		_computer_timer = randf_range(_computer_interval * 0.7, _computer_interval * 1.3)

	if _window_timer <= 0:
		_trigger_window_event(phase)
		_window_timer = randf_range(_window_interval * 0.7, _window_interval * 1.3)

	if _player_near_balcony and _balcony_stay_timer > 3.0 and _balcony_timer <= 0:
		_trigger_balcony_event(phase)
		_balcony_timer = randf_range(_balcony_interval * 0.7, _balcony_interval * 1.3)
		_balcony_stay_timer = 0.0

	if _room_timer <= 0:
		_trigger_room_event(phase)
		_room_timer = randf_range(_room_interval * 0.7, _room_interval * 1.3)

func _get_current_phase():
	if has_node("/root/DayNightManager"):
		return get_node("/root/DayNightManager").current_phase
	return 0

func _trigger_computer_event(_phase):
	var dnm = get_node("/root/DayNightManager") if has_node("/root/DayNightManager") else null
	var texts = _day_computer_texts
	var style = 0

	if dnm:
		match dnm.current_phase:
			dnm.DayPhase.NIGHT:
				texts = _night_computer_texts
				style = 2
			dnm.DayPhase.RAIN_NIGHT:
				texts = _rain_computer_texts
				style = 1
			_:
				texts = _day_computer_texts
				style = 0

	var text = texts[randi() % texts.size()]
	_spawn_bubble(text, _computer_pos + Vector2(randf_range(-20, 20), randf_range(-10, 10)), style)

func _trigger_window_event(_phase):
	var dnm = get_node("/root/DayNightManager") if has_node("/root/DayNightManager") else null
	var texts = _day_window_texts
	var style = 0

	if dnm:
		match dnm.current_phase:
			dnm.DayPhase.NIGHT:
				texts = _night_window_texts
				style = 2
			dnm.DayPhase.RAIN_NIGHT:
				texts = _rain_window_texts
				style = 3
			_:
				texts = _day_window_texts
				style = 0

	var text = texts[randi() % texts.size()]
	_spawn_bubble(text, _window_pos + Vector2(randf_range(-60, 60), randf_range(-10, 10)), style)

func _trigger_balcony_event(_phase):
	var dnm = get_node("/root/DayNightManager") if has_node("/root/DayNightManager") else null
	var texts = _balcony_texts
	var style = 3

	if dnm:
		match dnm.current_phase:
			dnm.DayPhase.NIGHT:
				texts = _night_balcony_texts
				style = 2
			dnm.DayPhase.RAIN_NIGHT:
				texts = _rain_balcony_texts
				style = 3
			_:
				texts = _balcony_texts
				style = 3

	var text = texts[randi() % texts.size()]
	_spawn_bubble(text, _balcony_pos + Vector2(randf_range(-30, 30), randf_range(-10, 10)), style)

	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("🏙️ " + text)

func _trigger_room_event(_phase):
	var dnm = get_node("/root/DayNightManager") if has_node("/root/DayNightManager") else null
	var events = _day_room_events
	var style = 3

	if dnm:
		match dnm.current_phase:
			dnm.DayPhase.NIGHT:
				events = _night_room_events
				style = 2
			dnm.DayPhase.RAIN_NIGHT:
				events = _rain_room_events
				style = 3
			_:
				events = _day_room_events
				style = 3

	var event = events[randi() % events.size()]
	_spawn_bubble(event.text, event.pos + Vector2(randf_range(-20, 20), randf_range(-10, 10)), style)

func _spawn_bubble(text: String, pos: Vector2, style: int):
	if not _bubble_scene:
		return
	var bubble = _bubble_scene.instantiate()
	add_child(bubble)
	bubble.setup(text, pos, style, randf_range(3.5, 5.0))

func set_player_near_balcony(near: bool):
	_player_near_balcony = near
	if not near:
		_balcony_stay_timer = 0.0
