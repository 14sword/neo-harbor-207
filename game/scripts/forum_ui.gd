extends CanvasLayer

var _forum_data: RefCounted
var _current_category: String = ""
var _category_buttons: Array[Button] = []
var _post_buttons: Array[Button] = []

var _bg_overlay: ColorRect
var _main_panel: PanelContainer
var _title_label: Label
var _close_button: Button
var _category_list: VBoxContainer
var _post_list: VBoxContainer
var _post_detail: RichTextLabel
var _post_image: TextureRect
var _signal_label: Label
var _signal_dot: ColorRect
var _time_label: Label
var _scanline_rect: ColorRect
var _detail_panel: PanelContainer

var _typewriter_timer: float = 0.0
var _typewriter_char_count: int = 0
var _typewriter_speed: float = 0.03
var _is_typing: bool = false
var _typewriter_pending: bool = false
var _cached_phase: String = "day"
var _last_post_title: String = ""

signal closed

func _ready():
	layer = 15
	_forum_data = load("res://scripts/forum_data.gd").new()
	_build_ui()
	_setup_categories()
	_apply_fonts()
	_apply_theme()
	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)

func _apply_fonts():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	tm.apply_font_to_label(_title_label, 18, true)
	tm.apply_font_to_rich_text(_post_detail, 13)
	tm.apply_font_to_button(_close_button, 18)
	tm.apply_font_to_label(_signal_label, 11)
	tm.apply_font_to_label(_time_label, 11)
	for btn in _category_buttons:
		tm.apply_font_to_button(btn, 14)
	for btn in _post_buttons:
		tm.apply_font_to_button(btn, 14)
	if has_node("/root/MediaManager"):
		get_node("/root/MediaManager").image_ready.connect(_on_media_image_ready)

func _build_ui():
	var t = _get_theme()
	var is_day = has_node("/root/UIThemeManager") and get_node("/root/UIThemeManager").is_day()

	_bg_overlay = ColorRect.new()
	_bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_overlay.color = Color(0, 0, 0, 0.7)
	_bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg_overlay)

	_main_panel = PanelContainer.new()
	_main_panel.set_anchors_preset(Control.PRESET_CENTER)
	_main_panel.offset_left = -500
	_main_panel.offset_top = -340
	_main_panel.offset_right = 500
	_main_panel.offset_bottom = 340
	var panel_style = StyleBoxFlat.new()
	if is_day:
		panel_style.bg_color = Color(0.12, 0.1, 0.08, 0.96)
		panel_style.border_color = Color(0.72, 0.53, 0.31, 0.6)
		panel_style.shadow_color = Color(0.72, 0.53, 0.31, 0.15)
	else:
		panel_style.bg_color = Color(0.04, 0.055, 0.1, 0.96)
		panel_style.border_color = Color(0, 0.93, 1, 0.6)
		panel_style.shadow_color = Color(0, 0.93, 1, 0.15)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_size = 6
	_main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_main_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 0)
	_main_panel.add_child(main_vbox)

	var title_bar = PanelContainer.new()
	var title_bar_style = StyleBoxFlat.new()
	if is_day:
		title_bar_style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	else:
		title_bar_style.bg_color = Color(0.024, 0.04, 0.08, 0.95)
	title_bar_style.set_corner_radius_all(0)
	title_bar_style.content_margin_left = 16
	title_bar_style.content_margin_right = 16
	title_bar_style.content_margin_top = 10
	title_bar_style.content_margin_bottom = 10
	title_bar.add_theme_stylebox_override("panel", title_bar_style)
	main_vbox.add_child(title_bar)

	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)
	title_bar.add_child(title_hbox)

	_title_label = Label.new()
	_title_label.text = "▸ DATAWHALE Terminal v2.7"
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color(0, 0.93, 1))
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(_title_label)

	_signal_dot = ColorRect.new()
	_signal_dot.custom_minimum_size = Vector2(10, 10)
	_signal_dot.color = Color(0.3, 0.9, 0.3)
	_signal_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_hbox.add_child(_signal_dot)

	_close_button = Button.new()
	_close_button.text = "✕"
	_close_button.custom_minimum_size = Vector2(28, 28)
	_close_button.add_theme_color_override("font_color", Color(1, 0.85, 0.85))
	_close_button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.667, 0.2, 0.2, 0.9)
	btn_normal.set_corner_radius_all(14)
	btn_normal.set_border_width_all(2)
	btn_normal.border_color = Color(1, 0.3, 0.3, 0.5)
	btn_normal.shadow_color = Color(1, 0, 0, 0.15)
	btn_normal.shadow_size = 3
	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.85, 0.25, 0.25, 1)
	btn_hover.set_corner_radius_all(14)
	btn_hover.set_border_width_all(2)
	btn_hover.border_color = Color(1, 0.4, 0.4, 0.8)
	btn_hover.shadow_color = Color(1, 0.2, 0.2, 0.3)
	btn_hover.shadow_size = 5
	_close_button.add_theme_stylebox_override("normal", btn_normal)
	_close_button.add_theme_stylebox_override("hover", btn_hover)
	_close_button.pressed.connect(_on_close)
	title_hbox.add_child(_close_button)

	var title_sep = ColorRect.new()
	title_sep.custom_minimum_size = Vector2(0, 1)
	title_sep.color = Color(0, 0.93, 1, 0.3)
	title_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(title_sep)

	var content_area = HSplitContainer.new()
	content_area.split_offset = 170
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 0)
	main_vbox.add_child(content_area)

	var category_panel = PanelContainer.new()
	var cat_panel_style = StyleBoxFlat.new()
	cat_panel_style.bg_color = Color(0.03, 0.04, 0.08, 0.9)
	cat_panel_style.content_margin_left = 10
	cat_panel_style.content_margin_right = 10
	cat_panel_style.content_margin_top = 10
	cat_panel_style.content_margin_bottom = 10
	category_panel.add_theme_stylebox_override("panel", cat_panel_style)
	category_panel.custom_minimum_size = Vector2(170, 0)
	content_area.add_child(category_panel)

	var cat_vbox = VBoxContainer.new()
	cat_vbox.add_theme_constant_override("separation", 6)
	category_panel.add_child(cat_vbox)

	var cat_title = Label.new()
	cat_title.text = "分类"
	cat_title.add_theme_font_size_override("font_size", 13)
	cat_title.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58))
	cat_vbox.add_child(cat_title)

	_category_list = VBoxContainer.new()
	_category_list.add_theme_constant_override("separation", 3)
	_category_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cat_vbox.add_child(_category_list)

	_signal_label = Label.new()
	_signal_label.add_theme_font_size_override("font_size", 11)
	_signal_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	cat_vbox.add_child(_signal_label)

	var vsep_container = PanelContainer.new()
	var vsep_style = StyleBoxFlat.new()
	vsep_style.bg_color = Color(0, 0.93, 1, 0.15)
	vsep_style.content_margin_left = 1
	vsep_style.content_margin_right = 0
	vsep_style.content_margin_top = 0
	vsep_style.content_margin_bottom = 0
	vsep_container.add_theme_stylebox_override("panel", vsep_style)
	vsep_container.custom_minimum_size = Vector2(1, 0)
	content_area.add_child(vsep_container)

	var right_panel = VBoxContainer.new()
	right_panel.add_theme_constant_override("separation", 0)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.add_child(right_panel)

	var post_list_container = ScrollContainer.new()
	post_list_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	post_list_container.custom_minimum_size = Vector2(0, 180)
	var scroll_style = StyleBoxFlat.new()
	scroll_style.bg_color = Color(0.03, 0.04, 0.08, 0.6)
	scroll_style.content_margin_left = 8
	scroll_style.content_margin_right = 8
	scroll_style.content_margin_top = 6
	scroll_style.content_margin_bottom = 6
	post_list_container.add_theme_stylebox_override("panel", scroll_style)
	right_panel.add_child(post_list_container)

	_post_list = VBoxContainer.new()
	_post_list.add_theme_constant_override("separation", 3)
	_post_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	post_list_container.add_child(_post_list)

	var detail_sep = ColorRect.new()
	detail_sep.custom_minimum_size = Vector2(0, 1)
	detail_sep.color = Color(0, 0.93, 1, 0.2)
	detail_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_child(detail_sep)

	_detail_panel = PanelContainer.new()
	var detail_style = StyleBoxFlat.new()
	detail_style.bg_color = Color(0.03, 0.04, 0.07, 0.8)
	detail_style.content_margin_left = 14
	detail_style.content_margin_right = 14
	detail_style.content_margin_top = 10
	detail_style.content_margin_bottom = 10
	detail_style.set_border_width_all(0)
	detail_style.border_width_left = 2
	detail_style.border_color = Color(0, 0.93, 1, 0.3)
	_detail_panel.add_theme_stylebox_override("panel", detail_style)
	_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(_detail_panel)

	_post_image = TextureRect.new()
	_post_image.custom_minimum_size = Vector2(0, 200)
	_post_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	_post_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_post_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_post_image.visible = false
	_detail_panel.add_child(_post_image)

	_post_detail = RichTextLabel.new()
	_post_detail.bbcode_enabled = true
	_post_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_post_detail.custom_minimum_size = Vector2(0, 140)
	_post_detail.add_theme_font_size_override("normal_font_size", 13)
	_post_detail.add_theme_color_override("default_color", Color(0.85, 0.88, 0.92))
	_detail_panel.add_child(_post_detail)

	var bottom_sep = ColorRect.new()
	bottom_sep.custom_minimum_size = Vector2(0, 1)
	bottom_sep.color = Color(0, 0.93, 1, 0.2)
	bottom_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(bottom_sep)

	var bottom_bar = PanelContainer.new()
	var bottom_style = StyleBoxFlat.new()
	bottom_style.bg_color = Color(0.024, 0.04, 0.08, 0.95)
	bottom_style.content_margin_left = 16
	bottom_style.content_margin_right = 16
	bottom_style.content_margin_top = 6
	bottom_style.content_margin_bottom = 6
	bottom_bar.add_theme_stylebox_override("panel", bottom_style)
	main_vbox.add_child(bottom_bar)

	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 8)
	bottom_bar.add_child(bottom_hbox)

	var pulse_label = Label.new()
	pulse_label.text = "●"
	pulse_label.add_theme_font_size_override("font_size", 10)
	pulse_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	bottom_hbox.add_child(pulse_label)

	_time_label = Label.new()
	_time_label.add_theme_font_size_override("font_size", 11)
	_time_label.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58))
	_time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(_time_label)

	var hint = Label.new()
	hint.text = "ESC 关闭"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom_hbox.add_child(hint)

	_scanline_rect = ColorRect.new()
	_scanline_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scanline_rect.color = Color(0, 0, 0, 0.05)
	_scanline_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scanline_rect)

	_update_signal_status()
	_update_time_label()

	_main_panel.modulate = Color(1, 1, 1, 0)
	_main_panel.scale = Vector2(0.96, 0.96)
	var open_tween = create_tween()
	open_tween.tween_property(_main_panel, "modulate", Color(1, 1, 1, 1), 0.15)
	open_tween.parallel().tween_property(_main_panel, "scale", Vector2(1, 1), 0.15)

func _setup_categories():
	for cat in _forum_data.categories:
		var btn = Button.new()
		btn.text = "  " + cat
		btn.custom_minimum_size = Vector2(140, 36)
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.05, 0.06, 0.11, 0.7)
		normal_style.set_corner_radius_all(6)
		normal_style.content_margin_left = 8
		normal_style.content_margin_right = 8
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.06, 0.08, 0.15, 0.9)
		hover_style.set_corner_radius_all(6)
		hover_style.set_border_width_all(0)
		hover_style.border_width_left = 3
		hover_style.border_color = Color(0, 0.93, 1, 0.5)
		hover_style.content_margin_left = 8
		hover_style.content_margin_right = 8
		var selected_style = StyleBoxFlat.new()
		selected_style.bg_color = Color(0.06, 0.08, 0.15, 0.9)
		selected_style.set_corner_radius_all(6)
		selected_style.set_border_width_all(0)
		selected_style.border_width_left = 3
		selected_style.border_color = Color(0, 0.93, 1, 0.8)
		selected_style.content_margin_left = 8
		selected_style.content_margin_right = 8
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", selected_style)
		btn.add_theme_color_override("font_color", Color(0.53, 0.53, 0.67))
		btn.add_theme_color_override("font_hover_color", Color(0, 0.93, 1))
		btn.add_theme_color_override("font_pressed_color", Color(0, 0.93, 1))
		btn.add_theme_color_override("font_focus_color", Color(0, 0.93, 1))
		btn.pressed.connect(_on_category_selected.bind(cat))
		_category_list.add_child(btn)
		_category_buttons.append(btn)

	if _forum_data.categories.size() > 0:
		_on_category_selected(_forum_data.categories[0])

func _on_category_selected(category: String):
	_current_category = category
	for btn in _category_buttons:
		if btn.text.strip_edges() == category:
			btn.add_theme_color_override("font_color", Color(0, 0.93, 1))
			var sel_style = btn.get_theme_stylebox("pressed") as StyleBoxFlat
			if sel_style:
				btn.add_theme_stylebox_override("normal", sel_style.duplicate())
		else:
			btn.add_theme_color_override("font_color", Color(0.53, 0.53, 0.67))
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color(0.05, 0.06, 0.11, 0.7)
			normal_style.set_corner_radius_all(6)
			normal_style.content_margin_left = 8
			normal_style.content_margin_right = 8
			btn.add_theme_stylebox_override("normal", normal_style)
	_show_post_list()

func _show_post_list():
	for child in _post_list.get_children():
		child.queue_free()
	_post_buttons.clear()

	var phase = _forum_data.get_phase_key()
	var posts = _forum_data.get_posts(_current_category, phase)

	if _current_category == "生活杂谈" and has_node("/root/DailyWorldGenerator"):
		var dwg = get_node("/root/DailyWorldGenerator")
		var ads = dwg.get_daily_ads()
		for ad in ads:
			posts.append({
				"title": "【广告】" + ad.get("title", ""),
				"author": "推广信息",
				"time": "12:00",
				"content": ad.get("desc", ""),
			})

	if posts.is_empty():
		var label = Label.new()
		label.text = "暂无帖子"
		label.add_theme_color_override("font_color", Color(0.42, 0.44, 0.58))
		label.add_theme_font_size_override("font_size", 13)
		_post_list.add_child(label)
		return

	for i in range(posts.size()):
		var post = posts[i]
		var btn = Button.new()
		btn.text = "  " + post.title
		btn.custom_minimum_size = Vector2(0, 32)
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		var post_style = StyleBoxFlat.new()
		post_style.bg_color = Color(0.04, 0.05, 0.09, 0.5)
		post_style.set_corner_radius_all(4)
		post_style.content_margin_left = 8
		post_style.content_margin_right = 8
		var post_hover = StyleBoxFlat.new()
		post_hover.bg_color = Color(0.05, 0.07, 0.13, 0.8)
		post_hover.set_corner_radius_all(4)
		post_hover.set_border_width_all(0)
		post_hover.border_width_left = 2
		post_hover.border_color = Color(0, 0.93, 1, 0.5)
		post_hover.content_margin_left = 8
		post_hover.content_margin_right = 8
		btn.add_theme_stylebox_override("normal", post_style)
		btn.add_theme_stylebox_override("hover", post_hover)
		btn.add_theme_color_override("font_color", Color(0.75, 0.76, 0.84))
		btn.add_theme_color_override("font_hover_color", Color(0, 0.93, 1))
		btn.pressed.connect(_on_post_selected.bind(post))
		_post_list.add_child(btn)
		_post_buttons.append(btn)

	_post_detail.text = ""
	_is_typing = false

func _on_post_selected(post: Dictionary):
	_last_post_title = post.get("title", "")
	var header = "[color=#00EEFF]" + post.title + "[/color]\n"
	header += "[color=#6B7094]" + post.author + " | " + post.time + "[/color]\n\n"
	header += post.content
	_post_detail.text = header
	_post_detail.visible_characters = 0
	_is_typing = true
	_typewriter_speed = 0.03
	_typewriter_timer = 0.0
	_typewriter_pending = true
	_cached_phase = _forum_data.get_phase_key()
	_load_post_image()

func _load_post_image():
	if not _post_image:
		return
	if has_node("/root/MediaManager"):
		var mm = get_node("/root/MediaManager")
		var cat = _get_image_category_for_forum()
		var tex = mm.get_random_image(cat)
		if tex:
			_post_image.texture = tex
			_post_image.visible = true
		else:
			_post_image.visible = false
	else:
		_post_image.visible = false

func _get_image_category_for_forum() -> String:
	match _current_category:
		"都市新闻":
			if has_node("/root/DayNightManager"):
				var dnm = get_node("/root/DayNightManager")
				if dnm.current_phase == dnm.DayPhase.RAIN_NIGHT:
					return "city_rain"
				if dnm.current_phase == dnm.DayPhase.NIGHT:
					return "city_night"
			return "city_day"
		"异常报告":
			return "anomaly"
		"生活杂谈":
			return "ads"
		"DATAWHALE公告":
			return "datawhale"
		_:
			return "forum"

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_close()
		return

	if _is_typing:
		if _typewriter_pending:
			_typewriter_char_count = _post_detail.get_total_character_count()
			_post_detail.visible_characters = 0
			_typewriter_pending = false
			if _cached_phase == "night":
				_typewriter_speed = 0.05
			return

		_typewriter_timer += delta
		var chars_this_frame = 0
		while _typewriter_timer >= _typewriter_speed and _post_detail.visible_characters < _typewriter_char_count and chars_this_frame < 10:
			_typewriter_timer -= _typewriter_speed
			_post_detail.visible_characters += 1
			chars_this_frame += 1

			if _cached_phase == "night" and randf() < 0.05:
				_typewriter_speed = randf_range(0.08, 0.2)
			else:
				_typewriter_speed = 0.03 if _cached_phase != "night" else 0.05

		if _post_detail.visible_characters >= _typewriter_char_count:
			_is_typing = false

func _update_signal_status():
	var phase = _forum_data.get_phase_key()
	match phase:
		"day":
			_signal_label.text = "信号: 正常"
			_signal_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			if _signal_dot:
				_signal_dot.color = Color(0.3, 0.9, 0.3)
		"rain":
			_signal_label.text = "信号: 不稳定"
			_signal_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.2))
			if _signal_dot:
				_signal_dot.color = Color(0.8, 0.7, 0.2)
		"night":
			_signal_label.text = "信号: ▓▓▓异常▓▓▓"
			_signal_label.add_theme_color_override("font_color", Color(0.8, 0.2, 1))
			if _signal_dot:
				_signal_dot.color = Color(0.8, 0.2, 1)

func _update_time_label():
	var date_str = "N.H.207"
	if has_node("/root/WorldCalendar"):
		date_str = get_node("/root/WorldCalendar").get_date_string()
	var phase = _forum_data.get_phase_key()
	var time_str = ""
	match phase:
		"day":
			time_str = "10:00"
		"rain":
			time_str = "22:30"
		"night":
			time_str = "02:??"
	_time_label.text = date_str + " " + time_str

func _get_theme() -> Dictionary:
	if has_node("/root/UIThemeManager"):
		return get_node("/root/UIThemeManager").get_theme()
	return {}

func _on_phase_changed(_new_phase):
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

	if _signal_label:
		_update_signal_status()

	if _time_label:
		_time_label.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.6))

	if _post_detail:
		_post_detail.add_theme_color_override("default_color", t["text_color"])

func _on_close():
	closed.emit()
	queue_free()

func _on_media_image_ready(category: String, texture: Texture2D):
	if not is_instance_valid(_post_image):
		return
	var valid_cats = ["forum", "city_day", "city_rain", "city_night", "anomaly", "ads", "datawhale"]
	if category not in valid_cats:
		return
	if texture and _post_image.visible:
		var tween = create_tween()
		tween.tween_property(_post_image, "modulate:a", 0.0, 0.12)
		tween.tween_callback(func(): _post_image.texture = texture)
		tween.tween_property(_post_image, "modulate:a", 1.0, 0.12)
