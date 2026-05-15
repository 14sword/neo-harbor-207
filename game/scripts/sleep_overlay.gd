extends CanvasLayer

signal finished

var _fade_rect: ColorRect
var _phase_label: Label
var _time_label: Label
var _date_label: Label
var _scanline_rect: ColorRect
var _top_line: ColorRect
var _bottom_line: ColorRect
var _tint_rect: ColorRect

var _callback: Callable
var _is_running: bool = false
var _target_phase_name: String = ""
var _tint_color: Color = Color(0, 0, 0, 0)
var _target_phase: int = -1

func _ready():
	layer = 20
	_build_ui()
	_apply_fonts()

func _apply_fonts():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()
	tm.apply_font_to_label(_phase_label, 36)
	tm.apply_font_to_label(_time_label, 18)
	tm.apply_font_to_label(_date_label, 14)
	_time_label.add_theme_color_override("font_color", Color(t["text_color"].r, t["text_color"].g, t["text_color"].b, 0))
	_date_label.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0))

func _build_ui():
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fade_rect)

	_tint_rect = ColorRect.new()
	_tint_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tint_rect.color = Color(0, 0, 0, 0)
	_tint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tint_rect)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	center.add_child(vbox)

	var line_color = _get_accent_color(0.3)

	_top_line = ColorRect.new()
	_top_line.custom_minimum_size = Vector2(400, 1)
	_top_line.color = line_color
	_top_line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_top_line.visible = false
	vbox.add_child(_top_line)

	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 36)
	_phase_label.add_theme_color_override("font_color", Color(0, 0.93, 1, 0))
	_phase_label.visible = false
	vbox.add_child(_phase_label)

	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 18)
	_time_label.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92, 0))
	_time_label.visible = false
	vbox.add_child(_time_label)

	_date_label = Label.new()
	_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_date_label.add_theme_font_size_override("font_size", 14)
	_date_label.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58, 0))
	_date_label.visible = false
	vbox.add_child(_date_label)

	_bottom_line = ColorRect.new()
	_bottom_line.custom_minimum_size = Vector2(400, 1)
	_bottom_line.color = line_color
	_bottom_line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_bottom_line.visible = false
	vbox.add_child(_bottom_line)

	_scanline_rect = ColorRect.new()
	_scanline_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scanline_rect.color = Color(0, 0, 0, 0)
	_scanline_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scanline_rect)

func start_transition(callback: Callable):
	if _is_running:
		return
	_is_running = true
	_callback = callback
	_determine_phase_text()
	_start_sequence()

func _determine_phase_text():
	var phase_name = ""
	var time_str = ""

	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		match dnm.current_phase:
			dnm.DayPhase.DAY, dnm.DayPhase.DUSK:
				if randi() % 2 == 0:
					phase_name = "雨夜"
					time_str = "◈ 21:30"
					_tint_color = Color(0.02, 0.02, 0.12, 0.6)
					_target_phase = dnm.DayPhase.RAIN_NIGHT
				else:
					phase_name = "深夜异常"
					time_str = "◈ 02:15"
					_tint_color = Color(0.08, 0.0, 0.12, 0.7)
					_target_phase = dnm.DayPhase.NIGHT
			dnm.DayPhase.RAIN_NIGHT, dnm.DayPhase.NIGHT:
				phase_name = "白天"
				time_str = "◈ 07:00"
				_tint_color = Color(0.12, 0.1, 0.04, 0.4)
				_target_phase = dnm.DayPhase.DAY
	else:
		phase_name = "时间流逝..."
		time_str = "◈ --:--"
		_tint_color = Color(0, 0, 0, 0.5)
		_target_phase = -1

	_target_phase_name = phase_name
	_phase_label.text = phase_name
	_time_label.text = time_str
	if has_node("/root/WorldCalendar"):
		_date_label.text = "// " + get_node("/root/WorldCalendar").get_date_string()
	else:
		_date_label.text = "// 2087.05.02"

func _start_sequence():
	var tween = create_tween()

	tween.tween_property(_fade_rect, "color", Color(0, 0, 0, 0.6), 0.5)
	tween.parallel().tween_property(_tint_rect, "color", _tint_color, 0.8)
	tween.tween_interval(0.3)
	tween.tween_callback(_show_phase_text)
	tween.tween_interval(2.0)
	tween.tween_callback(_do_switch)
	tween.tween_property(_phase_label, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.parallel().tween_property(_time_label, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.parallel().tween_property(_date_label, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.parallel().tween_property(_top_line, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.parallel().tween_property(_bottom_line, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_property(_tint_rect, "color", Color(0, 0, 0, 0), 0.5)
	tween.parallel().tween_property(_fade_rect, "color", Color(0, 0, 0, 0), 0.6)
	tween.tween_callback(_finish)

func _show_phase_text():
	_phase_label.visible = true
	_time_label.visible = true
	_date_label.visible = true
	_top_line.visible = true
	_bottom_line.visible = true

	_phase_label.modulate = Color(1, 1, 1, 0)
	_time_label.modulate = Color(1, 1, 1, 0)
	_date_label.modulate = Color(1, 1, 1, 0)
	_top_line.modulate = Color(1, 1, 1, 0)
	_bottom_line.modulate = Color(1, 1, 1, 0)

	_scanline_rect.color = Color(0, 0, 0, 0.05)

	_phase_label.scale = Vector2(0.9, 0.9)

	if _target_phase_name == "深夜异常":
		_phase_label.add_theme_color_override("font_color", Color(0.8, 0.2, 1, 1))
		_top_line.color = Color(0.8, 0.2, 1, 0.3)
		_bottom_line.color = Color(0.8, 0.2, 1, 0.3)
	elif _target_phase_name == "白天":
		_phase_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1))
		_top_line.color = Color(1.0, 0.9, 0.6, 0.3)
		_bottom_line.color = Color(1.0, 0.9, 0.6, 0.3)
	else:
		var accent = _get_accent_color(1.0)
		_phase_label.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 1))
		_top_line.color = Color(accent.r, accent.g, accent.b, 0.3)
		_bottom_line.color = Color(accent.r, accent.g, accent.b, 0.3)

	var tween = create_tween()
	tween.tween_property(_phase_label, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.parallel().tween_property(_phase_label, "scale", Vector2(1.0, 1.0), 0.4)
	tween.parallel().tween_property(_time_label, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.parallel().tween_property(_date_label, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.parallel().tween_property(_top_line, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.parallel().tween_property(_bottom_line, "modulate", Color(1, 1, 1, 1), 0.3)

func _do_switch():
	if has_node("/root/WorldCalendar"):
		get_node("/root/WorldCalendar").advance_day()
	if has_node("/root/DayNightManager") and _target_phase >= 0:
		var dnm = get_node("/root/DayNightManager")
		dnm.set_phase(_target_phase)
	elif _callback.is_valid():
		_callback.call()

func _get_accent_color(alpha: float = 1.0) -> Color:
	if has_node("/root/UIThemeManager"):
		var t = get_node("/root/UIThemeManager").get_theme()
		var c = t.get("border_accent", Color(0, 0.93, 1))
		return Color(c.r, c.g, c.b, alpha)
	return Color(0, 0.93, 1, alpha)

func _finish():
	_is_running = false
	finished.emit()
	queue_free()
