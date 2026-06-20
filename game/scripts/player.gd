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
var _idle_frames: Array[Texture2D] = []
var _idle_anim_frame: int = 0
var _idle_anim_timer: float = 0.0
var _idle_timer: float = 0.0
const IDLE_ANIM_INTERVAL: float = 0.22
const RAIN_WAIT_SCALE_Y_FACTOR: float = 0.9

var _class_id: String = "player"
var _class_sprite_dir: String = ""
var _class_visual: Dictionary = {}
var _class_accent: Color = Color(0, 0.85, 1, 1)
var _form_type: String = "form_female"
var _form_scale: Vector2 = Vector2(0.25, 0.25)
var _form_modulate: Color = Color(1, 1, 1, 1)
var _form_shader: ShaderMaterial = null
var _frame_count: int = 2
var _was_moving: bool = false
var _idle_alt_active: bool = false
var _holo_indicator: ColorRect
var _rain_waiting_active: bool = false
var _rain_wait_tween: Tween = null

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
	sprite.texture = _get_idle_texture()
	sprite.flip_h = false
	sprite.modulate = _form_modulate

	_holo_indicator = ColorRect.new()
	_holo_indicator.custom_minimum_size = Vector2(12, 6)
	_holo_indicator.color = Color(_class_accent.r, _class_accent.g, _class_accent.b, 0.6)
	_holo_indicator.position = Vector2(-6, -20)
	_holo_indicator.visible = false
	add_child(_holo_indicator)

	if has_node("/root/FootstepGenerator"):
		_footstep_gen = get_node("/root/FootstepGenerator")
	if has_node("/root/DayNightManager"):
		_day_night_mgr = get_node("/root/DayNightManager")

	_connect_class_manager()
	_update_head_label()

func _physics_process(delta: float):
	if is_interacting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = _get_input_direction() * speed
	move_and_slide()

	if velocity.length() > 10:
		_update_moving_state(delta)
	else:
		_update_idle_state(delta)

func _get_input_direction() -> Vector2:
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	return input_direction

func _update_moving_state(delta: float) -> void:
	var started_moving = not _was_moving
	_was_moving = true
	_idle_timer = 0.0
	_idle_anim_timer = 0.0
	_idle_anim_frame = 0
	_clear_idle_overlays()
	_play_footstep_if_due(delta)
	_update_walk_direction_and_frame(delta, started_moving)

func _clear_idle_overlays() -> void:
	if _idle_alt_active:
		_idle_alt_active = false
		if _holo_indicator:
			_holo_indicator.visible = false
		if sprite:
			sprite.modulate = _form_modulate
	if _rain_waiting_active:
		_set_rain_waiting_active(false, false)

func _play_footstep_if_due(delta: float) -> void:
	_footstep_timer -= delta
	if _footstep_timer > 0:
		return
	if _footstep_gen and is_instance_valid(_footstep_gen):
		_footstep_gen.play_footstep()
	_footstep_timer = FOOTSTEP_INTERVAL

func _update_walk_direction_and_frame(delta: float, started_moving: bool) -> void:
	var new_direction = _direction_for_velocity()
	if new_direction != _current_direction or started_moving:
		_current_direction = new_direction
		_current_frame = 0
		_walk_timer = 0.0
		_apply_frame()
		return

	_walk_timer += delta
	if _walk_timer >= WALK_FRAME_INTERVAL:
		_walk_timer -= WALK_FRAME_INTERVAL
		_current_frame = (_current_frame + 1) % _frame_count
		_apply_frame()

func _direction_for_velocity() -> String:
	var abs_vx = abs(velocity.x)
	var abs_vy = abs(velocity.y)
	var threshold = speed * 0.3

	if abs_vx > threshold and abs_vy > threshold:
		if velocity.x > 0 and velocity.y > 0:
			return "down_right"
		if velocity.x > 0 and velocity.y < 0:
			return "up_right"
		if velocity.x < 0 and velocity.y > 0:
			return "down_left"
		return "up_left"

	if abs_vx > abs_vy:
		return "right" if velocity.x > 0 else "left"
	return "down" if velocity.y > 0 else "up"

func _update_idle_state(delta: float) -> void:
	_was_moving = false
	_footstep_timer = 0.0
	_walk_timer = 0.0
	if _current_frame != 0:
		_current_frame = 0

	_idle_timer += delta
	_update_long_idle_state()
	_update_rain_waiting_state()
	_update_idle_animation(delta)

func _update_long_idle_state() -> void:
	if _idle_timer < 10.0 or _idle_alt_active:
		return
	_idle_alt_active = true
	_set_rain_waiting_active(false, false)
	if _holo_indicator:
		_holo_indicator.visible = true
	if sprite:
		sprite.modulate = _tinted_modulate(Color(0.85, 0.9, 1.0, 1.0))

func _update_rain_waiting_state() -> void:
	if _idle_alt_active:
		return
	var should_apply_rain_waiting = _should_apply_rain_waiting_pose()
	if should_apply_rain_waiting and not _rain_waiting_active:
		_set_rain_waiting_active(true)
	elif not should_apply_rain_waiting and _rain_waiting_active:
		_set_rain_waiting_active(false)

func _apply_frame():
	var frame_idx = _current_frame % _frame_count
	var frame_info = _resolve_frame_info(_current_direction, frame_idx)
	var tex: Texture2D = frame_info.get("texture", null)
	var flip: bool = bool(frame_info.get("flip", false))

	if sprite.texture != tex or sprite.flip_h != flip:
		if tex == null:
			tex = _tex_idle if _tex_idle != null else _tex_down_0
		if tex == null:
			return
		sprite.texture = tex
		sprite.flip_h = flip

	# 行走时身体上下起伏
	if velocity.length() > 10:
		var bob_offsets = [-3.0, 0.0, 3.0]
		sprite.offset.y = bob_offsets[_current_frame % _frame_count]
	else:
		sprite.offset.y = 0.0

func _resolve_frame_info(direction: String, frame_idx: int) -> Dictionary:
	var tex: Texture2D
	var flip := false

	match direction:
		"down":
			tex = _texture_from_frames(_tex_down_0, _tex_down_1, _tex_down_2, frame_idx)
		"up":
			tex = _texture_from_frames(_tex_up_0, _tex_up_1, _tex_up_2, frame_idx)
		"left":
			tex = _texture_from_frames(_tex_left_0, _tex_left_1, _tex_left_2, frame_idx)
		"right":
			tex = _texture_from_frames(_tex_right_0, _tex_right_1, _tex_right_2, frame_idx)
		"down_left":
			tex = _texture_from_frames(_tex_down_0, _tex_down_1, _tex_down_2, frame_idx)
			flip = true
		"down_right":
			tex = _texture_from_frames(_tex_down_0, _tex_down_1, _tex_down_2, frame_idx)
		"up_left":
			tex = _texture_from_frames(_tex_up_0, _tex_up_1, _tex_up_2, frame_idx)
			flip = true
		"up_right":
			tex = _texture_from_frames(_tex_up_0, _tex_up_1, _tex_up_2, frame_idx)
		_:
			tex = _texture_from_frames(_tex_down_0, _tex_down_1, _tex_down_2, frame_idx)

	return {"texture": tex, "flip": flip}

func _texture_from_frames(tex0: Texture2D, tex1: Texture2D, tex2: Texture2D, frame_idx: int) -> Texture2D:
	match frame_idx:
		0:
			return tex0
		1:
			return tex1
		2:
			return tex2 if _frame_count >= 3 else tex0
	return tex0

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("toggle_player_form"):
			if not is_interacting:
				_toggle_visual_form()
				get_viewport().set_input_as_handled()
			return
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

	_class_id = form_info.get("id", "player")
	_class_sprite_dir = form_info.get("runtime_sprite_dir", "")
	_class_visual = form_info.get("visual", {})
	_class_accent = _class_visual.get("accent_color", Color(0, 0.85, 1, 1))
	_form_type = form_info.get("form_type", "form_female")
	_form_scale = form_info.get("sprite_scale", Vector2(0.25, 0.25))
	_form_modulate = form_info.get("sprite_modulate", Color(1, 1, 1, 1))
	_form_shader = form_info.get("shader", null)

	_frame_count = 3
	_idle_frames.clear()
	_idle_anim_frame = 0
	_idle_anim_timer = 0.0

	var fallback_base = "res://assets/characters/player/player_"
	var fallback_down_0 = _safe_load_texture(fallback_base + "down_0.png")
	var fallback_up_0 = _safe_load_texture(fallback_base + "up_0.png")
	var fallback_left_0 = _safe_load_texture(fallback_base + "left_0.png")
	var fallback_right_0 = _safe_load_texture(fallback_base + "right_0.png")

	_tex_down_0 = _load_class_or_fallback("down", 0, fallback_down_0)
	_tex_down_1 = _load_class_or_fallback("down", 1, _load_or_fallback(fallback_base + "down_1.png", _tex_down_0))
	_tex_down_2 = _load_class_or_fallback("down", 2, _load_or_fallback(fallback_base + "down_2.png", _tex_down_0))
	_tex_up_0 = _load_class_or_fallback("up", 0, fallback_up_0)
	_tex_up_1 = _load_class_or_fallback("up", 1, _load_or_fallback(fallback_base + "up_1.png", _tex_up_0))
	_tex_up_2 = _load_class_or_fallback("up", 2, _load_or_fallback(fallback_base + "up_2.png", _tex_up_0))
	_tex_left_0 = _load_class_or_fallback("left", 0, fallback_left_0)
	_tex_left_1 = _load_class_or_fallback("left", 1, _load_or_fallback(fallback_base + "left_1.png", _tex_left_0))
	_tex_left_2 = _load_class_or_fallback("left", 2, _load_or_fallback(fallback_base + "left_2.png", _tex_left_0))
	_tex_right_0 = _load_class_or_fallback("right", 0, fallback_right_0)
	_tex_right_1 = _load_class_or_fallback("right", 1, _load_or_fallback(fallback_base + "right_1.png", _tex_right_0))
	_tex_right_2 = _load_class_or_fallback("right", 2, _load_or_fallback(fallback_base + "right_2.png", _tex_right_0))

	for idx in range(5):
		var idle_tex = _load_class_idle(idx)
		if idle_tex:
			_idle_frames.append(idle_tex)

	_tex_idle = _idle_frames[0] if _idle_frames.size() > 0 else _load_or_fallback("res://assets/characters/player/player_idle.png", _tex_down_0)

	_tex_down_0 = _ensure_texture(_tex_down_0, _tex_idle)
	_tex_down_1 = _ensure_texture(_tex_down_1, _tex_down_0)
	_tex_down_2 = _ensure_texture(_tex_down_2, _tex_down_0)
	_tex_up_0 = _ensure_texture(_tex_up_0, _tex_down_0)
	_tex_up_1 = _ensure_texture(_tex_up_1, _tex_up_0)
	_tex_up_2 = _ensure_texture(_tex_up_2, _tex_up_0)
	_tex_left_0 = _ensure_texture(_tex_left_0, _tex_down_0)
	_tex_left_1 = _ensure_texture(_tex_left_1, _tex_left_0)
	_tex_left_2 = _ensure_texture(_tex_left_2, _tex_left_0)
	_tex_right_0 = _ensure_texture(_tex_right_0, _tex_left_0)
	_tex_right_1 = _ensure_texture(_tex_right_1, _tex_right_0)
	_tex_right_2 = _ensure_texture(_tex_right_2, _tex_right_0)

	if _form_shader:
		sprite.material = _form_shader
	else:
		sprite.material = null

	if _holo_indicator:
		_holo_indicator.color = Color(_class_accent.r, _class_accent.g, _class_accent.b, 0.6)
	_create_class_particles()

	if sprite:
		sprite.scale = _form_scale
		sprite.modulate = _form_modulate
		sprite.texture = _get_idle_texture()
		sprite.flip_h = false

func _load_class_or_fallback(direction: String, frame_idx: int, fallback: Texture2D) -> Texture2D:
	if _class_id != "player" and not _class_sprite_dir.is_empty():
		var class_path = _class_sprite_dir + _class_id + "_" + direction + "_" + str(frame_idx) + ".png"
		var class_tex = _safe_load_texture(class_path)
		if class_tex:
			return class_tex
	return fallback

func _load_class_idle(frame_idx: int) -> Texture2D:
	if _class_id == "player" or _class_sprite_dir.is_empty():
		return null
	return _safe_load_texture(_class_sprite_dir + _class_id + "_idle_" + str(frame_idx) + ".png")

func _get_idle_texture() -> Texture2D:
	if _idle_frames.size() > 0:
		return _idle_frames[_idle_anim_frame % _idle_frames.size()]
	return _tex_idle if _tex_idle != null else _tex_down_0

func _update_idle_animation(delta: float) -> void:
	if _idle_frames.size() == 0 or not sprite:
		return
	_idle_anim_timer += delta
	if _idle_anim_timer >= IDLE_ANIM_INTERVAL:
		_idle_anim_timer -= IDLE_ANIM_INTERVAL
		_idle_anim_frame = (_idle_anim_frame + 1) % _idle_frames.size()
	var tex = _get_idle_texture()
	if tex and (sprite.texture != tex or sprite.flip_h):
		sprite.texture = tex
		sprite.flip_h = false
		sprite.offset.y = 0.0

func _should_apply_rain_waiting_pose() -> bool:
	if not has_node("/root/SceneManager") or not has_node("/root/WeatherEffects"):
		return false
	var scene_manager = get_node("/root/SceneManager")
	if not scene_manager.has_method("is_street") or not scene_manager.is_street():
		return false
	var weather_effects = get_node("/root/WeatherEffects")
	if weather_effects.has_method("is_raining"):
		return weather_effects.is_raining()
	return weather_effects.current_weather == WeatherEffects.WeatherType.LIGHT_RAIN or weather_effects.current_weather == WeatherEffects.WeatherType.THUNDERSTORM

func _set_rain_waiting_active(active: bool, animate: bool = true) -> void:
	if active == _rain_waiting_active and _rain_wait_tween == null:
		return
	_rain_waiting_active = active
	if _rain_wait_tween:
		_rain_wait_tween.kill()
		_rain_wait_tween = null
	if not sprite:
		return

	var target_scale_y = _form_scale.y * RAIN_WAIT_SCALE_Y_FACTOR if active else _form_scale.y
	var target_modulate = _tinted_modulate(Color(0.7, 0.75, 0.85, 1.0)) if active else _form_modulate
	if not animate:
		sprite.scale.y = target_scale_y
		sprite.modulate = target_modulate
		return

	var tw = create_tween()
	_rain_wait_tween = tw
	tw.tween_property(sprite, "scale:y", target_scale_y, 0.3)
	tw.parallel().tween_property(sprite, "modulate", target_modulate, 0.3)
	tw.finished.connect(func():
		if _rain_wait_tween == tw:
			_rain_wait_tween = null
	)

func _tinted_modulate(tint: Color) -> Color:
	return Color(
		_form_modulate.r * tint.r,
		_form_modulate.g * tint.g,
		_form_modulate.b * tint.b,
		_form_modulate.a * tint.a
	)

func _connect_class_manager() -> void:
	if not has_node("/root/CharacterClassManager"):
		return
	var ccm = get_node("/root/CharacterClassManager")
	if ccm.has_signal("class_changed") and not ccm.class_changed.is_connected(_on_class_changed):
		ccm.class_changed.connect(_on_class_changed)
	if ccm.has_signal("visual_form_mode_changed") and not ccm.visual_form_mode_changed.is_connected(_on_visual_form_mode_changed):
		ccm.visual_form_mode_changed.connect(_on_visual_form_mode_changed)

func _on_class_changed(_new_class: int) -> void:
	_reload_form_visuals()

func _on_visual_form_mode_changed(_mode: String) -> void:
	_reload_form_visuals()

func _reload_form_visuals() -> void:
	_idle_alt_active = false
	_set_rain_waiting_active(false, false)
	_idle_timer = 0.0
	_idle_anim_timer = 0.0
	_idle_anim_frame = 0
	_load_sprites_by_form()
	if _holo_indicator:
		_holo_indicator.visible = false
	if sprite:
		sprite.scale.y = _form_scale.y
		sprite.modulate = _form_modulate
		if velocity.length() > 10:
			_apply_frame()
		else:
			sprite.texture = _get_idle_texture()
			sprite.flip_h = false
			sprite.offset.y = 0.0
	_update_head_label()

func _toggle_visual_form() -> void:
	if not has_node("/root/CharacterClassManager"):
		return
	var ccm = get_node("/root/CharacterClassManager")
	if not ccm.has_method("toggle_visual_form_mode"):
		return
	var mode = ccm.toggle_visual_form_mode()
	if mode == "default":
		_log_event("已切换为默认形态")
	else:
		var codename = "职业"
		if ccm.has_method("get_class_codename"):
			codename = ccm.get_class_codename()
		_log_event("已切换为职业形态：" + codename)

func _safe_load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path)
	return null

func _load_or_fallback(path: String, fallback: Texture2D) -> Texture2D:
	var tex = _safe_load_texture(path)
	return tex if tex != null else fallback

func _ensure_texture(tex: Texture2D, fallback: Texture2D) -> Texture2D:
	return tex if tex != null else fallback

func _create_class_particles():
	_clear_class_visual_nodes()
	if not has_node("/root/CharacterClassManager"):
		return
	var ccm = get_node("/root/CharacterClassManager")
	if not ccm.has_method("get_form_info"):
		return

	var form_info = ccm.get_form_info()
	var effects = _class_visual.get("particle_profile", form_info.get("extra_effects", null))

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

	elif effects == "metallic_reflection" or effects == "afterimage":
		var particles = GPUParticles2D.new()
		particles.name = "ClassParticles"
		particles.z_index = 1
		particles.amount = 12 if effects == "metallic_reflection" else 10
		particles.lifetime = 0.9 if effects == "metallic_reflection" else 1.2
		particles.explosiveness = 0.0
		particles.randomness = 0.4
		particles.position = Vector2.ZERO
		particles.process_mode = Node.PROCESS_MODE_INHERIT

		var pm = ParticleProcessMaterial.new()
		pm.direction = Vector3(0, -0.4, 0)
		pm.spread = 45.0
		pm.initial_velocity_min = 4.0
		pm.initial_velocity_max = 12.0
		pm.gravity = Vector3(0, 1.0, 0)
		pm.scale_min = 0.25
		pm.scale_max = 0.8
		pm.color = Color(_class_accent.r, _class_accent.g, _class_accent.b, 0.65)
		pm.emission_box_extents = Vector3(12, 4, 0)
		particles.process_material = pm

		var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
		for x in range(12):
			for y in range(12):
				var dist = Vector2(x - 6, y - 6).length() / 6.0
				img.set_pixel(x, y, Color(1, 1, 1, max(0, 1.0 - dist)))
		particles.texture = ImageTexture.create_from_image(img)
		particles.emitting = true
		add_child(particles)

func _clear_class_visual_nodes() -> void:
	for child in get_children():
		if child.name.begins_with("ClassParticles") or child.name.begins_with("ClassVisualLayer"):
			child.queue_free()

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
