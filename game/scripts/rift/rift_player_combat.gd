extends CharacterBody2D

signal stats_changed(health: float, max_health: float, energy: float, max_energy: float)
signal skill_cooldown_changed(cooldown_left: float, cooldown_total: float)
signal took_damage(amount: float)
signal died()

const PROJECTILE_SCENE := preload("res://scenes/rift_projectile.tscn")
const CLASS_SPRITE_ROOT: String = "res://assets/characters/player/classes/"
const DEFAULT_SPRITE_ROOT: String = "res://assets/characters/player/"
const WALK_ANIM_INTERVAL: float = 0.12
const IDLE_ANIM_INTERVAL: float = 0.18

@export var speed: float = 245.0

var health: float = 100.0
var max_health: float = 100.0
var energy: float = 100.0
var max_energy: float = 100.0
var class_id: String = "cipher"
var attack_damage: float = 18.0
var skill_damage: float = 40.0

var _attack_cd: float = 0.0
var _skill_cd: float = 0.0
var _skill_cd_total: float = 5.0
var _dodge_cd: float = 0.0
var _invuln_timer: float = 0.0
var _status_timers: Dictionary = {}
var _facing: Vector2 = Vector2.RIGHT
var _sprite: Sprite2D
var _form_scale: Vector2 = Vector2(0.25, 0.25)
var _form_modulate: Color = Color(1, 1, 1, 1)
var _visual_id: String = "player"
var _visual_sprite_dir: String = ""
var _walk_frames: Dictionary = {}
var _idle_frames: Array[Texture2D] = []
var _walk_anim_timer: float = 0.0
var _idle_anim_timer: float = 0.0
var _walk_frame_index: int = 0
var _idle_frame_index: int = 0
var _current_direction: String = "down"
var _attack_chain_step: int = 0
var _attack_chain_timer: float = 0.0

func _ready() -> void:
	add_to_group("rift_player")
	_ensure_input_actions()
	_sprite = get_node_or_null("Sprite2D")
	_connect_class_manager()
	_load_player_visuals()
	_apply_class_stats()
	stats_changed.emit(health, max_health, energy, max_energy)

func _ensure_input_actions() -> void:
	_add_key_action("rift_attack", KEY_J)
	_add_mouse_action("rift_attack", MOUSE_BUTTON_LEFT)
	_add_key_action("rift_skill", KEY_K)
	_add_mouse_action("rift_skill", MOUSE_BUTTON_RIGHT)
	_add_key_action("rift_dodge", KEY_SPACE)
	_add_key_action("rift_use_item", KEY_R)

func _add_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			return
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action_name, ev)

func _add_mouse_action(action_name: String, button_index: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			return
	var ev := InputEventMouseButton.new()
	ev.button_index = button_index
	InputMap.action_add_event(action_name, ev)

func _connect_class_manager() -> void:
	var ccm = get_node_or_null("/root/CharacterClassManager")
	if not ccm:
		return
	if ccm.has_signal("class_changed") and not ccm.class_changed.is_connected(_on_class_changed):
		ccm.class_changed.connect(_on_class_changed)
	if ccm.has_signal("visual_form_mode_changed") and not ccm.visual_form_mode_changed.is_connected(_on_visual_form_mode_changed):
		ccm.visual_form_mode_changed.connect(_on_visual_form_mode_changed)

func _load_player_visuals() -> void:
	if not _sprite:
		return
	var form_info: Dictionary = {}
	var ccm = get_node_or_null("/root/CharacterClassManager")
	if ccm and ccm.has_method("get_form_info"):
		form_info = ccm.get_form_info()
	_visual_id = str(form_info.get("id", "player"))
	_visual_sprite_dir = str(form_info.get("runtime_sprite_dir", ""))
	_form_scale = form_info.get("sprite_scale", Vector2(0.25, 0.25))
	_form_modulate = form_info.get("sprite_modulate", Color(1, 1, 1, 1))
	_walk_frames.clear()
	_idle_frames.clear()
	for direction in ["down", "up", "left", "right"]:
		_walk_frames[direction] = _load_walk_frames(direction)
	if _visual_id != "player" and not _visual_sprite_dir.is_empty():
		for frame_idx in range(5):
			var idle_tex: Texture2D = _safe_load_texture("%s%s_idle_%d.png" % [_visual_sprite_dir, _visual_id, frame_idx])
			if idle_tex:
				_idle_frames.append(idle_tex)
	var fallback_idle: Texture2D = _safe_load_texture(DEFAULT_SPRITE_ROOT + "player_idle.png")
	if _idle_frames.is_empty() and fallback_idle:
		_idle_frames.append(fallback_idle)
	_sprite.scale = _form_scale
	_sprite.modulate = _form_modulate
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_apply_visual_frame(Vector2.ZERO)

func _load_walk_frames(direction: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for frame_idx in range(3):
		var tex: Texture2D = null
		if _visual_id != "player" and not _visual_sprite_dir.is_empty():
			tex = _safe_load_texture("%s%s_%s_%d.png" % [_visual_sprite_dir, _visual_id, direction, frame_idx])
		if not tex:
			tex = _safe_load_texture("%splayer_%s_%d.png" % [DEFAULT_SPRITE_ROOT, direction, frame_idx])
		if tex:
			frames.append(tex)
	return frames

func _safe_load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(path):
		var image := Image.new()
		var err: Error = image.load(path)
		if err == OK:
			return ImageTexture.create_from_image(image)
	return null

func _apply_class_stats() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var ccm = get_node_or_null("/root/CharacterClassManager")
	var equipment_bonuses: Dictionary = {}
	_skill_cd_total = 4.5
	if ccm and ccm.has_method("get_class_id"):
		class_id = ccm.get_class_id()
	if gm:
		if gm.has_method("get_equipment_bonuses"):
			equipment_bonuses = gm.get_equipment_bonuses()
		max_health = float(gm.get_effective_stat("max_health")) if gm.has_method("get_effective_stat") else float(gm.player_stats.get("max_health", 100.0))
		health = min(float(gm.player_stats.get("health", max_health)), max_health)
		max_energy = float(gm.player_stats.get("max_energy", 100.0))
		energy = min(float(gm.player_stats.get("energy", max_energy)), max_energy)
		var int_stat := float(gm.get_effective_stat("int")) if gm.has_method("get_effective_stat") else float(gm.player_stats.get("int", 10))
		var per_stat := float(gm.get_effective_stat("per")) if gm.has_method("get_effective_stat") else float(gm.player_stats.get("per", 10))
		var agi_stat := float(gm.get_effective_stat("agi")) if gm.has_method("get_effective_stat") else float(gm.player_stats.get("agi", 10))
		attack_damage = 12.0 + int_stat * 0.55 + agi_stat * 0.35
		skill_damage = 28.0 + int_stat * 0.8 + per_stat * 0.65
		attack_damage += float(equipment_bonuses.get("attack", 0.0))
	match class_id:
		"chrome":
			speed = 220.0
			attack_damage += 10.0
			skill_damage += 8.0
		"echo":
			speed = 230.0
			_skill_cd_total = 4.8
		"shadow":
			speed = 275.0
			attack_damage += 5.0
			_skill_cd_total = 4.2
		_:
			speed = 245.0
			_skill_cd_total = 4.5
	speed += float(equipment_bonuses.get("speed", 0.0)) * 18.0
	_skill_cd_total = max(1.0, _skill_cd_total + float(equipment_bonuses.get("skill_cd", 0.0)))

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if _status_timers.get("stunned", 0.0) > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_direction.length() > 0.05:
		_facing = input_direction.normalized()
	var move_speed := speed
	if _status_timers.get("haste", 0.0) > 0.0:
		move_speed *= 1.35
	if _status_timers.get("slow", 0.0) > 0.0:
		move_speed *= 0.55
	velocity = input_direction * move_speed
	move_and_slide()

	if _sprite:
		_apply_visual_frame(input_direction)
		_sprite.modulate = _stealth_modulate() if _status_timers.get("stealth", 0.0) > 0.0 else _form_modulate

	_regen_energy(delta)
	_handle_actions()

func _tick_timers(delta: float) -> void:
	_attack_cd = max(0.0, _attack_cd - delta)
	_skill_cd = max(0.0, _skill_cd - delta)
	_dodge_cd = max(0.0, _dodge_cd - delta)
	_invuln_timer = max(0.0, _invuln_timer - delta)
	_attack_chain_timer = max(0.0, _attack_chain_timer - delta)
	if _attack_chain_timer <= 0.0:
		_attack_chain_step = 0
	for key in _status_timers.keys():
		_status_timers[key] = max(0.0, float(_status_timers[key]) - delta)
	skill_cooldown_changed.emit(_skill_cd, _skill_cd_total)

func _apply_visual_frame(input_direction: Vector2) -> void:
	if input_direction.length() > 0.05:
		_current_direction = _direction_for_vector(input_direction)
		_walk_anim_timer += get_physics_process_delta_time()
		if _walk_anim_timer >= WALK_ANIM_INTERVAL:
			_walk_anim_timer -= WALK_ANIM_INTERVAL
			_walk_frame_index = (_walk_frame_index + 1) % 3
		var frames: Array = _walk_frames.get(_current_direction, [])
		if not frames.is_empty():
			_sprite.texture = frames[_walk_frame_index % frames.size()]
		_sprite.flip_h = false
	else:
		_idle_anim_timer += get_physics_process_delta_time()
		if _idle_anim_timer >= IDLE_ANIM_INTERVAL:
			_idle_anim_timer -= IDLE_ANIM_INTERVAL
			_idle_frame_index = (_idle_frame_index + 1) % maxi(1, _idle_frames.size())
		if not _idle_frames.is_empty():
			_sprite.texture = _idle_frames[_idle_frame_index % _idle_frames.size()]
		_sprite.flip_h = _facing.x < -0.05 and _visual_id == "player"

func _direction_for_vector(dir: Vector2) -> String:
	if absf(dir.x) > absf(dir.y):
		return "right" if dir.x > 0.0 else "left"
	return "down" if dir.y > 0.0 else "up"

func _stealth_modulate() -> Color:
	return Color(_form_modulate.r * 0.55, _form_modulate.g * 0.75, _form_modulate.b * 1.0, _form_modulate.a * 0.56)

func _regen_energy(delta: float) -> void:
	energy = min(max_energy, energy + 8.0 * delta)
	stats_changed.emit(health, max_health, energy, max_energy)

func _handle_actions() -> void:
	if Input.is_action_just_pressed("rift_dodge"):
		_dodge()
	if Input.is_action_pressed("rift_attack"):
		_attack()
	if Input.is_action_just_pressed("rift_skill"):
		_use_skill()
	if Input.is_action_just_pressed("rift_use_item"):
		_use_potion()

func _aim_direction() -> Vector2:
	var mouse_dir := get_global_mouse_position() - global_position
	if mouse_dir.length() > 8.0:
		return mouse_dir.normalized()
	return _facing.normalized()

func _attack() -> void:
	if _attack_cd > 0.0:
		return
	_attack_chain_step = (_attack_chain_step % 3) + 1
	_attack_chain_timer = 0.9
	var aim: Vector2 = _aim_direction()
	match class_id:
		"chrome":
			var is_finisher: bool = _attack_chain_step == 3
			_attack_cd = 0.56 if is_finisher else 0.34
			var radius: float = 118.0 if is_finisher else 82.0 + _attack_chain_step * 7.0
			var damage_scale: float = 1.45 if is_finisher else 0.92 + _attack_chain_step * 0.12
			_melee_arc(attack_damage * damage_scale, radius, 0.18 if is_finisher else 0.09, Color(1.0, 0.55, 0.25, 0.9))
		"shadow":
			_attack_cd = 0.24
			var stealth_bonus: bool = _status_timers.get("stealth", 0.0) > 0.0
			var damage_scale: float = 1.85 if stealth_bonus else 0.78
			_spawn_projectile(aim, attack_damage * damage_scale, 640.0, Color(0.45, 0.25, 1.0, 1.0), 0)
			if stealth_bonus:
				_status_timers["stealth"] = 0.0
				RiftFX.impact(get_tree().current_scene, global_position + aim * 34.0, 36.0, Color(0.7, 0.35, 1.0, 0.7))
		"echo":
			_attack_cd = 0.48
			_spawn_projectile(aim, attack_damage * 0.92, 430.0, Color(0.85, 0.45, 1.0, 1.0), 1, "slow", 0.65)
		_:
			_attack_cd = 0.34
			var pierce: int = 3 if _attack_chain_step == 3 else 1
			var damage_scale: float = 1.14 if _attack_chain_step == 3 else 0.96
			_spawn_projectile(aim, attack_damage * damage_scale, 590.0, Color(0.0, 0.92, 1.0, 1.0), pierce)
	_play_attack_feedback(aim)

func _use_skill() -> void:
	if _skill_cd > 0.0 or energy < 28.0:
		return
	energy -= 28.0
	_skill_cd = _skill_cd_total
	match class_id:
		"chrome":
			_invuln_timer = 1.0
			_melee_arc(skill_damage * 1.25, 124.0, 0.22, Color(1.0, 0.78, 0.25, 0.95))
			RiftFX.impact(get_tree().current_scene, global_position, 92.0, Color(1.0, 0.65, 0.2, 0.75))
		"echo":
			_area_burst(skill_damage * 0.9, 150.0, Color(0.75, 0.3, 1.0, 0.85), "slow", 2.2)
		"shadow":
			_status_timers["stealth"] = 1.8
			_status_timers["haste"] = 1.8
			_spawn_projectile(_aim_direction(), skill_damage * 1.3, 700.0, Color(0.7, 0.35, 1.0, 1.0), 3)
		_:
			_chain_shot()
	stats_changed.emit(health, max_health, energy, max_energy)

func _dodge() -> void:
	if _dodge_cd > 0.0 or energy < 12.0:
		return
	energy -= 12.0
	_dodge_cd = 0.8
	_invuln_timer = 0.32
	var dir := _aim_direction()
	if velocity.length() > 10.0:
		dir = velocity.normalized()
	global_position += dir * 82.0
	RiftFX.impact(get_tree().current_scene, global_position, 34.0, Color(0.0, 0.95, 1.0, 0.5))
	stats_changed.emit(health, max_health, energy, max_energy)

func _use_potion() -> void:
	if health >= max_health:
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("has_item") and gm.has_item("health_potion"):
		gm.remove_item("health_potion", 1)
		heal(32.0)
	else:
		heal(18.0)

func _spawn_projectile(dir: Vector2, dmg: float, projectile_speed: float, projectile_color: Color, pierce: int = 0, status_name: String = "", status_time: float = 0.0) -> Node:
	var projectile = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + dir * 34.0
	projectile.configure(dir * projectile_speed, dmg, projectile_color, "rift_enemy", 7.0, pierce)
	if not status_name.is_empty():
		projectile.status = status_name
		projectile.status_duration = status_time
	return projectile

func _chain_shot() -> void:
	var base_dir := _aim_direction()
	for i in range(3):
		var dir := base_dir.rotated(deg_to_rad((i - 1) * 10.0))
		_spawn_projectile(dir, skill_damage * 0.55, 580.0, Color(0.0, 1.0, 0.8, 1.0), 3)
	_play_attack_feedback(base_dir)

func _melee_arc(dmg: float, radius: float, delay: float, arc_color: Color) -> void:
	var center := global_position + _aim_direction() * (radius * 0.55)
	RiftFX.warning(get_tree().current_scene, center, radius, delay, arc_color)
	await get_tree().create_timer(delay).timeout
	RiftFX.impact(get_tree().current_scene, center, radius, arc_color)
	for enemy in get_tree().get_nodes_in_group("rift_enemy"):
		if enemy and is_instance_valid(enemy) and enemy.global_position.distance_to(center) <= radius:
			var final_damage := dmg
			if class_id == "shadow" and _status_timers.get("stealth", 0.0) > 0.0:
				final_damage *= 1.8
				_status_timers["stealth"] = 0.0
			enemy.take_damage(final_damage, global_position)

func _area_burst(dmg: float, radius: float, burst_color: Color, status_name: String = "", status_time: float = 0.0) -> void:
	RiftFX.warning(get_tree().current_scene, global_position, radius, 0.35, burst_color)
	await get_tree().create_timer(0.35).timeout
	RiftFX.impact(get_tree().current_scene, global_position, radius, burst_color)
	for enemy in get_tree().get_nodes_in_group("rift_enemy"):
		if enemy and is_instance_valid(enemy) and enemy.global_position.distance_to(global_position) <= radius:
			enemy.take_damage(dmg, global_position)
			if not status_name.is_empty() and enemy.has_method("apply_status"):
				enemy.apply_status(status_name, status_time)

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO) -> void:
	if _invuln_timer > 0.0 or _status_timers.get("stealth", 0.0) > 0.0:
		return
	health = max(0.0, health - amount)
	took_damage.emit(amount)
	RiftFX.damage_number(get_tree().current_scene, global_position + Vector2(0, -48), int(amount), Color(1.0, 0.35, 0.3, 1.0))
	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate", Color(1.0, 0.35, 0.35, 1.0), 0.06)
		tw.tween_property(_sprite, "modulate", Color(1, 1, 1, 1), 0.12)
	if from_position != Vector2.ZERO:
		var knock := (global_position - from_position).normalized()
		global_position += knock * 14.0
	stats_changed.emit(health, max_health, energy, max_energy)
	if health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	RiftFX.damage_number(get_tree().current_scene, global_position + Vector2(0, -52), int(amount), Color(0.3, 1.0, 0.55, 1.0))
	stats_changed.emit(health, max_health, energy, max_energy)

func apply_status(status_name: String, seconds: float) -> void:
	_status_timers[status_name] = max(float(_status_timers.get(status_name, 0.0)), seconds)

func _play_attack_feedback(dir: Vector2) -> void:
	if not _sprite:
		return
	var original_scale: Vector2 = _form_scale
	var tw := create_tween()
	tw.tween_property(_sprite, "scale", original_scale * Vector2(1.08, 0.94), 0.045)
	tw.tween_property(_sprite, "scale", original_scale, 0.085)
	global_position += dir * (4.0 if class_id != "chrome" else 7.0)

func _on_class_changed(_new_class: int) -> void:
	_apply_class_stats()
	_load_player_visuals()

func _on_visual_form_changed(_mode: String) -> void:
	_load_player_visuals()

func _on_visual_form_mode_changed(_mode: String) -> void:
	_load_player_visuals()
