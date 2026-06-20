extends CanvasLayer

const MIN_SLOT_CAPACITY: int = 24
const PANEL_HALF_WIDTH: float = 480.0
const PANEL_HALF_HEIGHT: float = 326.0

@onready var bg_overlay: ColorRect = $BGOverlay
@onready var main_panel: Panel = $MainPanel
@onready var main_container: VBoxContainer = $MainPanel/MainContainer
@onready var title_label: Label = $MainPanel/MainContainer/Header/TitleRow/TitleLabel
@onready var close_button: Button = $MainPanel/MainContainer/Header/TitleRow/CloseButton
@onready var filter_bar: HBoxContainer = $MainPanel/MainContainer/Header/FilterBar
@onready var old_scroll_container: ScrollContainer = $MainPanel/MainContainer/ScrollContainer
@onready var status_label: Label = $MainPanel/MainContainer/Footer/StatusLabel
@onready var date_label: Label = $MainPanel/MainContainer/Footer/DateLabel

var _slide_tween: Tween = null
var _current_filter: String = "all"
var _selected_quest_id: String = ""
var _filter_buttons: Dictionary = {}
var _list_slots: Array[Button] = []
var _slot_quest_ids: Array[String] = []
var _list_box: VBoxContainer = null
var _detail_box: VBoxContainer = null
var _empty_label: Label = null
var _body_split: HSplitContainer = null
var _summary_bar: HBoxContainer = null
var _summary_labels: Dictionary = {}

func _ready() -> void:
	visible = false
	_configure_panel_geometry()
	_build_body_layout()
	_init_filter_buttons()
	_init_list_slots()
	_connect_signals()
	_apply_theme()

func _configure_panel_geometry() -> void:
	main_panel.anchor_left = 0.0
	main_panel.anchor_top = 0.0
	main_panel.anchor_right = 0.0
	main_panel.anchor_bottom = 0.0
	main_panel.offset_left = 0.0
	main_panel.offset_top = 0.0
	main_panel.offset_right = PANEL_HALF_WIDTH * 2.0
	main_panel.offset_bottom = PANEL_HALF_HEIGHT * 2.0
	main_panel.position = _get_centered_panel_position()

func _get_centered_panel_position() -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := Vector2(PANEL_HALF_WIDTH * 2.0, PANEL_HALF_HEIGHT * 2.0)
	return Vector2(
		maxf((viewport_size.x - panel_size.x) * 0.5, 12.0),
		maxf((viewport_size.y - panel_size.y) * 0.5, 12.0)
	)

func _get_hidden_panel_position(target: Vector2) -> Vector2:
	return Vector2(-PANEL_HALF_WIDTH * 2.0 - 24.0, target.y)

func _build_body_layout() -> void:
	if old_scroll_container:
		old_scroll_container.visible = false
		old_scroll_container.custom_minimum_size = Vector2(0, 0)
	_build_summary_bar()
	_body_split = HSplitContainer.new()
	_body_split.name = "QuestBody"
	_body_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_split.custom_minimum_size = Vector2(0, 462)
	_body_split.split_offset = 360

	var list_panel := PanelContainer.new()
	list_panel.name = "QuestListPanel"
	list_panel.custom_minimum_size = Vector2(360, 0)
	_body_split.add_child(list_panel)

	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_child(list_scroll)

	_list_box = VBoxContainer.new()
	_list_box.name = "QuestList"
	_list_box.add_theme_constant_override("separation", 7)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(_list_box)

	_empty_label = Label.new()
	_empty_label.visible = false
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list_box.add_child(_empty_label)

	var detail_panel := PanelContainer.new()
	detail_panel.name = "QuestDetailPanel"
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_split.add_child(detail_panel)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_child(detail_scroll)

	_detail_box = VBoxContainer.new()
	_detail_box.name = "QuestDetail"
	_detail_box.add_theme_constant_override("separation", 10)
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(_detail_box)

	var footer := main_container.get_node_or_null("Footer")
	main_container.add_child(_body_split)
	if footer:
		main_container.move_child(_body_split, footer.get_index())

func _build_summary_bar() -> void:
	if _summary_bar:
		return
	var header := main_container.get_node_or_null("Header")
	if not header:
		return
	_summary_bar = HBoxContainer.new()
	_summary_bar.name = "SummaryBar"
	_summary_bar.add_theme_constant_override("separation", 8)
	_summary_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_summary_bar)
	for data in [
		{"id": "active", "label": "进行中"},
		{"id": "available", "label": "可接取"},
		{"id": "recommended", "label": "推荐"},
		{"id": "archived", "label": "归档"},
	]:
		var label := Label.new()
		label.name = "Summary" + str(data["id"]).capitalize()
		label.text = str(data["label"]) + " 0"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(92, 24)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_summary_bar.add_child(label)
		_summary_labels[str(data["id"])] = label

func _init_filter_buttons() -> void:
	_filter_buttons.clear()
	for child in filter_bar.get_children():
		if child is Button:
			child.visible = false
	for filter_data in [
		{"id": "all", "label": "全部"},
		{"id": "story", "label": "剧情"},
		{"id": "dialogue", "label": "对话"},
		{"id": "exploration", "label": "探索"},
		{"id": "collection", "label": "收集"},
		{"id": "daily", "label": "日常"},
		{"id": "hidden", "label": "隐藏"},
		{"id": "completed", "label": "归档"},
	]:
		var btn := Button.new()
		btn.text = str(filter_data["label"])
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(70, 28)
		btn.pressed.connect(_on_filter_pressed.bind(str(filter_data["id"])))
		filter_bar.add_child(btn)
		_filter_buttons[str(filter_data["id"])] = btn

func _init_list_slots() -> void:
	_list_slots.clear()
	_slot_quest_ids.clear()
	_ensure_slot_capacity(MIN_SLOT_CAPACITY)

func _ensure_slot_capacity(count: int) -> void:
	while _list_slots.size() < count:
		var idx := _list_slots.size()
		var slot := Button.new()
		slot.name = "QuestSlot" + str(idx)
		slot.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot.focus_mode = Control.FOCUS_NONE
		slot.clip_text = true
		slot.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		slot.custom_minimum_size = Vector2(0, 72)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.visible = false
		slot.pressed.connect(_on_slot_pressed.bind(idx))
		_list_box.add_child(slot)
		_list_slots.append(slot)
		_slot_quest_ids.append("")

func _connect_signals() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)
	if has_node("/root/QuestManager"):
		var qm = get_node("/root/QuestManager")
		qm.quest_updated.connect(_on_quest_changed)
		qm.quest_completed.connect(_on_quest_completed)
		qm.new_quest_available.connect(_on_quest_changed)
		qm.quest_accepted.connect(_on_quest_changed)
		if qm.has_signal("quest_tracked_changed"):
			qm.quest_tracked_changed.connect(_on_tracked_changed)
		if qm.has_signal("quest_recommendations_changed"):
			qm.quest_recommendations_changed.connect(_on_recommendations_changed)
		if qm.has_signal("daily_quests_reset"):
			qm.daily_quests_reset.connect(_on_daily_quests_reset)

func _apply_theme() -> void:
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()
	if main_panel:
		main_panel.add_theme_stylebox_override("panel", tm.make_panel_style())
	if title_label:
		title_label.add_theme_color_override("font_color", t["title_color"])
		tm.apply_font_bold_to_label(title_label, 22)
	if close_button:
		var close_styles = tm.make_close_button_styles()
		close_button.add_theme_stylebox_override("normal", close_styles["normal"])
		close_button.add_theme_stylebox_override("hover", close_styles["hover"])
		close_button.add_theme_color_override("font_color", Color(1, 0.85, 0.85))
	if _body_split:
		for panel in [_body_split.get_child(0), _body_split.get_child(1)]:
			if panel is PanelContainer:
				panel.add_theme_stylebox_override("panel", tm.make_card_style())
	if _empty_label:
		_empty_label.add_theme_color_override("font_color", t["secondary_color"])
		tm.apply_font_to_label(_empty_label, 14)
	if status_label:
		status_label.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.65))
	if date_label:
		date_label.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.65))
	_update_date_label()
	_apply_summary_styles()
	_apply_filter_styles()

func _apply_summary_styles() -> void:
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()
	for key in _summary_labels:
		var label: Label = _summary_labels[key]
		var color: Color = t["accent_color"]
		if key == "active":
			color = t["success_color"]
		elif key == "available":
			color = t["accent_color"]
		elif key == "recommended":
			color = t["warning_color"]
		elif key == "archived":
			color = t["secondary_color"]
		label.add_theme_color_override("font_color", color)
		label.add_theme_stylebox_override("normal", _make_pill_style(color, 0.12, 0.42))
		tm.apply_font_to_label(label, 12, true)

func _apply_filter_styles() -> void:
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	for filter_id in _filter_buttons:
		var btn: Button = _filter_buttons[filter_id]
		var styles = tm.make_filter_button_styles(filter_id == _current_filter)
		btn.add_theme_stylebox_override("normal", styles["normal"])
		btn.add_theme_stylebox_override("hover", styles["hover"])
		btn.add_theme_color_override("font_color", styles["font_color"])
		tm.apply_font_to_button(btn, 13)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q and not _is_dialogue_open():
			toggle_panel()
			get_viewport().set_input_as_handled()

func _is_dialogue_open() -> bool:
	var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
	return dialogue_ui and dialogue_ui.visible

func toggle_panel() -> void:
	if visible:
		hide_panel()
	else:
		show_panel()

func show_panel() -> void:
	refresh_quests()
	_configure_panel_geometry()
	var target_position := _get_centered_panel_position()
	visible = true
	bg_overlay.visible = true
	main_panel.visible = true
	main_panel.modulate = Color(1, 1, 1, 0)
	main_panel.position = _get_hidden_panel_position(target_position)
	if _slide_tween:
		_slide_tween.kill()
	_slide_tween = create_tween()
	_slide_tween.set_ease(Tween.EASE_OUT)
	_slide_tween.set_trans(Tween.TRANS_CUBIC)
	_slide_tween.tween_property(main_panel, "position", target_position, 0.28)
	_slide_tween.parallel().tween_property(main_panel, "modulate", Color(1, 1, 1, 1), 0.22)

func hide_panel() -> void:
	if _slide_tween:
		_slide_tween.kill()
	var target_position := _get_centered_panel_position()
	_slide_tween = create_tween()
	_slide_tween.set_ease(Tween.EASE_IN)
	_slide_tween.set_trans(Tween.TRANS_CUBIC)
	_slide_tween.tween_property(main_panel, "position", _get_hidden_panel_position(target_position), 0.22)
	_slide_tween.parallel().tween_property(main_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	_slide_tween.tween_callback(func():
		visible = false
		bg_overlay.visible = false
		main_panel.visible = false
	)

func refresh_quests() -> void:
	if not has_node("/root/QuestManager") or not has_node("/root/UIThemeManager"):
		return
	var qm = get_node("/root/QuestManager")
	var live_quests: Array = qm.get_quest_view_data("all", false)
	var archived_quests: Array = qm.get_completed_archive_data()
	var quests: Array = qm.get_completed_archive_data() if _current_filter == "completed" else qm.get_quest_view_data(_current_filter, false)
	_validate_selected_quest(quests)
	_update_summary(live_quests, archived_quests.size())
	_update_list_slots(quests)
	_update_detail(quests)
	_update_footer(quests.size(), live_quests.size(), archived_quests.size())

func _validate_selected_quest(quests: Array) -> void:
	for quest in quests:
		if quest is Dictionary and str(quest.get("id", "")) == _selected_quest_id:
			return
	_selected_quest_id = ""
	if not quests.is_empty() and quests[0] is Dictionary:
		_selected_quest_id = str(quests[0].get("id", ""))

func _update_list_slots(quests: Array) -> void:
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()
	_ensure_slot_capacity(maxi(quests.size(), MIN_SLOT_CAPACITY))
	_empty_label.visible = quests.is_empty()
	_empty_label.text = "暂无任务记录"
	for i in range(_list_slots.size()):
		if i >= quests.size():
			_list_slots[i].visible = false
			_slot_quest_ids[i] = ""
			continue
		var quest: Dictionary = quests[i]
		var slot := _list_slots[i]
		var quest_id := str(quest.get("id", ""))
		_slot_quest_ids[i] = quest_id
		slot.visible = true
		slot.text = _quest_slot_text(quest)
		slot.tooltip_text = str(quest.get("description", ""))
		var selected := quest_id == _selected_quest_id
		var type_color: Color = tm.get_quest_type_color(str(quest.get("type_key", "dialogue")))
		slot.add_theme_stylebox_override("normal", _make_slot_style(t, type_color, selected, false))
		slot.add_theme_stylebox_override("hover", _make_slot_style(t, type_color, selected, true))
		slot.add_theme_color_override("font_color", t["title_color"] if selected else t["text_color"])
		tm.apply_font_to_button(slot, 13)
		slot.disabled = false

func _update_detail(quests: Array) -> void:
	for child in _detail_box.get_children():
		child.free()
	var quest := _find_quest_entry(quests, _selected_quest_id)
	if quest.is_empty():
		_add_detail_empty("选择一个任务查看详情")
		return
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()
	var type_key := str(quest.get("type_key", "dialogue"))

	var hero := PanelContainer.new()
	hero.name = "QuestDetailHero"
	hero.add_theme_stylebox_override("panel", _make_detail_hero_style(t, tm.get_quest_type_color(type_key)))
	_detail_box.add_child(hero)

	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 8)
	hero.add_child(hero_box)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	hero_box.add_child(title_row)

	var type_label := Label.new()
	type_label.text = tm.get_quest_type_icon(type_key) + " " + str(quest.get("type", "任务"))
	type_label.add_theme_color_override("font_color", tm.get_quest_type_color(type_key))
	type_label.add_theme_font_size_override("font_size", 13)
	type_label.add_theme_stylebox_override("normal", tm.make_quest_type_tag(type_key))
	title_row.add_child(type_label)

	var status_label_detail := Label.new()
	status_label_detail.text = str(quest.get("status", ""))
	status_label_detail.add_theme_color_override("font_color", _status_color(quest, t))
	status_label_detail.add_theme_font_size_override("font_size", 13)
	status_label_detail.add_theme_stylebox_override("normal", _make_pill_style(_status_color(quest, t), 0.12, 0.52))
	title_row.add_child(status_label_detail)

	if bool(quest.get("tracked", false)):
		var tracked_label := Label.new()
		tracked_label.text = "追踪中"
		tracked_label.add_theme_color_override("font_color", t["accent_color"])
		tracked_label.add_theme_font_size_override("font_size", 13)
		tracked_label.add_theme_stylebox_override("normal", _make_pill_style(t["accent_color"], 0.12, 0.5))
		title_row.add_child(tracked_label)

	var title := Label.new()
	title.text = str(quest.get("title", ""))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", t["text_color"])
	hero_box.add_child(title)

	var desc := Label.new()
	desc.text = str(quest.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", t["secondary_color"])
	hero_box.add_child(desc)

	_add_progress_detail(quest, tm, t)
	_add_section_heading("任务目标", t["title_color"])
	_add_text_line("目标: " + str(quest.get("target_hint", "继续探索")), t["hint_color"])
	if not str(quest.get("target_action", "")).is_empty():
		_add_text_line(str(quest.get("target_action", "")), t["secondary_color"])
	if not str(quest.get("recommended_reason", "")).is_empty():
		_add_section_heading("今日推荐", t["warning_color"])
		_add_text_line("推荐: " + str(quest.get("recommended_reason", "")), t["warning_color"])
	if not str(quest.get("reward", "")).is_empty():
		_add_section_heading("报酬", t["title_color"])
		_add_text_line("奖励: " + str(quest.get("reward", "")), t["warning_color"])
	if int(quest.get("completed_day", 0)) > 0:
		_add_text_line("完成于第 " + str(int(quest.get("completed_day", 0))) + " 天", t["secondary_color"])
	_add_detail_actions(quest)

func _add_progress_detail(quest: Dictionary, tm: Node, t: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_detail_box.add_child(row)
	var bar := ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0, 16)
	bar.show_percentage = false
	bar.value = clampf(float(quest.get("progress_ratio", 0.0)) * 100.0, 0.0, 100.0)
	var progress_styles = tm.make_progress_bar_styles()
	bar.add_theme_stylebox_override("background", progress_styles["bg"])
	bar.add_theme_stylebox_override("fill", progress_styles["fill"])
	row.add_child(bar)
	var text := Label.new()
	text.text = str(quest.get("progress", "0/1"))
	text.add_theme_color_override("font_color", t["accent_color"])
	row.add_child(text)

func _add_text_line(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	_detail_box.add_child(label)

func _add_section_heading(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	_detail_box.add_child(label)

func _add_detail_actions(quest: Dictionary) -> void:
	var qm = get_node("/root/QuestManager")
	var tm = get_node_or_null("/root/UIThemeManager")
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	_detail_box.add_child(actions)
	var quest_id := str(quest.get("id", ""))
	var status_text := str(quest.get("status", ""))
	if status_text == "可接取":
		var accept_btn := Button.new()
		accept_btn.text = "接取任务"
		accept_btn.custom_minimum_size = Vector2(98, 32)
		_style_action_button(accept_btn, "accept", tm)
		accept_btn.pressed.connect(func():
			qm.accept_quest(quest_id)
			refresh_quests()
		)
		actions.add_child(accept_btn)
	if status_text != "已完成":
		var track_btn := Button.new()
		track_btn.text = "取消追踪" if bool(quest.get("tracked", false)) else "追踪"
		track_btn.custom_minimum_size = Vector2(98, 32)
		_style_action_button(track_btn, "normal", tm)
		track_btn.pressed.connect(func():
			if bool(quest.get("tracked", false)):
				qm.untrack_quest()
			else:
				qm.track_quest(quest_id)
			refresh_quests()
		)
		actions.add_child(track_btn)
	if not str(quest.get("target_area", "")).is_empty() and status_text != "已完成":
		var jump_btn := Button.new()
		jump_btn.text = "前往目标"
		jump_btn.custom_minimum_size = Vector2(98, 32)
		_style_action_button(jump_btn, "normal", tm)
		jump_btn.pressed.connect(func():
			qm.transition_to_quest_target(quest_id)
		)
		actions.add_child(jump_btn)
	if actions.get_child_count() == 0:
		_add_text_line("该任务已归档，暂无可用操作", get_node("/root/UIThemeManager").get_theme()["secondary_color"])

func _add_detail_empty(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	if has_node("/root/UIThemeManager"):
		label.add_theme_color_override("font_color", get_node("/root/UIThemeManager").get_theme()["secondary_color"])
	_detail_box.add_child(label)

func _update_footer(count: int, live_count: int = 0, archived_count: int = 0) -> void:
	if status_label:
		status_label.text = "◈ DATAWHALE 任务系统 · 当前 " + str(count) + " 项 · 进行中档案 " + str(live_count) + " · 归档 " + str(archived_count)
	_update_date_label()

func _quest_slot_text(quest: Dictionary) -> String:
	var tm = get_node("/root/UIThemeManager")
	var type_key := str(quest.get("type_key", "dialogue"))
	var prefix := "★ " if bool(quest.get("tracked", false)) else ""
	var recommend := " · " + str(quest.get("recommended_reason", "")) if not str(quest.get("recommended_reason", "")).is_empty() else ""
	return "%s%s %s\n%s · %s · %s%s" % [
		prefix,
		tm.get_quest_type_icon(type_key),
		_shorten(str(quest.get("title", "")), 18),
		str(quest.get("status", "")),
		str(quest.get("progress", "")),
		_shorten(str(quest.get("target_hint", "")), 18),
		recommend,
	]

func _update_summary(live_quests: Array, archived_count: int) -> void:
	var active_count := 0
	var available_count := 0
	var recommended_count := 0
	for quest in live_quests:
		if not quest is Dictionary:
			continue
		match str(quest.get("status", "")):
			"进行中":
				active_count += 1
			"可接取":
				available_count += 1
		if not str(quest.get("recommended_reason", "")).is_empty():
			recommended_count += 1
	_set_summary_text("active", "进行中 " + str(active_count))
	_set_summary_text("available", "可接取 " + str(available_count))
	_set_summary_text("recommended", "推荐 " + str(recommended_count))
	_set_summary_text("archived", "归档 " + str(archived_count))

func _set_summary_text(key: String, text: String) -> void:
	if _summary_labels.has(key) and _summary_labels[key] is Label:
		_summary_labels[key].text = text

func _make_slot_style(t: Dictionary, type_color: Color, selected: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var base: Color = t["filter_active_bg"] if selected else t["card_bg"]
	var bg_alpha := 0.96 if selected else 0.86
	if hover:
		bg_alpha = minf(bg_alpha + 0.1, 1.0)
	style.bg_color = Color(base.r, base.g, base.b, bg_alpha)
	style.border_color = Color(type_color.r, type_color.g, type_color.b, 0.85 if selected else 0.45)
	style.set_border_width(SIDE_LEFT, 3 if selected else 2)
	style.set_border_width(SIDE_TOP, 1)
	style.set_border_width(SIDE_RIGHT, 1)
	style.set_border_width(SIDE_BOTTOM, 1)
	style.set_corner_radius_all(int(t.get("card_corner", 8)))
	style.content_margin_left = 12
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(type_color.r, type_color.g, type_color.b, 0.16 if selected else 0.08)
	style.shadow_size = 4 if selected else 1
	return style

func _make_detail_hero_style(t: Dictionary, type_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var card: Color = t["card_bg"]
	style.bg_color = Color(card.r, card.g, card.b, 0.96)
	style.border_color = Color(type_color.r, type_color.g, type_color.b, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(t.get("card_corner", 8)))
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(type_color.r, type_color.g, type_color.b, 0.12)
	style.shadow_size = 3
	return style

func _make_pill_style(color: Color, bg_alpha: float, border_alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, bg_alpha)
	style.border_color = Color(color.r, color.g, color.b, border_alpha)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

func _style_action_button(btn: Button, role: String, tm: Node) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	if not tm:
		return
	if role == "accept":
		var accept_styles = tm.make_accept_button_styles()
		btn.add_theme_stylebox_override("normal", accept_styles["normal"])
		btn.add_theme_stylebox_override("hover", accept_styles["hover"])
		btn.add_theme_stylebox_override("pressed", accept_styles["pressed"])
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		var styles = tm.make_filter_button_styles(false)
		btn.add_theme_stylebox_override("normal", styles["normal"])
		btn.add_theme_stylebox_override("hover", styles["hover"])
		btn.add_theme_color_override("font_color", styles["font_color"])
	tm.apply_font_to_button(btn, 13)

func _shorten(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.left(maxi(max_chars - 1, 1)) + "…"

func _find_quest_entry(quests: Array, quest_id: String) -> Dictionary:
	for quest in quests:
		if quest is Dictionary and str(quest.get("id", "")) == quest_id:
			return quest
	return {}

func _status_color(quest: Dictionary, t: Dictionary) -> Color:
	match str(quest.get("status", "")):
		"进行中":
			return t["success_color"]
		"可接取":
			return t["accent_color"]
		"已完成":
			return t["warning_color"]
		_:
			return t["secondary_color"]

func _on_slot_pressed(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= _slot_quest_ids.size():
		return
	_selected_quest_id = _slot_quest_ids[slot_idx]
	refresh_quests()

func _on_filter_pressed(filter_id: String) -> void:
	_current_filter = filter_id
	_selected_quest_id = ""
	_apply_filter_styles()
	refresh_quests()

func _on_close_button_pressed() -> void:
	hide_panel()

func _on_quest_changed(_quest_id: String, _status: int = 0) -> void:
	if visible:
		refresh_quests()

func _on_quest_completed(quest_id: String) -> void:
	if visible:
		refresh_quests()
		_play_completion_feedback(quest_id)

func _on_tracked_changed(_quest_id: String) -> void:
	if visible:
		refresh_quests()

func _on_recommendations_changed() -> void:
	if visible:
		refresh_quests()

func _on_daily_quests_reset() -> void:
	if status_label:
		status_label.text = "每日任务已刷新"
	if visible:
		refresh_quests()

func _on_phase_changed(_new_phase) -> void:
	_apply_theme()
	if visible:
		refresh_quests()

func _play_completion_feedback(_quest_id: String) -> void:
	if not title_label:
		return
	var tween := create_tween()
	title_label.modulate = Color(1.0, 0.9, 0.25, 1.0)
	tween.tween_property(title_label, "modulate", Color(1, 1, 1, 1), 0.65)

func _update_date_label() -> void:
	if not date_label:
		return
	if has_node("/root/WorldCalendar"):
		var cal = get_node("/root/WorldCalendar")
		date_label.text = cal.get_day_string() + " | " + cal.get_short_date()
	else:
		date_label.text = ""
