extends SceneTree

const EXPECTED_IMAGE_SIZE := Vector2i(1672, 941)

const SPECIAL_SCENES := {
	"res://scenes/underground.tscn": {
		"background_dir": "res://assets/backgrounds/underground/",
		"root": "Underground",
		"air_walls": [
			"Bounds/TopSceneryAirWall",
			"Bounds/RailTrenchAirWall",
			"Bounds/ForegroundAirWall",
		],
		"npc": "NPCs/NPC_SunYue",
		"safe_min": Vector2(20, 145),
		"safe_max": Vector2(1410, 845),
	},
	"res://scenes/anomaly_space.tscn": {
		"background_dir": "res://assets/backgrounds/anomaly_space/",
		"root": "AnomalySpace",
		"air_walls": [
			"Bounds/TopVoidAirWall",
			"Bounds/BottomVoidAirWall",
			"Bounds/LeftVoidAirWall",
			"Bounds/RightVoidAirWall",
		],
		"npc": "NPCs/NPC_HeZhen",
		"safe_min": Vector2(245, 195),
		"safe_max": Vector2(1428, 845),
	},
}

const PHASE_FILES := ["白天.png", "傍晚.png", "黑夜.png", "雨夜.png"]

const UNDERGROUND_AMBIENT_NODES := {
	"HoloNotice": {
		"position": Vector2(520, 260),
		"z_range": Vector2i(20, 28),
	},
	"MaintenanceMonitor": {
		"position": Vector2(1030, 205),
		"z_range": Vector2i(20, 28),
	},
	"TrainLightSweep": {
		"position": Vector2(1320, 520),
		"z_range": Vector2i(20, 28),
		"allow_air_wall": true,
	},
	"SteamPuffA": {
		"position": Vector2(360, 690),
		"z_range": Vector2i(30, 33),
	},
	"SteamPuffB": {
		"position": Vector2(1180, 720),
		"z_range": Vector2i(30, 33),
	},
	"DripReflectionA": {
		"position": Vector2(650, 790),
		"z_range": Vector2i(30, 33),
	},
	"DripReflectionB": {
		"position": Vector2(980, 760),
		"z_range": Vector2i(30, 33),
	},
	"SunYueResearchKit": {
		"position": Vector2(720, 635),
		"z_range": Vector2i(30, 33),
	},
	"PortalPulse": {
		"position": Vector2(836, 320),
		"z_range": Vector2i(34, 36),
	},
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []

	print("====== VERIFY SPECIAL SCENE LAYOUT ======")
	for scene_path in SPECIAL_SCENES.keys():
		var spec: Dictionary = SPECIAL_SCENES[scene_path]
		_verify_phase_images(spec, errors)
		_verify_scene(scene_path, spec, errors)

	print("\n====== RESULT ======")
	if errors.is_empty():
		print("Special scene layout passed: %d scenes" % SPECIAL_SCENES.size())
		quit(0)
	else:
		for error in errors:
			print(error)
		print("Special scene layout failed: %d issue(s)" % errors.size())
		quit(1)

func _verify_phase_images(spec: Dictionary, errors: Array[String]) -> void:
	for phase_file in PHASE_FILES:
		var path: String = spec["background_dir"] + phase_file
		var img := Image.new()
		var err := img.load(path)
		if err != OK:
			errors.append("PHASE_IMAGE_LOAD_FAILED: " + path)
			continue
		if img.get_size() != EXPECTED_IMAGE_SIZE:
			errors.append("PHASE_IMAGE_SIZE_INVALID: %s -> %s" % [path, str(img.get_size())])
		else:
			print("  OK IMAGE: " + path)

func _verify_scene(scene_path: String, spec: Dictionary, errors: Array[String]) -> void:
	if not ResourceLoader.exists(scene_path):
		errors.append("SCENE_MISSING: " + scene_path)
		return
	var packed := load(scene_path)
	if not packed is PackedScene:
		errors.append("NOT_PACKED_SCENE: " + scene_path)
		return
	var instance := (packed as PackedScene).instantiate()
	if not instance:
		errors.append("INSTANTIATE_FAILED: " + scene_path)
		return

	if instance.name != spec["root"]:
		errors.append("ROOT_NAME_INVALID: %s -> %s" % [scene_path, instance.name])

	var background := instance.get_node_or_null("Background")
	if not background or not background is Sprite2D:
		errors.append("BACKGROUND_MISSING: " + scene_path)
	elif not background.is_in_group("background"):
		errors.append("BACKGROUND_GROUP_MISSING: " + scene_path)

	for wall_path in spec["air_walls"]:
		if not instance.get_node_or_null(wall_path):
			errors.append("AIR_WALL_MISSING: %s -> %s" % [scene_path, wall_path])

	var npc := instance.get_node_or_null(spec["npc"])
	if not npc:
		errors.append("NPC_MISSING: %s -> %s" % [scene_path, spec["npc"]])
	else:
		_check_point(scene_path, spec, "npc position", npc.position, errors)
		var patrol_points: Array = npc.get("patrol_points")
		for idx in range(patrol_points.size()):
			_check_point(scene_path, spec, "patrol %d" % idx, patrol_points[idx], errors)

	if scene_path == "res://scenes/underground.tscn":
		_verify_underground_ambient(instance, spec, errors)

	instance.free()

func _check_point(scene_path: String, spec: Dictionary, label: String, point: Vector2, errors: Array[String]) -> void:
	var safe_min: Vector2 = spec["safe_min"]
	var safe_max: Vector2 = spec["safe_max"]
	if point.x < safe_min.x or point.x > safe_max.x or point.y < safe_min.y or point.y > safe_max.y:
		errors.append("POINT_OUTSIDE_SAFE_AREA: %s %s -> %s" % [scene_path, label, str(point)])

func _verify_underground_ambient(instance: Node, spec: Dictionary, errors: Array[String]) -> void:
	var ambient := instance.get_node_or_null("UndergroundAmbient")
	if not ambient:
		errors.append("UNDERGROUND_AMBIENT_MISSING")
		return
	if not ambient.get_script():
		errors.append("UNDERGROUND_AMBIENT_SCRIPT_MISSING")
		return

	if ambient.get_child_count() == 0 and ambient.has_method("_build_ambient_nodes"):
		ambient.call("_build_ambient_nodes")

	_check_no_collision_descendants(ambient, "UndergroundAmbient", errors)

	for node_name in UNDERGROUND_AMBIENT_NODES.keys():
		var expected: Dictionary = UNDERGROUND_AMBIENT_NODES[node_name]
		var node := ambient.get_node_or_null(node_name)
		if not node:
			errors.append("UNDERGROUND_AMBIENT_NODE_MISSING: " + node_name)
			continue
		if node.position.distance_to(expected["position"]) > 0.1:
			errors.append("UNDERGROUND_AMBIENT_POSITION_INVALID: %s -> %s" % [node_name, str(node.position)])
		if not expected.get("allow_air_wall", false):
			_check_point("res://scenes/underground.tscn", spec, "ambient " + node_name, node.position, errors)
		var z_range: Vector2i = expected["z_range"]
		if node.z_index < z_range.x or node.z_index > z_range.y:
			errors.append("UNDERGROUND_AMBIENT_Z_INVALID: %s -> %d" % [node_name, node.z_index])
		if node is AnimatedSprite2D:
			_verify_animated_sprite(node_name, node, errors)
		elif node is Sprite2D:
			if not node.texture:
				errors.append("UNDERGROUND_AMBIENT_TEXTURE_MISSING: " + node_name)
		else:
			errors.append("UNDERGROUND_AMBIENT_TYPE_INVALID: %s -> %s" % [node_name, node.get_class()])

func _verify_animated_sprite(node_name: String, node: AnimatedSprite2D, errors: Array[String]) -> void:
	if not node.sprite_frames:
		errors.append("UNDERGROUND_AMBIENT_FRAMES_MISSING: " + node_name)
		return
	if not node.sprite_frames.has_animation("default"):
		errors.append("UNDERGROUND_AMBIENT_ANIMATION_MISSING: " + node_name)
		return
	if node.sprite_frames.get_frame_count("default") != 4:
		errors.append("UNDERGROUND_AMBIENT_FRAME_COUNT_INVALID: %s -> %d" % [node_name, node.sprite_frames.get_frame_count("default")])

func _check_no_collision_descendants(node: Node, label: String, errors: Array[String]) -> void:
	for child in node.get_children():
		var child_label := label + "/" + child.name
		if child is CollisionObject2D or child is CollisionShape2D:
			errors.append("UNDERGROUND_AMBIENT_COLLISION_FORBIDDEN: " + child_label)
		_check_no_collision_descendants(child, child_label, errors)
