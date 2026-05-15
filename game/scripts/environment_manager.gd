extends Node

signal rain_started
signal rain_stopped
signal neon_flickered(building_id: String)
signal billboard_changed(billboard_id: String, new_content: String)
signal window_toggled(building_id: String, window_index: int, is_on: bool)
signal drone_spawned(drone_id: String)
signal late_night_event_triggered(event_id: String)

var _is_raining: bool = false
var _neon_flicker_timer: float = 0.0
var _window_toggle_timer: float = 0.0
var _late_night_check_timer: float = 0.0

var _billboard_contents: Dictionary = {
	"main": "DATAWHALE 招聘中",
	"side": "AI改变世界",
}

var _late_night_events: Dictionary = {
	"glitch_billboard": {
		"name": "广告牌乱码",
		"description": "广告牌偶尔闪现乱码字符",
		"min_phase": 2,
	},
	"strange_sound": {
		"name": "异常声响",
		"description": "深夜从地下传来低频震动",
		"min_phase": 3,
	},
	"window_anomaly": {
		"name": "窗口异常",
		"description": "某些建筑窗户闪烁不自然的光",
		"min_phase": 2,
	},
}

func _ready():
	print("[EnvironmentManager] 初始化完成")

func _process(delta: float):
	if not has_node("/root/DayNightManager"):
		return

	var dnm = get_node("/root/DayNightManager")
	var is_night = dnm.is_night()

	if is_night:
		_neon_flicker_timer += delta
		if _neon_flicker_timer > randf_range(3.0, 8.0):
			_neon_flicker_timer = 0.0
			_random_neon_flicker()

		_window_toggle_timer += delta
		if _window_toggle_timer > randf_range(5.0, 15.0):
			_window_toggle_timer = 0.0
			_random_window_toggle()

		_late_night_check_timer += delta
		if _late_night_check_timer > 60.0:
			_late_night_check_timer = 0.0
			check_late_night_events()

	if dnm.is_rain() and not _is_raining:
		_is_raining = true
		rain_started.emit()
	elif not dnm.is_rain() and _is_raining:
		_is_raining = false
		rain_stopped.emit()

func trigger_rain() -> void:
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if not dnm.is_rain():
			dnm.current_phase = dnm.DayPhase.RAIN_NIGHT
			dnm.phase_changed.emit(dnm.current_phase)
			dnm._apply_background()
			dnm._apply_bgm()
			dnm._apply_night_effects()

func stop_rain() -> void:
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if dnm.is_rain():
			dnm.current_phase = dnm.DayPhase.NIGHT
			dnm.phase_changed.emit(dnm.current_phase)
			dnm._apply_background()
			dnm._apply_bgm()
			dnm._apply_night_effects()

func flicker_neon(id: String) -> void:
	neon_flickered.emit(id)

func change_billboard(id: String, content: String) -> void:
	_billboard_contents[id] = content
	billboard_changed.emit(id, content)

func toggle_window(id: String, index: int) -> void:
	window_toggled.emit(id, index, true)

func spawn_drone() -> void:
	var drone_id = "drone_" + str(Time.get_ticks_msec())
	drone_spawned.emit(drone_id)
	_log_event("🛸 无人机飞过")

func check_late_night_events() -> void:
	if not has_node("/root/DayNightManager"):
		return

	var dnm = get_node("/root/DayNightManager")
	var phase_value = dnm.current_phase

	for event_id in _late_night_events:
		var event = _late_night_events[event_id]
		if phase_value >= event["min_phase"]:
			if randf() < 0.15:
				late_night_event_triggered.emit(event_id)
				_log_event("⚡ " + event["name"] + ": " + event["description"])

				if event_id == "glitch_billboard":
					change_billboard("main", "▓▓▓数据异常异常▓▓▓")
					await get_tree().create_timer(3.0).timeout
					change_billboard("main", "DATAWHALE 招聘中")

func _random_neon_flicker():
	var buildings = ["ramen", "convenience", "pharmacy", "bar", "datawhale"]
	var id = buildings[randi() % buildings.size()]
	flicker_neon(id)

func _random_window_toggle():
	var buildings = ["apartment_a", "apartment_b", "office_block"]
	var id = buildings[randi() % buildings.size()]
	var index = randi() % 5
	toggle_window(id, index)

func get_billboard_content(id: String) -> String:
	return _billboard_contents.get(id, "")

func is_raining() -> bool:
	return _is_raining

func _log_event(message: String):
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)
