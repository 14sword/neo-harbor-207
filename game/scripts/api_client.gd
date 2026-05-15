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

const GROQ_API_KEY = "YOUR_GROQ_API_KEY"
const GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
const GROQ_MODEL = "llama-3.3-70b-versatile"

signal affinity_level_up(npc_id: String, new_level: int)

var _affinity_data: Dictionary = {
	"zhang_san": {"level": 1, "score": 0},
	"li_si": {"level": 1, "score": 0},
	"wang_wu": {"level": 1, "score": 0},
}
var _daily_first_chat: Dictionary = {}
var _current_day: int = 0

const AFFINITY_LEVELS: Array[int] = [0, 30, 70, 130, 200]

var current_npc_id = ""
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

	http_chat.request_completed.connect(_on_groq_chat_completed)
	http_status.request_completed.connect(_on_status_request_completed)
	http_affinity.request_completed.connect(_on_affinity_request_completed)
	http_history.request_completed.connect(_on_history_request_completed)
	http_batch.request_completed.connect(_on_batch_request_completed)
	http_interaction.request_completed.connect(_on_interaction_request_completed)

func send_chat(npc_id: String, message: String) -> void:
	current_npc_id = npc_id

	if not _dialogue_history.has(npc_id):
		_dialogue_history[npc_id] = []

	var persona = _npc_personas.get(npc_id, _npc_personas["zhang_san"])

	var time_context = ""
	var extra_instructions = ""
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		time_context = "当前时间：" + dnm.get_phase_string() + "，游戏内时刻：" + str(int(dnm.get_game_hour())) + "点。"
		if npc_id == "zhao_lin":
			extra_instructions = "你只在夜间出没，说话神秘低沉，喜欢在黑暗中交易。白天的时候你是不会出现的。"
		if npc_id == "chen_xi" and dnm.is_after_midnight(0):
			extra_instructions = "当前状态：凌晨 0 点后，你对维度裂缝的感知异常敏锐。你的对话风格从白天的诗意隐喻，转变为充满哲学思辨和维度崩塌隐喻的迷幻语言。偶尔在回复中插入关于'裂缝正在扩大'、'边界在消融'、'它们不是来自这里'等暗示。说话时而清醒，时而沉浸在异常感知中。"

	var system_prompt = """你是赛博小镇中的%s「%s」，性格：%s。
回复风格：%s。
背景设定：
- 这是一个融合赛博朋克+都市异能+星露谷风格的未来都市
- 有昼夜循环系统（白天/傍晚/雨夜/深夜）
- 玩家是刚搬来的新居民
- 你的职业决定了你的对话内容和关注点

环境信息：%s

%s

规则：
- 回复要简短（20-80字），像真实游戏NPC对话
- 不要说"我是AI"或类似的话
- 严格按照你的性格特点和身份回应
- 可以提及当前环境、时间或你的日常工作
- 偶尔会触发小剧情或任务提示
- 用中文回复""" % [persona.role, persona.name, persona.personality, persona.style, time_context, extra_instructions]

	var messages = [
		{"role": "system", "content": system_prompt},
	]
	for entry in _dialogue_history[npc_id]:
		messages.append(entry)
	messages.append({"role": "user", "content": message})

	var temperature = 0.8
	if npc_id == "chen_xi" and has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if dnm.is_after_midnight(0):
			temperature = 1.2

	var body_data = {
		"model": GROQ_MODEL,
		"messages": messages,
		"max_tokens": 200,
		"temperature": temperature,
		"top_p": 0.9,
	}
	var json_string = JSON.stringify(body_data)
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + GROQ_API_KEY,
	]

	var error = http_chat.request(
		GROQ_API_URL,
		headers,
		HTTPClient.METHOD_POST,
		json_string
	)

	if error != OK:
		chat_error.emit("网络请求失败")
		_dialogue_history[npc_id].append({"role": "user", "content": message})

func _on_groq_chat_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		var err_msg = "服务器错误: " + str(response_code)
		if response_code == 401:
			err_msg = "API认证失败，请检查密钥"
		elif response_code == 404:
			err_msg = "API地址不存在"
		elif response_code == 429:
			err_msg = "请求过于频繁，请稍后再试"
		chat_error.emit(err_msg)
		return

	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		chat_error.emit("响应解析失败")
		return

	var data = json.data
	if data.has("choices") and data.choices.size() > 0:
		var content = data.choices[0].message.content.strip_edges()
		content = content.replace("\n", " ").replace("  ", " ")

		_dialogue_history[current_npc_id].append({"role": "assistant", "content": content})
		if _dialogue_history[current_npc_id].size() > 12:
			_dialogue_history[current_npc_id] = _dialogue_history[current_npc_id].slice(-10)

		var increment = _calculate_affinity_increment(content.length())
		if not _affinity_data.has(current_npc_id):
			_affinity_data[current_npc_id] = {"level": 1, "score": 0}
		var aff_data = _affinity_data[current_npc_id]
		var old_level = aff_data.level
		aff_data.score += increment
		aff_data.level = _calculate_level(aff_data.score)
		if aff_data.level > old_level:
			affinity_level_up.emit(current_npc_id, aff_data.level)
			if has_node("/root/LogPanel"):
				var npc_name = _npc_personas.get(current_npc_id, {}).get("name", current_npc_id)
				get_node("/root/LogPanel").add_log("❤️ " + npc_name + "好感度提升至Lv." + str(aff_data.level) + "！")
		print("[APIClient][Groq] %s: %s (affinity +%d -> %d, Lv.%d)" % [current_npc_id, content, increment, aff_data.score, aff_data.level])
		chat_response_received.emit(current_npc_id, content, aff_data.level, aff_data.score)
	else:
		chat_error.emit("无有效回复")

func get_npc_status() -> void:
	if http_status.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var dialogues = {}
	for npc_id in _npc_personas:
		var p = _npc_personas[npc_id]
		var actions = ["正在看数据报表", "调试代码中", "设计新界面", "喝咖啡休息", "开会讨论需求", "整理文档"]
		dialogues[p.name] = actions[randi() % actions.size()]
	npc_status_received.emit(dialogues)

func _on_status_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	pass

func get_affinity(npc_id: String, _player_name: String) -> void:
	if not _affinity_data.has(npc_id):
		_affinity_data[npc_id] = {"level": 1, "score": 0}
	var data = _affinity_data[npc_id]
	affinity_received.emit(npc_id, data.level, data.score)

func _on_affinity_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	pass

func get_dialogue_history(npc_id: String) -> void:
	history_received.emit(npc_id, _dialogue_history.get(npc_id, []))

func _on_history_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	pass

func get_batch_dialogue() -> void:
	get_npc_status()

func _on_batch_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	pass

func get_npc_interactions() -> void:
	npc_interaction_received.emit([])

func _on_interaction_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	pass

func _calculate_affinity_increment(message_length: int) -> int:
	var base_increment = randi_range(3, 8)
	var length_bonus = mini(floori(message_length / 15), 5)
	var total = base_increment + length_bonus
	var today = _get_today_id()
	if today != _current_day:
		_current_day = today
		_daily_first_chat.clear()
	if not _daily_first_chat.has(current_npc_id):
		_daily_first_chat[current_npc_id] = true
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
	if not _affinity_data.has(npc_id):
		_affinity_data[npc_id] = {"level": 1, "score": 0}
	var data = _affinity_data[npc_id]
	var old_level = data.level
	data.score += amount
	data.level = _calculate_level(data.score)
	if data.level > old_level:
		affinity_level_up.emit(npc_id, data.level)

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
