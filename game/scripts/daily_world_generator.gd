extends CanvasLayer

var _daily_seed: int = 0
var _daily_weather: Dictionary = {}
var _daily_events: Array = []
var _daily_ads: Array = []
var _daily_anomaly_level: float = 0.0

func _ready():
	_refresh_daily_data()
	if has_node("/root/WorldCalendar"):
		get_node("/root/WorldCalendar").day_advanced.connect(_on_day_advanced)

func _on_day_advanced(_new_day):
	_refresh_daily_data()

func _refresh_daily_data():
	if has_node("/root/WorldCalendar"):
		_daily_seed = get_node("/root/WorldCalendar").get_day_seed()
	else:
		_daily_seed = 1
	_generate_weather()
	_generate_anomaly_level()
	_generate_daily_events()
	_generate_daily_ads()

func get_daily_weather() -> Dictionary:
	return _daily_weather

func get_daily_anomaly_level() -> float:
	return _daily_anomaly_level

func get_daily_events() -> Array:
	return _daily_events

func get_daily_ads() -> Array:
	return _daily_ads

func _generate_weather():
	var rng = RandomNumberGenerator.new()
	rng.seed = _daily_seed
	var weathers = [
		{"name": "晴", "desc": "今日天气晴朗，紫外线指数中等", "icon": "☀️"},
		{"name": "多云", "desc": "多云转阴，傍晚有微风", "icon": "⛅"},
		{"name": "小雨", "desc": "全天小雨，建议携带雨具", "icon": "🌦️"},
		{"name": "雷暴", "desc": "雷暴预警，建议减少外出", "icon": "⛈️"},
		{"name": "雾霾", "desc": "空气指数偏高，建议佩戴防护面罩", "icon": "🌫️"},
	]
	_daily_weather = weathers[rng.randi() % weathers.size()]
	_daily_weather["temperature"] = "%d°C" % (rng.randi() % 15 + 18)
	_daily_weather["humidity"] = "%d%%" % (rng.randi() % 40 + 40)

func _generate_anomaly_level():
	var rng = RandomNumberGenerator.new()
	rng.seed = _daily_seed + 100
	var base = 0.0
	if has_node("/root/WorldCalendar"):
		var cal = get_node("/root/WorldCalendar")
		if cal.is_ghost_month():
			base = 0.3
		elif cal.is_rain_month():
			base = 0.1
	_daily_anomaly_level = base + rng.randf() * 0.4

func _generate_daily_events():
	var rng = RandomNumberGenerator.new()
	rng.seed = _daily_seed + 200
	var all_events = [
		"高架列车延误30分钟",
		"新城区商业综合体开业",
		"DATAWHALE发布新AI模型",
		"区域3临时停电维护",
		"未来茶楼新品上市",
		"城市安全指数上升",
		"霓虹节庆典筹备中",
		"自动售货机系统升级",
		"无人机配送线路调整",
		"地下铁新线路试运行",
		"赛博街区艺术展",
		"便利店全品类促销",
		"社区健康检查日",
		"虚拟偶像演唱会",
		"旧城区改造计划启动",
	]
	var count = rng.randi() % 3 + 3
	_daily_events = []
	var used = {}
	for i in range(count):
		var idx = rng.randi() % all_events.size()
		while used.has(idx):
			idx = rng.randi() % all_events.size()
		used[idx] = true
		_daily_events.append(all_events[idx])

func _generate_daily_ads():
	var rng = RandomNumberGenerator.new()
	rng.seed = _daily_seed + 300
	var all_ads = [
		{"title": "霓虹能量饮", "desc": "一罐提神，全天在线", "category": "ads"},
		{"title": "DATAWHALE招聘", "desc": "加入我们，塑造未来", "category": "ads"},
		{"title": "全息奶茶", "desc": "传统与科技的融合", "category": "ads"},
		{"title": "赛博拉面", "desc": "霓虹面馆，视觉满分", "category": "ads"},
		{"title": "无人机快递", "desc": "30分钟必达", "category": "ads"},
		{"title": "虚拟宠物伴侣", "desc": "不再孤单", "category": "ads"},
	]
	var count = rng.randi() % 2 + 2
	_daily_ads = []
	var used = {}
	for i in range(count):
		var idx = rng.randi() % all_ads.size()
		while used.has(idx):
			idx = rng.randi() % all_ads.size()
		used[idx] = true
		_daily_ads.append(all_ads[idx])
