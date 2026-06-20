extends CanvasLayer

var _bg_overlay: ColorRect
var _outer_frame: PanelContainer
var _tv_frame: PanelContainer
var _channel_label: Label
var _signal_bars: HBoxContainer
var _news_text: RichTextLabel
var _static_noise: ColorRect
var _hint_label: Label
var _hint_bg: PanelContainer
var _scanline_rect: ColorRect
var _crt_lines: ColorRect
var _flash_rect: ColorRect
var _news_image: TextureRect
var _loading_label: Label

var _news_pool: Array[Dictionary] = []
var _current_index: int = 0
var _is_showing_static: bool = false
var _static_timer: float = 0.0
var _is_night: bool = false
var _pulse_tween: Tween = null
var _date_label: Label

signal closed

func _ready():
	layer = 15
	_is_night = _check_night()
	_build_ui()
	_build_news_pool()
	_show_current()
	_apply_style()
	_apply_fonts()
	if _is_night:
		_start_night_pulse()
	if has_node("/root/MediaManager"):
		get_node("/root/MediaManager").image_ready.connect(_on_media_image_ready)
	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)

func _apply_fonts():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	tm.apply_font_to_label(_channel_label, 16)
	tm.apply_font_to_rich_text(_news_text, 14)
	tm.apply_font_to_label(_hint_label, 13)

func _check_night() -> bool:
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		return dnm.current_phase == dnm.DayPhase.NIGHT or dnm.current_phase == dnm.DayPhase.RAIN_NIGHT
	return false

func _build_ui():
	_bg_overlay = ColorRect.new()
	_bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_overlay.color = Color(0, 0, 0, 0.6)
	_bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg_overlay)

	_outer_frame = PanelContainer.new()
	_outer_frame.set_anchors_preset(Control.PRESET_CENTER)
	_outer_frame.offset_left = -400
	_outer_frame.offset_top = -260
	_outer_frame.offset_right = 400
	_outer_frame.offset_bottom = 260
	var outer_style = StyleBoxFlat.new()
	outer_style.bg_color = Color(0.1, 0.1, 0.18, 0.98)
	outer_style.border_color = Color(0.15, 0.15, 0.25, 0.8)
	outer_style.set_border_width_all(6)
	outer_style.set_corner_radius_all(12)
	outer_style.shadow_color = Color(0, 0, 0, 0.3)
	outer_style.shadow_size = 4
	_outer_frame.add_theme_stylebox_override("panel", outer_style)
	add_child(_outer_frame)

	_tv_frame = PanelContainer.new()
	var tv_style = StyleBoxFlat.new()
	tv_style.bg_color = Color(0.03, 0.04, 0.08, 0.95)
	tv_style.border_color = Color(0, 0.93, 1, 0.5)
	tv_style.set_border_width_all(2)
	tv_style.set_corner_radius_all(8)
	_tv_frame.add_theme_stylebox_override("panel", tv_style)
	_outer_frame.add_child(_tv_frame)

	var frame_vbox = VBoxContainer.new()
	frame_vbox.add_theme_constant_override("separation", 0)
	_tv_frame.add_child(frame_vbox)

	var channel_bar = PanelContainer.new()
	var ch_bar_style = StyleBoxFlat.new()
	ch_bar_style.bg_color = Color(0.024, 0.04, 0.08, 0.9)
	ch_bar_style.set_corner_radius_all(0)
	ch_bar_style.content_margin_left = 14
	ch_bar_style.content_margin_right = 14
	ch_bar_style.content_margin_top = 8
	ch_bar_style.content_margin_bottom = 8
	channel_bar.add_theme_stylebox_override("panel", ch_bar_style)
	frame_vbox.add_child(channel_bar)

	var channel_hbox = HBoxContainer.new()
	channel_hbox.add_theme_constant_override("separation", 8)
	channel_bar.add_child(channel_hbox)

	_channel_label = Label.new()
	_channel_label.add_theme_font_size_override("font_size", 16)
	_channel_label.add_theme_color_override("font_color", Color(0, 0.93, 1))
	_channel_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	channel_hbox.add_child(_channel_label)

	_signal_bars = HBoxContainer.new()
	_signal_bars.add_theme_constant_override("separation", 2)
	_signal_bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in range(3):
		var bar = ColorRect.new()
		bar.custom_minimum_size = Vector2(4, 6 + i * 3)
		bar.color = Color(0.3, 0.9, 0.3, 0.8)
		_signal_bars.add_child(bar)
	channel_hbox.add_child(_signal_bars)

	_date_label = Label.new()
	_date_label.add_theme_font_size_override("font_size", 11)
	_date_label.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58))
	_date_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	channel_hbox.add_child(_date_label)
	_update_date_label()

	var ch_sep = ColorRect.new()
	ch_sep.custom_minimum_size = Vector2(0, 1)
	ch_sep.color = Color(0, 0.93, 1, 0.3)
	ch_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_vbox.add_child(ch_sep)

	var content_margin = MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 14)
	content_margin.add_theme_constant_override("margin_right", 14)
	content_margin.add_theme_constant_override("margin_top", 10)
	content_margin.add_theme_constant_override("margin_bottom", 10)
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame_vbox.add_child(content_margin)

	_news_image = TextureRect.new()
	_news_image.custom_minimum_size = Vector2(0, 240)
	_news_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	_news_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_news_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_child(_news_image)

	_loading_label = Label.new()
	_loading_label.text = "▸ 信号接收中..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_size_override("font_size", 12)
	_loading_label.add_theme_color_override("font_color", Color(0, 0.93, 1, 0.5))
	_loading_label.visible = false
	content_margin.add_child(_loading_label)

	_news_text = RichTextLabel.new()
	_news_text.bbcode_enabled = true
	_news_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_news_text.add_theme_font_size_override("normal_font_size", 14)
	_news_text.add_theme_color_override("default_color", Color(0.85, 0.9, 0.85))
	content_margin.add_child(_news_text)

	_crt_lines = ColorRect.new()
	_crt_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_crt_lines.color = Color(0, 0, 0, 0)
	_crt_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tv_frame.add_child(_crt_lines)

	_static_noise = ColorRect.new()
	_static_noise.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_static_noise.color = Color(1, 1, 1, 0)
	_static_noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tv_frame.add_child(_static_noise)

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tv_frame.add_child(_flash_rect)

	_hint_bg = PanelContainer.new()
	_hint_bg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_bg.offset_left = -200
	_hint_bg.offset_top = -55
	_hint_bg.offset_right = 200
	_hint_bg.offset_bottom = -15
	var hint_style = StyleBoxFlat.new()
	hint_style.bg_color = Color(0.024, 0.04, 0.08, 0.85)
	hint_style.set_corner_radius_all(8)
	hint_style.set_border_width_all(1)
	hint_style.border_color = Color(0, 0.93, 1, 0.2)
	_hint_bg.add_theme_stylebox_override("panel", hint_style)
	add_child(_hint_bg)

	_hint_label = Label.new()
	_hint_label.text = "按 [E] 换台 | 按 [ESC] 关闭"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58))
	_hint_bg.add_child(_hint_label)

	_scanline_rect = ColorRect.new()
	_scanline_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scanline_rect.color = Color(0, 0, 0, 0.04)
	_scanline_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scanline_rect)

	_outer_frame.modulate = Color(1, 1, 1, 0)
	_outer_frame.scale = Vector2(0.95, 0.95)
	var open_tween = create_tween()
	open_tween.tween_property(_outer_frame, "modulate", Color(1, 1, 1, 1), 0.15)
	open_tween.parallel().tween_property(_outer_frame, "scale", Vector2(1, 1), 0.15)

func _build_news_pool():
	var phase = _get_phase_key()
	_news_pool.clear()
	if has_node("/root/DailyWorldGenerator"):
		var dwg = get_node("/root/DailyWorldGenerator")
		if dwg.has_method("get_daily_news_items"):
			_append_news_items(dwg.get_daily_news_items(phase))
	if _news_pool.is_empty():
		_append_news_items(_get_fallback_news_pool(phase))
	_current_index = 0

func _append_news_items(items: Array) -> void:
	for item in items:
		if item is Dictionary:
			_news_pool.append(item)

func _get_phase_key() -> String:
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		match dnm.current_phase:
			dnm.DayPhase.NIGHT:
				return "night"
			dnm.DayPhase.RAIN_NIGHT:
				return "rain"
			_:
				return "day"
	return "day"

func _get_fallback_news_pool(phase: String) -> Array:
	match phase:
		"day":
			return [
				{"channel": "◆ CH-12 天气频道", "title": "今日天气档案", "text": "天气数据接收中，城市运行稳定。", "image_category": "tv_weather", "severity": "normal"},
				{"channel": "◆ CH-07 都市新闻", "title": "城市运行简报", "text": "公共终端同步完成，街区服务正常开放。", "image_category": "tv_city", "severity": "normal"},
				{"channel": "◆ CH-03 生活频道", "title": "社区生活", "text": "便利店和茶饮店推出今日推荐。", "image_category": "tv_life", "severity": "normal"},
			]
		"rain":
			return [
				{"channel": "◆ CH-12 天气频道", "title": "雨夜预警", "text": "雨势增强，建议减少外出并保护电子设备。", "image_category": "tv_weather", "severity": "warning"},
				{"channel": "◆ CH-19 交通频道", "title": "交通调整", "text": "高架列车与无人机配送路线进入雨夜模式。", "image_category": "tv_traffic", "severity": "warning"},
				{"channel": "◆ CH-03 生活频道", "title": "雨夜服务", "text": "便利店配送窗口保持开放。", "image_category": "tv_life", "severity": "normal"},
			]
		"night":
			return [
				{"channel": "◆ CH-?? 异常播报", "title": "信号中断", "text": "监测图层出现短暂空白，请勿关闭终端。", "image_category": "tv_anomaly", "severity": "warning"},
				{"channel": "◆ CH-12 天气频道", "title": "深夜天气", "text": "气象图层进入低功耗转播。", "image_category": "tv_weather", "severity": "normal"},
				{"channel": "◆ CH-03 生活频道", "title": "深夜服务", "text": "街角便利店仍在营业。", "image_category": "tv_life", "severity": "normal"},
			]
	return []

func _show_current():
	if _news_pool.is_empty():
		return
	var item = _news_pool[_current_index]
	_channel_label.text = item.get("channel", "◆ CH-07 都市新闻")
	_news_text.text = _format_news_text(item)
	_load_news_image()

func _format_news_text(item: Dictionary) -> String:
	var title = item.get("title", "")
	var body = item.get("text", "")
	if title.is_empty():
		return body
	var title_color = "#CC33FF" if item.get("severity", "normal") == "warning" else "#00EEFF"
	return "[color=%s]%s[/color]\n%s" % [title_color, title, body]

func _load_news_image():
	if not _news_image:
		return
	if has_node("/root/MediaManager"):
		var mm = get_node("/root/MediaManager")
		var cat = _get_image_category_for_channel()
		var tex = mm.get_random_image(cat)
		if tex:
			_news_image.texture = tex
			_news_image.visible = true
			if _loading_label:
				_loading_label.visible = false
		else:
			_news_image.visible = false
			if _loading_label:
				_loading_label.visible = true
	else:
		_news_image.visible = false

func _get_image_category_for_channel() -> String:
	if _news_pool.is_empty():
		return "tv_city"
	var item = _news_pool[_current_index]
	var explicit_category = item.get("image_category", "")
	if not explicit_category.is_empty():
		return explicit_category
	var channel = item.get("channel", "")
	if "天气" in channel:
		return "tv_weather"
	if _is_night:
		if "异常" in channel or "??" in channel:
			return "tv_anomaly"
		return "tv_city"
	if "交通" in channel:
		return "tv_traffic"
	if "生活" in channel:
		return "tv_life"
	if "都市" in channel:
		return "tv_city"
	return "tv_city"

func _update_date_label():
	if not _date_label:
		return
	if has_node("/root/WorldCalendar"):
		_date_label.text = "  " + get_node("/root/WorldCalendar").get_short_date()
	else:
		_date_label.text = ""

func _apply_style():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()

	if _tv_frame:
		var tv_style = StyleBoxFlat.new()
		tv_style.bg_color = t.get("scroll_bg", t["card_bg"])
		tv_style.border_color = t["border_accent"]
		tv_style.set_border_width_all(2)
		tv_style.set_corner_radius_all(8)
		_tv_frame.add_theme_stylebox_override("panel", tv_style)

	if _outer_frame:
		var outer_style = StyleBoxFlat.new()
		outer_style.bg_color = t["panel_bg"]
		outer_style.border_color = t["panel_border"]
		outer_style.set_border_width_all(6)
		outer_style.set_corner_radius_all(12)
		outer_style.shadow_color = t["panel_shadow"]
		outer_style.shadow_size = 4
		_outer_frame.add_theme_stylebox_override("panel", outer_style)

	if _channel_label:
		_channel_label.add_theme_color_override("font_color", t["title_color"])

	if _date_label:
		_date_label.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.6))

	if _hint_label:
		_hint_label.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.6))

	if _news_text:
		_news_text.add_theme_color_override("default_color", t["text_color"])

	if _signal_bars:
		var bar_color = t["success_color"] if not _is_night else Color(0.8, 0.2, 1, 0.8)
		for bar in _signal_bars.get_children():
			bar.color = bar_color

func _on_phase_changed(_new_phase):
	_is_night = _check_night()
	_build_news_pool()
	_show_current()
	_update_date_label()
	_apply_style()

func _start_night_pulse():
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_tv_frame, "modulate", Color(0.9, 0.7, 1.1, 1), 1.2)
	_pulse_tween.tween_property(_tv_frame, "modulate", Color(1, 1, 1, 1), 1.2)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_close()
		return

	if Input.is_action_just_pressed("interact"):
		_switch_channel()

	if _is_showing_static:
		_static_timer -= delta
		_static_noise.color = Color(randf(), randf(), randf(), randf() * 0.6)
		if _static_timer <= 0:
			_is_showing_static = false
			_static_noise.color = Color(1, 1, 1, 0)
			_show_current()

func _switch_channel():
	_current_index = (_current_index + 1) % _news_pool.size()

	_flash_rect.color = Color(1, 1, 1, 0.6)
	var tween = create_tween()
	tween.tween_property(_flash_rect, "color", Color(1, 1, 1, 0), 0.15)

	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if (dnm.current_phase == dnm.DayPhase.NIGHT or dnm.current_phase == dnm.DayPhase.RAIN_NIGHT) and randf() < 0.3:
			_trigger_static()
			return

	_show_current()

func _trigger_static():
	_is_showing_static = true
	_static_timer = randf_range(0.3, 0.8)
	_channel_label.text = "◆ CH-?? 信号干扰"
	_news_text.text = ""

func _on_close():
	if _pulse_tween:
		_pulse_tween.kill()
	closed.emit()
	queue_free()

func _on_media_image_ready(category: String, texture: Texture2D):
	if not is_instance_valid(_news_image):
		return
	var valid_cats = ["weather", "anomaly", "surveillance", "ads", "city_day", "city_rain", "city_night", "tv_weather", "tv_city", "tv_life", "tv_traffic", "tv_anomaly"]
	if category not in valid_cats:
		return
	if texture and _news_image.visible:
		var tween = create_tween()
		tween.tween_property(_news_image, "modulate:a", 0.0, 0.12)
		tween.tween_callback(func(): _news_image.texture = texture)
		tween.tween_property(_news_image, "modulate:a", 1.0, 0.12)
		if _loading_label:
			_loading_label.visible = false
