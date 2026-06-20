extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var mgr = root.get_node_or_null("/root/RiftRunManager")
	if not mgr:
		errors.append("RiftRunManager autoload missing")
	else:
		_verify_rewards(mgr, errors)
	print("====== VERIFY RIFT REWARDS ======")
	if errors.is_empty():
		print("Rift reward checks passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _verify_rewards(mgr: Node, errors: Array[String]) -> void:
	mgr.set("discovered_clues", {})
	mgr.start_run(2222, 1)
	for i in range(3):
		var tile_id := "tile_%02d" % [i + 1]
		var tile: Dictionary = mgr.choose_tile(tile_id)
		if tile.is_empty():
			errors.append("TILE_CHOOSE_FAILED: " + tile_id)
			return
		mgr.complete_current_node(8 + i, 12.0 * i, 3 + i)
	var result: Dictionary = mgr.end_run("evacuated")
	for field in ["status", "rating", "cleared_nodes", "total_kills", "exp", "currency", "materials", "equipment_drops", "new_clues", "unresolved_phenomena"]:
		if not result.has(field):
			errors.append("RESULT_FIELD_MISSING: " + field)
	if int(result.get("cleared_nodes", 0)) != 3:
		errors.append("RESULT_CLEARED_INVALID")
	if int(result.get("exp", 0)) <= 0:
		errors.append("RESULT_EXP_NOT_POSITIVE")
	if int(result.get("currency", 0)) <= 0:
		errors.append("RESULT_CURRENCY_NOT_POSITIVE")
	if not result.get("materials", {}).has("rift_shard"):
		errors.append("RESULT_RIFT_SHARD_MISSING")
	if result.get("new_clues", []).is_empty():
		errors.append("RESULT_CLUES_EMPTY")
	if result.get("unresolved_phenomena", []).is_empty():
		errors.append("RESULT_PHENOMENA_EMPTY")
	var drops: Array = result.get("equipment_drops", [])
	if drops.is_empty():
		errors.append("RESULT_DROPS_EMPTY")
	for item in drops:
		if not item.has("slot") or not item.has("rarity") or not item.has("instance_id"):
			errors.append("DROP_SHAPE_INVALID: " + str(item))

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
