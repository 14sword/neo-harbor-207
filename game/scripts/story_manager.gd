extends Node

enum ChapterStatus { LOCKED, AVAILABLE, ACTIVE, COMPLETED }

signal chapter_unlocked(chapter_id: String)
signal chapter_completed(chapter_id: String)
signal story_event_triggered(event_id: String, event_data: Dictionary)

const CHAPTERS = {
	"ch1_arrival": {
		"id": "ch1_arrival",
		"title": "初来乍到",
		"chapter": 1,
		"description": "你刚抵达新港·207，一切都很陌生。适应新生活，认识周围的人，也许你会发现一些不寻常的迹象...",
		"unlock_condition": {},
		"complete_condition": {"min_anomaly": 10, "min_npc_chats": 3},
		"story_steps": [
			{"id": "step_1_1", "type": "dialogue", "npc_id": "zhang_san", "description": "与张三交谈，了解公司情况"},
			{"id": "step_1_2", "type": "explore", "location": "apartment", "description": "探索公寓，熟悉环境"},
			{"id": "step_1_3", "type": "dialogue", "npc_id": "li_si", "description": "与李四交谈，了解产品部门"},
			{"id": "step_1_4", "type": "explore", "location": "street", "description": "前往街区，感受小镇氛围"},
			{"id": "step_1_5", "type": "dialogue", "npc_id": "wang_wu", "description": "与王五交谈，了解设计团队"},
			{"id": "step_1_6", "type": "observe", "target": "talisman", "description": "查看符纸，感到一丝异样"},
			{"id": "step_1_7", "type": "explore", "location": "balcony", "description": "在阳台观察城市夜景"},
			{"id": "step_1_8", "type": "event", "event_id": "first_anomaly_hint", "description": "第一次异常暗示"},
		],
	},
	"ch2_dark_data": {
		"id": "ch2_dark_data",
		"title": "数据暗流",
		"chapter": 2,
		"description": "公司内部出现了异常数据，一些NPC开始行为古怪。何真发现AI系统产生了自主意识...",
		"unlock_condition": {"chapter_complete": "ch1_arrival", "min_anomaly": 20},
		"complete_condition": {"min_anomaly": 35, "key_npcs_met": ["he_zhen", "chen_xi"]},
		"story_steps": [
			{"id": "step_2_1", "type": "dialogue", "npc_id": "he_zhen", "description": "与何真交谈，了解AI系统异常"},
			{"id": "step_2_2", "type": "dialogue", "npc_id": "zhang_san", "description": "询问张三关于代码中的异常"},
			{"id": "step_2_3", "type": "explore", "location": "street", "description": "前往街区，寻找陈曦的咖啡店"},
			{"id": "step_2_4", "type": "dialogue", "npc_id": "chen_xi", "description": "与陈曦交谈，她似乎知道些什么"},
			{"id": "step_2_5", "type": "observe", "target": "computer", "description": "在电脑上发现异常数据流"},
			{"id": "step_2_6", "type": "event", "event_id": "system_glitch", "description": "系统故障，城市短暂停电"},
		],
	},
	"ch3_rift_appears": {
		"id": "ch3_rift_appears",
		"title": "裂缝显现",
		"chapter": 3,
		"description": "维度裂缝在城市中出现，异常现象越来越频繁。孙悦的研究揭示了惊人的真相...",
		"unlock_condition": {"chapter_complete": "ch2_dark_data", "min_anomaly": 40},
		"complete_condition": {"min_anomaly": 55, "key_npcs_met": ["sun_yue"]},
		"story_steps": [],
	},
	"ch4_convergence": {
		"id": "ch4_convergence",
		"title": "诸天交汇",
		"chapter": 4,
		"description": "多个维度开始交汇，城市面临前所未有的危机。所有NPC都被卷入了这场风暴...",
		"unlock_condition": {"chapter_complete": "ch3_rift_appears", "min_anomaly": 60},
		"complete_condition": {"min_anomaly": 75},
		"story_steps": [],
	},
	"ch5_decision": {
		"id": "ch5_decision",
		"title": "抉择时刻",
		"chapter": 5,
		"description": "最终的选择来临，你的决定将影响整个小镇的命运...",
		"unlock_condition": {"chapter_complete": "ch4_convergence", "min_anomaly": 80},
		"complete_condition": {"final_choice_made": true},
		"story_steps": [],
	},
}

var _chapter_status: Dictionary = {}
var _current_step: Dictionary = {}
var _completed_steps: Array = []
var _story_flags: Dictionary = {}

func _ready():
	_init_chapters()

func _init_chapters() -> void:
	for chapter_id in CHAPTERS:
		_chapter_status[chapter_id] = ChapterStatus.LOCKED
	_chapter_status["ch1_arrival"] = ChapterStatus.AVAILABLE
	_check_unlock_conditions()

func _check_unlock_conditions() -> void:
	for chapter_id in CHAPTERS:
		if _chapter_status[chapter_id] == ChapterStatus.LOCKED:
			if _can_unlock_chapter(chapter_id):
				_chapter_status[chapter_id] = ChapterStatus.AVAILABLE
				chapter_unlocked.emit(chapter_id)
				_log_event("📖 新章节解锁: " + CHAPTERS[chapter_id]["title"])

func _can_unlock_chapter(chapter_id: String) -> bool:
	var chapter = CHAPTERS.get(chapter_id, {})
	var conditions = chapter.get("unlock_condition", {})
	if conditions.is_empty():
		return true
	if conditions.has("chapter_complete"):
		var required_chapter = conditions["chapter_complete"]
		if _chapter_status.get(required_chapter, ChapterStatus.LOCKED) != ChapterStatus.COMPLETED:
			return false
	if conditions.has("min_anomaly"):
		var min_anomaly = conditions["min_anomaly"]
		if not has_node("/root/GameManager"):
			return false
		var gm = get_node("/root/GameManager")
		if gm.anomaly_level < min_anomaly:
			return false
	return true

func start_chapter(chapter_id: String) -> bool:
	if not CHAPTERS.has(chapter_id):
		return false
	if _chapter_status[chapter_id] != ChapterStatus.AVAILABLE:
		return false
	_chapter_status[chapter_id] = ChapterStatus.ACTIVE
	_completed_steps = []
	var steps = CHAPTERS[chapter_id].get("story_steps", [])
	if steps.size() > 0:
		_current_step = steps[0]
	_log_event("📖 开始章节: " + CHAPTERS[chapter_id]["title"])
	return true

func complete_step(step_id: String) -> void:
	if step_id in _completed_steps:
		return
	_completed_steps.append(step_id)
	var active_chapter = _get_active_chapter()
	if active_chapter.is_empty():
		return
	var steps = active_chapter.get("story_steps", [])
	var next_step_idx = -1
	for i in range(steps.size()):
		if steps[i]["id"] == step_id:
			next_step_idx = i + 1
			break
	if next_step_idx < steps.size():
		_current_step = steps[next_step_idx]
	else:
		_check_chapter_completion(active_chapter["id"])

func _check_chapter_completion(chapter_id: String) -> void:
	var chapter = CHAPTERS.get(chapter_id, {})
	var conditions = chapter.get("complete_condition", {})
	var anomaly_ok = true
	if conditions.has("min_anomaly"):
		if has_node("/root/GameManager"):
			anomaly_ok = get_node("/root/GameManager").anomaly_level >= conditions["min_anomaly"]
	var steps_ok = true
	if chapter.get("story_steps", []).size() > 0:
		var all_step_ids = []
		for step in chapter["story_steps"]:
			all_step_ids.append(step["id"])
		for sid in all_step_ids:
			if not sid in _completed_steps:
				steps_ok = false
				break
	if anomaly_ok and steps_ok:
		complete_chapter(chapter_id)

func complete_chapter(chapter_id: String) -> void:
	if not CHAPTERS.has(chapter_id):
		return
	_chapter_status[chapter_id] = ChapterStatus.COMPLETED
	_current_step = {}
	chapter_completed.emit(chapter_id)
	_log_event("🎉 章节完成: " + CHAPTERS[chapter_id]["title"])
	_check_unlock_conditions()
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").gain_exp(200.0)

func _get_active_chapter() -> Dictionary:
	for chapter_id in _chapter_status:
		if _chapter_status[chapter_id] == ChapterStatus.ACTIVE:
			return CHAPTERS[chapter_id]
	return {}

func get_current_step() -> Dictionary:
	return _current_step

func get_chapter_status(chapter_id: String) -> int:
	return _chapter_status.get(chapter_id, ChapterStatus.LOCKED)

func get_active_chapter_id() -> String:
	for chapter_id in _chapter_status:
		if _chapter_status[chapter_id] == ChapterStatus.ACTIVE:
			return chapter_id
	return ""

func get_all_chapters() -> Dictionary:
	return CHAPTERS

func get_chapter_progress(chapter_id: String) -> float:
	var chapter = CHAPTERS.get(chapter_id, {})
	var steps = chapter.get("story_steps", [])
	if steps.is_empty():
		return 0.0
	var completed_count = 0
	for step in steps:
		if step["id"] in _completed_steps:
			completed_count += 1
	return float(completed_count) / float(steps.size())

func set_story_flag(flag_name: String, value: Variant = true) -> void:
	_story_flags[flag_name] = value

func get_story_flag(flag_name: String, default: Variant = false) -> Variant:
	return _story_flags.get(flag_name, default)

func trigger_story_event(event_id: String, event_data: Dictionary = {}) -> void:
	story_event_triggered.emit(event_id, event_data)
	_log_event("🎬 剧情事件: " + event_id)

func get_save_data() -> Dictionary:
	return {
		"chapter_status": _chapter_status,
		"completed_steps": _completed_steps,
		"current_step": _current_step,
		"story_flags": _story_flags,
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("chapter_status"):
		_chapter_status = data["chapter_status"]
	if data.has("completed_steps"):
		_completed_steps = data["completed_steps"]
	if data.has("current_step"):
		_current_step = data["current_step"]
	if data.has("story_flags"):
		_story_flags = data["story_flags"]

func _log_event(message: String) -> void:
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)
