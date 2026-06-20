extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var gm = root.get_node_or_null("/root/GameManager")
	var ccm = root.get_node_or_null("/root/CharacterClassManager")
	if not gm:
		errors.append("GameManager autoload missing")
	else:
		if ccm and ccm.has_method("select_class"):
			ccm.select_class(ccm.ClassType.CIPHER, "测试玩家")
		_verify_equipment_api(gm, errors)
	print("====== VERIFY EQUIPMENT SYSTEM ======")
	if errors.is_empty():
		print("Equipment system checks passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _verify_equipment_api(gm: Node, errors: Array[String]) -> void:
	gm.equipment_bag.clear()
	for slot in gm.EQUIPMENT_SLOT_ORDER:
		gm.equipped_items[slot] = ""
	gm.inventory = []

	var base_int := float(gm.player_stats.get("int", 0.0))
	var cipher_core := {
		"id": "cipher_matrix_core",
		"name": "矩阵解析核心",
		"slot": "weapon_core",
		"rarity": "rare",
		"class": "cipher",
		"level": 1,
		"affixes": {"int": 2, "attack": 1},
	}
	var instance_id: String = gm.add_equipment(cipher_core)
	if instance_id.is_empty():
		errors.append("ADD_EQUIPMENT_EMPTY_INSTANCE")
	if gm.equipment_bag.size() != 1:
		errors.append("EQUIPMENT_BAG_SIZE_INVALID")
	if not gm.equip_equipment(instance_id):
		errors.append("EQUIP_MATCHING_CLASS_FAILED")
	if str(gm.equipped_items.get("weapon_core", "")) != instance_id:
		errors.append("EQUIPPED_SLOT_NOT_SET")
	if gm.get_effective_stat("int") < base_int + 2.0:
		errors.append("EQUIPMENT_BONUS_NOT_APPLIED")

	var chrome_plate_id: String = gm.add_equipment({"id": "chrome_void_plate"})
	if gm.equip_equipment(chrome_plate_id):
		errors.append("CLASS_RESTRICTION_FAILED")

	if not gm.unequip_slot("weapon_core"):
		errors.append("UNEQUIP_FAILED")
	if not gm.dismantle_equipment(instance_id):
		errors.append("DISMANTLE_FAILED")
	if not gm.has_item("rift_shard"):
		errors.append("DISMANTLE_REWARD_MISSING")

	gm.load_save_data({
		"inventory": [
			{"id": "neural_link", "amount": 2},
			{"id": "health_potion", "amount": 1},
		],
		"equipment_bag": [],
		"equipped_items": {},
	})
	if gm.equipment_bag.size() != 2:
		errors.append("LEGACY_EQUIPMENT_MIGRATION_FAILED")
	if gm.inventory.size() != 1 or str(gm.inventory[0].get("id", "")) != "health_potion":
		errors.append("LEGACY_INVENTORY_KEEP_FAILED")

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
