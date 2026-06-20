extends Node

signal stats_changed(stat_name: String, new_value: float)
signal inventory_changed()
signal equipment_changed()
signal currency_changed(new_currency: int)
signal anomaly_level_changed(new_level: float)
signal area_discovered(area_id: String)
signal level_up(new_level: int)
signal exp_gained(current_exp: float, target_exp: float)

var player_stats: Dictionary = {
	"health": 100.0,
	"max_health": 100.0,
	"energy": 100.0,
	"max_energy": 100.0,
	"anomaly_sensitivity": 0.0,
	"int": 10,
	"per": 10,
	"agi": 10,
	"cha": 10,
	"level": 1,
	"exp": 0.0,
	"exp_to_next": 100.0,
	"stat_points": 0,
}

var currency: int = 0

var inventory: Array = []
var equipment_bag: Array[Dictionary] = []
var equipped_items: Dictionary = {
	"weapon_core": "",
	"armor": "",
	"boots": "",
	"relic": "",
	"class_mod": "",
}
var skills: Dictionary = {}
var discovered_areas: Array = ["office", "street", "apartment"]
var anomaly_level: float = 0.0
var play_time: float = 0.0
var interaction_count: int = 0
var _inventory_sort_key: String = "type"

const ITEM_DATABASE: Dictionary = {
	"health_potion": {"name": "生命药剂", "desc": "恢复30点HP", "type": "consumable", "rarity": "common", "icon": "HP+", "value": 30},
	"energy_potion": {"name": "体力药剂", "desc": "恢复30点EP", "type": "consumable", "rarity": "common", "icon": "EP+", "value": 30},
	"mega_health": {"name": "高级生命药剂", "desc": "恢复80点HP", "type": "consumable", "rarity": "rare", "icon": "HP++", "value": 80},
	"mega_energy": {"name": "高级体力药剂", "desc": "恢复80点EP", "type": "consumable", "rarity": "rare", "icon": "EP++", "value": 80},
	"anomaly_detector": {"name": "异常探测器", "desc": "探测周围异常波动", "type": "equipment", "rarity": "rare", "icon": "DET", "value": 0},
	"neural_link": {"name": "神经链接芯片", "desc": "增强INT+2", "type": "equipment", "rarity": "epic", "icon": "INT", "value": 2},
	"cyber_eye": {"name": "赛博义眼", "desc": "增强PER+2", "type": "equipment", "rarity": "epic", "icon": "PER", "value": 2},
	"reflex_boost": {"name": "反射加速器", "desc": "增强AGI+2", "type": "equipment", "rarity": "epic", "icon": "AGI", "value": 2},
	"social_chip": {"name": "社交模组", "desc": "增强CHA+2", "type": "equipment", "rarity": "epic", "icon": "CHA", "value": 2},
	"quantum_coffee": {"name": "量子咖啡", "desc": "同时恢复HP和EP各20点", "type": "consumable", "rarity": "common", "icon": "QCF", "value": 20},
	"dimension_key": {"name": "维度裂缝钥匙", "desc": "开启异常空间的钥匙", "type": "material", "rarity": "legendary", "icon": "DIM", "value": 0},
	"data_shard": {"name": "数据碎片", "desc": "记录着未知信息的数据碎片", "type": "material", "rarity": "rare", "icon": "DAT", "value": 0},
	"memory_chip": {"name": "记忆芯片", "desc": "存储NPC记忆的芯片", "type": "material", "rarity": "rare", "icon": "MEM", "value": 0},
	"talisman_paper": {"name": "符纸", "desc": "神秘的符纸，似乎有特殊力量", "type": "material", "rarity": "epic", "icon": "TLM", "value": 0},
	"credit_chip": {"name": "信用芯片", "desc": "可兑换50信用点", "type": "consumable", "rarity": "common", "icon": "CRD", "value": 50},
	"hacking_tool": {"name": "黑客工具包", "desc": "用于入侵系统的工具", "type": "equipment", "rarity": "rare", "icon": "HCK", "value": 0},
	"combat_drone": {"name": "战斗无人机", "desc": "可协助战斗的小型无人机", "type": "equipment", "rarity": "legendary", "icon": "DRN", "value": 0},
	"rare_mineral": {"name": "稀有矿石", "desc": "来自深层地下矿脉的稀有矿石", "type": "material", "rarity": "rare", "icon": "MIN", "value": 0},
	"shadow_cloak": {"name": "暗影斗篷", "desc": "增强隐匿能力，AGI+1", "type": "equipment", "rarity": "epic", "icon": "SHD", "value": 1},
	"anomaly_spectrometer": {"name": "异常谱仪", "desc": "张三改装的便携仪器，可记录幽蓝断点和裂缝噪声", "type": "equipment", "rarity": "rare", "icon": "ASP", "value": 0},
	"shadow_pass": {"name": "影签通行证", "desc": "赵霖提供的黑巷身份标记，能换来一次不被追问的通行", "type": "equipment", "rarity": "rare", "icon": "SGN", "value": 0},
	"pulse_bracelet": {"name": "脉冲腕环", "desc": "孙悦与刘风共同调校的腕部护件，会记录异常心跳", "type": "equipment", "rarity": "epic", "icon": "PUL", "value": 0},
	"cold_boot_ring": {"name": "冷启动戒指", "desc": "何真梦境中出现的冷色戒指，像一枚给记忆用的锚点", "type": "accessory", "rarity": "legendary", "icon": "CBR", "value": 0},
	"neon_grid_earclip": {"name": "霓虹栅格耳夹", "desc": "李四留下的反馈纪念物，能让被删掉的声音短暂浮现", "type": "accessory", "rarity": "rare", "icon": "NGE", "value": 0},
	"star_noise_earring": {"name": "星噪耳饰", "desc": "王五把异常符号做成的耳饰，靠近错误现实时会微微发烫", "type": "accessory", "rarity": "epic", "icon": "SNE", "value": 0},
	"broken_silver_needle": {"name": "断线银针", "desc": "陈曦杯底出现的细针，据说能缝合非常小的现实裂口", "type": "material", "rarity": "rare", "icon": "BSN", "value": 0},
	"mirror_page": {"name": "镜界残页", "desc": "从界面之外拓下的残页，可以映出短暂重叠的街区", "type": "material", "rarity": "epic", "icon": "MPG", "value": 0},
	"echo_latte": {"name": "回声拿铁", "desc": "量子咖啡店的第二杯饮品，同时恢复HP和EP各25点", "type": "consumable", "rarity": "rare", "icon": "ELT", "value": 25},
	"rainport_access_chip": {"name": "雨港通行芯片", "desc": "写有新港旧路由的临时访问芯片，边缘常有雨声", "type": "key_item", "rarity": "rare", "icon": "RPC", "value": 0},
	"echo_crystal": {"name": "回响水晶", "desc": "蕴含灵能的水晶", "type": "material", "rarity": "epic", "icon": "ECH", "value": 0},
	"rift_shard": {"name": "裂隙碎片", "desc": "万界镶层中掉落的基础材料", "type": "material", "rarity": "common", "icon": "RFT", "value": 0},
	"anomaly_thread": {"name": "异常缝线", "desc": "用于缝合异界装备的细线", "type": "material", "rarity": "rare", "icon": "THR", "value": 0},
	"rift_mucus": {"name": "星露黏液", "desc": "史莱姆留下的半透明材料", "type": "material", "rarity": "common", "icon": "SLM", "value": 0},
	"rift_talisman": {"name": "裂隙黄符", "desc": "仍在震动的镇尸符", "type": "material", "rarity": "rare", "icon": "TAL", "value": 0},
	"shadow_residue": {"name": "影砂残渣", "desc": "游魂消散后的暗色砂粒", "type": "material", "rarity": "common", "icon": "SHR", "value": 0},
	"clockwork_core": {"name": "机巧核心", "desc": "傀儡体内的微型炉心", "type": "material", "rarity": "rare", "icon": "CLK", "value": 0},
	"mirror_shard": {"name": "镜界碎片", "desc": "可以映出不属于此地的影像", "type": "material", "rarity": "epic", "icon": "MIR", "value": 0},
	"idol_plate": {"name": "玄甲石片", "desc": "石像外壳上剥落的甲片", "type": "material", "rarity": "rare", "icon": "IDL", "value": 0},
	"phase_wire": {"name": "相位导线", "desc": "赛博残影留下的发光导线", "type": "material", "rarity": "epic", "icon": "PHS", "value": 0},
	"forbidden_page": {"name": "禁书残页", "desc": "写满陌生咒式的纸页", "type": "material", "rarity": "epic", "icon": "PAG", "value": 0},
	"cipher_matrix_core": {"name": "矩阵解析核心", "desc": "CIPHER 专属武器核心", "type": "equipment", "rarity": "rare", "icon": "CIP", "value": 0},
	"cipher_fractal_lens": {"name": "分形透镜", "desc": "CIPHER 专属职业模组", "type": "equipment", "rarity": "epic", "icon": "CFR", "value": 0},
	"chrome_void_plate": {"name": "虚鳞胸甲", "desc": "CHROME 专属护甲", "type": "equipment", "rarity": "rare", "icon": "CHP", "value": 0},
	"chrome_impact_core": {"name": "冲击炉心", "desc": "CHROME 专属武器核心", "type": "equipment", "rarity": "epic", "icon": "CIC", "value": 0},
	"echo_mirror_relic": {"name": "镜鸣遗物", "desc": "ECHO 专属遗物", "type": "equipment", "rarity": "rare", "icon": "EMR", "value": 0},
	"echo_psy_mod": {"name": "灵纹调频器", "desc": "ECHO 专属职业模组", "type": "equipment", "rarity": "epic", "icon": "EPM", "value": 0},
	"shadow_blink_boots": {"name": "影跃足具", "desc": "SHADOW 专属足具", "type": "equipment", "rarity": "rare", "icon": "SBB", "value": 0},
	"shadow_backstab_core": {"name": "背刺裂刃", "desc": "SHADOW 专属武器核心", "type": "equipment", "rarity": "epic", "icon": "SBC", "value": 0},
	"rift_blade_core": {"name": "裂隙刃核", "desc": "通用武器核心", "type": "equipment", "rarity": "common", "icon": "RBC", "value": 0},
	"voidscale_armor": {"name": "虚鳞护甲", "desc": "通用护甲", "type": "equipment", "rarity": "common", "icon": "VSA", "value": 0},
	"blink_boots": {"name": "闪步足具", "desc": "通用足具", "type": "equipment", "rarity": "common", "icon": "BLK", "value": 0},
	"mirror_relic": {"name": "镜界遗物", "desc": "传说级通用遗物", "type": "equipment", "rarity": "legendary", "icon": "MRR", "value": 0},
}

const EQUIPMENT_SLOT_ORDER: Array[String] = ["weapon_core", "armor", "boots", "relic", "class_mod"]
const EQUIPMENT_SLOT_LABELS: Dictionary = {
	"weapon_core": "武器核心",
	"armor": "护甲",
	"boots": "足具",
	"relic": "遗物",
	"class_mod": "职业模组",
}
const CLASS_IDS: Array[String] = ["cipher", "chrome", "echo", "shadow"]
const LEGACY_EQUIPMENT_AFFIXES: Dictionary = {
	"neural_link": {"int": 2},
	"cyber_eye": {"per": 2},
	"reflex_boost": {"agi": 2},
	"social_chip": {"cha": 2},
	"shadow_cloak": {"agi": 1},
}

var _game_flags: Dictionary = {}

func _ready():
	print("[GameManager] 初始化完成")

func _process(delta: float):
	play_time += delta

func set_stat(stat_name: String, value: float) -> void:
	if player_stats.has(stat_name):
		player_stats[stat_name] = value
		stats_changed.emit(stat_name, value)

func get_stat(stat_name: String) -> float:
	return player_stats.get(stat_name, 0.0)

func add_item(item_id: String, amount: int = 1) -> void:
	if _is_equipment_item_id(item_id):
		for _i in range(maxi(1, amount)):
			add_equipment({"id": item_id})
		return
	for item in inventory:
		if item["id"] == item_id:
			item["amount"] += amount
			inventory_changed.emit()
			return
	inventory.append({"id": item_id, "amount": amount})
	inventory_changed.emit()

func use_item(item_id: String) -> bool:
	if not ITEM_DATABASE.has(item_id):
		return false
	var db: Dictionary = ITEM_DATABASE[item_id]
	if str(db.get("type", "")) != "consumable":
		return false
	if not has_item(item_id):
		return false

	var value := float(db.get("value", 0.0))
	var used := false
	match item_id:
		"health_potion", "mega_health":
			used = _restore_stat("health", "max_health", value)
		"energy_potion", "mega_energy":
			used = _restore_stat("energy", "max_energy", value)
		"quantum_coffee", "echo_latte":
			var healed := _restore_stat("health", "max_health", value)
			var energized := _restore_stat("energy", "max_energy", value)
			used = healed or energized
		"credit_chip":
			add_currency(int(value))
			used = true
		_:
			return false

	if not used:
		return false
	if remove_item(item_id, 1):
		_log_event("使用物品: " + str(db.get("name", item_id)))
		return true
	return false

func get_inventory_display_data(filter: String = "all", sort_key: String = "type") -> Array:
	var normalized_filter := _normalize_inventory_filter(filter)
	var result: Array = []

	for slot in EQUIPMENT_SLOT_ORDER:
		var equipped := get_equipped_item(slot)
		if equipped.is_empty():
			var slot_entry := {
				"uid": "slot:" + slot,
				"kind": "slot",
				"id": "",
				"instance_id": "",
				"name": get_equipment_slot_label(slot) + " 空槽",
				"desc": "尚未装备",
				"type": "equipment_slot",
				"type_label": "装备槽",
				"category": "equipped",
				"amount": 0,
				"rarity": "common",
				"icon": "--",
				"equipped": true,
				"empty_slot": true,
				"slot": slot,
				"slot_label": get_equipment_slot_label(slot),
				"can_equip": false,
				"can_use": false,
				"action_label": "",
			}
			if _inventory_entry_matches_filter(slot_entry, normalized_filter):
				result.append(slot_entry)

	for equipment in equipment_bag:
		if not (equipment is Dictionary):
			continue
		var entry := _equipment_to_display_entry(equipment)
		if _inventory_entry_matches_filter(entry, normalized_filter):
			result.append(entry)

	for item_data in inventory:
		if not (item_data is Dictionary):
			continue
		var item_id := str(item_data.get("id", ""))
		if _is_equipment_item_id(item_id):
			continue
		var entry := _item_to_display_entry(item_data)
		if _inventory_entry_matches_filter(entry, normalized_filter):
			result.append(entry)

	_inventory_sort_key = sort_key
	result.sort_custom(_sort_inventory_entries)
	return result

func get_equipment_compare_data(instance_id: String) -> Dictionary:
	var equipment := get_equipment_by_instance_id(instance_id)
	if equipment.is_empty():
		return {}
	var slot := str(equipment.get("slot", ""))
	var current := get_equipped_item(slot)
	var result := {
		"candidate": equipment.duplicate(true),
		"current": current.duplicate(true),
		"slot": slot,
		"slot_label": get_equipment_slot_label(slot),
		"diff": {},
	}
	var stats: Array[String] = ["int", "per", "agi", "cha", "max_health", "attack", "speed", "skill_cd", "all", "crit", "dodge"]
	var candidate_affixes: Dictionary = equipment.get("affixes", {})
	var current_affixes: Dictionary = current.get("affixes", {}) if not current.is_empty() else {}
	for stat_name in stats:
		var candidate_value := float(candidate_affixes.get(stat_name, 0.0))
		var current_value := float(current_affixes.get(stat_name, 0.0))
		var delta := candidate_value - current_value
		if abs(delta) > 0.001:
			result["diff"][stat_name] = delta
	return result

func remove_item(item_id: String, amount: int = 1) -> bool:
	if _is_equipment_item_id(item_id):
		var removed := 0
		for i in range(equipment_bag.size() - 1, -1, -1):
			if removed >= amount:
				break
			var equipment: Dictionary = equipment_bag[i]
			if str(equipment.get("id", "")) == item_id and not _is_equipment_equipped(str(equipment.get("instance_id", ""))):
				equipment_bag.remove_at(i)
				removed += 1
		if removed > 0:
			equipment_changed.emit()
			inventory_changed.emit()
		return removed >= amount
	for i in range(inventory.size()):
		if inventory[i]["id"] == item_id:
			inventory[i]["amount"] -= amount
			if inventory[i]["amount"] <= 0:
				inventory.remove_at(i)
			inventory_changed.emit()
			return true
	return false

func has_item(item_id: String) -> bool:
	if _is_equipment_item_id(item_id):
		for equipment in equipment_bag:
			if str(equipment.get("id", "")) == item_id:
				return true
		return false
	for item in inventory:
		if item["id"] == item_id and item["amount"] > 0:
			return true
	return false

func add_equipment(item: Dictionary) -> String:
	var equipment := _normalize_equipment_instance(item)
	var instance_id := str(equipment.get("instance_id", ""))
	if instance_id.is_empty() or str(equipment.get("id", "")).is_empty():
		return ""
	equipment_bag.append(equipment)
	equipment_changed.emit()
	inventory_changed.emit()
	return instance_id

func equip_equipment(instance_id: String) -> bool:
	var index := _find_equipment_index(instance_id)
	if index < 0:
		return false
	var equipment: Dictionary = equipment_bag[index]
	if not _can_equip_equipment_data(equipment):
		_log_event("装备职业不匹配: " + str(equipment.get("name", equipment.get("id", ""))))
		return false
	var slot := str(equipment.get("slot", ""))
	if not slot in EQUIPMENT_SLOT_ORDER:
		return false
	equipped_items[slot] = instance_id
	equipment_changed.emit()
	stats_changed.emit("equipment", 0.0)
	return true

func unequip_slot(slot: String) -> bool:
	if not equipped_items.has(slot) or str(equipped_items.get(slot, "")).is_empty():
		return false
	equipped_items[slot] = ""
	equipment_changed.emit()
	stats_changed.emit("equipment", 0.0)
	return true

func dismantle_equipment(instance_id: String) -> bool:
	if _is_equipment_equipped(instance_id):
		return false
	var index := _find_equipment_index(instance_id)
	if index < 0:
		return false
	var equipment: Dictionary = equipment_bag[index]
	equipment_bag.remove_at(index)
	add_item("rift_shard", _get_dismantle_shard_amount(str(equipment.get("rarity", "common"))))
	equipment_changed.emit()
	inventory_changed.emit()
	return true

func can_equip_equipment(instance_id: String) -> bool:
	var index := _find_equipment_index(instance_id)
	if index < 0:
		return false
	return _can_equip_equipment_data(equipment_bag[index])

func get_equipment_by_instance_id(instance_id: String) -> Dictionary:
	var index := _find_equipment_index(instance_id)
	if index < 0:
		return {}
	return equipment_bag[index].duplicate(true)

func get_equipped_item(slot: String) -> Dictionary:
	var instance_id := str(equipped_items.get(slot, ""))
	if instance_id.is_empty():
		return {}
	return get_equipment_by_instance_id(instance_id)

func is_equipment_equipped(instance_id: String) -> bool:
	return _is_equipment_equipped(instance_id)

func get_equipment_bonuses() -> Dictionary:
	var bonuses: Dictionary = {}
	for slot in EQUIPMENT_SLOT_ORDER:
		var instance_id := str(equipped_items.get(slot, ""))
		if instance_id.is_empty():
			continue
		var index := _find_equipment_index(instance_id)
		if index < 0:
			continue
		var equipment: Dictionary = equipment_bag[index]
		var affixes: Dictionary = equipment.get("affixes", {})
		for stat_name in affixes.keys():
			bonuses[stat_name] = float(bonuses.get(stat_name, 0.0)) + float(affixes[stat_name])
	return bonuses

func get_effective_stat(stat_name: String) -> float:
	var bonuses := get_equipment_bonuses()
	var value := float(player_stats.get(stat_name, 0.0))
	value += float(bonuses.get(stat_name, 0.0))
	if stat_name in ["int", "per", "agi", "cha"]:
		value += float(bonuses.get("all", 0.0))
	return value

func get_equipment_slot_label(slot: String) -> String:
	return str(EQUIPMENT_SLOT_LABELS.get(slot, slot))

func _is_equipment_item_id(item_id: String) -> bool:
	return ITEM_DATABASE.has(item_id) and str(ITEM_DATABASE[item_id].get("type", "")) == "equipment"

func _normalize_equipment_instance(item: Dictionary) -> Dictionary:
	var item_id := str(item.get("id", ""))
	if item_id.is_empty():
		return {}
	var base := _get_equipment_base(item_id)
	var instance_id := str(item.get("instance_id", ""))
	if instance_id.is_empty():
		instance_id = "%s_%d_%d_%d" % [item_id, Time.get_unix_time_from_system(), Time.get_ticks_usec(), randi()]
	var affixes_source = item.get("affixes", base.get("affixes", LEGACY_EQUIPMENT_AFFIXES.get(item_id, {})))
	var affixes: Dictionary = {}
	if affixes_source is Dictionary:
		affixes = affixes_source.duplicate(true)
	return {
		"instance_id": instance_id,
		"id": item_id,
		"name": str(item.get("name", base.get("name", item_id))),
		"desc": str(item.get("desc", base.get("desc", ""))),
		"slot": str(item.get("slot", base.get("slot", _infer_equipment_slot(item_id)))),
		"rarity": str(item.get("rarity", base.get("rarity", "common"))),
		"class": str(item.get("class", base.get("class", _infer_equipment_class(item_id)))).to_lower(),
		"level": maxi(1, int(item.get("level", base.get("level", 1)))),
		"icon": str(item.get("icon", base.get("icon", "?"))),
		"affixes": affixes,
	}

func _get_equipment_base(item_id: String) -> Dictionary:
	var base: Dictionary = {}
	var rift_manager = get_node_or_null("/root/RiftRunManager")
	if rift_manager and rift_manager.has_method("get_equipment_definitions"):
		var definitions: Dictionary = rift_manager.get_equipment_definitions()
		if definitions.has(item_id):
			base = definitions[item_id].duplicate(true)
	var db: Dictionary = ITEM_DATABASE.get(item_id, {})
	for key in db.keys():
		if not base.has(key):
			base[key] = db[key]
	if not base.has("slot"):
		base["slot"] = _infer_equipment_slot(item_id)
	if not base.has("class"):
		base["class"] = _infer_equipment_class(item_id)
	if not base.has("affixes"):
		base["affixes"] = LEGACY_EQUIPMENT_AFFIXES.get(item_id, {}).duplicate(true)
	return base

func _infer_equipment_slot(item_id: String) -> String:
	var id := item_id.to_lower()
	if id.contains("armor") or id.contains("plate") or id.contains("cloak"):
		return "armor"
	if id.contains("boot") or id.contains("boost"):
		return "boots"
	if id.contains("relic") or id.contains("eye") or id.contains("detector"):
		return "relic"
	if id.contains("mod") or id.contains("lens") or id.contains("link") or id.contains("chip"):
		return "class_mod"
	return "weapon_core"

func _infer_equipment_class(item_id: String) -> String:
	var id := item_id.to_lower()
	for class_id in CLASS_IDS:
		if id.begins_with(class_id + "_"):
			return class_id
	return "any"

func _find_equipment_index(instance_id: String) -> int:
	if instance_id.is_empty():
		return -1
	for i in range(equipment_bag.size()):
		if str(equipment_bag[i].get("instance_id", "")) == instance_id:
			return i
	return -1

func _is_equipment_equipped(instance_id: String) -> bool:
	if instance_id.is_empty():
		return false
	for slot in equipped_items.keys():
		if str(equipped_items[slot]) == instance_id:
			return true
	return false

func _can_equip_equipment_data(equipment: Dictionary) -> bool:
	var slot := str(equipment.get("slot", ""))
	if not slot in EQUIPMENT_SLOT_ORDER:
		return false
	var required_class := str(equipment.get("class", "any")).to_lower()
	if required_class.is_empty() or required_class == "any":
		return true
	return required_class == _get_current_class_id()

func _restore_stat(stat_name: String, max_stat_name: String, amount: float) -> bool:
	if amount <= 0.0 or not player_stats.has(stat_name):
		return false
	var current := float(player_stats.get(stat_name, 0.0))
	var maximum := get_effective_stat(max_stat_name) if player_stats.has(max_stat_name) else float(player_stats.get(max_stat_name, current))
	if current >= maximum:
		return false
	var new_value: float = min(current + amount, maximum)
	player_stats[stat_name] = new_value
	stats_changed.emit(stat_name, new_value)
	return true

func _item_to_display_entry(item_data: Dictionary) -> Dictionary:
	var item_id := str(item_data.get("id", ""))
	var db: Dictionary = ITEM_DATABASE.get(item_id, {})
	var item_type := str(db.get("type", "material"))
	var rarity := str(db.get("rarity", "common"))
	return {
		"uid": "item:" + item_id,
		"kind": "item",
		"id": item_id,
		"instance_id": "",
		"name": str(db.get("name", item_id)),
		"desc": str(db.get("desc", "")),
		"type": item_type,
		"type_label": _get_item_type_label(item_type),
		"category": item_type,
		"amount": int(item_data.get("amount", 1)),
		"rarity": rarity,
		"icon": str(db.get("icon", "?")),
		"value": db.get("value", 0),
		"equipped": false,
		"empty_slot": false,
		"slot": "",
		"slot_label": "",
		"can_equip": false,
		"can_use": item_type == "consumable",
		"action_label": "使用" if item_type == "consumable" else "",
	}

func _equipment_to_display_entry(equipment: Dictionary) -> Dictionary:
	var instance_id := str(equipment.get("instance_id", ""))
	var slot := str(equipment.get("slot", ""))
	var is_equipped := _is_equipment_equipped(instance_id)
	return {
		"uid": "equipment:" + instance_id,
		"kind": "equipment",
		"id": str(equipment.get("id", "")),
		"instance_id": instance_id,
		"name": str(equipment.get("name", equipment.get("id", "未知装备"))),
		"desc": str(equipment.get("desc", "")),
		"type": "equipment",
		"type_label": "装备",
		"category": "equipment",
		"amount": 1,
		"rarity": str(equipment.get("rarity", "common")),
		"icon": str(equipment.get("icon", "?")),
		"value": equipment.get("value", 0),
		"equipped": is_equipped,
		"empty_slot": false,
		"slot": slot,
		"slot_label": get_equipment_slot_label(slot),
		"class": str(equipment.get("class", "any")),
		"level": int(equipment.get("level", 1)),
		"affixes": equipment.get("affixes", {}).duplicate(true),
		"can_equip": _can_equip_equipment_data(equipment),
		"can_use": false,
		"action_label": "卸下" if is_equipped else ("装备" if _can_equip_equipment_data(equipment) else "职业不符"),
	}

func _normalize_inventory_filter(filter: String) -> String:
	match filter:
		"", "all", "全部":
			return "all"
		"equipment", "装备":
			return "equipment"
		"equipped", "已装备":
			return "equipped"
		"unequipped", "未装备":
			return "unequipped"
		"items", "物品":
			return "items"
		"consumable", "消耗", "消耗品":
			return "consumable"
		"material", "材料":
			return "material"
		"key_item", "剧情", "剧情物品":
			return "key_item"
		"accessory", "饰品":
			return "accessory"
		_:
			return filter

func _inventory_entry_matches_filter(entry: Dictionary, filter: String) -> bool:
	match filter:
		"all":
			return true
		"equipment":
			return entry.get("kind", "") == "equipment" or entry.get("kind", "") == "slot"
		"equipped":
			return bool(entry.get("equipped", false))
		"unequipped":
			return entry.get("kind", "") == "equipment" and not bool(entry.get("equipped", false))
		"items":
			return entry.get("kind", "") == "item"
		"consumable", "material", "key_item", "accessory":
			return entry.get("type", "") == filter
		_:
			return true

func _sort_inventory_entries(a: Dictionary, b: Dictionary) -> bool:
	match _inventory_sort_key:
		"rarity":
			var rarity_delta := _rarity_rank(str(b.get("rarity", "common"))) - _rarity_rank(str(a.get("rarity", "common")))
			if rarity_delta != 0:
				return rarity_delta < 0
		"name":
			return str(a.get("name", "")) < str(b.get("name", ""))
		_:
			var type_delta := _inventory_type_rank(a) - _inventory_type_rank(b)
			if type_delta != 0:
				return type_delta < 0
	var equipped_delta := int(b.get("equipped", false)) - int(a.get("equipped", false))
	if equipped_delta != 0:
		return equipped_delta < 0
	var rarity_rank_delta := _rarity_rank(str(b.get("rarity", "common"))) - _rarity_rank(str(a.get("rarity", "common")))
	if rarity_rank_delta != 0:
		return rarity_rank_delta < 0
	return str(a.get("uid", "")) < str(b.get("uid", ""))

func _inventory_type_rank(entry: Dictionary) -> int:
	match str(entry.get("kind", "")):
		"slot":
			return 0
		"equipment":
			return 1
		"item":
			match str(entry.get("type", "")):
				"consumable":
					return 2
				"material":
					return 3
				"accessory":
					return 4
				"key_item":
					return 5
	return 9

func _rarity_rank(rarity: String) -> int:
	match rarity:
		"legendary":
			return 4
		"epic":
			return 3
		"rare":
			return 2
		"common":
			return 1
		_:
			return 0

func _get_item_type_label(item_type: String) -> String:
	match item_type:
		"consumable":
			return "消耗"
		"equipment":
			return "装备"
		"accessory":
			return "饰品"
		"material":
			return "材料"
		"key_item":
			return "剧情"
		_:
			return "未知"

func _get_current_class_id() -> String:
	var ccm = get_node_or_null("/root/CharacterClassManager")
	if ccm and ccm.has_method("get_class_id"):
		return str(ccm.get_class_id()).to_lower()
	return "unknown"

func _get_dismantle_shard_amount(rarity: String) -> int:
	match rarity:
		"rare":
			return 2
		"epic":
			return 4
		"legendary":
			return 8
		_:
			return 1

func _normalize_equipment_state() -> void:
	var normalized_bag: Array[Dictionary] = []
	for item in equipment_bag:
		if item is Dictionary:
			var normalized := _normalize_equipment_instance(item)
			if not normalized.is_empty():
				normalized_bag.append(normalized)
	equipment_bag = normalized_bag
	for slot in EQUIPMENT_SLOT_ORDER:
		if not equipped_items.has(slot):
			equipped_items[slot] = ""
	var extra_slots: Array = []
	for slot in equipped_items.keys():
		if not slot in EQUIPMENT_SLOT_ORDER:
			extra_slots.append(slot)
	for slot in extra_slots:
		equipped_items.erase(slot)
	for slot in EQUIPMENT_SLOT_ORDER:
		var instance_id := str(equipped_items.get(slot, ""))
		if not instance_id.is_empty() and _find_equipment_index(instance_id) < 0:
			equipped_items[slot] = ""

func _migrate_inventory_equipment() -> void:
	var kept_inventory: Array = []
	var migrated := false
	for item in inventory:
		if not (item is Dictionary):
			continue
		var item_id := str(item.get("id", ""))
		var amount := maxi(1, int(item.get("amount", 1)))
		if _is_equipment_item_id(item_id):
			for _i in range(amount):
				equipment_bag.append(_normalize_equipment_instance({"id": item_id}))
			migrated = true
		else:
			kept_inventory.append(item)
	if migrated:
		inventory = kept_inventory
		equipment_changed.emit()
		inventory_changed.emit()

func unlock_skill(skill_id: String, skill_data: Dictionary = {}) -> void:
	skills[skill_id] = skill_data
	print("[GameManager] 解锁技能: " + skill_id)

func has_skill(skill_id: String) -> bool:
	return skills.has(skill_id)

func discover_area(area_id: String) -> void:
	if not area_id in discovered_areas:
		discovered_areas.append(area_id)
		area_discovered.emit(area_id)
		print("[GameManager] 发现区域: " + area_id)

func set_flag(flag_name: String, value: Variant = true) -> void:
	_game_flags[flag_name] = value

func get_flag(flag_name: String, default: Variant = false) -> Variant:
	return _game_flags.get(flag_name, default)

func increase_anomaly(amount: float) -> void:
	anomaly_level = clamp(anomaly_level + amount, 0.0, 100.0)
	anomaly_level_changed.emit(anomaly_level)
	if anomaly_level >= 50.0:
		_log_event("⚠️ 异常感知增强...")
	if anomaly_level >= 80.0:
		_log_event("🔴 数据裂缝正在扩散...")

func record_interaction() -> void:
	interaction_count += 1

func gain_exp(amount: float) -> void:
	var current_exp = player_stats.get("exp", 0.0)
	var target_exp = player_stats.get("exp_to_next", 100.0)
	current_exp += amount
	player_stats["exp"] = current_exp
	exp_gained.emit(current_exp, target_exp)
	while current_exp >= target_exp:
		current_exp -= target_exp
		_level_up()
		target_exp = player_stats.get("exp_to_next", 100.0)
	player_stats["exp"] = current_exp

func _level_up() -> void:
	var current_level = int(player_stats.get("level", 1))
	current_level += 1
	player_stats["level"] = current_level
	player_stats["exp_to_next"] = _calculate_exp_requirement(current_level)
	player_stats["stat_points"] = int(player_stats.get("stat_points", 0)) + 3
	player_stats["max_health"] = player_stats.get("max_health", 100.0) + 10.0
	player_stats["health"] = player_stats.get("max_health", 100.0)
	player_stats["max_energy"] = player_stats.get("max_energy", 100.0) + 5.0
	player_stats["energy"] = player_stats.get("max_energy", 100.0)
	level_up.emit(current_level)
	_log_event("⬆️ 升级！等级: " + str(current_level))

func _calculate_exp_requirement(level: int) -> float:
	return 100.0 * pow(1.5, level - 1)

func allocate_stat(stat_name: String, amount: int = 1) -> bool:
	var available = int(player_stats.get("stat_points", 0))
	if available < amount:
		return false
	if not player_stats.has(stat_name):
		return false
	player_stats[stat_name] = int(player_stats.get(stat_name, 0)) + amount
	player_stats["stat_points"] = available - amount
	stats_changed.emit(stat_name, float(player_stats[stat_name]))
	return true

func add_currency(amount: int) -> void:
	currency += amount
	currency_changed.emit(currency)

func spend_currency(amount: int) -> bool:
	if currency < amount:
		return false
	currency -= amount
	currency_changed.emit(currency)
	return true

func get_save_data() -> Dictionary:
	return {
		"player_stats": player_stats,
		"inventory": inventory,
		"equipment_bag": equipment_bag,
		"equipped_items": equipped_items,
		"skills": skills,
		"discovered_areas": discovered_areas,
		"anomaly_level": anomaly_level,
		"play_time": play_time,
		"interaction_count": interaction_count,
		"game_flags": _game_flags,
		"currency": currency,
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("player_stats"):
		player_stats = data["player_stats"]
	if data.has("inventory"):
		inventory = data["inventory"]
	equipment_bag.clear()
	equipped_items.clear()
	for slot in EQUIPMENT_SLOT_ORDER:
		equipped_items[slot] = ""
	if data.has("equipment_bag"):
		for item in data["equipment_bag"]:
			if item is Dictionary:
				equipment_bag.append(item.duplicate(true))
	if data.has("equipped_items"):
		for slot in data["equipped_items"].keys():
			equipped_items[slot] = data["equipped_items"][slot]
	_normalize_equipment_state()
	_migrate_inventory_equipment()
	if data.has("skills"):
		skills = data["skills"]
	if data.has("discovered_areas"):
		discovered_areas = data["discovered_areas"]
		for area_id in ["office", "street", "apartment"]:
			if not area_id in discovered_areas:
				discovered_areas.append(area_id)
	if data.has("anomaly_level"):
		anomaly_level = data["anomaly_level"]
	if data.has("play_time"):
		play_time = data["play_time"]
	if data.has("interaction_count"):
		interaction_count = data["interaction_count"]
	if data.has("game_flags"):
		_game_flags = data["game_flags"]
	if data.has("currency"):
		currency = int(data["currency"])

func _log_event(message: String):
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)
