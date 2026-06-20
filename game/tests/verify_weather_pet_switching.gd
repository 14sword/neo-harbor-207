extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame

	var errors: Array[String] = []
	var root = get_root()
	var scene_manager = root.get_node_or_null("SceneManager")
	var day_night_manager = root.get_node_or_null("DayNightManager")
	var weather_effects = root.get_node_or_null("WeatherEffects")
	var pet_manager = root.get_node_or_null("PetManager")

	if not scene_manager:
		errors.append("MISSING: /root/SceneManager")
	if not day_night_manager:
		errors.append("MISSING: /root/DayNightManager")
	if not weather_effects:
		errors.append("MISSING: /root/WeatherEffects")
	if not pet_manager:
		errors.append("MISSING: /root/PetManager")
	if not errors.is_empty():
		_finish(errors)
		return

	var err = change_scene_to_file("res://scenes/street.tscn")
	if err != OK:
		errors.append("FAILED: change_scene_to_file street (%d)" % err)
		_finish(errors)
		return

	await process_frame
	await process_frame
	scene_manager.current_scene = scene_manager.GameScene.STREET

	await _verify_weather_node_reuse(weather_effects, errors)
	await process_frame
	await _verify_background_preload(day_night_manager, errors)
	await process_frame
	await _verify_pet_instance_cache(pet_manager, scene_manager, errors)

	_finish(errors)

func _verify_weather_node_reuse(weather_effects: Node, errors: Array[String]) -> void:
	weather_effects.current_weather = weather_effects.WeatherType.SUNNY
	weather_effects.set_weather(weather_effects.WeatherType.LIGHT_RAIN)
	await process_frame

	var scene = current_scene
	var overlay = scene.get_node_or_null("WeatherOverlay")
	var rain = scene.get_node_or_null("RainParticles")
	if not overlay:
		errors.append("WEATHER: overlay was not created")
	if not rain:
		errors.append("WEATHER: rain particles were not created")
	if not errors.is_empty():
		return

	var overlay_id = overlay.get_instance_id()
	var rain_id = rain.get_instance_id()
	if not rain.visible or not rain.emitting or rain.amount != 40:
		errors.append("WEATHER: light rain did not activate expected particles")

	weather_effects.set_weather(weather_effects.WeatherType.THUNDERSTORM)
	await process_frame
	var lightning = scene.get_node_or_null("LightningFlash")
	if not lightning:
		errors.append("WEATHER: lightning rect was not created")
	if scene.get_node_or_null("WeatherOverlay").get_instance_id() != overlay_id:
		errors.append("WEATHER: overlay was recreated during switch")
	if scene.get_node_or_null("RainParticles").get_instance_id() != rain_id:
		errors.append("WEATHER: rain particles were recreated during switch")
	if rain.amount != 80 or not rain.visible or not rain.emitting:
		errors.append("WEATHER: thunderstorm did not reuse active heavy rain")

	weather_effects.set_weather(weather_effects.WeatherType.CLOUDY)
	await process_frame
	if rain.visible or rain.emitting:
		errors.append("WEATHER: cloudy did not disable rain particles")
	if scene.get_node_or_null("RainParticles").get_instance_id() != rain_id:
		errors.append("WEATHER: rain particles changed after cloudy switch")

	print("  OK: weather switching reuses overlay/rain/lightning nodes")

func _verify_background_preload(day_night_manager: Node, errors: Array[String]) -> void:
	var bg = get_first_node_in_group("background")
	if not bg or not bg is Sprite2D:
		errors.append("BACKGROUND: missing Sprite2D background")
		return

	var expected_path = day_night_manager.street_backgrounds.get(day_night_manager.DayPhase.RAIN_NIGHT, "")
	day_night_manager.set_phase(day_night_manager.DayPhase.RAIN_NIGHT)

	for _i in range(180):
		var current_path = bg.texture.resource_path if bg.texture else ""
		if current_path == expected_path:
			break
		await process_frame

	var final_path = bg.texture.resource_path if bg.texture else ""
	if final_path != expected_path:
		errors.append("BACKGROUND: expected %s got %s" % [expected_path, final_path])
	else:
		print("  OK: background switches after preload without synchronous load path")

func _verify_pet_instance_cache(pet_manager: Node, scene_manager: Node, errors: Array[String]) -> void:
	pet_manager.ensure_pet_in_scene()
	await process_frame

	var first_pet = pet_manager.get_active_pet()
	if not first_pet or not is_instance_valid(first_pet):
		errors.append("PET: first active pet missing")
		return
	var first_id = first_pet.get_instance_id()
	if first_pet.get_parent() != current_scene:
		errors.append("PET: active pet was not attached to current scene")

	pet_manager._switch_to_next_pet()
	await process_frame
	var second_pet = pet_manager.get_active_pet()
	if not second_pet or not is_instance_valid(second_pet):
		errors.append("PET: second active pet missing")
		return
	if second_pet.get_instance_id() == first_id:
		errors.append("PET: switching did not activate a different pet")
	if first_pet.visible or first_pet.process_mode != Node.PROCESS_MODE_DISABLED:
		errors.append("PET: previous pet was not hidden and disabled")
	if not second_pet.visible or second_pet.process_mode == Node.PROCESS_MODE_DISABLED:
		errors.append("PET: new pet was not active")
	if scene_manager._persistent_nodes.has(first_pet):
		errors.append("PET: inactive pet remained registered as persistent")
	if not scene_manager._persistent_nodes.has(second_pet):
		errors.append("PET: active pet was not registered as persistent")

	for _i in range(3):
		pet_manager._switch_to_next_pet()
		await process_frame

	var first_again = pet_manager.get_active_pet()
	if not first_again or first_again.get_instance_id() != first_id:
		errors.append("PET: first pet instance was not reused after cycle")
	else:
		print("  OK: pet switching reuses cached instances")

func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("====== WEATHER AND PET SWITCHING OK ======")
		quit(0)
	else:
		print("====== WEATHER AND PET SWITCHING ERRORS ======")
		for error in errors:
			print(error)
		quit(1)
