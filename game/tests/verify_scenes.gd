extends SceneTree

const SCENE_PATHS := [
	"res://scenes/character_select.tscn",
	"res://scenes/main.tscn",
	"res://scenes/street.tscn",
	"res://scenes/apartment.tscn",
	"res://scenes/underground.tscn",
	"res://scenes/anomaly_space.tscn",
	"res://scenes/rift_projectile.tscn",
	"res://scenes/rift_enemy.tscn",
	"res://scenes/rift_hud.tscn",
	"res://scenes/rift_tile_select.tscn",
	"res://scenes/rift_result_panel.tscn",
	"res://scenes/rift_run.tscn",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []

	print("====== VERIFY SCENE LOADS ======")
	for path in SCENE_PATHS:
		if not ResourceLoader.exists(path):
			errors.append("MISSING: " + path)
			print("  MISSING: " + path)
			continue

		var packed := load(path)
		if not packed is PackedScene:
			errors.append("NOT_PACKED_SCENE: " + path)
			print("  NOT PACKED SCENE: " + path)
			continue

		var instance := (packed as PackedScene).instantiate()
		if not instance:
			errors.append("INSTANTIATE_FAILED: " + path)
			print("  INSTANTIATE FAILED: " + path)
			continue

		instance.free()
		print("  OK: " + path)

	print("\n====== RESULT ======")
	if errors.is_empty():
		print("Scene loads passed: %d/%d" % [SCENE_PATHS.size(), SCENE_PATHS.size()])
		quit(0)
	else:
		for error in errors:
			print(error)
		print("Scene loads passed: %d/%d" % [SCENE_PATHS.size() - errors.size(), SCENE_PATHS.size()])
		quit(1)
