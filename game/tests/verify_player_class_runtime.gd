extends SceneTree

const CLASS_IDS = ["cipher", "chrome", "echo", "shadow"]
const DIRECTIONS = ["down", "up", "left", "right"]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame

	var errors: Array[String] = []
	var root = get_root()
	var ccm = root.get_node_or_null("CharacterClassManager")
	if not ccm:
		print("MISSING: /root/CharacterClassManager")
		quit(1)
		return

	var player_scene = load("res://scenes/player.tscn")
	if not player_scene:
		print("MISSING: res://scenes/player.tscn")
		quit(1)
		return

	for class_idx in range(CLASS_IDS.size()):
		var class_id = CLASS_IDS[class_idx]
		ccm.load_save_data({
			"current_class": class_idx,
			"player_name": "RuntimeTest",
			"class_selected": true,
			"visual_form_mode": "class",
		})

		var player = player_scene.instantiate()
		root.add_child(player)
		await process_frame

		var sprite: Sprite2D = player.get_node("Sprite2D")
		_verify_class_frames(player, sprite, class_id, errors)

		_press_toggle_key(player)
		await process_frame
		var mode = ccm.get_visual_form_mode()
		if mode != "default":
			errors.append("TOGGLE MODE MISMATCH: expected default got %s" % mode)
		_verify_default_frames(player, sprite, errors)
		var save_data = ccm.get_save_data()
		if save_data.get("visual_form_mode", "") != "default":
			errors.append("SAVE MODE MISMATCH: expected default got %s" % save_data.get("visual_form_mode", ""))

		_press_toggle_key(player)
		await process_frame
		mode = ccm.get_visual_form_mode()
		if mode != "class":
			errors.append("TOGGLE MODE MISMATCH: expected class got %s" % mode)
		_verify_class_frames(player, sprite, class_id, errors)

		ccm.load_save_data({
			"current_class": class_idx,
			"player_name": "RuntimeTest",
			"class_selected": true,
			"visual_form_mode": "default",
		})
		await process_frame
		_verify_default_frames(player, sprite, errors)

		ccm.load_save_data({
			"current_class": class_idx,
			"player_name": "RuntimeTest",
			"class_selected": true,
		})
		await process_frame
		if ccm.get_visual_form_mode() != "class":
			errors.append("OLD SAVE DEFAULT MISMATCH: expected class got %s" % ccm.get_visual_form_mode())
		_verify_class_frames(player, sprite, class_id, errors)

		print("  OK: %s runtime walk + idle frames + form toggle" % class_id)
		player.queue_free()
		await process_frame

	if errors.is_empty():
		print("====== PLAYER CLASS RUNTIME OK ======")
		quit(0)
	else:
		print("====== PLAYER CLASS RUNTIME ERRORS ======")
		for error in errors:
			print(error)
		quit(1)

func _verify_class_frames(player: Node, sprite: Sprite2D, class_id: String, errors: Array[String]) -> void:
	for direction in DIRECTIONS:
		for frame_idx in range(3):
			player._current_direction = direction
			player._current_frame = frame_idx
			player._apply_frame()
			var expected = "res://assets/characters/player/classes/%s/%s_%s_%d.png" % [class_id, class_id, direction, frame_idx]
			_expect_texture(sprite.texture, expected, "CLASS WALK", errors)

	for frame_idx in range(5):
		player._idle_anim_frame = frame_idx
		var expected_idle = "res://assets/characters/player/classes/%s/%s_idle_%d.png" % [class_id, class_id, frame_idx]
		_expect_texture(player._get_idle_texture(), expected_idle, "CLASS IDLE", errors)

func _verify_default_frames(player: Node, sprite: Sprite2D, errors: Array[String]) -> void:
	for direction in DIRECTIONS:
		for frame_idx in range(3):
			player._current_direction = direction
			player._current_frame = frame_idx
			player._apply_frame()
			var expected = "res://assets/characters/player/player_%s_%d.png" % [direction, frame_idx]
			_expect_texture(sprite.texture, expected, "DEFAULT WALK", errors)

	_expect_texture(player._get_idle_texture(), "res://assets/characters/player/player_idle.png", "DEFAULT IDLE", errors)

func _expect_texture(texture: Texture2D, expected: String, label: String, errors: Array[String]) -> void:
	var actual = texture.resource_path if texture else ""
	if actual != expected:
		errors.append("%s MISMATCH: expected %s got %s" % [label, expected, actual])

func _press_toggle_key(player: Node) -> void:
	var event = InputEventKey.new()
	event.keycode = KEY_X
	event.pressed = true
	player._input(event)
