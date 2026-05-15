extends CanvasLayer

signal day_advanced(new_day: int)

var current_day: int = 1

var _month_names = ["霜月", "霓月", "雨月", "幽月", "灰月"]
var _month_en = ["Frostmonth", "Neonmonth", "Rainmonth", "Ghostmonth", "Ashmonth"]
var _weekday_names = ["曜日", "霓日", "雨日", "铁日", "幽日", "灰日"]
var _days_per_month = 36
var _days_per_week = 6

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
