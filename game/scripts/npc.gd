extends CharacterBody2D

enum State { WORKING, WANDERING, RETURNING, RESTING, SHELTERING }

@export var npc_name: String = "NPC"
@export var npc_title: String = "角色"
@export var move_speed: float = 50.0
@export var wander_enabled: bool = true
@export var wander_range: float = 150.0
@export var work_duration_min: float = 5.0
@export var work_duration_max: float = 10.0
@export var wander_duration_min: float = 10.0
@export var wander_duration_max: float = 20.0
@export var patrol_points: Array[Vector2] = []

const NPC_DISPLAY_NAMES = {
	"zhang_san": "张三",
	"li_si": "李四",
	"wang_wu": "王五",
	"chen_xi": "陈曦",
	"zhao_lin": "赵霖",
	"sun_yue": "孙悦",
	"liu_feng": "刘风",
	"he_zhen": "何真",
}

const RUNTIME_SPRITE_BASE = "res://assets/characters/npcs/runtime/"
const SPRITE_SCALE = Vector2(0.25, 0.25)

var current_dialogue: String = ""
var player: Node = null
var wander_target: Vector2 = Vector2.ZERO
var state_timer: float = 0.0
var is_wandering: bool = false
var is_interacting: bool = false
var spawn_position: Vector2 = Vector2.ZERO
var work_position: Vector2 = Vector2.ZERO
var current_state: State = State.WORKING
var bubble_timer: SceneTreeTimer = null
var _patrol_index: int = 0

var _directional_frames: Dictionary = {}
var _idle_frames: Array[Texture2D] = []
var _current_direction: String = "down"
var _walk_frame: int = 0
var _walk_timer: float = 0.0
var _walk_frame_interval: float = 0.18
var _idle_frame: int = 0
var _idle_timer: float = 0.0
var _idle_frame_interval: float = 0.24
var _was_moving_last_frame: bool = false
var _last_texture: Texture2D = null
var _last_flip_h: bool = false
var _rest_position: Vector2 = Vector2.ZERO
var _shelter_position: Vector2 = Vector2.ZERO
var _current_day_phase: int = 0
var _resting_bubble_timer: float = 0.0

var _night_only_npc: bool = false
var _night_glow_light: PointLight2D = null
var _glitch_mutation_active: bool = false
var _glitch_shader: ShaderMaterial = null
var _glitch_timer: float = 0.0
var _next_glitch_change: float = 3.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var name_label: Label = $NameLabel
@onready var dialogue_label: Label = $DialogueLabel
@onready var dialogue_bubble: Panel = $DialogueBubble
@onready var bubble_label: Label = $DialogueBubble/BubbleLabel

var display_name: String = ""

func _ready():
	add_to_group("npcs")

	collision_layer = 2
	collision_mask = 1

	display_name = NPC_DISPLAY_NAMES.get(npc_name, npc_name)

	name_label.text = display_name
	name_label.visible = true

	dialogue_bubble.visible = false
	dialogue_label.visible = false
	dialogue_label.text = ""
	bubble_label.text = ""

	_load_directional_frames()

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

	work_position = global_position
	spawn_position = global_position

	if wander_enabled:
		current_state = State.WORKING
		state_timer = randf_range(work_duration_min, work_duration_max)
		_log_event("💼 " + display_name + "开始工作")

	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_day_night_changed)
		get_node("/root/DayNightManager").hour_changed.connect(_on_hour_changed)
	_on_apply_bubble_style()

	_setup_night_only_npc()
	_setup_glitch_mutation()

	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		_current_day_phase = dnm.current_phase
		if patrol_points.size() > 0:
			_rest_position = patrol_points[min(1, patrol_points.size() - 1)]
			_shelter_position = patrol_points[0]
		else:
			_rest_position = work_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
			_shelter_position = work_position

func _load_directional_frames():
	var base_path = "res://assets/characters/npcs/"
	var char_id = npc_name
	var directions = ["down", "up", "left", "right"]
	var loaded_count = 0
	_idle_frames.clear()

	for dir_name in directions:
		_directional_frames[dir_name] = []
		for frame_idx in range(3):
			var path = RUNTIME_SPRITE_BASE + char_id + "/" + char_id + "_" + dir_name + "_" + str(frame_idx) + ".png"
			var tex = _load_texture_if_exists(path)
			if tex == null:
				path = base_path + char_id + "_" + dir_name + "_" + str(frame_idx) + ".png"
				tex = _load_texture_if_exists(path)
			if tex:
				_directional_frames[dir_name].append(tex)
				loaded_count += 1

		if _directional_frames[dir_name].size() == 0:
			var fallback_path = RUNTIME_SPRITE_BASE + char_id + "/" + char_id + "_" + dir_name + ".png"
			var fallback_tex = _load_texture_if_exists(fallback_path)
			if fallback_tex == null:
				fallback_path = base_path + char_id + "_" + dir_name + ".png"
				fallback_tex = _load_texture_if_exists(fallback_path)
			if fallback_tex:
				_directional_frames[dir_name].append(fallback_tex)
				loaded_count += 1

		if _directional_frames[dir_name].size() == 0:
			var still_tex = _load_still_fallback()
			if still_tex:
				_directional_frames[dir_name].append(still_tex)
				loaded_count += 1

	for frame_idx in range(5):
		var idle_path = RUNTIME_SPRITE_BASE + char_id + "/" + char_id + "_idle_" + str(frame_idx) + ".png"
		var idle_tex = _load_texture_if_exists(idle_path)
		if idle_tex:
			_idle_frames.append(idle_tex)

	if sprite:
		sprite.scale = SPRITE_SCALE
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var frames = _directional_frames.get("down", [])
		if frames.size() > 0:
			sprite.texture = frames[0]
			sprite.flip_h = false
			_last_texture = frames[0]
			_last_flip_h = false

	if loaded_count == 0:
		push_warning("[NPC] " + npc_name + " 未找到任何可用纹理")
	_log_event("[NPC] " + npc_name + " 方向帧加载完成 (" + str(loaded_count) + "帧)")

func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex is Texture2D:
			return tex
	return null

func _load_still_fallback() -> Texture2D:
	var zh_name = NPC_DISPLAY_NAMES.get(npc_name, "")
	var fallback_paths = []
	if not zh_name.is_empty():
		fallback_paths.append("res://assets/characters/npcs/" + zh_name + ".png")
		fallback_paths.append("res://assets/characters/npcs/人物移动动作/" + zh_name + ".png")
		fallback_paths.append("res://assets/characters/npcs/人物展示界面/" + zh_name + ".png")
	for path in fallback_paths:
		var tex = _load_texture_if_exists(path)
		if tex:
			return tex
	return null

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player = body
		is_wandering = false
		if player.has_method("set_nearby_npc"):
			player.set_nearby_npc(self)

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		if player != null and player.has_method("set_nearby_npc"):
			player.set_nearby_npc(null)
		player = null
		if wander_enabled and current_state == State.WORKING:
			state_timer = randf_range(work_duration_min, work_duration_max)

func update_dialogue(dialogue: String):
	if dialogue.is_empty():
		return

	var max_chars = 10
	var display_text = dialogue
	if display_text.length() > max_chars:
		display_text = display_text.left(max_chars) + "..."

	bubble_label.text = display_text

	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.clip_text = true

	dialogue_bubble.visible = true
	dialogue_bubble.modulate = Color(1, 1, 1, 0)
	var fade_tween = create_tween()
	fade_tween.tween_property(dialogue_bubble, "modulate", Color(1, 1, 1, 1), 0.2)

	if bubble_timer:
		bubble_timer.timeout.disconnect(_hide_bubble)
	bubble_timer = get_tree().create_timer(5.0)
	bubble_timer.timeout.connect(_hide_bubble)

func _hide_bubble():
	var fade_tween = create_tween()
	fade_tween.tween_property(dialogue_bubble, "modulate", Color(1, 1, 1, 0), 0.15)
	fade_tween.tween_callback(func():
		dialogue_bubble.visible = false
		bubble_label.text = ""
	)

func _physics_process(delta: float):
	if is_interacting:
		if player != null:
			_face_toward_player()
		_update_sprite_idle(delta, true)
		return

	if _glitch_mutation_active:
		_update_glitch_mutation_effect(delta)

	if player != null:
		_face_toward_player()
		_update_sprite_idle(delta, true)
		return

	if not wander_enabled:
		_update_sprite_idle(delta)
		return

	if _should_idle_for_distance():
		_update_sprite_idle(delta)
		return

	state_timer -= delta
	var is_moving_now = _update_current_state(delta)

	if is_moving_now:
		_update_sprite_walking(delta)
	else:
		_update_sprite_idle(delta)

func _should_idle_for_distance() -> bool:
	var player_dist = 9999.0
	if is_instance_valid(player):
		player_dist = global_position.distance_to(player.global_position)
	elif has_node("/root/PlayerManager") and is_instance_valid(get_node("/root/PlayerManager").player_node):
		player_dist = global_position.distance_to(get_node("/root/PlayerManager").player_node.global_position)
	else:
		var active_player = get_tree().get_first_node_in_group("player")
		if active_player and active_player is Node2D:
			player_dist = global_position.distance_to(active_player.global_position)
	return player_dist > 800.0 and current_state != State.WANDERING and current_state != State.RETURNING

func _update_current_state(delta: float) -> bool:
	match current_state:
		State.WORKING:
			return _update_working_state()

		State.WANDERING:
			return _update_wandering_state()

		State.RETURNING:
			return _update_returning_state()

		State.RESTING:
			return _update_resting_state(delta)

		State.SHELTERING:
			return _update_sheltering_state()
	return false

func _update_working_state() -> bool:
	if state_timer <= 0:
		current_state = State.WANDERING
		choose_new_wander_target()
		state_timer = randf_range(wander_duration_min, wander_duration_max)
		_log_event("🚶 " + display_name + "离开工位，开始闲逛")
	return false

func _update_wandering_state() -> bool:
	if state_timer <= 0:
		current_state = State.RETURNING
		state_timer = 9999
		_log_event("🔙 " + display_name + "正在返回工位")
	if is_wandering:
		return _move_toward_target(wander_target, 1.0)
	return false

func _update_returning_state() -> bool:
	if global_position.distance_to(work_position) < 10:
		current_state = State.WORKING
		is_wandering = false
		velocity = Vector2.ZERO
		global_position = work_position
		state_timer = randf_range(work_duration_min, work_duration_max)
		_log_event("💼 " + display_name + "回到工位，继续工作")
		return false
	return _move_toward_target(work_position, 1.5, false)

func _update_resting_state(delta: float) -> bool:
	if is_wandering:
		return _move_toward_target(wander_target, 0.7)
	_update_resting_bubble(delta)
	velocity = Vector2.ZERO
	return false

func _update_resting_bubble(delta: float) -> void:
	_resting_bubble_timer -= delta
	if _resting_bubble_timer > 0:
		return
	_resting_bubble_timer = randf_range(8.0, 15.0)
	var rest_phrases = ["休息中...", "好累啊...", "喝杯咖啡吧..."]
	if display_name in ["陈曦", "赵霖", "刘风"]:
		rest_phrases = ["嗯...今天也不错", "来一杯?", "..."]
	update_dialogue(rest_phrases[randi() % rest_phrases.size()])

func _update_sheltering_state() -> bool:
	if is_wandering:
		return _move_toward_target(wander_target, 1.2)
	if sprite:
		sprite.scale.y = SPRITE_SCALE.y * 1.1
	velocity = Vector2.ZERO
	return false

func _move_toward_target(target: Vector2, speed_multiplier: float, clear_wander_on_arrival: bool = true) -> bool:
	if global_position.distance_to(target) < 10:
		if clear_wander_on_arrival:
			is_wandering = false
		velocity = Vector2.ZERO
		return false
	var direction = (target - global_position).normalized()
	velocity = direction * move_speed * speed_multiplier
	move_and_slide()
	return true

func _update_sprite_walking(delta: float):
	if velocity.length() <= 1.0:
		_update_sprite_idle(delta)
		return

	if current_state != State.SHELTERING and sprite and not _glitch_mutation_active:
		sprite.scale = SPRITE_SCALE

	var new_direction = _current_direction
	var abs_vx = abs(velocity.x)
	var abs_vy = abs(velocity.y)
	if abs_vx >= abs_vy:
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
		_walk_frame = 0
		_walk_timer = 0.0
		_was_moving_last_frame = true
		_apply_frame()
		return

	_walk_timer += delta
	if _walk_timer >= _walk_frame_interval:
		_walk_timer -= _walk_frame_interval
		_walk_frame = (_walk_frame + 1) % _get_walk_frame_count(new_direction)
		_apply_frame()
	_was_moving_last_frame = true

func _update_sprite_idle(delta: float = 0.0, keep_direction: bool = false):
	_walk_frame = 0
	_walk_timer = 0.0

	if current_state != State.SHELTERING and sprite and not _glitch_mutation_active:
		sprite.scale = SPRITE_SCALE

	if keep_direction or _idle_frames.is_empty():
		_idle_frame = 0
		_idle_timer = 0.0
		_was_moving_last_frame = false
		_apply_frame()
		return

	if _was_moving_last_frame:
		_idle_frame = 0
		_idle_timer = 0.0
		_was_moving_last_frame = false
	else:
		_idle_timer += delta
		if _idle_timer >= _idle_frame_interval:
			_idle_timer -= _idle_frame_interval
			_idle_frame = (_idle_frame + 1) % _idle_frames.size()

	var tex: Texture2D = _idle_frames[_idle_frame]
	if sprite and tex and (tex != _last_texture or _last_flip_h):
		sprite.texture = tex
		sprite.flip_h = false
		_last_texture = tex
		_last_flip_h = false
		sprite.offset.y = 0.0

func _get_walk_frame_count(direction: String) -> int:
	var frames = _directional_frames.get(direction, [])
	if frames.size() > 0:
		return frames.size()

	if direction == "left" and _directional_frames.get("right", []).size() > 0:
		return _directional_frames["right"].size()
	if direction == "right" and _directional_frames.get("left", []).size() > 0:
		return _directional_frames["left"].size()
	if _directional_frames.get("down", []).size() > 0:
		return _directional_frames["down"].size()
	return 1

func _resolve_frame_direction(direction: String) -> Dictionary:
	var base_dir = direction
	var flip := false

	if direction in ["down_left", "up_left"]:
		base_dir = "down" if direction == "down_left" else "up"
		flip = true
	elif direction in ["down_right", "up_right"]:
		base_dir = "down" if direction == "down_right" else "up"

	var frames = _directional_frames.get(base_dir, [])
	if frames.size() == 0 and base_dir == "left":
		frames = _directional_frames.get("right", [])
		flip = true
	elif frames.size() == 0 and base_dir == "right":
		frames = _directional_frames.get("left", [])
		flip = true

	if frames.size() == 0:
		base_dir = "down"
		frames = _directional_frames.get(base_dir, [])
		flip = false

	return {"frames": frames, "flip": flip}

func _apply_frame():
	var resolved = _resolve_frame_direction(_current_direction)
	var frames: Array = resolved["frames"]
	if frames.size() == 0:
		return

	var flip: bool = resolved["flip"]
	var tex: Texture2D = frames[_walk_frame % frames.size()]

	if sprite and (tex != _last_texture or flip != _last_flip_h):
		sprite.texture = tex
		sprite.flip_h = flip
		_last_texture = tex
		_last_flip_h = flip

	# 行走时身体上下起伏
	if sprite:
		if velocity.length() > 10:
			var bob_offsets = [-2.0, 0.0, 2.0]
			sprite.offset.y = bob_offsets[_walk_frame % 3]
		else:
			sprite.offset.y = 0.0

func choose_new_wander_target():
	if patrol_points.size() > 0:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		wander_target = patrol_points[_patrol_index]
		is_wandering = true
	else:
		var offset = Vector2(
			randf_range(-wander_range, wander_range),
			randf_range(-wander_range, wander_range)
		)
		wander_target = work_position + offset
		is_wandering = true

func _on_day_night_changed(new_phase):
	_on_apply_bubble_style()
	_current_day_phase = new_phase
	_update_night_only_visibility(new_phase)
	if is_interacting:
		return
	match new_phase:
		0:
			if current_state == State.RESTING or current_state == State.SHELTERING:
				current_state = State.RETURNING
				state_timer = 9999
		1:
			current_state = State.RESTING
			is_wandering = true
			wander_target = _rest_position
			state_timer = randf_range(15.0, 25.0)
			_log_event("☕ " + display_name + "开始休息")
		2, 3:
			current_state = State.SHELTERING
			is_wandering = true
			wander_target = _shelter_position
			state_timer = 9999
			_log_event("🌧️ " + display_name + "寻找避雨处")

func _on_apply_bubble_style():
	var is_night = false
	if has_node("/root/DayNightManager"):
		is_night = get_node("/root/DayNightManager").is_night()

	if dialogue_bubble:
		var style = StyleBoxFlat.new()
		if is_night:
			style.bg_color = Color(0.06, 0.06, 0.15, 0.92)
			style.set_border_width_all(3)
			style.border_color = Color(0, 0.94, 1, 0.7)
			style.set_corner_radius_all(14)
			style.shadow_color = Color(0, 0.94, 1, 0.35)
			style.shadow_size = 5
		else:
			style.bg_color = Color(0.961, 0.941, 0.910, 0.92)
			style.set_border_width_all(3)
			style.border_color = Color(0.72, 0.53, 0.31, 0.7)
			style.set_corner_radius_all(14)
			style.shadow_color = Color(0.72, 0.53, 0.31, 0.25)
			style.shadow_size = 4
		dialogue_bubble.add_theme_stylebox_override("panel", style)

	if bubble_label:
		bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if is_night:
			bubble_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 1))
		else:
			bubble_label.add_theme_color_override("font_color", Color(0.15, 0.12, 0.10, 1))
		if has_node("/root/UIThemeManager"):
			get_node("/root/UIThemeManager").apply_font_to_label(bubble_label, 15)

func _face_toward_player():
	if not player:
		return
	var diff = player.global_position - global_position
	if abs(diff.x) > abs(diff.y):
		_current_direction = "right" if diff.x > 0 else "left"
	else:
		_current_direction = "down" if diff.y > 0 else "up"
	_apply_frame()

func _log_event(message: String):
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)

func _setup_night_only_npc():
	if npc_name == "zhao_lin":
		_night_only_npc = true

		_night_glow_light = PointLight2D.new()
		_night_glow_light.name = "NightGlow"
		_night_glow_light.color = Color(0.6, 0.2, 1.0, 0.5)
		_night_glow_light.energy = 0.8
		_night_glow_light.z_index = 47
		_night_glow_light.scale = Vector2(2, 2)

		var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for x in range(64):
			for y in range(64):
				var dist = Vector2(x - 32, y - 32).length() / 32.0
				var alpha = max(0, 1.0 - dist)
				alpha = pow(alpha, 2.0)
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
		_night_glow_light.texture = ImageTexture.create_from_image(img)

		add_child(_night_glow_light)
		_night_glow_light.visible = false

		if has_node("/root/DayNightManager"):
			_update_night_only_visibility(get_node("/root/DayNightManager").current_phase)

func _update_night_only_visibility(phase):
	if not _night_only_npc:
		return
	var is_night = (phase == DayNightManager.DayPhase.NIGHT or phase == DayNightManager.DayPhase.RAIN_NIGHT)
	if is_night:
		visible = true
		collision_layer = 2
		if _night_glow_light:
			_night_glow_light.visible = true
			_night_glow_light.modulate.a = 0.0
			var tw = create_tween()
			tw.tween_property(_night_glow_light, "modulate:a", 1.0, 0.6)
	else:
		if _night_glow_light:
			_night_glow_light.visible = false
		collision_layer = 0
		visible = false

func _setup_glitch_mutation():
	if npc_name != "chen_xi":
		return
	_glitch_shader = ShaderMaterial.new()
	var shader_path = "res://shaders/glitch.gdshader"
	if ResourceLoader.exists(shader_path):
		var shader = load(shader_path)
		if shader:
			_glitch_shader.shader = shader
			_glitch_shader.set_shader_parameter("intensity", 0.0)

func _on_hour_changed(hour: int):
	if npc_name != "chen_xi":
		return
	if not is_inside_tree():
		return
	if not has_node("/root/DayNightManager"):
		return

	var dnm = get_node("/root/DayNightManager")
	if dnm.is_after_midnight(0) and not _glitch_mutation_active:
		_activate_glitch_mutation()
	elif not dnm.is_after_midnight(0) and _glitch_mutation_active:
		_deactivate_glitch_mutation()

func _activate_glitch_mutation():
	if not sprite:
		return
	_glitch_mutation_active = true
	_glitch_timer = 0.0
	_next_glitch_change = 2.0 + randf() * 3.0
	if _glitch_shader and _glitch_shader.shader:
		sprite.material = _glitch_shader
		_glitch_shader.set_shader_parameter("intensity", 0.3 + randf() * 0.3)
	if OS.is_debug_build():
		print("[NPC] 陈曦触发凌晨glitch变异")

func _deactivate_glitch_mutation():
	if not sprite:
		return
	sprite.material = null
	_glitch_mutation_active = false
	if is_instance_valid(sprite):
		sprite.modulate = Color(1, 1, 1, 1)
		sprite.scale = Vector2(0.25, 0.25)
	if OS.is_debug_build():
		print("[NPC] 陈曦glitch变异解除")

func _update_glitch_mutation_effect(delta: float):
	if not _glitch_mutation_active:
		return
	_glitch_timer += delta
	if _glitch_timer >= _next_glitch_change:
		_glitch_timer = 0.0
		_next_glitch_change = 2.0 + randf() * 3.0
		if _glitch_shader and _glitch_shader.shader:
			_glitch_shader.set_shader_parameter("intensity", 0.3 + randf() * 0.3)
		if sprite and not (_glitch_shader and _glitch_shader.shader):
			_apply_glitch_tween()

func _apply_glitch_tween():
	if not sprite:
		return
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "modulate", Color(0.8, 0.3, 1.0, 1.0), 0.05)
	tw.tween_property(sprite, "scale:x", 0.048 + randf() * 0.008, 0.05)
	tw.chain().tween_property(sprite, "modulate", Color(1.0, 0.8, 1.0, 0.9), 0.1)
	tw.tween_property(sprite, "scale:x", 0.052, 0.1)
	tw.tween_property(sprite, "modulate", Color(0.7, 0.3, 1.0, 1.0), 0.08)
	tw.tween_property(sprite, "scale:x", 0.046, 0.08)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 0.9), 0.15)
	tw.tween_property(sprite, "scale:x", 0.05, 0.15)
