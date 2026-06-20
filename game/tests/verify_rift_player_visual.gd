extends SceneTree

const CLASS_IDS: Array[String] = ["cipher", "chrome", "echo", "shadow"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var ccm = root.get_node_or_null("/root/CharacterClassManager")
	if not ccm:
		errors.append("CHARACTER_CLASS_MANAGER_MISSING")
	else:
		await _verify_class_visuals(ccm, errors)
		await _verify_default_visual(ccm, errors)
	print("====== VERIFY RIFT PLAYER VISUAL ======")
	if errors.is_empty():
		print("Rift player visual checks passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _verify_class_visuals(ccm: Node, errors: Array[String]) -> void:
	for class_idx in range(CLASS_IDS.size()):
		var class_id: String = CLASS_IDS[class_idx]
		ccm.load_save_data({
			"current_class": class_idx,
			"player_name": "RiftVisualTest",
			"class_selected": true,
			"visual_form_mode": "class",
		})
		var instance: Node = await _make_rift_run_instance()
		var player: Node = instance.get_node("Player")
		var sprite: Sprite2D = player.get_node("Sprite2D")
		var expected_prefix: String = "res://assets/characters/player/classes/%s/%s_idle_" % [class_id, class_id]
		var actual: String = sprite.texture.resource_path if sprite.texture else ""
		if not actual.begins_with(expected_prefix):
			errors.append("RIFT_CLASS_TEXTURE_MISMATCH: %s expected %s got %s" % [class_id, expected_prefix, actual])
		if player.get("class_id") != class_id:
			errors.append("RIFT_CLASS_ID_MISMATCH: expected %s got %s" % [class_id, player.get("class_id")])
		instance.queue_free()
		await process_frame

func _verify_default_visual(ccm: Node, errors: Array[String]) -> void:
	ccm.load_save_data({
		"current_class": 0,
		"player_name": "RiftVisualTest",
		"class_selected": true,
		"visual_form_mode": "default",
	})
	var instance: Node = await _make_rift_run_instance()
	var sprite: Sprite2D = instance.get_node("Player/Sprite2D")
	var actual: String = sprite.texture.resource_path if sprite.texture else ""
	if actual != "res://assets/characters/player/player_idle.png":
		errors.append("RIFT_DEFAULT_TEXTURE_MISMATCH: got " + actual)
	instance.queue_free()
	await process_frame

func _make_rift_run_instance() -> Node:
	var packed: PackedScene = load("res://scenes/rift_run.tscn")
	var instance: Node = packed.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	return instance

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
