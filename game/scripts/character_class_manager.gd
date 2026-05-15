extends Node

enum ClassType { CIPHER, CHROME, ECHO, SHADOW }
enum FormType { FORM_FEMALE, FORM_HEAVY, FORM_ETHEREAL, FORM_STEALTH }

signal class_changed(new_class: int)

var _current_class: ClassType = ClassType.CIPHER
var _player_name: String = "玩家"
var _class_selected: bool = false

const CLASS_DATA = {
	ClassType.CIPHER: {
		"id": "cipher",
		"name": "数据分析师",
		"codename": "CIPHER",
		"description": "精通数据分析与系统入侵，能发现隐藏在数据中的维度坐标",
		"form_type": "form_female",
		"sprite_scale": Vector2(0.25, 0.25),
		"sprite_modulate": Color(1, 1, 1, 1),
		"shader": null,
		"extra_effects": "blue_flow_particles",
		"base_stats": {
			"health": 80.0,
			"max_health": 80.0,
			"energy": 100.0,
			"max_energy": 100.0,
			"int": 18,
			"per": 12,
			"agi": 8,
			"cha": 10,
		},
		"skills": ["data_insight_1", "system_hack_1"],
		"initial_affinity": {"zhang_san": 10},
		"storyline": "企业暗流",
		"aliases": ["零壹", "刻律", "矩点"],
	},
	ClassType.CHROME: {
		"id": "chrome",
		"name": "义体战士",
		"codename": "CHROME",
		"description": "经过深度义体改造的战斗专家，在街头生存中无往不利",
		"form_type": "form_heavy",
		"sprite_scale": Vector2(0.29, 0.29),
		"sprite_modulate": Color(1, 1, 1, 1),
		"shader": null,
		"extra_effects": "metallic_reflection",
		"base_stats": {
			"health": 120.0,
			"max_health": 120.0,
			"energy": 80.0,
			"max_energy": 80.0,
			"int": 8,
			"per": 10,
			"agi": 14,
			"cha": 6,
		},
		"skills": ["cyborg_overload_1", "shield_gen_1"],
		"initial_affinity": {"liu_feng": 10},
		"storyline": "街头生存",
		"aliases": ["钢隼", "钨骸", "雷霆-V"],
	},
	ClassType.ECHO: {
		"id": "echo",
		"name": "灵能感知者",
		"codename": "ECHO",
		"description": "天生对维度裂缝敏感，能看到常人无法察觉的异常现象",
		"form_type": "form_ethereal",
		"sprite_scale": Vector2(0.25, 0.25),
		"sprite_modulate": Color(1, 1, 1, 0.8),
		"shader": null,
		"extra_effects": "purple_orbiting_particles",
		"base_stats": {
			"health": 70.0,
			"max_health": 70.0,
			"energy": 110.0,
			"max_energy": 110.0,
			"int": 12,
			"per": 18,
			"agi": 8,
			"cha": 10,
		},
		"skills": ["dimension_sense_1", "psychic_blast_1"],
		"initial_affinity": {"sun_yue": 10},
		"storyline": "异常调查",
		"aliases": ["幽响", "频率-S", "灵汐"],
	},
	ClassType.SHADOW: {
		"id": "shadow",
		"name": "暗影潜行者",
		"codename": "SHADOW",
		"description": "游走于暗巷与黑市之间的情报专家，信息网络遍布全城",
		"form_type": "form_stealth",
		"sprite_scale": Vector2(0.23, 0.23),
		"sprite_modulate": Color(1, 1, 1, 0.9),
		"shader": null,
		"extra_effects": "afterimage",
		"base_stats": {
			"health": 90.0,
			"max_health": 90.0,
			"energy": 90.0,
			"max_energy": 90.0,
			"int": 10,
			"per": 10,
			"agi": 18,
			"cha": 8,
		},
		"skills": ["stealth_1", "info_network_1"],
		"initial_affinity": {"zhao_lin": 10},
		"storyline": "地下世界",
		"aliases": ["无名者", "掠鸦", "影迹"],
	},
}

const SKILL_DATA = {
	"data_insight_1": {"name": "数据透视", "level": 1, "max_level": 3, "type": "passive", "description": "可以发现隐藏的数据信息"},
	"data_insight_2": {"name": "数据透视", "level": 2, "max_level": 3, "type": "passive", "description": "数据透视范围扩大，发现更多隐藏信息"},
	"data_insight_3": {"name": "数据透视", "level": 3, "max_level": 3, "type": "active", "description": "主动扫描，揭示区域内所有隐藏数据"},
	"system_hack_1": {"name": "系统入侵", "level": 1, "max_level": 3, "type": "active", "description": "骇入简单终端获取信息"},
	"system_hack_2": {"name": "系统入侵", "level": 2, "max_level": 3, "type": "active", "description": "可以骇入中等安全级别的系统"},
	"system_hack_3": {"name": "系统入侵", "level": 3, "max_level": 3, "type": "active", "description": "骇入任何系统，包括AI中枢"},
	"dimension_map_1": {"name": "维度映射", "level": 1, "max_level": 3, "type": "active", "description": "标记附近维度裂缝位置"},
	"dimension_map_2": {"name": "维度映射", "level": 2, "max_level": 3, "type": "active", "description": "映射裂缝连接的维度信息"},
	"dimension_map_3": {"name": "维度映射", "level": 3, "max_level": 3, "type": "active", "description": "创建维度通道，短暂打开裂缝"},
	"cyborg_overload_1": {"name": "义体过载", "level": 1, "max_level": 3, "type": "active", "description": "短暂提升义体输出，增加攻击力"},
	"cyborg_overload_2": {"name": "义体过载", "level": 2, "max_level": 3, "type": "active", "description": "过载持续时间延长，附带范围伤害"},
	"cyborg_overload_3": {"name": "义体过载", "level": 3, "max_level": 3, "type": "active", "description": "完全过载，进入无敌状态数秒"},
	"shield_gen_1": {"name": "护盾生成", "level": 1, "max_level": 3, "type": "active", "description": "生成能量护盾吸收伤害"},
	"shield_gen_2": {"name": "护盾生成", "level": 2, "max_level": 3, "type": "active", "description": "护盾强度提升，可反弹部分伤害"},
	"shield_gen_3": {"name": "护盾生成", "level": 3, "max_level": 3, "type": "active", "description": "全队护盾，持续回复"},
	"melee_mastery_1": {"name": "近战精通", "level": 1, "max_level": 3, "type": "passive", "description": "近战攻击伤害提升"},
	"melee_mastery_2": {"name": "近战精通", "level": 2, "max_level": 3, "type": "passive", "description": "近战连击概率提升"},
	"melee_mastery_3": {"name": "近战精通", "level": 3, "max_level": 3, "type": "active", "description": "释放终结技，造成巨额伤害"},
	"dimension_sense_1": {"name": "维度感知", "level": 1, "max_level": 3, "type": "passive", "description": "可以感知附近的维度异常"},
	"dimension_sense_2": {"name": "维度感知", "level": 2, "max_level": 3, "type": "passive", "description": "感知范围扩大，可识别异常类型"},
	"dimension_sense_3": {"name": "维度感知", "level": 3, "max_level": 3, "type": "active", "description": "主动探测，揭示维度裂缝全貌"},
	"psychic_blast_1": {"name": "灵能冲击", "level": 1, "max_level": 3, "type": "active", "description": "释放灵能冲击波攻击敌人"},
	"psychic_blast_2": {"name": "灵能冲击", "level": 2, "max_level": 3, "type": "active", "description": "冲击波范围和伤害提升"},
	"psychic_blast_3": {"name": "灵能冲击", "level": 3, "max_level": 3, "type": "active", "description": "灵能风暴，大范围持续伤害"},
	"precog_dodge_1": {"name": "预知闪避", "level": 1, "max_level": 3, "type": "passive", "description": "有一定概率闪避攻击"},
	"precog_dodge_2": {"name": "预知闪避", "level": 2, "max_level": 3, "type": "passive", "description": "闪避概率大幅提升"},
	"precog_dodge_3": {"name": "预知闪避", "level": 3, "max_level": 3, "type": "active", "description": "时间减速，完全闪避所有攻击数秒"},
	"soul_link_1": {"name": "灵魂链接", "level": 1, "max_level": 3, "type": "active", "description": "与一个NPC建立临时精神链接"},
	"soul_link_2": {"name": "灵魂链接", "level": 2, "max_level": 3, "type": "active", "description": "链接增强，可共享感知信息"},
	"soul_link_3": {"name": "灵魂链接", "level": 3, "max_level": 3, "type": "active", "description": "深度链接，暂时获得链接者能力"},
	"stealth_1": {"name": "隐匿行踪", "level": 1, "max_level": 3, "type": "active", "description": "短暂隐身，避开敌人视线"},
	"stealth_2": {"name": "隐匿行踪", "level": 2, "max_level": 3, "type": "active", "description": "隐身时间延长，移动速度提升"},
	"stealth_3": {"name": "隐匿行踪", "level": 3, "max_level": 3, "type": "active", "description": "完全隐匿，攻击时不会暴露"},
	"info_network_1": {"name": "信息网络", "level": 1, "max_level": 3, "type": "passive", "description": "可以获取黑市情报"},
	"info_network_2": {"name": "信息网络", "level": 2, "max_level": 3, "type": "passive", "description": "情报范围扩大，获取更多秘密"},
	"info_network_3": {"name": "信息网络", "level": 3, "max_level": 3, "type": "active", "description": "全城信息网络，实时掌握所有动态"},
	"assassinate_1": {"name": "暗杀技巧", "level": 1, "max_level": 3, "type": "active", "description": "从暗处发动致命一击"},
	"assassinate_2": {"name": "暗杀技巧", "level": 2, "max_level": 3, "type": "active", "description": "暗杀伤害提升，暴击率增加"},
	"assassinate_3": {"name": "暗杀技巧", "level": 3, "max_level": 3, "type": "active", "description": "完美暗杀，一击必杀普通敌人"},
	"trap_set_1": {"name": "陷阱布置", "level": 1, "max_level": 3, "type": "active", "description": "布置基础陷阱"},
	"trap_set_2": {"name": "陷阱布置", "level": 2, "max_level": 3, "type": "active", "description": "高级陷阱，附带减速效果"},
	"trap_set_3": {"name": "陷阱布置", "level": 3, "max_level": 3, "type": "active", "description": "维度陷阱，将敌人暂时困在裂缝中"},
}

func _ready():
	print("[CharacterClassManager] 初始化完成")

func select_class(class_type: ClassType, player_name: String) -> void:
	_current_class = class_type
	_player_name = player_name
	_class_selected = true
	_apply_class_stats()
	_apply_initial_affinity()
	class_changed.emit(class_type)
	print("[CharacterClassManager] 选择职业: " + get_class_name() + " (" + _player_name + ")")

func _apply_class_stats() -> void:
	if not has_node("/root/GameManager"):
		return
	var gm = get_node("/root/GameManager")
	var class_data = CLASS_DATA[_current_class]
	var base = class_data["base_stats"]
	gm.player_stats["health"] = base["health"]
	gm.player_stats["max_health"] = base["max_health"]
	gm.player_stats["energy"] = base["energy"]
	gm.player_stats["max_energy"] = base["max_energy"]
	gm.player_stats["int"] = base["int"]
	gm.player_stats["per"] = base["per"]
	gm.player_stats["agi"] = base["agi"]
	gm.player_stats["cha"] = base["cha"]
	gm.player_stats["level"] = 1
	gm.player_stats["exp"] = 0
	gm.player_stats["exp_to_next"] = 100
	gm.set_stat("anomaly_sensitivity", 0.0)
	for skill_id in class_data["skills"]:
		gm.unlock_skill(skill_id, SKILL_DATA[skill_id])

func _apply_initial_affinity() -> void:
	var class_data = CLASS_DATA[_current_class]
	if not class_data.has("initial_affinity"):
		return
	if not has_node("/root/APIClient"):
		return
	var api = get_node("/root/APIClient")
	for npc_id in class_data["initial_affinity"]:
		var amount = class_data["initial_affinity"][npc_id]
		if api.has_method("add_affinity"):
			api.add_affinity(npc_id, amount)

func get_current_class() -> ClassType:
	return _current_class

func get_class_data() -> Dictionary:
	return CLASS_DATA.get(_current_class, {})

func get_class_name() -> String:
	return CLASS_DATA.get(_current_class, {}).get("name", "未知")

func get_class_codename() -> String:
	return CLASS_DATA.get(_current_class, {}).get("codename", "???")

func get_class_id() -> String:
	return CLASS_DATA.get(_current_class, {}).get("id", "unknown")

func get_player_name() -> String:
	return _player_name

func is_class_selected() -> bool:
	return _class_selected

func get_all_classes() -> Dictionary:
	return CLASS_DATA

func get_skill_data(skill_id: String) -> Dictionary:
	return SKILL_DATA.get(skill_id, {})

func get_class_skills() -> Array:
	return CLASS_DATA.get(_current_class, {}).get("skills", [])

func get_skill_tree() -> Array:
	var class_id = get_class_id()
	var tree = []
	match class_id:
		"cipher":
			tree = [
				["data_insight_1", "data_insight_2", "data_insight_3"],
				["system_hack_1", "system_hack_2", "system_hack_3"],
				["dimension_map_1", "dimension_map_2", "dimension_map_3"],
			]
		"chrome":
			tree = [
				["cyborg_overload_1", "cyborg_overload_2", "cyborg_overload_3"],
				["shield_gen_1", "shield_gen_2", "shield_gen_3"],
				["melee_mastery_1", "melee_mastery_2", "melee_mastery_3"],
			]
		"echo":
			tree = [
				["dimension_sense_1", "dimension_sense_2", "dimension_sense_3"],
				["psychic_blast_1", "psychic_blast_2", "psychic_blast_3"],
				["precog_dodge_1", "precog_dodge_2", "precog_dodge_3"],
				["soul_link_1", "soul_link_2", "soul_link_3"],
			]
		"shadow":
			tree = [
				["stealth_1", "stealth_2", "stealth_3"],
				["info_network_1", "info_network_2", "info_network_3"],
				["assassinate_1", "assassinate_2", "assassinate_3"],
				["trap_set_1", "trap_set_2", "trap_set_3"],
			]
	return tree

func get_save_data() -> Dictionary:
	return {
		"current_class": _current_class,
		"player_name": _player_name,
		"class_selected": _class_selected,
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("current_class"):
		_current_class = int(data["current_class"])
	if data.has("player_name"):
		_player_name = str(data["player_name"])
	if data.has("class_selected"):
		_class_selected = bool(data["class_selected"])

func get_form_info() -> Dictionary:
	var class_data = CLASS_DATA.get(_current_class, {})
	return {
		"id": class_data.get("id", "player"),
		"form_type": class_data.get("form_type", "form_female"),
		"sprite_scale": class_data.get("sprite_scale", Vector2(1.25, 1.25)),
		"sprite_modulate": class_data.get("sprite_modulate", Color(1, 1, 1, 1)),
		"shader": class_data.get("shader", null),
		"extra_effects": class_data.get("extra_effects", null),
	}

const CLASS_IMAGE_PROMPTS = {
	ClassType.CIPHER: "Cyberpunk female analyst, short silver hair, glowing cyan monocle reflecting digital code, sleek white and teal tech-wear, skin engraved with faint glowing circuitry, background of a high-tech data hub with blue holographic streams, sharp focus, 8k, volumetric lighting, futuristic aesthetic.",
	ClassType.CHROME: "Massive cybernetic male soldier, heavy matte-black armor plating, glowing red mechanical eye, industrial hydraulic arms with visible pistons, rugged facial features with scars, standing in a smoggy orange-lit warehouse (Block 17), grit and metallic texture, hyper-realistic, dramatic low-angle shot.",
	ClassType.ECHO: "Ethereal psionic figure, translucent skin, long flowing hair made of purple energy ripples, eyes glowing with intense violet light, wearing organic cyber-fabric, background is a distorted dimension rift with glitching neon fragments, surreal and dreamlike, soft glowing particles, cinematic digital art.",
	ClassType.SHADOW: "Stealth ninja operative, lean build, full-face matte black tactical mask with a single glowing green sensor strip, obsidian-colored suit that blends into darkness, rainy midnight street background with neon green reflections, cinematic rim lighting, mysterious and lethal vibe, high contrast, sharp details.",
}

static func get_class_image_prompt(class_type: ClassType) -> String:
	return CLASS_IMAGE_PROMPTS.get(class_type, "")
