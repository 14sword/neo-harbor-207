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
var dialogue_director: Node = null
var current_npc_id: String = ""
var current_npc_display_name: String = ""
var current_affinity_level: int = 1
var current_affinity_score: int = 0
var dialogue_history: Array = []
var all_histories: Dictionary = {}
var is_waiting_for_input: bool = false
var pending_npc_response: String = ""
var is_free_chat_sending: bool = false
var current_dialogue_mode: String = "story"
var current_director_node: Dictionary = {}
var mode_container: HBoxContainer = null
var choice_scroll: ScrollContainer = null
var choice_container: VBoxContainer = null
var _mode_buttons: Dictionary = {}

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
	"zhang_san": "res://assets/characters/npcs/generated_portraits/zhang_san.webp",
	"li_si": "res://assets/characters/npcs/generated_portraits/li_si.webp",
	"wang_wu": "res://assets/characters/npcs/generated_portraits/wang_wu.webp",
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

	dialogue_director = get_node_or_null("/root/DialogueDirector")
	_create_director_controls()
	
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
	for btn in _mode_buttons.values():
		tm.apply_font_to_button(btn, 14)

func _setup_button_hover_effects():
	var buttons = [send_button, history_button, close_button, close_history_button]
	for btn in buttons:
		if btn:
			btn.mouse_entered.connect(_on_button_hover.bind(btn))
			btn.mouse_exited.connect(_on_button_hover_end.bind(btn))
			btn.button_down.connect(_on_button_press.bind(btn))
			btn.button_up.connect(_on_button_release.bind(btn))

func _create_director_controls() -> void:
	if mode_container != null:
		return

	mode_container = HBoxContainer.new()
	mode_container.name = "ModeContainer"
	mode_container.anchor_left = 0.0
	mode_container.anchor_top = 0.0
	mode_container.anchor_right = 1.0
	mode_container.anchor_bottom = 0.0
	mode_container.offset_left = 150.0
	mode_container.offset_top = 76.0
	mode_container.offset_right = -20.0
	mode_container.offset_bottom = 110.0
	mode_container.add_theme_constant_override("separation", 8)
	panel.add_child(mode_container)

	var modes = [
		{"id": "story", "label": "剧情"},
		{"id": "daily", "label": "日常"},
		{"id": "affinity", "label": "好感"},
		{"id": "free", "label": "自由聊"},
	]
	if dialogue_director and dialogue_director.has_method("get_available_modes"):
		modes = dialogue_director.get_available_modes("")
	for mode in modes:
		var btn = Button.new()
		btn.text = str(mode.get("label", mode.get("id", "")))
		btn.custom_minimum_size = Vector2(88, 32)
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		mode_container.add_child(btn)
		_mode_buttons[str(mode.get("id", ""))] = btn
		btn.pressed.connect(_on_mode_button_pressed.bind(str(mode.get("id", ""))))

	choice_scroll = ScrollContainer.new()
	choice_scroll.name = "ChoiceScroll"
	choice_scroll.anchor_left = 0.0
	choice_scroll.anchor_top = 1.0
	choice_scroll.anchor_right = 1.0
	choice_scroll.anchor_bottom = 1.0
	choice_scroll.offset_left = 150.0
	choice_scroll.offset_top = -122.0
	choice_scroll.offset_right = -20.0
	choice_scroll.offset_bottom = -62.0
	choice_scroll.visible = false
	panel.add_child(choice_scroll)

	choice_container = VBoxContainer.new()
	choice_container.name = "ChoiceContainer"
	choice_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_container.add_theme_constant_override("separation", 6)
	choice_scroll.add_child(choice_container)

	if dialogue_text:
		dialogue_text.offset_top = 116.0
		dialogue_text.offset_bottom = -132.0

	_refresh_mode_buttons()

func _refresh_mode_buttons() -> void:
	for mode in _mode_buttons:
		var btn: Button = _mode_buttons[mode]
		var active = mode == current_dialogue_mode
		btn.disabled = false
		btn.add_theme_stylebox_override("normal", _make_mode_button_style(active, false))
		btn.add_theme_stylebox_override("hover", _make_mode_button_style(active, true))
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1) if active else Color(0.78, 0.86, 0.94, 1))

func _make_mode_button_style(active: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var base := Color(0.12, 0.18, 0.28, 0.9)
	var border := Color(0.0, 0.94, 1.0, 0.45)
	if active:
		base = Color(0.0, 0.42, 0.56, 0.95)
		border = Color(0.0, 0.94, 1.0, 0.95)
	elif hover:
		base = Color(0.16, 0.25, 0.36, 0.95)
		border = Color(0.0, 0.94, 1.0, 0.72)
	style.bg_color = base
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _make_choice_button_style(hover: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.12, 0.18, 0.92) if not hover else Color(0.12, 0.2, 0.28, 0.96)
	style.border_color = Color(0.0, 0.94, 1.0, 0.36) if not hover else Color(0.0, 0.94, 1.0, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

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

func _on_mode_button_pressed(mode: String) -> void:
	if current_npc_id.is_empty():
		return
	current_dialogue_mode = mode
	_refresh_mode_buttons()
	_update_input_mode()
	if mode == "free":
		_clear_choices()
		input_field.grab_focus()
		return
	_show_director_entry(mode)

func _show_director_entry(mode: String) -> void:
	if not dialogue_director or not dialogue_director.has_method("get_entry_node"):
		return
	var node: Dictionary = dialogue_director.get_entry_node(current_npc_id, mode)
	_show_director_node(node, true)

func _show_director_node(node: Dictionary, show_text: bool) -> void:
	current_director_node = node
	if node.is_empty():
		_clear_choices()
		return
	if dialogue_director and dialogue_director.has_method("mark_node_seen"):
		dialogue_director.mark_node_seen(current_npc_id, str(node.get("id", "")))
	var node_text := str(node.get("text", ""))
	if show_text and not node_text.is_empty() and not _history_ends_with("npc", node_text):
		_append_npc_line(node_text, true)
	_render_choices(node.get("choices", []))

func _render_choices(choices: Array) -> void:
	_clear_choices()
	if current_dialogue_mode == "free" or not choice_container:
		return
	if choice_scroll:
		choice_scroll.visible = true

	if choices.is_empty():
		var back_btn := _make_choice_button("返回话题")
		back_btn.pressed.connect(_show_director_entry.bind(current_dialogue_mode))
		choice_container.add_child(back_btn)
		return

	for choice in choices:
		if not (choice is Dictionary):
			continue
		var choice_id := str(choice.get("id", ""))
		var text := str(choice.get("text", "继续"))
		var btn := _make_choice_button(text)
		btn.pressed.connect(_on_choice_pressed.bind(choice_id))
		choice_container.add_child(btn)

func _make_choice_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 34)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _make_choice_button_style(false))
	btn.add_theme_stylebox_override("hover", _make_choice_button_style(true))
	btn.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 1.0))
	if has_node("/root/UIThemeManager"):
		get_node("/root/UIThemeManager").apply_font_to_button(btn, 15)
	return btn

func _clear_choices() -> void:
	if choice_container:
		for child in choice_container.get_children():
			child.queue_free()
	if choice_scroll:
		choice_scroll.visible = false

func _on_choice_pressed(choice_id: String) -> void:
	if current_director_node.is_empty() or not dialogue_director:
		return
	AudioManager.play_ui_click()
	var node_id := str(current_director_node.get("id", ""))
	var result: Dictionary = dialogue_director.select_choice(current_npc_id, node_id, choice_id)
	if result.is_empty():
		return

	var player_text := str(result.get("player_text", ""))
	if not player_text.is_empty():
		_append_player_line(player_text)
	if has_node("/root/QuestManager"):
		get_node("/root/QuestManager").on_dialogue_with_npc(current_npc_id)

	var npc_text := str(result.get("npc_text", ""))
	var rewards: Array = result.get("rewards", [])
	if not rewards.is_empty():
		npc_text += "\n[color=#8FFFEA]获得：" + "，".join(rewards) + "[/color]"
	if not npc_text.is_empty():
		_append_npc_line(npc_text, true)

	var next_node: Dictionary = result.get("next_node", {})
	if not next_node.is_empty():
		_show_director_node(next_node, true)
	elif bool(result.get("close", false)):
		hide_dialogue()
	elif current_dialogue_mode == "story" or current_dialogue_mode == "affinity":
		_show_director_entry(current_dialogue_mode)
	else:
		_render_choices(current_director_node.get("choices", []))

func _append_player_line(message: String) -> void:
	add_dialogue_line("[color=#4ECDC4]玩家:[/color] " + message)
	dialogue_history.append({"role": "player", "content": message})
	LogPanel.add_dialogue_log("玩家", message, "player")

func _append_npc_line(response: String, typewriter: bool = true) -> void:
	var npc_color = npc_color_map.get(current_npc_id, "#FFE66D")
	var line = "[color=" + npc_color + "]" + current_npc_display_name + ":[/color] " + response
	if typewriter:
		add_dialogue_line_typewriter(line, 0.04)
	else:
		add_dialogue_line(line)
	dialogue_history.append({"role": "npc", "content": response})
	LogPanel.add_dialogue_log(current_npc_display_name, _strip_bbcode(response), current_npc_id)

func _history_ends_with(role: String, content: String) -> bool:
	if dialogue_history.is_empty():
		return false
	var last_entry = dialogue_history[dialogue_history.size() - 1]
	if not (last_entry is Dictionary):
		return false
	var last_role := str(last_entry.get("role", ""))
	var normalized_role := "player" if last_role == "user" else ("npc" if last_role == "assistant" else last_role)
	return normalized_role == role and str(last_entry.get("content", "")) == content

func _update_input_mode() -> void:
	var is_free := current_dialogue_mode == "free"
	if input_field:
		input_field.visible = true
		input_field.editable = not is_free_chat_sending
		input_field.placeholder_text = "自由输入你想说的话..."
	if send_button:
		send_button.visible = true
		send_button.disabled = is_free_chat_sending
		if not is_free_chat_sending:
			send_button.text = "发送"
	if history_button:
		history_button.visible = true
	if choice_scroll:
		choice_scroll.visible = not is_free and not current_director_node.is_empty()

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
		if entry["role"] == "player" or entry["role"] == "user":
			dialogue_text.text += "[color=#4ECDC4]玩家:[/color] " + entry["content"] + "\n"
		elif entry["role"] == "npc" or entry["role"] == "assistant":
			dialogue_text.text += "[color=" + npc_color + "]" + current_npc_display_name + ":[/color] " + entry["content"] + "\n"
	
	current_dialogue_mode = "story" if dialogue_director else "free"
	current_director_node = {}
	_clear_choices()
	_refresh_mode_buttons()
	_update_input_mode()
	
	visible = true
	panel.visible = true
	panel.anchor_top = 1.0
	panel.offset_top = 0
	var slide_tween = create_tween()
	slide_tween.set_ease(Tween.EASE_OUT)
	slide_tween.set_trans(Tween.TRANS_CUBIC)
	slide_tween.tween_property(panel, "anchor_top", 0.5, 0.3)
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
	if dialogue_director:
		_show_director_entry(current_dialogue_mode)
	else:
		add_dialogue_line_typewriter("[color=#FFFFFF]与 " + current_npc_display_name + " 的对话继续...[/color]", 0.02)
	if current_dialogue_mode == "free":
		input_field.text = ""
		input_field.editable = true
		input_field.grab_focus()
		input_field.caret_column = 0
	else:
		input_field.text = ""
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
	is_free_chat_sending = false
	current_director_node = {}
	current_dialogue_mode = "story"
	_clear_choices()

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
	if is_free_chat_sending:
		return
	AudioManager.play_send_message()
	var message = input_field.text.strip_edges()
	if message.is_empty() or current_npc_id.is_empty():
		return

	_append_player_line(message)
	print("[DialogueUI] dialogue_history append player, size: ", dialogue_history.size(), " content: ", message)
	input_field.text = ""

	is_free_chat_sending = true
	send_button.disabled = true
	send_button.text = "发送中..."
	input_field.editable = false

	print("[DialogueUI] 发送消息到后端: " + current_npc_id + " - " + message)

	if api_client:
		print("[DialogueUI] 调用 api_client.send_chat")
		api_client.send_chat(current_npc_id, message)
		if has_node("/root/QuestManager"):
			get_node("/root/QuestManager").on_dialogue_with_npc(current_npc_id)
	else:
		is_free_chat_sending = false
		_update_input_mode()
		var fallback = "远端暂时没有回应，但本地对话仍然可用。"
		if dialogue_director and dialogue_director.has_method("get_free_chat_fallback"):
			fallback = dialogue_director.get_free_chat_fallback(current_npc_id, message)
		_append_npc_line(fallback, true)

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
		is_free_chat_sending = false
		_update_input_mode()
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
		if entry["role"] == "player" or entry["role"] == "user":
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
