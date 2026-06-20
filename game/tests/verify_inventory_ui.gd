extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var gm = root.get_node_or_null("/root/GameManager")
	if not gm:
		errors.append("GameManager autoload missing")
	else:
		_verify_inventory_api(gm, errors)
		await _verify_inventory_panel(gm, errors)
	print("====== VERIFY INVENTORY UI ======")
	if errors.is_empty():
		print("Inventory UI checks passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _verify_inventory_api(gm: Node, errors: Array[String]) -> void:
	gm.inventory = []
	gm.equipment_bag.clear()
	for slot in gm.EQUIPMENT_SLOT_ORDER:
		gm.equipped_items[slot] = ""
	gm.currency = 0
	gm.player_stats["health"] = 40.0
	gm.player_stats["max_health"] = 100.0
	gm.player_stats["energy"] = 20.0
	gm.player_stats["max_energy"] = 100.0

	var currency_seen := {"value": false}
	gm.currency_changed.connect(func(_new_currency: int): currency_seen["value"] = true)

	gm.add_item("health_potion", 2)
	if not gm.use_item("health_potion"):
		errors.append("USE_HEALTH_POTION_FAILED")
	if float(gm.player_stats.get("health", 0.0)) <= 40.0:
		errors.append("HEALTH_POTION_DID_NOT_RESTORE")

	gm.add_item("credit_chip", 1)
	if not gm.use_item("credit_chip"):
		errors.append("USE_CREDIT_CHIP_FAILED")
	if gm.currency != 50 or not bool(currency_seen["value"]):
		errors.append("CURRENCY_USE_OR_SIGNAL_FAILED")

	var equipment_id: String = gm.add_equipment({"id": "rift_blade_core", "affixes": {"attack": 2}})
	if equipment_id.is_empty():
		errors.append("ADD_TEST_EQUIPMENT_FAILED")
	var equipment_rows: Array = gm.get_inventory_display_data("equipment", "type")
	if equipment_rows.size() < 1:
		errors.append("EQUIPMENT_FILTER_EMPTY")
	var compare: Dictionary = gm.get_equipment_compare_data(equipment_id)
	if compare.is_empty() or str(compare.get("slot", "")) != "weapon_core":
		errors.append("EQUIPMENT_COMPARE_INVALID")
	if not gm.equip_equipment(equipment_id):
		errors.append("EQUIP_FROM_INVENTORY_API_FAILED")

	var consumables: Array = gm.get_inventory_display_data("consumable", "name")
	for entry in consumables:
		if entry is Dictionary and str(entry.get("type", "")) != "consumable":
			errors.append("CONSUMABLE_FILTER_LEAKED_NON_CONSUMABLE")

func _verify_inventory_panel(gm: Node, errors: Array[String]) -> void:
	var scene: PackedScene = load("res://scenes/character_panel.tscn")
	var panel = scene.instantiate()
	root.add_child(panel)
	await process_frame
	panel._inventory_filter = "all"
	panel._refresh_inventory_tab()
	await process_frame
	if panel._inventory_tab.get_child_count() < 4:
		errors.append("INVENTORY_PANEL_LAYOUT_MISSING")
	if str(panel._selected_inventory_uid).is_empty():
		errors.append("INVENTORY_PANEL_NO_SELECTION")
	panel._inventory_filter = "material"
	panel._refresh_inventory_tab()
	await process_frame
	var material_rows: Array = gm.get_inventory_display_data("material", "type")
	if material_rows.size() != 0 and panel._inventory_tab.get_child_count() < 4:
		errors.append("INVENTORY_PANEL_FILTER_REBUILD_FAILED")
	panel.queue_free()

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
