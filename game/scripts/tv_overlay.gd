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
	var phase = "day"
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		match dnm.current_phase:
			dnm.DayPhase.NIGHT:
				phase = "night"
			dnm.DayPhase.RAIN_NIGHT:
				phase = "rain"
			_:
				phase = "day"

	match phase:
		"day":
			_news_pool = [
				{"channel": "◆ CH-07 都市新闻", "text": "[color=#00EEFF]DATAWHALE[/color] 最新AI模型通过图灵测试，引发业界热议。专家表示这标志着人工智能进入新纪元。"},
				{"channel": "◆ CH-12 天气频道", "text": "今日天气晴朗，紫外线指数中等。建议外出时佩戴防蓝光眼镜。明日多云转雨，夜间有雷暴预警。"},
				{"channel": "◆ CH-03 生活频道", "text": "未来茶楼新品上市：全息奶茶，融合传统与科技。首杯半价，欢迎品尝。"},
				{"channel": "◆ CH-07 都市新闻", "text": "新城区商业综合体今日开放，内含全息影院和无人机配送中心。首日客流预计突破5万。"},
				{"channel": "◆ CH-19 交通频道", "text": "高架列车全线正常运行，预计客流高峰17:00-19:00。建议错峰出行。"},
				{"channel": "◆ CH-03 生活频道", "text": "赛博街区新开拉面店「霓虹面馆」，老板据说是退役黑客。招牌全息拉面视觉效果满分。"},
				{"channel": "◆ CH-07 都市新闻", "text": "城市安全指数本月上升3个百分点。网络犯罪率下降7%，但异常事件报告同比增加12%。"},
			]
		"rain":
			_news_pool = [
				{"channel": "◆ CH-07 都市新闻", "text": "雷暴预警：今晚雷暴概率67%，建议减少外出。电子设备请做好防护措施。"},
				{"channel": "◆ CH-12 天气频道", "text": "雨势预计持续至凌晨3点，注意电子设备防护。明日天气多云转晴。"},
				{"channel": "◆ CH-03 生活频道", "text": "深夜便利店推出雨夜配送服务，30分钟送达。配送费全免。"},
				{"channel": "◆ CH-19 交通频道", "text": "地铁运行间隔临时调整为8分钟，请耐心等待。高架列车维持正常运行。"},
				{"channel": "◆ CH-07 都市新闻", "text": "区域3临时停电，原因不明。电力管理局正在排查，预计3小时内恢复。"},
			]
		"night":
			_news_pool = [
				{"channel": "◆ CH-?? 未知频道", "text": "[color=#CC33FF]▓▓▓ 信号中断 ▓▓▓ 信号中断 ▓▓▓[/color]"},
				{"channel": "◆ CH-07 都市新闻", "text": "[color=#CC33FF]区域3临时停电，原因不明。请保持冷静。请勿关闭终端。[/color]"},
				{"channel": "◆ CH-?? 异常播报", "text": "[color=#CC33FF]观测等级已更新。请勿关闭终端。重复。请勿关闭终端。[/color]"},
				{"channel": "◆ CH-12 天气频道", "text": "紫雨概率：3%。无需特殊防护。气象中心将持续监测。"},
				{"channel": "◆ CH-03 生活频道", "text": "深夜食堂仍在营业。老板说今晚的客人比平时少。隔壁便利店的灯光忽明忽暗。"},
			]

	if has_node("/root/DailyWorldGenerator"):
		var dwg = get_node("/root/DailyWorldGenerator")
		var weather = dwg.get_daily_weather()
		if not weather.is_empty():
			var weather_item = {"channel": "◆ CH-12 天气频道", "text": "%s %s | 温度: %s | 湿度: %s\n%s" % [weather.get("icon", ""), weather.get("name", ""), weather.get("temperature", ""), weather.get("humidity", ""), weather.get("desc", "")]}
			_news_pool.append(weather_item)
		var events = dwg.get_daily_events()
		for event in events:
			_news_pool.append({"channel": "◆ CH-07 都市新闻", "text": "[color=#00EEFF]今日快讯[/color] " + event})
	_current_index = randi() % _news_pool.size()

func _show_current():
	if _news_pool.is_empty():
		return
	var item = _news_pool[_current_index]
	_channel_label.text = item.channel
	_news_text.text = item.text
	_load_news_image()

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
		return "city_day"
	var item = _news_pool[_current_index]
	var channel = item.get("channel", "")
	if "天气" in channel:
		return "weather"
	if _is_night:
		if "异常" in channel or "??" in channel:
			return "anomaly"
		return "city_night"
	if "交通" in channel:
		return "surveillance"
	if "生活" in channel:
		return "ads"
	if "都市" in channel:
		if has_node("/root/DayNightManager"):
			var dnm = get_node("/root/DayNightManager")
			if dnm.current_phase == dnm.DayPhase.RAIN_NIGHT:
				return "city_rain"
		return "city_day"
	if has_node("/root/MediaManager"):
		return get_node("/root/MediaManager").get_category_for_phase()
	return "city_day"

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
	var valid_cats = ["weather", "anomaly", "surveillance", "ads", "city_day", "city_rain", "city_night"]
	if category not in valid_cats:
		return
	if texture and _news_image.visible:
		var tween = create_tween()
		tween.tween_property(_news_image, "modulate:a", 0.0, 0.12)
		tween.tween_callback(func(): _news_image.texture = texture)
		tween.tween_property(_news_image, "modulate:a", 1.0, 0.12)
		if _loading_label:
			_loading_label.visible = false
