extends CanvasLayer

var _bg_overlay: ColorRect
var _main_panel: PanelContainer
var _title_label: Label
var _key_labels: Array[Label] = []
var _value_labels: Array[Label] = []
var _progress_bars: Array[PanelContainer] = []
var _close_hint: Label
var _flicker_timer: float = 0.0
var _is_anomaly: bool = false
var _watermark: Label
var _bg_image: TextureRect

signal closed

func _ready():
	layer = 12
	_is_anomaly = _check_anomaly()
	_build_ui()
	_populate_data()
	_apply_fonts()
	_apply_theme()
	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)

func _apply_fonts():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	tm.apply_font_to_label(_title_label, 18)
	if has_node("/root/MediaManager"):
		get_node("/root/MediaManager").image_ready.connect(_on_media_image_ready)
	for lbl in _key_labels:
		tm.apply_font_to_label(lbl, 13)
	for lbl in _value_labels:
		tm.apply_font_to_label(lbl, 13)
	tm.apply_font_to_label(_close_hint, 11)
	tm.apply_font_to_label(_watermark, 10)

func _on_phase_changed(_new_phase):
	_is_anomaly = _check_anomaly()
	_apply_theme()

func _apply_theme():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()

	if _main_panel:
		var style = tm.make_panel_style()
		_main_panel.add_theme_stylebox_override("panel", style)

	if _title_label:
		if _is_anomaly:
			_title_label.add_theme_color_override("font_color", Color(0.8, 0.2, 1))
		else:
			_title_label.add_theme_color_override("font_color", t["title_color"])

	if _close_hint:
		_close_hint.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.6))

	if _watermark:
		_watermark.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.4))

	for lbl in _key_labels:
		lbl.add_theme_color_override("font_color", t["secondary_color"])

	for lbl in _value_labels:
		lbl.add_theme_color_override("font_color", t["text_color"])

func _check_anomaly() -> bool:
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		return dnm.current_phase == dnm.DayPhase.NIGHT or dnm.current_phase == dnm.DayPhase.RAIN_NIGHT
	return false

func _build_ui():
	_bg_overlay = ColorRect.new()
	_bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_overlay.color = Color(0, 0, 0, 0.4)
	_bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg_overlay)

	_bg_image = TextureRect.new()
	_bg_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	_bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bg_image.modulate = Color(1, 1, 1, 0.15)
	_bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_bg_image()
	add_child(_bg_image)

	_main_panel = PanelContainer.new()
	_main_panel.set_anchors_preset(Control.PRESET_CENTER)
	_main_panel.offset_left = -190
	_main_panel.offset_top = -140
	_main_panel.offset_right = 190
	_main_panel.offset_bottom = 140
	var panel_style = StyleBoxFlat.new()
	if _is_anomaly:
		panel_style.bg_color = Color(0.06, 0.02, 0.09, 0.94)
		panel_style.border_color = Color(0.8, 0.2, 1, 0.6)
		panel_style.shadow_color = Color(0.8, 0.2, 1, 0.2)
	else:
		panel_style.bg_color = Color(0.04, 0.055, 0.1, 0.94)
		panel_style.border_color = Color(0, 0.93, 1, 0.5)
		panel_style.shadow_color = Color(0, 0.93, 1, 0.2)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_size = 10
	_main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_main_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	_main_panel.add_child(vbox)

	var title_bar = PanelContainer.new()
	var tb_style = StyleBoxFlat.new()
	if _is_anomaly:
		tb_style.bg_color = Color(0.04, 0.01, 0.06, 0.9)
	else:
		tb_style.bg_color = Color(0.024, 0.04, 0.08, 0.9)
	tb_style.set_corner_radius_all(0)
	tb_style.content_margin_left = 14
	tb_style.content_margin_right = 14
	tb_style.content_margin_top = 10
	tb_style.content_margin_bottom = 10
	title_bar.add_theme_stylebox_override("panel", tb_style)
	vbox.add_child(title_bar)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	if _is_anomaly:
		_title_label.text = "◈ 异常数据监测"
		_title_label.add_theme_color_override("font_color", Color(0.8, 0.2, 1))
	else:
		_title_label.text = "◈ 电子符纸"
		_title_label.add_theme_color_override("font_color", Color(0, 0.93, 1))
	title_bar.add_child(_title_label)

	var title_sep = ColorRect.new()
	title_sep.custom_minimum_size = Vector2(0, 1)
	if _is_anomaly:
		title_sep.color = Color(0.8, 0.2, 1, 0.3)
	else:
		title_sep.color = Color(0, 0.93, 1, 0.3)
	title_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_sep)

	var content_margin = MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 14)
	content_margin.add_theme_constant_override("margin_right", 14)
	content_margin.add_theme_constant_override("margin_top", 10)
	content_margin.add_theme_constant_override("margin_bottom", 6)
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content_margin)

	var data_vbox = VBoxContainer.new()
	data_vbox.add_theme_constant_override("separation", 6)
	content_margin.add_child(data_vbox)

	for i in range(5):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var key_label = Label.new()
		key_label.add_theme_font_size_override("font_size", 13)
		if _is_anomaly:
			key_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.8))
		else:
			key_label.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58))
		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(key_label)
		_key_labels.append(key_label)

		var value_label = Label.new()
		value_label.add_theme_font_size_override("font_size", 13)
		if _is_anomaly:
			value_label.add_theme_color_override("font_color", Color(0.88, 0.7, 1))
		else:
			value_label.add_theme_color_override("font_color", Color(0.88, 0.89, 0.94))
		row.add_child(value_label)
		_value_labels.append(value_label)

		data_vbox.add_child(row)

		if _is_anomaly and (i == 0 or i == 1):
			var bar_container = PanelContainer.new()
			var bar_bg = StyleBoxFlat.new()
			bar_bg.bg_color = Color(0.1, 0.05, 0.15, 0.8)
			bar_bg.set_corner_radius_all(3)
			bar_container.add_theme_stylebox_override("panel", bar_bg)
			bar_container.custom_minimum_size = Vector2(80, 8)
			bar_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(bar_container)

			var bar_fill = PanelContainer.new()
			var fill_style = StyleBoxFlat.new()
			fill_style.bg_color = Color(0.8, 0.2, 1, 0.8)
			fill_style.set_corner_radius_all(3)
			bar_fill.add_theme_stylebox_override("panel", fill_style)
			bar_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
			bar_fill.anchor_right = 0.6 if i == 0 else 0.88
			bar_container.add_child(bar_fill)
			_progress_bars.append(bar_container)

	var bottom_sep = ColorRect.new()
	bottom_sep.custom_minimum_size = Vector2(0, 1)
	if _is_anomaly:
		bottom_sep.color = Color(0.8, 0.2, 1, 0.2)
	else:
		bottom_sep.color = Color(0, 0.93, 1, 0.2)
	bottom_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(bottom_sep)

	_watermark = Label.new()
	var date_str = "DATAWHALE 安全系统"
	if has_node("/root/WorldCalendar"):
		date_str = "DATAWHALE 安全系统 | " + get_node("/root/WorldCalendar").get_date_string()
	_watermark.text = date_str
	_watermark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_watermark.add_theme_font_size_override("font_size", 10)
	_watermark.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58, 0.4))
	var wm_margin = MarginContainer.new()
	wm_margin.add_theme_constant_override("margin_bottom", 6)
	wm_margin.add_child(_watermark)
	vbox.add_child(wm_margin)

	_close_hint = Label.new()
	_close_hint.text = "按 [ESC] 关闭"
	_close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_close_hint.add_theme_font_size_override("font_size", 11)
	_close_hint.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58))
	var hint_margin = MarginContainer.new()
	hint_margin.add_theme_constant_override("margin_bottom", 8)
	hint_margin.add_child(_close_hint)
	vbox.add_child(hint_margin)

func _populate_data():
	if _is_anomaly:
		_key_labels[0].text = "观测等级:"
		_key_labels[1].text = "现实稳定度:"
		_key_labels[2].text = "异常信号:"
		_key_labels[3].text = "紫雨概率:"
		_key_labels[4].text = "数据状态:"

		var obs_level = 2 + randi() % 3
		var fill_ratio = float(obs_level) / 5.0
		if _progress_bars.size() > 0 and _progress_bars[0].get_child_count() > 0:
			var fill = _progress_bars[0].get_child(0) as PanelContainer
			if fill:
				fill.anchor_right = fill_ratio

		var stability = 80.0 + randf() * 15.0
		if _progress_bars.size() > 1 and _progress_bars[1].get_child_count() > 0:
			var fill2 = _progress_bars[1].get_child(0) as PanelContainer
			if fill2:
				fill2.anchor_right = stability / 100.0

		_update_anomaly_values()
	else:
		_key_labels[0].text = "状态:"
		_value_labels[0].text = "正常"
		_value_labels[0].add_theme_color_override("font_color", Color(0.3, 1.0, 0.57))

		_key_labels[1].text = "现实稳定度:"
		_value_labels[1].text = "98.7%"

		_key_labels[2].text = "异常信号:"
		_value_labels[2].text = "无"
		_value_labels[2].add_theme_color_override("font_color", Color(0.3, 1.0, 0.57))

		_key_labels[3].text = "紫雨概率:"
		_value_labels[3].text = "0%"

		_key_labels[4].text = "备注:"
		_value_labels[4].text = "一张普通的电子符纸"
		_value_labels[4].add_theme_color_override("font_color", Color(0.42, 0.44, 0.58))

func _repeat_char(char: String, count: int) -> String:
	var result = ""
	for i in range(count):
		result += char
	return result

func _update_anomaly_values():
	var obs_level = 2 + randi() % 3
	_value_labels[0].text = _repeat_char("▓", obs_level) + _repeat_char("░", 5 - obs_level)

	var stability = 80.0 + randf() * 15.0
	_value_labels[1].text = "%.1f%%" % stability

	_value_labels[2].text = "%d处活跃" % (2 + randi() % 4)
	_value_labels[2].add_theme_color_override("font_color", Color(1.0, 0.4, 0.6))

	_value_labels[3].text = "3%"

	_value_labels[4].text = "▓▓▓ 数据更新中 ▓▓▓"

	if _progress_bars.size() > 0 and _progress_bars[0].get_child_count() > 0:
		var fill = _progress_bars[0].get_child(0) as PanelContainer
		if fill:
			fill.anchor_right = float(obs_level) / 5.0

	if _progress_bars.size() > 1 and _progress_bars[1].get_child_count() > 0:
		var fill2 = _progress_bars[1].get_child(0) as PanelContainer
		if fill2:
			fill2.anchor_right = stability / 100.0

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_close()
		return

	if _is_anomaly:
		_flicker_timer += delta
		if _flicker_timer > 0.5:
			_flicker_timer = 0.0
			if randf() < 0.3:
				_value_labels[4].modulate = Color(1, 1, 1, 0.3)
			else:
				_value_labels[4].modulate = Color(1, 1, 1, 1)

			if randf() < 0.2:
				_update_anomaly_values()

func _on_close():
	closed.emit()
	queue_free()

func _load_bg_image():
	if not _bg_image:
		return
	if has_node("/root/MediaManager"):
		var mm = get_node("/root/MediaManager")
		var cat = "anomaly" if _is_anomaly else "talisman"
		var tex = mm.get_random_image(cat)
		if tex:
			_bg_image.texture = tex
			_bg_image.visible = true
		else:
			_bg_image.visible = false
	else:
		_bg_image.visible = false

func _on_media_image_ready(category: String, texture: Texture2D):
	if not is_instance_valid(_bg_image):
		return
	if category != "talisman" and category != "anomaly":
		return
	if texture and _bg_image.visible:
		var tween = create_tween()
		tween.tween_property(_bg_image, "modulate", Color(1, 1, 1, 0.20), 0.3)
		tween.tween_callback(func(): _bg_image.texture = texture)
