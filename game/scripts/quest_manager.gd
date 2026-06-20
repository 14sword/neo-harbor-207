extends Node

enum QuestStatus { LOCKED, AVAILABLE, ACTIVE, COMPLETED }
enum QuestType { DIALOGUE, EXPLORATION, COLLECTION, DAILY, HIDDEN, STORY }

var _quests: Dictionary = {}
var _dialogue_counts: Dictionary = {}
var _interaction_counts: Dictionary = {}
var _daily_dialogue_counts: Dictionary = {}
var _daily_interaction_counts: Dictionary = {}
var _tracked_quest_id: String = ""
var _recommendations: Dictionary = {}

signal quest_updated(quest_id: String, status: int)
signal quest_completed(quest_id: String)
signal new_quest_available(quest_id: String)
signal quest_accepted(quest_id: String)
signal quest_tracked_changed(quest_id: String)
signal quest_progressed(quest_id: String, progress: int, target: int)
signal daily_quests_reset()
signal quest_recommendations_changed()

func _ready():
	_init_quests()
	_apply_default_quest_metadata()
	_connect_world_signals()
	call_deferred("refresh_contextual_recommendations")

func _init_quests():
	_quests = {
		"first_chat": {
			"id": "first_chat",
			"title": "初来乍到",
			"description": "与任意一位NPC进行第一次对话",
			"type": QuestType.DIALOGUE,
			"npc_id": "",
			"status": QuestStatus.AVAILABLE,
			"requirement": {"type": "any_chat", "count": 1},
			"progress": 0,
			"reward_text": "解锁更多对话选项",
			"rewards": {},
		},
		"chat_zhang_3": {
			"id": "chat_zhang_3",
			"title": "技术交流",
			"description": "与张三对话3次，了解Python工程师的工作",
			"type": QuestType.DIALOGUE,
			"npc_id": "zhang_san",
			"status": QuestStatus.LOCKED,
			"requirement": {"type": "chat", "npc_id": "zhang_san", "count": 3},
			"progress": 0,
			"unlock_condition": {"type": "quest_complete", "quest_id": "first_chat"},
			"reward_text": "张三好感度+5",
			"rewards": {"affinity": {"zhang_san": 5}},
		},
		"chat_li_3": {
			"id": "chat_li_3",
			"title": "产品思维",
			"description": "与李四对话3次，了解产品经理的思考方式",
			"type": QuestType.DIALOGUE,
			"npc_id": "li_si",
			"status": QuestStatus.LOCKED,
			"requirement": {"type": "chat", "npc_id": "li_si", "count": 3},
			"progress": 0,
			"unlock_condition": {"type": "quest_complete", "quest_id": "first_chat"},
			"reward_text": "李四好感度+5",
			"rewards": {"affinity": {"li_si": 5}},
		},
		"chat_wang_3": {
			"id": "chat_wang_3",
			"title": "设计灵感",
			"description": "与王五对话3次，了解UI设计师的创意世界",
			"type": QuestType.DIALOGUE,
			"npc_id": "wang_wu",
			"status": QuestStatus.LOCKED,
			"requirement": {"type": "chat", "npc_id": "wang_wu", "count": 3},
			"progress": 0,
			"unlock_condition": {"type": "quest_complete", "quest_id": "first_chat"},
			"reward_text": "王五好感度+5",
			"rewards": {"affinity": {"wang_wu": 5}},
		},
		"explore_balcony": {
			"id": "explore_balcony",
			"title": "城市观察者",
			"description": "在阳台观景3次，感受新港·207的脉搏",
			"type": QuestType.EXPLORATION,
			"npc_id": "",
			"status": QuestStatus.AVAILABLE,
			"requirement": {"type": "interaction", "interaction_type": "balcony", "count": 3},
			"progress": 0,
			"reward_text": "解锁阳台隐藏描述",
			"rewards": {},
		},
		"explore_forum": {
			"id": "explore_forum",
			"title": "网络冲浪",
			"description": "使用电脑论坛5次，了解小镇的网络世界",
			"type": QuestType.EXPLORATION,
			"npc_id": "",
			"status": QuestStatus.AVAILABLE,
			"requirement": {"type": "interaction", "interaction_type": "forum", "count": 5},
			"progress": 0,
			"reward_text": "解锁论坛隐藏板块",
			"rewards": {},
		},
		"explore_tv": {
			"id": "explore_tv",
			"title": "资讯猎手",
			"description": "观看电视新闻3次，掌握小镇动态",
			"type": QuestType.EXPLORATION,
			"npc_id": "",
			"status": QuestStatus.AVAILABLE,
			"requirement": {"type": "interaction", "interaction_type": "tv", "count": 3},
			"progress": 0,
			"reward_text": "解锁深夜频道",
			"rewards": {},
		},
		"explore_talisman": {
			"id": "explore_talisman",
			"title": "符咒研究者",
			"description": "查看护符2次，探索神秘力量",
			"type": QuestType.EXPLORATION,
			"npc_id": "",
			"status": QuestStatus.AVAILABLE,
			"requirement": {"type": "interaction", "interaction_type": "talisman", "count": 2},
			"progress": 0,
			"reward_text": "解锁护符隐藏信息",
			"rewards": {},
		},
		"water_plant": {
			"id": "water_plant",
			"title": "园艺新手",
			"description": "给植物浇水3次，保持它的健康生长",
			"type": QuestType.COLLECTION,
			"npc_id": "",
			"status": QuestStatus.AVAILABLE,
			"requirement": {"type": "interaction", "interaction_type": "water_plant", "count": 3},
			"progress": 0,
			"reward_text": "张三好感度+5，解锁植物生长状态",
			"rewards": {"affinity": {"zhang_san": 5}},
		},
		"check_fridge": {
			"id": "check_fridge",
			"title": "冰箱巡检",
			"description": "查看冰箱5次，确保食物储备充足",
			"type": QuestType.COLLECTION,
			"npc_id": "",
			"status": QuestStatus.AVAILABLE,
			"requirement": {"type": "interaction", "interaction_type": "fridge", "count": 5},
			"progress": 0,
			"reward_text": "李四好感度+3",
			"rewards": {"affinity": {"li_si": 3}},
		},
		"sleep_well": {
			"id": "sleep_well",
			"title": "规律作息",
			"description": "睡觉5次，保持良好的生活节奏",
			"type": QuestType.COLLECTION,
			"npc_id": "",
			"status": QuestStatus.AVAILABLE,
			"requirement": {"type": "interaction", "interaction_type": "sleep", "count": 5},
			"progress": 0,
			"reward_text": "王五好感度+3",
			"rewards": {"affinity": {"wang_wu": 3}},
		},
		"daily_chat": {
			"id": "daily_chat",
			"title": "每日社交",
			"description": "每天与NPC对话1次",
			"type": QuestType.DAILY,
			"npc_id": "",
			"status": QuestStatus.AVAILABLE,
			"requirement": {"type": "any_chat", "count": 1},
			"progress": 0,
			"reward_text": "随机NPC好感度+2",
			"rewards": {},
			"daily": true,
		},
		"daily_explore": {
			"id": "daily_explore",
			"title": "每日探索",
			"description": "每天使用2个不同交互点",
			"type": QuestType.DAILY,
			"npc_id": "",
			"status": QuestStatus.AVAILABLE,
			"requirement": {"type": "unique_interactions", "count": 2},
			"progress": 0,
			"reward_text": "全NPC好感度+1",
			"rewards": {},
			"daily": true,
		},
		"midnight_anomaly": {
			"id": "midnight_anomaly",
			"title": "深夜异象",
			"description": "在深夜触发3次异常事件",
			"type": QuestType.HIDDEN,
			"npc_id": "",
			"status": QuestStatus.LOCKED,
			"requirement": {"type": "interaction", "interaction_type": "night_event", "count": 3},
			"progress": 0,
			"unlock_condition": {"type": "phase", "phase": "night"},
			"reward_text": "解锁隐藏剧情线索",
			"rewards": {},
		},
		"social_butterfly": {
			"id": "social_butterfly",
			"title": "社交达人",
			"description": "与所有NPC各对话5次",
			"type": QuestType.HIDDEN,
			"npc_id": "",
			"status": QuestStatus.LOCKED,
			"requirement": {"type": "all_chat", "count": 5},
			"progress": 0,
			"unlock_condition": {"type": "quests_complete", "quest_ids": ["chat_zhang_3", "chat_li_3", "chat_wang_3"]},
			"reward_text": "解锁隐藏对话，全NPC好感度+10",
			"rewards": {"affinity": {"zhang_san": 10, "li_si": 10, "wang_wu": 10}},
		},
		"story_ch1_meet_team": {
			"id": "story_ch1_meet_team",
			"title": "认识团队",
			"description": "与办公室的三位同事各对话1次，了解DATAWHALE公司",
			"type": QuestType.STORY,
			"npc_id": "",
			"status": QuestStatus.AVAILABLE,
			"requirement": {"type": "all_chat", "count": 1},
			"progress": 0,
			"reward_text": "经验值+50，解锁街区探索",
			"rewards": {"exp": 50},
		},
		"story_ch1_explore_street": {
			"id": "story_ch1_explore_street",
			"title": "走出办公室",
			"description": "前往街区，感受新港·207的氛围",
			"type": QuestType.STORY,
			"npc_id": "",
			"status": QuestStatus.LOCKED,
			"requirement": {"type": "interaction", "interaction_type": "visit_street", "count": 1},
			"progress": 0,
			"unlock_condition": {"type": "quest_complete", "quest_id": "story_ch1_meet_team"},
			"reward_text": "经验值+30，发现新区域",
			"rewards": {"exp": 30},
		},
		"story_ch1_mystery_hint": {
			"id": "story_ch1_mystery_hint",
			"title": "异常的暗示",
			"description": "在公寓中查看符纸和阳台，留意任何不寻常的迹象",
			"type": QuestType.STORY,
			"npc_id": "",
			"status": QuestStatus.LOCKED,
			"requirement": {"type": "unique_interactions", "count": 2},
			"progress": 0,
			"unlock_condition": {"type": "quest_complete", "quest_id": "story_ch1_explore_street"},
			"reward_text": "异常感知+5，经验值+80",
			"rewards": {"exp": 80, "anomaly": 5},
		},
		"story_ch1_coffee_shop": {
			"id": "story_ch1_coffee_shop",
			"title": "量子咖啡",
			"description": "在街区找到陈曦的咖啡店，与她交谈",
			"type": QuestType.STORY,
			"npc_id": "chen_xi",
			"status": QuestStatus.LOCKED,
			"requirement": {"type": "chat", "npc_id": "chen_xi", "count": 1},
			"progress": 0,
			"unlock_condition": {"type": "quest_complete", "quest_id": "story_ch1_mystery_hint"},
			"reward_text": "陈曦好感度+5，经验值+100",
			"rewards": {"affinity": {"chen_xi": 5}, "exp": 100},
		},
		"story_ch1_first_anomaly": {
			"id": "story_ch1_first_anomaly",
			"title": "第一次异常",
			"description": "深夜查看符纸，触发第一次异常事件",
			"type": QuestType.STORY,
			"npc_id": "",
			"status": QuestStatus.LOCKED,
			"requirement": {"type": "interaction", "interaction_type": "night_event", "count": 1},
			"progress": 0,
			"unlock_condition": {"type": "quest_complete", "quest_id": "story_ch1_coffee_shop"},
			"reward_text": "异常感知+10，解锁Ch2，经验值+200",
			"rewards": {"exp": 200, "anomaly": 10},
		},
	}

func _connect_world_signals() -> void:
	if has_node("/root/WorldCalendar"):
		var cal = get_node("/root/WorldCalendar")
		if not cal.day_advanced.is_connected(_on_day_advanced):
			cal.day_advanced.connect(_on_day_advanced)
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if dnm.has_signal("phase_changed") and not dnm.phase_changed.is_connected(_on_phase_changed):
			dnm.phase_changed.connect(_on_phase_changed)

func _apply_default_quest_metadata() -> void:
	for quest_id in _quests:
		var quest: Dictionary = _quests[quest_id]
		quest["priority"] = int(quest.get("priority", _default_priority_for_quest(quest)))
		quest["target_hint"] = str(quest.get("target_hint", _default_target_hint_for_quest(quest)))
		quest["target_area"] = str(quest.get("target_area", _default_target_area_for_quest(quest)))
		quest["target_action"] = str(quest.get("target_action", _default_target_action_for_quest(quest)))
		quest["completed_day"] = int(quest.get("completed_day", 0))
		quest["recommended_reason"] = str(quest.get("recommended_reason", ""))

func _default_priority_for_quest(quest: Dictionary) -> int:
	match int(quest.get("type", QuestType.DIALOGUE)):
		QuestType.STORY:
			return 10
		QuestType.HIDDEN:
			return 25
		QuestType.DAILY:
			return 60
		_:
			return 40

func _default_target_hint_for_quest(quest: Dictionary) -> String:
	var req: Dictionary = quest.get("requirement", {})
	match str(req.get("type", "")):
		"any_chat":
			return "找任意 NPC 对话"
		"chat":
			return "找" + _npc_display_name(str(req.get("npc_id", quest.get("npc_id", "")))) + "对话"
		"all_chat":
			return "依次拜访主要 NPC"
		"interaction":
			return _interaction_display_hint(str(req.get("interaction_type", "")))
		"unique_interactions":
			return "探索不同交互点"
	return "继续探索新港"

func _default_target_area_for_quest(quest: Dictionary) -> String:
	var req: Dictionary = quest.get("requirement", {})
	match str(req.get("type", "")):
		"chat":
			return _npc_area(str(req.get("npc_id", quest.get("npc_id", ""))))
		"interaction":
			return _interaction_area(str(req.get("interaction_type", "")))
		"unique_interactions":
			if str(quest.get("id", "")).begins_with("story_ch1_mystery_hint"):
				return "apartment"
	return ""

func _default_target_action_for_quest(quest: Dictionary) -> String:
	var area := _default_target_area_for_quest(quest)
	if area.is_empty():
		return ""
	return "前往" + _area_display_name(area)

func _npc_display_name(npc_id: String) -> String:
	match npc_id:
		"zhang_san":
			return "张三"
		"li_si":
			return "李四"
		"wang_wu":
			return "王五"
		"chen_xi":
			return "陈曦"
		"zhao_lin":
			return "赵霖"
		"sun_yue":
			return "孙悦"
		"liu_feng":
			return "刘风"
		"he_zhen":
			return "何真"
		_:
			return "NPC"

func _npc_area(npc_id: String) -> String:
	match npc_id:
		"zhang_san", "li_si", "wang_wu":
			return "office"
		"chen_xi", "zhao_lin", "sun_yue", "liu_feng", "he_zhen":
			return "street"
		_:
			return ""

func _interaction_area(interaction_type: String) -> String:
	match interaction_type:
		"balcony", "tv", "talisman", "water_plant", "fridge", "sleep", "night_event":
			return "apartment"
		"forum":
			return "office"
		"visit_street":
			return "street"
		_:
			return ""

func _interaction_display_hint(interaction_type: String) -> String:
	match interaction_type:
		"balcony":
			return "去公寓阳台"
		"tv":
			return "查看公寓电视"
		"talisman":
			return "查看公寓符纸"
		"water_plant":
			return "给公寓植物浇水"
		"fridge":
			return "检查公寓冰箱"
		"sleep":
			return "回公寓睡觉"
		"night_event":
			return "深夜查看异常迹象"
		"forum":
			return "使用办公室电脑论坛"
		"visit_street":
			return "前往街区"
		_:
			return "探索交互点"

func _area_display_name(area_id: String) -> String:
	match area_id:
		"office":
			return "办公室"
		"street":
			return "街区"
		"apartment":
			return "公寓"
		"underground":
			return "地下站台"
		"anomaly":
			return "异常空间"
		_:
			return "目标区域"

func on_dialogue_with_npc(npc_id: String) -> void:
	if not _dialogue_counts.has(npc_id):
		_dialogue_counts[npc_id] = 0
	_dialogue_counts[npc_id] += 1
	if not _daily_dialogue_counts.has(npc_id):
		_daily_dialogue_counts[npc_id] = 0
	_daily_dialogue_counts[npc_id] += 1
	_check_all_quests()

func on_interaction(interaction_type: String) -> void:
	if not _interaction_counts.has(interaction_type):
		_interaction_counts[interaction_type] = 0
	_interaction_counts[interaction_type] += 1
	if not _daily_interaction_counts.has(interaction_type):
		_daily_interaction_counts[interaction_type] = 0
	_daily_interaction_counts[interaction_type] += 1
	_check_all_quests()

func accept_quest(quest_id: String) -> bool:
	if not _quests.has(quest_id):
		return false
	var quest = _quests[quest_id]
	if quest["status"] != QuestStatus.AVAILABLE:
		return false
	quest["status"] = QuestStatus.ACTIVE
	quest_accepted.emit(quest_id)
	_log_event("📋 接受任务: " + quest["title"])
	_check_all_quests()
	return true

func _check_all_quests() -> void:
	for quest_id in _quests:
		var quest = _quests[quest_id]

		if quest["status"] == QuestStatus.LOCKED:
			if _check_unlock_condition(quest):
				quest["status"] = QuestStatus.AVAILABLE
				new_quest_available.emit(quest_id)
				_log_event("📋 新任务可用: " + quest["title"])
				refresh_contextual_recommendations()

		if quest["status"] == QuestStatus.ACTIVE:
			var new_progress = _calculate_progress(quest)
			if new_progress != quest["progress"]:
				quest["progress"] = new_progress
				quest_updated.emit(quest_id, quest["status"])
				quest_progressed.emit(quest_id, new_progress, int(quest.get("requirement", {}).get("count", 1)))

			if _check_completion(quest):
				quest["status"] = QuestStatus.COMPLETED
				quest["completed_day"] = _get_current_day()
				quest_completed.emit(quest_id)
				_log_event("🎉 任务完成: " + quest["title"])
				_on_quest_reward(quest)
				refresh_contextual_recommendations()

func _check_unlock_condition(quest: Dictionary) -> bool:
	if not quest.has("unlock_condition"):
		return true
	var cond = quest["unlock_condition"]
	match cond["type"]:
		"quest_complete":
			var required_id = cond["quest_id"]
			return _quests.has(required_id) and _quests[required_id]["status"] == QuestStatus.COMPLETED
		"quests_complete":
			for required_id in cond["quest_ids"]:
				if not _quests.has(required_id) or _quests[required_id]["status"] != QuestStatus.COMPLETED:
					return false
			return true
		"phase":
			if has_node("/root/DayNightManager"):
				var dnm = get_node("/root/DayNightManager")
				match cond["phase"]:
					"night":
						return dnm.current_phase == dnm.DayPhase.NIGHT or dnm.current_phase == dnm.DayPhase.RAIN_NIGHT
					"day":
						return dnm.current_phase == dnm.DayPhase.DAY
			return false
	return false

func _calculate_progress(quest: Dictionary) -> int:
	var req = quest["requirement"]
	var target_count = req.get("count", 1)
	var dialogue_counts := _daily_dialogue_counts if quest.get("daily", false) else _dialogue_counts
	var interaction_counts := _daily_interaction_counts if quest.get("daily", false) else _interaction_counts
	match req["type"]:
		"any_chat":
			var total = 0
			for npc_id in dialogue_counts:
				total += dialogue_counts[npc_id]
			return mini(total, target_count)
		"chat":
			var npc_id = req.get("npc_id", "")
			return mini(dialogue_counts.get(npc_id, 0), target_count)
		"all_chat":
			var min_count = 999
			for npc_id in ["zhang_san", "li_si", "wang_wu", "chen_xi", "zhao_lin", "sun_yue", "liu_feng", "he_zhen"]:
				min_count = mini(min_count, dialogue_counts.get(npc_id, 0))
			return mini(min_count, target_count)
		"interaction":
			var itype = req.get("interaction_type", "")
			return mini(interaction_counts.get(itype, 0), target_count)
		"unique_interactions":
			return mini(interaction_counts.size(), target_count)
	return 0

func _check_completion(quest: Dictionary) -> bool:
	var req = quest["requirement"]
	var target_count = req.get("count", 1)
	return _calculate_progress(quest) >= target_count

func apply_reward_payload(rewards: Dictionary, _source_npc_id: String = "") -> Array:
	var summaries: Array = []
	if rewards.has("affinity"):
		var affinity_rewards = rewards["affinity"]
		for npc_id in affinity_rewards:
			if has_node("/root/APIClient"):
				var amount := int(affinity_rewards[npc_id])
				get_node("/root/APIClient").add_affinity(npc_id, amount)
				summaries.append("好感度+" + str(amount))
	if rewards.has("exp"):
		var exp_reward = rewards["exp"]
		if has_node("/root/GameManager"):
			get_node("/root/GameManager").gain_exp(float(exp_reward))
			summaries.append("经验+" + str(int(exp_reward)))
	if rewards.has("anomaly"):
		var anomaly_reward = rewards["anomaly"]
		if has_node("/root/GameManager"):
			get_node("/root/GameManager").increase_anomaly(float(anomaly_reward))
			summaries.append("异常感知+" + str(int(anomaly_reward)))
	if rewards.has("items"):
		var item_rewards: Dictionary = rewards["items"]
		if has_node("/root/GameManager"):
			var gm = get_node("/root/GameManager")
			for item_id in item_rewards:
				var amount := int(item_rewards[item_id])
				gm.add_item(str(item_id), amount)
				var db: Dictionary = gm.ITEM_DATABASE.get(str(item_id), {})
				summaries.append(db.get("name", str(item_id)) + "x" + str(amount))
	if rewards.has("currency") and has_node("/root/GameManager"):
		var currency_reward := int(rewards["currency"])
		get_node("/root/GameManager").add_currency(currency_reward)
		summaries.append("信用点+" + str(currency_reward))
	if rewards.has("flags"):
		var flags: Dictionary = rewards["flags"]
		for flag_name in flags:
			if has_node("/root/GameManager"):
				get_node("/root/GameManager").set_flag(str(flag_name), flags[flag_name])
			if has_node("/root/StoryManager"):
				get_node("/root/StoryManager").set_story_flag(str(flag_name), flags[flag_name])
	if rewards.has("story_step") and has_node("/root/StoryManager"):
		get_node("/root/StoryManager").complete_step(str(rewards["story_step"]))
	return summaries

func _on_quest_reward(quest: Dictionary) -> void:
	var summaries := apply_reward_payload(quest.get("rewards", {}), str(quest.get("npc_id", "")))
	if not summaries.is_empty():
		_log_event("🎁 任务奖励: " + "，".join(summaries))

func reset_daily_quests() -> void:
	_daily_dialogue_counts.clear()
	_daily_interaction_counts.clear()
	for quest_id in _quests:
		var quest = _quests[quest_id]
		if quest.get("daily", false):
			quest["status"] = QuestStatus.AVAILABLE
			quest["progress"] = 0
			quest_updated.emit(quest_id, quest["status"])
	daily_quests_reset.emit()
	_log_event("📅 每日任务已刷新")
	refresh_contextual_recommendations()

func track_quest(quest_id: String) -> bool:
	if not _quests.has(quest_id):
		return false
	var quest: Dictionary = _quests[quest_id]
	if int(quest.get("status", QuestStatus.LOCKED)) == QuestStatus.LOCKED:
		return false
	_tracked_quest_id = quest_id
	quest_tracked_changed.emit(_tracked_quest_id)
	return true

func untrack_quest() -> void:
	_tracked_quest_id = ""
	quest_tracked_changed.emit(_tracked_quest_id)

func get_tracked_quest_display_data() -> Dictionary:
	if _tracked_quest_id.is_empty() or not _quests.has(_tracked_quest_id):
		return {}
	return _make_quest_view_entry(_tracked_quest_id, _quests[_tracked_quest_id])

func get_quest_view_data(filter: String = "all", include_completed: bool = false) -> Array:
	var normalized_filter := _normalize_quest_filter(filter)
	var result: Array = []
	for quest_id in _quests:
		var quest: Dictionary = _quests[quest_id]
		var status := int(quest.get("status", QuestStatus.LOCKED))
		if status == QuestStatus.LOCKED:
			continue
		if normalized_filter == "completed":
			if status != QuestStatus.COMPLETED:
				continue
		elif status == QuestStatus.COMPLETED and not include_completed:
			continue
		if normalized_filter != "all" and normalized_filter != "completed":
			if _type_to_key(int(quest.get("type", QuestType.DIALOGUE))) != normalized_filter:
				continue
		result.append(_make_quest_view_entry(quest_id, quest))
	result.sort_custom(_sort_quest_entries)
	return result

func get_completed_archive_data() -> Array:
	var result: Array = []
	for quest_id in _quests:
		var quest: Dictionary = _quests[quest_id]
		if int(quest.get("status", QuestStatus.LOCKED)) == QuestStatus.COMPLETED:
			result.append(_make_quest_view_entry(quest_id, quest))
	result.sort_custom(_sort_completed_quest_entries)
	return result

func transition_to_quest_target(quest_id: String = "") -> bool:
	var target_id := quest_id if not quest_id.is_empty() else _tracked_quest_id
	if target_id.is_empty() or not _quests.has(target_id):
		return false
	var area_id := str(_quests[target_id].get("target_area", ""))
	if area_id.is_empty():
		return false
	var gm = get_node_or_null("/root/GameManager")
	if gm and not area_id in gm.discovered_areas:
		return false
	var sm = get_node_or_null("/root/SceneManager")
	if sm and sm.has_method("transition_to_area"):
		return sm.transition_to_area(area_id)
	return false

func get_active_quests() -> Array:
	var result = []
	for quest_id in _quests:
		var quest = _quests[quest_id]
		if quest["status"] == QuestStatus.ACTIVE or quest["status"] == QuestStatus.AVAILABLE:
			result.append(quest.duplicate())
	return result

func get_completed_quests() -> Array:
	var result = []
	for quest_id in _quests:
		if _quests[quest_id]["status"] == QuestStatus.COMPLETED:
			result.append(_quests[quest_id].duplicate())
	return result

func get_all_quests() -> Array:
	var result = []
	for quest_id in _quests:
		result.append(_quests[quest_id].duplicate())
	return result

func get_quest_display_data() -> Array:
	return get_quest_view_data("all", true)

func refresh_contextual_recommendations() -> void:
	_recommendations.clear()
	var context := _get_world_recommendation_context()
	for quest_id in _quests:
		var quest: Dictionary = _quests[quest_id]
		if int(quest.get("status", QuestStatus.LOCKED)) == QuestStatus.LOCKED:
			quest["recommended_reason"] = ""
			continue
		if int(quest.get("status", QuestStatus.LOCKED)) == QuestStatus.COMPLETED:
			quest["recommended_reason"] = ""
			continue
		var reason := _build_recommendation_reason(quest, context)
		quest["recommended_reason"] = reason
		if not reason.is_empty():
			_recommendations[quest_id] = reason
	quest_recommendations_changed.emit()

func _make_quest_view_entry(quest_id: String, quest: Dictionary) -> Dictionary:
	var req: Dictionary = quest.get("requirement", {})
	var target := int(req.get("count", 1))
	var progress := int(quest.get("progress", 0))
	var qtype := int(quest.get("type", QuestType.DIALOGUE))
	var status := int(quest.get("status", QuestStatus.LOCKED))
	var type_key := _type_to_key(qtype)
	return {
		"id": quest_id,
		"title": str(quest.get("title", quest_id)),
		"description": str(quest.get("description", "")),
		"progress_value": progress,
		"progress_target": target,
		"progress": str(progress) + "/" + str(target),
		"progress_ratio": clampf(float(progress) / float(maxi(target, 1)), 0.0, 1.0),
		"status": _status_to_text(status),
		"status_value": status,
		"reward": str(quest.get("reward_text", "")),
		"rewards": quest.get("rewards", {}).duplicate(true),
		"type": _type_to_text(qtype),
		"type_key": type_key,
		"target_hint": str(quest.get("target_hint", "")),
		"target_area": str(quest.get("target_area", "")),
		"target_action": str(quest.get("target_action", "")),
		"tracked": quest_id == _tracked_quest_id,
		"priority": int(quest.get("priority", 50)),
		"completed_day": int(quest.get("completed_day", 0)),
		"recommended_reason": str(quest.get("recommended_reason", "")),
		"daily": bool(quest.get("daily", false)),
	}

func _normalize_quest_filter(filter: String) -> String:
	match filter:
		"", "all", "全部":
			return "all"
		"dialogue", "对话":
			return "dialogue"
		"exploration", "探索":
			return "exploration"
		"collection", "收集":
			return "collection"
		"daily", "日常":
			return "daily"
		"hidden", "隐藏":
			return "hidden"
		"story", "剧情":
			return "story"
		"completed", "已完成", "归档":
			return "completed"
		_:
			return filter

func _sort_quest_entries(a: Dictionary, b: Dictionary) -> bool:
	var tracked_delta := _tracked_rank(a) - _tracked_rank(b)
	if tracked_delta != 0:
		return tracked_delta < 0
	var type_delta := _quest_type_rank(a) - _quest_type_rank(b)
	if type_delta != 0:
		return type_delta < 0
	var status_delta := _quest_status_rank(a) - _quest_status_rank(b)
	if status_delta != 0:
		return status_delta < 0
	var priority_delta := int(a.get("priority", 50)) - int(b.get("priority", 50))
	if priority_delta != 0:
		return priority_delta < 0
	return str(a.get("id", "")) < str(b.get("id", ""))

func _sort_completed_quest_entries(a: Dictionary, b: Dictionary) -> bool:
	var day_delta := int(b.get("completed_day", 0)) - int(a.get("completed_day", 0))
	if day_delta != 0:
		return day_delta < 0
	return str(a.get("id", "")) < str(b.get("id", ""))

func _tracked_rank(entry: Dictionary) -> int:
	return 0 if bool(entry.get("tracked", false)) else 1

func _quest_type_rank(entry: Dictionary) -> int:
	match str(entry.get("type_key", "")):
		"story":
			return 0
		"hidden":
			return 1
		_:
			return 2

func _quest_status_rank(entry: Dictionary) -> int:
	match int(entry.get("status_value", QuestStatus.LOCKED)):
		QuestStatus.ACTIVE:
			return 0
		QuestStatus.AVAILABLE:
			return 1
		QuestStatus.COMPLETED:
			return 2
		_:
			return 9

func _type_to_key(qtype: int) -> String:
	match qtype:
		QuestType.DIALOGUE:
			return "dialogue"
		QuestType.EXPLORATION:
			return "exploration"
		QuestType.COLLECTION:
			return "collection"
		QuestType.DAILY:
			return "daily"
		QuestType.HIDDEN:
			return "hidden"
		QuestType.STORY:
			return "story"
		_:
			return "other"

func _get_world_recommendation_context() -> Dictionary:
	var context := {
		"month_id": "",
		"weather_id": "",
		"weather_name": "",
		"anomaly_level": 0.0,
		"phase": "",
	}
	var cal = get_node_or_null("/root/WorldCalendar")
	if cal and cal.has_method("get_calendar_context"):
		var cal_context: Dictionary = cal.get_calendar_context()
		context["month_id"] = str(cal_context.get("month_id", ""))
	var dwg = get_node_or_null("/root/DailyWorldGenerator")
	if dwg:
		if dwg.has_method("get_daily_weather"):
			var weather: Dictionary = dwg.get_daily_weather()
			context["weather_id"] = str(weather.get("id", ""))
			context["weather_name"] = str(weather.get("name", ""))
		if dwg.has_method("get_daily_anomaly_level"):
			context["anomaly_level"] = float(dwg.get_daily_anomaly_level())
	var dnm = get_node_or_null("/root/DayNightManager")
	if dnm:
		context["phase"] = str(dnm.current_phase)
	return context

func _build_recommendation_reason(quest: Dictionary, context: Dictionary) -> String:
	var qtype := int(quest.get("type", QuestType.DIALOGUE))
	var target_area := str(quest.get("target_area", ""))
	var target_hint := str(quest.get("target_hint", ""))
	var month_id := str(context.get("month_id", ""))
	var weather_id := str(context.get("weather_id", ""))
	var anomaly_level := float(context.get("anomaly_level", 0.0))
	var is_rain_context := month_id == "rain" or weather_id in ["rain", "thunderstorm"]
	var is_ghost_context := month_id == "ghost" or anomaly_level >= 0.48
	if qtype == QuestType.DAILY and is_rain_context:
		return "雨夜动态推荐"
	if qtype == QuestType.HIDDEN and is_ghost_context:
		return "幽月异常推荐"
	if qtype == QuestType.STORY and is_ghost_context:
		return "DATAWHALE 观测推荐"
	if target_area == "apartment" and target_hint.find("阳台") != -1 and is_rain_context:
		return "雨夜适合观察阳台"
	if target_hint.find("符纸") != -1 and is_ghost_context:
		return "异常信号升高"
	return ""

func _on_day_advanced(_new_day: int) -> void:
	reset_daily_quests()

func _on_phase_changed(_new_phase) -> void:
	_check_all_quests()
	refresh_contextual_recommendations()

func _get_current_day() -> int:
	if has_node("/root/WorldCalendar"):
		return int(get_node("/root/WorldCalendar").current_day)
	return 0

func _status_to_text(status: int) -> String:
	match status:
		QuestStatus.AVAILABLE: return "可接取"
		QuestStatus.ACTIVE: return "进行中"
		QuestStatus.COMPLETED: return "已完成"
		_: return "未知"

func _type_to_text(qtype: int) -> String:
	match qtype:
		QuestType.DIALOGUE: return "对话"
		QuestType.EXPLORATION: return "探索"
		QuestType.COLLECTION: return "收集"
		QuestType.DAILY: return "日常"
		QuestType.HIDDEN: return "隐藏"
		QuestType.STORY: return "剧情"
		_: return "其他"

func get_save_data() -> Dictionary:
	var quests_data = {}
	for quest_id in _quests:
		var quest = _quests[quest_id]
		quests_data[quest_id] = {
			"status": quest["status"],
			"progress": quest["progress"],
			"completed_day": int(quest.get("completed_day", 0)),
		}
	return {
		"quests": quests_data,
		"dialogue_counts": _dialogue_counts.duplicate(),
		"interaction_counts": _interaction_counts.duplicate(),
		"daily_dialogue_counts": _daily_dialogue_counts.duplicate(),
		"daily_interaction_counts": _daily_interaction_counts.duplicate(),
		"tracked_quest_id": _tracked_quest_id,
	}

func load_save_data(data: Dictionary) -> void:
	_apply_default_quest_metadata()
	if data.has("quests"):
		for quest_id in data["quests"]:
			if _quests.has(quest_id):
				_quests[quest_id]["status"] = data["quests"][quest_id].get("status", QuestStatus.LOCKED)
				_quests[quest_id]["progress"] = data["quests"][quest_id].get("progress", 0)
				_quests[quest_id]["completed_day"] = int(data["quests"][quest_id].get("completed_day", 0))
	if data.has("dialogue_counts"):
		_dialogue_counts = data["dialogue_counts"].duplicate()
	if data.has("interaction_counts"):
		_interaction_counts = data["interaction_counts"].duplicate()
	if data.has("daily_dialogue_counts"):
		_daily_dialogue_counts = data["daily_dialogue_counts"].duplicate()
	if data.has("daily_interaction_counts"):
		_daily_interaction_counts = data["daily_interaction_counts"].duplicate()
	_tracked_quest_id = str(data.get("tracked_quest_id", ""))
	if not _quests.has(_tracked_quest_id):
		_tracked_quest_id = ""
	refresh_contextual_recommendations()

func _log_event(message: String) -> void:
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)
