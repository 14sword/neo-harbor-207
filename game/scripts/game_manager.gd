extends Node

signal stats_changed(stat_name: String, new_value: float)
signal inventory_changed()
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
var skills: Dictionary = {}
var discovered_areas: Array = ["office", "street"]
var anomaly_level: float = 0.0
var play_time: float = 0.0
var interaction_count: int = 0

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
	"echo_crystal": {"name": "回响水晶", "desc": "蕴含灵能的水晶", "type": "material", "rarity": "epic", "icon": "ECH", "value": 0},
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
	for item in inventory:
		if item["id"] == item_id:
			item["amount"] += amount
			inventory_changed.emit()
			return
	inventory.append({"id": item_id, "amount": amount})
	inventory_changed.emit()

func remove_item(item_id: String, amount: int = 1) -> bool:
	for i in range(inventory.size()):
		if inventory[i]["id"] == item_id:
			inventory[i]["amount"] -= amount
			if inventory[i]["amount"] <= 0:
				inventory.remove_at(i)
			inventory_changed.emit()
			return true
	return false

func has_item(item_id: String) -> bool:
	for item in inventory:
		if item["id"] == item_id and item["amount"] > 0:
			return true
	return false

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
	anomaly_level = min(anomaly_level + amount, 100.0)
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

func spend_currency(amount: int) -> bool:
	if currency < amount:
		return false
	currency -= amount
	return true

func get_save_data() -> Dictionary:
	return {
		"player_stats": player_stats,
		"inventory": inventory,
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
	if data.has("skills"):
		skills = data["skills"]
	if data.has("discovered_areas"):
		discovered_areas = data["discovered_areas"]
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
