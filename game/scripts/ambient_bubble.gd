extends Node2D

enum Style { HOLOGRAM, CRT, ANOMALY, NORMAL }

var _duration: float = 4.0
var _elapsed: float = 0.0
var _style: int = Style.NORMAL
var _pulse_tween: Tween = null

@onready var _panel: PanelContainer = $Panel
@onready var _label: Label = $Panel/Label

func _ready():
	visible = false
	_apply_style()
	_apply_font()

func _apply_font():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	if _label:
		tm.apply_font_to_label(_label, 13)

func setup(text: String, pos: Vector2, style: int = Style.NORMAL, duration: float = 4.0):
	if _label:
		_label.text = text
	global_position = pos
	_style = style
	_duration = duration
	_apply_style()
	visible = true

func _process(delta):
	_elapsed += delta
	position.y -= delta * 8.0
	var remaining = _duration - _elapsed
	if remaining < 1.0:
		modulate.a = max(0, remaining)
	if _elapsed >= _duration:
		if _pulse_tween:
			_pulse_tween.kill()
		queue_free()

func _apply_style():
	if not _panel:
		return
	var style_box = StyleBoxFlat.new()
	style_box.set_corner_radius_all(8)
	style_box.set_border_width_all(2)
	style_box.content_margin_left = 10
	style_box.content_margin_right = 10
	style_box.content_margin_top = 6
	style_box.content_margin_bottom = 6

	match _style:
		Style.HOLOGRAM:
			style_box.bg_color = Color(0.0, 0.25, 0.45, 0.75)
			style_box.border_color = Color(0.0, 0.8, 1.0, 0.8)
			style_box.shadow_color = Color(0, 0.93, 1, 0.15)
			style_box.shadow_size = 4
			if _label:
				_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0, 0.9))
		Style.CRT:
			style_box.bg_color = Color(0.0, 0.12, 0.0, 0.75)
			style_box.border_color = Color(0.0, 0.8, 0.0, 0.6)
			if _label:
				_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 0.9))
		Style.ANOMALY:
			style_box.bg_color = Color(0.18, 0.0, 0.28, 0.75)
			style_box.border_color = Color(0.6, 0.1, 0.9, 0.8)
			style_box.shadow_color = Color(0.8, 0.2, 1, 0.15)
			style_box.shadow_size = 4
			if _label:
				_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0, 0.9))
			_start_anomaly_pulse()
		Style.NORMAL, _:
			if has_node("/root/UIThemeManager"):
				var t = get_node("/root/UIThemeManager").get_theme()
				style_box.bg_color = t.get("ambient_normal_bg", Color(0.08, 0.08, 0.13, 0.7))
				style_box.border_color = t.get("ambient_normal_border", Color(0.5, 0.5, 0.6, 0.5))
				if _label:
					_label.add_theme_color_override("font_color", t.get("ambient_normal_text", Color(0.9, 0.9, 0.95, 0.85)))
			else:
				style_box.bg_color = Color(0.08, 0.08, 0.13, 0.7)
				style_box.border_color = Color(0.5, 0.5, 0.6, 0.5)
				if _label:
					_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 0.85))

	_panel.add_theme_stylebox_override("panel", style_box)

func _start_anomaly_pulse():
	if not _panel:
		return
	if _pulse_tween:
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_panel, "modulate", Color(1.1, 0.8, 1.2, 1), 0.6)
	_pulse_tween.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.6)
