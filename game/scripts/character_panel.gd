extends CanvasLayer

var _is_visible: bool = false
var _inventory_filter: String = "all"
var _inventory_sort_key: String = "type"
var _selected_inventory_uid: String = ""

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
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if gm.has_signal("equipment_changed"):
			gm.equipment_changed.connect(_on_game_data_changed)
		if gm.has_signal("inventory_changed"):
			gm.inventory_changed.connect(_on_game_data_changed)
		if gm.has_signal("currency_changed"):
			gm.currency_changed.connect(_on_game_data_changed)
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
	_add_stat_bar(_stats_tab, "HP", gm.player_stats.get("health", 0), gm.get_effective_stat("max_health") if gm.has_method("get_effective_stat") else gm.player_stats.get("max_health", 100))
	_add_stat_bar(_stats_tab, "EP", gm.player_stats.get("energy", 0), gm.player_stats.get("max_energy", 100))
	_add_stat_bar(_stats_tab, "EXP", gm.player_stats.get("exp", 0), gm.player_stats.get("exp_to_next", 100))
	var stats_header = Label.new()
	stats_header.text = "-- 属性 --"
	stats_header.add_theme_font_size_override("font_size", 14)
	_stats_tab.add_child(stats_header)
	var stat_names = {"int": "智力(INT)", "per": "感知(PER)", "agi": "敏捷(AGI)", "cha": "社交(CHA)"}
	for stat_key in ["int", "per", "agi", "cha"]:
		var label = Label.new()
		label.text = stat_names.get(stat_key, stat_key) + ": " + _format_effective_stat(gm, stat_key)
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
	var data: Array = gm.get_inventory_display_data(_inventory_filter, _inventory_sort_key)
	_validate_inventory_selection(data)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	_inventory_tab.add_child(header)

	var title := Label.new()
	title.text = "背包终端"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", tm.get_theme().get("title_color", Color(0.85, 0.95, 1.0)))
	header.add_child(title)

	var currency_label := Label.new()
	currency_label.text = "信用点 " + str(gm.currency)
	currency_label.add_theme_font_size_override("font_size", 13)
	currency_label.add_theme_color_override("font_color", tm.get_theme().get("accent_color", Color(1, 0.8, 0.3)))
	currency_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(currency_label)

	var sort_btn := Button.new()
	sort_btn.text = _inventory_sort_label()
	sort_btn.custom_minimum_size = Vector2(86, 28)
	sort_btn.pressed.connect(_cycle_inventory_sort)
	header.add_child(sort_btn)

	var filter_bar := HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 6)
	_inventory_tab.add_child(filter_bar)
	for filter_data in [
		{"id": "all", "label": "全部"},
		{"id": "equipment", "label": "装备"},
		{"id": "consumable", "label": "消耗"},
		{"id": "material", "label": "材料"},
		{"id": "key_item", "label": "剧情"},
	]:
		_add_inventory_filter_button(filter_bar, filter_data, tm)

	_inventory_tab.add_child(tm.make_separator())

	var split := HSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.custom_minimum_size = Vector2(0, 390)
	_inventory_tab.add_child(split)

	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(245, 0)
	list_panel.add_theme_stylebox_override("panel", tm.make_card_style())
	split.add_child(list_panel)

	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_child(list_scroll)

	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 5)
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(list_box)
	_populate_inventory_list(list_box, data, tm)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", tm.make_card_style())
	split.add_child(detail_panel)

	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 8)
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_child(detail_box)
	_populate_inventory_detail(detail_box, data, gm, tm)

func _validate_inventory_selection(data: Array) -> void:
	var found := false
	for entry in data:
		if entry is Dictionary and str(entry.get("uid", "")) == _selected_inventory_uid:
			found = true
			break
	if found:
		return
	_selected_inventory_uid = ""
	for entry in data:
		if not (entry is Dictionary):
			continue
		if bool(entry.get("empty_slot", false)):
			continue
		_selected_inventory_uid = str(entry.get("uid", ""))
		return
	if not data.is_empty() and data[0] is Dictionary:
		_selected_inventory_uid = str(data[0].get("uid", ""))

func _add_inventory_filter_button(parent: HBoxContainer, filter_data: Dictionary, tm: Node) -> void:
	var filter_id := str(filter_data.get("id", "all"))
	var btn := Button.new()
	btn.text = str(filter_data.get("label", filter_id))
	btn.custom_minimum_size = Vector2(62, 28)
	var styles = tm.make_filter_button_styles(filter_id == _inventory_filter)
	btn.add_theme_stylebox_override("normal", styles["normal"])
	btn.add_theme_stylebox_override("hover", styles["hover"])
	btn.add_theme_color_override("font_color", styles["font_color"])
	btn.pressed.connect(func():
		_inventory_filter = filter_id
		_refresh_inventory_tab()
	)
	parent.add_child(btn)

func _populate_inventory_list(parent: VBoxContainer, data: Array, tm: Node) -> void:
	if data.is_empty():
		_add_empty_line(parent, "没有符合筛选的物品", tm)
		return
	for entry in data:
		if not (entry is Dictionary):
			continue
		var btn := Button.new()
		btn.text = _inventory_entry_button_text(entry, tm)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 38)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var selected := str(entry.get("uid", "")) == _selected_inventory_uid
		var styles = tm.make_filter_button_styles(selected)
		btn.add_theme_stylebox_override("normal", styles["normal"])
		btn.add_theme_stylebox_override("hover", styles["hover"])
		btn.add_theme_color_override("font_color", styles["font_color"])
		btn.disabled = bool(entry.get("empty_slot", false)) and _inventory_filter != "equipment" and _inventory_filter != "all"
		btn.pressed.connect(func():
			_selected_inventory_uid = str(entry.get("uid", ""))
			_refresh_inventory_tab()
		)
		parent.add_child(btn)

func _populate_inventory_detail(parent: VBoxContainer, data: Array, gm: Node, tm: Node) -> void:
	var entry := _find_inventory_entry(data, _selected_inventory_uid)
	if entry.is_empty():
		_add_empty_line(parent, "背包为空", tm)
		return
	_add_inventory_detail_header(parent, entry, tm)
	if bool(entry.get("empty_slot", false)):
		_add_empty_line(parent, "当前槽位尚未装备", tm)
		return
	var desc := Label.new()
	desc.text = str(entry.get("desc", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", tm.get_theme().get("secondary_color", Color(0.6, 0.6, 0.6)))
	parent.add_child(desc)

	if str(entry.get("kind", "")) == "equipment":
		_add_equipment_detail(parent, entry, gm, tm)
	else:
		_add_item_detail(parent, entry, gm, tm)

func _add_inventory_detail_header(parent: VBoxContainer, entry: Dictionary, tm: Node) -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	parent.add_child(top)
	_add_icon_node(top, str(entry.get("icon", "?")), tm.get_rarity_color(str(entry.get("rarity", "common"))))
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_box)
	var title := Label.new()
	title.text = str(entry.get("name", "未知物品"))
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", tm.get_theme().get("text_color", Color(0.9, 0.9, 0.9)))
	title_box.add_child(title)
	var meta := Label.new()
	meta.text = str(entry.get("type_label", "")) + " · " + tm.get_rarity_label(str(entry.get("rarity", "common")))
	if int(entry.get("amount", 1)) > 1:
		meta.text += " · x" + str(int(entry.get("amount", 1)))
	meta.add_theme_font_size_override("font_size", 12)
	meta.add_theme_color_override("font_color", tm.get_rarity_color(str(entry.get("rarity", "common"))))
	title_box.add_child(meta)

func _add_item_detail(parent: VBoxContainer, entry: Dictionary, gm: Node, tm: Node) -> void:
	if not bool(entry.get("can_use", false)):
		_add_empty_line(parent, "材料和剧情物品暂不可直接使用", tm)
		return
	var use_btn := Button.new()
	use_btn.text = "使用"
	use_btn.custom_minimum_size = Vector2(120, 34)
	use_btn.pressed.connect(func():
		gm.use_item(str(entry.get("id", "")))
		_refresh_all_tabs()
	)
	parent.add_child(use_btn)

func _add_equipment_detail(parent: VBoxContainer, entry: Dictionary, gm: Node, tm: Node) -> void:
	var slot_label := Label.new()
	slot_label.text = "槽位: " + str(entry.get("slot_label", "")) + "   等级: Lv." + str(int(entry.get("level", 1)))
	slot_label.add_theme_font_size_override("font_size", 12)
	slot_label.add_theme_color_override("font_color", tm.get_theme().get("secondary_color", Color(0.6, 0.6, 0.6)))
	parent.add_child(slot_label)

	var affix := Label.new()
	affix.text = _format_affixes(entry.get("affixes", {}))
	affix.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	affix.add_theme_font_size_override("font_size", 12)
	affix.add_theme_color_override("font_color", tm.get_rarity_color(str(entry.get("rarity", "common"))))
	parent.add_child(affix)

	var compare: Dictionary = {}
	var compare_data: Variant = gm.get_equipment_compare_data(str(entry.get("instance_id", "")))
	if compare_data is Dictionary:
		compare = compare_data
	var diff_text: String = _format_compare_diff(compare.get("diff", {}))
	if not diff_text.is_empty():
		var diff_label := Label.new()
		diff_label.text = diff_text
		diff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		diff_label.add_theme_font_size_override("font_size", 12)
		diff_label.add_theme_color_override("font_color", tm.get_theme().get("accent_color", Color(0, 0.93, 1)))
		parent.add_child(diff_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	parent.add_child(actions)
	if bool(entry.get("equipped", false)):
		var unequip_btn := Button.new()
		unequip_btn.text = "卸下"
		unequip_btn.custom_minimum_size = Vector2(90, 32)
		unequip_btn.pressed.connect(func():
			gm.unequip_slot(str(entry.get("slot", "")))
			_refresh_all_tabs()
		)
		actions.add_child(unequip_btn)
	else:
		var equip_btn := Button.new()
		equip_btn.text = str(entry.get("action_label", "装备"))
		equip_btn.disabled = not bool(entry.get("can_equip", false))
		equip_btn.custom_minimum_size = Vector2(90, 32)
		equip_btn.pressed.connect(func():
			gm.equip_equipment(str(entry.get("instance_id", "")))
			_refresh_all_tabs()
		)
		actions.add_child(equip_btn)
		var dismantle_btn := Button.new()
		dismantle_btn.text = "分解"
		dismantle_btn.custom_minimum_size = Vector2(90, 32)
		dismantle_btn.pressed.connect(func():
			gm.dismantle_equipment(str(entry.get("instance_id", "")))
			_selected_inventory_uid = ""
			_refresh_all_tabs()
		)
		actions.add_child(dismantle_btn)

func _find_inventory_entry(data: Array, uid: String) -> Dictionary:
	for entry in data:
		if entry is Dictionary and str(entry.get("uid", "")) == uid:
			return entry
	return {}

func _inventory_entry_button_text(entry: Dictionary, tm: Node) -> String:
	var prefix := "◎" if bool(entry.get("equipped", false)) else " "
	if bool(entry.get("empty_slot", false)):
		prefix = "□"
	var amount := ""
	if int(entry.get("amount", 1)) > 1:
		amount = " x" + str(int(entry.get("amount", 1)))
	return "%s %s  %s%s" % [prefix, str(entry.get("icon", "?")), str(entry.get("name", "")), amount]

func _cycle_inventory_sort() -> void:
	match _inventory_sort_key:
		"type":
			_inventory_sort_key = "rarity"
		"rarity":
			_inventory_sort_key = "name"
		_:
			_inventory_sort_key = "type"
	_refresh_inventory_tab()

func _inventory_sort_label() -> String:
	match _inventory_sort_key:
		"rarity":
			return "稀有度"
		"name":
			return "名称"
		_:
			return "类型"

func _format_compare_diff(diff: Dictionary) -> String:
	if diff.is_empty():
		return ""
	var parts: Array[String] = []
	for stat_name in diff.keys():
		var delta := float(diff[stat_name])
		var text := ("+" if delta > 0 else "") + _trim_float(delta)
		parts.append(_get_affix_label(str(stat_name)) + " " + text)
	return "对比当前: " + " / ".join(parts)


func _add_equipped_section(parent: VBoxContainer, gm: Node, tm: Node) -> void:
	_add_section_label(parent, "已装备", tm)
	for slot in gm.EQUIPMENT_SLOT_ORDER:
		var item: Dictionary = gm.get_equipped_item(slot)
		if item.is_empty():
			var empty := Label.new()
			empty.text = gm.get_equipment_slot_label(slot) + ": 空"
			empty.add_theme_font_size_override("font_size", 12)
			empty.add_theme_color_override("font_color", tm.get_theme().get("secondary_color", Color(0.5, 0.5, 0.5)))
			parent.add_child(empty)
		else:
			_add_equipment_card(parent, item, gm, tm, true)

func _add_equipment_bag_section(parent: VBoxContainer, gm: Node, tm: Node) -> void:
	_add_section_label(parent, "装备背包", tm)
	var count := 0
	for item in gm.equipment_bag:
		if not (item is Dictionary):
			continue
		var instance_id := str(item.get("instance_id", ""))
		if gm.is_equipment_equipped(instance_id):
			continue
		count += 1
		_add_equipment_card(parent, item, gm, tm, false)
	if count == 0:
		_add_empty_line(parent, "没有可用装备", tm)

func _add_item_bag_section(parent: VBoxContainer, gm: Node, tm: Node) -> void:
	_add_section_label(parent, "物品背包", tm)
	var count := 0
	for item_data in gm.inventory:
		if not (item_data is Dictionary):
			continue
		var item_id = item_data.get("id", "???")
		var db = gm.ITEM_DATABASE.get(item_id, {})
		if str(db.get("type", "")) == "equipment":
			continue
		count += 1
		_add_item_card(parent, item_data, gm, tm)
	if count == 0:
		_add_empty_line(parent, "没有材料或消耗品", tm)

func _add_item_card(parent: VBoxContainer, item_data: Dictionary, gm: Node, tm: Node) -> void:
	var item_id = item_data.get("id", "???")
	var amount = item_data.get("amount", 1)
	var db = gm.ITEM_DATABASE.get(item_id, {})
	var rarity = db.get("rarity", "common")
	var item_name = db.get("name", item_id)
	var item_desc = db.get("desc", "")
	var item_type = db.get("type", "material")
	var item_icon = db.get("icon", "?")
	var card_hbox := _create_card_hbox(parent, tm, rarity)
	_add_icon_node(card_hbox, str(item_icon), tm.get_rarity_color(rarity))
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	var name_label = Label.new()
	name_label.text = str(item_name) + "  " + _get_item_type_label(item_type) + "  " + tm.get_rarity_label(rarity)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", tm.get_theme().get("text_color", Color(0.9, 0.9, 0.9)))
	info_vbox.add_child(name_label)
	if not str(item_desc).is_empty():
		var desc_label = Label.new()
		desc_label.text = str(item_desc)
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", tm.get_theme().get("secondary_color", Color(0.6, 0.6, 0.6)))
		info_vbox.add_child(desc_label)
	card_hbox.add_child(info_vbox)
	if int(amount) > 1:
		var amount_label = Label.new()
		amount_label.text = "x" + str(amount)
		amount_label.add_theme_font_size_override("font_size", 14)
		amount_label.add_theme_color_override("font_color", tm.get_theme().get("accent_color", Color(0, 0.93, 1)))
		amount_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card_hbox.add_child(amount_label)

func _add_equipment_card(parent: VBoxContainer, equipment: Dictionary, gm: Node, tm: Node, is_equipped: bool) -> void:
	var rarity := str(equipment.get("rarity", "common"))
	var rarity_color = tm.get_rarity_color(rarity)
	var card_hbox := _create_card_hbox(parent, tm, rarity)
	_add_icon_node(card_hbox, str(equipment.get("icon", "?")), rarity_color)
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.text = "%s · Lv.%d · %s · %s" % [
		str(equipment.get("name", equipment.get("id", "未知装备"))),
		int(equipment.get("level", 1)),
		gm.get_equipment_slot_label(str(equipment.get("slot", ""))),
		tm.get_rarity_label(rarity),
	]
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", tm.get_theme().get("text_color", Color(0.9, 0.9, 0.9)))
	info_vbox.add_child(title)
	var meta := Label.new()
	meta.text = _equipment_meta_text(equipment)
	meta.add_theme_font_size_override("font_size", 11)
	meta.add_theme_color_override("font_color", tm.get_theme().get("secondary_color", Color(0.6, 0.6, 0.6)))
	info_vbox.add_child(meta)
	var affix := Label.new()
	affix.text = _format_affixes(equipment.get("affixes", {}))
	affix.add_theme_font_size_override("font_size", 11)
	affix.add_theme_color_override("font_color", rarity_color)
	info_vbox.add_child(affix)
	card_hbox.add_child(info_vbox)
	var button_box := VBoxContainer.new()
	button_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var instance_id := str(equipment.get("instance_id", ""))
	if is_equipped:
		var unequip_button := Button.new()
		unequip_button.text = "卸下"
		unequip_button.pressed.connect(func():
			gm.unequip_slot(str(equipment.get("slot", "")))
			_refresh_all_tabs()
		)
		button_box.add_child(unequip_button)
	else:
		var equip_button := Button.new()
		equip_button.text = "装备" if gm.can_equip_equipment(instance_id) else "职业不符"
		equip_button.disabled = not gm.can_equip_equipment(instance_id)
		equip_button.pressed.connect(func():
			gm.equip_equipment(instance_id)
			_refresh_all_tabs()
		)
		button_box.add_child(equip_button)
		var dismantle_button := Button.new()
		dismantle_button.text = "分解"
		dismantle_button.pressed.connect(func():
			gm.dismantle_equipment(instance_id)
			_refresh_all_tabs()
		)
		button_box.add_child(dismantle_button)
	card_hbox.add_child(button_box)

func _create_card_hbox(parent: VBoxContainer, tm: Node, rarity: String) -> HBoxContainer:
	var card_panel = Panel.new()
	card_panel.add_theme_stylebox_override("panel", tm.make_item_card_style(rarity))
	card_panel.custom_minimum_size = Vector2(0, 58)
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_hbox = HBoxContainer.new()
	card_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_hbox.offset_left = 8
	card_hbox.offset_top = 6
	card_hbox.offset_right = -8
	card_hbox.offset_bottom = -6
	card_hbox.add_theme_constant_override("separation", 10)
	card_panel.add_child(card_hbox)
	parent.add_child(card_panel)
	return card_hbox

func _add_icon_node(parent: HBoxContainer, icon: String, rarity_color: Color) -> void:
	var icon_panel = Panel.new()
	icon_panel.custom_minimum_size = Vector2(40, 40)
	icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_bg = StyleBoxFlat.new()
	icon_bg.bg_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.15)
	icon_bg.border_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.5)
	icon_bg.set_border_width_all(1)
	icon_bg.set_corner_radius_all(6)
	icon_panel.add_theme_stylebox_override("panel", icon_bg)
	if icon.begins_with("res://") and ResourceLoader.exists(icon):
		var icon_texture := TextureRect.new()
		icon_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_texture.texture = load(icon)
		icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_texture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_texture.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_panel.add_child(icon_texture)
	else:
		var icon_label = Label.new()
		icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_label.text = icon
		icon_label.add_theme_font_size_override("font_size", 13)
		icon_label.add_theme_color_override("font_color", rarity_color)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_panel.add_child(icon_label)
	parent.add_child(icon_panel)

func _add_section_label(parent: VBoxContainer, text: String, tm: Node) -> void:
	var label := Label.new()
	label.text = "-- " + text + " --"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", tm.get_theme().get("title_color", Color(0.85, 0.95, 1.0)))
	parent.add_child(label)

func _add_empty_line(parent: VBoxContainer, text: String, tm: Node) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", tm.get_theme().get("secondary_color", Color(0.5, 0.5, 0.5)))
	parent.add_child(label)

func _equipment_meta_text(equipment: Dictionary) -> String:
	var class_id := str(equipment.get("class", "any"))
	var class_text := "通用" if class_id == "any" or class_id.is_empty() else class_id.to_upper()
	return "适用: " + class_text

func _format_affixes(affixes: Dictionary) -> String:
	if affixes.is_empty():
		return "无属性词条"
	var parts: Array[String] = []
	for key in affixes.keys():
		var value := float(affixes[key])
		var value_text := ("+" if value > 0.0 else "") + _trim_float(value)
		parts.append(_get_affix_label(str(key)) + " " + value_text)
	return " / ".join(parts)

func _get_affix_label(key: String) -> String:
	match key:
		"int": return "智力"
		"per": return "感知"
		"agi": return "敏捷"
		"cha": return "社交"
		"max_health": return "生命上限"
		"attack": return "攻击"
		"speed": return "速度"
		"skill_cd": return "技能冷却"
		"all": return "全属性"
		"chain": return "连锁"
		"guard": return "防护"
		"melee": return "近战"
		"shield": return "护盾"
		"slow": return "减速"
		"area": return "范围"
		"dodge": return "闪避"
		"crit": return "暴击"
		"reroll": return "重构"
		_: return key

func _trim_float(value: float) -> String:
	if abs(value - int(value)) < 0.001:
		return str(int(value))
	return "%.1f" % value

func _format_effective_stat(gm: Node, stat_key: String) -> String:
	var base := float(gm.player_stats.get(stat_key, 0.0))
	var effective: float = gm.get_effective_stat(stat_key) if gm.has_method("get_effective_stat") else base
	var bonus: float = effective - base
	if abs(bonus) < 0.001:
		return str(int(base))
	return "%d (+%s)" % [int(effective), _trim_float(bonus)]

func _on_game_data_changed() -> void:
	if _is_visible:
		_refresh_all_tabs()

func _get_item_type_label(item_type: String) -> String:
	match item_type:
		"consumable": return "消耗"
		"equipment": return "装备"
		"accessory": return "饰品"
		"material": return "材料"
		"key_item": return "剧情"
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
