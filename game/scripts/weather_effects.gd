extends Node

enum WeatherType { SUNNY, CLOUDY, LIGHT_RAIN, THUNDERSTORM, FOG }

var current_weather: WeatherType = WeatherType.SUNNY
var _weather_overlay: ColorRect
var _rain_particles: GPUParticles2D
var _lightning_rect: ColorRect
var _lightning_timer: float = 0.0
var _lightning_cooldown: float = 0.0
var _cached_light_texture: Texture2D = null
var _cached_rain_texture: Texture2D = null
var _cached_rain_ramp: GradientTexture1D = null
var _initialized: bool = false

signal weather_changed(new_weather: WeatherType)

func _ready():
	_cached_light_texture = _create_light_texture()
	_cached_rain_texture = _create_rain_texture()
	_cached_rain_ramp = _create_color_ramp([Color(0.6, 0.65, 0.8, 0.0), Color(0.6, 0.65, 0.8, 0.5), Color(0.6, 0.65, 0.8, 0.0)])
	_sync_with_daily_generator()
	_initialized = true

func _process(delta):
	if current_weather == WeatherType.THUNDERSTORM:
		_process_thunderstorm(delta)

func _sync_with_daily_generator():
	if has_node("/root/DailyWorldGenerator"):
		var dwg = get_node("/root/DailyWorldGenerator")
		var weather = dwg.get_daily_weather()
		var _weather_name = weather.get("name", "")
		match _weather_name:
			"晴":
				current_weather = WeatherType.SUNNY
			"多云":
				current_weather = WeatherType.CLOUDY
			"小雨":
				current_weather = WeatherType.LIGHT_RAIN
			"雷暴":
				current_weather = WeatherType.THUNDERSTORM
			"雾霾":
				current_weather = WeatherType.FOG
			_:
				current_weather = WeatherType.SUNNY

func apply_weather_effects():
	if not _initialized:
		return
	if has_node("/root/SceneManager") and get_node("/root/SceneManager").is_apartment():
		_set_effects_visible(false)
		return

	var root = get_tree().current_scene
	if not root:
		return

	_ensure_effect_nodes(root)
	_set_effects_visible(true)
	_rain_particles.emitting = false
	_rain_particles.visible = false
	_lightning_rect.visible = false
	_lightning_rect.color = Color(1, 1, 1, 0)
	_weather_overlay.visible = current_weather != WeatherType.SUNNY

	match current_weather:
		WeatherType.SUNNY:
			_weather_overlay.color = Color(0, 0, 0, 0)
		WeatherType.CLOUDY:
			_weather_overlay.color = Color(0.05, 0.05, 0.08, 0.1)
		WeatherType.LIGHT_RAIN:
			_weather_overlay.color = Color(0.02, 0.02, 0.06, 0.15)
			_rain_particles.amount = 40
			_rain_particles.emitting = true
			_rain_particles.visible = true
		WeatherType.THUNDERSTORM:
			_weather_overlay.color = Color(0.02, 0.02, 0.08, 0.25)
			_rain_particles.amount = 80
			_rain_particles.emitting = true
			_rain_particles.visible = true
			_lightning_rect.visible = true
			_lightning_cooldown = randf_range(3.0, 8.0)
		WeatherType.FOG:
			_weather_overlay.color = Color(0.3, 0.3, 0.35, 0.2)

func _ensure_effect_nodes(root: Node) -> void:
	if is_instance_valid(_weather_overlay) and _weather_overlay.get_parent() == root:
		return

	_cleanup_effects()

	_weather_overlay = ColorRect.new()
	_weather_overlay.name = "WeatherOverlay"
	_weather_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_weather_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_weather_overlay.z_index = 51
	_weather_overlay.color = Color(0, 0, 0, 0)
	root.add_child(_weather_overlay)

	_rain_particles = _create_rain_particles(80)
	_rain_particles.emitting = false
	_rain_particles.visible = false
	root.add_child(_rain_particles)

	_lightning_rect = ColorRect.new()
	_lightning_rect.name = "LightningFlash"
	_lightning_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lightning_rect.color = Color(1, 1, 1, 0)
	_lightning_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lightning_rect.z_index = 52
	_lightning_rect.visible = false
	root.add_child(_lightning_rect)

func _set_effects_visible(visible: bool) -> void:
	if is_instance_valid(_weather_overlay):
		_weather_overlay.visible = visible and current_weather != WeatherType.SUNNY
	if is_instance_valid(_rain_particles):
		_rain_particles.visible = visible and is_raining()
		_rain_particles.emitting = visible and is_raining()
	if is_instance_valid(_lightning_rect):
		_lightning_rect.visible = visible and current_weather == WeatherType.THUNDERSTORM

func _process_thunderstorm(delta):
	if _lightning_cooldown > 0:
		_lightning_cooldown -= delta
		if _lightning_cooldown <= 0:
			_trigger_lightning()
			_lightning_cooldown = randf_range(4.0, 12.0)

	if _lightning_timer > 0:
		_lightning_timer -= delta
		if _lightning_timer <= 0 and _lightning_rect:
			_lightning_rect.color = Color(1, 1, 1, 0)

func _trigger_lightning():
	if not _lightning_rect:
		return
	_lightning_rect.color = Color(0.9, 0.9, 1.0, 0.4)
	_lightning_timer = 0.08 + randf() * 0.06

	if randf() < 0.4:
		var tween = create_tween()
		tween.tween_interval(0.1)
		tween.tween_callback(func():
			if is_instance_valid(_lightning_rect):
				_lightning_rect.color = Color(0.9, 0.9, 1.0, 0.25)
		)
		tween.tween_interval(0.06)
		tween.tween_callback(func():
			if is_instance_valid(_lightning_rect):
				_lightning_rect.color = Color(1, 1, 1, 0)
		)

func _create_rain_particles(amount: int) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.name = "RainParticles"
	particles.z_index = 51
	particles.amount = amount
	particles.process_mode = Node.PROCESS_MODE_INHERIT

	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0.1, 1.0, 0)
	pm.spread = 10.0
	pm.initial_velocity_min = 400.0
	pm.initial_velocity_max = 600.0
	pm.gravity = Vector3(0, 200, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.5
	pm.color = Color(0.6, 0.65, 0.8, 0.4)
	pm.color_ramp = _cached_rain_ramp
	pm.emission_box_extents = Vector3(700, 10, 0)

	particles.process_material = pm
	particles.texture = _cached_rain_texture
	particles.lifetime = 1.0
	particles.explosiveness = 0.0
	particles.randomness = 0.3
	particles.position = Vector2(640, -20)

	return particles

func _create_rain_texture() -> Texture2D:
	var img = Image.create(4, 16, false, Image.FORMAT_RGBA8)
	for x in range(4):
		for y in range(16):
			var alpha = 1.0 - abs(y - 8.0) / 8.0
			img.set_pixel(x, y, Color(0.7, 0.75, 0.9, alpha * 0.6))
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

func _create_light_texture() -> Texture2D:
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for x in range(256):
		for y in range(256):
			var dist = Vector2(x - 128, y - 128).length() / 128.0
			var alpha = max(0, 1.0 - dist)
			alpha = pow(alpha, 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)

func _cleanup_effects():
	var nodes_to_free = [_weather_overlay, _rain_particles, _lightning_rect]
	for node in nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()
	_weather_overlay = null
	_rain_particles = null
	_lightning_rect = null

func set_weather(weather: WeatherType):
	if current_weather == weather:
		return
	current_weather = weather
	weather_changed.emit(current_weather)
	apply_weather_effects()

func get_weather_name() -> String:
	match current_weather:
		WeatherType.SUNNY: return "晴"
		WeatherType.CLOUDY: return "多云"
		WeatherType.LIGHT_RAIN: return "小雨"
		WeatherType.THUNDERSTORM: return "雷暴"
		WeatherType.FOG: return "雾霾"
		_: return "未知"

func get_weather_icon() -> String:
	match current_weather:
		WeatherType.SUNNY: return "☀"
		WeatherType.CLOUDY: return "☁"
		WeatherType.LIGHT_RAIN: return "🌧"
		WeatherType.THUNDERSTORM: return "⛈"
		WeatherType.FOG: return "🌫"
		_: return "?"

func is_raining() -> bool:
	return current_weather == WeatherType.LIGHT_RAIN or current_weather == WeatherType.THUNDERSTORM

func rebuild_effects():
	_cleanup_effects()
	apply_weather_effects()
