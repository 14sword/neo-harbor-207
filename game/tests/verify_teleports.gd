extends SceneTree

const PLAYABLE_SCENES := [
	"res://scenes/main.tscn",
	"res://scenes/street.tscn",
	"res://scenes/apartment.tscn",
	"res://scenes/underground.tscn",
	"res://scenes/anomaly_space.tscn",
]

const REQUIRED_NODES := {
	"res://scenes/street.tscn": [
		"UndergroundEntrance",
		"UndergroundEntrance/CollisionShape2D",
		"UndergroundEntranceVisual",
	],
	"res://scenes/underground.tscn": [
		"ReturnZone",
		"ReturnZone/CollisionShape2D",
		"ReturnZoneVisual",
		"AnomalyZone",
		"AnomalyZone/CollisionShape2D",
		"AnomalyZoneVisual",
	],
	"res://scenes/anomaly_space.tscn": [
		"ReturnZone",
		"ReturnZone/CollisionShape2D",
		"ReturnZoneVisual",
	],
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []

	print("====== VERIFY TELEPORTS AND MAP PANEL ======")
	for scene_path in PLAYABLE_SCENES:
		_verify_map_panel(scene_path, errors)
	for scene_path in REQUIRED_NODES.keys():
		_verify_required_nodes(scene_path, REQUIRED_NODES[scene_path], errors)
	_verify_special_scene_exports(errors)
	_verify_spawn_rules(errors)

	print("\n====== RESULT ======")
	if errors.is_empty():
		print("Teleport and map checks passed")
		quit(0)
	else:
		for error in errors:
			print(error)
		print("Teleport and map checks failed: %d issue(s)" % errors.size())
		quit(1)

func _instantiate_scene(scene_path: String) -> Node:
	if not ResourceLoader.exists(scene_path):
		return null
	var packed := load(scene_path)
	if not packed is PackedScene:
		return null
	return (packed as PackedScene).instantiate()

func _verify_map_panel(scene_path: String, errors: Array[String]) -> void:
	var instance := _instantiate_scene(scene_path)
	if not instance:
		errors.append("SCENE_INSTANTIATE_FAILED: " + scene_path)
		return
	if not instance.get_node_or_null("MapPanel"):
		errors.append("MAP_PANEL_MISSING: " + scene_path)
	else:
		print("  OK MAP PANEL: " + scene_path)
	instance.free()

func _verify_required_nodes(scene_path: String, paths: Array, errors: Array[String]) -> void:
	var instance := _instantiate_scene(scene_path)
	if not instance:
		errors.append("SCENE_INSTANTIATE_FAILED: " + scene_path)
		return
	for node_path in paths:
		if not instance.get_node_or_null(node_path):
			errors.append("TELEPORT_NODE_MISSING: %s -> %s" % [scene_path, node_path])
		else:
			print("  OK NODE: %s -> %s" % [scene_path, node_path])
	instance.free()

func _verify_special_scene_exports(errors: Array[String]) -> void:
	var underground := _instantiate_scene("res://scenes/underground.tscn")
	if underground:
		if underground.get("return_scene_name") != "STREET":
			errors.append("UNDERGROUND_RETURN_TARGET_INVALID")
		if underground.get("portal_scene_name") != "ANOMALY_SPACE":
			errors.append("UNDERGROUND_PORTAL_TARGET_INVALID")
		underground.free()
	else:
		errors.append("UNDERGROUND_INSTANTIATE_FAILED")

	var anomaly := _instantiate_scene("res://scenes/anomaly_space.tscn")
	if anomaly:
		if anomaly.get("return_scene_name") != "UNDERGROUND":
			errors.append("ANOMALY_RETURN_TARGET_INVALID")
		if anomaly.get("portal_scene_name") != "RIFT_RUN":
			errors.append("ANOMALY_PORTAL_TARGET_INVALID")
		anomaly.free()
	else:
		errors.append("ANOMALY_INSTANTIATE_FAILED")

func _verify_spawn_rules(errors: Array[String]) -> void:
	var script := load("res://scripts/scene_manager.gd")
	var sm := Node.new()
	sm.set_script(script)

	sm.current_scene = sm.GameScene.STREET
	sm.set("_previous_scene", sm.GameScene.UNDERGROUND)
	_expect_spawn(sm, Vector2(520, 760), "street from underground", errors)

	sm.current_scene = sm.GameScene.UNDERGROUND
	sm.set("_previous_scene", sm.GameScene.STREET)
	_expect_spawn(sm, Vector2(836, 700), "underground from street", errors)

	sm.current_scene = sm.GameScene.UNDERGROUND
	sm.set("_previous_scene", sm.GameScene.ANOMALY_SPACE)
	_expect_spawn(sm, Vector2(836, 520), "underground from anomaly", errors)

	sm.current_scene = sm.GameScene.ANOMALY_SPACE
	sm.set("_previous_scene", sm.GameScene.UNDERGROUND)
	_expect_spawn(sm, Vector2(836, 700), "anomaly from underground", errors)

	sm.free()

func _expect_spawn(sm: Node, expected: Vector2, label: String, errors: Array[String]) -> void:
	var actual: Vector2 = sm.get_spawn_position()
	if actual.distance_to(expected) > 0.1:
		errors.append("SPAWN_INVALID: %s expected %s got %s" % [label, str(expected), str(actual)])
	else:
		print("  OK SPAWN: %s -> %s" % [label, str(actual)])
