extends CanvasLayer

const MAX_CARDS: int = 10

@onready var bg_overlay: ColorRect = $BGOverlay
@onready var main_panel: Panel = $MainPanel
@onready var title_label: Label = $MainPanel/MainContainer/Header/TitleRow/TitleLabel
@onready var close_button: Button = $MainPanel/MainContainer/Header/TitleRow/CloseButton
@onready var filter_bar: HBoxContainer = $MainPanel/MainContainer/Header/FilterBar
@onready var filter_all: Button = $MainPanel/MainContainer/Header/FilterBar/FilterAll
@onready var filter_dialogue: Button = $MainPanel/MainContainer/Header/FilterBar/FilterDialogue
@onready var filter_exploration: Button = $MainPanel/MainContainer/Header/FilterBar/FilterExploration
@onready var filter_collection: Button = $MainPanel/MainContainer/Header/FilterBar/FilterCollection
@onready var filter_daily: Button = $MainPanel/MainContainer/Header/FilterBar/FilterDaily
@onready var card_pool: VBoxContainer = $MainPanel/MainContainer/ScrollContainer/CardPool
@onready var status_label: Label = $MainPanel/MainContainer/Footer/StatusLabel
@onready var date_label: Label = $MainPanel/MainContainer/Footer/DateLabel

var _slide_tween: Tween = null
var _current_filter: String = "全部"
var _filter_buttons: Dictionary = {}
var _card_slots: Array = []

var _type_icons: Dictionary = {
	"dialogue": "💬",
	"exploration": "🔍",
	"collection": "📦",
	"daily": "🔄",
	"hidden": "👻",
}

# 预创建的样式实例（一次性初始化）
var _panel_style: StyleBoxFlat = null
var _card_style: StyleBoxFlat = null
var _title_style: StyleBoxFlat = null
var _close_normal_style: StyleBoxFlat = null
var _close_hover_style: StyleBoxFlat = null
var _scroll_style: StyleBoxFlat = null
var _progress_bg_style: StyleBoxFlat = null
var _progress_fill_style: StyleBoxFlat = null
var _accept_normal_style: StyleBoxFlat = null
var _accept_hover_style: StyleBoxFlat = null
var _accept_pressed_style: StyleBoxFlat = null
var _tag_styles: Dictionary = {}

func _ready():
	visible = false
	_init_card_slots()
	_init_filter_buttons()
	_init_styles()
	_connect_signals()
	_apply_theme()

func _init_card_slots():
	for i in range(MAX_CARDS):
		var slot = card_pool.get_child(i)
		if slot:
			_card_slots.append(slot)
			_setup_card_slot(slot, i)

func _setup_card_slot(slot: PanelContainer, idx: int):
	slot.name = "CardSlot" + str(idx)
	var hbox = HBoxContainer.new()
	hbox.name = "CardContent"
	hbox.add_theme_constant_override("separation", 12)
	slot.add_child(hbox)

	var indicator_vbox = VBoxContainer.new()
	indicator_vbox.name = "Indicator"
	indicator_vbox.add_theme_constant_override("separation", 0)
	indicator_vbox.custom_minimum_size = Vector2(12, 0)

	var dot = ColorRect.new()
	dot.name = "Dot"
	dot.custom_minimum_size = Vector2(10, 10)
	dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	indicator_vbox.add_child(dot)

	var line = ColorRect.new()
	line.name = "Line"
	line.custom_minimum_size = Vector2(2, 0)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	indicator_vbox.add_child(line)

	hbox.add_child(indicator_vbox)

	var vbox = VBoxContainer.new()
	vbox.name = "Content"
	vbox.add_theme_constant_override("separation", 5)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_hbox = HBoxContainer.new()
	title_hbox.name = "TitleRow"
	title_hbox.add_theme_constant_override("separation", 8)

	var type_tag = PanelContainer.new()
	type_tag.name = "TypeTag"
	var tag_hbox = HBoxContainer.new()
	tag_hbox.name = "TagHBox"
	tag_hbox.add_theme_constant_override("separation", 3)
	type_tag.add_child(tag_hbox)
	title_hbox.add_child(type_tag)

	var type_icon_lbl = Label.new()
	type_icon_lbl.name = "TypeIcon"
	tag_hbox.add_child(type_icon_lbl)

	var type_lbl = Label.new()
	type_lbl.name = "TypeLabel"
	tag_hbox.add_child(type_lbl)

	var title_lbl = Label.new()
	title_lbl.name = "Title"
	title_hbox.add_child(title_lbl)

	var status_lbl = Label.new()
	status_lbl.name = "Status"
	status_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_hbox.add_child(status_lbl)

	vbox.add_child(title_hbox)

	var desc_lbl = Label.new()
	desc_lbl.name = "Description"
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	var progress_hbox = HBoxContainer.new()
	progress_hbox.name = "ProgressRow"
	progress_hbox.add_theme_constant_override("separation", 10)

	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(120, 14)
	progress_bar.show_percentage = false
	progress_hbox.add_child(progress_bar)

	var progress_text = Label.new()
	progress_text.name = "ProgressText"
	progress_hbox.add_child(progress_text)

	vbox.add_child(progress_hbox)

	var reward_hbox = HBoxContainer.new()
	reward_hbox.name = "RewardRow"
	reward_hbox.add_theme_constant_override("separation", 4)

	var reward_icon = Label.new()
	reward_icon.name = "RewardIcon"
	reward_icon.text = "🎁"
	reward_hbox.add_child(reward_icon)

	var reward_lbl = Label.new()
	reward_lbl.name = "RewardLabel"
	reward_hbox.add_child(reward_lbl)

	vbox.add_child(reward_hbox)

	var action_btn = Button.new()
	action_btn.name = "ActionButton"
	action_btn.custom_minimum_size = Vector2(80, 30)
	action_btn.visible = false
	vbox.add_child(action_btn)

	hbox.add_child(vbox)

func _init_filter_buttons():
	_filter_buttons["全部"] = filter_all
	_filter_buttons["对话"] = filter_dialogue
	_filter_buttons["探索"] = filter_exploration
	_filter_buttons["收集"] = filter_collection
	_filter_buttons["日常"] = filter_daily

	filter_all.pressed.connect(_on_filter_pressed.bind("全部"))
	filter_dialogue.pressed.connect(_on_filter_pressed.bind("对话"))
	filter_exploration.pressed.connect(_on_filter_pressed.bind("探索"))
	filter_collection.pressed.connect(_on_filter_pressed.bind("收集"))
	filter_daily.pressed.connect(_on_filter_pressed.bind("日常"))

func _init_styles():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()

	_panel_style = tm.make_panel_style()
	_card_style = tm.make_card_style()
	_title_style = tm.make_title_bar_style()

	var close_styles = tm.make_close_button_styles()
	_close_normal_style = close_styles["normal"]
	_close_hover_style = close_styles["hover"]

	_scroll_style = tm.make_scroll_container_style()

	var prog_styles = tm.make_progress_bar_styles()
	_progress_bg_style = prog_styles["bg"]
	_progress_fill_style = prog_styles["fill"]

	var accept_styles = tm.make_accept_button_styles()
	_accept_normal_style = accept_styles["normal"]
	_accept_hover_style = accept_styles["hover"]
	_accept_pressed_style = accept_styles["pressed"]

	for type_key in ["dialogue", "exploration", "collection", "daily", "hidden"]:
		_tag_styles[type_key] = tm.make_quest_type_tag(type_key)

func _connect_signals():
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)
	if has_node("/root/QuestManager"):
		var qm = get_node("/root/QuestManager")
		qm.quest_updated.connect(_on_quest_updated)
		qm.quest_completed.connect(_on_quest_completed)
		qm.new_quest_available.connect(_on_new_quest_available)
		qm.quest_accepted.connect(_on_quest_accepted)

func _apply_theme():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()

	if main_panel and _panel_style:
		main_panel.add_theme_stylebox_override("panel", _panel_style)

	if title_label:
		title_label.add_theme_color_override("font_color", t["title_color"])
		tm.apply_font_bold_to_label(title_label, 22)

	if close_button:
		if _close_normal_style:
			close_button.add_theme_stylebox_override("normal", _close_normal_style)
		if _close_hover_style:
			close_button.add_theme_stylebox_override("hover", _close_hover_style)
		close_button.add_theme_color_override("font_color", Color(1, 0.85, 0.85))

	if status_label:
		status_label.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.6))
		tm.apply_font_to_label(status_label, 12)

	if date_label:
		date_label.add_theme_color_override("font_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.6))
		tm.apply_font_to_label(date_label, 12)

	_update_date_label()
	_apply_filter_styles()

func _apply_filter_styles():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	for filter_name in _filter_buttons:
		var btn = _filter_buttons[filter_name]
		var is_active = (filter_name == _current_filter)
		var styles = tm.make_filter_button_styles(is_active)
		btn.add_theme_stylebox_override("normal", styles["normal"])
		btn.add_theme_stylebox_override("hover", styles["hover"])
		btn.add_theme_color_override("font_color", styles["font_color"])
		tm.apply_font_to_button(btn, 13)

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			if not _is_dialogue_open():
				if OS.is_debug_build():
					print("[QuestPanel] Q pressed, toggling panel")
				toggle_panel()
				get_viewport().set_input_as_handled()

func _is_dialogue_open() -> bool:
	var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue_ui and dialogue_ui.visible:
		return true
	return false

func toggle_panel():
	if visible:
		hide_panel()
	else:
		show_panel()

func show_panel():
	refresh_quests()
	visible = true
	bg_overlay.visible = true
	main_panel.visible = true
	main_panel.modulate = Color(1, 1, 1, 0)
	main_panel.position.x = -620

	if _slide_tween:
		_slide_tween.kill()
	_slide_tween = create_tween()
	_slide_tween.set_ease(Tween.EASE_OUT)
	_slide_tween.set_trans(Tween.TRANS_CUBIC)
	_slide_tween.tween_property(main_panel, "position:x", -300.0, 0.3)
	_slide_tween.parallel().tween_property(main_panel, "modulate", Color(1, 1, 1, 1), 0.25)

func hide_panel():
	if _slide_tween:
		_slide_tween.kill()
	_slide_tween = create_tween()
	_slide_tween.set_ease(Tween.EASE_IN)
	_slide_tween.set_trans(Tween.TRANS_CUBIC)
	_slide_tween.tween_property(main_panel, "position:x", -620.0, 0.25)
	_slide_tween.parallel().tween_property(main_panel, "modulate", Color(1, 1, 1, 0), 0.2)
	_slide_tween.tween_callback(func():
		visible = false
		bg_overlay.visible = false
		main_panel.visible = false
	)

func _on_close_button_pressed():
	hide_panel()

func _on_filter_pressed(filter_name: String):
	_current_filter = filter_name
	_apply_filter_styles()
	refresh_quests()

func _on_quest_updated(_quest_id: String, _status: int):
	if visible:
		refresh_quests()

func _on_quest_completed(_quest_id: String):
	if visible:
		refresh_quests()

func _on_new_quest_available(_quest_id: String):
	if visible:
		refresh_quests()

func _on_quest_accepted(_quest_id: String):
	if visible:
		refresh_quests()

func _on_phase_changed(_new_phase):
	_apply_theme()

func _update_date_label():
	if not date_label:
		return
	if has_node("/root/WorldCalendar"):
		var cal = get_node("/root/WorldCalendar")
		date_label.text = cal.get_day_string() + " | " + cal.get_short_date()
	else:
		date_label.text = ""

func refresh_quests():
	if not has_node("/root/QuestManager"):
		if OS.is_debug_build():
			print("[QuestPanel] QuestManager not found!")
		return
	if not has_node("/root/UIThemeManager"):
		if OS.is_debug_build():
			print("[QuestPanel] UIThemeManager not found!")
		return

	var quest_manager = get_node("/root/QuestManager")
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()
	var quests = quest_manager.get_quest_display_data()

	if OS.is_debug_build():
		print("[QuestPanel] Got ", quests.size(), " quests, filter=", _current_filter)

	var filtered_quests: Array = []
	if _current_filter == "全部":
		filtered_quests = quests
	else:
		for quest in quests:
			if quest.get("type", "对话") == _current_filter:
				filtered_quests.append(quest)

	print("[QuestPanel] Filtered: ", filtered_quests.size(), " quests")

	if filtered_quests.size() == 0:
		for i in range(MAX_CARDS):
			_hide_card_slot(i)
		_show_empty_message(t, tm)
		return

	var idx = 0
	for quest in filtered_quests:
		if idx < MAX_CARDS:
			_update_card_data(idx, quest, tm, t)
			_show_card_slot(idx)
			idx += 1

	for i in range(idx, MAX_CARDS):
		_hide_card_slot(i)

func _show_empty_message(t: Dictionary, tm: Node):
	var first_slot = _card_slots[0] if _card_slots.size() > 0 else null
	if not first_slot:
		return

	_clear_card_slot_content(first_slot, 0)

	var content = first_slot.get_node_or_null("CardContent")
	if not content:
		return

	var vbox = content.get_node_or_null("Content")
	if not vbox:
		return

	var empty_label = Label.new()
	empty_label.text = "暂无" + _current_filter + "任务，继续探索吧！"
	empty_label.add_theme_color_override("font_color", t["secondary_color"])
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tm.apply_font_to_label(empty_label, 14)
	vbox.add_child(empty_label)

	first_slot.visible = true
	if _card_style:
		first_slot.add_theme_stylebox_override("panel", _card_style)

func _update_card_data(slot_idx: int, quest: Dictionary, tm: Node, t: Dictionary):
	if slot_idx >= _card_slots.size():
		return

	var slot = _card_slots[slot_idx]
	_clear_card_slot_content(slot, slot_idx)

	var content = slot.get_node_or_null("CardContent")
	if not content:
		return

	var indicator = content.get_node_or_null("Indicator")
	var vbox = content.get_node_or_null("Content")
	if not indicator or not vbox:
		return

	if _card_style:
		slot.add_theme_stylebox_override("panel", _card_style)

	if quest["status"] == "已完成":
		slot.modulate = Color(t.get("quest_complete_tint", Color(1, 1, 1, 0.6)).r, t.get("quest_complete_tint", Color(1, 1, 1, 0.6)).g, t.get("quest_complete_tint", Color(1, 1, 1, 0.6)).b, t.get("quest_complete_tint", Color(1, 1, 1, 0.6)).a)
	else:
		slot.modulate = Color(1, 1, 1, 1)

	var status_color: Color
	match quest["status"]:
		"进行中":
			status_color = t["success_color"]
		"已完成":
			status_color = t["warning_color"]
		"可接取":
			status_color = t["accent_color"]
		_:
			status_color = t["indicator_color"]

	var dot = indicator.get_node_or_null("Dot")
	var line = indicator.get_node_or_null("Line")
	if dot:
		dot.color = status_color
	if line:
		line.color = Color(status_color.r, status_color.g, status_color.b, 0.3)

	var title_row = vbox.get_node_or_null("TitleRow")
	var desc_lbl = vbox.get_node_or_null("Description")
	var progress_row = vbox.get_node_or_null("ProgressRow")
	var reward_row = vbox.get_node_or_null("RewardRow")
	var action_btn = vbox.get_node_or_null("ActionButton")

	if title_row:
		var type_tag = title_row.get_node_or_null("TypeTag")
		var tag_hbox = type_tag.get_node_or_null("TagHBox") if type_tag else null
		var type_icon_lbl = tag_hbox.get_node_or_null("TypeIcon") if tag_hbox else null
		var type_lbl = tag_hbox.get_node_or_null("TypeLabel") if tag_hbox else null
		var title_lbl = title_row.get_node_or_null("Title")
		var status_lbl = title_row.get_node_or_null("Status")

		var type_name = quest.get("type", "对话")
		var type_key = _type_to_key(type_name)

		if type_tag and _tag_styles.has(type_key):
			type_tag.add_theme_stylebox_override("panel", _tag_styles[type_key])

		if type_icon_lbl:
			type_icon_lbl.text = _type_icons.get(type_key, "◈")
			type_icon_lbl.add_theme_color_override("font_color", tm.get_quest_type_color(type_key))
			tm.apply_font_to_label(type_icon_lbl, 11)

		if type_lbl:
			type_lbl.text = type_name
			var type_color = tm.get_quest_type_color(type_key)
			type_lbl.add_theme_color_override("font_color", type_color)
			tm.apply_font_to_label(type_lbl, 11)

		if title_lbl:
			title_lbl.text = quest["title"]
			title_lbl.add_theme_color_override("font_color", t["text_color"])
			tm.apply_font_bold_to_label(title_lbl, 16)

		if status_lbl:
			status_lbl.text = "[" + quest["status"] + "]"
			status_lbl.add_theme_color_override("font_color", status_color)
			tm.apply_font_to_label(status_lbl, 12)

	if desc_lbl:
		desc_lbl.text = quest["description"]
		desc_lbl.add_theme_color_override("font_color", t["secondary_color"])
		tm.apply_font_to_label(desc_lbl, 13)

	if progress_row:
		var progress_bar = progress_row.get_node_or_null("ProgressBar")
		var progress_text = progress_row.get_node_or_null("ProgressText")

		if progress_bar:
			if _progress_bg_style:
				progress_bar.add_theme_stylebox_override("background", _progress_bg_style)
			if _progress_fill_style:
				progress_bar.add_theme_stylebox_override("fill", _progress_fill_style)

			var progress_parts = quest["progress"].split("/")
			var current_val = int(progress_parts[0]) if progress_parts.size() > 0 else 0
			var max_val = int(progress_parts[1]) if progress_parts.size() > 1 else 1
			progress_bar.value = clampf(float(current_val) / float(maxi(max_val, 1)) * 100.0, 0.0, 100.0)

		if progress_text:
			progress_text.text = quest["progress"]
			progress_text.add_theme_color_override("font_color", t["accent_color"])
			tm.apply_font_to_label(progress_text, 12)

	if reward_row:
		var reward_lbl = reward_row.get_node_or_null("RewardLabel")
		if quest["reward"] != "":
			reward_row.visible = true
			if reward_lbl:
				reward_lbl.text = quest["reward"]
				reward_lbl.add_theme_color_override("font_color", t["warning_color"])
				tm.apply_font_to_label(reward_lbl, 12)
		else:
			reward_row.visible = false

	if action_btn:
		if quest["status"] == "可接取":
			action_btn.visible = true
			action_btn.text = "接取任务"
			if _accept_normal_style:
				action_btn.add_theme_stylebox_override("normal", _accept_normal_style)
			if _accept_hover_style:
				action_btn.add_theme_stylebox_override("hover", _accept_hover_style)
			if _accept_pressed_style:
				action_btn.add_theme_stylebox_override("pressed", _accept_pressed_style)
			action_btn.add_theme_color_override("font_color", Color.WHITE)
			tm.apply_font_to_button(action_btn, 13)
			var quest_id = quest.get("id", "")
			if action_btn.pressed.is_connected(_on_accept_quest):
				action_btn.pressed.disconnect(_on_accept_quest)
			action_btn.pressed.connect(_on_accept_quest.bind(quest_id))
			action_btn.mouse_entered.connect(_on_accept_btn_hover.bind(action_btn))
			action_btn.mouse_exited.connect(_on_accept_btn_hover_end.bind(action_btn))
		elif quest["status"] == "已完成":
			action_btn.visible = true
			action_btn.text = "✓ 已完成"
			action_btn.disabled = true
			var done_style = StyleBoxFlat.new()
			done_style.bg_color = Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.3)
			done_style.set_corner_radius_all(6)
			done_style.set_border_width_all(1)
			done_style.border_color = Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.2)
			action_btn.add_theme_stylebox_override("disabled", done_style)
			action_btn.add_theme_color_override("font_disabled_color", Color(t["secondary_color"].r, t["secondary_color"].g, t["secondary_color"].b, 0.6))
			tm.apply_font_to_button(action_btn, 13)
		else:
			action_btn.visible = false

func _clear_card_slot_content(slot: PanelContainer, _slot_idx: int):
	var content = slot.get_node_or_null("CardContent")
	if not content:
		return

	var vbox = content.get_node_or_null("Content")
	if vbox:
		for child in vbox.get_children():
			child.queue_free()

	var indicator = content.get_node_or_null("Indicator")
	if indicator:
		var dot = indicator.get_node_or_null("Dot")
		var line = indicator.get_node_or_null("Line")
		if dot:
			dot.color = Color(1, 1, 1, 0)
		if line:
			line.color = Color(1, 1, 1, 0)

func _show_card_slot(slot_idx: int):
	if slot_idx < _card_slots.size():
		_card_slots[slot_idx].visible = true

func _hide_card_slot(slot_idx: int):
	if slot_idx < _card_slots.size():
		_card_slots[slot_idx].visible = false

func _on_accept_btn_hover(btn: Button):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)

func _on_accept_btn_hover_end(btn: Button):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)

func _type_to_key(type_name: String) -> String:
	match type_name:
		"对话": return "dialogue"
		"探索": return "exploration"
		"收集": return "collection"
		"日常": return "daily"
		"隐藏": return "hidden"
		_: return "dialogue"

func _on_accept_quest(quest_id: String):
	if has_node("/root/QuestManager"):
		get_node("/root/QuestManager").accept_quest(quest_id)
