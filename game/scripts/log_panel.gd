extends CanvasLayer

var panel: PanelContainer
var log_text: RichTextLabel
var close_button: Button
var title_label: Label
var toggle_button: Button
var scroll_container: ScrollContainer
var title_bar: PanelContainer
var time_label: Label
var clear_button: Button
var bottom_bar: PanelContainer
var title_sep: ColorRect
var bottom_sep: ColorRect
var hint_label: Label

var _initialized: bool = false
var _last_l_pressed: bool = false
var _slide_tween: Tween = null

var _npc_color_map: Dictionary = {
	"zhang_san": "#4ECDC4",
	"li_si": "#FFE66D",
	"wang_wu": "#FF6B9D",
	"chen_xi": "#A050C8",
	"zhao_lin": "#FFC800",
	"sun_yue": "#00C8B4",
	"liu_feng": "#FF503C",
	"he_zhen": "#3C78FF",
	"张三": "#4ECDC4",
	"李四": "#FFE66D",
	"王五": "#FF6B9D",
	"陈曦": "#A050C8",
	"赵霖": "#FFC800",
	"孙悦": "#00C8B4",
	"刘风": "#FF503C",
	"何真": "#3C78FF",
}

func _ready():
	_create_ui()
	_apply_theme()
	_initialized = true
	add_log("🎮 游戏启动完成！")
	add_log("💡 按 L 键切换日志面板")
	add_log("🌙 按 T 键切换白天/黑夜")
	add_log("👆 按 E 键与NPC交互")
	add_log("🐾 按 Tab 切换宠物 / 按 P 宠物动作")

	if _is_on_login_scene():
		if toggle_button:
			toggle_button.visible = false

	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)

func _is_on_login_scene() -> bool:
	var cs = get_tree().current_scene
	if cs and cs.scene_file_path.to_lower().find("character_select") != -1:
		return true
	return false

func _on_phase_changed(_new_phase):
	_apply_theme()

func _apply_theme():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()

	if panel:
		var style = tm.make_panel_style(-1, 2, 6)
		panel.add_theme_stylebox_override("panel", style)

	if title_bar:
		title_bar.add_theme_stylebox_override("panel", tm.make_title_bar_style())

	if title_label:
		title_label.add_theme_color_override("font_color", t["title_color"])

	if time_label:
		time_label.add_theme_color_override("font_color", t["secondary_color"])

	if log_text:
		log_text.add_theme_color_override("default_color", t["text_color"])
		tm.apply_font_to_rich_text(log_text, 15)

	if close_button:
		var styles = tm.make_close_button_styles()
		close_button.add_theme_stylebox_override("normal", styles["normal"])
		close_button.add_theme_stylebox_override("hover", styles["hover"])
		close_button.add_theme_color_override("font_color", Color.WHITE)
		tm.apply_font_to_button(close_button, 18)

	if toggle_button:
		var t_style = StyleBoxFlat.new()
		t_style.bg_color = t["card_bg"]
		t_style.border_color = t["panel_border"]
		t_style.set_border_width_all(2)
		t_style.set_corner_radius_all(12)
		t_style.shadow_color = t["panel_shadow"]
		t_style.shadow_size = 4
		toggle_button.add_theme_stylebox_override("normal", t_style)
		toggle_button.add_theme_color_override("font_color", t["title_color"])
		tm.apply_font_to_button(toggle_button, 16)

	if clear_button:
		var c_style = StyleBoxFlat.new()
		c_style.bg_color = Color(t["card_bg"].r, t["card_bg"].g, t["card_bg"].b, 0.7)
		c_style.set_corner_radius_all(6)
		clear_button.add_theme_stylebox_override("normal", c_style)
		clear_button.add_theme_color_override("font_color", t["secondary_color"])
		tm.apply_font_to_button(clear_button, 12)

	if bottom_bar:
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = t["title_bar_bg"]
		b_style.set_corner_radius_all(0)
		b_style.content_margin_left = 12
		b_style.content_margin_right = 12
		b_style.content_margin_top = 6
		b_style.content_margin_bottom = 6
		bottom_bar.add_theme_stylebox_override("panel", b_style)

	if scroll_container:
		var scroll_style = StyleBoxFlat.new()
		scroll_style.bg_color = t.get("scroll_bg", t["card_bg"])
		scroll_style.set_corner_radius_all(6)
		scroll_style.content_margin_left = 8
		scroll_style.content_margin_right = 8
		scroll_style.content_margin_top = 6
		scroll_style.content_margin_bottom = 6
		scroll_container.add_theme_stylebox_override("panel", scroll_style)

	if title_sep:
		title_sep.color = t["separator_color"]

	if bottom_sep:
		bottom_sep.color = t["separator_color"]

	if hint_label:
		hint_label.add_theme_font_size_override("font_size", 11)
		hint_label.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.6))
		tm.apply_font_to_label(hint_label, 11)

func _create_ui():
	toggle_button = Button.new()
	toggle_button.text = "📋 L"
	toggle_button.tooltip_text = "显示/隐藏日志 (L键)"
	toggle_button.custom_minimum_size = Vector2(60, 44)
	toggle_button.anchor_left = 1.0
	toggle_button.anchor_right = 1.0
	toggle_button.anchor_top = 0.0
	toggle_button.anchor_bottom = 0.0
	toggle_button.offset_left = -75
	toggle_button.offset_right = -15
	toggle_button.offset_top = 15
	toggle_button.offset_bottom = 59
	toggle_button.z_index = 100
	toggle_button.pressed.connect(_on_toggle_pressed)
	add_child(toggle_button)

	panel = PanelContainer.new()
	panel.name = "LogPanel_Main"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 10
	panel.offset_top = 10
	panel.offset_right = -320
	panel.offset_bottom = -10
	panel.visible = false
	add_child(panel)

	var panel_vbox = VBoxContainer.new()
	panel_vbox.add_theme_constant_override("separation", 0)
	panel.add_child(panel_vbox)

	title_bar = PanelContainer.new()
	title_bar.name = "TitleBar"
	panel_vbox.add_child(title_bar)

	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 8)
	title_bar.add_child(title_hbox)

	title_label = Label.new()
	title_label.text = "◈ 游戏日志"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(title_label)

	time_label = Label.new()
	time_label.add_theme_font_size_override("font_size", 11)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_hbox.add_child(time_label)

	close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(28, 28)
	close_button.pressed.connect(_on_close_pressed)
	title_hbox.add_child(close_button)

	title_sep = ColorRect.new()
	title_sep.custom_minimum_size = Vector2(0, 1)
	title_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_vbox.add_child(title_sep)

	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_vbox.add_child(scroll_container)

	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.fit_content = true
	log_text.scroll_following = true
	log_text.custom_minimum_size = Vector2(0, 0)
	log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(log_text)

	bottom_sep = ColorRect.new()
	bottom_sep.custom_minimum_size = Vector2(0, 1)
	bottom_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_vbox.add_child(bottom_sep)

	bottom_bar = PanelContainer.new()
	panel_vbox.add_child(bottom_bar)

	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 6)
	bottom_bar.add_child(bottom_hbox)

	hint_label = Label.new()
	hint_label.text = "按 L 切换 | 按 ESC 关闭"
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(hint_label)

	clear_button = Button.new()
	clear_button.text = "清空"
	clear_button.custom_minimum_size = Vector2(50, 24)
	clear_button.pressed.connect(_on_clear_pressed)
	bottom_hbox.add_child(clear_button)

func _process(_delta):
	if _is_on_login_scene():
		return
	if Input.is_physical_key_pressed(KEY_L):
		if not _last_l_pressed:
			_on_toggle_pressed()
		_last_l_pressed = true
	else:
		_last_l_pressed = false

	if time_label:
		time_label.text = _get_current_time_string()

func add_log(message: String):
	if not _initialized or not log_text:
		return
	var time_str = _get_current_time_string()
	var t = _get_current_theme()
	var time_color = t.get("secondary_color", Color(0.55, 0.45, 0.33))
	var time_hex = "#" + time_color.to_html(false)
	var phase_icon = _get_phase_icon()
	log_text.append_text("[color=" + time_hex + "][" + phase_icon + " " + time_str + "][/color] " + message + "\n")
	_scroll_to_bottom()

func add_dialogue_log(speaker: String, message: String, npc_id: String = ""):
	if not _initialized or not log_text:
		return
	var time_str = _get_current_time_string()
	var t = _get_current_theme()
	var time_color = t.get("secondary_color", Color(0.55, 0.45, 0.33))
	var time_hex = "#" + time_color.to_html(false)
	var speaker_color = _npc_color_map.get(npc_id, _npc_color_map.get(speaker, "#" + t.get("accent_color", Color(0.83, 0.58, 0.42)).to_html(false)))
	var phase_icon = _get_phase_icon()
	log_text.append_text("[color=" + time_hex + "][" + phase_icon + " " + time_str + "][/color] [color=" + speaker_color + "]" + speaker + ":[/color] " + message + "\n")
	_scroll_to_bottom()

func _get_phase_icon() -> String:
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		match dnm.current_phase:
			dnm.DayPhase.DAY:
				return "☀️"
			dnm.DayPhase.DUSK:
				return "🌅"
			dnm.DayPhase.RAIN_NIGHT:
				return "🌧️"
			dnm.DayPhase.NIGHT:
				return "🌙"
	return "◈"

func clear_logs():
	if log_text:
		log_text.clear()

func _get_current_theme() -> Dictionary:
	if has_node("/root/UIThemeManager"):
		return get_node("/root/UIThemeManager").get_theme()
	return {"secondary_color": Color(0.55, 0.45, 0.33)}

func _on_close_pressed():
	if panel:
		_slide_out()

func _on_toggle_pressed():
	if panel:
		if panel.visible:
			_slide_out()
		else:
			_slide_in()

func _slide_in():
	panel.visible = true
	panel.modulate = Color(1, 1, 1, 0)
	panel.offset_left = -320
	_apply_theme()

	if _slide_tween:
		_slide_tween.kill()
	_slide_tween = create_tween()
	_slide_tween.set_ease(Tween.EASE_OUT)
	_slide_tween.set_trans(Tween.TRANS_CUBIC)
	_slide_tween.tween_property(panel, "offset_left", 10.0, 0.3)
	_slide_tween.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.25)
	_slide_tween.tween_callback(_scroll_to_bottom)

func _slide_out():
	if _slide_tween:
		_slide_tween.kill()
	_slide_tween = create_tween()
	_slide_tween.set_ease(Tween.EASE_IN)
	_slide_tween.set_trans(Tween.TRANS_CUBIC)
	_slide_tween.tween_property(panel, "offset_left", -320.0, 0.25)
	_slide_tween.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.2)
	_slide_tween.tween_callback(func(): panel.visible = false)

func _on_clear_pressed():
	clear_logs()
	add_log("📋 日志已清空")

func _scroll_to_bottom():
	if log_text:
		await get_tree().process_frame
		var scroll = log_text.get_parent()
		if scroll is ScrollContainer:
			var vbar = scroll.get_v_scroll_bar()
			if vbar:
				scroll.scroll_vertical = vbar.max_value

func _get_current_time_string() -> String:
	var time = Time.get_time_dict_from_system()
	var base = "%02d:%02d:%02d" % [time.hour, time.minute, time.second]
	if has_node("/root/WorldCalendar"):
		var cal = get_node("/root/WorldCalendar")
		base = cal.get_short_date() + " " + base
	return base
