extends CanvasLayer

var _bg_overlay: ColorRect
var _main_panel: PanelContainer
var _title_label: Label
var _title_sep: ColorRect
var _observation_text: RichTextLabel
var _city_image: TextureRect
var _continue_hint: Label
var _hint_bg: PanelContainer
var _flash_effect: ColorRect
var _left_deco: ColorRect

var _texts: Array[String] = []
var _last_index: int = -1
var _flash_timer: float = 0.0
var _is_night: bool = false

signal closed

func _ready():
	layer = 12
	_is_night = _check_night()
	_build_ui()
	_build_texts()
	_show_random_text()
	_apply_fonts()
	_apply_theme()
	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)

func _apply_fonts():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	tm.apply_font_to_label(_title_label, 16)
	tm.apply_font_to_rich_text(_observation_text, 16)
	tm.apply_font_to_label(_continue_hint, 13)
	if has_node("/root/MediaManager"):
		get_node("/root/MediaManager").image_ready.connect(_on_media_image_ready)

func _check_night() -> bool:
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		return dnm.current_phase == dnm.DayPhase.NIGHT or dnm.current_phase == dnm.DayPhase.RAIN_NIGHT
	return false

func _build_ui():
	_bg_overlay = ColorRect.new()
	_bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_overlay.color = Color(0, 0, 0, 0.3)
	_bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg_overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var outer_vbox = VBoxContainer.new()
	outer_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	outer_vbox.add_theme_constant_override("separation", 10)
	center.add_child(outer_vbox)

	_main_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.055, 0.1, 0.85)
	panel_style.border_color = Color(0, 0.93, 1, 0.4)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)
	panel_style.shadow_color = Color(0, 0.93, 1, 0.1)
	panel_style.shadow_size = 4
	_main_panel.add_theme_stylebox_override("panel", panel_style)
	_main_panel.custom_minimum_size = Vector2(680, 0)
	outer_vbox.add_child(_main_panel)

	var panel_vbox = VBoxContainer.new()
	panel_vbox.add_theme_constant_override("separation", 0)
	_main_panel.add_child(panel_vbox)

	var title_bar = PanelContainer.new()
	var tb_style = StyleBoxFlat.new()
	tb_style.bg_color = Color(0.024, 0.04, 0.08, 0.9)
	tb_style.set_corner_radius_all(0)
	tb_style.content_margin_left = 16
	tb_style.content_margin_right = 16
	tb_style.content_margin_top = 8
	tb_style.content_margin_bottom = 8
	title_bar.add_theme_stylebox_override("panel", tb_style)
	panel_vbox.add_child(title_bar)

	_title_label = Label.new()
	_title_label.text = "▸ 城市观察"
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0, 0.93, 1))
	title_bar.add_child(_title_label)

	var date_suffix = ""
	if has_node("/root/WorldCalendar"):
		date_suffix = "  " + get_node("/root/WorldCalendar").get_short_date()
	var date_in_title = Label.new()
	date_in_title.text = date_suffix
	date_in_title.add_theme_font_size_override("font_size", 12)
	date_in_title.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58))
	date_in_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_bar.add_child(date_in_title)

	_title_sep = ColorRect.new()
	_title_sep.custom_minimum_size = Vector2(0, 1)
	_title_sep.color = Color(0, 0.93, 1, 0.3)
	_title_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_vbox.add_child(_title_sep)

	var content_hbox = HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 0)
	panel_vbox.add_child(content_hbox)

	_left_deco = ColorRect.new()
	_left_deco.custom_minimum_size = Vector2(2, 0)
	_left_deco.color = Color(0, 0.93, 1, 0.4)
	_left_deco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(_left_deco)

	_city_image = TextureRect.new()
	_city_image.custom_minimum_size = Vector2(560, 320)
	_city_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	_city_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_city_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_city_image.visible = false

	_observation_text = RichTextLabel.new()
	_observation_text.bbcode_enabled = true
	_observation_text.custom_minimum_size = Vector2(560, 120)
	_observation_text.add_theme_font_size_override("normal_font_size", 16)
	_observation_text.add_theme_color_override("default_color", Color(0.88, 0.9, 0.88))
	_observation_text.fit_content = true
	_observation_text.scroll_following = false

	var text_margin = MarginContainer.new()
	text_margin.add_theme_constant_override("margin_left", 14)
	text_margin.add_theme_constant_override("margin_right", 14)
	text_margin.add_theme_constant_override("margin_top", 12)
	text_margin.add_theme_constant_override("margin_bottom", 12)
	text_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_margin.add_child(_city_image)
	text_margin.add_child(_observation_text)
	content_hbox.add_child(text_margin)

	if _is_night:
		_left_deco.color = Color(0.8, 0.2, 1, 0.5)
		_title_sep.color = Color(0.8, 0.2, 1, 0.3)
		var night_panel = _main_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if night_panel:
			night_panel.border_color = Color(0.8, 0.2, 1, 0.4)
			night_panel.shadow_color = Color(0.8, 0.2, 1, 0.1)
			_main_panel.add_theme_stylebox_override("panel", night_panel)

	_hint_bg = PanelContainer.new()
	var hint_style = StyleBoxFlat.new()
	hint_style.bg_color = Color(0.024, 0.04, 0.08, 0.8)
	hint_style.set_corner_radius_all(8)
	hint_style.set_border_width_all(1)
	hint_style.border_color = Color(0, 0.93, 1, 0.15)
	hint_style.content_margin_left = 16
	hint_style.content_margin_right = 16
	hint_style.content_margin_top = 6
	hint_style.content_margin_bottom = 6
	_hint_bg.add_theme_stylebox_override("panel", hint_style)
	outer_vbox.add_child(_hint_bg)

	_continue_hint = Label.new()
	_continue_hint.text = "按 [E] 继续观察 | 按 [ESC] 离开"
	_continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_hint.add_theme_font_size_override("font_size", 13)
	_continue_hint.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58))
	_hint_bg.add_child(_continue_hint)

	_flash_effect = ColorRect.new()
	_flash_effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_effect.color = Color(1, 1, 1, 0)
	_flash_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_effect)

func _on_phase_changed(_new_phase):
	_is_night = _check_night()
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
		_title_label.add_theme_color_override("font_color", t["title_color"])

	if _title_sep:
		_title_sep.color = t["separator_color"]

	if _left_deco:
		_left_deco.color = Color(t["border_accent"].r, t["border_accent"].g, t["border_accent"].b, 0.4)

	if _observation_text:
		_observation_text.add_theme_color_override("default_color", t["text_color"])

	if _continue_hint:
		_continue_hint.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.6))

func _build_texts():
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
			_texts = [
				"远处的霓虹灯在闪烁，城市从不睡觉。",
				"一架无人机从窗外飞过，发出低沉的嗡鸣。",
				"高架列车划过天际，留下一道光尾。",
				"对面楼的窗户亮着暖黄色的灯光。",
				"街道上有人在走动，看起来很匆忙。",
				"远处传来模糊的音乐声。",
				"一架飞行汽车从楼顶掠过。",
				"城市的轮廓在雾气中若隐若现。",
				"楼下便利店的招牌在阳光下闪烁。",
				"远处建筑工地的全息投影广告正在播放。",
			]
		"rain":
			_texts = [
				"雨幕中的霓虹灯模糊成一片光晕。",
				"远处传来雷声，窗户微微震动。",
				"楼下便利店的灯光在雨中显得格外温暖。",
				"雨滴打在栏杆上，发出清脆的声响。",
				"远处的高架列车在雨中缓缓驶过。",
				"对面楼有人关上了窗户，拉上了窗帘。",
				"一架无人机在雨中艰难飞行，灯光忽明忽暗。",
				"雨声掩盖了城市的喧嚣，世界变得安静。",
			]
		"night":
			_texts = [
				"[color=#CC33FF]天空似乎有一道裂缝...不太对劲。[/color]",
				"[color=#CC33FF]远处的楼突然熄灭了，然后又亮了起来。[/color]",
				"空气中弥漫着微弱的臭氧味。",
				"[color=#CC33FF]某个方向传来低频嗡鸣，让人不安。[/color]",
				"[color=#CC33FF]你感觉有什么东西在注视你。[/color]",
				"远处信号灯的频率似乎不太正常...",
				"[color=#CC33FF]紫色微粒在空气中缓缓飘过。[/color]",
				"城市的轮廓在异常的光线下扭曲变形。",
			]

func _show_random_text():
	if _texts.is_empty():
		return
	var index = randi() % _texts.size()
	while index == _last_index and _texts.size() > 1:
		index = randi() % _texts.size()
	_last_index = index
	_observation_text.text = _texts[index]
	_load_city_image()

func _load_city_image():
	if not _city_image:
		return
	if has_node("/root/MediaManager"):
		var mm = get_node("/root/MediaManager")
		var cat = mm.get_category_for_phase()
		if _is_night:
			if has_node("/root/DayNightManager"):
				var dnm = get_node("/root/DayNightManager")
				if dnm.current_phase == dnm.DayPhase.RAIN_NIGHT:
					cat = "city_rain"
				else:
					cat = "city_night"
			else:
				cat = "city_night"
		var tex = mm.get_random_image(cat)
		if tex:
			_city_image.texture = tex
			_city_image.visible = true
		else:
			_city_image.visible = false
	else:
		_city_image.visible = false

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_close()
		return

	if Input.is_action_just_pressed("interact"):
		_continue_observe()

	if _flash_timer > 0:
		_flash_timer -= delta
		if _flash_timer <= 0:
			_flash_effect.color = Color(1, 1, 1, 0)

func _continue_observe():
	var roll = randf()
	if roll < 0.15:
		_trigger_flash()
	elif roll < 0.20:
		_trigger_shake()
	_show_random_text()

func _trigger_flash():
	if _is_night:
		_flash_effect.color = Color(0.8, 0.2, 1, 0.3)
	else:
		_flash_effect.color = Color(1, 1, 1, 0.4)
	_flash_timer = 0.2

func _trigger_shake():
	var tween = create_tween()
	tween.tween_property(_observation_text, "modulate", Color(1, 1, 1, 0.3), 0.05)
	tween.tween_property(_observation_text, "modulate", Color(1, 1, 1, 1.0), 0.05)
	tween.tween_property(_observation_text, "modulate", Color(1, 1, 1, 0.5), 0.05)
	tween.tween_property(_observation_text, "modulate", Color(1, 1, 1, 1.0), 0.05)

func _on_close():
	closed.emit()
	queue_free()

func _on_media_image_ready(category: String, texture: Texture2D):
	if not is_instance_valid(_city_image):
		return
	if category != "city_day" and category != "city_rain" and category != "city_night":
		return
	if texture and _city_image.visible:
		var tween = create_tween()
		tween.tween_property(_city_image, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): _city_image.texture = texture)
		tween.tween_property(_city_image, "modulate:a", 1.0, 0.15)
