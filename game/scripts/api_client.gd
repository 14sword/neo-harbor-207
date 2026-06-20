extends Node

signal chat_response_received(npc_name: String, message: String, affinity_level: int, affinity_score: int)
signal chat_error(error_message: String)
signal npc_status_received(dialogues: Dictionary)
signal affinity_received(npc_id: String, affinity_level: int, affinity_score: int)
signal history_received(npc_id: String, history: Array)
signal npc_interaction_received(interactions: Array)

var http_chat: HTTPRequest
var http_status: HTTPRequest
var http_affinity: HTTPRequest
var http_history: HTTPRequest
var http_batch: HTTPRequest
var http_interaction: HTTPRequest

signal affinity_level_up(npc_id: String, new_level: int)

const DEFAULT_API_BASE_URL = "http://localhost:8000"
const AFFINITY_ENDPOINT = "/affinity"
const DIALOGUE_HISTORY_ENDPOINT = "/dialogue/history"
const BATCH_DIALOGUE_ENDPOINT = "/npcs/batch_dialogue"
const NPC_INTERACTIONS_ENDPOINT = "/npcs/interactions"

var _affinity_data: Dictionary = {
	"zhang_san": {"level": 1, "score": 0},
	"li_si": {"level": 1, "score": 0},
	"wang_wu": {"level": 1, "score": 0},
	"chen_xi": {"level": 1, "score": 0},
	"zhao_lin": {"level": 1, "score": 0},
	"sun_yue": {"level": 1, "score": 0},
	"liu_feng": {"level": 1, "score": 0},
	"he_zhen": {"level": 1, "score": 0},
}
var _daily_first_chat: Dictionary = {}
var _current_day: int = 0

const AFFINITY_LEVELS: Array[int] = [0, 30, 70, 130, 200]

var current_npc_id = ""
var _pending_chat_npc_id: String = ""
var _pending_chat_message: String = ""
var _pending_affinity_npc_id: String = ""
var _pending_history_npc_id: String = ""
var _dialogue_history: Dictionary = {}
var _npc_personas: Dictionary = {
	"zhang_san": {"name": "张三", "role": "Python工程师", "personality": "严谨、专业、喜欢分享技术知识。说话直接，注重代码质量。", "style": "技术化，偶尔用代码比喻"},
	"li_si": {"name": "李四", "role": "产品经理", "personality": "外向、善于沟通、注重用户体验。喜欢从用户角度思考问题。", "style": "亲切、用户导向"},
	"wang_wu": {"name": "王五", "role": "UI设计师", "personality": "温和、富有创意、审美独特。注重视觉呈现。", "style": "文艺、有设计感"},
	"chen_xi": {"name": "陈曦", "role": "咖啡店老板", "personality": "神秘、博学、话中有话。总是用隐喻和哲学性的语言交流。", "style": "诗意朦胧，意味深长"},
	"zhao_lin": {"name": "赵霖", "role": "黑市信息贩子", "personality": "狡猾、精明、见钱眼开。说话暗示性的，喜欢交易和讨价还价。", "style": "神秘，充满暗示和交易邀约"},
	"sun_yue": {"name": "孙悦", "role": "异常现象研究员", "personality": "理性、偏执、痴迷异常现象。说话充满学术术语和数据。", "style": "学术化，大量专业术语"},
	"liu_feng": {"name": "刘风", "role": "赛博义体技师", "personality": "粗犷、直爽、技术宅。说话口语化，喜欢用技术术语。", "style": "豪爽直接，带技术黑话"},
	"he_zhen": {"name": "何真", "role": "AI系统管理员", "personality": "冷静、逻辑性强、偶尔失控。机械式说话，偶尔流露人性化情感。", "style": "程序化表达，偶尔失序"},
}
var _status_fallbacks: Dictionary = {
	"zhang_san": ["正在审查构建日志", "调试异步任务中", "盯着终端思考边界条件"],
	"li_si": ["正在整理用户反馈", "重新排需求优先级", "和远程团队同步路线图"],
	"wang_wu": ["调整界面动效曲线", "检查霓虹色板", "给新组件做可读性测试"],
	"chen_xi": ["擦拭咖啡杯，像在等待某种信号", "低声记录梦里的裂缝", "把咖啡香调到刚好像雨夜"],
	"zhao_lin": ["在暗网频道里挂起交易", "清点几枚来路不明的数据芯片", "靠在巷口观察人流"],
	"sun_yue": ["校准异常读数", "核对凌晨采集的维度波形", "对着监测屏写下新假设"],
	"liu_feng": ["焊接一条义体神经接口", "测试过载保护模块", "把工具台收拾得勉强能用"],
	"he_zhen": ["静默巡检城市子系统", "重建一段损坏的记忆索引", "用平稳语调报告不平稳数据"],
}

func _ready():
	http_chat = HTTPRequest.new()
	http_status = HTTPRequest.new()
	http_affinity = HTTPRequest.new()
	http_history = HTTPRequest.new()
	http_batch = HTTPRequest.new()
	http_interaction = HTTPRequest.new()

	http_chat.timeout = 20
	http_status.timeout = 10
	http_affinity.timeout = 10
	http_history.timeout = 10
	http_batch.timeout = 15
	http_interaction.timeout = 15

	add_child(http_chat)
	add_child(http_status)
	add_child(http_affinity)
	add_child(http_history)
	add_child(http_batch)
	add_child(http_interaction)

	http_chat.request_completed.connect(_on_dialogue_request_completed)
	http_status.request_completed.connect(_on_status_request_completed)
	http_affinity.request_completed.connect(_on_affinity_request_completed)
	http_history.request_completed.connect(_on_history_request_completed)
	http_batch.request_completed.connect(_on_batch_request_completed)
	http_interaction.request_completed.connect(_on_interaction_request_completed)

func send_chat(npc_id: String, message: String) -> void:
	current_npc_id = npc_id

	if not _dialogue_history.has(npc_id):
		_dialogue_history[npc_id] = []

	if _is_request_busy(http_chat):
		chat_error.emit("上一条消息仍在发送中，请稍后再试")
		return

	var persona = _npc_personas.get(npc_id, _npc_personas["zhang_san"])
	var context = _build_chat_context(npc_id)
	var previous_history = _dialogue_history[npc_id].duplicate(true)
	_append_history(npc_id, "user", message)

	_pending_chat_npc_id = npc_id
	_pending_chat_message = message
	var body_data = {
		"npc_id": npc_id,
		"player_name": "玩家",
		"player_message": _build_backend_player_message(message, context, previous_history, persona),
	}

	var error = _request_json(http_chat, _dialogue_url(), HTTPClient.METHOD_POST, body_data)
	if error != OK:
		_pending_chat_npc_id = ""
		_pending_chat_message = ""
		_emit_local_chat_fallback(npc_id, message, "后端请求失败")

func _on_dialogue_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var npc_id = _pending_chat_npc_id
	if npc_id.is_empty():
		npc_id = current_npc_id
	var original_message = _pending_chat_message
	_pending_chat_npc_id = ""
	_pending_chat_message = ""

	if not _is_success_response(result, response_code):
		_emit_local_chat_fallback(npc_id, original_message, _http_error_message("后端对话服务不可用", result, response_code))
		return

	var data = _parse_json_body(body)
	if data == null:
		_emit_local_chat_fallback(npc_id, original_message, "后端响应解析失败")
		return

	var content = _normalize_reply(_extract_chat_content(data))
	if content.is_empty():
		_emit_local_chat_fallback(npc_id, original_message, "后端没有返回有效回复")
		return

	_append_history(npc_id, "assistant", content)

	var increment = 0
	if not _apply_affinity_from_response(npc_id, data):
		increment = _apply_local_affinity_increment(npc_id, content.length())

	var aff_data = _get_affinity_entry(npc_id)
	print("[APIClient][Backend] %s: %s (affinity +%d -> %d, Lv.%d)" % [npc_id, content, increment, aff_data.get("score", 0), aff_data.get("level", 1)])
	chat_response_received.emit(npc_id, content, aff_data.get("level", 1), aff_data.get("score", 0))

func get_npc_status() -> void:
	if _is_request_busy(http_status):
		return

	var error = _request_json(http_status, _npc_status_url(), HTTPClient.METHOD_GET)
	if error != OK:
		npc_status_received.emit(_get_local_status_dialogues())

func _on_status_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not _is_success_response(result, response_code):
		npc_status_received.emit(_get_local_status_dialogues())
		return
	_emit_status_from_body(body)

func get_affinity(npc_id: String, player_name: String) -> void:
	if _is_request_busy(http_affinity):
		_emit_local_affinity(npc_id)
		return

	_pending_affinity_npc_id = npc_id
	var url = _build_url(AFFINITY_ENDPOINT + "/" + npc_id.uri_encode() + "/" + player_name.uri_encode())
	var error = _request_json(http_affinity, url, HTTPClient.METHOD_GET)
	if error != OK:
		_pending_affinity_npc_id = ""
		_emit_local_affinity(npc_id)

func _on_affinity_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var npc_id = _pending_affinity_npc_id
	_pending_affinity_npc_id = ""
	if npc_id.is_empty():
		return

	if not _is_success_response(result, response_code):
		_emit_local_affinity(npc_id)
		return

	var data = _parse_json_body(body)
	if data == null or not _apply_affinity_from_response(npc_id, data):
		_emit_local_affinity(npc_id)
		return

	_emit_local_affinity(npc_id)

func get_dialogue_history(npc_id: String) -> void:
	if _is_request_busy(http_history):
		history_received.emit(npc_id, _dialogue_history.get(npc_id, []))
		return

	_pending_history_npc_id = npc_id
	var url = _build_url(DIALOGUE_HISTORY_ENDPOINT + "/" + npc_id.uri_encode())
	var error = _request_json(http_history, url, HTTPClient.METHOD_GET)
	if error != OK:
		_pending_history_npc_id = ""
		history_received.emit(npc_id, _dialogue_history.get(npc_id, []))

func _on_history_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var npc_id = _pending_history_npc_id
	_pending_history_npc_id = ""
	if npc_id.is_empty():
		return

	if not _is_success_response(result, response_code):
		history_received.emit(npc_id, _dialogue_history.get(npc_id, []))
		return

	var data = _parse_json_body(body)
	if data == null:
		history_received.emit(npc_id, _dialogue_history.get(npc_id, []))
		return

	var history = _extract_history(data)
	if history.size() > 0:
		_dialogue_history[npc_id] = history.duplicate(true)
	history_received.emit(npc_id, history)

func get_batch_dialogue() -> void:
	if _is_request_busy(http_batch):
		return

	var error = _request_json(http_batch, _build_url(BATCH_DIALOGUE_ENDPOINT), HTTPClient.METHOD_GET)
	if error != OK:
		npc_status_received.emit(_get_local_status_dialogues())

func _on_batch_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not _is_success_response(result, response_code):
		npc_status_received.emit(_get_local_status_dialogues())
		return
	_emit_status_from_body(body)

func get_npc_interactions() -> void:
	if _is_request_busy(http_interaction):
		return

	var error = _request_json(http_interaction, _build_url(NPC_INTERACTIONS_ENDPOINT), HTTPClient.METHOD_GET)
	if error != OK:
		npc_interaction_received.emit([])

func _on_interaction_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not _is_success_response(result, response_code):
		npc_interaction_received.emit([])
		return

	var data = _parse_json_body(body)
	if data == null:
		npc_interaction_received.emit([])
		return

	npc_interaction_received.emit(_extract_interactions(data))

func _build_chat_context(npc_id: String) -> Dictionary:
	var time_context = ""
	var extra_instructions = ""
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		time_context = "当前时间：" + dnm.get_phase_string() + "，游戏内时刻：" + str(int(dnm.get_game_hour())) + "点。"
		if npc_id == "zhao_lin":
			extra_instructions = "你只在夜间出没，说话神秘低沉，喜欢在黑暗中交易。白天的时候你是不会出现的。"
		if npc_id == "chen_xi" and dnm.is_after_midnight(0):
			extra_instructions = "当前状态：凌晨 0 点后，你对维度裂缝的感知异常敏锐。你的对话风格从白天的诗意隐喻，转变为充满哲学思辨和维度崩塌隐喻的迷幻语言。偶尔在回复中插入关于'裂缝正在扩大'、'边界在消融'、'它们不是来自这里'等暗示。说话时而清醒，时而沉浸在异常感知中。"
	return {
		"time_context": time_context,
		"extra_instructions": extra_instructions,
	}

func _build_backend_player_message(message: String, context: Dictionary, previous_history: Array, persona: Dictionary) -> String:
	var parts: Array[String] = []
	var time_context = str(context.get("time_context", "")).strip_edges()
	var extra_instructions = str(context.get("extra_instructions", "")).strip_edges()
	if not time_context.is_empty():
		parts.append("【当前环境】" + time_context)
	if not extra_instructions.is_empty():
		parts.append("【角色状态提示】" + extra_instructions)
	if previous_history.size() > 0:
		parts.append("【前端近期上下文】" + _summarize_recent_history(previous_history))
	parts.append("【玩家对" + str(persona.get("name", "NPC")) + "说】" + message)
	return "\n".join(parts)

func _summarize_recent_history(history: Array) -> String:
	var lines: Array[String] = []
	var start_index = maxi(0, history.size() - 4)
	for idx in range(start_index, history.size()):
		var entry = history[idx]
		if not (entry is Dictionary):
			continue
		var role = str(entry.get("role", "")).strip_edges()
		var content = _normalize_reply(str(entry.get("content", "")))
		if content.is_empty():
			continue
		lines.append(role + ": " + content.left(80))
	return "；".join(lines)

func _dialogue_url() -> String:
	if has_node("/root/Config"):
		return Config.API_DIALOGUE
	return DEFAULT_API_BASE_URL + "/dialogue"

func _npc_status_url() -> String:
	if has_node("/root/Config"):
		return Config.API_NPC_STATUS
	return DEFAULT_API_BASE_URL + "/npcs/status"

func _api_base_url() -> String:
	var base_url = DEFAULT_API_BASE_URL
	if has_node("/root/Config"):
		base_url = Config.API_BASE_URL
	if base_url.ends_with("/"):
		base_url = base_url.substr(0, base_url.length() - 1)
	return base_url

func _build_url(path: String, query: Dictionary = {}) -> String:
	var url = _api_base_url() + path
	var query_string = ""
	for key in query:
		if not query_string.is_empty():
			query_string += "&"
		query_string += str(key).uri_encode() + "=" + str(query[key]).uri_encode()
	if not query_string.is_empty():
		url += "?" + query_string
	return url

func _request_json(request: HTTPRequest, url: String, method: int, body_data: Dictionary = {}) -> int:
	if request == null:
		return ERR_UNCONFIGURED

	var body = ""
	if method != HTTPClient.METHOD_GET:
		body = JSON.stringify(body_data)

	return request.request(
		url,
		PackedStringArray(["Content-Type: application/json", "Accept: application/json"]),
		method,
		body
	)

func _is_request_busy(request: HTTPRequest) -> bool:
	if request == null:
		return false
	return request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED

func _is_success_response(result: int, response_code: int) -> bool:
	return result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300

func _http_error_message(prefix: String, result: int, response_code: int) -> String:
	if response_code == 0:
		return prefix + "，请确认 FastAPI 服务已启动"
	if result != HTTPRequest.RESULT_SUCCESS:
		return prefix + "，网络请求失败"
	return prefix + ": HTTP " + str(response_code)

func _parse_json_body(body: PackedByteArray) -> Variant:
	var text = body.get_string_from_utf8().strip_edges()
	if text.is_empty():
		return null

	var json = JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data

func _normalize_reply(content: String) -> String:
	content = content.strip_edges().replace("\n", " ")
	while content.find("  ") != -1:
		content = content.replace("  ", " ")
	return content

func _extract_chat_content(data: Variant) -> String:
	if data is Dictionary:
		var direct = _extract_first_string(data, ["npc_reply", "response", "reply", "message", "dialogue", "content", "text"])
		if not direct.is_empty():
			return direct

		if data.has("choices") and data["choices"] is Array and data["choices"].size() > 0:
			var first_choice = data["choices"][0]
			if first_choice is Dictionary:
				if first_choice.has("message") and first_choice["message"] is Dictionary:
					var message = first_choice["message"]
					var content = _extract_first_string(message, ["content"])
					if not content.is_empty():
						return content
				var text = _extract_first_string(first_choice, ["text"])
				if not text.is_empty():
					return text

		for nested_key in ["data", "result"]:
			if data.has(nested_key):
				var nested = _extract_chat_content(data[nested_key])
				if not nested.is_empty():
					return nested
	elif data is Array and data.size() > 0:
		return _extract_chat_content(data[0])
	return ""

func _emit_status_from_body(body: PackedByteArray) -> void:
	var data = _parse_json_body(body)
	var dialogues = _extract_status_dialogues(data)
	if dialogues.size() == 0:
		dialogues = _get_local_status_dialogues()
	npc_status_received.emit(dialogues)

func _extract_status_dialogues(data: Variant) -> Dictionary:
	if data is Dictionary:
		for nested_key in ["dialogues", "statuses", "npcs", "items", "data"]:
			if data.has(nested_key):
				var nested = _extract_status_dialogues(data[nested_key])
				if nested.size() > 0:
					return nested

		var direct: Dictionary = {}
		for key in data.keys():
			var value = data[key]
			if value is String:
				direct[str(key)] = value
			elif value is Dictionary:
				var line = _extract_first_string(value, ["dialogue", "status", "current_dialogue", "current_action", "message", "text", "content"])
				if not line.is_empty():
					var npc_name = _extract_npc_display_name(value, str(key))
					direct[npc_name] = line
		return direct
	elif data is Array:
		var from_array: Dictionary = {}
		for item in data:
			if item is Dictionary:
				var line = _extract_first_string(item, ["dialogue", "status", "current_dialogue", "current_action", "message", "text", "content"])
				if not line.is_empty():
					var npc_name = _extract_npc_display_name(item, "")
					if not npc_name.is_empty():
						from_array[npc_name] = line
		return from_array
	return {}

func _extract_history(data: Variant) -> Array:
	if data is Dictionary:
		for key in ["history", "dialogue_history", "messages", "items", "data"]:
			if data.has(key):
				return _normalize_history(data[key])
	elif data is Array:
		return _normalize_history(data)
	return []

func _normalize_history(raw_history: Variant) -> Array:
	var normalized: Array = []
	if not (raw_history is Array):
		return normalized

	for entry in raw_history:
		if not (entry is Dictionary):
			continue
		var role = str(entry.get("role", "")).strip_edges()
		if role == "player":
			role = "user"
		elif role == "npc":
			role = "assistant"

		var content = _extract_first_string(entry, ["content", "message", "text", "dialogue"])
		if not role.is_empty() and not content.is_empty():
			normalized.append({"role": role, "content": content})
	return normalized

func _extract_interactions(data: Variant) -> Array:
	var raw_interactions: Variant = data
	if data is Dictionary:
		for key in ["interactions", "items", "data"]:
			if data.has(key):
				raw_interactions = data[key]
				break

	var interactions: Array = []
	if raw_interactions is Array:
		for interaction in raw_interactions:
			if interaction is Dictionary:
				interactions.append(interaction.duplicate(true))
	return interactions

func _extract_first_string(source: Dictionary, keys: Array) -> String:
	for key in keys:
		if source.has(key) and source[key] != null:
			var value = source[key]
			if value is Dictionary or value is Array:
				continue
			var text = str(value).strip_edges()
			if not text.is_empty():
				return text
	return ""

func _extract_npc_display_name(source: Dictionary, fallback: String) -> String:
	var name = _extract_first_string(source, ["name", "npc_name", "display_name"])
	if not name.is_empty():
		return name

	var npc_id = _extract_first_string(source, ["npc_id", "id"])
	if npc_id.is_empty():
		npc_id = fallback
	return _display_name_for_npc(npc_id)

func _display_name_for_npc(npc_id: String) -> String:
	if _npc_personas.has(npc_id):
		return _npc_personas[npc_id].get("name", npc_id)
	return npc_id

func _get_local_status_dialogues() -> Dictionary:
	var dialogues: Dictionary = {}
	for npc_id in _npc_personas:
		var persona = _npc_personas[npc_id]
		var lines = _status_fallbacks.get(npc_id, [])
		if lines.size() == 0:
			dialogues[persona.get("name", npc_id)] = "正在观察新港的日常噪声"
		else:
			dialogues[persona.get("name", npc_id)] = lines[randi() % lines.size()]
	return dialogues

func _emit_local_chat_fallback(npc_id: String, player_message: String, reason: String = "") -> void:
	if npc_id.is_empty():
		chat_error.emit("本地对话失败：NPC 不存在")
		return

	var content = _generate_local_chat_reply(npc_id, player_message)
	if content.is_empty():
		content = "远端暂时没有回应，但我还在。我们可以先从剧情或日常话题继续。"

	_append_history(npc_id, "assistant", content)
	var increment = _apply_local_affinity_increment(npc_id, player_message.length())
	var aff_data = _get_affinity_entry(npc_id)
	if not reason.is_empty():
		print("[APIClient][LocalFallback] " + reason)
	print("[APIClient][LocalFallback] %s: %s (affinity +%d -> %d, Lv.%d)" % [npc_id, content, increment, aff_data.get("score", 0), aff_data.get("level", 1)])
	chat_response_received.emit(npc_id, content, aff_data.get("level", 1), aff_data.get("score", 0))

func _generate_local_chat_reply(npc_id: String, player_message: String) -> String:
	if has_node("/root/DialogueDirector"):
		var director = get_node("/root/DialogueDirector")
		if director.has_method("get_free_chat_fallback"):
			return str(director.get_free_chat_fallback(npc_id, player_message))

	var persona = _npc_personas.get(npc_id, _npc_personas["zhang_san"])
	var name = persona.get("name", npc_id)
	var role = persona.get("role", "居民")
	return name + "以" + role + "的语气回应：远端线路暂时安静，我们先用本地记录把话聊下去。"

func _append_history(npc_id: String, role: String, content: String) -> void:
	if not _dialogue_history.has(npc_id):
		_dialogue_history[npc_id] = []
	_dialogue_history[npc_id].append({"role": role, "content": content})
	if _dialogue_history[npc_id].size() > 12:
		_dialogue_history[npc_id] = _dialogue_history[npc_id].slice(-10)

func _get_affinity_entry(npc_id: String) -> Dictionary:
	if not _affinity_data.has(npc_id):
		_affinity_data[npc_id] = {"level": 1, "score": 0}
	return _affinity_data[npc_id]

func _emit_local_affinity(npc_id: String) -> void:
	var data = _get_affinity_entry(npc_id)
	affinity_received.emit(npc_id, data.get("level", 1), data.get("score", 0))

func _apply_affinity_from_response(npc_id: String, data: Variant) -> bool:
	var level = _extract_int(data, ["affinity_level", "level"], -1)
	var score = _extract_int(data, ["affinity_score", "score"], -1)
	if level < 0 and score < 0:
		return false

	var current = _get_affinity_entry(npc_id)
	if score < 0:
		score = current.get("score", 0)
	if level < 0:
		level = _calculate_level(score)
	_set_affinity(npc_id, maxi(1, level), maxi(0, score))
	return true

func _extract_int(source: Variant, keys: Array, default_value: int) -> int:
	if source is Dictionary:
		for key in keys:
			if source.has(key):
				return _to_int(source[key], default_value)
		for nested_key in ["affinity", "data", "result"]:
			if source.has(nested_key):
				var nested_value = _extract_int(source[nested_key], keys, default_value)
				if nested_value != default_value:
					return nested_value
	return default_value

func _to_int(value: Variant, default_value: int) -> int:
	match typeof(value):
		TYPE_INT:
			return value
		TYPE_FLOAT:
			return int(value)
		TYPE_STRING:
			var text = value.strip_edges()
			if text.is_valid_int():
				return int(text)
	return default_value

func _apply_local_affinity_increment(npc_id: String, message_length: int) -> int:
	var increment = _calculate_affinity_increment(npc_id, message_length)
	var data = _get_affinity_entry(npc_id)
	var new_score = data.get("score", 0) + increment
	var new_level = _calculate_level(new_score)
	_set_affinity(npc_id, new_level, new_score)
	return increment

func _set_affinity(npc_id: String, level: int, score: int) -> void:
	var old_level = _get_affinity_entry(npc_id).get("level", 1)
	_affinity_data[npc_id] = {"level": level, "score": score}
	if level > old_level:
		affinity_level_up.emit(npc_id, level)
		if has_node("/root/LogPanel"):
			var npc_name = _npc_personas.get(npc_id, {}).get("name", npc_id)
			get_node("/root/LogPanel").add_log("❤️ " + npc_name + "好感度提升至Lv." + str(level) + "！")

func _calculate_affinity_increment(npc_id: String, message_length: int) -> int:
	var base_increment = randi_range(3, 8)
	var length_bonus = mini(floori(message_length / 15), 5)
	var total = base_increment + length_bonus
	var today = _get_today_id()
	if today != _current_day:
		_current_day = today
		_daily_first_chat.clear()
	if not _daily_first_chat.has(npc_id):
		_daily_first_chat[npc_id] = true
		total *= 2
	return total

func _calculate_level(score: int) -> int:
	for i in range(AFFINITY_LEVELS.size() - 1, -1, -1):
		if score >= AFFINITY_LEVELS[i]:
			return i + 1
	return 1

func _get_today_id() -> int:
	if has_node("/root/WorldCalendar"):
		return get_node("/root/WorldCalendar").current_day
	return Time.get_date_dict_from_system().get("yday", 0)

func add_affinity(npc_id: String, amount: int) -> void:
	var data = _get_affinity_entry(npc_id)
	var new_score = data.get("score", 0) + amount
	_set_affinity(npc_id, _calculate_level(new_score), new_score)

func get_affinity_data() -> Dictionary:
	return _affinity_data.duplicate(true)

func get_save_data() -> Dictionary:
	var affinity_save = {}
	for npc_id in _affinity_data:
		affinity_save[npc_id] = _affinity_data[npc_id].duplicate()
	return {
		"affinity": affinity_save,
		"dialogue_history": _dialogue_history.duplicate(true),
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("affinity"):
		for npc_id in data["affinity"]:
			_affinity_data[npc_id] = {
				"level": data["affinity"][npc_id].get("level", 1),
				"score": data["affinity"][npc_id].get("score", 0),
			}
	if data.has("dialogue_history"):
		_dialogue_history = data["dialogue_history"].duplicate(true)
