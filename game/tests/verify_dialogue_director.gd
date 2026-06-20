extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var director = root.get_node_or_null("/root/DialogueDirector")
	if not director:
		errors.append("DialogueDirector autoload missing")
	else:
		_verify_director_flow(director, errors)
	_verify_quest_rewards(errors)
	_verify_api_fallback(errors)
	print("====== VERIFY DIALOGUE DIRECTOR ======")
	if errors.is_empty():
		print("Dialogue director checks passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _verify_director_flow(director: Node, errors: Array[String]) -> void:
	var node: Dictionary = director.get_entry_node("zhang_san", "story")
	if node.is_empty():
		errors.append("STORY_NODE_EMPTY")
		return
	if str(node.get("id", "")) != "story_zhang_fog_onboarding":
		errors.append("STORY_NODE_UNEXPECTED: " + str(node.get("id", "")))
	var choices: Array = node.get("choices", [])
	if choices.is_empty():
		errors.append("STORY_CHOICES_EMPTY")
		return
	var result: Dictionary = director.select_choice("zhang_san", str(node["id"]), "inspect_log")
	if result.is_empty():
		errors.append("CHOICE_RESULT_EMPTY")
		return
	if str(result.get("npc_text", "")).is_empty():
		errors.append("CHOICE_REPLY_EMPTY")
	var rewards: Array = result.get("rewards", [])
	if rewards.is_empty():
		errors.append("CHOICE_REWARDS_EMPTY")
	var gm = root.get_node_or_null("/root/GameManager")
	if not gm or not gm.has_item("rainport_access_chip"):
		errors.append("CHOICE_ITEM_NOT_GRANTED")
	var next_node: Dictionary = result.get("next_node", {})
	if next_node.is_empty() or str(next_node.get("id", "")) != "side_zhang_blue_breakpoint":
		errors.append("CHOICE_NEXT_NODE_INVALID")

func _verify_quest_rewards(errors: Array[String]) -> void:
	var qm = root.get_node_or_null("/root/QuestManager")
	var gm = root.get_node_or_null("/root/GameManager")
	if not qm or not gm:
		errors.append("QUEST_OR_GAME_MANAGER_MISSING")
		return
	var currency_before := int(gm.currency)
	var summaries: Array = qm.apply_reward_payload({
		"items": {"mirror_page": 1},
		"currency": 7,
		"flags": {"verify_dialogue_reward": true},
	})
	if summaries.is_empty():
		errors.append("QUEST_REWARD_SUMMARY_EMPTY")
	if not gm.has_item("mirror_page"):
		errors.append("QUEST_ITEM_NOT_GRANTED")
	if int(gm.currency) != currency_before + 7:
		errors.append("QUEST_CURRENCY_NOT_GRANTED")
	if not gm.get_flag("verify_dialogue_reward", false):
		errors.append("QUEST_FLAG_NOT_SET")

func _verify_api_fallback(errors: Array[String]) -> void:
	var api = root.get_node_or_null("/root/APIClient")
	if not api:
		errors.append("API_CLIENT_MISSING")
		return
	var reply := str(api._generate_local_chat_reply("he_zhen", "任务和线索"))
	if reply.is_empty():
		errors.append("API_FALLBACK_EMPTY")
	if reply.find("剧情") == -1 and reply.find("本地") == -1 and reply.find("线索") == -1:
		errors.append("API_FALLBACK_WEAK: " + reply)

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
