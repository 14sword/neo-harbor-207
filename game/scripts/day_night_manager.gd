extends Node

enum DayPhase { DAY, DUSK, NIGHT, RAIN_NIGHT }

var current_phase: DayPhase = DayPhase.DAY
var _initialized: bool = false

const GAME_MINUTES_PER_REAL_SECOND: float = 20.0
var _game_hour: float = 8.0
var _previous_hour: int = 8

var office_backgrounds: Dictionary = {
	DayPhase.DAY: "res://assets/backgrounds/星露谷.png",
	DayPhase.DUSK: "res://assets/backgrounds/星露谷.png",
	DayPhase.NIGHT: "res://assets/backgrounds/黑夜办公室.png",
	DayPhase.RAIN_NIGHT: "res://assets/backgrounds/黑夜办公室.png",
}

var street_backgrounds: Dictionary = {
	DayPhase.DAY: "res://assets/backgrounds/street/白天.png",
	DayPhase.DUSK: "res://assets/backgrounds/street/傍晚.png",
	DayPhase.NIGHT: "res://assets/backgrounds/street/黑夜.png",
	DayPhase.RAIN_NIGHT: "res://assets/backgrounds/street/雨夜街区.png",
}

var apartment_backgrounds: Dictionary = {
	DayPhase.DAY: "res://assets/backgrounds/apartment/白天.png",
	DayPhase.DUSK: "res://assets/backgrounds/apartment/白天.png",
	DayPhase.NIGHT: "res://assets/backgrounds/apartment/黑夜.png",
	DayPhase.RAIN_NIGHT: "res://assets/backgrounds/apartment/雨夜.png",
}

signal phase_changed(new_phase: DayPhase)
signal time_updated(phase: String)
signal hour_changed(hour: int)

var _overlay: ColorRect
var _firefly_particles: GPUParticles2D
var _neon_particles: GPUParticles2D
var _ambient_light: PointLight2D
var _sunlight_particles: GPUParticles2D
var _window_light: PointLight2D
var _screen_lights: Array = []
var _moonlight: PointLight2D
var _time: float = 0.0
var _cached_light_texture: Texture2D = null
var _last_phase: int = -1

var _screen_flicker_timer: float = 0.0

func _ready():
	_cached_light_texture = _create_light_texture()
	_create_night_effects()
	_initialized = true
	_apply_background()
	_apply_bgm()
	_apply_night_effects()

func _process(delta: float):
	_time += delta

	_game_hour += delta * GAME_MINUTES_PER_REAL_SECOND / 60.0
	if _game_hour >= 24.0:
		_game_hour = fmod(_game_hour, 24.0)
	var current_hour = int(_game_hour)
	if current_hour != _previous_hour:
		_previous_hour = current_hour
		hour_changed.emit(current_hour)

	if Input.is_action_just_pressed("toggle_day_night"):
		toggle_day_night()

	var _phase_switched = (current_phase != _last_phase)
	_last_phase = current_phase

	match current_phase:
		DayPhase.DAY:
			_process_day(delta, _phase_switched)
		DayPhase.DUSK:
			_process_dusk(delta, _phase_switched)
		DayPhase.NIGHT:
			_process_night(delta, _phase_switched)
		DayPhase.RAIN_NIGHT:
			_process_rain_night(delta, _phase_switched)

func _process_day(_delta: float, phase_changed: bool):
	if has_node("/root/SceneManager") and get_node("/root/SceneManager").is_apartment():
		return
	if phase_changed:
		if _firefly_particles:
			_firefly_particles.emitting = false
		if _neon_particles:
			_neon_particles.emitting = false
		if _sunlight_particles:
			_sunlight_particles.emitting = true
			_sunlight_particles.amount = 10
		if _moonlight:
			_moonlight.energy = 0.0
		for sl in _screen_lights:
			if sl:
				sl.energy = 0.0
	if _window_light:
		_window_light.energy = 0.3 + sin(_time * 0.5) * 0.1

func _process_dusk(_delta: float, phase_changed: bool):
	if has_node("/root/SceneManager") and get_node("/root/SceneManager").is_apartment():
		return
	if phase_changed:
		if _firefly_particles:
			_firefly_particles.emitting = false
		if _neon_particles:
			_neon_particles.emitting = true
			_neon_particles.amount = 4
		if _sunlight_particles:
			_sunlight_particles.emitting = true
			_sunlight_particles.amount = 5
		if _moonlight:
			_moonlight.energy = 0.15
		for sl in _screen_lights:
			if sl:
				sl.energy = 0.1
	if _window_light:
		_window_light.energy = 0.2 + sin(_time * 0.5) * 0.08

func _process_night(_delta: float, phase_changed: bool):
	if has_node("/root/SceneManager") and get_node("/root/SceneManager").is_apartment():
		return
	if phase_changed:
		if _firefly_particles:
			_firefly_particles.emitting = true
			_firefly_particles.amount = 15
		if _neon_particles:
			_neon_particles.emitting = true
			_neon_particles.amount = 8
		if _sunlight_particles:
			_sunlight_particles.emitting = false
		if _window_light:
			_window_light.energy = 0.0
	if _ambient_light:
		_ambient_light.energy = 0.6 + sin(_time * 0.8) * 0.08
	if _moonlight:
		_moonlight.energy = 0.4 + sin(_time * 0.3) * 0.1
	_screen_flicker_timer += _delta
	if _screen_flicker_timer > 0.5:
		_screen_flicker_timer = 0.0
		for sl in _screen_lights:
			if sl:
				sl.energy = 0.3 + randf() * 0.1

func _process_rain_night(_delta: float, phase_changed: bool):
	if has_node("/root/SceneManager") and get_node("/root/SceneManager").is_apartment():
		return
	if phase_changed:
		if _firefly_particles:
			_firefly_particles.emitting = false
		if _neon_particles:
			_neon_particles.emitting = true
			_neon_particles.amount = 10
		if _sunlight_particles:
			_sunlight_particles.emitting = false
		if _window_light:
			_window_light.energy = 0.0
		if _moonlight:
			_moonlight.energy = 0.1
	if _ambient_light:
		_ambient_light.energy = 0.4 + sin(_time * 0.8) * 0.06
	_screen_flicker_timer += _delta
	if _screen_flicker_timer > 0.5:
		_screen_flicker_timer = 0.0
		for sl in _screen_lights:
			if sl:
				sl.energy = 0.4 + randf() * 0.15

func _create_night_effects():
	if has_node("/root/SceneManager") and get_node("/root/SceneManager").is_apartment():
		return
	var root = get_tree().current_scene
	if not root:
		return

	_overlay = ColorRect.new()
	_overlay.name = "NightOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.z_index = 50
	_overlay.color = Color(0, 0, 0, 0)
	root.add_child(_overlay)

	_firefly_particles = _create_firefly_particles()
	root.add_child(_firefly_particles)

	_neon_particles = _create_neon_particles()
	root.add_child(_neon_particles)

	_ambient_light = PointLight2D.new()
	_ambient_light.name = "NightAmbientLight"
	_ambient_light.energy = 0.8
	_ambient_light.texture = _cached_light_texture
	_ambient_light.z_index = 49
	_ambient_light.scale = Vector2(25, 25)
	_ambient_light.color = Color(0.5, 0.5, 0.9, 0.6)
	root.add_child(_ambient_light)

	_sunlight_particles = _create_sunlight_particles()
	root.add_child(_sunlight_particles)

	_window_light = PointLight2D.new()
	_window_light.name = "WindowLight"
	_window_light.energy = 0.3
	_window_light.texture = _cached_light_texture
	_window_light.z_index = 46
	_window_light.scale = Vector2(5, 5)
	_window_light.color = Color(1, 0.95, 0.8, 0.4)
	_window_light.position = Vector2(200, 100)
	root.add_child(_window_light)

	_moonlight = PointLight2D.new()
	_moonlight.name = "Moonlight"
	_moonlight.energy = 0.0
	_moonlight.texture = _cached_light_texture
	_moonlight.z_index = 46
	_moonlight.scale = Vector2(8, 8)
	_moonlight.color = Color(0.4, 0.5, 0.9, 0.3)
	_moonlight.position = Vector2(1100, 50)
	root.add_child(_moonlight)

	for pos in [Vector2(300, 300), Vector2(600, 280), Vector2(900, 310)]:
		var screen_light = PointLight2D.new()
		screen_light.name = "ScreenLight"
		screen_light.energy = 0.0
		screen_light.texture = _cached_light_texture
		screen_light.z_index = 46
		screen_light.scale = Vector2(3, 3)
		screen_light.color = Color(0.2, 0.8, 0.7, 0.5)
		screen_light.position = pos
		root.add_child(screen_light)
		_screen_lights.append(screen_light)

func _create_firefly_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.name = "FireflyParticles"
	particles.z_index = 48
	particles.amount = 15
	particles.emitting = false
	particles.process_mode = Node.PROCESS_MODE_INHERIT

	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0.5, -0.3, 0)
	pm.spread = 90.0
	pm.initial_velocity_min = 2.5
	pm.initial_velocity_max = 10.0
	pm.gravity = Vector3(0, -0.5, 0)
	pm.scale_min = 0.5
	pm.scale_max = 2.0
	pm.color = Color(0.3, 0.8, 0.4, 0.6)
	pm.color_ramp = _create_color_ramp([Color(0.3, 0.8, 0.4, 0.0), Color(0.5, 1.0, 0.6, 0.8), Color(0.3, 0.8, 0.4, 0.0)])
	pm.emission_box_extents = Vector3(400, 200, 0)

	particles.process_material = pm
	particles.texture = _create_firefly_texture()
	particles.lifetime = 6.0
	particles.explosiveness = 0.0
	particles.randomness = 0.8
	particles.position = Vector2(640, 360)

	return particles

func _create_neon_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.name = "NeonParticles"
	particles.z_index = 47
	particles.amount = 8
	particles.emitting = false
	particles.process_mode = Node.PROCESS_MODE_INHERIT

	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, 0)
	pm.spread = 30.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0, 0, 0)
	pm.scale_min = 1.0
	pm.scale_max = 4.0
	pm.color = Color(0.8, 0.2, 0.8, 0.5)
	pm.color_ramp = _create_color_ramp([Color(0.8, 0.2, 0.8, 0.0), Color(0.9, 0.4, 1.0, 0.7), Color(0.8, 0.2, 0.8, 0.0)])

	particles.process_material = pm
	particles.texture = _create_neon_texture()
	particles.lifetime = 4.0
	particles.explosiveness = 0.0
	particles.randomness = 0.9
	particles.position = Vector2(640, 360)

	return particles

func _create_sunlight_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.name = "SunlightParticles"
	particles.z_index = 46
	particles.amount = 10
	particles.lifetime = 8.0
	particles.explosiveness = 0.0
	particles.randomness = 0.6
	particles.position = Vector2(640, 360)
	particles.process_mode = Node.PROCESS_MODE_INHERIT

	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0.3, 0.5, 0)
	pm.spread = 45.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0, 0.5, 0)
	pm.scale_min = 2.0
	pm.scale_max = 5.0
	pm.color = Color(1.0, 0.9, 0.5, 0.3)
	pm.color_ramp = _create_color_ramp([Color(1.0, 0.9, 0.5, 0.0), Color(1.0, 0.95, 0.6, 0.4), Color(1.0, 0.9, 0.5, 0.0)])
	pm.emission_box_extents = Vector3(500, 300, 0)

	particles.process_material = pm
	particles.texture = _create_sunlight_texture()

	return particles

func _create_sunlight_texture() -> Texture2D:
	var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for x in range(48):
		for y in range(48):
			var center = Vector2(23.5, 23.5)
			var dist = Vector2(x, y).distance_to(center) / 24.0
			var glow = max(0, 1.0 - dist)
			glow = pow(glow, 1.5)
			img.set_pixel(x, y, Color(1.0, 0.95, 0.7, glow))
	return ImageTexture.create_from_image(img)

func _create_color_ramp(colors: Array) -> GradientTexture1D:
	var gradient = Gradient.new()
	var count = colors.size()
	for i in range(count):
		gradient.add_point(float(i) / float(count - 1), colors[i])
	var tex = GradientTexture1D.new()
	tex.gradient = gradient
	tex.width = 256
	return tex

func _create_firefly_texture() -> Texture2D:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for x in range(32):
		for y in range(32):
			var center = Vector2(15.5, 15.5)
			var dist = Vector2(x, y).distance_to(center) / 16.0
			var glow = max(0, 1.0 - dist * dist)
			glow = pow(glow, 0.5)
			img.set_pixel(x, y, Color(0.6, 1.0, 0.7, glow))
	return ImageTexture.create_from_image(img)

func _create_neon_texture() -> Texture2D:
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	for x in range(24):
		for y in range(24):
			var center = Vector2(11.5, 11.5)
			var dist = Vector2(x, y).distance_to(center) / 12.0
			var glow = max(0, 1.0 - dist)
			glow = pow(glow, 1.2)
			img.set_pixel(x, y, Color(1.0, 0.5, 1.0, glow))
	return ImageTexture.create_from_image(img)

func _create_light_texture() -> Texture2D:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for x in range(256):
		for y in range(256):
			var dist = Vector2(x - 128, y - 128).length() / 128.0
			var alpha = max(0, 1.0 - dist)
			alpha = pow(alpha, 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)

func _apply_night_effects():
	if has_node("/root/SceneManager") and get_node("/root/SceneManager").is_apartment():
		return
	if not _overlay:
		return

	match current_phase:
		DayPhase.DAY:
			_overlay.color = Color(0, 0, 0, 0)
			if _ambient_light:
				_ambient_light.energy = 1.0
				_ambient_light.color = Color(1, 1, 0.9, 0.3)
		DayPhase.DUSK:
			_overlay.color = Color(0.1, 0.05, 0.0, 0.2)
			if _ambient_light:
				_ambient_light.energy = 0.7
				_ambient_light.color = Color(1, 0.7, 0.4, 0.4)
		DayPhase.NIGHT:
			_overlay.color = Color(0.02, 0.02, 0.08, 0.4)
			if _ambient_light:
				_ambient_light.energy = 0.8
				_ambient_light.color = Color(0.5, 0.5, 0.9, 0.6)
		DayPhase.RAIN_NIGHT:
			_overlay.color = Color(0.02, 0.02, 0.1, 0.5)
			if _ambient_light:
				_ambient_light.energy = 0.5
				_ambient_light.color = Color(0.4, 0.4, 0.8, 0.5)

func set_phase(new_phase: DayPhase) -> void:
	current_phase = new_phase
	_apply_background()
	_apply_bgm()
	_apply_night_effects()
	_apply_weather_effects()
	phase_changed.emit(current_phase)
	time_updated.emit(get_phase_string())

func toggle_day_night():
	var is_office = true
	if has_node("/root/SceneManager"):
		is_office = get_node("/root/SceneManager").is_office()

	if is_office:
		match current_phase:
			DayPhase.DAY, DayPhase.DUSK:
				current_phase = DayPhase.NIGHT
			DayPhase.NIGHT, DayPhase.RAIN_NIGHT:
				current_phase = DayPhase.DAY
	else:
		var is_apartment = false
		if has_node("/root/SceneManager"):
			is_apartment = get_node("/root/SceneManager").is_apartment()
		
		if is_apartment:
			match current_phase:
				DayPhase.DAY:
					current_phase = DayPhase.RAIN_NIGHT
				DayPhase.DUSK:
					current_phase = DayPhase.RAIN_NIGHT
				DayPhase.RAIN_NIGHT:
					current_phase = DayPhase.NIGHT
				DayPhase.NIGHT:
					current_phase = DayPhase.DAY
		else:
			match current_phase:
				DayPhase.DAY:
					current_phase = DayPhase.DUSK
				DayPhase.DUSK:
					current_phase = DayPhase.NIGHT
				DayPhase.NIGHT:
					current_phase = DayPhase.RAIN_NIGHT
				DayPhase.RAIN_NIGHT:
					current_phase = DayPhase.DAY

	_apply_background()
	_apply_bgm()
	_apply_night_effects()
	_apply_weather_effects()
	phase_changed.emit(current_phase)
	time_updated.emit(get_phase_string())
	_log_event("切换到" + get_phase_string() + "模式")

func _apply_background():
	if not _initialized:
		return

	var bg = get_tree().get_first_node_in_group("background")
	if bg == null:
		print("[DayNight] Background node not found!")
		return

	if not bg is Sprite2D:
		return

	var is_street = false
	var is_apartment = false
	if has_node("/root/SceneManager"):
		is_street = get_node("/root/SceneManager").is_street()
		is_apartment = get_node("/root/SceneManager").is_apartment()

	var bg_map = office_backgrounds
	if is_street:
		bg_map = street_backgrounds
	elif is_apartment:
		bg_map = apartment_backgrounds

	var bg_path = bg_map.get(current_phase, "")
	print("[DayNight] Applying background: ", bg_path, " phase=", current_phase, " street=", is_street, " apt=", is_apartment)
	if bg_path != "" and ResourceLoader.exists(bg_path):
		bg.texture = load(bg_path)
	else:
		print("[DayNight] Background path invalid or missing: ", bg_path)

func _apply_bgm():
	if not _initialized:
		return

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method("play_bgm_day"):
			match current_phase:
				DayPhase.DAY:
					am.play_bgm_day()
				DayPhase.DUSK:
					am.play_bgm_night()
				DayPhase.NIGHT:
					am.play_bgm_night()
				DayPhase.RAIN_NIGHT:
					am.play_bgm_night()

func is_day() -> bool:
	return current_phase == DayPhase.DAY

func is_dusk() -> bool:
	return current_phase == DayPhase.DUSK

func is_night() -> bool:
	return current_phase == DayPhase.NIGHT or current_phase == DayPhase.RAIN_NIGHT

func is_rain() -> bool:
	return current_phase == DayPhase.RAIN_NIGHT

func get_phase_string() -> String:
	match current_phase:
		DayPhase.DAY: return "白天"
		DayPhase.DUSK: return "傍晚"
		DayPhase.NIGHT: return "黑夜"
		DayPhase.RAIN_NIGHT: return "雨夜"
		_: return "未知"

func get_current_phase() -> int:
	return current_phase

func get_game_hour() -> float:
	return _game_hour

func is_after_midnight(hour_threshold: int = 2) -> bool:
	return (current_phase == DayPhase.NIGHT or current_phase == DayPhase.RAIN_NIGHT) and _game_hour >= float(hour_threshold) and _game_hour < 6.0

func _log_event(message: String):
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)

func rebuild_effects():
	_cleanup_effects()
	_create_night_effects()
	_apply_background()
	_apply_night_effects()

func _cleanup_effects():
	var nodes_to_free = [_overlay, _firefly_particles, _neon_particles, _ambient_light, _sunlight_particles, _window_light, _moonlight]
	for node in nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()
	for sl in _screen_lights:
		if is_instance_valid(sl):
			sl.queue_free()
	_screen_lights.clear()
	_overlay = null
	_firefly_particles = null
	_neon_particles = null
	_ambient_light = null
	_sunlight_particles = null
	_window_light = null
	_moonlight = null

func _apply_weather_effects():
	if has_node("/root/WeatherEffects"):
		get_node("/root/WeatherEffects").apply_weather_effects()
