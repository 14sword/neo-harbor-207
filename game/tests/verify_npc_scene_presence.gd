extends SceneTree

const EXPECTED_NPCS_BY_SCENE := {
	"res://scenes/main.tscn": [
		"zhang_san",
		"li_si",
		"wang_wu",
	],
	"res://scenes/street.tscn": [
		"chen_xi",
		"zhao_lin",
		"liu_feng",
	],
	"res://scenes/apartment.tscn": [],
	"res://scenes/underground.tscn": [
		"sun_yue",
	],
	"res://scenes/anomaly_space.tscn": [
		"he_zhen",
	],
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var npc_locations: Dictionary = {}

	print("====== VERIFY NPC SCENE PRESENCE ======")
	for scene_path in EXPECTED_NPCS_BY_SCENE.keys():
		var expected: Array = EXPECTED_NPCS_BY_SCENE[scene_path].duplicate()
		expected.sort()

		if not ResourceLoader.exists(scene_path):
			errors.append("SCENE MISSING: " + scene_path)
			print("  MISSING SCENE: " + scene_path)
			continue

		var packed := load(scene_path)
		if not packed is PackedScene:
			errors.append("NOT PACKED SCENE: " + scene_path)
			print("  NOT PACKED SCENE: " + scene_path)
			continue

		var instance := (packed as PackedScene).instantiate()
		if not instance:
			errors.append("INSTANTIATE FAILED: " + scene_path)
			print("  INSTANTIATE FAILED: " + scene_path)
			continue

		var actual := _collect_npc_names(instance)
		instance.free()

		for npc_id in actual:
			if not npc_locations.has(npc_id):
				npc_locations[npc_id] = []
			npc_locations[npc_id].append(scene_path)

		var actual_sorted = actual.duplicate()
		actual_sorted.sort()

		print("  %s -> %s" % [scene_path, ", ".join(actual_sorted)])
		for npc_id in expected:
			if not actual.has(npc_id):
				errors.append("NPC MISSING: %s expected in %s" % [npc_id, scene_path])

		for npc_id in actual:
			if not expected.has(npc_id):
				errors.append("NPC UNAUTHORIZED: %s found in %s" % [npc_id, scene_path])

		for npc_id in _duplicates(actual):
			errors.append("NPC DUPLICATE: %s appears more than once in %s" % [npc_id, scene_path])

	for npc_id in npc_locations.keys():
		var locations: Array = npc_locations[npc_id]
		if locations.size() > 1:
			errors.append("NPC MULTI-SCENE: %s appears in %s" % [npc_id, ", ".join(locations)])

	print("\n====== RESULT ======")
	if errors.is_empty():
		print("NPC scene presence passed: %d scenes" % EXPECTED_NPCS_BY_SCENE.size())
		quit(0)
	else:
		for error in errors:
			print(error)
		print("NPC scene presence failed: %d issue(s)" % errors.size())
		quit(1)

func _collect_npc_names(root: Node) -> Array[String]:
	var names: Array[String] = []
	_collect_npc_names_recursive(root, names)
	return names

func _collect_npc_names_recursive(node: Node, names: Array[String]) -> void:
	if _has_property(node, "npc_name"):
		var npc_id = str(node.get("npc_name")).strip_edges()
		if not npc_id.is_empty() and npc_id != "NPC":
			names.append(npc_id)

	for child in node.get_children():
		if child is Node:
			_collect_npc_names_recursive(child, names)

func _has_property(node: Node, property_name: String) -> bool:
	for property in node.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _duplicates(items: Array[String]) -> Array[String]:
	var seen: Dictionary = {}
	var duplicated: Array[String] = []
	for item in items:
		if seen.has(item):
			if not duplicated.has(item):
				duplicated.append(item)
		else:
			seen[item] = true
	return duplicated
