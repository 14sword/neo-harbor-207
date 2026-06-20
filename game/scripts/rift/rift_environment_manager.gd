extends Node2D

signal environment_changed(tile: Dictionary)

const ARENA_SIZE: Vector2 = Vector2(1920, 1080)
const BACKGROUND_ROOT: String = "res://assets/rift/backgrounds/"
const TARGET_MAX_FPS: int = 120

class WeatherPainter:
	extends Node2D

	var weather: String = "clear_rift"
	var arena_size: Vector2 = Vector2(1920, 1080)
	var _particles: Array[Dictionary] = []
	var _rng := RandomNumberGenerator.new()
	var _pulse: float = 0.0
	var _lightning_point: Vector2 = Vector2.ZERO
	var _lightning_timer: float = 0.0

	func configure(new_weather: String, new_arena_size: Vector2) -> void:
		weather = new_weather
		arena_size = new_arena_size
		_rng.randomize()
		_particles.clear()
		_pulse = 0.0
		_lightning_timer = _rng.randf_range(0.8, 1.6)
		_lightning_point = _random_point()
		var count: int = _particle_count_for_weather(weather)
		for i in range(count):
			_particles.append(_new_particle())
		set_process(weather != "clear_rift")
		queue_redraw()

	func _process(delta: float) -> void:
		_pulse += delta
		for i in range(_particles.size()):
			var particle: Dictionary = _particles[i]
			var pos: Vector2 = particle.get("pos", Vector2.ZERO)
			var velocity: Vector2 = particle.get("velocity", Vector2.ZERO)
			pos += velocity * delta
			if pos.x < -90.0 or pos.x > arena_size.x + 90.0 or pos.y < -90.0 or pos.y > arena_size.y + 90.0:
				particle = _new_particle()
			else:
				particle["pos"] = pos
			_particles[i] = particle
		if weather == "thunderstorm":
			_lightning_timer -= delta
			if _lightning_timer <= 0.0:
				_lightning_timer = _rng.randf_range(1.0, 2.2)
				_lightning_point = _random_point()
		queue_redraw()

	func _draw() -> void:
		match weather:
			"data_rain":
				_draw_data_rain()
			"rift_snow":
				_draw_rift_snow()
			"thunderstorm":
				_draw_thunderstorm()
			"fog_tide":
				_draw_fog_tide()

	func _draw_data_rain() -> void:
		for particle in _particles:
			var pos: Vector2 = particle.get("pos", Vector2.ZERO)
			var length: float = float(particle.get("length", 32.0))
			draw_line(pos, pos + Vector2(-18.0, length), Color(0.1, 0.95, 1.0, 0.46), 2.0)

	func _draw_rift_snow() -> void:
		draw_rect(Rect2(Vector2.ZERO, arena_size), Color(0.7, 0.85, 1.0, 0.08), true)
		for particle in _particles:
			var pos: Vector2 = particle.get("pos", Vector2.ZERO)
			var radius: float = float(particle.get("radius", 2.2))
			draw_circle(pos, radius, Color(0.82, 0.96, 1.0, 0.72))

	func _draw_thunderstorm() -> void:
		for particle in _particles:
			var pos: Vector2 = particle.get("pos", Vector2.ZERO)
			var length: float = float(particle.get("length", 42.0))
			draw_line(pos, pos + Vector2(-14.0, length), Color(0.25, 0.65, 1.0, 0.28), 1.6)
		var pulse_alpha: float = 0.24 + sin(_pulse * 9.0) * 0.11
		draw_circle(_lightning_point, 56.0, Color(0.95, 0.82, 0.25, pulse_alpha))
		draw_arc(_lightning_point, 74.0, 0.0, TAU, 48, Color(1.0, 0.9, 0.38, 0.68), 3.0)

	func _draw_fog_tide() -> void:
		draw_rect(Rect2(Vector2.ZERO, arena_size), Color(0.65, 0.78, 0.86, 0.14), true)
		for particle in _particles:
			var pos: Vector2 = particle.get("pos", Vector2.ZERO)
			var radius: float = float(particle.get("radius", 96.0))
			var alpha: float = 0.08 + 0.03 * sin(_pulse * 1.5 + pos.x * 0.01)
			draw_circle(pos, radius, Color(0.86, 0.9, 0.96, alpha))

	func _particle_count_for_weather(kind: String) -> int:
		match kind:
			"data_rain":
				return 130
			"rift_snow":
				return 95
			"thunderstorm":
				return 80
			"fog_tide":
				return 22
			_:
				return 0

	func _new_particle() -> Dictionary:
		match weather:
			"data_rain":
				return {
					"pos": Vector2(_rng.randf_range(-80.0, arena_size.x + 80.0), _rng.randf_range(-80.0, arena_size.y)),
					"velocity": Vector2(-210.0, _rng.randf_range(420.0, 620.0)),
					"length": _rng.randf_range(22.0, 46.0),
				}
			"rift_snow":
				return {
					"pos": Vector2(_rng.randf_range(-60.0, arena_size.x + 60.0), _rng.randf_range(-80.0, arena_size.y)),
					"velocity": Vector2(_rng.randf_range(-18.0, 34.0), _rng.randf_range(45.0, 92.0)),
					"radius": _rng.randf_range(1.4, 3.4),
				}
			"thunderstorm":
				return {
					"pos": Vector2(_rng.randf_range(-80.0, arena_size.x + 80.0), _rng.randf_range(-80.0, arena_size.y)),
					"velocity": Vector2(-120.0, _rng.randf_range(330.0, 520.0)),
					"length": _rng.randf_range(34.0, 62.0),
				}
			"fog_tide":
				return {
					"pos": Vector2(_rng.randf_range(-80.0, arena_size.x + 80.0), _rng.randf_range(80.0, arena_size.y - 80.0)),
					"velocity": Vector2(_rng.randf_range(6.0, 22.0), _rng.randf_range(-8.0, 8.0)),
					"radius": _rng.randf_range(82.0, 180.0),
				}
			_:
				return {"pos": _random_point(), "velocity": Vector2.ZERO}

	func _random_point() -> Vector2:
		return Vector2(_rng.randf_range(260.0, arena_size.x - 260.0), _rng.randf_range(170.0, arena_size.y - 170.0))

var _overlay: ColorRect
var _weather_painter: WeatherPainter

func _ready() -> void:
	z_index = 4
	_overlay = ColorRect.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.position = Vector2.ZERO
	_overlay.size = ARENA_SIZE
	_overlay.color = Color(0.04, 0.0, 0.10, 0.10)
	add_child(_overlay)
	_weather_painter = WeatherPainter.new()
	_weather_painter.z_index = 2
	add_child(_weather_painter)
	_weather_painter.configure("clear_rift", ARENA_SIZE)

func apply_tile_environment(tile: Dictionary, background: Sprite2D) -> void:
	if not background:
		return
	var realm_id: String = str(tile.get("realm_id", "western_fantasy"))
	var time_phase: String = str(tile.get("time_phase", "dawn"))
	var weather: String = str(tile.get("weather", "data_rain"))
	var background_path: String = str(tile.get("background_path", get_background_path(realm_id, time_phase, weather)))
	var tex: Texture2D = _load_texture(background_path)
	if tex:
		background.texture = tex
		background.position = ARENA_SIZE * 0.5
		background.scale = _scale_for_texture(tex)
		background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_overlay.color = _tint_for_environment(time_phase, weather)
	_weather_painter.configure(weather, ARENA_SIZE)
	environment_changed.emit(tile.duplicate(true))

func clear_environment() -> void:
	_overlay.color = Color(0.04, 0.0, 0.10, 0.10)
	_weather_painter.configure("clear_rift", ARENA_SIZE)

func get_background_path(realm_id: String, time_phase: String, weather: String) -> String:
	return "%s%s_%s_%s.png" % [BACKGROUND_ROOT, realm_id, time_phase, weather]

func get_display_name_for_time(time_phase: String) -> String:
	match time_phase:
		"dawn":
			return "黎明"
		"dusk":
			return "黄昏"
		"night":
			return "深夜"
		"eclipse":
			return "蚀时"
		_:
			return "未知时相"

func get_display_name_for_weather(weather: String) -> String:
	match weather:
		"data_rain":
			return "数据雨"
		"rift_snow":
			return "裂雪"
		"thunderstorm":
			return "雷暴"
		"fog_tide":
			return "雾潮"
		"clear_rift":
			return "晴裂"
		_:
			return "未知天气"

func _load_texture(path: String) -> Texture2D:
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

func _scale_for_texture(tex: Texture2D) -> Vector2:
	var size: Vector2 = tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ONE
	return Vector2(ARENA_SIZE.x / size.x, ARENA_SIZE.y / size.y)

func _tint_for_environment(time_phase: String, weather: String) -> Color:
	var tint: Color = Color(0.03, 0.0, 0.08, 0.12)
	match time_phase:
		"dawn":
			tint = Color(0.08, 0.03, 0.0, 0.08)
		"dusk":
			tint = Color(0.18, 0.06, 0.12, 0.12)
		"night":
			tint = Color(0.0, 0.02, 0.10, 0.22)
		"eclipse":
			tint = Color(0.0, 0.0, 0.0, 0.28)
	match weather:
		"data_rain":
			tint = tint.blend(Color(0.0, 0.65, 0.95, 0.10))
		"rift_snow":
			tint = tint.blend(Color(0.65, 0.82, 1.0, 0.12))
		"thunderstorm":
			tint = tint.blend(Color(0.0, 0.0, 0.12, 0.18))
		"fog_tide":
			tint = tint.blend(Color(0.74, 0.82, 0.92, 0.16))
	return tint
