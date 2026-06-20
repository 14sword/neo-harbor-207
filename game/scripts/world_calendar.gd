extends CanvasLayer

signal day_advanced(new_day: int)

var current_day: int = 1

var _month_names = ["霜月", "霓月", "雨月", "幽月", "灰月"]
var _month_en = ["Frostmonth", "Neonmonth", "Rainmonth", "Ghostmonth", "Ashmonth"]
var _weekday_names = ["曜日", "霓日", "雨日", "铁日", "幽日", "灰日"]
var _month_ids = ["frost", "neon", "rain", "ghost", "ash"]
var _weekday_ids = ["public", "commerce", "weather", "industry", "rumor", "safety"]
var _days_per_month = 36
var _days_per_week = 6

var _month_semantics = [
	{"id": "frost", "theme": "冷空气维护期", "description": "维护、冷空气、低异常", "weather_bias": "fog", "anomaly_bias": 0.03},
	{"id": "neon", "theme": "霓虹商业季", "description": "商业、节庆、广告", "weather_bias": "sunny", "anomaly_bias": 0.08},
	{"id": "rain", "theme": "雨季通勤压力", "description": "降雨、交通、设备故障", "weather_bias": "rain", "anomaly_bias": 0.14},
	{"id": "ghost", "theme": "幽月信号污染", "description": "异常、失踪、信号污染", "weather_bias": "anomaly", "anomaly_bias": 0.30},
	{"id": "ash", "theme": "灰月修复管制", "description": "灾后修复、安全管制", "weather_bias": "fog", "anomaly_bias": 0.18},
]

var _weekday_semantics = [
	{"id": "public", "theme": "公共公告", "description": "公共公告、城市运行"},
	{"id": "commerce", "theme": "娱乐消费", "description": "娱乐消费、社区生活"},
	{"id": "weather", "theme": "天气交通", "description": "天气交通、配送线路"},
	{"id": "industry", "theme": "工业维护", "description": "工业维护、节点巡检"},
	{"id": "rumor", "theme": "异常传闻", "description": "异常传闻、低频信号"},
	{"id": "safety", "theme": "社区安全", "description": "社区安全、夜巡提醒"},
]

func _ready():
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		if not sm.save_completed.is_connected(_on_game_saved):
			sm.save_completed.connect(_on_game_saved)
		if not sm.load_completed.is_connected(_on_game_loaded):
			sm.load_completed.connect(_on_game_loaded)

func advance_day():
	current_day += 1
	day_advanced.emit(current_day)
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("📅 " + get_date_string())

func get_day_string() -> String:
	return "第%d天" % current_day

func get_date_string() -> String:
	var month_idx = get_current_month_index()
	var day_in_month = get_day_in_month()
	var weekday_idx = get_current_weekday_index()
	return "N.H.207 %s%d %s" % [_month_names[month_idx], day_in_month, _weekday_names[weekday_idx]]

func get_date_string_full() -> String:
	var month_idx = get_current_month_index()
	var day_in_month = get_day_in_month()
	var weekday_idx = get_current_weekday_index()
	return "N.H.207 %s(%s)%d %s | %s" % [_month_names[month_idx], _month_en[month_idx], day_in_month, _weekday_names[weekday_idx], get_day_string()]

func get_short_date() -> String:
	var month_idx = get_current_month_index()
	var day_in_month = get_day_in_month()
	return "%s%d" % [_month_names[month_idx], day_in_month]

func get_calendar_context() -> Dictionary:
	var month_idx = get_current_month_index()
	var weekday_idx = get_current_weekday_index()
	var month_semantic = get_month_semantic()
	var weekday_semantic = get_weekday_semantic()
	return {
		"day": current_day,
		"day_in_month": get_day_in_month(),
		"date_string": get_date_string(),
		"date_string_full": get_date_string_full(),
		"short_date": get_short_date(),
		"month_index": month_idx,
		"month_id": _month_ids[month_idx],
		"month_name": _month_names[month_idx],
		"month_en": _month_en[month_idx],
		"month_theme": month_semantic.get("theme", ""),
		"month_description": month_semantic.get("description", ""),
		"weekday_index": weekday_idx,
		"weekday_id": _weekday_ids[weekday_idx],
		"weekday_name": _weekday_names[weekday_idx],
		"weekday_theme": weekday_semantic.get("theme", ""),
		"weekday_description": weekday_semantic.get("description", ""),
	}

func get_month_semantic() -> Dictionary:
	return _month_semantics[get_current_month_index()].duplicate(true)

func get_weekday_semantic() -> Dictionary:
	return _weekday_semantics[get_current_weekday_index()].duplicate(true)

func get_current_month_index() -> int:
	var total_day = current_day - 1
	var year_day = total_day % (_days_per_month * _month_names.size())
	return year_day / _days_per_month

func get_day_in_month() -> int:
	var total_day = current_day - 1
	var year_day = total_day % (_days_per_month * _month_names.size())
	return (year_day % _days_per_month) + 1

func get_current_weekday_index() -> int:
	return (current_day - 1) % _days_per_week

func get_day_seed() -> int:
	return current_day * 7919 + 42

func get_random_for_day() -> float:
	var seed_val = get_day_seed()
	var x = sin(float(seed_val)) * 43758.5453
	return x - floor(x)

func is_ghost_month() -> bool:
	return get_current_month_index() == 3

func is_rain_month() -> bool:
	return get_current_month_index() == 2

func get_save_data() -> Dictionary:
	return {"current_day": current_day}

func load_save_data(data: Dictionary):
	if data.has("current_day"):
		current_day = int(data["current_day"])

func _on_game_saved():
	pass

func _on_game_loaded():
	pass
