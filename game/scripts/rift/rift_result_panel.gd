extends CanvasLayer

signal closed()

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var summary_label: Label = $Panel/VBox/SummaryLabel
@onready var rewards_box: VBoxContainer = $Panel/VBox/RewardsBox
@onready var clues_box: VBoxContainer = $Panel/VBox/CluesBox
@onready var drops_box: VBoxContainer = $Panel/VBox/DropsBox
@onready var close_button: Button = $Panel/VBox/CloseButton

var _result: Dictionary = {}

func _ready() -> void:
	visible = false
	if close_button:
		close_button.pressed.connect(func(): closed.emit())
	_apply_theme()

func _apply_theme() -> void:
	var tm = get_node_or_null("/root/UIThemeManager")
	if tm and panel:
		panel.add_theme_stylebox_override("panel", tm.make_panel_style(10, 2, 12))
		for label in [title_label, summary_label]:
			if label:
				tm.apply_font_to_label(label, 22 if label == title_label else 14)

func show_result(result: Dictionary) -> void:
	_result = result.duplicate(true)
	visible = true
	if title_label:
		title_label.text = _status_text(result.get("status", "")) + " · 评级 " + result.get("rating", "D")
	if summary_label:
		summary_label.text = "节点 %d · 击破 %d · 伤害 %d · 最高连击 %d" % [
			int(result.get("cleared_nodes", 0)),
			int(result.get("total_kills", 0)),
			int(result.get("damage_taken", 0)),
			int(result.get("combo_best", 0)),
		]
	_refresh_rewards()
	_refresh_clues()
	_refresh_drops()

func _refresh_rewards() -> void:
	for child in rewards_box.get_children():
		child.queue_free()
	var exp_label := Label.new()
	exp_label.text = "经验 +%d    信用点 +%d" % [int(_result.get("exp", 0)), int(_result.get("currency", 0))]
	rewards_box.add_child(exp_label)
	var materials: Dictionary = _result.get("materials", {})
	for material_id in materials:
		var label := Label.new()
		label.text = "%s x%d" % [_material_name(material_id), int(materials[material_id])]
		rewards_box.add_child(label)

func _refresh_clues() -> void:
	for child in clues_box.get_children():
		child.queue_free()
	var clues: Array = _result.get("new_clues", [])
	var phenomena: Array = _result.get("unresolved_phenomena", [])
	if clues.is_empty() and phenomena.is_empty():
		var quiet_label := _make_wrap_label("未发现新的裂隙档案")
		clues_box.add_child(quiet_label)
		return
	if not clues.is_empty():
		var header := Label.new()
		header.text = "新裂隙档案"
		clues_box.add_child(header)
		for clue in clues:
			var label := _make_wrap_label("%s · %s：%s" % [
				clue.get("category", "档案"),
				clue.get("title", "未知记录"),
				clue.get("text", ""),
			])
			clues_box.add_child(label)
	if not phenomena.is_empty():
		var phen_header := Label.new()
		phen_header.text = "未解释现象"
		clues_box.add_child(phen_header)
		for text in phenomena:
			clues_box.add_child(_make_wrap_label(str(text)))

func _make_wrap_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _refresh_drops() -> void:
	for child in drops_box.get_children():
		child.queue_free()
	var drops: Array = _result.get("equipment_drops", [])
	if drops.is_empty():
		var empty := Label.new()
		empty.text = "没有装备掉落"
		drops_box.add_child(empty)
		return
	for item in drops:
		_add_drop_row(item)

func _add_drop_row(item: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.text = "%s · %s · Lv.%d · %s" % [
		item.get("name", item.get("id", "未知装备")),
		_rarity_name(item.get("rarity", "common")),
		int(item.get("level", 1)),
		_slot_name(item.get("slot", "")),
	]
	row.add_child(info)
	var equip_btn := Button.new()
	equip_btn.text = "装备"
	equip_btn.pressed.connect(func():
		_equip_drop(item)
		_disable_row_buttons(row)
	)
	row.add_child(equip_btn)
	var bag_btn := Button.new()
	bag_btn.text = "入包"
	bag_btn.pressed.connect(func():
		_add_drop_to_bag(item)
		_disable_row_buttons(row)
	)
	row.add_child(bag_btn)
	var dis_btn := Button.new()
	dis_btn.text = "分解"
	dis_btn.pressed.connect(func():
		_dismantle_drop(item)
		_disable_row_buttons(row)
	)
	row.add_child(dis_btn)
	drops_box.add_child(row)

func _add_drop_to_bag(item: Dictionary) -> String:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("add_equipment"):
		return gm.add_equipment(item)
	var mgr = get_node_or_null("/root/RiftRunManager")
	if mgr and mgr.has_method("add_equipment_to_bag"):
		mgr.add_equipment_to_bag(item)
	return ""

func _equip_drop(item: Dictionary) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("add_equipment") and gm.has_method("equip_equipment"):
		var instance_id: String = gm.add_equipment(item)
		gm.equip_equipment(instance_id)
		return
	var mgr = get_node_or_null("/root/RiftRunManager")
	if mgr and mgr.has_method("equip_item"):
		mgr.equip_item(item)

func _dismantle_drop(item: Dictionary) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var rarity := str(item.get("rarity", "common"))
		var amount := 1
		match rarity:
			"rare": amount = 2
			"epic": amount = 4
			"legendary": amount = 8
		gm.add_item("rift_shard", amount)
		return
	var mgr = get_node_or_null("/root/RiftRunManager")
	if mgr and mgr.has_method("dismantle_item"):
		mgr.dismantle_item(item)

func _disable_row_buttons(row: HBoxContainer) -> void:
	for child in row.get_children():
		if child is Button:
			child.disabled = true

func _status_text(status: String) -> String:
	match status:
		"cleared": return "完整通关"
		"evacuated": return "主动撤离"
		"defeated": return "作战失败"
		_: return "结算"

func _rarity_name(rarity: String) -> String:
	match rarity:
		"rare": return "稀有"
		"epic": return "史诗"
		"legendary": return "传说"
		_: return "普通"

func _slot_name(slot: String) -> String:
	match slot:
		"weapon_core": return "武器核心"
		"armor": return "护甲"
		"boots": return "足具"
		"relic": return "遗物"
		"class_mod": return "职业模组"
		_: return "装备"

func _material_name(material_id: String) -> String:
	match material_id:
		"rift_shard": return "裂隙碎片"
		"anomaly_thread": return "异常缝线"
		"data_shard": return "数据碎片"
		"frozen_talisman": return "霜封符纸"
		"phase_wire": return "相位导线"
		"mirror_mist": return "镜雾凝珠"
		_: return material_id
