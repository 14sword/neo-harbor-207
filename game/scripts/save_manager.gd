extends Node

const SAVE_DIR = "user://saves/"
const SAVE_FILE = SAVE_DIR + "save_slot_1.json"
const AUTO_SAVE_INTERVAL: float = 120.0

var _auto_save_timer: float = 0.0
var _has_save: bool = false
var _is_loading: bool = false

signal save_completed()
signal load_completed()

func _ready():
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_has_save = FileAccess.file_exists(SAVE_FILE)

func has_save() -> bool:
	return _has_save

func save_game() -> bool:
	if _is_loading:
		return false
	var player = get_tree().get_first_node_in_group("player")
	var current_scene_str = "apartment"
	if has_node("/root/SceneManager"):
		var sm = get_node("/root/SceneManager")
		if sm.is_street():
			current_scene_str = "street"
		elif sm.is_office():
			current_scene_str = "office"
		elif sm.is_apartment():
			current_scene_str = "apartment"
		elif sm.is_underground():
			current_scene_str = "underground"
		elif sm.is_anomaly_space():
			current_scene_str = "anomaly_space"
		elif sm.is_rift_run():
			current_scene_str = "rift_run"

	var save_data = {
		"version": 3,
		"timestamp": Time.get_datetime_string_from_system(),
		"current_scene": current_scene_str,
		"player": {
			"x": player.global_position.x if player else 640.0,
			"y": player.global_position.y if player else 600.0,
		},
		"day_phase": _get_day_phase(),
		"quests": _get_quest_progress(),
		"calendar": _get_calendar_data(),
		"game_manager": _get_game_manager_data(),
	}
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		print("[SaveManager] 保存失败: " + str(FileAccess.get_open_error()))
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	
	_has_save = true
	print("[SaveManager] 游戏已保存")
	_log_event("💾 游戏已保存")
	save_completed.emit()
	return true

func load_game() -> bool:
	if not _has_save:
		print("[SaveManager] 没有存档")
		return false
	
	_is_loading = true
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		print("[SaveManager] 读取存档失败")
		_is_loading = false
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("[SaveManager] 存档解析失败")
		_is_loading = false
		return false
	
	var save_data = json.data

	if save_data.has("day_phase") and has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		var target_phase = save_data["day_phase"]
		if dnm.current_phase != target_phase:
			dnm.current_phase = target_phase
			dnm._apply_background()
			dnm._apply_bgm()
			dnm._apply_night_effects()
			dnm.phase_changed.emit(dnm.current_phase)

	if save_data.has("current_scene"):
		await _restore_saved_scene(str(save_data["current_scene"]))

	var player = get_tree().get_first_node_in_group("player")
	if player and save_data.has("player"):
		player.global_position = Vector2(
			save_data["player"].get("x", 640.0),
			save_data["player"].get("y", 600.0)
		)
	
	if save_data.has("quests"):
		_apply_quest_progress(save_data["quests"])
	
	if save_data.has("calendar"):
		_apply_calendar_data(save_data["calendar"])
	
	if save_data.has("game_manager"):
		_apply_game_manager_data(save_data["game_manager"])
	_sync_current_area_discovery()
	
	print("[SaveManager] 存档已加载")
	_log_event("📂 存档已加载")
	_is_loading = false
	load_completed.emit()
	return true

func _restore_saved_scene(target_scene: String) -> void:
	if not has_node("/root/SceneManager"):
		return
	var sm = get_node("/root/SceneManager")
	var scene_info = _get_scene_restore_info(sm, target_scene)
	if scene_info.is_empty():
		return
	var is_current: Callable = scene_info["is_current"]
	if is_current.call():
		return
	sm.transition_to(scene_info["scene"])
	await get_tree().create_timer(1.0).timeout

func _get_scene_restore_info(sm: Node, target_scene: String) -> Dictionary:
	match target_scene:
		"street":
			return {"scene": sm.GameScene.STREET, "is_current": Callable(sm, "is_street")}
		"office":
			return {"scene": sm.GameScene.OFFICE, "is_current": Callable(sm, "is_office")}
		"apartment":
			return {"scene": sm.GameScene.APARTMENT, "is_current": Callable(sm, "is_apartment")}
		"underground":
			return {"scene": sm.GameScene.UNDERGROUND, "is_current": Callable(sm, "is_underground")}
		"anomaly_space":
			return {"scene": sm.GameScene.ANOMALY_SPACE, "is_current": Callable(sm, "is_anomaly_space")}
		"rift_run":
			return {"scene": sm.GameScene.ANOMALY_SPACE, "is_current": Callable(sm, "is_anomaly_space")}
	return {}

func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)
		_has_save = false
		print("[SaveManager] 存档已删除")
		_log_event("🗑️ 存档已删除")
		return true
	return false

func _process(delta: float):
	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		save_game()

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			if event.ctrl_pressed:
				load_game()
			else:
				save_game()

func _get_day_phase() -> int:
	if has_node("/root/DayNightManager"):
		return get_node("/root/DayNightManager").current_phase
	return 0

func _get_quest_progress() -> Dictionary:
	if has_node("/root/QuestManager"):
		return get_node("/root/QuestManager").get_save_data()
	return {}

func _get_calendar_data() -> Dictionary:
	if has_node("/root/WorldCalendar"):
		return get_node("/root/WorldCalendar").get_save_data()
	return {}

func _apply_quest_progress(data: Dictionary) -> void:
	if has_node("/root/QuestManager"):
		get_node("/root/QuestManager").load_save_data(data)

func _apply_calendar_data(data: Dictionary) -> void:
	if has_node("/root/WorldCalendar"):
		get_node("/root/WorldCalendar").load_save_data(data)

func _get_game_manager_data() -> Dictionary:
	var data = {}
	if has_node("/root/GameManager"):
		data["game_manager"] = get_node("/root/GameManager").get_save_data()
	if has_node("/root/CharacterClassManager"):
		data["character_class"] = get_node("/root/CharacterClassManager").get_save_data()
	if has_node("/root/StoryManager"):
		data["story"] = get_node("/root/StoryManager").get_save_data()
	if has_node("/root/RiftRunManager"):
		data["rift_run"] = get_node("/root/RiftRunManager").get_save_data()
	if has_node("/root/APIClient"):
		data["api_client"] = get_node("/root/APIClient").get_save_data()
	if has_node("/root/DialogueDirector"):
		data["dialogue_director"] = get_node("/root/DialogueDirector").get_save_data()
	return data

func _apply_game_manager_data(data: Dictionary) -> void:
	if data.has("game_manager") and has_node("/root/GameManager"):
		get_node("/root/GameManager").load_save_data(data["game_manager"])
	if data.has("character_class") and has_node("/root/CharacterClassManager"):
		get_node("/root/CharacterClassManager").load_save_data(data["character_class"])
	if data.has("story") and has_node("/root/StoryManager"):
		get_node("/root/StoryManager").load_save_data(data["story"])
	if data.has("rift_run") and has_node("/root/RiftRunManager"):
		get_node("/root/RiftRunManager").load_save_data(data["rift_run"])
	if data.has("api_client") and has_node("/root/APIClient"):
		get_node("/root/APIClient").load_save_data(data["api_client"])
	if data.has("dialogue_director") and has_node("/root/DialogueDirector"):
		get_node("/root/DialogueDirector").load_save_data(data["dialogue_director"])

func _sync_current_area_discovery() -> void:
	var sm = get_node_or_null("/root/SceneManager")
	var gm = get_node_or_null("/root/GameManager")
	if sm and gm and sm.has_method("get_current_area_id") and gm.has_method("discover_area"):
		var area_id := str(sm.get_current_area_id())
		if not area_id.is_empty():
			gm.discover_area(area_id)

func _log_event(message: String) -> void:
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)
