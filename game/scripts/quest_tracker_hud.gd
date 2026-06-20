extends CanvasLayer

var _panel: PanelContainer = null
var _title_label: Label = null
var _target_label: Label = null
var _progress_bar: ProgressBar = null
var _progress_label: Label = null
var _hint_label: Label = null
var _toast_panel: PanelContainer = null
var _toast_label: Label = null
var _toast_tween: Tween = null
var _refresh_timer: float = 0.0

func _ready() -> void:
	layer = 8
	_build_ui()
	_connect_signals()
	_apply_theme()
	_refresh_hud()

func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= 0.5:
		_refresh_timer = 0.0
		_sync_visibility()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "TrackerPanel"
	_panel.anchor_left = 0.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = 18
	_panel.offset_top = 82
	_panel.offset_right = 342
	_panel.offset_bottom = 182
	_panel.visible = false
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	_panel.add_child(box)

	_title_label = Label.new()
	_title_label.text = ""
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(_title_label)

	_target_label = Label.new()
	_target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_target_label)

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 8)
	box.add_child(progress_row)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 12)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.show_percentage = false
	progress_row.add_child(_progress_bar)

	_progress_label = Label.new()
	_progress_label.custom_minimum_size = Vector2(44, 0)
	progress_row.add_child(_progress_label)

	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint_label)

	_toast_panel = PanelContainer.new()
	_toast_panel.name = "QuestToast"
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_top = 0.0
	_toast_panel.anchor_right = 0.5
	_toast_panel.anchor_bottom = 0.0
	_toast_panel.offset_left = -190
	_toast_panel.offset_top = 22
	_toast_panel.offset_right = 190
	_toast_panel.offset_bottom = 68
	_toast_panel.visible = false
	add_child(_toast_panel)

	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_panel.add_child(_toast_label)

func _connect_signals() -> void:
	var qm = get_node_or_null("/root/QuestManager")
	if qm:
		if qm.has_signal("quest_tracked_changed"):
			qm.quest_tracked_changed.connect(_on_quest_tracked_changed)
		if qm.has_signal("quest_progressed"):
			qm.quest_progressed.connect(_on_quest_progressed)
		qm.quest_completed.connect(_on_quest_completed)
		if qm.has_signal("daily_quests_reset"):
			qm.daily_quests_reset.connect(_on_daily_quests_reset)
		if qm.has_signal("quest_recommendations_changed"):
			qm.quest_recommendations_changed.connect(_on_recommendations_changed)
	var dnm = get_node_or_null("/root/DayNightManager")
	if dnm and dnm.has_signal("phase_changed"):
		dnm.phase_changed.connect(func(_phase): _apply_theme())

func _apply_theme() -> void:
	var tm = get_node_or_null("/root/UIThemeManager")
	if not tm:
		return
	var t = tm.get_theme()
	if _panel:
		_panel.add_theme_stylebox_override("panel", tm.make_card_style())
	if _toast_panel:
		_toast_panel.add_theme_stylebox_override("panel", tm.make_panel_style())
	if _title_label:
		_title_label.add_theme_font_size_override("font_size", 14)
		_title_label.add_theme_color_override("font_color", t["title_color"])
	if _target_label:
		_target_label.add_theme_font_size_override("font_size", 12)
		_target_label.add_theme_color_override("font_color", t["text_color"])
	if _progress_label:
		_progress_label.add_theme_font_size_override("font_size", 11)
		_progress_label.add_theme_color_override("font_color", t["accent_color"])
	if _hint_label:
		_hint_label.add_theme_font_size_override("font_size", 11)
		_hint_label.add_theme_color_override("font_color", t["warning_color"])
	if _toast_label:
		_toast_label.add_theme_font_size_override("font_size", 14)
		_toast_label.add_theme_color_override("font_color", t["text_color"])
	if _progress_bar:
		var progress_styles = tm.make_progress_bar_styles()
		_progress_bar.add_theme_stylebox_override("background", progress_styles["bg"])
		_progress_bar.add_theme_stylebox_override("fill", progress_styles["fill"])

func _refresh_hud() -> void:
	var qm = get_node_or_null("/root/QuestManager")
	if not qm:
		_panel.visible = false
		return
	var quest: Dictionary = qm.get_tracked_quest_display_data()
	if quest.is_empty() or str(quest.get("status", "")) == "已完成":
		quest = _get_first_recommended_quest(qm)
	if quest.is_empty():
		_panel.visible = false
		return
	_title_label.text = ("追踪 " if bool(quest.get("tracked", false)) else "推荐 ") + str(quest.get("title", ""))
	_target_label.text = str(quest.get("target_hint", "继续探索"))
	_progress_bar.value = clampf(float(quest.get("progress_ratio", 0.0)) * 100.0, 0.0, 100.0)
	_progress_label.text = str(quest.get("progress", "0/1"))
	_hint_label.text = str(quest.get("recommended_reason", quest.get("reward", "")))
	_sync_visibility()

func _get_first_recommended_quest(qm: Node) -> Dictionary:
	for quest in qm.get_quest_view_data("all", false):
		if quest is Dictionary and not str(quest.get("recommended_reason", "")).is_empty():
			return quest
	return {}

func _sync_visibility() -> void:
	if not _panel:
		return
	var should_show := _has_displayable_hud_data() and not _is_blocked_scene()
	_panel.visible = should_show

func _has_displayable_hud_data() -> bool:
	var qm = get_node_or_null("/root/QuestManager")
	if not qm:
		return false
	var tracked: Dictionary = qm.get_tracked_quest_display_data()
	if not tracked.is_empty() and str(tracked.get("status", "")) != "已完成":
		return true
	return not _get_first_recommended_quest(qm).is_empty()

func _is_blocked_scene() -> bool:
	var current = get_tree().current_scene
	if current and str(current.name).to_lower().contains("character"):
		return true
	var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue_ui and dialogue_ui.visible:
		return true
	var quest_panel = get_tree().get_first_node_in_group("quest_panel")
	if quest_panel and quest_panel.visible:
		return true
	var sm = get_node_or_null("/root/SceneManager")
	if sm and sm.has_method("is_rift_run") and sm.is_rift_run():
		return true
	return false

func _show_toast(text: String) -> void:
	if not _toast_panel or not _toast_label:
		return
	_toast_label.text = text
	_toast_panel.visible = true
	_toast_panel.modulate = Color(1, 1, 1, 0)
	_toast_panel.position.y = 0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.set_ease(Tween.EASE_OUT)
	_toast_tween.set_trans(Tween.TRANS_CUBIC)
	_toast_tween.tween_property(_toast_panel, "modulate", Color(1, 1, 1, 1), 0.18)
	_toast_tween.parallel().tween_property(_toast_panel, "position:y", 8.0, 0.18)
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast_panel, "modulate", Color(1, 1, 1, 0), 0.25)
	_toast_tween.tween_callback(func(): _toast_panel.visible = false)

func _on_quest_tracked_changed(_quest_id: String) -> void:
	_refresh_hud()

func _on_quest_progressed(_quest_id: String, _progress: int, _target: int) -> void:
	_refresh_hud()

func _on_quest_completed(quest_id: String) -> void:
	var title := quest_id
	var qm = get_node_or_null("/root/QuestManager")
	if qm:
		for quest in qm.get_completed_archive_data():
			if quest is Dictionary and str(quest.get("id", "")) == quest_id:
				title = str(quest.get("title", quest_id))
				break
	_show_toast("任务完成: " + title)
	_refresh_hud()

func _on_daily_quests_reset() -> void:
	_show_toast("每日任务已刷新")
	_refresh_hud()

func _on_recommendations_changed() -> void:
	_refresh_hud()
