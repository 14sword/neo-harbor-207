extends Node

signal run_started(run_seed: int)
signal tile_selected(tile: Dictionary)
signal node_completed(tile: Dictionary)
signal run_ended(result: Dictionary)
signal equipment_changed()

const MAX_TILE_COUNT: int = 9

var unlocked_difficulty: int = 1
var best_rating: String = ""
var best_cleared_nodes: int = 0
var codex: Dictionary = {}
var discovered_clues: Dictionary = {}
var gate_phase: int = 0
var equipped_items: Dictionary = {
	"weapon_core": "",
	"armor": "",
	"boots": "",
	"relic": "",
	"class_mod": "",
}

var active_run: Dictionary = {}
var current_tile: Dictionary = {}
var last_result: Dictionary = {}

var _rng := RandomNumberGenerator.new()

const TILE_DEFINITIONS: Dictionary = {
	"normal": {"name": "漂移镶片", "desc": "稳定的异界碎片，适合热身。", "reward_bias": "balanced"},
	"event": {"name": "异闻镶片", "desc": "空间里有事件和短契约。", "reward_bias": "material"},
	"elite": {"name": "压迫镶片", "desc": "精英怪更多，但装备掉落更好。", "reward_bias": "equipment"},
	"shop": {"name": "回声商店", "desc": "用裂隙碎片换药剂或遗物。", "reward_bias": "utility"},
	"boss": {"name": "缝合锚点", "desc": "首领守住了回廊缝线。", "reward_bias": "boss"},
}

const REALMS: Array[Dictionary] = [
	{"id": "western_fantasy", "name": "西幻黏液沼", "modifier": "史莱姆死亡会留下酸液区。", "color": Color(0.1, 0.95, 0.65, 1.0), "enemy_tags": ["slime", "automaton"]},
	{"id": "eastern_crypt", "name": "东方符墓", "modifier": "僵尸定身频率提高，但掉落符纸材料。", "color": Color(1.0, 0.76, 0.2, 1.0), "enemy_tags": ["jiangshi", "stone_idol"]},
	{"id": "mirror_realm", "name": "镜界花庭", "modifier": "镜像怪物出现，精英掉落遗物概率提高。", "color": Color(1.0, 0.35, 0.86, 1.0), "enemy_tags": ["mirror_witch", "book_spirit"]},
	{"id": "cyber_ruin", "name": "赛博废墟", "modifier": "投射物速度提高，职业模组掉落概率提高。", "color": Color(0.0, 0.92, 1.0, 1.0), "enemy_tags": ["cyber_wraith", "automaton"]},
	{"id": "ash_sand", "name": "影砂荒原", "modifier": "游魂更活跃，移动型装备更容易出现。", "color": Color(0.72, 0.45, 1.0, 1.0), "enemy_tags": ["ghost", "cyber_wraith"]},
]

const TIME_PHASES: Dictionary = {
	"dawn": {"name": "黎明", "modifier": "视野清晰，普通材料略多。"},
	"dusk": {"name": "黄昏", "modifier": "精英气息增强，边缘裂口更不稳定。"},
	"night": {"name": "深夜", "modifier": "怪物攻击更紧，稀有装备概率提高。"},
	"eclipse": {"name": "蚀时", "modifier": "坐标短暂失真，首领机制进入异常相位。"},
}

const WEATHER_TYPES: Dictionary = {
	"data_rain": {"name": "数据雨", "modifier": "投射物拖尾增强，赛博材料更常见。", "enemy_bias": ["cyber_wraith", "automaton"], "reward_bias": "data"},
	"rift_snow": {"name": "裂雪", "modifier": "地面出现微弱减速感，东方与石像系更常见。", "enemy_bias": ["jiangshi", "stone_idol"], "reward_bias": "talisman"},
	"thunderstorm": {"name": "雷暴", "modifier": "落雷预警会扰乱走位，机巧/赛博掉落提升。", "enemy_bias": ["automaton", "cyber_wraith"], "reward_bias": "machine"},
	"fog_tide": {"name": "雾潮", "modifier": "远处怪物淡入，游魂与镜界怪物增强。", "enemy_bias": ["ghost", "mirror_witch", "book_spirit"], "reward_bias": "mirror"},
	"clear_rift": {"name": "晴裂", "modifier": "裂隙较稳定，适合商店与短事件。", "enemy_bias": [], "reward_bias": "balanced"},
}

const LAYER_DEFINITIONS: Array[Dictionary] = [
	{"layer": 1, "name": "外层镶片", "pattern": ["normal", "event", "boss"], "realm_pool": ["western_fantasy", "eastern_crypt", "ash_sand"]},
	{"layer": 2, "name": "中层错位", "pattern": ["normal", "shop", "boss"], "realm_pool": ["mirror_realm", "cyber_ruin", "western_fantasy", "eastern_crypt"]},
	{"layer": 3, "name": "内层缝合", "pattern": ["normal", "elite", "boss"], "realm_pool": ["western_fantasy", "eastern_crypt", "mirror_realm", "cyber_ruin", "ash_sand"]},
]

const ENVIRONMENT_SEQUENCE: Array[Dictionary] = [
	{"time_phase": "dawn", "weather": "data_rain"},
	{"time_phase": "dusk", "weather": "rift_snow"},
	{"time_phase": "eclipse", "weather": "fog_tide"},
	{"time_phase": "night", "weather": "thunderstorm"},
	{"time_phase": "dawn", "weather": "data_rain"},
	{"time_phase": "eclipse", "weather": "fog_tide"},
	{"time_phase": "dusk", "weather": "rift_snow"},
	{"time_phase": "night", "weather": "thunderstorm"},
	{"time_phase": "eclipse", "weather": "fog_tide"},
]

const SUSPENSE_ARCHIVE: Dictionary = {
	"monster_origin_01": {"category": "怪物来源", "title": "史莱姆并非低等生命", "text": "它们记得一座被切碎的蓝色月亮，只是不知道月亮曾经叫作故乡。"},
	"hezhen_record_01": {"category": "何真异常记录", "title": "何真留下的坐标", "text": "坐标重复出现三次，每次都比现实时间提前七分钟。"},
	"stitcher_sentence_01": {"category": "万界缝合者残句", "title": "门后不是出口", "text": "门后不是出口，是某个人把出口伪装成了门。"},
	"missing_coord_01": {"category": "失踪坐标", "title": "第九镶片的空白", "text": "第九镶片完成后，地图上会多出一个不属于本次 run 的影子节点。"},
	"monster_origin_02": {"category": "怪物来源", "title": "符墓的错字", "text": "僵尸额头的符纸并不镇尸，它在给尸体发送回家指令。"},
	"hezhen_record_02": {"category": "何真异常记录", "title": "观测者反转", "text": "何真写下：当裂隙门开始凝视我，说明门后的东西已经学会等待。"},
}

const ENEMY_DEFINITIONS: Dictionary = {
	"slime": {
		"id": "slime", "name": "星露史莱姆", "realm": "western_fantasy", "rank": "normal",
		"hp": 42.0, "speed": 90.0, "contact_damage": 8.0, "exp": 9, "sprite": "res://assets/rift/enemies/slime.png",
		"attacks": [
			{"id": "hop", "name": "弹跳撞击", "cooldown": 1.4, "range": 42.0, "damage": 8.0, "windup": 0.18, "type": "lunge"},
			{"id": "acid", "name": "酸液喷吐", "cooldown": 4.0, "range": 260.0, "damage": 7.0, "windup": 0.55, "type": "projectile"},
		],
		"drops": ["rift_mucus", "health_potion"],
	},
	"slime_split": {
		"id": "slime_split", "name": "裂滴史莱姆", "realm": "western_fantasy", "rank": "minion",
		"hp": 18.0, "speed": 124.0, "contact_damage": 5.0, "exp": 3, "sprite": "res://assets/rift/enemies/slime_split.png",
		"attacks": [{"id": "nip", "name": "黏液啃咬", "cooldown": 1.2, "range": 34.0, "damage": 5.0, "windup": 0.12, "type": "melee"}],
		"drops": ["rift_mucus"],
	},
	"jiangshi": {
		"id": "jiangshi", "name": "贴符僵尸", "realm": "eastern_crypt", "rank": "normal",
		"hp": 58.0, "speed": 78.0, "contact_damage": 11.0, "exp": 12, "sprite": "res://assets/rift/enemies/jiangshi.png",
		"attacks": [
			{"id": "palm", "name": "僵直拍击", "cooldown": 1.2, "range": 50.0, "damage": 12.0, "windup": 0.28, "type": "melee"},
			{"id": "talisman", "name": "黄符定身", "cooldown": 5.0, "range": 220.0, "damage": 5.0, "windup": 0.75, "type": "snare"},
		],
		"drops": ["rift_talisman", "talisman_paper"],
	},
	"ghost": {
		"id": "ghost", "name": "影砂游魂", "realm": "ash_sand", "rank": "normal",
		"hp": 48.0, "speed": 116.0, "contact_damage": 9.0, "exp": 11, "sprite": "res://assets/rift/enemies/ghost.png",
		"attacks": [
			{"id": "sandbolt", "name": "暗砂弹", "cooldown": 2.2, "range": 320.0, "damage": 10.0, "windup": 0.45, "type": "projectile"},
			{"id": "phase", "name": "潜影换位", "cooldown": 6.0, "range": 380.0, "damage": 0.0, "windup": 0.3, "type": "teleport"},
		],
		"drops": ["shadow_residue", "energy_potion"],
	},
	"automaton": {
		"id": "automaton", "name": "机巧傀儡", "realm": "cyber_ruin", "rank": "normal",
		"hp": 72.0, "speed": 66.0, "contact_damage": 10.0, "exp": 14, "sprite": "res://assets/rift/enemies/automaton.png",
		"attacks": [
			{"id": "trishot", "name": "三连弹", "cooldown": 1.8, "range": 380.0, "damage": 7.0, "windup": 0.38, "type": "trishot"},
			{"id": "shield", "name": "开盾", "cooldown": 7.0, "range": 0.0, "damage": 0.0, "windup": 0.2, "type": "shield"},
		],
		"drops": ["clockwork_core", "data_shard"],
	},
	"mirror_witch": {
		"id": "mirror_witch", "name": "镜面巫女", "realm": "mirror_realm", "rank": "elite",
		"hp": 128.0, "speed": 82.0, "contact_damage": 14.0, "exp": 28, "sprite": "res://assets/rift/enemies/mirror_witch.png",
		"attacks": [
			{"id": "beam", "name": "镜光束", "cooldown": 3.0, "range": 420.0, "damage": 22.0, "windup": 0.95, "type": "beam"},
			{"id": "mirror", "name": "制造镜像", "cooldown": 9.0, "range": 0.0, "damage": 0.0, "windup": 0.5, "type": "summon"},
		],
		"drops": ["mirror_shard", "echo_crystal"],
	},
	"stone_idol": {
		"id": "stone_idol", "name": "玄甲石像", "realm": "eastern_crypt", "rank": "elite",
		"hp": 168.0, "speed": 50.0, "contact_damage": 18.0, "exp": 34, "sprite": "res://assets/rift/enemies/stone_idol.png",
		"attacks": [
			{"id": "slam", "name": "玄甲重砸", "cooldown": 2.8, "range": 78.0, "damage": 24.0, "windup": 0.72, "type": "slam"},
			{"id": "ring", "name": "环形震波", "cooldown": 6.0, "range": 185.0, "damage": 16.0, "windup": 0.9, "type": "ring"},
		],
		"drops": ["idol_plate", "rare_mineral"],
	},
	"cyber_wraith": {
		"id": "cyber_wraith", "name": "赛博残影", "realm": "cyber_ruin", "rank": "elite",
		"hp": 118.0, "speed": 150.0, "contact_damage": 16.0, "exp": 30, "sprite": "res://assets/rift/enemies/cyber_wraith.png",
		"attacks": [
			{"id": "dash", "name": "残影突刺", "cooldown": 3.0, "range": 340.0, "damage": 21.0, "windup": 0.6, "type": "dash"},
			{"id": "mine", "name": "电磁雷", "cooldown": 5.0, "range": 260.0, "damage": 17.0, "windup": 0.45, "type": "mine"},
		],
		"drops": ["phase_wire", "memory_chip"],
	},
	"book_spirit": {
		"id": "book_spirit", "name": "禁书页灵", "realm": "mirror_realm", "rank": "elite",
		"hp": 106.0, "speed": 96.0, "contact_damage": 12.0, "exp": 27, "sprite": "res://assets/rift/enemies/book_spirit.png",
		"attacks": [
			{"id": "paper", "name": "纸刃", "cooldown": 1.5, "range": 360.0, "damage": 9.0, "windup": 0.32, "type": "projectile"},
			{"id": "silence", "name": "封页沉默", "cooldown": 8.0, "range": 280.0, "damage": 8.0, "windup": 0.8, "type": "silence"},
		],
		"drops": ["forbidden_page", "data_shard"],
	},
}

const BOSS_DEFINITIONS: Array[Dictionary] = [
	{"id": "jiangshi", "name": "黄符尸王", "hp_multiplier": 4.2, "damage_multiplier": 1.35, "reward_tag": "eastern"},
	{"id": "mirror_witch", "name": "镜界裁缝", "hp_multiplier": 4.6, "damage_multiplier": 1.35, "reward_tag": "mirror"},
	{"id": "cyber_wraith", "name": "万界缝合者", "hp_multiplier": 5.2, "damage_multiplier": 1.5, "reward_tag": "rift"},
]

const EQUIPMENT_DEFINITIONS: Dictionary = {
	"cipher_matrix_core": {"id": "cipher_matrix_core", "name": "矩阵解析核心", "slot": "weapon_core", "rarity": "rare", "class": "cipher", "icon": "res://assets/rift/equipment/rift_blade_core.png", "affixes": {"int": 2, "chain": 1}},
	"cipher_fractal_lens": {"id": "cipher_fractal_lens", "name": "分形透镜", "slot": "class_mod", "rarity": "epic", "class": "cipher", "icon": "res://assets/rift/equipment/class_modulator.png", "affixes": {"int": 3, "skill_cd": -0.4}},
	"chrome_void_plate": {"id": "chrome_void_plate", "name": "虚鳞胸甲", "slot": "armor", "rarity": "rare", "class": "chrome", "icon": "res://assets/rift/equipment/voidscale_armor.png", "affixes": {"max_health": 18, "guard": 1}},
	"chrome_impact_core": {"id": "chrome_impact_core", "name": "冲击炉心", "slot": "weapon_core", "rarity": "epic", "class": "chrome", "icon": "res://assets/rift/equipment/rift_blade_core.png", "affixes": {"melee": 2, "shield": 1}},
	"echo_mirror_relic": {"id": "echo_mirror_relic", "name": "镜鸣遗物", "slot": "relic", "rarity": "rare", "class": "echo", "icon": "res://assets/rift/equipment/mirror_relic.png", "affixes": {"per": 2, "slow": 1}},
	"echo_psy_mod": {"id": "echo_psy_mod", "name": "灵纹调频器", "slot": "class_mod", "rarity": "epic", "class": "echo", "icon": "res://assets/rift/equipment/class_modulator.png", "affixes": {"per": 3, "area": 1}},
	"shadow_blink_boots": {"id": "shadow_blink_boots", "name": "影跃足具", "slot": "boots", "rarity": "rare", "class": "shadow", "icon": "res://assets/rift/equipment/blink_boots.png", "affixes": {"agi": 2, "dodge": 1}},
	"shadow_backstab_core": {"id": "shadow_backstab_core", "name": "背刺裂刃", "slot": "weapon_core", "rarity": "epic", "class": "shadow", "icon": "res://assets/rift/equipment/rift_blade_core.png", "affixes": {"agi": 3, "crit": 1}},
	"rift_blade_core": {"id": "rift_blade_core", "name": "裂隙刃核", "slot": "weapon_core", "rarity": "common", "class": "any", "icon": "res://assets/rift/equipment/rift_blade_core.png", "affixes": {"attack": 1}},
	"voidscale_armor": {"id": "voidscale_armor", "name": "虚鳞护甲", "slot": "armor", "rarity": "common", "class": "any", "icon": "res://assets/rift/equipment/voidscale_armor.png", "affixes": {"max_health": 8}},
	"blink_boots": {"id": "blink_boots", "name": "闪步足具", "slot": "boots", "rarity": "common", "class": "any", "icon": "res://assets/rift/equipment/blink_boots.png", "affixes": {"speed": 1}},
	"mirror_relic": {"id": "mirror_relic", "name": "镜界遗物", "slot": "relic", "rarity": "legendary", "class": "any", "icon": "res://assets/rift/equipment/mirror_relic.png", "affixes": {"all": 1, "reroll": 1}},
}

const CLASS_LOOT_POOLS: Dictionary = {
	"cipher": ["cipher_matrix_core", "cipher_fractal_lens", "rift_blade_core", "mirror_relic"],
	"chrome": ["chrome_void_plate", "chrome_impact_core", "voidscale_armor", "rift_blade_core"],
	"echo": ["echo_mirror_relic", "echo_psy_mod", "mirror_relic", "blink_boots"],
	"shadow": ["shadow_blink_boots", "shadow_backstab_core", "blink_boots", "rift_blade_core"],
	"unknown": ["rift_blade_core", "voidscale_armor", "blink_boots", "mirror_relic"],
}

func _ready() -> void:
	print("[RiftRunManager] 初始化完成")

func start_run(run_seed: int = 0, difficulty: int = 1) -> Dictionary:
	if run_seed == 0:
		run_seed = int(Time.get_unix_time_from_system()) ^ randi()
	_rng.seed = run_seed
	active_run = {
		"seed": run_seed,
		"difficulty": clampi(difficulty, 1, max(unlocked_difficulty, difficulty)),
		"started_at": Time.get_unix_time_from_system(),
		"tiles": _generate_tiles(),
		"cleared_tiles": [],
		"clues_found": [],
		"new_clues": [],
		"defeated": {},
		"total_kills": 0,
		"damage_taken": 0.0,
		"combo_best": 0,
		"status": "running",
	}
	current_tile = {}
	last_result = {}
	run_started.emit(run_seed)
	return active_run.duplicate(true)

func _generate_tiles() -> Array:
	var tiles: Array = []
	var global_index: int = 0
	for layer_def in LAYER_DEFINITIONS:
		var pattern: Array = layer_def.get("pattern", [])
		var realm_pool: Array = layer_def.get("realm_pool", [])
		for local_index in range(3):
			var tile_type: String = str(pattern[local_index])
			if global_index in [2, 5, 8]:
				tile_type = "boss"
			var realm_id: String = str(realm_pool[_rng.randi_range(0, realm_pool.size() - 1)])
			var realm: Dictionary = _realm_by_id(realm_id)
			var env: Dictionary = ENVIRONMENT_SEQUENCE[global_index % ENVIRONMENT_SEQUENCE.size()].duplicate(true)
			var time_phase: String = str(env.get("time_phase", "dawn"))
			var weather: String = str(env.get("weather", "data_rain"))
			var base: Dictionary = TILE_DEFINITIONS[tile_type]
			var enemy_tags: Array = _enemy_tags_for_environment(realm, weather)
			var clue_id: String = _suspense_id_for_index(global_index)
			var layer_index: int = int(layer_def.get("layer", 1))
			var time_data: Dictionary = TIME_PHASES.get(time_phase, {})
			var weather_data: Dictionary = WEATHER_TYPES.get(weather, {})
			var modifier_text: String = "%s\n%s · %s" % [
				realm.get("modifier", ""),
				time_data.get("modifier", ""),
				weather_data.get("modifier", ""),
			]
			tiles.append({
				"id": "tile_%02d" % [global_index + 1],
				"index": global_index,
				"type": tile_type,
				"name": base["name"],
				"description": base["desc"],
				"layer": layer_index,
				"layer_name": layer_def.get("name", "未知镶层"),
				"ring": local_index + 1,
				"realm_id": realm["id"],
				"realm_name": realm["name"],
				"time_phase": time_phase,
				"time_name": time_data.get("name", time_phase),
				"weather": weather,
				"weather_name": weather_data.get("name", weather),
				"background_path": _background_path_for(realm["id"], time_phase, weather),
				"modifier": modifier_text,
				"enemy_tags": enemy_tags,
				"reward_bias": _reward_bias_for_tile(tile_type, weather),
				"reward_tags": [base["reward_bias"], weather_data.get("reward_bias", "balanced")],
				"suspense_id": clue_id,
				"cleared": false,
				"locked": global_index > 0,
				"color": realm["color"],
			})
			global_index += 1
	return tiles

func _realm_by_id(realm_id: String) -> Dictionary:
	for realm in REALMS:
		if str(realm.get("id", "")) == realm_id:
			return realm.duplicate(true)
	return REALMS[0].duplicate(true)

func _enemy_tags_for_environment(realm: Dictionary, weather: String) -> Array:
	var tags: Array = realm.get("enemy_tags", []).duplicate()
	var weather_data: Dictionary = WEATHER_TYPES.get(weather, {})
	for biased_enemy in weather_data.get("enemy_bias", []):
		if not (biased_enemy in tags):
			tags.append(biased_enemy)
	return tags

func _background_path_for(realm_id: String, time_phase: String, weather: String) -> String:
	return "res://assets/rift/backgrounds/%s_%s_%s.png" % [realm_id, time_phase, weather]

func _reward_bias_for_tile(tile_type: String, weather: String) -> String:
	var weather_data: Dictionary = WEATHER_TYPES.get(weather, {})
	if tile_type in ["elite", "boss"]:
		return str(TILE_DEFINITIONS[tile_type].get("reward_bias", "equipment"))
	return str(weather_data.get("reward_bias", TILE_DEFINITIONS.get(tile_type, {}).get("reward_bias", "balanced")))

func _suspense_id_for_index(index: int) -> String:
	var ids: Array = SUSPENSE_ARCHIVE.keys()
	if ids.is_empty():
		return ""
	return str(ids[index % ids.size()])

func choose_tile(tile_id: String) -> Dictionary:
	if active_run.is_empty():
		start_run()
	for tile in active_run.get("tiles", []):
		if tile.get("id", "") == tile_id:
			if tile.get("locked", false):
				return {}
			current_tile = tile.duplicate(true)
			tile_selected.emit(current_tile)
			return current_tile.duplicate(true)
	return {}

func complete_current_node(kill_count: int, damage_taken: float, combo_best: int) -> void:
	if current_tile.is_empty() or active_run.is_empty():
		return
	active_run["total_kills"] = int(active_run.get("total_kills", 0)) + kill_count
	active_run["damage_taken"] = float(active_run.get("damage_taken", 0.0)) + damage_taken
	active_run["combo_best"] = maxi(int(active_run.get("combo_best", 0)), combo_best)
	active_run["cleared_tiles"].append(current_tile.get("id", ""))
	_record_suspense_for_tile(current_tile)
	for i in range(active_run["tiles"].size()):
		if active_run["tiles"][i].get("id", "") == current_tile.get("id", ""):
			active_run["tiles"][i]["cleared"] = true
			if i + 1 < active_run["tiles"].size():
				active_run["tiles"][i + 1]["locked"] = false
			break
	best_cleared_nodes = maxi(best_cleared_nodes, active_run["cleared_tiles"].size())
	node_completed.emit(current_tile.duplicate(true))
	current_tile = {}

func _record_suspense_for_tile(tile: Dictionary) -> void:
	var clue_id: String = str(tile.get("suspense_id", ""))
	if clue_id.is_empty() or not SUSPENSE_ARCHIVE.has(clue_id):
		return
	var found: Array = active_run.get("clues_found", [])
	if not (clue_id in found):
		found.append(clue_id)
	active_run["clues_found"] = found
	if discovered_clues.has(clue_id):
		return
	discovered_clues[clue_id] = true
	var new_clues: Array = active_run.get("new_clues", [])
	var clue: Dictionary = SUSPENSE_ARCHIVE[clue_id].duplicate(true)
	clue["id"] = clue_id
	clue["layer"] = tile.get("layer", 1)
	clue["weather"] = tile.get("weather_name", tile.get("weather", ""))
	new_clues.append(clue)
	active_run["new_clues"] = new_clues

func record_enemy_defeated(enemy_id: String) -> void:
	if active_run.is_empty():
		return
	var defeated: Dictionary = active_run.get("defeated", {})
	defeated[enemy_id] = int(defeated.get(enemy_id, 0)) + 1
	active_run["defeated"] = defeated
	codex[enemy_id] = int(codex.get(enemy_id, 0)) + 1

func end_run(result_status: String = "cleared") -> Dictionary:
	if active_run.is_empty():
		start_run()
	var cleared_nodes: int = active_run.get("cleared_tiles", []).size()
	var result: Dictionary = _build_result(result_status, cleared_nodes)
	last_result = result
	active_run["status"] = result_status
	_apply_rewards(result)
	run_ended.emit(result.duplicate(true))
	active_run = {}
	current_tile = {}
	return result.duplicate(true)

func _build_result(result_status: String, cleared_nodes: int) -> Dictionary:
	var difficulty := int(active_run.get("difficulty", 1))
	var total_kills := int(active_run.get("total_kills", 0))
	var damage_taken := float(active_run.get("damage_taken", 0.0))
	var combo_best := int(active_run.get("combo_best", 0))
	var exp := 25 * cleared_nodes + total_kills * 4 + difficulty * 12
	var currency := 12 * cleared_nodes + total_kills * 2
	if result_status == "cleared":
		exp += 160 + difficulty * 40
		currency += 90
	elif result_status == "defeated":
		exp = int(exp * 0.55)
		currency = int(currency * 0.45)
	var rating := _calculate_rating(result_status, cleared_nodes, damage_taken, combo_best)
	var equipment_drops := _roll_equipment_drops(cleared_nodes, rating, result_status)
	var materials := _roll_materials(cleared_nodes, result_status)
	var new_clues: Array = active_run.get("new_clues", []).duplicate(true)
	return {
		"status": result_status,
		"rating": rating,
		"cleared_nodes": cleared_nodes,
		"total_kills": total_kills,
		"damage_taken": int(damage_taken),
		"combo_best": combo_best,
		"exp": exp,
		"currency": currency,
		"materials": materials,
		"equipment_drops": equipment_drops,
		"defeated": active_run.get("defeated", {}).duplicate(),
		"new_clues": new_clues,
		"unresolved_phenomena": _roll_unresolved_phenomena(cleared_nodes),
	}

func _calculate_rating(result_status: String, cleared_nodes: int, damage_taken: float, combo_best: int) -> String:
	if result_status == "defeated":
		return "D"
	var score := cleared_nodes * 14 + combo_best * 2 - int(damage_taken / 18.0)
	if result_status == "cleared":
		score += 25
	if score >= 145:
		return "S"
	if score >= 110:
		return "A"
	if score >= 75:
		return "B"
	if score >= 42:
		return "C"
	return "D"

func _roll_materials(cleared_nodes: int, result_status: String) -> Dictionary:
	var multiplier := 2 if result_status == "cleared" else 1
	var materials: Dictionary = {
		"rift_shard": maxi(1, cleared_nodes * multiplier),
		"anomaly_thread": maxi(0, int(cleared_nodes / 2)),
	}
	var weather_counts: Dictionary = _weather_counts_for_cleared()
	if int(weather_counts.get("data_rain", 0)) > 0:
		materials["data_shard"] = int(weather_counts["data_rain"]) * multiplier
	if int(weather_counts.get("rift_snow", 0)) > 0:
		materials["frozen_talisman"] = int(weather_counts["rift_snow"]) * multiplier
	if int(weather_counts.get("thunderstorm", 0)) > 0:
		materials["phase_wire"] = int(weather_counts["thunderstorm"]) * multiplier
	if int(weather_counts.get("fog_tide", 0)) > 0:
		materials["mirror_mist"] = int(weather_counts["fog_tide"]) * multiplier
	return materials

func _weather_counts_for_cleared() -> Dictionary:
	var counts: Dictionary = {}
	var cleared_ids: Array = active_run.get("cleared_tiles", [])
	for tile in active_run.get("tiles", []):
		if tile.get("id", "") in cleared_ids:
			var weather: String = str(tile.get("weather", "clear_rift"))
			counts[weather] = int(counts.get(weather, 0)) + 1
	return counts

func _roll_unresolved_phenomena(cleared_nodes: int) -> Array[String]:
	var phenomena: Array[String] = []
	var weather_counts: Dictionary = _weather_counts_for_cleared()
	if int(weather_counts.get("fog_tide", 0)) > 0:
		phenomena.append("雾潮退去后，地面留下了不属于玩家的第二组脚印。")
	if int(weather_counts.get("thunderstorm", 0)) > 0:
		phenomena.append("雷暴节点的落雷轨迹组成了一个尚未解锁的坐标。")
	if cleared_nodes >= 6:
		phenomena.append("第六镶片之后，裂隙门短暂显示出门后人影。")
	if cleared_nodes >= 9:
		phenomena.append("完整通关后，节点选择界面多闪了一枚不存在的第十镶片。")
	if phenomena.is_empty():
		phenomena.append("本次回廊没有给出答案，只留下更稳定的回声。")
	return phenomena

func _roll_equipment_drops(cleared_nodes: int, rating: String, result_status: String) -> Array:
	var drops: Array = []
	if cleared_nodes <= 0:
		return drops
	var drop_count := 1
	if cleared_nodes >= 6:
		drop_count += 1
	if result_status == "cleared":
		drop_count += 1
	if rating in ["S", "A"]:
		drop_count += 1
	for i in range(drop_count):
		drops.append(_roll_equipment(rating, i))
	return drops

func _roll_equipment(rating: String, index: int) -> Dictionary:
	var class_id := _get_current_class_id()
	var pool: Array = CLASS_LOOT_POOLS.get(class_id, CLASS_LOOT_POOLS["unknown"])
	var id: String = pool[_rng.randi_range(0, pool.size() - 1)]
	if rating == "S" and index == 0 and EQUIPMENT_DEFINITIONS.has("mirror_relic"):
		id = "mirror_relic"
	var item: Dictionary = EQUIPMENT_DEFINITIONS[id].duplicate(true)
	item["instance_id"] = "%s_%d_%d" % [id, Time.get_unix_time_from_system(), _rng.randi()]
	item["level"] = maxi(1, int(active_run.get("difficulty", 1)) + int(active_run.get("cleared_tiles", []).size() / 3))
	return item

func _get_current_class_id() -> String:
	var ccm = get_node_or_null("/root/CharacterClassManager")
	if ccm and ccm.has_method("get_class_id"):
		return ccm.get_class_id()
	return "unknown"

func _apply_rewards(result: Dictionary) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if result.get("exp", 0) > 0:
			gm.gain_exp(float(result["exp"]))
		if result.get("currency", 0) > 0:
			gm.add_currency(int(result["currency"]))
		for material_id in result.get("materials", {}):
			gm.add_item(material_id, int(result["materials"][material_id]))
	if _rating_value(result.get("rating", "")) > _rating_value(best_rating):
		best_rating = result.get("rating", "")
	if result.get("status", "") == "cleared":
		unlocked_difficulty = maxi(unlocked_difficulty, int(active_run.get("difficulty", 1)) + 1)
		gate_phase = clampi(gate_phase + 1, 0, 4)
	elif int(result.get("cleared_nodes", 0)) >= 6:
		gate_phase = maxi(gate_phase, 2)
	elif int(result.get("cleared_nodes", 0)) >= 3:
		gate_phase = maxi(gate_phase, 1)

func add_equipment_to_bag(item: Dictionary) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if gm.has_method("add_equipment"):
			gm.add_equipment(item)
		else:
			gm.add_item(item.get("id", "rift_unknown_equipment"), 1)

func equip_item(item: Dictionary) -> void:
	var slot: String = str(item.get("slot", ""))
	if slot.is_empty():
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("add_equipment") and gm.has_method("equip_equipment"):
		var instance_id := str(item.get("instance_id", ""))
		if instance_id.is_empty() or gm.get_equipment_by_instance_id(instance_id).is_empty():
			instance_id = gm.add_equipment(item)
		if gm.equip_equipment(instance_id):
			equipped_items[slot] = item.get("id", "")
	else:
		equipped_items[slot] = item.get("id", "")
	equipment_changed.emit()

func dismantle_item(item: Dictionary) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var instance_id := str(item.get("instance_id", ""))
		if not instance_id.is_empty() and gm.has_method("dismantle_equipment") and not gm.get_equipment_by_instance_id(instance_id).is_empty():
			gm.dismantle_equipment(instance_id)
			return
		var rarity: String = str(item.get("rarity", "common"))
		var amount: int = 1
		match rarity:
			"rare": amount = 2
			"epic": amount = 4
			"legendary": amount = 8
		gm.add_item("rift_shard", amount)

func _rating_value(rating: String) -> int:
	match rating:
		"S": return 5
		"A": return 4
		"B": return 3
		"C": return 2
		"D": return 1
		_: return 0

func get_enemy_definitions() -> Dictionary:
	return ENEMY_DEFINITIONS.duplicate(true)

func get_tile_definitions() -> Dictionary:
	return TILE_DEFINITIONS.duplicate(true)

func get_realms() -> Array:
	return REALMS.duplicate(true)

func get_time_phases() -> Dictionary:
	return TIME_PHASES.duplicate(true)

func get_weather_types() -> Dictionary:
	return WEATHER_TYPES.duplicate(true)

func get_layer_definitions() -> Array:
	return LAYER_DEFINITIONS.duplicate(true)

func get_suspense_archive() -> Dictionary:
	return SUSPENSE_ARCHIVE.duplicate(true)

func get_gate_phase() -> int:
	return gate_phase

func get_equipment_definitions() -> Dictionary:
	return EQUIPMENT_DEFINITIONS.duplicate(true)

func get_boss_definitions() -> Array:
	return BOSS_DEFINITIONS.duplicate(true)

func get_save_data() -> Dictionary:
	return {
		"unlocked_difficulty": unlocked_difficulty,
		"best_rating": best_rating,
		"best_cleared_nodes": best_cleared_nodes,
		"codex": codex.duplicate(),
		"discovered_clues": discovered_clues.duplicate(),
		"gate_phase": gate_phase,
		"equipped_items": equipped_items.duplicate(),
	}

func load_save_data(data: Dictionary) -> void:
	unlocked_difficulty = int(data.get("unlocked_difficulty", 1))
	best_rating = str(data.get("best_rating", ""))
	best_cleared_nodes = int(data.get("best_cleared_nodes", 0))
	codex = data.get("codex", {}).duplicate()
	discovered_clues = data.get("discovered_clues", {}).duplicate()
	gate_phase = int(data.get("gate_phase", 0))
	if data.has("equipped_items"):
		for slot in equipped_items:
			equipped_items[slot] = data["equipped_items"].get(slot, "")
		_migrate_legacy_equipped_items()

func _migrate_legacy_equipped_items() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm or not gm.has_method("add_equipment") or not gm.has_method("equip_equipment"):
		return
	for slot in equipped_items:
		if not gm.equipped_items.has(slot) or not str(gm.equipped_items.get(slot, "")).is_empty():
			continue
		var item_id := str(equipped_items.get(slot, ""))
		if item_id.is_empty():
			continue
		var definitions := get_equipment_definitions()
		var item: Dictionary = definitions.get(item_id, {"id": item_id, "slot": slot})
		item["id"] = item_id
		item["slot"] = slot
		var instance_id: String = gm.add_equipment(item)
		gm.equip_equipment(instance_id)
