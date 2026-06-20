extends CharacterBody2D

@export var follow_distance: float = 60.0
@export var follow_speed: float = 150.0
@export var catch_up_speed: float = 250.0
@export var max_distance: float = 150.0

@onready var animator: AnimatedSprite2D = $AnimatedSprite2D

var _random_action_timer: float = 0.0
var _is_moving: bool = false
var _idle_timer: float = 0.0
var _idle_behavior: String = ""
var _idle_behavior_timer: float = 0.0
var _player_ref: Node = null
var _current_action: String = "idle"
var _action_locked: bool = false
var _pet_name: String = "宠物"
var _move_animation: String = "run"
var _idle_behaviors: Array[String] = ["idle", "idle", "move_closer"]
var _random_actions: Array[String] = ["idle"]
var _action_names: Dictionary = {"idle": "发呆"}

func _ready():
	_configure_pet()
	add_to_group("pet")
	_player_ref = get_tree().get_first_node_in_group("player")
	_random_action_timer = randf_range(3.0, 8.0)
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").register_persistent(self)

func _configure_pet() -> void:
	pass

func _physics_process(delta):
	if not _ensure_player_ref():
		return

	var to_player = _player_ref.global_position - global_position
	if to_player.length() > follow_distance:
		_follow_player(to_player)
	else:
		_idle_near_player(delta, to_player)

	move_and_slide()
	_update_animation(delta)

func _ensure_player_ref() -> bool:
	if _player_ref and is_instance_valid(_player_ref):
		return true
	_player_ref = get_tree().get_first_node_in_group("player")
	if _player_ref:
		global_position = _player_ref.global_position + Vector2(-40, 20)
		return true
	return false

func _follow_player(to_player: Vector2) -> void:
	var distance = to_player.length()
	var speed = follow_speed if distance < max_distance else catch_up_speed
	var direction = to_player.normalized()
	velocity = direction * speed
	_is_moving = true
	_idle_timer = 0.0
	_idle_behavior = ""
	_face_direction(direction.x)

func _idle_near_player(delta: float, to_player: Vector2) -> void:
	velocity = Vector2.ZERO
	_is_moving = false
	_idle_timer += delta
	if _idle_timer > 5.0 and _idle_behavior == "":
		_choose_idle_behavior()
	if _idle_behavior == "move_closer" and _player_ref:
		_move_closer_to_player(to_player)
	_update_idle_behavior_timer(delta)

func _move_closer_to_player(to_player: Vector2) -> void:
	if to_player.length() <= 30.0:
		return
	velocity = to_player.normalized() * 30.0
	_is_moving = true
	_face_direction(to_player.x)

func _update_idle_behavior_timer(delta: float) -> void:
	if _idle_behavior == "":
		return
	_idle_behavior_timer -= delta
	if _idle_behavior_timer <= 0:
		_idle_behavior = ""

func _face_direction(x_delta: float) -> void:
	if x_delta < 0:
		animator.flip_h = true
	elif x_delta > 0:
		animator.flip_h = false

func _choose_idle_behavior():
	_idle_behavior = _idle_behaviors[randi() % _idle_behaviors.size()]
	_idle_behavior_timer = randf_range(3.0, 8.0)
	if _idle_behavior == "move_closer":
		return
	if _idle_behavior == "idle":
		_play_idle_near_window()
	else:
		_play_animation_if_available(_idle_behavior)

func _play_idle_near_window() -> void:
	animator.play("idle")
	if not _player_ref:
		return
	var window_pos = Vector2(836, 200)
	if global_position.distance_to(window_pos) < 400:
		_face_direction(window_pos.x - global_position.x)

func _update_animation(delta):
	if _action_locked:
		return
	if _is_moving:
		if _current_action != _move_animation:
			_current_action = _move_animation
			animator.play(_move_animation)
		_random_action_timer = randf_range(3.0, 8.0)
	else:
		_random_action_timer -= delta
		if _random_action_timer <= 0:
			_play_random_action()
			_random_action_timer = randf_range(5.0, 12.0)
		elif _current_action != "idle":
			_current_action = "idle"
			animator.play("idle")

func _play_random_action():
	if _random_actions.is_empty():
		return
	var action = _random_actions[randi() % _random_actions.size()]
	_play_action_locked(action)

func play_action(action: String):
	_play_action_locked(action)

func _play_action_locked(action: String):
	if _action_locked:
		return
	if not _play_animation_if_available(action):
		return
	_current_action = action
	_action_locked = true
	_log_pet_action(action)
	if animator.sprite_frames.get_animation_loop(action):
		await get_tree().create_timer(1.5).timeout
		animator.play("idle")
	else:
		await animator.animation_finished
	_action_locked = false
	_current_action = "idle"
	animator.play("idle")

func _play_animation_if_available(action: String) -> bool:
	if not animator.sprite_frames.has_animation(action):
		return false
	animator.play(action)
	return true

func _log_pet_action(action: String):
	var display_name = _action_names.get(action, action)
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("🐾 " + _pet_name + display_name + "了")

func set_pet_name(new_name: String):
	_pet_name = new_name
