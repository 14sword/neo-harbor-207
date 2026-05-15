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
var _pet_name: String = "小狐狸"

func _ready():
	add_to_group("pet")
	_player_ref = get_tree().get_first_node_in_group("player")
	_random_action_timer = randf_range(3.0, 8.0)
	
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").register_persistent(self)

func _physics_process(delta):
	if not _player_ref or not is_instance_valid(_player_ref):
		_player_ref = get_tree().get_first_node_in_group("player")
		if _player_ref:
			global_position = _player_ref.global_position + Vector2(-40, 20)
		return
	
	var to_player = _player_ref.global_position - global_position
	var distance = to_player.length()
	
	if distance > follow_distance:
		var speed = follow_speed if distance < max_distance else catch_up_speed
		var direction = to_player.normalized()
		velocity = direction * speed
		_is_moving = true
		_idle_timer = 0.0
		_idle_behavior = ""
		
		if direction.x < 0:
			animator.flip_h = true
		elif direction.x > 0:
			animator.flip_h = false
	else:
		velocity = Vector2.ZERO
		_is_moving = false
		_idle_timer += delta
		if _idle_timer > 5.0 and _idle_behavior == "":
			_choose_idle_behavior()
		if _idle_behavior == "move_closer" and _player_ref:
			to_player = _player_ref.global_position - global_position
			if to_player.length() > 30.0:
				velocity = to_player.normalized() * 30.0
				_is_moving = true
				if to_player.x < 0:
					animator.flip_h = true
				elif to_player.x > 0:
					animator.flip_h = false
		if _idle_behavior != "":
			_idle_behavior_timer -= delta
			if _idle_behavior_timer <= 0:
				_idle_behavior = ""
	
	move_and_slide()
	_update_animation(delta)

func _choose_idle_behavior():
	var behaviors = ["crouch", "idle", "idle", "move_closer"]
	_idle_behavior = behaviors[randi() % behaviors.size()]
	_idle_behavior_timer = randf_range(3.0, 8.0)
	if _idle_behavior == "crouch":
		if animator.sprite_frames.has_animation("crouch"):
			animator.play("crouch")
	elif _idle_behavior == "idle":
		animator.play("idle")
		if _player_ref:
			var window_pos = Vector2(836, 200)
			if global_position.distance_to(window_pos) < 400:
				if window_pos.x < global_position.x:
					animator.flip_h = true
				else:
					animator.flip_h = false

func _update_animation(delta):
	if _action_locked:
		return
	
	if _is_moving:
		if _current_action != "run":
			_current_action = "run"
			animator.play("run")
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
	var actions = ["crouch", "roll", "jump"]
	var action = actions[randi() % actions.size()]
	if animator.sprite_frames.has_animation(action):
		_current_action = action
		_action_locked = true
		animator.play(action)
		_log_pet_action(action)
		if animator.sprite_frames.get_animation_loop(action):
			await get_tree().create_timer(1.5).timeout
			animator.play("idle")
		else:
			await animator.animation_finished
		_action_locked = false
		_current_action = "idle"
		animator.play("idle")

func play_action(action: String):
	if _action_locked:
		return
	if animator.sprite_frames.has_animation(action):
		_current_action = action
		_action_locked = true
		animator.play(action)
		_log_pet_action(action)
		if animator.sprite_frames.get_animation_loop(action):
			await get_tree().create_timer(1.5).timeout
			animator.play("idle")
		else:
			await animator.animation_finished
		_action_locked = false
		_current_action = "idle"
		animator.play("idle")

func _log_pet_action(action: String):
	var action_names = {
		"idle": "发呆",
		"run": "奔跑",
		"jump": "跳跃",
		"crouch": "蹲下",
		"roll": "翻滚",
		"dizzy": "眩晕",
		"hurt": "受伤",
		"victory": "胜利"
	}
	var display_name = action_names.get(action, action)
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("🐾 " + _pet_name + display_name + "了")

func set_pet_name(new_name: String):
	_pet_name = new_name
