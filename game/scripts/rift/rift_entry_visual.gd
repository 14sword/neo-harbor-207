extends Node2D

@export var radius: float = 96.0
@export var phase_scale: float = 1.0

var _time: float = 0.0
var _shards: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	z_index = 32
	_rng.randomize()
	_rebuild_shards()
	set_process(true)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func set_gate_phase(phase: int) -> void:
	phase_scale = 1.0 + clampi(phase, 0, 4) * 0.08
	_rebuild_shards()

func _rebuild_shards() -> void:
	_shards.clear()
	var count: int = int(12 * phase_scale)
	for i in range(count):
		var angle: float = TAU * float(i) / max(1.0, float(count)) + _rng.randf_range(-0.12, 0.12)
		_shards.append({
			"angle": angle,
			"distance": _rng.randf_range(radius * 0.52, radius * 1.18),
			"size": _rng.randf_range(4.0, 10.0),
			"speed": _rng.randf_range(0.45, 0.9),
			"color": Color(0.15, 0.95, 1.0, _rng.randf_range(0.36, 0.72)) if i % 2 == 0 else Color(1.0, 0.18, 0.92, _rng.randf_range(0.32, 0.68)),
		})

func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_time * 2.6)
	var cyan := Color(0.0, 0.95, 1.0, 0.42 + pulse * 0.18)
	var magenta := Color(1.0, 0.12, 0.92, 0.34 + (1.0 - pulse) * 0.16)
	var core := Color(0.92, 0.86, 1.0, 0.18)
	var basin_radius: float = radius * phase_scale

	_draw_flat_ellipse(Vector2.ZERO, Vector2(basin_radius * 1.15, basin_radius * 0.48), Color(0.0, 0.0, 0.0, 0.22))
	draw_arc(Vector2.ZERO, basin_radius * 0.64, 0.0, TAU, 96, cyan, 3.0)
	draw_arc(Vector2.ZERO, basin_radius * 0.79, _time * 0.4, TAU + _time * 0.4, 96, magenta, 2.4)
	draw_circle(Vector2.ZERO, basin_radius * 0.36, core)
	draw_arc(Vector2.ZERO, basin_radius * (0.92 + pulse * 0.08), -0.15, PI + 0.15, 72, Color(0.22, 0.95, 1.0, 0.22), 5.0)

	for i in range(10):
		var angle: float = TAU * float(i) / 10.0 + sin(_time * 0.7 + i) * 0.04
		var start := Vector2(cos(angle), sin(angle) * 0.52) * basin_radius * 0.74
		var end := Vector2(cos(angle), sin(angle) * 0.52) * basin_radius * (1.12 + 0.08 * pulse)
		var crack_color := cyan if i % 2 == 0 else magenta
		crack_color.a *= 0.48
		draw_line(start, end, crack_color, 1.7)

	for shard in _shards:
		var angle: float = float(shard["angle"]) + _time * float(shard["speed"]) * 0.18
		var dist: float = float(shard["distance"]) + sin(_time * 1.7 + angle) * 5.0
		var pos := Vector2(cos(angle), sin(angle) * 0.62) * dist
		var size: float = float(shard["size"])
		var color: Color = shard["color"]
		color.a *= 0.72 + pulse * 0.28
		draw_polygon([
			pos + Vector2(0, -size),
			pos + Vector2(size * 0.75, 0),
			pos + Vector2(0, size),
			pos + Vector2(-size * 0.65, 0),
		], [color])

func _draw_flat_ellipse(center: Vector2, half_size: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(48):
		var angle: float = TAU * float(i) / 48.0
		points.append(center + Vector2(cos(angle) * half_size.x, sin(angle) * half_size.y))
	draw_colored_polygon(points, color)
