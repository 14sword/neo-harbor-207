extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var manager = root.get_node_or_null("/root/RiftRunManager")
	if not manager:
		errors.append("RIFT_MANAGER_MISSING")
	else:
		_verify_pacing(manager, errors)
	print("====== VERIFY RIFT PACING ======")
	if errors.is_empty():
		print("Rift pacing checks passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _verify_pacing(manager: Node, errors: Array[String]) -> void:
	var packed: PackedScene = load("res://scenes/rift_run.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	var spawner: Node = scene.get_node("EnemySpawner")
	var run: Dictionary = manager.start_run(7777, 1)
	var tiles: Array = run.get("tiles", [])
	for tile_type in ["normal", "elite", "boss"]:
		var tile: Dictionary = _first_tile_of_type(tiles, tile_type)
		if tile.is_empty():
			errors.append("PACING_TILE_MISSING: " + tile_type)
			continue
		spawner.start_node(tile, 1)
		var snapshot: Dictionary = spawner.get_active_pacing()
		_check_max_enemies(tile_type, int(snapshot.get("max_enemies", 0)), errors)
		var queue: Array = snapshot.get("queue", [])
		if queue.is_empty():
			errors.append("PACING_QUEUE_EMPTY: " + tile_type)
		for group in queue:
			_check_group_shape(tile_type, group, errors)
		spawner.clear_enemies()
	_verify_spawn_distance(spawner, errors)
	scene.queue_free()

func _first_tile_of_type(tiles: Array, tile_type: String) -> Dictionary:
	for tile in tiles:
		if str(tile.get("type", "")) == tile_type:
			return tile
	return {}

func _check_max_enemies(tile_type: String, value: int, errors: Array[String]) -> void:
	match tile_type:
		"normal":
			if value < 10 or value > 14:
				errors.append("NORMAL_MAX_ENEMIES_INVALID: %d" % value)
		"elite":
			if value < 12 or value > 16:
				errors.append("ELITE_MAX_ENEMIES_INVALID: %d" % value)
		"boss":
			if value < 8 or value > 12:
				errors.append("BOSS_MAX_ENEMIES_INVALID: %d" % value)

func _check_group_shape(tile_type: String, group: Dictionary, errors: Array[String]) -> void:
	var members: Array = group.get("members", [])
	if members.is_empty():
		errors.append("PACING_GROUP_EMPTY: " + tile_type)
	var warning_time: float = float(group.get("warning_time", 0.0))
	if warning_time < 0.68 or warning_time > 1.35:
		errors.append("PACING_WARNING_TIME_INVALID: %s %.2f" % [tile_type, warning_time])
	var interval_after: float = float(group.get("interval_after", 0.0))
	if interval_after < 0.8 or interval_after > 2.8:
		errors.append("PACING_INTERVAL_INVALID: %s %.2f" % [tile_type, interval_after])

func _verify_spawn_distance(spawner: Node, errors: Array[String]) -> void:
	var dummy := Node2D.new()
	dummy.global_position = Vector2(960, 710)
	dummy.add_to_group("rift_player")
	root.add_child(dummy)
	for i in range(20):
		var pos: Vector2 = spawner.call("_random_spawn_position")
		if pos.distance_to(dummy.global_position) < 280.0:
			errors.append("SPAWN_TOO_CLOSE: %.1f" % pos.distance_to(dummy.global_position))
			break
	dummy.queue_free()

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
