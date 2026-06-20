extends SceneTree

const EXPECTED_NPCS: Array[String] = [
	"zhang_san",
	"li_si",
	"wang_wu",
	"chen_xi",
	"zhao_lin",
	"sun_yue",
	"liu_feng",
	"he_zhen",
]

const EXPECTED_MODES: Array[String] = ["story", "daily", "affinity", "free"]
const NODE_MODES: Array[String] = ["story", "daily", "affinity", "fallback"]
const EFFECT_KEYS: Array[String] = [
	"affinity",
	"items",
	"currency",
	"exp",
	"anomaly",
	"flags",
	"story_step",
	"quest_interaction",
	"once_per_day",
	"repeatable",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var director = root.get_node_or_null("/root/DialogueDirector")
	if not director:
		errors.append("DialogueDirector autoload missing")
	else:
		_validate_static_dialogue_data(director, errors)
		_validate_runtime_entries(director, errors)
		_validate_story_progression_smoke(director, errors)
	print("====== VERIFY ALL DIALOGUE LOGIC ======")
	if errors.is_empty():
		print("All NPC dialogue logic checks passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _validate_static_dialogue_data(director: Node, errors: Array[String]) -> void:
	var nodes: Dictionary = director.DIALOGUE_NODES
	var gm = root.get_node_or_null("/root/GameManager")
	var story_steps := _collect_story_steps()
	for node_id in nodes.keys():
		var node: Dictionary = nodes[node_id]
		_require_string(node, "id", "NODE_ID_EMPTY", errors)
		_require_string(node, "npc_id", "NODE_NPC_EMPTY:" + str(node_id), errors)
		_require_string(node, "mode", "NODE_MODE_EMPTY:" + str(node_id), errors)
		_require_string(node, "text", "NODE_TEXT_EMPTY:" + str(node_id), errors)
		if str(node.get("id", "")) != str(node_id):
			errors.append("NODE_ID_MISMATCH:" + str(node_id))
		if not str(node.get("npc_id", "")) in EXPECTED_NPCS:
			errors.append("NODE_NPC_UNKNOWN:" + str(node_id) + ":" + str(node.get("npc_id", "")))
		if not str(node.get("mode", "")) in NODE_MODES:
			errors.append("NODE_MODE_UNKNOWN:" + str(node_id) + ":" + str(node.get("mode", "")))
		if not node.has("conditions") or not (node["conditions"] is Dictionary):
			errors.append("NODE_CONDITIONS_INVALID:" + str(node_id))
		if not node.has("effects") or not (node["effects"] is Dictionary):
			errors.append("NODE_EFFECTS_INVALID:" + str(node_id))
		if not node.has("choices") or not (node["choices"] is Array):
			errors.append("NODE_CHOICES_INVALID:" + str(node_id))
			continue
		if node["choices"].is_empty():
			errors.append("NODE_CHOICES_EMPTY:" + str(node_id))
		_validate_conditions(node.get("conditions", {}), gm, str(node_id), errors)
		for choice in node["choices"]:
			if not (choice is Dictionary):
				errors.append("CHOICE_NOT_DICTIONARY:" + str(node_id))
				continue
			_validate_choice(choice, str(node_id), nodes, gm, story_steps, errors)
	_validate_node_orders(director, nodes, errors)

func _validate_runtime_entries(director: Node, errors: Array[String]) -> void:
	for npc_id in EXPECTED_NPCS:
		var modes: Array = director.get_available_modes(npc_id)
		for mode in EXPECTED_MODES:
			if not _mode_list_has(modes, mode):
				errors.append("MODE_MISSING:" + npc_id + ":" + mode)
		for mode in ["story", "daily", "affinity"]:
			var node: Dictionary = director.get_entry_node(npc_id, mode)
			if node.is_empty():
				errors.append("ENTRY_EMPTY:" + npc_id + ":" + mode)
				continue
			if str(node.get("text", "")).strip_edges().is_empty():
				errors.append("ENTRY_TEXT_EMPTY:" + npc_id + ":" + mode)
			if not (str(node.get("npc_id", "")) == npc_id or str(node.get("mode", "")) == "fallback"):
				errors.append("ENTRY_WRONG_NPC:" + npc_id + ":" + mode + ":" + str(node.get("npc_id", "")))
		var fallback := str(director.get_free_chat_fallback(npc_id, "开放自由对话测试"))
		if fallback.strip_edges().is_empty():
			errors.append("FREE_FALLBACK_EMPTY:" + npc_id)

func _validate_story_progression_smoke(director: Node, errors: Array[String]) -> void:
	var he_node: Dictionary = director.get_entry_node("he_zhen", "story")
	if he_node.is_empty():
		errors.append("PROGRESSION_HE_EMPTY")
		return
	var result: Dictionary = director.select_choice("he_zhen", str(he_node.get("id", "")), "ask_voice")
	if result.is_empty():
		errors.append("PROGRESSION_HE_CHOICE_FAILED")
	var zhang_node: Dictionary = director.get_entry_node("zhang_san", "story")
	if zhang_node.is_empty():
		errors.append("PROGRESSION_ZHANG_EMPTY_AFTER_HE")
	elif str(zhang_node.get("id", "")) != "story_zhang_fog_onboarding":
		errors.append("PROGRESSION_ZHANG_UNEXPECTED_INITIAL:" + str(zhang_node.get("id", "")))

func _validate_choice(choice: Dictionary, node_id: String, nodes: Dictionary, gm: Node, story_steps: Dictionary, errors: Array[String]) -> void:
	_require_string(choice, "id", "CHOICE_ID_EMPTY:" + node_id, errors)
	_require_string(choice, "text", "CHOICE_TEXT_EMPTY:" + node_id, errors)
	_require_string(choice, "response", "CHOICE_RESPONSE_EMPTY:" + node_id + ":" + str(choice.get("id", "")), errors)
	if choice.has("next_node"):
		var next_id := str(choice["next_node"])
		if next_id.is_empty() or not nodes.has(next_id):
			errors.append("CHOICE_NEXT_NODE_MISSING:" + node_id + ":" + str(choice.get("id", "")) + ":" + next_id)
	if choice.has("effects"):
		if not (choice["effects"] is Dictionary):
			errors.append("CHOICE_EFFECTS_INVALID:" + node_id + ":" + str(choice.get("id", "")))
		else:
			_validate_effects(choice["effects"], gm, story_steps, node_id + ":" + str(choice.get("id", "")), errors)

func _validate_conditions(conditions: Dictionary, gm: Node, node_id: String, errors: Array[String]) -> void:
	if conditions.has("item"):
		var item_id := str(conditions["item"])
		if not gm or not gm.ITEM_DATABASE.has(item_id):
			errors.append("CONDITION_ITEM_UNKNOWN:" + node_id + ":" + item_id)

func _validate_effects(effects: Dictionary, gm: Node, story_steps: Dictionary, context: String, errors: Array[String]) -> void:
	for key in effects.keys():
		if not str(key) in EFFECT_KEYS:
			errors.append("EFFECT_KEY_UNKNOWN:" + context + ":" + str(key))
	if effects.has("affinity"):
		if not (effects["affinity"] is Dictionary):
			errors.append("EFFECT_AFFINITY_INVALID:" + context)
		else:
			for npc_id in effects["affinity"].keys():
				if not str(npc_id) in EXPECTED_NPCS:
					errors.append("EFFECT_AFFINITY_NPC_UNKNOWN:" + context + ":" + str(npc_id))
	if effects.has("items"):
		if not (effects["items"] is Dictionary):
			errors.append("EFFECT_ITEMS_INVALID:" + context)
		else:
			for item_id in effects["items"].keys():
				if not gm or not gm.ITEM_DATABASE.has(str(item_id)):
					errors.append("EFFECT_ITEM_UNKNOWN:" + context + ":" + str(item_id))
	if effects.has("story_step"):
		var step_id := str(effects["story_step"])
		if not story_steps.has(step_id):
			errors.append("EFFECT_STORY_STEP_UNKNOWN:" + context + ":" + step_id)

func _validate_node_orders(director: Node, nodes: Dictionary, errors: Array[String]) -> void:
	_validate_order_dictionary(director.STORY_NODE_ORDER, nodes, "STORY_ORDER", errors)
	_validate_order_dictionary(director.DAILY_NODE_ORDER, nodes, "DAILY_ORDER", errors)
	_validate_order_dictionary(director.AFFINITY_NODE_ORDER, nodes, "AFFINITY_ORDER", errors)

func _validate_order_dictionary(order: Dictionary, nodes: Dictionary, label: String, errors: Array[String]) -> void:
	for npc_id in EXPECTED_NPCS:
		if not order.has(npc_id):
			errors.append(label + "_NPC_MISSING:" + npc_id)
			continue
		var node_ids: Array = order[npc_id]
		if node_ids.is_empty():
			errors.append(label + "_EMPTY:" + npc_id)
		for node_id in node_ids:
			if not nodes.has(str(node_id)):
				errors.append(label + "_NODE_MISSING:" + npc_id + ":" + str(node_id))

func _collect_story_steps() -> Dictionary:
	var result := {}
	var story = root.get_node_or_null("/root/StoryManager")
	if not story:
		return result
	var chapters: Dictionary = story.get_all_chapters()
	for chapter_id in chapters.keys():
		var chapter: Dictionary = chapters[chapter_id]
		for step in chapter.get("story_steps", []):
			if step is Dictionary and step.has("id"):
				result[str(step["id"])] = true
	return result

func _mode_list_has(modes: Array, mode_id: String) -> bool:
	for mode in modes:
		if mode is Dictionary and str(mode.get("id", "")) == mode_id:
			return true
	return false

func _require_string(source: Dictionary, key: String, message: String, errors: Array[String]) -> void:
	if not source.has(key) or str(source[key]).strip_edges().is_empty():
		errors.append(message)

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
