extends Node

enum GameScene { OFFICE, STREET, UNDERGROUND, ANOMALY_SPACE, APARTMENT, RIFT_RUN }

var current_scene: GameScene = GameScene.APARTMENT
var _transitioning: bool = false
var _pending_scene: GameScene = GameScene.APARTMENT
var _previous_scene: GameScene = GameScene.APARTMENT

signal scene_changed(scene: GameScene)

var _fade_overlay: ColorRect = null
var _fade_layer: CanvasLayer = null
var _transition_panel: Control = null
var _transition_title: Label = null
var _transition_subtitle: Label = null
var _transition_hint: Label = null
var _transition_scan: ColorRect = null
var _transition_bar_bg: ColorRect = null
var _transition_bar_fill: ColorRect = null
var _persistent_nodes: Array[Node] = []

func _ready():
	print("[SceneManager] 初始化完成")
	_create_fade_overlay()

func _create_fade_overlay():
	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "SceneFadeOverlay"
	_fade_overlay.color = Color(0, 0, 0, 0)
	_fade_overlay.z_index = 100
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "FadeLayer"
	_fade_layer.layer = 100
	_fade_layer.add_child(_fade_overlay)
	add_child(_fade_layer)

	_transition_panel = Control.new()
	_transition_panel.name = "TransitionPanel"
	_transition_panel.visible = false
	_transition_panel.modulate = Color(1, 1, 1, 0)
	_transition_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_panel.z_index = 110
	_fade_layer.add_child(_transition_panel)

	_transition_scan = ColorRect.new()
	_transition_scan.name = "TransitionScan"
	_transition_scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_panel.add_child(_transition_scan)

	_transition_title = _make_transition_label(40, Color(0.92, 0.98, 1.0, 1.0))
	_transition_title.name = "TransitionTitle"
	_transition_panel.add_child(_transition_title)

	_transition_subtitle = _make_transition_label(19, Color(0.84, 0.93, 0.98, 1.0))
	_transition_subtitle.name = "TransitionSubtitle"
	_transition_panel.add_child(_transition_subtitle)

	_transition_hint = _make_transition_label(14, Color(0.66, 0.82, 0.88, 1.0))
	_transition_hint.name = "TransitionHint"
	_transition_panel.add_child(_transition_hint)

	_transition_bar_bg = ColorRect.new()
	_transition_bar_bg.name = "TransitionBarBg"
	_transition_bar_bg.color = Color(0.04, 0.08, 0.1, 0.9)
	_transition_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_panel.add_child(_transition_bar_bg)

	_transition_bar_fill = ColorRect.new()
	_transition_bar_fill.name = "TransitionBarFill"
	_transition_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_panel.add_child(_transition_bar_fill)

	var resize_callback := Callable(self, "_layout_transition_overlay")
	var viewport := get_viewport()
	if viewport and not viewport.size_changed.is_connected(resize_callback):
		viewport.size_changed.connect(resize_callback)

func _make_transition_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.035, 0.95))
	label.add_theme_constant_override("outline_size", 3)
	return label

func _prepare_transition_visuals(target: GameScene) -> void:
	if not _transition_panel:
		return
	var accent := _transition_accent(target)
	_layout_transition_overlay()
	_transition_title.text = _transition_title_for_scene(target)
	_transition_title.add_theme_color_override("font_color", accent.lightened(0.36))
	_transition_subtitle.add_theme_color_override("font_color", Color(0.86, 0.94, 0.98, 1.0))
	_transition_hint.add_theme_color_override("font_color", accent.lightened(0.2))
	_transition_subtitle.text = _transition_subtitle_for_scene(target)
	_transition_hint.text = "导航协议建立中"
	_transition_scan.color = Color(accent.r, accent.g, accent.b, 0.34)
	_transition_scan.position.x = -_transition_scan.size.x
	_transition_bar_fill.color = Color(accent.r, accent.g, accent.b, 0.95)
	_transition_bar_fill.size = Vector2(0.0, _transition_bar_bg.size.y)
	_transition_panel.visible = true
	_transition_panel.modulate = Color(1, 1, 1, 0)

func _layout_transition_overlay() -> void:
	if not _transition_panel:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_transition_panel.position = Vector2.ZERO
	_transition_panel.size = viewport_size

	var text_width: float = minf(760.0, maxf(320.0, viewport_size.x - 120.0))
	var center_x: float = viewport_size.x / 2.0
	var title_y: float = viewport_size.y * 0.39

	_transition_title.position = Vector2(center_x - text_width / 2.0, title_y)
	_transition_title.size = Vector2(text_width, 48.0)
	_transition_subtitle.position = Vector2(center_x - text_width / 2.0, title_y + 50.0)
	_transition_subtitle.size = Vector2(text_width, 30.0)
	_transition_hint.position = Vector2(center_x - text_width / 2.0, title_y + 112.0)
	_transition_hint.size = Vector2(text_width, 24.0)

	var bar_width: float = minf(460.0, maxf(240.0, viewport_size.x * 0.42))
	_transition_bar_bg.position = Vector2(center_x - bar_width / 2.0, title_y + 92.0)
	_transition_bar_bg.size = Vector2(bar_width, 4.0)
	_transition_bar_fill.position = _transition_bar_bg.position
	_transition_bar_fill.size.y = _transition_bar_bg.size.y

	_transition_scan.size = Vector2(maxf(140.0, viewport_size.x * 0.16), viewport_size.y)
	_transition_scan.position.y = 0.0

func _transition_scan_target_x() -> float:
	if not _transition_scan:
		return 0.0
	return get_viewport().get_visible_rect().size.x + _transition_scan.size.x

func _transition_overlay_color(scene: GameScene) -> Color:
	var accent := _transition_accent(scene)
	return Color(accent.r * 0.08, accent.g * 0.08, accent.b * 0.11, 0.94)

func _transition_accent(scene: GameScene) -> Color:
	match scene:
		GameScene.OFFICE:
			return Color(0.1, 0.9, 1.0, 1.0)
		GameScene.STREET:
			return Color(1.0, 0.45, 0.78, 1.0)
		GameScene.UNDERGROUND:
			return Color(0.24, 1.0, 0.76, 1.0)
		GameScene.ANOMALY_SPACE:
			return Color(0.76, 0.34, 1.0, 1.0)
		GameScene.APARTMENT:
			return Color(1.0, 0.78, 0.24, 1.0)
		GameScene.RIFT_RUN:
			return Color(1.0, 0.38, 0.3, 1.0)
		_:
			return Color(0.0, 0.9, 1.0, 1.0)

func _transition_title_for_scene(scene: GameScene) -> String:
	match scene:
		GameScene.OFFICE:
			return "接入办公室"
		GameScene.STREET:
			return "驶入街区"
		GameScene.UNDERGROUND:
			return "下行地下站台"
		GameScene.ANOMALY_SPACE:
			return "锁定异常空间"
		GameScene.APARTMENT:
			return "返回公寓"
		GameScene.RIFT_RUN:
			return "进入万界镶层"
		_:
			return "切换场景"

func _transition_subtitle_for_scene(scene: GameScene) -> String:
	match scene:
		GameScene.OFFICE:
			return "门禁认证 / 办公网络同步"
		GameScene.STREET:
			return "霓虹路网 / 行人密度重算"
		GameScene.UNDERGROUND:
			return "轨道信号 / 站台坐标接管"
		GameScene.ANOMALY_SPACE:
			return "裂隙坐标 / 异常场稳定"
		GameScene.APARTMENT:
			return "私人门禁 / 生活系统唤醒"
		GameScene.RIFT_RUN:
			return "裂隙协议 / 战斗层加载"
		_:
			return "导航协议 / 场景载入"

func register_persistent(node: Node):
	if not _persistent_nodes.has(node):
		_persistent_nodes.append(node)

func unregister_persistent(node: Node):
	_persistent_nodes.erase(node)

func transition_to(target: GameScene) -> void:
	if _transitioning:
		return
	_transitioning = true
	_pending_scene = target
	_prepare_transition_visuals(target)

	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game()

	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	for node in _persistent_nodes:
		if is_instance_valid(node) and node.get_parent():
			node.get_parent().remove_child(node)
			add_child(node)

	var fade_out = create_tween()
	fade_out.set_trans(Tween.TRANS_CUBIC)
	fade_out.set_ease(Tween.EASE_OUT)
	fade_out.tween_property(_fade_overlay, "color", _transition_overlay_color(target), 0.34)
	fade_out.parallel().tween_property(_transition_panel, "modulate:a", 1.0, 0.14)
	fade_out.parallel().tween_property(_transition_scan, "position:x", _transition_scan_target_x(), 0.46)
	fade_out.parallel().tween_property(_transition_bar_fill, "size:x", _transition_bar_bg.size.x, 0.46)
	fade_out.tween_interval(0.08)
	fade_out.tween_callback(_do_scene_change)

func _do_scene_change():
	_previous_scene = current_scene
	current_scene = _pending_scene

	var scene_path = _get_scene_path(_pending_scene)
	if not ResourceLoader.exists(scene_path):
		push_warning("[SceneManager] 场景不存在，回退到公寓: " + scene_path)
		current_scene = GameScene.APARTMENT
		_pending_scene = GameScene.APARTMENT
		scene_path = _get_scene_path(GameScene.APARTMENT)

	var err = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[SceneManager] 切换场景失败: %s (%d)" % [scene_path, err])
		if scene_path != _get_scene_path(GameScene.APARTMENT):
			current_scene = GameScene.APARTMENT
			_pending_scene = GameScene.APARTMENT
			get_tree().change_scene_to_file(_get_scene_path(GameScene.APARTMENT))

	await get_tree().process_frame
	await get_tree().process_frame

	var new_scene = get_tree().current_scene
	for node in _persistent_nodes:
		if is_instance_valid(node) and node.get_parent() == self:
			remove_child(node)
			if new_scene:
				new_scene.add_child(node)
	
	if has_node("/root/PetManager"):
		var pet = get_node("/root/PetManager").get_active_pet()
		if pet and is_instance_valid(pet):
			var player = get_tree().get_first_node_in_group("player")
			if player:
				pet.global_position = player.global_position + Vector2(-40, 20)

	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").rebuild_effects()

	_discover_current_area()
	scene_changed.emit(_pending_scene)

	_layout_transition_overlay()
	if _transition_hint:
		_transition_hint.text = "抵达 " + get_scene_name()

	var fade_in = create_tween()
	fade_in.set_trans(Tween.TRANS_CUBIC)
	fade_in.set_ease(Tween.EASE_IN_OUT)
	fade_in.tween_property(_fade_overlay, "color", Color(0, 0, 0, 0), 0.42)
	fade_in.parallel().tween_property(_transition_panel, "modulate:a", 0.0, 0.34)
	fade_in.parallel().tween_property(_transition_scan, "position:x", _transition_scan_target_x(), 0.34)
	fade_in.tween_callback(func():
		_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _transition_panel:
			_transition_panel.visible = false
		_transitioning = false
	)

func get_spawn_position() -> Vector2:
	match current_scene:
		GameScene.OFFICE:
			if _previous_scene == GameScene.STREET:
				return Vector2(640, 640)
			return Vector2(640, 550)
		GameScene.STREET:
			if _previous_scene == GameScene.APARTMENT:
				return Vector2(1100, 700)
			if _previous_scene == GameScene.UNDERGROUND:
				return Vector2(520, 760)
			if _previous_scene == GameScene.ANOMALY_SPACE:
				return Vector2(520, 760)
			return Vector2(836, 700)
		GameScene.UNDERGROUND:
			if _previous_scene == GameScene.ANOMALY_SPACE:
				return Vector2(836, 520)
			return Vector2(836, 700)
		GameScene.ANOMALY_SPACE:
			return Vector2(836, 700)
		GameScene.APARTMENT:
			return Vector2(836, 700)
		GameScene.RIFT_RUN:
			return Vector2(836, 620)
		_:
			return Vector2(640, 600)

func is_transitioning() -> bool:
	return _transitioning

func get_current_area_id() -> String:
	return get_area_id_for_scene(current_scene)

func get_area_id_for_scene(scene: GameScene) -> String:
	match scene:
		GameScene.OFFICE:
			return "office"
		GameScene.STREET:
			return "street"
		GameScene.UNDERGROUND:
			return "underground"
		GameScene.ANOMALY_SPACE:
			return "anomaly"
		GameScene.APARTMENT:
			return "apartment"
		_:
			return ""

func transition_to_area(area_id: String) -> bool:
	if _transitioning:
		return false
	var target: GameScene = current_scene
	match area_id:
		"office":
			target = GameScene.OFFICE
		"street":
			target = GameScene.STREET
		"underground":
			target = GameScene.UNDERGROUND
		"anomaly":
			target = GameScene.ANOMALY_SPACE
		"apartment":
			target = GameScene.APARTMENT
		_:
			return false
	if target == current_scene:
		return false
	transition_to(target)
	return true

func _discover_current_area() -> void:
	var area_id := get_current_area_id()
	if area_id.is_empty():
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("discover_area"):
		gm.discover_area(area_id)

func _get_scene_path(scene: GameScene) -> String:
	match scene:
		GameScene.OFFICE:
			return "res://scenes/main.tscn"
		GameScene.STREET:
			return "res://scenes/street.tscn"
		GameScene.UNDERGROUND:
			return "res://scenes/underground.tscn"
		GameScene.ANOMALY_SPACE:
			return "res://scenes/anomaly_space.tscn"
		GameScene.APARTMENT:
			return "res://scenes/apartment.tscn"
		GameScene.RIFT_RUN:
			return "res://scenes/rift_run.tscn"
		_:
			return "res://scenes/apartment.tscn"

func is_office() -> bool:
	return current_scene == GameScene.OFFICE

func is_street() -> bool:
	return current_scene == GameScene.STREET

func is_apartment() -> bool:
	return current_scene == GameScene.APARTMENT

func is_underground() -> bool:
	return current_scene == GameScene.UNDERGROUND

func is_anomaly_space() -> bool:
	return current_scene == GameScene.ANOMALY_SPACE

func is_rift_run() -> bool:
	return current_scene == GameScene.RIFT_RUN

func get_scene_name() -> String:
	match current_scene:
		GameScene.OFFICE: return "办公室"
		GameScene.STREET: return "街区"
		GameScene.UNDERGROUND: return "地下站台"
		GameScene.ANOMALY_SPACE: return "异常空间"
		GameScene.APARTMENT: return "公寓"
		GameScene.RIFT_RUN: return "万界镶层"
		_: return "未知"
