extends SceneTree

var _reply_received := false
var _reply_npc_id := ""
var _reply_message := ""
var _reply_level := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	_verify_api_free_chat(errors)
	await create_timer(0.2).timeout
	await _verify_dialogue_ui_free_mode(errors)
	print("====== VERIFY FREE DIALOGUE FLOW ======")
	if errors.is_empty():
		print("Free dialogue flow checks passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _verify_api_free_chat(errors: Array[String]) -> void:
	var api = root.get_node_or_null("/root/APIClient")
	if not api:
		errors.append("API_CLIENT_MISSING")
		return
	if api.http_chat:
		api.http_chat.timeout = 1.0
	if not api.chat_response_received.is_connected(_on_chat_response):
		api.chat_response_received.connect(_on_chat_response)
	_reply_received = false
	api.send_chat("zhang_san", "后端没有连上时还能自由聊天吗？")
	var deadline := Time.get_ticks_msec() + 2500
	while not _reply_received and Time.get_ticks_msec() < deadline:
		await process_frame
	if not _reply_received:
		errors.append("API_FREE_CHAT_NO_REPLY")
		return
	if _reply_npc_id != "zhang_san":
		errors.append("API_FREE_CHAT_WRONG_NPC: " + _reply_npc_id)
	if _reply_message.strip_edges().is_empty():
		errors.append("API_FREE_CHAT_EMPTY_REPLY")
	if _reply_level < 1:
		errors.append("API_FREE_CHAT_BAD_AFFINITY")

func _verify_dialogue_ui_free_mode(errors: Array[String]) -> void:
	var packed := load("res://scenes/dialogue_ui.tscn")
	if not packed:
		errors.append("DIALOGUE_UI_SCENE_MISSING")
		return
	var ui = packed.instantiate()
	root.add_child(ui)
	await process_frame
	ui.start_dialogue("he_zhen")
	await process_frame
	await process_frame
	if ui.current_dialogue_mode != "story":
		errors.append("UI_DEFAULT_MODE_NOT_STORY")
	if not ui.input_field.visible or not ui.input_field.editable:
		errors.append("UI_FREE_INPUT_NOT_RESIDENT_IN_STORY")
	if not ui.send_button.visible or ui.send_button.disabled:
		errors.append("UI_FREE_SEND_NOT_RESIDENT_IN_STORY")
	var resident_before_count: int = ui.dialogue_history.size()
	ui.input_field.text = "剧情模式下也能自由问吗"
	_reply_received = false
	ui.send_message()
	var resident_deadline := Time.get_ticks_msec() + 3000
	while not _reply_received and Time.get_ticks_msec() < resident_deadline:
		await process_frame
	if not _reply_received:
		errors.append("UI_RESIDENT_FREE_CHAT_NO_REPLY")
	if ui.dialogue_history.size() <= resident_before_count:
		errors.append("UI_RESIDENT_FREE_HISTORY_NOT_UPDATED")
	ui._on_mode_button_pressed("free")
	await process_frame
	if ui.current_dialogue_mode != "free":
		errors.append("UI_FREE_MODE_NOT_SELECTED")
	if not ui.input_field.visible or not ui.input_field.editable:
		errors.append("UI_FREE_INPUT_NOT_READY")
	if not ui.send_button.visible or ui.send_button.disabled:
		errors.append("UI_FREE_SEND_NOT_READY")
	var before_count: int = ui.dialogue_history.size()
	ui.input_field.text = "开放自由对话测试"
	_reply_received = false
	ui.send_message()
	var deadline := Time.get_ticks_msec() + 3000
	while not _reply_received and Time.get_ticks_msec() < deadline:
		await process_frame
	if not _reply_received:
		errors.append("UI_FREE_CHAT_NO_REPLY")
	if ui.dialogue_history.size() <= before_count:
		errors.append("UI_FREE_HISTORY_NOT_UPDATED")
	if ui.send_button.disabled:
		errors.append("UI_FREE_SEND_STILL_DISABLED")
	ui.hide_dialogue()
	ui.queue_free()

func _on_chat_response(npc_id: String, message: String, affinity_level: int, _affinity_score: int) -> void:
	_reply_received = true
	_reply_npc_id = npc_id
	_reply_message = message
	_reply_level = affinity_level

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
