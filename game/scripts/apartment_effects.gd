extends Node2D

var _time: float = 0.0
var _lightning_timer: float = 0.0
var _last_phase: int = -1

var _sunlight_particles: GPUParticles2D = null
var _anomaly_particles: GPUParticles2D = null
var _ambient_light: PointLight2D = null
var _screen_light: PointLight2D = null
var _anomaly_light: PointLight2D = null
var _window_neon_light: PointLight2D = null
var _distant_lightning_light: PointLight2D = null
var _night_overlay: ColorRect = null

var _cached_light_texture: Texture2D = null

func _ready():
	_cached_light_texture = _create_light_texture()
	_create_effects()
	_apply_effects()

func _create_effects():
	_sunlight_particles = _create_sunlight_particles()
	add_child(_sunlight_particles)
	
	_anomaly_particles = _create_anomaly_particles()
	add_child(_anomaly_particles)
	
	_ambient_light = PointLight2D.new()
	_ambient_light.energy = 0.0
	_ambient_light.texture = _cached_light_texture
	_ambient_light.z_index = 49
	_ambient_light.scale = Vector2(20, 20)
	_ambient_light.color = Color(1, 0.95, 0.8, 0.3)
	_ambient_light.position = Vector2(836, 300)
	add_child(_ambient_light)
	
	_screen_light = PointLight2D.new()
	_screen_light.energy = 0.0
	_screen_light.texture = _cached_light_texture
	_screen_light.z_index = 46
	_screen_light.scale = Vector2(3, 3)
	_screen_light.color = Color(0.2, 0.8, 0.7, 0.5)
	_screen_light.position = Vector2(600, 280)
	add_child(_screen_light)
	
	_anomaly_light = PointLight2D.new()
	_anomaly_light.energy = 0.0
	_anomaly_light.texture = _cached_light_texture
	_anomaly_light.z_index = 46
	_anomaly_light.scale = Vector2(5, 5)
	_anomaly_light.color = Color(0.6, 0.1, 0.9, 0.4)
	_anomaly_light.position = Vector2(1100, 300)
	add_child(_anomaly_light)
	
	_window_neon_light = PointLight2D.new()
	_window_neon_light.energy = 0.0
	_window_neon_light.texture = _cached_light_texture
	_window_neon_light.z_index = 45
	_window_neon_light.scale = Vector2(6, 6)
	_window_neon_light.color = Color(0.0, 0.8, 1.0, 0.4)
	_window_neon_light.position = Vector2(836, 200)
	add_child(_window_neon_light)
	
	_distant_lightning_light = PointLight2D.new()
	_distant_lightning_light.energy = 0.0
	_distant_lightning_light.texture = _cached_light_texture
	_distant_lightning_light.z_index = 45
	_distant_lightning_light.scale = Vector2(10, 10)
	_distant_lightning_light.color = Color(0.7, 0.7, 1.0, 0.3)
	_distant_lightning_light.position = Vector2(836, 100)
	add_child(_distant_lightning_light)
	
	_night_overlay = ColorRect.new()
	_night_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_night_overlay.z_index = 50
	_night_overlay.color = Color(0, 0, 0, 0)
	add_child(_night_overlay)

func _process(delta):
	_time += delta
	
	if not has_node("/root/DayNightManager"):
		return
	
	var dnm = get_node("/root/DayNightManager")
	var phase = dnm.current_phase
	var phase_changed = (phase != _last_phase)
	_last_phase = phase
	
	match phase:
		dnm.DayPhase.DAY, dnm.DayPhase.DUSK:
			_process_day(delta, phase_changed)
		dnm.DayPhase.RAIN_NIGHT:
			_process_rain_night(delta, phase_changed)
		dnm.DayPhase.NIGHT:
			_process_anomaly_night(delta, phase_changed)

func _process_day(_delta, phase_changed):
	if phase_changed:
		if _sunlight_particles:
			_sunlight_particles.emitting = true
			_sunlight_particles.amount = 5
		if _anomaly_particles:
			_anomaly_particles.emitting = false
		if _ambient_light:
			_ambient_light.energy = 0.8
			_ambient_light.color = Color(1, 0.95, 0.8, 0.3)
		if _screen_light:
			_screen_light.energy = 0.0
		if _anomaly_light:
			_anomaly_light.energy = 0.0
		if _window_neon_light:
			_window_neon_light.energy = 0.0
		if _distant_lightning_light:
			_distant_lightning_light.energy = 0.0
		if _night_overlay:
			_night_overlay.color = Color(0, 0, 0, 0)

func _process_rain_night(delta, phase_changed):
	if phase_changed:
		if _sunlight_particles:
			_sunlight_particles.emitting = false
		if _anomaly_particles:
			_anomaly_particles.emitting = false
		if _ambient_light:
			_ambient_light.energy = 0.4
			_ambient_light.color = Color(0.4, 0.4, 0.8, 0.5)
		if _anomaly_light:
			_anomaly_light.energy = 0.0
		if _distant_lightning_light:
			_distant_lightning_light.energy = 0.0
		if _night_overlay:
			_night_overlay.color = Color(0.02, 0.02, 0.1, 0.5)
	if _screen_light:
		_screen_light.energy = 0.3 + randf() * 0.1
	if _window_neon_light:
		_window_neon_light.energy = 0.5 + sin(_time * 1.2) * 0.15
		if randf() < 0.01:
			_window_neon_light.energy = 0.1
	
	_lightning_timer -= delta
	if _lightning_timer <= 0:
		_lightning_timer = randf_range(6.0, 18.0)
		if _distant_lightning_light:
			_distant_lightning_light.energy = 0.6
			var tween = create_tween()
			tween.tween_property(_distant_lightning_light, "energy", 0.0, 0.3)

func _process_anomaly_night(_delta, phase_changed):
	if phase_changed:
		if _sunlight_particles:
			_sunlight_particles.emitting = false
		if _anomaly_particles:
			_anomaly_particles.emitting = true
			_anomaly_particles.amount = 5
		if _ambient_light:
			_ambient_light.energy = 0.3
			_ambient_light.color = Color(0.3, 0.1, 0.5, 0.6)
		if _window_neon_light:
			_window_neon_light.energy = 0.0
		if _distant_lightning_light:
			_distant_lightning_light.energy = 0.0
		if _night_overlay:
			_night_overlay.color = Color(0.05, 0.02, 0.1, 0.6)
	if _screen_light:
		_screen_light.energy = 0.2 + sin(_time * 2.0) * 0.1
	if _anomaly_light:
		_anomaly_light.energy = 0.3 + sin(_time * 1.5) * 0.15

func _apply_effects():
	_process_day(0, true)

func _create_sunlight_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.z_index = 46
	p.amount = 5
	p.lifetime = 8.0
	p.position = Vector2(836, 300)
	p.process_mode = Node.PROCESS_MODE_INHERIT
	
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0.3, 0.5, 0)
	pm.spread = 45.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0, 0.5, 0)
	pm.scale_min = 2.0
	pm.scale_max = 4.0
	pm.color = Color(1.0, 0.9, 0.5, 0.25)
	pm.emission_box_extents = Vector3(400, 200, 0)
	p.process_material = pm
	
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for x in range(32):
		for y in range(32):
			var dist = Vector2(x - 16, y - 16).length() / 16.0
			var glow = max(0, 1.0 - dist)
			img.set_pixel(x, y, Color(1.0, 0.95, 0.7, pow(glow, 1.5)))
	p.texture = ImageTexture.create_from_image(img)
	
	return p

func _create_anomaly_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.z_index = 48
	p.amount = 5
	p.lifetime = 7.0
	p.position = Vector2(836, 400)
	p.process_mode = Node.PROCESS_MODE_INHERIT
	
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 50.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 12.0
	pm.gravity = Vector3(0, -2, 0)
	pm.scale_min = 0.7
	pm.scale_max = 2.0
	pm.color = Color(0.6, 0.1, 0.9, 0.4)
	pm.emission_box_extents = Vector3(500, 200, 0)
	p.process_material = pm
	
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for x in range(8):
		for y in range(8):
			var dist = Vector2(x - 4, y - 4).length() / 4.0
			var glow = max(0, 1.0 - dist)
			img.set_pixel(x, y, Color(0.7, 0.2, 1.0, pow(glow, 1.0)))
	p.texture = ImageTexture.create_from_image(img)
	
	return p

func _create_light_texture() -> Texture2D:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for x in range(256):
		for y in range(256):
			var dist = Vector2(x - 128, y - 128).length() / 128.0
			var alpha = max(0, 1.0 - dist)
			alpha = pow(alpha, 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)
