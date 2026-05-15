extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var avatar_container: Panel = $Panel/AvatarContainer
@onready var avatar_texture: TextureRect = $Panel/AvatarContainer/AvatarTexture
@onready var name_label: Label = $Panel/NameLabel
@onready var title_label: Label = $Panel/TitleLabel
@onready var affinity_container: HBoxContainer = $Panel/AffinityContainer
@onready var hearts_label: Label = $Panel/AffinityContainer/Hearts
@onready var dialogue_text: RichTextLabel = $Panel/DialogueText
@onready var input_container: HBoxContainer = $Panel/InputContainer
@onready var input_field: LineEdit = $Panel/InputContainer/PlayerInput
@onready var send_button: Button = $Panel/InputContainer/SendButton
@onready var history_button: Button = $Panel/InputContainer/HistoryButton
@onready var close_button: Button = $Panel/CloseButton
@onready var history_panel: Panel = $HistoryPanel
@onready var history_text: RichTextLabel = $HistoryPanel/HistoryScroll/HistoryText
@onready var close_history_button: Button = $HistoryPanel/CloseHistoryButton

var api_client: Node = null
var current_npc_id: String = ""
var current_npc_display_name: String = ""
var current_affinity_level: int = 1
var current_affinity_score: int = 0
var dialogue_history: Array = []
var all_histories: Dictionary = {}
var is_waiting_for_input: bool = false
var pending_npc_response: String = ""

var name_map = {
	"zhang_san": "张三",
	"li_si": "李四",
	"wang_wu": "王五",
	"chen_xi": "陈曦",
	"zhao_lin": "赵霖",
	"sun_yue": "孙悦",
	"liu_feng": "刘风",
	"he_zhen": "何真",
}

var title_map = {
	"zhang_san": "Python工程师",
	"li_si": "产品经理",
	"wang_wu": "UI设计师",
	"chen_xi": "咖啡店老板",
	"zhao_lin": "黑市信息贩子",
	"sun_yue": "异常现象研究员",
	"liu_feng": "赛博义体技师",
	"he_zhen": "AI系统管理员",
}

var avatar_map = {
	"zhang_san": "res://assets/characters/avatars/张三头像.png",
	"li_si": "res://assets/characters/avatars/李四头像.png",
	"wang_wu": "res://assets/characters/avatars/王五头像.png",
	"chen_xi": "res://assets/characters/avatars/陈曦头像.png",
	"zhao_lin": "res://assets/characters/avatars/赵霖头像.png",
	"sun_yue": "res://assets/characters/avatars/孙悦头像.png",
	"liu_feng": "res://assets/characters/avatars/刘风头像.png",
	"he_zhen": "res://assets/characters/avatars/何真头像.png",
}

var npc_color_map = {
	"zhang_san": "#4ECDC4",
	"li_si": "#FFE66D",
	"wang_wu": "#FF6B9D",
	"chen_xi": "#6C5CE7",
	"zhao_lin": "#E17055",
	"sun_yue": "#A29BFE",
	"liu_feng": "#FDCB6E",
	"he_zhen": "#00B894",
}

var avatar_textures: Dictionary = {}
var loading_avatars: Dictionary = {}

var _typewriter_timer: Timer = null
var _typewriter_full_text: String = ""
var _typewriter_index: int = 0
var _typewriter_active: bool = false
var _typewriter_prefix: String = ""

func _ready():
	print("[DialogueUI] 初始化")
	visible = false
	panel.visible = false
	history_panel.visible = false
	dialogue_text.visible = true
	
	if send_button:
		send_button.pressed.connect(_on_send_button_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if history_button:
		history_button.pressed.connect(_on_history_button_pressed)
	if close_history_button:
		close_history_button.pressed.connect(_on_close_history_button_pressed)
	if input_field:
		input_field.text_submitted.connect(_on_text_submitted)
	
	api_client = get_node_or_null("/root/APIClient")
	if api_client:
		api_client.chat_response_received.connect(on_chat_response_received)
		api_client.chat_error.connect(on_chat_error)
		api_client.affinity_received.connect(on_affinity_received)
		api_client.history_received.connect(on_history_received)
		api_client.affinity_level_up.connect(_on_affinity_level_up)
	
	_start_avatar_loading()
	
	var groups = get_groups()
	print("[DialogueUI] groups: ", groups)
	
	_setup_button_hover_effects()
	_apply_theme()
	_apply_fonts()
	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)
	print("[DialogueUI] 初始化完成")

func _on_phase_changed(_new_phase):
	_apply_theme()

func _apply_theme():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()

	var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		var dup = style.duplicate() as StyleBoxFlat
		dup.bg_color = t["panel_bg"]
		dup.border_color = t["panel_border"]
		dup.shadow_color = t["panel_shadow"]
		panel.add_theme_stylebox_override("panel", dup)

	var avatar_style = avatar_container.get_theme_stylebox("panel") as StyleBoxFlat
	if avatar_style:
		var adup = avatar_style.duplicate() as StyleBoxFlat
		adup.border_color = t["border_accent"]
		adup.shadow_color = Color(t["border_accent"].r, t["border_accent"].g, t["border_accent"].b, 0.3)
		avatar_container.add_theme_stylebox_override("panel", adup)

	dialogue_text.add_theme_color_override("default_color", t["text_color"])
	if tm.is_day():
		dialogue_text.add_theme_color_override("outline_color", Color(0.1, 0.08, 0.04, 0.3))
		dialogue_text.add_theme_constant_override("outline_size", 1)
	else:
		dialogue_text.add_theme_color_override("outline_color", Color(0, 0, 0, 0.4))
		dialogue_text.add_theme_constant_override("outline_size", 2)

func _apply_fonts():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	tm.apply_font_to_label(name_label, 26)
	tm.apply_font_to_label(title_label, 16)
	tm.apply_font_to_rich_text(dialogue_text, 19)
	tm.apply_font_to_line_edit(input_field, 17)
	tm.apply_font_to_button(send_button, 17)
	tm.apply_font_to_button(history_button, 17)
	tm.apply_font_to_button(close_button, 26)
	tm.apply_font_to_label(hearts_label, 20)

func _setup_button_hover_effects():
	var buttons = [send_button, history_button, close_button, close_history_button]
	for btn in buttons:
		if btn:
			btn.mouse_entered.connect(_on_button_hover.bind(btn))
			btn.mouse_exited.connect(_on_button_hover_end.bind(btn))
			btn.button_down.connect(_on_button_press.bind(btn))
			btn.button_up.connect(_on_button_release.bind(btn))

func _on_button_hover(btn: Button):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_hover_end(btn: Button):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_press(btn: Button):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.05)

func _on_button_release(btn: Button):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.05)

func _input(event: InputEvent):
	if visible and _typewriter_active:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
				_skip_typewriter()
		elif event is InputEventKey and event.pressed:
			if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_skip_typewriter()

func _skip_typewriter():
	if not _typewriter_active or not dialogue_text:
		return
	
	_typewriter_active = false
	if _typewriter_timer:
		_typewriter_timer.stop()
	
	dialogue_text.text = _typewriter_prefix + _typewriter_full_text

func _start_avatar_loading():
	for npc_id in avatar_map.keys():
		var path: String = avatar_map[npc_id]
		if ResourceLoader.exists(path):
			ResourceLoader.load_threaded_request(path, "Texture2D")
			loading_avatars[npc_id] = path
			print("[DialogueUI] 开始异步加载头像: " + path)
		else:
			print("[DialogueUI] 头像资源不存在，生成占位图: " + path)
			_generate_placeholder_avatar(npc_id)

func _generate_placeholder_avatar(npc_id: String) -> void:
	if avatar_textures.has(npc_id):
		return
	var color_str = npc_color_map.get(npc_id, "#CCCCCC")
	var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var bg = Color.html(color_str)
	bg.a = 0.3
	img.fill(bg)
	var border = Color.html(color_str)
	img.fill_rect(Rect2i(0, 0, 128, 4), border)
	img.fill_rect(Rect2i(0, 124, 128, 4), border)
	img.fill_rect(Rect2i(0, 0, 4, 128), border)
	img.fill_rect(Rect2i(124, 0, 4, 128), border)
	var name_text = name_map.get(npc_id, npc_id)
	print("[DialogueUI] 为 " + name_text + " 生成占位头像，颜色: " + color_str)
	var texture = ImageTexture.create_from_image(img)
	avatar_textures[npc_id] = texture

func _process(_delta: float):
	if visible and panel and panel.visible:
		var t = _get_current_theme()
		var alpha = 0.5 + sin(Time.get_ticks_msec() / 1000.0 * 1.5) * 0.2
		var accent = t.get("border_accent", Color(0, 0.93, 1))
		var style = panel.get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			style.border_color = Color(accent.r, accent.g, accent.b, alpha)
	for npc_id in loading_avatars.keys():
		var path: String = loading_avatars[npc_id]
		var status = ResourceLoader.load_threaded_get_status(path)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var texture = ResourceLoader.load_threaded_get(path)
				if texture is Texture2D:
					avatar_textures[npc_id] = texture
					print("[DialogueUI] 头像加载完成: " + path)
				loading_avatars.erase(npc_id)
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				print("[DialogueUI] 头像加载失败: " + path)
				loading_avatars.erase(npc_id)
				break

func _set_avatar(npc_id: String):
	if avatar_textures.has(npc_id):
		avatar_texture.texture = avatar_textures[npc_id]
	else:
		print("[DialogueUI] 头像尚未加载完成: " + npc_id)
		avatar_texture.texture = null

func on_chat_error(error_message: String):
	add_dialogue_line("[color=#FF6B6B]错误:[/color] " + error_message)
	send_button.disabled = false
	send_button.text = "发送"
	input_field.grab_focus()

func on_affinity_received(npc_id: String, affinity_level: int, affinity_score: int):
	if npc_id == current_npc_id:
		var old_level = current_affinity_level
		current_affinity_level = affinity_level
		current_affinity_score = affinity_score
		update_affinity_display()
		if old_level != 0 and affinity_level != old_level:
			var npc_display = name_map.get(npc_id, npc_id)
			_log_event("❤️ " + npc_display + "好感度提升至Lv." + str(affinity_level))

func on_history_received(npc_id: String, history: Array):
	if npc_id == current_npc_id and history.size() > 0:
		if dialogue_history.size() == 0:
			dialogue_history = history
			all_histories[npc_id] = history
			dialogue_text.text = ""
			for entry in dialogue_history:
				if entry["role"] == "user":
					dialogue_text.text += "[color=#4ECDC4]玩家:[/color] " + entry["content"] + "\n"
				elif entry["role"] == "assistant":
					dialogue_text.text += "[color=#FFE66D]" + current_npc_display_name + ":[/color] " + entry["content"] + "\n"
			print("[DialogueUI] 从后端加载了 " + str(history.size()) + " 条历史记录")

var _affinity_level_names: Dictionary = {
	1: "陌生人",
	2: "认识",
	3: "熟人",
	4: "朋友",
	5: "挚友",
}

func update_affinity_display():
	var full_hearts = mini(current_affinity_level, 5)
	var empty_hearts = maxi(0, 5 - full_hearts)
	var hearts_text = ""
	for i in range(full_hearts):
		hearts_text += "❤️"
	for i in range(empty_hearts):
		hearts_text += "☆"
	var level_name = _affinity_level_names.get(current_affinity_level, "未知")
	hearts_label.text = hearts_text + " Lv." + str(current_affinity_level) + " " + level_name

func _on_affinity_level_up(npc_id: String, new_level: int):
	if npc_id == current_npc_id and hearts_label:
		current_affinity_level = new_level
		update_affinity_display()
		hearts_label.modulate = Color(1, 1, 0, 1)
		hearts_label.scale = Vector2(1.3, 1.3)
		var tween = create_tween()
		tween.tween_property(hearts_label, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.parallel().tween_property(hearts_label, "modulate", Color(1, 1, 1, 1), 0.5)

func start_dialogue(npc_id: String):
	print("[DialogueUI] 开始对话: " + npc_id)
	
	_save_current_history()
	
	current_npc_id = npc_id
	var npc_color = npc_color_map.get(npc_id, "#FFE66D")
	current_npc_display_name = name_map.get(npc_id, npc_id)

	_log_event("💬 开始与" + current_npc_display_name + "对话")
	
	name_label.text = current_npc_display_name
	name_label.add_theme_color_override("font_color", Color.html(npc_color))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0.94, 1, 0.5))
	name_label.add_theme_constant_override("shadow_offset_x", 0)
	name_label.add_theme_constant_override("shadow_offset_y", 0)
	name_label.add_theme_constant_override("shadow_outline_size", 4)
	title_label.text = title_map.get(npc_id, "")
	
	_set_avatar(npc_id)
	
	current_affinity_level = 0
	current_affinity_score = 0
	hearts_label.text = "加载中..."
	
	if api_client:
		api_client.get_affinity(current_npc_id, "玩家")
		api_client.get_dialogue_history(current_npc_id)
	
	if all_histories.has(npc_id):
		dialogue_history = all_histories[npc_id]
	else:
		dialogue_history = []
	
	dialogue_text.text = ""
	for entry in dialogue_history:
		if entry["role"] == "player":
			dialogue_text.text += "[color=#4ECDC4]玩家:[/color] " + entry["content"] + "\n"
		elif entry["role"] == "npc":
			dialogue_text.text += "[color=" + npc_color + "]" + current_npc_display_name + ":[/color] " + entry["content"] + "\n"
	
	add_dialogue_line_typewriter("[color=#FFFFFF]与 " + current_npc_display_name + " 的对话继续...[/color]", 0.02)
	
	visible = true
	panel.visible = true
	panel.anchor_top = 1.0
	panel.offset_top = 0
	var slide_tween = create_tween()
	slide_tween.set_ease(Tween.EASE_OUT)
	slide_tween.set_trans(Tween.TRANS_CUBIC)
	slide_tween.tween_property(panel, "anchor_top", 0.65, 0.3)
	slide_tween.parallel().tween_property(panel, "offset_top", 0.0, 0.3)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_interacting"):
		player.set_interacting(true)
	
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc.npc_name == npc_id:
			npc.is_interacting = true
			print("[DialogueUI] NPC " + npc_id + " 开始交互")
			break
	
	send_button.focus_mode = Control.FOCUS_NONE
	close_button.focus_mode = Control.FOCUS_NONE
	history_button.focus_mode = Control.FOCUS_NONE
	close_history_button.focus_mode = Control.FOCUS_NONE
	
	await get_tree().process_frame
	await get_tree().process_frame
	input_field.text = ""
	input_field.editable = true
	input_field.grab_focus()
	input_field.caret_column = 0
	is_waiting_for_input = true
	print("[DialogueUI] 对话框已显示")

func _save_current_history():
	if not current_npc_id.is_empty() and dialogue_history.size() > 0:
		all_histories[current_npc_id] = dialogue_history.duplicate()

func hide_dialogue():
	var npc_id_to_reset = current_npc_id
	var npc_display = current_npc_display_name
	
	_save_current_history()
	
	visible = false
	panel.visible = false
	history_panel.visible = false
	current_npc_id = ""
	current_npc_display_name = ""
	is_waiting_for_input = false
	pending_npc_response = ""

	if npc_display != "":
		_log_event("👋 结束与" + npc_display + "对话")

	if not npc_id_to_reset.is_empty():
		for npc in get_tree().get_nodes_in_group("npcs"):
			if npc.npc_name == npc_id_to_reset:
				npc.is_interacting = false
				print("[DialogueUI] 重置NPC交互状态: " + npc_id_to_reset)
				break

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_interacting"):
		player.set_interacting(false)

	input_field.release_focus()

	print("[DialogueUI] 对话框已关闭")

func _on_send_button_pressed():
	AudioManager.play_ui_click()
	send_message()

func _on_close_button_pressed():
	AudioManager.play_ui_click()
	if close_button.text == "×":
		close_button.text = "确认?"
		await get_tree().create_timer(1.5).timeout
		if close_button.text == "确认?":
			close_button.text = "×"
	elif close_button.text == "确认?":
		close_button.text = "×"
		AudioManager.play_close()
		hide_dialogue()

func _on_history_button_pressed():
	AudioManager.play_ui_click()
	show_history_panel()

func _on_close_history_button_pressed():
	AudioManager.play_ui_click()
	history_panel.visible = false
	input_field.grab_focus()

func _on_text_submitted(_text: String):
	send_message()

func send_message():
	AudioManager.play_send_message()
	var message = input_field.text.strip_edges()
	if message.is_empty() or current_npc_id.is_empty():
		return

	add_dialogue_line("[color=#4ECDC4]玩家:[/color] " + message)
	dialogue_history.append({"role": "player", "content": message})
	LogPanel.add_dialogue_log("玩家", message, "player")
	print("[DialogueUI] dialogue_history append player, size: ", dialogue_history.size(), " content: ", message)
	input_field.text = ""

	send_button.disabled = true
	send_button.text = "发送中..."

	print("[DialogueUI] 发送消息到后端: " + current_npc_id + " - " + message)

	if api_client:
		print("[DialogueUI] 调用 api_client.send_chat")
		api_client.send_chat(current_npc_id, message)
		if has_node("/root/QuestManager"):
			get_node("/root/QuestManager").on_dialogue_with_npc(current_npc_id)
	else:
		send_button.disabled = false
		send_button.text = "发送"
		add_dialogue_line("[color=#FF6B6B]警告:[/color] 无法连接到后端服务")

func on_chat_response_received(npc_id: String, response: String, affinity_level: int = 1, affinity_score: int = 0):
	AudioManager.play_receive_message()
	if npc_id == current_npc_id:
		current_affinity_level = affinity_level
		current_affinity_score = affinity_score
		update_affinity_display()
		
		var npc_color = npc_color_map.get(npc_id, "#FFE66D")
		add_dialogue_line_typewriter("[color=" + npc_color + "]" + current_npc_display_name + ":[/color] " + response, 0.04)
		dialogue_history.append({"role": "npc", "content": response})
		LogPanel.add_dialogue_log(current_npc_display_name, response, current_npc_id)
		print("[DialogueUI] dialogue_history append npc, size: ", dialogue_history.size(), " content: ", response)
		
		pending_npc_response = ""
		is_waiting_for_input = false
		send_button.text = "发送"
		send_button.disabled = false
		input_field.editable = true
		input_field.grab_focus()

func add_dialogue_line(line: String):
	if dialogue_text:
		if dialogue_text.text.length() > 0:
			dialogue_text.text += "\n"
		dialogue_text.text += line
		await get_tree().process_frame

func add_dialogue_line_typewriter(line: String, speed: float = 0.04):
	if not dialogue_text:
		return

	if _typewriter_active:
		_skip_typewriter()

	_typewriter_prefix = dialogue_text.text
	if _typewriter_prefix.length() > 0:
		_typewriter_prefix += "\n"

	_typewriter_active = true
	_typewriter_full_text = line
	_typewriter_index = 0

	if _typewriter_timer:
		_typewriter_timer.queue_free()

	_typewriter_timer = Timer.new()
	_typewriter_timer.wait_time = speed
	_typewriter_timer.one_shot = false
	add_child(_typewriter_timer)
	_typewriter_timer.timeout.connect(_typewriter_step)
	_typewriter_timer.start()

func _typewriter_step():
	if _typewriter_index >= _typewriter_full_text.length():
		_typewriter_active = false
		_typewriter_timer.queue_free()
		return

	_typewriter_index += 1
	var displayed_text = _typewriter_full_text.substr(0, _typewriter_index)
	dialogue_text.text = _typewriter_prefix + displayed_text

func _strip_bbcode(text: String) -> String:
	var result = text
	var regex = RegEx.new()
	regex.compile("\\[/?color[^\\]]*\\]")
	result = regex.sub(result, "", true)
	return result

func show_history_panel():
	print("[DialogueUI] === show_history_panel called ===")
	print("[DialogueUI] dialogue_history size: ", dialogue_history.size())
	print("[DialogueUI] current_npc_display_name: ", current_npc_display_name)
	
	history_text.text = ""
	var history_content = ""
	for entry in dialogue_history:
		if entry["role"] == "player":
			history_content += "[color=#4ECDC4]玩家:[/color] " + entry["content"] + "\n\n"
		else:
			history_content += "[color=#FFE66D]" + current_npc_display_name + ":[/color] " + entry["content"] + "\n\n"
	
	history_text.text = history_content
	print("[DialogueUI] history_text text length: ", history_text.text.length())
	print("[DialogueUI] history_text visible: ", history_text.visible)
	print("[DialogueUI] history_panel visible: ", history_panel.visible)
	history_panel.visible = true
	print("[DialogueUI] history_panel set to visible")

func _log_event(message: String):
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)

func _get_current_theme() -> Dictionary:
	if has_node("/root/UIThemeManager"):
		return get_node("/root/UIThemeManager").get_theme()
	return {"border_accent": Color(0, 0.93, 1)}
