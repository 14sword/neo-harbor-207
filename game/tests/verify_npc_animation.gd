extends SceneTree

const NPC_IDS := [
	"zhang_san",
	"li_si",
	"wang_wu",
	"sun_yue",
	"he_zhen",
	"chen_xi",
	"zhao_lin",
	"liu_feng",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var npc_scene := load("res://scenes/npc.tscn") as PackedScene
	if npc_scene == null:
		print("FAILED: Could not load NPC scene")
		quit(1)
		return

	print("====== VERIFY NPC ANIMATION ======")
	for npc_id in NPC_IDS:
		var npc = npc_scene.instantiate()
		npc.npc_name = npc_id
		npc.wander_enabled = false
		root.add_child(npc)
		await process_frame

		var idle_start: Texture2D = npc.sprite.texture
		npc._update_sprite_idle(0.25)
		var idle_next: Texture2D = npc.sprite.texture
		if npc._idle_frames.size() > 1 and idle_start == idle_next:
			errors.append("%s idle frame did not advance" % npc_id)

		npc.velocity = Vector2(60, 0)
		npc._update_sprite_walking(0.2)
		var walk_start: Texture2D = npc.sprite.texture
		npc._update_sprite_walking(0.2)
		var walk_next: Texture2D = npc.sprite.texture
		if walk_start == walk_next:
			errors.append("%s walk frame did not advance" % npc_id)

		npc.free()
		print("  OK: %s" % npc_id)

	print("\n====== RESULT ======")
	if errors.is_empty():
		print("NPC animation passed: %d/%d" % [NPC_IDS.size(), NPC_IDS.size()])
		quit(0)
	else:
		for error in errors:
			print(error)
		print("NPC animation failed: %d/%d" % [errors.size(), NPC_IDS.size()])
		quit(1)
