extends CharacterBody2D

signal defeated(enemy_id: String, exp_value: int)

const PROJECTILE_SCENE := preload("res://scenes/rift_projectile.tscn")

var enemy_id: String = "slime"
var display_name: String = "裂隙怪物"
var max_health: float = 40.0
var health: float = 40.0
var move_speed: float = 80.0
var contact_damage: float = 8.0
var exp_value: int = 8
var attacks: Array = []
var drops: Array = []
var damage_multiplier: float = 1.0
var is_boss: bool = false

var _player: Node2D = null
var _attack_timers: Dictionary = {}
var _status_timers: Dictionary = {}
var _dead: bool = false
var _casting: bool = false
var _shield_timer: float = 0.0
var _sprite: Sprite2D
var _health_bar: ProgressBar
var _name_label: Label

func _ready() -> void:
	add_to_group("rift_enemy")
	_sprite = get_node_or_null("Sprite2D")
	_health_bar = get_node_or_null("HealthBar")
	_name_label = get_node_or_null("NameLabel")
	_player = get_tree().get_first_node_in_group("rift_player")
	_apply_definition()
	_update_health_ui()

func configure(new_enemy_id: String, overrides: Dictionary = {}) -> void:
	enemy_id = new_enemy_id
	if is_inside_tree():
		_apply_definition(overrides)

func _apply_definition(overrides: Dictionary = {}) -> void:
	var manager = get_node_or_null("/root/RiftRunManager")
	if not manager:
		return
	var defs: Dictionary = manager.get_enemy_definitions()
	var data: Dictionary = defs.get(enemy_id, defs.get("slime", {})).duplicate(true)
	for key in overrides:
		data[key] = overrides[key]
	display_name = data.get("name", enemy_id)
	max_health = float(data.get("hp", 40.0))
	health = max_health
	move_speed = float(data.get("speed", 80.0))
	contact_damage = float(data.get("contact_damage", 8.0))
	exp_value = int(data.get("exp", 8))
	attacks = data.get("attacks", []).duplicate(true)
	drops = data.get("drops", []).duplicate()
	damage_multiplier = float(data.get("damage_multiplier", 1.0))
	is_boss = bool(data.get("is_boss", false))
	if _sprite:
		_load_sprite(data.get("sprite", ""))
		_sprite.scale = Vector2(0.38, 0.38) if is_boss else Vector2(0.27, 0.27)
	if _name_label:
		_name_label.text = display_name
	for attack in attacks:
		_attack_timers[attack.get("id", attack.get("type", "attack"))] = randf_range(0.2, 1.0)
	_update_health_ui()

func _load_sprite(path: String) -> void:
	if path.is_empty():
		return
	var tex := _load_texture(path)
	if tex:
		_sprite.texture = tex
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(path):
		var image := Image.new()
		var err := image.load(path)
		if err == OK:
			return ImageTexture.create_from_image(image)
	return null

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_tick_timers(delta)
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("rift_player")
		return
	if _casting:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var to_player := _player.global_position - global_position
	var distance := to_player.length()
	var attack := _find_ready_attack(distance)
	if not attack.is_empty():
		_begin_attack(attack, to_player.normalized())
	else:
		var speed_scale := 1.0
		if _status_timers.get("slow", 0.0) > 0.0:
			speed_scale *= 0.48
		if _status_timers.get("stunned", 0.0) > 0.0:
			speed_scale = 0.0
		velocity = to_player.normalized() * move_speed * speed_scale
		move_and_slide()
		if _sprite:
			_sprite.flip_h = velocity.x < -4.0

func _tick_timers(delta: float) -> void:
	for key in _attack_timers:
		_attack_timers[key] = max(0.0, float(_attack_timers[key]) - delta)
	for key in _status_timers.keys():
		_status_timers[key] = max(0.0, float(_status_timers[key]) - delta)
	_shield_timer = max(0.0, _shield_timer - delta)

func _find_ready_attack(distance: float) -> Dictionary:
	var fallback: Dictionary = {}
	for attack in attacks:
		var attack_id: String = str(attack.get("id", attack.get("type", "attack")))
		var attack_range := float(attack.get("range", 80.0))
		if fallback.is_empty() and distance <= attack_range:
			fallback = attack
		if distance <= attack_range and float(_attack_timers.get(attack_id, 0.0)) <= 0.0:
			return attack
	return {}

func _begin_attack(attack: Dictionary, dir: Vector2) -> void:
	_casting = true
	var attack_id: String = str(attack.get("id", attack.get("type", "attack")))
	_attack_timers[attack_id] = float(attack.get("cooldown", 2.0))
	var windup: float = float(attack.get("windup", 0.35))
	var attack_type: String = str(attack.get("type", "melee"))
	var radius: float = _warning_radius_for(attack_type, attack)
	var target_pos: Vector2 = _target_position_for(attack_type, dir, attack)
	RiftFX.warning(get_tree().current_scene, target_pos, radius, max(windup, 0.08), _attack_color())
	await get_tree().create_timer(windup).timeout
	if not is_inside_tree() or _dead:
		return
	_execute_attack(attack, dir, target_pos, radius)
	_casting = false

func _warning_radius_for(attack_type: String, attack: Dictionary) -> float:
	match attack_type:
		"beam": return 48.0
		"ring": return float(attack.get("range", 160.0))
		"slam": return 86.0
		"mine": return 54.0
		"trishot": return 42.0
		_: return max(34.0, min(float(attack.get("range", 80.0)) * 0.45, 92.0))

func _target_position_for(attack_type: String, dir: Vector2, attack: Dictionary) -> Vector2:
	if not _player or not is_instance_valid(_player):
		return global_position
	match attack_type:
		"ring":
			return global_position
		"melee", "lunge", "slam":
			return global_position + dir * min(float(attack.get("range", 70.0)), 82.0)
		"mine":
			return _player.global_position
		_:
			return _player.global_position

func _execute_attack(attack: Dictionary, dir: Vector2, target_pos: Vector2, radius: float) -> void:
	var attack_type: String = str(attack.get("type", "melee"))
	var dmg: float = float(attack.get("damage", contact_damage)) * damage_multiplier
	match attack_type:
		"projectile", "snare", "silence":
			_spawn_projectile(dir, dmg, attack_type)
		"trishot":
			for angle in [-14.0, 0.0, 14.0]:
				_spawn_projectile(dir.rotated(deg_to_rad(angle)), dmg, "projectile")
		"beam":
			_beam_attack(dir, dmg)
		"lunge", "dash":
			global_position += dir * (92.0 if attack_type == "dash" else 48.0)
			_area_damage(global_position, radius, dmg, "")
		"slam", "ring", "melee":
			_area_damage(target_pos, radius, dmg, "")
		"shield":
			_shield_timer = 3.0
			RiftFX.impact(get_tree().current_scene, global_position, 72.0, Color(0.3, 0.85, 1.0, 0.65))
		"teleport":
			_teleport_near_player()
		"summon":
			_summon_mirror()
		"mine":
			_area_damage(target_pos, radius, dmg, "slow")
		_:
			_area_damage(target_pos, radius, dmg, "")

func _attack_color() -> Color:
	if is_boss:
		return Color(1.0, 0.18, 0.16, 0.72)
	match enemy_id:
		"jiangshi", "stone_idol":
			return Color(1.0, 0.72, 0.18, 0.68)
		"mirror_witch", "book_spirit":
			return Color(1.0, 0.34, 0.88, 0.68)
		"ghost", "cyber_wraith":
			return Color(0.55, 0.38, 1.0, 0.68)
		_:
			return Color(0.2, 1.0, 0.72, 0.68)

func _spawn_projectile(dir: Vector2, dmg: float, attack_type: String) -> void:
	var projectile = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + dir * 36.0
	projectile.configure(dir * (315.0 if attack_type != "snare" else 250.0), dmg, _attack_color(), "rift_player", 8.0, 0)
	if attack_type == "snare":
		projectile.status = "stunned"
		projectile.status_duration = 0.65
	elif attack_type == "silence":
		projectile.status = "slow"
		projectile.status_duration = 1.5

func _beam_attack(dir: Vector2, dmg: float) -> void:
	RiftFX.impact(get_tree().current_scene, global_position + dir * 190.0, 190.0, _attack_color())
	if not _player or not is_instance_valid(_player):
		return
	var to_player: Vector2 = _player.global_position - global_position
	var projection: float = to_player.dot(dir)
	var side_distance: float = abs(to_player.cross(dir))
	if projection > 0.0 and projection < 440.0 and side_distance < 42.0:
		_player.take_damage(dmg, global_position)

func _area_damage(pos: Vector2, radius: float, dmg: float, status_name: String) -> void:
	RiftFX.impact(get_tree().current_scene, pos, radius, _attack_color())
	if _player and is_instance_valid(_player) and _player.global_position.distance_to(pos) <= radius:
		_player.take_damage(dmg, global_position)
		if not status_name.is_empty() and _player.has_method("apply_status"):
			_player.apply_status(status_name, 1.5)

func _teleport_near_player() -> void:
	if not _player or not is_instance_valid(_player):
		return
	var angle := randf() * TAU
	global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(120.0, 190.0)
	RiftFX.impact(get_tree().current_scene, global_position, 42.0, _attack_color())

func _summon_mirror() -> void:
	var spawner = get_tree().get_first_node_in_group("rift_spawner")
	if spawner and spawner.has_method("spawn_enemy"):
		spawner.spawn_enemy("book_spirit", global_position + Vector2(randf_range(-90.0, 90.0), randf_range(-90.0, 90.0)), {"hp": 46.0, "exp": 5})

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO) -> void:
	if _dead:
		return
	var actual := amount
	if _shield_timer > 0.0:
		actual *= 0.35
	health = max(0.0, health - actual)
	RiftFX.damage_number(get_tree().current_scene, global_position + Vector2(0, -48), int(actual))
	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate", Color(1.0, 0.3, 0.28, 1.0), 0.06)
		tw.tween_property(_sprite, "modulate", Color(1, 1, 1, 1), 0.12)
	if from_position != Vector2.ZERO and not is_boss:
		global_position += (global_position - from_position).normalized() * 10.0
	_update_health_ui()
	if health <= 0.0:
		_die()

func apply_status(status_name: String, seconds: float) -> void:
	if is_boss and status_name in ["stunned", "slow"]:
		seconds *= 0.45
	_status_timers[status_name] = max(float(_status_timers.get(status_name, 0.0)), seconds)

func _update_health_ui() -> void:
	if _health_bar:
		_health_bar.max_value = max_health
		_health_bar.value = health
		_health_bar.visible = health < max_health or is_boss

func _die() -> void:
	if _dead:
		return
	_dead = true
	if enemy_id == "slime":
		var spawner = get_tree().get_first_node_in_group("rift_spawner")
		if spawner and spawner.has_method("spawn_enemy"):
			for i in range(2):
				spawner.spawn_enemy("slime_split", global_position + Vector2(randf_range(-36.0, 36.0), randf_range(-36.0, 36.0)))
	RiftFX.impact(get_tree().current_scene, global_position, 50.0 if not is_boss else 110.0, Color(1.0, 0.95, 0.55, 0.75))
	defeated.emit(enemy_id, exp_value)
	queue_free()
