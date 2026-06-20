extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var scene_path: String = "res://scenes/anomaly_space.tscn"
	if not FileAccess.file_exists(scene_path):
		errors.append("ANOMALY_SCENE_MISSING")
	else:
		var text: String = FileAccess.get_file_as_string(scene_path)
		_verify_scene_text(text, errors)
	print("====== VERIFY RIFT ENTRY ======")
	if errors.is_empty():
		print("Rift entry checks passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _verify_scene_text(text: String, errors: Array[String]) -> void:
	if not text.contains('portal_scene_name = "RIFT_RUN"'):
		errors.append("PORTAL_TARGET_INVALID")
	if not text.contains('portal_prompt_key = "enter_rift"'):
		errors.append("PORTAL_PROMPT_INVALID")
	for path in [
		"res://assets/backgrounds/anomaly_space/裂隙_白天.png",
		"res://assets/backgrounds/anomaly_space/裂隙_傍晚.png",
		"res://assets/backgrounds/anomaly_space/裂隙_黑夜.png",
		"res://assets/backgrounds/anomaly_space/裂隙_雨夜.png",
	]:
		if not _asset_exists(path):
			errors.append("RIFT_ENTRY_BACKGROUND_MISSING: " + path)
		else:
			var size: Vector2 = _asset_size(path)
			if size != Vector2(1672, 941):
				errors.append("RIFT_ENTRY_BACKGROUND_SIZE_INVALID: %s %s" % [path, size])
	if not text.contains('[node name="RiftEntryZone" type="Area2D" parent="."]'):
		errors.append("RIFT_ENTRY_ZONE_MISSING")
	if not text.contains('position = Vector2(836, 390)'):
		errors.append("RIFT_ENTRY_POSITION_INVALID")
	if not text.contains("input_pickable = true"):
		errors.append("RIFT_ENTRY_NOT_CLICKABLE")
	if not text.contains('[node name="RiftGateVisual" type="Sprite2D" parent="."]'):
		errors.append("RIFT_GATE_VISUAL_MISSING")
	if not text.contains('[node name="RiftEntryFX" type="Node2D" parent="."]'):
		errors.append("RIFT_ENTRY_FX_MISSING")
	if not text.contains("visible = false"):
		errors.append("RIFT_GATE_BLACK_PATCH_STILL_VISIBLE")
	if not _asset_exists("res://assets/rift/gate/rift_gate.png"):
		errors.append("RIFT_GATE_TEXTURE_MISSING")

func _asset_exists(path: String) -> bool:
	if ResourceLoader.exists(path):
		return true
	return FileAccess.file_exists(path)

func _asset_size(path: String) -> Vector2:
	if ResourceLoader.exists(path):
		var texture: Texture2D = load(path)
		if texture:
			return texture.get_size()
	var image := Image.new()
	var err: Error = image.load(path)
	if err == OK:
		return Vector2(image.get_width(), image.get_height())
	return Vector2.ZERO

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
