extends CharacterBody2D

@export var speed: float = 200.0

var nearby_npc: Node = null
var is_interacting: bool = false
var _footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.28

var _walk_timer: float = 0.0
const WALK_FRAME_INTERVAL: float = 0.18
var _current_direction: String = "down"
var _current_frame: int = 0

var _tex_down_0: Texture2D
var _tex_down_1: Texture2D
var _tex_up_0: Texture2D
var _tex_up_1: Texture2D
var _tex_left_0: Texture2D
var _tex_left_1: Texture2D
var _tex_right_0: Texture2D
var _tex_right_1: Texture2D
var _tex_down_2: Texture2D
var _tex_up_2: Texture2D
var _tex_left_2: Texture2D
var _tex_right_2: Texture2D
var _tex_idle: Texture2D
var _idle_timer: float = 0.0

var _form_type: String = "form_female"
var _form_scale: Vector2 = Vector2(0.25, 0.25)
var _form_modulate: Color = Color(1, 1, 1, 1)
var _form_shader: ShaderMaterial = null
var _frame_count: int = 2
var _idle_alt_active: bool = false
var _holo_indicator: ColorRect
var _rain_waiting_active: bool = false

@onready var camera: Camera2D = $Camera2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var head_label: Label = $HeadLabel
var _footstep_gen = null
var _day_night_mgr = null

func _ready():
	add_to_group("player")
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	set_process_input(true)

	collision_layer = 1
	collision_mask = 3

	_load_sprites_by_form()

	sprite.scale = _form_scale
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.texture = _tex_idle
	sprite.flip_h = false
	sprite.modulate = _form_modulate

	_holo_indicator = ColorRect.new()
	_holo_indicator.custom_minimum_size = Vector2(12, 6)
	_holo_indicator.color = Color(0, 0.85, 1, 0.6)
	_holo_indicator.position = Vector2(-6, -20)
	_holo_indicator.visible = false
	add_child(_holo_indicator)

	if has_node("/root/FootstepGenerator"):
		_footstep_gen = get_node("/root/FootstepGenerator")
	if has_node("/root/DayNightManager"):
		_day_night_mgr = get_node("/root/DayNightManager")

	_update_head_label()

func _physics_process(delta: float):
	if is_interacting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	velocity = input_direction * speed
	move_and_slide()

	if velocity.length() > 10:
		_idle_timer = 0.0
		if _idle_alt_active:
			_idle_alt_active = false
			if _holo_indicator:
				_holo_indicator.visible = false
			if sprite:
				sprite.modulate = Color(1, 1, 1, 1)
		if _rain_waiting_active:
			_rain_waiting_active = false
			if sprite:
				sprite.scale.y = _form_scale.y
				sprite.modulate = Color(1, 1, 1, 1)

		_footstep_timer -= delta
		if _footstep_timer <= 0:
			if _footstep_gen and is_instance_valid(_footstep_gen):
				_footstep_gen.play_footstep()
			_footstep_timer = FOOTSTEP_INTERVAL

		var new_direction: String
		var abs_vx = abs(velocity.x)
		var abs_vy = abs(velocity.y)
		var threshold = speed * 0.3

		if abs_vx > threshold and abs_vy > threshold:
			if velocity.x > 0 and velocity.y > 0:
				new_direction = "down_right"
			elif velocity.x > 0 and velocity.y < 0:
				new_direction = "up_right"
			elif velocity.x < 0 and velocity.y > 0:
				new_direction = "down_left"
			else:
				new_direction = "up_left"
		elif abs_vx > abs_vy:
			if velocity.x > 0:
				new_direction = "right"
			else:
				new_direction = "left"
		else:
			if velocity.y > 0:
				new_direction = "down"
			else:
				new_direction = "up"

		if new_direction != _current_direction:
			_current_direction = new_direction
			_current_frame = 0
			_walk_timer = 0.0
			_apply_frame()
		else:
			_walk_timer += delta
			if _walk_timer >= WALK_FRAME_INTERVAL:
				_walk_timer -= WALK_FRAME_INTERVAL
				_current_frame = (_current_frame + 1) % _frame_count
				_apply_frame()
	else:
		_footstep_timer = 0.0
		_walk_timer = 0.0
		if _current_frame != 0:
			_current_frame = 0
			_apply_frame()
		_idle_timer += delta
		if _idle_timer >= 10.0 and not _idle_alt_active:
			_idle_alt_active = true
			if _holo_indicator:
				_holo_indicator.visible = true
			if sprite:
				sprite.modulate = Color(0.85, 0.9, 1.0, 1.0)
		if not _idle_alt_active:
			var is_raining = false
			if has_node("/root/WeatherEffects"):
				var we = get_node("/root/WeatherEffects")
				if we.current_weather == WeatherEffects.WeatherType.LIGHT_RAIN or we.current_weather == WeatherEffects.WeatherType.THUNDERSTORM:
					is_raining = true
			if is_raining and not _rain_waiting_active:
				_rain_waiting_active = true
				if sprite:
					var tw = create_tween()
					tw.tween_property(sprite, "scale:y", 0.9, 0.3)
					tw.tween_property(sprite, "modulate", Color(0.7, 0.75, 0.85, 1.0), 0.3)
			elif not is_raining and _rain_waiting_active:
				_rain_waiting_active = false
				if sprite:
					var tw = create_tween()
					tw.tween_property(sprite, "scale:y", _form_scale.y, 0.3)
					tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.3)

func _apply_frame():
	var tex: Texture2D
	var flip: bool = false
	var frame_idx = _current_frame % _frame_count

	match _current_direction:
		"down":
			match frame_idx:
				0: tex = _tex_down_0
				1: tex = _tex_down_1
				2: tex = _tex_down_2 if _frame_count >= 3 else _tex_down_0
		"up":
			match frame_idx:
				0: tex = _tex_up_0
				1: tex = _tex_up_1
				2: tex = _tex_up_2 if _frame_count >= 3 else _tex_up_0
		"left":
			match frame_idx:
				0: tex = _tex_left_0
				1: tex = _tex_left_1
				2: tex = _tex_left_2 if _frame_count >= 3 else _tex_left_0
		"right":
			match frame_idx:
				0: tex = _tex_right_0
				1: tex = _tex_right_1
				2: tex = _tex_right_2 if _frame_count >= 3 else _tex_right_0
		"down_left":
			match frame_idx:
				0: tex = _tex_down_0
				1: tex = _tex_down_1
				2: tex = _tex_down_2 if _frame_count >= 3 else _tex_down_0
			flip = true
		"down_right":
			match frame_idx:
				0: tex = _tex_down_0
				1: tex = _tex_down_1
				2: tex = _tex_down_2 if _frame_count >= 3 else _tex_down_0
		"up_left":
			match frame_idx:
				0: tex = _tex_up_0
				1: tex = _tex_up_1
				2: tex = _tex_up_2 if _frame_count >= 3 else _tex_up_0
			flip = true
		"up_right":
			match frame_idx:
				0: tex = _tex_up_0
				1: tex = _tex_up_1
				2: tex = _tex_up_2 if _frame_count >= 3 else _tex_up_0

	if sprite.texture != tex or sprite.flip_h != flip:
		sprite.texture = tex
		sprite.flip_h = flip

	# 行走时身体上下起伏
	if velocity.length() > 10:
		var bob_offsets = [-3.0, 0.0, 3.0]
		sprite.offset.y = bob_offsets[_current_frame % _frame_count]
	else:
		sprite.offset.y = 0.0

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			if not is_interacting and nearby_npc != null:
				interact_with_npc()
				get_viewport().set_input_as_handled()

func interact_with_npc():
	if nearby_npc == null:
		return

	AudioManager.play_interact()
	print("[Player] 与 " + nearby_npc.npc_name + " 开始对话")

	var dialogue_ui = get_parent().get_node_or_null("DialogueUI")
	if not dialogue_ui:
		dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")

	if dialogue_ui and dialogue_ui.has_method("start_dialogue"):
		print("[Player] 调用 start_dialogue")
		dialogue_ui.start_dialogue(nearby_npc.npc_name)

func set_nearby_npc(npc: Node):
	var old_npc = nearby_npc
	nearby_npc = npc

	var interaction_prompt = get_tree().get_first_node_in_group("interaction_prompt")

	if npc != null:
		print("[Player] 附近进入 NPC: " + npc.npc_name)
		_log_event("👋 靠近了" + npc.display_name)
		if interaction_prompt and interaction_prompt.has_method("show_prompt"):
			interaction_prompt.show_prompt(npc.npc_name)
	else:
		print("[Player] 附近离开 NPC: " + (old_npc.npc_name if old_npc else "null"))
		if old_npc:
			_log_event("🚶 离开了" + old_npc.display_name + "的范围")
		if interaction_prompt and interaction_prompt.has_method("hide_prompt"):
			interaction_prompt.hide_prompt()

func set_interacting(interacting: bool):
	is_interacting = interacting
	if interacting:
		print("[Player] 开始交互，禁用移动")
	else:
		print("[Player] 结束交互，恢复移动")

func _load_sprites_by_form():
	var form_info = {}
	if is_inside_tree() and has_node("/root/CharacterClassManager"):
		var ccm = get_node("/root/CharacterClassManager")
		if ccm.has_method("get_form_info"):
			form_info = ccm.get_form_info()

	_form_type = form_info.get("form_type", "form_female")
	_form_scale = form_info.get("sprite_scale", Vector2(0.25, 0.25))
	_form_modulate = form_info.get("sprite_modulate", Color(1, 1, 1, 1))
	_form_shader = form_info.get("shader", null)

	var prefix = "player_"
	_frame_count = 3

	var base = "res://assets/characters/player/" + prefix
	_tex_down_0 = _safe_load_texture(base + "down_0.png")
	_tex_down_1 = _tex_down_0 if _frame_count < 2 else _safe_load_texture(base + "down_1.png")
	_tex_up_0 = _safe_load_texture(base + "up_0.png")
	_tex_up_1 = _tex_up_0 if _frame_count < 2 else _safe_load_texture(base + "up_1.png")
	_tex_left_0 = _safe_load_texture(base + "left_0.png")
	_tex_left_1 = _tex_left_0 if _frame_count < 2 else _safe_load_texture(base + "left_1.png")
	_tex_right_0 = _safe_load_texture(base + "right_0.png")
	_tex_right_1 = _tex_right_0 if _frame_count < 2 else _safe_load_texture(base + "right_1.png")
	_tex_down_2 = _tex_down_0 if _frame_count < 3 else _safe_load_texture(base + "down_2.png")
	_tex_up_2 = _tex_up_0 if _frame_count < 3 else _safe_load_texture(base + "up_2.png")
	_tex_left_2 = _tex_left_0 if _frame_count < 3 else _safe_load_texture(base + "left_2.png")
	_tex_right_2 = _tex_right_0 if _frame_count < 3 else _safe_load_texture(base + "right_2.png")
	_tex_idle = _tex_down_0

	if _form_shader:
		sprite.material = _form_shader
	else:
		sprite.material = null

	_create_class_particles()

func _safe_load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _create_class_particles():
	if not has_node("/root/CharacterClassManager"):
		return
	var ccm = get_node("/root/CharacterClassManager")
	if not ccm.has_method("get_form_info"):
		return

	var form_info = ccm.get_form_info()
	var effects = form_info.get("extra_effects", null)

	var is_gl_compat = ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus") == "gl_compatibility"

	if effects == "blue_flow_particles":
		var particles = GPUParticles2D.new()
		particles.name = "ClassParticles"
		particles.z_index = 1
		particles.amount = 20
		particles.lifetime = 1.5
		particles.explosiveness = 0.0
		particles.randomness = 0.5
		particles.position = Vector2.ZERO
		particles.process_mode = Node.PROCESS_MODE_INHERIT

		var pm = ParticleProcessMaterial.new()
		pm.direction = Vector3(0, -0.8, 0)
		pm.spread = 60.0
		pm.initial_velocity_min = 8.0
		pm.initial_velocity_max = 20.0
		pm.gravity = Vector3(0, 2.0, 0)
		pm.scale_min = 0.3
		pm.scale_max = 1.0
		pm.color = Color(0.2, 0.7, 1.0, 0.8)
		if not is_gl_compat:
			var gradient = Gradient.new()
			gradient.add_point(0.0, Color(0.2, 0.7, 1.0, 0.0))
			gradient.add_point(0.5, Color(0.3, 0.8, 1.0, 0.8))
			gradient.add_point(1.0, Color(0.2, 0.7, 1.0, 0.0))
			var gt = GradientTexture1D.new()
			gt.gradient = gradient
			gt.width = 256
			pm.color_ramp = gt
		pm.emission_box_extents = Vector3(12, 2, 0)
		particles.process_material = pm

		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for x in range(16):
			for y in range(16):
				var dist = Vector2(x - 8, y - 8).length() / 8.0
				var a = max(0, 1.0 - dist)
				a = pow(a, 1.5)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		particles.texture = ImageTexture.create_from_image(img)
		particles.emitting = true
		add_child(particles)

	elif effects == "purple_orbiting_particles":
		var particles = GPUParticles2D.new()
		particles.name = "ClassParticles"
		particles.z_index = 1
		particles.amount = 25
		particles.lifetime = 2.0
		particles.explosiveness = 0.0
		particles.randomness = 0.6
		particles.position = Vector2.ZERO
		particles.process_mode = Node.PROCESS_MODE_INHERIT

		var pm = ParticleProcessMaterial.new()
		pm.direction = Vector3(0, -0.3, 0)
		pm.spread = 120.0
		pm.initial_velocity_min = 5.0
		pm.initial_velocity_max = 15.0
		pm.gravity = Vector3(0, 1.0, 0)
		pm.scale_min = 0.5
		pm.scale_max = 1.5
		pm.color = Color(0.8, 0.2, 1.0, 0.7)
		if not is_gl_compat:
			var gradient = Gradient.new()
			gradient.add_point(0.0, Color(0.8, 0.2, 1.0, 0.0))
			gradient.add_point(0.5, Color(0.9, 0.4, 1.0, 0.8))
			gradient.add_point(1.0, Color(0.8, 0.2, 1.0, 0.0))
			var gt = GradientTexture1D.new()
			gt.gradient = gradient
			gt.width = 256
			pm.color_ramp = gt
		pm.emission_box_extents = Vector3(14, 14, 0)
		particles.process_material = pm

		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for x in range(16):
			for y in range(16):
				var dist = Vector2(x - 8, y - 8).length() / 8.0
				var a = max(0, 1.0 - dist)
				a = pow(a, 1.5)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		particles.texture = ImageTexture.create_from_image(img)
		particles.emitting = true
		add_child(particles)

func _log_event(message: String):
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)

func _update_head_label():
	if not head_label:
		return
	if has_node("/root/CharacterClassManager"):
		var ccm = get_node("/root/CharacterClassManager")
		if ccm.has_method("get_player_name"):
			head_label.text = ccm.get_player_name()
			return
	head_label.text = "玩家"
