extends SceneTree

const CLASS_IDS = ["cipher", "chrome", "echo", "shadow"]
const EPSILON: float = 0.001

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame

	var errors: Array[String] = []
	var root = get_root()
	var ccm = root.get_node_or_null("CharacterClassManager")
	var scene_manager = root.get_node_or_null("SceneManager")
	var weather_effects = root.get_node_or_null("WeatherEffects")
	if not ccm:
		print("MISSING: /root/CharacterClassManager")
		quit(1)
		return
	if not scene_manager:
		print("MISSING: /root/SceneManager")
		quit(1)
		return
	if not weather_effects:
		print("MISSING: /root/WeatherEffects")
		quit(1)
		return

	var player_scene = load("res://scenes/player.tscn")
	if not player_scene:
		print("MISSING: res://scenes/player.tscn")
		quit(1)
		return

	var original_scene = scene_manager.current_scene
	var original_weather = weather_effects.current_weather

	for class_idx in range(CLASS_IDS.size()):
		var class_id = CLASS_IDS[class_idx]
		ccm.load_save_data({
			"current_class": class_idx,
			"player_name": "ScaleTest",
			"class_selected": true,
			"visual_form_mode": "class",
		})

		var player = player_scene.instantiate()
		root.add_child(player)
		await process_frame

		var sprite: Sprite2D = player.get_node("Sprite2D")
		_expect_vector2(sprite.scale, player._form_scale, "%s INITIAL SCALE" % class_id, errors)

		scene_manager.current_scene = scene_manager.GameScene.STREET
		weather_effects.current_weather = WeatherEffects.WeatherType.LIGHT_RAIN
		if not player._should_apply_rain_waiting_pose():
			errors.append("%s STREET RAIN CONDITION FALSE: scene=%s weather=%s raining=%s" % [
				class_id,
				str(scene_manager.current_scene),
				str(weather_effects.current_weather),
				str(weather_effects.is_raining()),
			])
		player._physics_process(0.016)
		if not player._rain_waiting_active:
			errors.append("%s STREET RAIN NOT ACTIVE IMMEDIATELY: velocity=%s idle_alt=%s interacting=%s" % [
				class_id,
				str(player.velocity),
				str(player._idle_alt_active),
				str(player.is_interacting),
			])
		await create_timer(0.35).timeout
		_expect_bool(player._rain_waiting_active, true, "%s STREET RAIN ACTIVE" % class_id, errors)
		var expected_rain_scale_y = player._form_scale.y * player.RAIN_WAIT_SCALE_Y_FACTOR
		_expect_float(sprite.scale.y, expected_rain_scale_y, "%s STREET RAIN SCALE Y" % class_id, errors)
		if abs(sprite.scale.y - 0.9) <= EPSILON:
			errors.append("%s STREET RAIN SCALE USED ABSOLUTE 0.9" % class_id)

		scene_manager.current_scene = scene_manager.GameScene.APARTMENT
		player._physics_process(0.016)
		await create_timer(0.35).timeout
		_expect_bool(player._rain_waiting_active, false, "%s APARTMENT RAIN INACTIVE" % class_id, errors)
		_expect_float(sprite.scale.y, player._form_scale.y, "%s APARTMENT SCALE Y" % class_id, errors)

		scene_manager.current_scene = scene_manager.GameScene.STREET
		player._set_rain_waiting_active(true, false)
		_expect_bool(player._rain_waiting_active, true, "%s MANUAL RAIN ACTIVE" % class_id, errors)
		_expect_float(sprite.scale.y, expected_rain_scale_y, "%s MANUAL RAIN SCALE Y" % class_id, errors)
		weather_effects.current_weather = WeatherEffects.WeatherType.SUNNY
		ccm.load_save_data({
			"current_class": class_idx,
			"player_name": "ScaleTest",
			"class_selected": true,
			"visual_form_mode": "default",
		})
		await process_frame
		_expect_bool(player._rain_waiting_active, false, "%s RELOAD CLEARS RAIN" % class_id, errors)
		_expect_float(sprite.scale.y, player._form_scale.y, "%s RELOAD SCALE Y" % class_id, errors)

		print("  OK: %s idle rain scale" % class_id)
		player.queue_free()
		await process_frame

	scene_manager.current_scene = original_scene
	weather_effects.current_weather = original_weather

	if errors.is_empty():
		print("====== PLAYER IDLE SCALE OK ======")
		quit(0)
	else:
		print("====== PLAYER IDLE SCALE ERRORS ======")
		for error in errors:
			print(error)
		quit(1)

func _expect_bool(actual: bool, expected: bool, label: String, errors: Array[String]) -> void:
	if actual != expected:
		errors.append("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _expect_float(actual: float, expected: float, label: String, errors: Array[String]) -> void:
	if abs(actual - expected) > EPSILON:
		errors.append("%s: expected %.4f got %.4f" % [label, expected, actual])

func _expect_vector2(actual: Vector2, expected: Vector2, label: String, errors: Array[String]) -> void:
	if actual.distance_to(expected) > EPSILON:
		errors.append("%s: expected %s got %s" % [label, str(expected), str(actual)])
