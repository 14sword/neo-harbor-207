extends Node

enum QuestStatus { LOCKED, AVAILABLE, ACTIVE, COMPLETED }
enum QuestType { DIALOGUE, EXPLORATION, COLLECTION, DAILY, HIDDEN, STORY }

var _quests: Dictionary = {}
var _dialogue_counts: Dictionary = {}
var _interaction_counts: Dictionary = {}

signal quest_updated(quest_id: String, status: int)
signal quest_completed(quest_id: String)
signal new_quest_available(quest_id: String)
signal quest_accepted(quest_id: String)

func _ready():
	_init_quests()

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

func on_dialogue_with_npc(npc_id: String) -> void:
	if not _dialogue_counts.has(npc_id):
		_dialogue_counts[npc_id] = 0
	_dialogue_counts[npc_id] += 1
	_check_all_quests()

func on_interaction(interaction_type: String) -> void:
	if not _interaction_counts.has(interaction_type):
		_interaction_counts[interaction_type] = 0
	_interaction_counts[interaction_type] += 1
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

		if quest["status"] == QuestStatus.ACTIVE:
			var new_progress = _calculate_progress(quest)
			if new_progress != quest["progress"]:
				quest["progress"] = new_progress
				quest_updated.emit(quest_id, quest["status"])

			if _check_completion(quest):
				quest["status"] = QuestStatus.COMPLETED
				quest_completed.emit(quest_id)
				_log_event("🎉 任务完成: " + quest["title"])
				_on_quest_reward(quest)

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
	match req["type"]:
		"any_chat":
			var total = 0
			for npc_id in _dialogue_counts:
				total += _dialogue_counts[npc_id]
			return mini(total, target_count)
		"chat":
			var npc_id = req.get("npc_id", "")
			return mini(_dialogue_counts.get(npc_id, 0), target_count)
		"all_chat":
			var min_count = 999
			for npc_id in ["zhang_san", "li_si", "wang_wu", "chen_xi", "zhao_lin", "sun_yue", "liu_feng", "he_zhen"]:
				min_count = mini(min_count, _dialogue_counts.get(npc_id, 0))
			return mini(min_count, target_count)
		"interaction":
			var itype = req.get("interaction_type", "")
			return mini(_interaction_counts.get(itype, 0), target_count)
		"unique_interactions":
			return mini(_interaction_counts.size(), target_count)
	return 0

func _check_completion(quest: Dictionary) -> bool:
	var req = quest["requirement"]
	var target_count = req.get("count", 1)
	return _calculate_progress(quest) >= target_count

func _on_quest_reward(quest: Dictionary) -> void:
	if quest.has("rewards") and quest["rewards"].has("affinity"):
		var affinity_rewards = quest["rewards"]["affinity"]
		for npc_id in affinity_rewards:
			if has_node("/root/APIClient"):
				get_node("/root/APIClient").add_affinity(npc_id, affinity_rewards[npc_id])
	if quest.has("rewards") and quest["rewards"].has("exp"):
		var exp_reward = quest["rewards"]["exp"]
		if has_node("/root/GameManager"):
			get_node("/root/GameManager").gain_exp(float(exp_reward))
	if quest.has("rewards") and quest["rewards"].has("anomaly"):
		var anomaly_reward = quest["rewards"]["anomaly"]
		if has_node("/root/GameManager"):
			get_node("/root/GameManager").increase_anomaly(float(anomaly_reward))
	if quest.get("daily", false):
		quest["status"] = QuestStatus.AVAILABLE
		quest["progress"] = 0

func reset_daily_quests() -> void:
	for quest_id in _quests:
		var quest = _quests[quest_id]
		if quest.get("daily", false) and quest["status"] == QuestStatus.COMPLETED:
			quest["status"] = QuestStatus.AVAILABLE
			quest["progress"] = 0

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
	var result = []
	for quest_id in _quests:
		var quest = _quests[quest_id]
		if quest["status"] == QuestStatus.LOCKED:
			continue
		var req = quest["requirement"]
		var target = req.get("count", 1)
		result.append({
			"id": quest["id"],
			"title": quest["title"],
			"description": quest["description"],
			"progress": str(quest["progress"]) + "/" + str(target),
			"status": _status_to_text(quest["status"]),
			"reward": quest.get("reward_text", ""),
			"type": _type_to_text(quest.get("type", QuestType.DIALOGUE)),
		})
	return result

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
		}
	return {
		"quests": quests_data,
		"dialogue_counts": _dialogue_counts.duplicate(),
		"interaction_counts": _interaction_counts.duplicate(),
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("quests"):
		for quest_id in data["quests"]:
			if _quests.has(quest_id):
				_quests[quest_id]["status"] = data["quests"][quest_id].get("status", QuestStatus.LOCKED)
				_quests[quest_id]["progress"] = data["quests"][quest_id].get("progress", 0)
	if data.has("dialogue_counts"):
		_dialogue_counts = data["dialogue_counts"].duplicate()
	if data.has("interaction_counts"):
		_interaction_counts = data["interaction_counts"].duplicate()

func _log_event(message: String) -> void:
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)
