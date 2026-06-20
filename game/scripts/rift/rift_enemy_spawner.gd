extends Node2D

signal wave_changed(wave: int, total_waves: int, enemies_alive: int)
signal node_cleared(kill_count: int, damage_taken: float, combo_best: int)

const ENEMY_SCENE := preload("res://scenes/rift_enemy.tscn")

@export var arena_min: Vector2 = Vector2(260, 150)
@export var arena_max: Vector2 = Vector2(1410, 800)
@export var max_enemies: int = 14

var active_tile: Dictionary = {}
var difficulty: int = 1
var wave: int = 0
var total_waves: int = 3
var running: bool = false
var kill_count: int = 0
var damage_taken: float = 0.0
var combo_best: int = 0
var current_combo: int = 0

var _rng := RandomNumberGenerator.new()
var _spawn_queue: Array = []
var _spawn_timer: float = 0.0
var _base_max_enemies: int = 14
var _warning_active: bool = false
var _active_pacing: Dictionary = {}

func _ready() -> void:
	add_to_group("rift_spawner")
	_rng.randomize()
	_base_max_enemies = max_enemies

func start_node(tile: Dictionary, run_difficulty: int = 1) -> void:
	clear_enemies()
	active_tile = tile.duplicate(true)
	difficulty = run_difficulty
	wave = 0
	total_waves = 3
	running = true
	kill_count = 0
	damage_taken = 0.0
	combo_best = 0
	current_combo = 0
	_spawn_queue.clear()
	_spawn_timer = 0.0
	_warning_active = false
	_apply_environment_limits()
	if active_tile.get("type", "normal") in ["event", "shop"]:
		total_waves = 1
		_apply_noncombat_tile()
	else:
		_begin_next_wave()

func _physics_process(delta: float) -> void:
	if not running:
		return
	if _spawn_queue.size() > 0:
		_spawn_timer -= delta
		if _warning_active:
			wave_changed.emit(wave, total_waves, _alive_count())
			return
		if _alive_count() >= max_enemies:
			_spawn_timer = max(_spawn_timer, 0.45)
			wave_changed.emit(wave, total_waves, _alive_count())
			return
		if _spawn_timer <= 0.0:
			var group: Dictionary = _spawn_queue.pop_front()
			_schedule_spawn_group(group)
		wave_changed.emit(wave, total_waves, _alive_count())
		return
	if _alive_count() == 0:
		if wave >= total_waves:
			running = false
			node_cleared.emit(kill_count, damage_taken, combo_best)
		else:
			_begin_next_wave()

func _apply_noncombat_tile() -> void:
	var player = get_tree().get_first_node_in_group("rift_player")
	if active_tile.get("type", "") == "event":
		if player and player.has_method("heal"):
			player.heal(24.0)
		kill_count = 0
	else:
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.add_item("health_potion", 1)
			gm.add_item("energy_potion", 1)
	await get_tree().create_timer(0.9).timeout
	running = false
	node_cleared.emit(kill_count, damage_taken, combo_best)

func _begin_next_wave() -> void:
	wave += 1
	_spawn_queue = _build_wave_queue(wave)
	_spawn_timer = _rng.randf_range(float(_active_pacing.get("wave_delay_min", 0.85)), float(_active_pacing.get("wave_delay_max", 1.25)))
	wave_changed.emit(wave, total_waves, _alive_count())

func _build_wave_queue(wave_index: int) -> Array:
	var queue: Array = []
	var tile_type: String = str(active_tile.get("type", "normal"))
	var tags: Array = active_tile.get("enemy_tags", ["slime"])
	_active_pacing = _pacing_for_tile(tile_type)
	var count: int = int(_active_pacing.get("base_count", 4)) + int(_active_pacing.get("per_wave", 2)) * wave_index + difficulty
	if tile_type == "elite":
		count += 1
	if tile_type == "boss":
		count = 2 + wave_index + difficulty
	if str(active_tile.get("time_phase", "")) in ["night", "eclipse"]:
		count += 1
	if str(active_tile.get("weather", "")) == "fog_tide":
		count = maxi(2, count - 1)
	var entries: Array = []
	for i in range(count):
		entries.append(_entry_for_enemy(str(tags[_rng.randi_range(0, tags.size() - 1)])))
	if tile_type == "elite" and wave_index >= 2:
		entries.append(_entry_for_enemy(_elite_id_for_tags(tags)))
	if tile_type == "boss" and wave_index == total_waves:
		entries.append(_boss_entry_for_index(int(active_tile.get("index", 2))))
	var group_min: int = int(_active_pacing.get("group_min", 2))
	var group_max: int = int(_active_pacing.get("group_max", 3))
	while not entries.is_empty():
		var group_size: int = clampi(_rng.randi_range(group_min, group_max), 1, entries.size())
		var members: Array = []
		for i in range(group_size):
			members.append(entries.pop_front())
		queue.append({
			"members": members,
			"warning_time": _warning_time_for_environment(float(_active_pacing.get("warning_time", 0.95))),
			"warning_radius": float(_active_pacing.get("warning_radius", 46.0)),
			"interval_after": _group_interval_for_environment(),
		})
	return queue

func _apply_environment_limits() -> void:
	var tile_type: String = str(active_tile.get("type", "normal"))
	match tile_type:
		"elite":
			max_enemies = 14
		"boss":
			max_enemies = 10
		_:
			max_enemies = 12
	match str(active_tile.get("weather", "")):
		"fog_tide":
			max_enemies = maxi(8, max_enemies - 2)
		"thunderstorm":
			max_enemies += 2
		"data_rain":
			max_enemies += 1

func _pacing_for_tile(tile_type: String) -> Dictionary:
	match tile_type:
		"elite":
			return {"base_count": 4, "per_wave": 2, "group_min": 2, "group_max": 3, "warning_time": 1.0, "warning_radius": 52.0, "interval_min": 1.55, "interval_max": 2.15, "wave_delay_min": 1.0, "wave_delay_max": 1.35}
		"boss":
			return {"base_count": 2, "per_wave": 1, "group_min": 1, "group_max": 2, "warning_time": 1.12, "warning_radius": 58.0, "interval_min": 1.8, "interval_max": 2.55, "wave_delay_min": 1.15, "wave_delay_max": 1.55}
		_:
			return {"base_count": 3, "per_wave": 2, "group_min": 2, "group_max": 3, "warning_time": 0.92, "warning_radius": 46.0, "interval_min": 1.45, "interval_max": 2.05, "wave_delay_min": 0.85, "wave_delay_max": 1.2}

func get_active_pacing() -> Dictionary:
	return {
		"max_enemies": max_enemies,
		"pacing": _active_pacing.duplicate(true),
		"queue": _spawn_queue.duplicate(true),
		"warning_active": _warning_active,
	}

func _warning_time_for_environment(base_time: float) -> float:
	var result: float = base_time
	match str(active_tile.get("weather", "")):
		"thunderstorm":
			result *= 0.82
		"fog_tide":
			result *= 0.78
		"rift_snow":
			result *= 1.08
	return clampf(result, 0.68, 1.35)

func _group_interval_for_environment() -> float:
	var interval_min: float = float(_active_pacing.get("interval_min", 1.5))
	var interval_max: float = float(_active_pacing.get("interval_max", 2.1))
	var multiplier: float = 1.0
	match str(active_tile.get("weather", "")):
		"thunderstorm":
			multiplier *= 0.78
		"data_rain":
			multiplier *= 0.9
		"fog_tide":
			multiplier *= 1.08
	match str(active_tile.get("time_phase", "")):
		"night":
			multiplier *= 0.9
		"eclipse":
			multiplier *= 0.86
	return _rng.randf_range(interval_min, interval_max) * multiplier

func _schedule_spawn_group(group: Dictionary) -> void:
	_warning_active = true
	var members: Array = group.get("members", [])
	var warning_time: float = float(group.get("warning_time", 0.9))
	var warning_radius: float = float(group.get("warning_radius", 46.0))
	var spawn_positions: Array[Vector2] = []
	for member in members:
		var pos: Vector2 = _random_spawn_position()
		spawn_positions.append(pos)
		RiftFX.warning(get_tree().current_scene, pos, warning_radius, warning_time, _spawn_warning_color())
	await get_tree().create_timer(warning_time).timeout
	if not running or not is_inside_tree():
		_warning_active = false
		return
	for i in range(members.size()):
		if _alive_count() >= max_enemies:
			break
		var entry: Dictionary = members[i]
		spawn_enemy(entry["id"], spawn_positions[i], entry.get("overrides", {}))
	_spawn_timer = float(group.get("interval_after", 1.6))
	_warning_active = false

func _spawn_warning_color() -> Color:
	match str(active_tile.get("weather", "")):
		"thunderstorm":
			return Color(1.0, 0.82, 0.22, 0.68)
		"rift_snow":
			return Color(0.62, 0.9, 1.0, 0.62)
		"fog_tide":
			return Color(0.88, 0.72, 1.0, 0.56)
		_:
			return Color(0.1, 0.95, 1.0, 0.62)

func _entry_for_enemy(enemy_id: String) -> Dictionary:
	var overrides: Dictionary = {}
	var cooldown_multiplier: float = _attack_cooldown_multiplier(enemy_id)
	if not is_equal_approx(cooldown_multiplier, 1.0):
		overrides["attacks"] = _scaled_attacks_for(enemy_id, cooldown_multiplier)
	var weather: String = str(active_tile.get("weather", ""))
	if weather == "rift_snow":
		overrides["speed"] = _base_speed(enemy_id) * 0.92
	elif weather == "data_rain" and enemy_id in ["cyber_wraith", "automaton"]:
		overrides["speed"] = _base_speed(enemy_id) * 1.08
	return {"id": enemy_id, "overrides": overrides}

func _attack_cooldown_multiplier(enemy_id: String) -> float:
	var multiplier: float = 1.0
	match str(active_tile.get("time_phase", "")):
		"night":
			multiplier *= 0.88
		"eclipse":
			multiplier *= 0.82
	match str(active_tile.get("weather", "")):
		"thunderstorm":
			multiplier *= 0.88
		"data_rain":
			if enemy_id in ["cyber_wraith", "automaton"]:
				multiplier *= 0.90
		"fog_tide":
			if enemy_id in ["ghost", "mirror_witch", "book_spirit"]:
				multiplier *= 0.90
	return clampf(multiplier, 0.68, 1.05)

func _scaled_attacks_for(enemy_id: String, cooldown_multiplier: float) -> Array:
	var manager = get_node_or_null("/root/RiftRunManager")
	if not manager:
		return []
	var defs: Dictionary = manager.get_enemy_definitions()
	var attacks: Array = defs.get(enemy_id, {}).get("attacks", []).duplicate(true)
	for attack in attacks:
		attack["cooldown"] = max(0.35, float(attack.get("cooldown", 1.2)) * cooldown_multiplier)
		attack["windup"] = max(0.10, float(attack.get("windup", 0.35)) * lerpf(1.0, cooldown_multiplier, 0.35))
	return attacks

func _elite_id_for_tags(tags: Array) -> String:
	for candidate in ["mirror_witch", "stone_idol", "cyber_wraith", "book_spirit"]:
		if candidate in tags:
			return candidate
	return ["mirror_witch", "stone_idol", "cyber_wraith", "book_spirit"][_rng.randi_range(0, 3)]

func _boss_entry_for_index(tile_index: int) -> Dictionary:
	var manager = get_node_or_null("/root/RiftRunManager")
	var boss_data: Dictionary = {}
	if manager:
		var boss_list: Array = manager.get_boss_definitions()
		var boss_idx: int = clampi(int(tile_index / 3), 0, boss_list.size() - 1)
		boss_data = boss_list[boss_idx]
	var base_id: String = str(boss_data.get("id", "jiangshi"))
	var cooldown_multiplier: float = _attack_cooldown_multiplier(base_id)
	return {
		"id": base_id,
		"overrides": {
			"name": boss_data.get("name", "缝合首领"),
			"hp": _base_hp(base_id) * float(boss_data.get("hp_multiplier", 4.0)) * (1.0 + difficulty * 0.12),
			"damage_multiplier": float(boss_data.get("damage_multiplier", 1.35)),
			"attacks": _scaled_attacks_for(base_id, cooldown_multiplier),
			"is_boss": true,
			"exp": 80 + difficulty * 20,
		}
	}

func _base_hp(enemy_id: String) -> float:
	var manager = get_node_or_null("/root/RiftRunManager")
	if manager:
		return float(manager.get_enemy_definitions().get(enemy_id, {}).get("hp", 80.0))
	return 80.0

func _base_speed(enemy_id: String) -> float:
	var manager = get_node_or_null("/root/RiftRunManager")
	if manager:
		return float(manager.get_enemy_definitions().get(enemy_id, {}).get("speed", 80.0))
	return 80.0

func spawn_enemy(enemy_id: String, pos: Vector2, overrides: Dictionary = {}) -> Node:
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	enemy.global_position = pos
	enemy.configure(enemy_id, overrides)
	enemy.defeated.connect(_on_enemy_defeated)
	wave_changed.emit(wave, total_waves, _alive_count())
	return enemy

func _on_enemy_defeated(enemy_id: String, exp_value: int) -> void:
	kill_count += 1
	current_combo += 1
	combo_best = maxi(combo_best, current_combo)
	var manager = get_node_or_null("/root/RiftRunManager")
	if manager:
		manager.record_enemy_defeated(enemy_id)
	wave_changed.emit(wave, total_waves, _alive_count())

func record_player_damage(amount: float) -> void:
	damage_taken += amount
	current_combo = 0

func clear_enemies() -> void:
	running = false
	_warning_active = false
	for enemy in get_tree().get_nodes_in_group("rift_enemy"):
		if enemy and is_instance_valid(enemy):
			enemy.queue_free()
	_spawn_queue.clear()

func _alive_count() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("rift_enemy"):
		if enemy and is_instance_valid(enemy):
			count += 1
	return count

func _random_spawn_position() -> Vector2:
	var player = get_tree().get_first_node_in_group("rift_player")
	for i in range(12):
		var pos := Vector2(_rng.randf_range(arena_min.x, arena_max.x), _rng.randf_range(arena_min.y, arena_max.y))
		if not player or pos.distance_to(player.global_position) > 280.0:
			return pos
	return Vector2(_rng.randf_range(arena_min.x, arena_max.x), _rng.randf_range(arena_min.y, arena_max.y))
