extends CanvasLayer

var _is_visible: bool = false

@onready var _main_panel: Panel = $MainPanel
@onready var _title_bar: Panel = $MainPanel/TitleBar
@onready var _close_button: Button = $MainPanel/TitleBar/CloseButton
@onready var _stats_tab: VBoxContainer = $MainPanel/TabContainer/属性
@onready var _skills_tab: VBoxContainer = $MainPanel/TabContainer/技能
@onready var _inventory_tab: VBoxContainer = $MainPanel/TabContainer/背包
@onready var _story_tab: VBoxContainer = $MainPanel/TabContainer/剧情

func _ready():
	visible = false
	if _close_button:
		_close_button.pressed.connect(_on_close)
	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)
	_apply_theme()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			toggle_panel()
			get_viewport().set_input_as_handled()

func toggle_panel() -> void:
	_is_visible = not _is_visible
	visible = _is_visible
	if _is_visible:
		_refresh_all_tabs()

func _on_close() -> void:
	_is_visible = false
	visible = false

func _refresh_all_tabs() -> void:
	_refresh_stats_tab()
	_refresh_skills_tab()
	_refresh_inventory_tab()
	_refresh_story_tab()

func _refresh_stats_tab() -> void:
	if not _stats_tab:
		return
	for child in _stats_tab.get_children():
		child.queue_free()
	if not has_node("/root/GameManager") or not has_node("/root/CharacterClassManager"):
		return
	var gm = get_node("/root/GameManager")
	var ccm = get_node("/root/CharacterClassManager")
	var header = Label.new()
	header.text = ccm.get_player_name() + " · " + ccm.get_class_codename()
	header.add_theme_font_size_override("font_size", 20)
	_stats_tab.add_child(header)
	var level_label = Label.new()
	level_label.text = "Lv." + str(int(gm.player_stats.get("level", 1))) + " " + ccm.get_class_name()
	level_label.add_theme_font_size_override("font_size", 14)
	_stats_tab.add_child(level_label)
	_add_stat_bar(_stats_tab, "HP", gm.player_stats.get("health", 0), gm.player_stats.get("max_health", 100))
	_add_stat_bar(_stats_tab, "EP", gm.player_stats.get("energy", 0), gm.player_stats.get("max_energy", 100))
	_add_stat_bar(_stats_tab, "EXP", gm.player_stats.get("exp", 0), gm.player_stats.get("exp_to_next", 100))
	var stats_header = Label.new()
	stats_header.text = "-- 属性 --"
	stats_header.add_theme_font_size_override("font_size", 14)
	_stats_tab.add_child(stats_header)
	var stat_names = {"int": "智力(INT)", "per": "感知(PER)", "agi": "敏捷(AGI)", "cha": "社交(CHA)"}
	for stat_key in ["int", "per", "agi", "cha"]:
		var label = Label.new()
		label.text = stat_names.get(stat_key, stat_key) + ": " + str(int(gm.player_stats.get(stat_key, 0)))
		_stats_tab.add_child(label)
	var points_label = Label.new()
	points_label.text = "可用属性点: " + str(int(gm.player_stats.get("stat_points", 0)))
	points_label.add_theme_font_size_override("font_size", 13)
	_stats_tab.add_child(points_label)
	var anomaly_header = Label.new()
	anomaly_header.text = "-- 异常感知 --"
	anomaly_header.add_theme_font_size_override("font_size", 14)
	_stats_tab.add_child(anomaly_header)
	_add_stat_bar(_stats_tab, "异常", gm.anomaly_level, 100.0)
	var currency_label = Label.new()
	currency_label.text = "信用点: " + str(gm.currency)
	_stats_tab.add_child(currency_label)

func _add_stat_bar(parent: VBoxContainer, label_text: String, current: float, maximum: float) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(60, 20)
	hbox.add_child(label)
	var bar = ProgressBar.new()
	bar.max_value = maximum
	bar.value = current
	bar.custom_minimum_size = Vector2(200, 20)
	bar.show_percentage = false
	hbox.add_child(bar)
	var value_label = Label.new()
	value_label.text = str(int(current)) + "/" + str(int(maximum))
	value_label.custom_minimum_size = Vector2(80, 20)
	hbox.add_child(value_label)
	parent.add_child(hbox)

func _refresh_skills_tab() -> void:
	if not _skills_tab:
		return
	for child in _skills_tab.get_children():
		child.queue_free()
	if not has_node("/root/CharacterClassManager") or not has_node("/root/GameManager"):
		return
	var ccm = get_node("/root/CharacterClassManager")
	var gm = get_node("/root/GameManager")
	var tree = ccm.get_skill_tree()
	for branch in tree:
		for skill_id in branch:
			var skill_data = ccm.get_skill_data(skill_id)
			var owned = gm.has_skill(skill_id)
			var label = Label.new()
			var prefix = "[锁定]" if not owned else "[已学]"
			label.text = prefix + " " + skill_data.get("name", skill_id) + " Lv" + str(skill_data.get("level", 1))
			if owned:
				label.text += " - " + skill_data.get("description", "")
			_skills_tab.add_child(label)

func _refresh_inventory_tab() -> void:
	if not _inventory_tab:
		return
	for child in _inventory_tab.get_children():
		child.queue_free()
	if not has_node("/root/GameManager") or not has_node("/root/UIThemeManager"):
		return
	var gm = get_node("/root/GameManager")
	var tm = get_node("/root/UIThemeManager")
	if gm.inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "背包为空"
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", tm.get_theme().get("secondary_color", Color(0.5, 0.5, 0.5)))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_inventory_tab.add_child(empty_label)
		return
	var currency_label = Label.new()
	currency_label.text = "信用点: " + str(gm.currency)
	currency_label.add_theme_font_size_override("font_size", 13)
	currency_label.add_theme_color_override("font_color", tm.get_theme().get("accent_color", Color(1, 0.8, 0.3)))
	_inventory_tab.add_child(currency_label)
	var sep = tm.make_separator()
	_inventory_tab.add_child(sep)
	var item_count_label = Label.new()
	item_count_label.text = "共 " + str(gm.inventory.size()) + " 种物品"
	item_count_label.add_theme_font_size_override("font_size", 12)
	item_count_label.add_theme_color_override("font_color", tm.get_theme().get("secondary_color", Color(0.5, 0.5, 0.5)))
	_inventory_tab.add_child(item_count_label)
	for item_data in gm.inventory:
		var item_id = item_data.get("id", "???")
		var amount = item_data.get("amount", 1)
		var db = gm.ITEM_DATABASE.get(item_id, {})
		var rarity = db.get("rarity", "common")
		var item_name = db.get("name", item_id)
		var item_desc = db.get("desc", "")
		var item_type = db.get("type", "material")
		var item_icon = db.get("icon", "?")
		var rarity_color = tm.get_rarity_color(rarity)
		var card_panel = Panel.new()
		card_panel.add_theme_stylebox_override("panel", tm.make_item_card_style(rarity))
		card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_hbox = HBoxContainer.new()
		card_hbox.add_theme_constant_override("separation", 10)
		var icon_panel = Panel.new()
		icon_panel.custom_minimum_size = Vector2(40, 40)
		icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var icon_bg = StyleBoxFlat.new()
		icon_bg.bg_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.15)
		icon_bg.border_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.5)
		icon_bg.set_border_width_all(1)
		icon_bg.set_corner_radius_all(6)
		icon_panel.add_theme_stylebox_override("panel", icon_bg)
		var icon_label = Label.new()
		icon_label.text = item_icon
		icon_label.add_theme_font_size_override("font_size", 13)
		icon_label.add_theme_color_override("font_color", rarity_color)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_panel.add_child(icon_label)
		card_hbox.add_child(icon_panel)
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 2)
		var name_hbox = HBoxContainer.new()
		name_hbox.add_theme_constant_override("separation", 6)
		var name_label = Label.new()
		name_label.text = item_name
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", tm.get_theme().get("text_color", Color(0.9, 0.9, 0.9)))
		name_hbox.add_child(name_label)
		var type_label = Label.new()
		type_label.text = _get_item_type_label(item_type)
		type_label.add_theme_font_size_override("font_size", 10)
		type_label.add_theme_color_override("font_color", tm.get_theme().get("secondary_color", Color(0.5, 0.5, 0.5)))
		var type_style = StyleBoxFlat.new()
		type_style.bg_color = Color(0.3, 0.3, 0.3, 0.3)
		type_style.set_corner_radius_all(3)
		type_style.content_margin_left = 4
		type_style.content_margin_right = 4
		type_style.content_margin_top = 1
		type_style.content_margin_bottom = 1
		type_label.add_theme_stylebox_override("normal", type_style)
		name_hbox.add_child(type_label)
		var rarity_label = Label.new()
		rarity_label.text = tm.get_rarity_label(rarity)
		rarity_label.add_theme_font_size_override("font_size", 10)
		rarity_label.add_theme_color_override("font_color", rarity_color)
		name_hbox.add_child(rarity_label)
		info_vbox.add_child(name_hbox)
		if not item_desc.is_empty():
			var desc_label = Label.new()
			desc_label.text = item_desc
			desc_label.add_theme_font_size_override("font_size", 11)
			desc_label.add_theme_color_override("font_color", tm.get_theme().get("secondary_color", Color(0.6, 0.6, 0.6)))
			info_vbox.add_child(desc_label)
		card_hbox.add_child(info_vbox)
		if amount > 1:
			var amount_label = Label.new()
			amount_label.text = "x" + str(amount)
			amount_label.add_theme_font_size_override("font_size", 14)
			amount_label.add_theme_color_override("font_color", tm.get_theme().get("accent_color", Color(0, 0.93, 1)))
			amount_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			card_hbox.add_child(amount_label)
		card_panel.add_child(card_hbox)
		_inventory_tab.add_child(card_panel)

func _get_item_type_label(item_type: String) -> String:
	match item_type:
		"consumable": return "消耗"
		"equipment": return "装备"
		"material": return "材料"
		_: return "未知"

func _refresh_story_tab() -> void:
	if not _story_tab:
		return
	for child in _story_tab.get_children():
		child.queue_free()
	if not has_node("/root/StoryManager"):
		return
	var sm = get_node("/root/StoryManager")
	var chapters = sm.get_all_chapters()
	for chapter_id in chapters:
		var chapter = chapters[chapter_id]
		var status = sm.get_chapter_status(chapter_id)
		var status_text = ""
		match status:
			0: status_text = "[锁定]"
			1: status_text = "[可接]"
			2: status_text = "[进行中]"
			3: status_text = "[完成]"
		var label = Label.new()
		var progress = sm.get_chapter_progress(chapter_id)
		var progress_text = ""
		if status == StoryManager.ChapterStatus.COMPLETED:
			progress_text = " (" + str(int(progress * 100)) + "%)"
		label.text = status_text + " Ch" + str(chapter.get("chapter", 0)) + ": " + chapter.get("title", "") + progress_text
		_story_tab.add_child(label)
	var current_step = sm.get_current_step()
	if not current_step.is_empty():
		var step_label = Label.new()
		step_label.text = "当前目标: " + str(current_step.get("description", ""))
		step_label.add_theme_font_size_override("font_size", 13)
		_story_tab.add_child(step_label)

func _on_phase_changed(_new_phase: int) -> void:
	_apply_theme()

func _apply_theme() -> void:
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	if _main_panel:
		_main_panel.add_theme_stylebox_override("panel", tm.make_panel_style())
	if _title_bar:
		_title_bar.add_theme_stylebox_override("panel", tm.make_title_bar_style())
