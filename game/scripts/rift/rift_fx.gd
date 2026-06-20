class_name RiftFX
extends Node2D

var effect_type: String = "pulse"
var radius: float = 48.0
var duration: float = 0.35
var color: Color = Color(0, 0.9, 1.0, 0.7)
var text: String = ""
var drift: Vector2 = Vector2.ZERO

var _elapsed: float = 0.0
var _label: Label = null

static func warning(parent: Node, pos: Vector2, warn_radius: float, warn_duration: float, warn_color: Color = Color(1.0, 0.25, 0.18, 0.65)) -> RiftFX:
	var fx := RiftFX.new()
	fx.effect_type = "warning"
	fx.global_position = pos
	fx.radius = warn_radius
	fx.duration = warn_duration
	fx.color = warn_color
	parent.add_child(fx)
	return fx

static func impact(parent: Node, pos: Vector2, impact_radius: float, impact_color: Color = Color(0, 0.95, 1.0, 0.8)) -> RiftFX:
	var fx := RiftFX.new()
	fx.effect_type = "impact"
	fx.global_position = pos
	fx.radius = impact_radius
	fx.duration = 0.28
	fx.color = impact_color
	parent.add_child(fx)
	return fx

static func damage_number(parent: Node, pos: Vector2, amount: int, number_color: Color = Color(1.0, 0.92, 0.35, 1.0)) -> RiftFX:
	var fx := RiftFX.new()
	fx.effect_type = "text"
	fx.global_position = pos
	fx.duration = 0.75
	fx.color = number_color
	fx.text = str(amount)
	fx.drift = Vector2(randf_range(-12.0, 12.0), -44.0)
	parent.add_child(fx)
	return fx

func _ready() -> void:
	z_index = 80
	if effect_type == "text":
		_label = Label.new()
		_label.text = text
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.position = Vector2(-42, -14)
		_label.size = Vector2(84, 28)
		_label.add_theme_font_size_override("font_size", 18)
		_label.add_theme_color_override("font_color", color)
		_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		_label.add_theme_constant_override("shadow_offset_x", 1)
		_label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(_label)
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = clamp(_elapsed / max(duration, 0.01), 0.0, 1.0)
	if effect_type == "text":
		position += drift * delta
		if _label:
			_label.modulate.a = 1.0 - t
	else:
		queue_redraw()
	if _elapsed >= duration:
		queue_free()

func _draw() -> void:
	var t: float = clamp(_elapsed / max(duration, 0.01), 0.0, 1.0)
	match effect_type:
		"warning":
			var ring_color := color
			ring_color.a *= 0.65 + sin(t * TAU * 4.0) * 0.2
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, ring_color, 4.0)
			var fill := color
			fill.a *= 0.13 + 0.06 * sin(t * TAU * 3.0)
			draw_circle(Vector2.ZERO, radius, fill)
		"impact":
			var ring := color
			ring.a *= 1.0 - t
			draw_arc(Vector2.ZERO, radius * (0.35 + t), 0.0, TAU, 80, ring, 5.0)
			var fill := color
			fill.a *= 0.25 * (1.0 - t)
			draw_circle(Vector2.ZERO, radius * (0.25 + t * 0.65), fill)
		_:
			var pulse := color
			pulse.a *= 1.0 - t
			draw_circle(Vector2.ZERO, radius * (0.4 + t), pulse)
