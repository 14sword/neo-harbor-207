extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var manager = root.get_node_or_null("/root/RiftRunManager")
	var env_script: Script = load("res://scripts/rift/rift_environment_manager.gd")
	if not manager:
		errors.append("RIFT_MANAGER_MISSING")
	if not env_script:
		errors.append("ENV_SCRIPT_MISSING")
	if errors.is_empty():
		await _verify_environment_switch(manager, env_script, errors)
	print("====== VERIFY RIFT ENVIRONMENT ======")
	if errors.is_empty():
		print("Rift environment checks passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _verify_environment_switch(manager: Node, env_script: Script, errors: Array[String]) -> void:
	var env: Node2D = Node2D.new()
	env.set_script(env_script)
	root.add_child(env)
	var background := Sprite2D.new()
	root.add_child(background)
	await process_frame
	var run: Dictionary = manager.start_run(3333, 1)
	var weather_seen: Dictionary = {}
	for tile in run.get("tiles", []):
		var weather: String = str(tile.get("weather", ""))
		if weather_seen.has(weather):
			continue
		weather_seen[weather] = true
		env.call("apply_tile_environment", tile, background)
		await process_frame
		if not background.texture:
			errors.append("BACKGROUND_NOT_APPLIED: " + weather)
		else:
			var size: Vector2 = background.texture.get_size()
			if size.x < 1900.0 or size.y < 1000.0:
				errors.append("BACKGROUND_RESOLUTION_LOW: %s %s" % [weather, size])
	for weather in ["data_rain", "rift_snow", "thunderstorm", "fog_tide"]:
		if not weather_seen.has(weather):
			errors.append("WEATHER_NOT_TESTED: " + weather)
	env.queue_free()
	background.queue_free()

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
