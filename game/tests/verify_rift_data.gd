extends SceneTree

const REQUIRED_ENEMY_FIELDS := ["id", "name", "realm", "rank", "hp", "speed", "attacks", "drops"]
const REQUIRED_ATTACK_FIELDS := ["id", "name", "cooldown", "range", "damage", "windup", "type"]
const REQUIRED_EQUIPMENT_FIELDS := ["id", "name", "slot", "rarity", "class", "icon", "affixes"]
const REQUIRED_TILE_FIELDS := ["id", "index", "type", "layer", "layer_name", "realm_id", "realm_name", "time_phase", "weather", "background_path", "enemy_tags", "reward_bias", "locked"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var mgr = root.get_node_or_null("/root/RiftRunManager")
	if not mgr:
		errors.append("RiftRunManager autoload missing")
	else:
		_verify_enemies(mgr, errors)
		_verify_tiles(mgr, errors)
		_verify_equipment(mgr, errors)
	print("====== VERIFY RIFT DATA ======")
	if errors.is_empty():
		print("Rift data passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _verify_enemies(mgr: Node, errors: Array[String]) -> void:
	var enemies: Dictionary = mgr.get_enemy_definitions()
	for enemy_id in enemies:
		var enemy: Dictionary = enemies[enemy_id]
		for field in REQUIRED_ENEMY_FIELDS:
			if not enemy.has(field):
				errors.append("ENEMY_FIELD_MISSING: %s.%s" % [enemy_id, field])
		for attack in enemy.get("attacks", []):
			for field in REQUIRED_ATTACK_FIELDS:
				if not attack.has(field):
					errors.append("ATTACK_FIELD_MISSING: %s.%s" % [enemy_id, field])
		var sprite_path: String = str(enemy.get("sprite", ""))
		if not sprite_path.is_empty() and not _asset_exists(sprite_path):
			errors.append("ENEMY_SPRITE_MISSING: %s -> %s" % [enemy_id, sprite_path])

func _verify_tiles(mgr: Node, errors: Array[String]) -> void:
	var run: Dictionary = mgr.start_run(12345, 1)
	var tiles: Array = run.get("tiles", [])
	if tiles.size() != 9:
		errors.append("TILE_COUNT_INVALID: %d" % tiles.size())
	var layers_seen: Dictionary = {}
	var weather_seen: Dictionary = {}
	var type_seen: Dictionary = {}
	for i in range(tiles.size()):
		var tile: Dictionary = tiles[i]
		for field in REQUIRED_TILE_FIELDS:
			if not tile.has(field):
				errors.append("TILE_FIELD_MISSING: tile_%d.%s" % [i, field])
		layers_seen[int(tile.get("layer", 0))] = true
		weather_seen[str(tile.get("weather", ""))] = true
		type_seen[str(tile.get("type", ""))] = true
		var background_path: String = str(tile.get("background_path", ""))
		if background_path.is_empty() or not _asset_exists(background_path):
			errors.append("TILE_BACKGROUND_MISSING: %s -> %s" % [tile.get("id", "unknown"), background_path])
		if i == 0 and tile.get("locked", true):
			errors.append("FIRST_TILE_LOCKED")
		if i > 0 and not tile.get("locked", false):
			errors.append("NON_FIRST_TILE_UNLOCKED: %d" % i)
	if tiles.size() >= 9:
		for boss_index in [2, 5, 8]:
			if tiles[boss_index].get("type", "") != "boss":
				errors.append("BOSS_TILE_MISSING_AT: %d" % boss_index)
	for layer in [1, 2, 3]:
		if not layers_seen.has(layer):
			errors.append("LAYER_MISSING: %d" % layer)
	for weather in ["data_rain", "rift_snow", "thunderstorm", "fog_tide"]:
		if not weather_seen.has(weather):
			errors.append("WEATHER_MISSING: " + weather)
	if type_seen.keys().size() < 3:
		errors.append("NODE_TYPE_VARIETY_LOW: %s" % [type_seen.keys()])

func _verify_equipment(mgr: Node, errors: Array[String]) -> void:
	var equipment: Dictionary = mgr.get_equipment_definitions()
	for item_id in equipment:
		var item: Dictionary = equipment[item_id]
		for field in REQUIRED_EQUIPMENT_FIELDS:
			if not item.has(field):
				errors.append("EQUIPMENT_FIELD_MISSING: %s.%s" % [item_id, field])
		var slot: String = str(item.get("slot", ""))
		if not (slot in ["weapon_core", "armor", "boots", "relic", "class_mod"]):
			errors.append("EQUIPMENT_SLOT_INVALID: %s.%s" % [item_id, slot])
		var icon_path: String = str(item.get("icon", ""))
		if not icon_path.is_empty() and not _asset_exists(icon_path):
			errors.append("EQUIPMENT_ICON_MISSING: %s -> %s" % [item_id, icon_path])

func _asset_exists(path: String) -> bool:
	if ResourceLoader.exists(path):
		return true
	return FileAccess.file_exists(path)

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
