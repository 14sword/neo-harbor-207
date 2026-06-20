extends CanvasLayer

const MAP_TEXTURE_PATH := "res://assets/ui/map/cyber_town_overview.webp"
const CURRENT_BEACON_PATH := "res://assets/ui/map/current_beacon.png"
const LOCKED_MARKER_PATH := "res://assets/ui/map/locked.png"
const PANEL_MARGIN := 18.0
const PANEL_PADDING := 24.0
const CONTENT_TOP := 62.0
const CONTENT_GAP := 18.0
const MAP_INSET := 12.0
const MARKER_SIZE := Vector2(58, 58)
const BEACON_SIZE := Vector2(74, 74)
const RING_SIZE := Vector2(86, 86)

const LOCATION_DATA := {
	"office": {
		"name": "办公室",
		"scene": "OFFICE",
		"icon": "res://assets/ui/map/office.png",
		"position": Vector2(0.58, 0.22),
		"npcs": ["张三", "李四", "王五"],
		"routes": ["街区"],
		"status": "可达"
	},
	"street": {
		"name": "街区",
		"scene": "STREET",
		"icon": "res://assets/ui/map/street.png",
		"position": Vector2(0.66, 0.48),
		"npcs": ["陈曦", "赵霖", "刘风"],
		"routes": ["办公室", "公寓", "地下站台"],
		"status": "可达"
	},
	"apartment": {
		"name": "公寓",
		"scene": "APARTMENT",
		"icon": "res://assets/ui/map/apartment.png",
		"position": Vector2(0.75, 0.76),
		"npcs": [],
		"routes": ["街区"],
		"status": "可达"
	},
	"underground": {
		"name": "地下站台",
		"scene": "UNDERGROUND",
		"icon": "res://assets/ui/map/underground.png",
		"position": Vector2(0.43, 0.72),
		"npcs": ["孙悦"],
		"routes": ["街区", "异常空间"],
		"status": "调查区"
	},
	"anomaly": {
		"name": "异常空间",
		"scene": "ANOMALY_SPACE",
		"icon": "res://assets/ui/map/anomaly.png",
		"position": Vector2(0.24, 0.58),
		"npcs": ["何真"],
		"routes": ["地下站台"],
		"status": "异常核心"
	},
}

var _root: Control = null
var _panel: Panel = null
var _map_area: Control = null
var _map_frame: Panel = null
var _map_texture: TextureRect = null
var _route_line: Line2D = null
var _travel_banner: Panel = null
var _travel_label: Label = null
var _info_panel: Panel = null
var _info_title: Label = null
var _info_body: RichTextLabel = null
var _title: Label = null
var _close_button: Button = null
var _marker_nodes: Dictionary = {}
var _hovered_location_id := ""
var _selected_location_id := ""
var _map_transition_pending := false
var _banner_tween: Tween = null

func _ready() -> void:
	layer = 60
	visible = false
	_build_ui()
	_layout_panel()
	var viewport := get_viewport()
	if viewport:
		var resize_callback := Callable(self, "_layout_panel")
		if not viewport.size_changed.is_connected(resize_callback):
			viewport.size_changed.connect(resize_callback)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map"):
		_toggle()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	visible = not visible
	if visible:
		_map_transition_pending = false
		_selected_location_id = ""
		_hovered_location_id = ""
		_refresh()

func _close() -> void:
	visible = false

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.025, 0.04, 0.94)
	style.border_color = Color(0.0, 0.86, 1.0, 0.65)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.6, 0.9, 0.2)
	style.shadow_size = 10
	_panel.add_theme_stylebox_override("panel", style)

	_title = Label.new()
	_title.text = "新港地图"
	_title.position = Vector2(28, 20)
	_title.size = Vector2(260, 34)
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", Color(0.85, 0.96, 1.0))
	_panel.add_child(_title)

	_close_button = Button.new()
	_close_button.text = "X"
	_close_button.position = Vector2(928, 18)
	_close_button.size = Vector2(34, 34)
	_close_button.pressed.connect(_close)
	_panel.add_child(_close_button)

	_map_area = Control.new()
	_map_area.name = "MapArea"
	_map_area.position = Vector2(28, 66)
	_map_area.size = Vector2(620, 500)
	_map_area.mouse_filter = Control.MOUSE_FILTER_PASS
	_panel.add_child(_map_area)

	_map_frame = Panel.new()
	_map_frame.name = "MapFrame"
	_map_frame.position = Vector2.ZERO
	_map_frame.size = _map_area.size
	_map_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	_map_area.add_child(_map_frame)

	var map_style := StyleBoxFlat.new()
	map_style.bg_color = Color(0.015, 0.02, 0.03, 1.0)
	map_style.border_color = Color(0.45, 0.86, 1.0, 0.35)
	map_style.set_border_width_all(1)
	map_style.set_corner_radius_all(6)
	_map_frame.add_theme_stylebox_override("panel", map_style)

	_map_texture = TextureRect.new()
	_map_texture.name = "MapTexture"
	_map_texture.position = Vector2(10, 10)
	_map_texture.size = Vector2(480, 480)
	_map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_texture.mouse_filter = Control.MOUSE_FILTER_PASS
	_map_texture.texture = _load_texture(MAP_TEXTURE_PATH)
	_map_frame.add_child(_map_texture)

	_route_line = Line2D.new()
	_route_line.name = "RouteLine"
	_route_line.visible = false
	_route_line.width = 5.0
	_route_line.default_color = Color(0.0, 0.9, 1.0, 0.9)
	_route_line.z_index = 2
	_map_texture.add_child(_route_line)

	for location_id in LOCATION_DATA.keys():
		_create_marker(location_id)

	_travel_banner = Panel.new()
	_travel_banner.name = "TravelBanner"
	_travel_banner.visible = false
	_travel_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_travel_banner.z_index = 20
	_map_frame.add_child(_travel_banner)

	_travel_label = Label.new()
	_travel_label.position = Vector2(14, 8)
	_travel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_travel_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_travel_label.add_theme_font_size_override("font_size", 16)
	_travel_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))
	_travel_label.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.04, 0.95))
	_travel_label.add_theme_constant_override("outline_size", 3)
	_travel_banner.add_child(_travel_label)

	_info_panel = Panel.new()
	_info_panel.name = "InfoPanel"
	_info_panel.position = Vector2(672, 66)
	_info_panel.size = Vector2(280, 500)
	_panel.add_child(_info_panel)

	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color(0.03, 0.035, 0.055, 0.96)
	info_style.border_color = Color(0.9, 0.78, 0.28, 0.35)
	info_style.set_border_width_all(1)
	info_style.set_corner_radius_all(6)
	_info_panel.add_theme_stylebox_override("panel", info_style)

	_info_title = Label.new()
	_info_title.position = Vector2(18, 18)
	_info_title.size = Vector2(244, 34)
	_info_title.add_theme_font_size_override("font_size", 20)
	_info_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	_info_panel.add_child(_info_title)

	_info_body = RichTextLabel.new()
	_info_body.position = Vector2(18, 62)
	_info_body.size = Vector2(244, 410)
	_info_body.bbcode_enabled = true
	_info_body.fit_content = false
	_info_body.scroll_active = false
	_info_body.add_theme_font_size_override("normal_font_size", 15)
	_info_body.add_theme_color_override("default_color", Color(0.84, 0.9, 0.95))
	_info_panel.add_child(_info_body)

func _create_marker(location_id: String) -> void:
	var data: Dictionary = LOCATION_DATA[location_id]
	var ring := Panel.new()
	ring.name = "FeedbackRing_" + location_id
	ring.size = RING_SIZE
	ring.visible = false
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.z_index = 3
	_apply_ring_style(ring, _location_accent(location_id))
	_map_texture.add_child(ring)

	var marker := TextureButton.new()
	marker.name = "Marker_" + location_id
	marker.size = MARKER_SIZE
	marker.pivot_offset = MARKER_SIZE / 2.0
	marker.texture_normal = _load_texture(str(data["icon"]))
	marker.ignore_texture_size = true
	marker.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	marker.tooltip_text = str(data["name"])
	marker.mouse_filter = Control.MOUSE_FILTER_STOP
	marker.z_index = 5
	marker.mouse_entered.connect(_on_marker_hovered.bind(location_id))
	marker.mouse_exited.connect(_on_marker_unhovered.bind(location_id))
	marker.button_down.connect(_on_marker_button_down.bind(location_id))
	marker.button_up.connect(_on_marker_button_up.bind(location_id))
	marker.pressed.connect(_on_location_pressed.bind(location_id))
	_map_texture.add_child(marker)

	var label := Label.new()
	label.text = str(data["name"])
	label.size = Vector2(98, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 6
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 3)
	_map_texture.add_child(label)

	var beacon := TextureRect.new()
	beacon.name = "CurrentBeacon"
	beacon.visible = false
	beacon.size = BEACON_SIZE
	beacon.texture = _load_texture(CURRENT_BEACON_PATH)
	beacon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	beacon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beacon.z_index = 4
	_map_texture.add_child(beacon)

	_marker_nodes[location_id] = {"button": marker, "label": label, "beacon": beacon, "ring": ring}
	_layout_markers()

func _layout_panel() -> void:
	if not _panel or not _root:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_root.position = Vector2.ZERO

	var margin := PANEL_MARGIN
	if viewport_size.x < 900.0 or viewport_size.y < 620.0:
		margin = 10.0
	var panel_size := Vector2(
		maxf(1.0, viewport_size.x - margin * 2.0),
		maxf(1.0, viewport_size.y - margin * 2.0)
	)
	_panel.position = Vector2(margin, margin)
	_panel.size = panel_size
	_panel.scale = Vector2.ONE

	if _title:
		_title.position = Vector2(PANEL_PADDING, 16)
		_title.size = Vector2(maxf(180.0, panel_size.x - PANEL_PADDING * 2.0 - 46.0), 34)
	if _close_button:
		_close_button.size = Vector2(34, 34)
		_close_button.position = Vector2(panel_size.x - PANEL_PADDING - _close_button.size.x, 16)

	var content_position := Vector2(PANEL_PADDING, CONTENT_TOP)
	var content_size := Vector2(
		maxf(1.0, panel_size.x - PANEL_PADDING * 2.0),
		maxf(1.0, panel_size.y - CONTENT_TOP - PANEL_PADDING)
	)
	var stacked := content_size.x < 760.0
	if stacked:
		var map_height: float = maxf(220.0, content_size.y * 0.58)
		map_height = minf(map_height, content_size.y - 190.0)
		_map_area.position = content_position
		_map_area.size = Vector2(content_size.x, map_height)
		_info_panel.position = content_position + Vector2(0, map_height + CONTENT_GAP)
		_info_panel.size = Vector2(content_size.x, maxf(160.0, content_size.y - map_height - CONTENT_GAP))
	else:
		var info_width: float = clampf(content_size.x * 0.28, 280.0, 360.0)
		var map_width: float = maxf(320.0, content_size.x - info_width - CONTENT_GAP)
		_map_area.position = content_position
		_map_area.size = Vector2(map_width, content_size.y)
		_info_panel.position = content_position + Vector2(map_width + CONTENT_GAP, 0)
		_info_panel.size = Vector2(info_width, content_size.y)

	_map_frame.position = Vector2.ZERO
	_map_frame.size = _map_area.size
	var map_available := Vector2(
		maxf(1.0, _map_frame.size.x - MAP_INSET * 2.0),
		maxf(1.0, _map_frame.size.y - MAP_INSET * 2.0)
	)
	var map_side: float = minf(map_available.x, map_available.y)
	_map_texture.size = Vector2(map_side, map_side)
	_map_texture.position = (_map_frame.size - _map_texture.size) / 2.0

	_info_title.position = Vector2(18, 16)
	_info_title.size = Vector2(maxf(1.0, _info_panel.size.x - 36.0), 34)
	_info_body.position = Vector2(18, 58)
	_info_body.size = Vector2(maxf(1.0, _info_panel.size.x - 36.0), maxf(1.0, _info_panel.size.y - 76.0))
	_layout_banner()
	_layout_markers()

func _layout_markers() -> void:
	if not _map_texture:
		return
	for location_id in _marker_nodes.keys():
		var data: Dictionary = LOCATION_DATA[location_id]
		var normalized: Vector2 = data["position"]
		var marker_position := Vector2(
			normalized.x * _map_texture.size.x,
			normalized.y * _map_texture.size.y
		) - MARKER_SIZE / 2.0
		var nodes: Dictionary = _marker_nodes[location_id]
		if nodes.has("button"):
			var button: TextureButton = nodes["button"]
			button.size = MARKER_SIZE
			button.pivot_offset = MARKER_SIZE / 2.0
			button.position = marker_position
		if nodes.has("label"):
			var label: Label = nodes["label"]
			label.position = marker_position + Vector2(-20, MARKER_SIZE.y - 4.0)
		if nodes.has("beacon"):
			var beacon: TextureRect = nodes["beacon"]
			beacon.size = BEACON_SIZE
			beacon.position = marker_position - (BEACON_SIZE - MARKER_SIZE) / 2.0
		if nodes.has("ring"):
			var ring: Panel = nodes["ring"]
			ring.size = RING_SIZE
			ring.position = marker_position - (RING_SIZE - MARKER_SIZE) / 2.0
	_refresh_route_line()

func _refresh() -> void:
	var current_scene_name := _current_scene_enum_name()
	var current_location := _location_for_scene(current_scene_name)
	for location_id in _marker_nodes.keys():
		var nodes: Dictionary = _marker_nodes[location_id]
		var is_current: bool = str(location_id) == current_location
		var is_discovered := _is_location_discovered(str(location_id), current_location)
		var data: Dictionary = LOCATION_DATA[location_id]
		if nodes.has("beacon"):
			nodes["beacon"].visible = is_current
		if nodes.has("button"):
			var button: TextureButton = nodes["button"]
			button.texture_normal = _load_texture(str(data["icon"]) if is_discovered else LOCKED_MARKER_PATH)
			button.tooltip_text = str(data["name"]) if is_discovered else "未发现地点"
			button.modulate = Color(1, 1, 1, 1) if is_discovered else Color(0.45, 0.48, 0.55, 0.75)
			button.disabled = _map_transition_pending
		if nodes.has("label"):
			var label: Label = nodes["label"]
			label.text = str(data["name"]) if is_discovered else "未发现地点"
			if is_current:
				label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.42))
			elif is_discovered:
				label.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0))
			else:
				label.add_theme_color_override("font_color", Color(0.55, 0.58, 0.66))
	_show_location(current_location if not current_location.is_empty() else "street")
	_update_marker_feedback()

func _on_location_pressed(location_id: String) -> void:
	if not LOCATION_DATA.has(location_id):
		return
	if _map_transition_pending:
		return
	var current_location := _location_for_scene(_current_scene_enum_name())
	if not _is_location_discovered(location_id, current_location):
		_show_location(location_id)
		_play_location_feedback(location_id, "未发现地点：需要先从场景入口抵达")
		return
	if location_id == current_location:
		_show_location(location_id)
		_play_location_feedback(location_id, "当前位置：" + str(LOCATION_DATA[location_id]["name"]))
		return
	var scene_manager := get_node_or_null("/root/SceneManager")
	if not scene_manager or not scene_manager.has_method("transition_to_area"):
		_show_location(location_id)
		return
	if scene_manager.has_method("is_transitioning") and scene_manager.is_transitioning():
		return
	var data: Dictionary = LOCATION_DATA[location_id]
	_map_transition_pending = true
	_selected_location_id = location_id
	_hovered_location_id = ""
	_show_location(location_id)
	_play_location_feedback(location_id, "正在前往：" + str(data["name"]))
	await get_tree().create_timer(0.18).timeout
	if not is_instance_valid(scene_manager):
		_map_transition_pending = false
		return
	if scene_manager.has_method("is_transitioning") and scene_manager.is_transitioning():
		return
	if scene_manager.transition_to_area(location_id):
		_log_event("地图导航: 前往" + str(data["name"]))
		_close()
	else:
		_map_transition_pending = false
		_play_location_feedback(location_id, "无法切换至：" + str(data["name"]))
		_refresh()

func _on_marker_hovered(location_id: String) -> void:
	if _map_transition_pending:
		return
	_hovered_location_id = location_id
	_show_location(location_id)
	_animate_marker_scale(location_id, 1.12, 0.08)
	_update_marker_feedback()

func _on_marker_unhovered(location_id: String) -> void:
	if _hovered_location_id == location_id:
		_hovered_location_id = ""
	if _selected_location_id != location_id:
		_animate_marker_scale(location_id, 1.0, 0.1)
	_update_marker_feedback()

func _on_marker_button_down(location_id: String) -> void:
	if _map_transition_pending:
		return
	_animate_marker_scale(location_id, 0.92, 0.05)

func _on_marker_button_up(location_id: String) -> void:
	if _map_transition_pending:
		return
	_animate_marker_scale(location_id, 1.12 if _hovered_location_id == location_id else 1.0, 0.08)

func _animate_marker_scale(location_id: String, target_scale: float, duration: float) -> void:
	if not _marker_nodes.has(location_id):
		return
	var nodes: Dictionary = _marker_nodes[location_id]
	if not nodes.has("button"):
		return
	var button: TextureButton = nodes["button"]
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), duration)

func _play_location_feedback(location_id: String, message: String) -> void:
	if not _marker_nodes.has(location_id):
		return
	_selected_location_id = location_id
	var accent := _location_accent(location_id)
	_show_travel_banner(message, accent)
	_update_marker_feedback()
	_refresh_route_line()

	var nodes: Dictionary = _marker_nodes[location_id]
	if nodes.has("ring"):
		var ring: Panel = nodes["ring"]
		ring.visible = true
		ring.scale = Vector2(0.72, 0.72)
		ring.modulate = Color(1, 1, 1, 1)
		var ring_tween := create_tween()
		ring_tween.set_trans(Tween.TRANS_CUBIC)
		ring_tween.set_ease(Tween.EASE_OUT)
		ring_tween.tween_property(ring, "scale", Vector2(1.22, 1.22), 0.22)
		ring_tween.parallel().tween_property(ring, "modulate:a", 0.45, 0.22)
		ring_tween.tween_property(ring, "scale", Vector2(1.0, 1.0), 0.12)
		ring_tween.parallel().tween_property(ring, "modulate:a", 0.9, 0.12)

	_animate_marker_scale(location_id, 1.16, 0.08)
	var settle_tween := create_tween()
	settle_tween.tween_interval(0.1)
	settle_tween.tween_callback(func():
		if is_instance_valid(self):
			_animate_marker_scale(location_id, 1.08, 0.1)
	)

	if not _map_transition_pending:
		var clear_tween := create_tween()
		clear_tween.tween_interval(1.15)
		clear_tween.tween_callback(func():
			if is_instance_valid(self) and not _map_transition_pending and _selected_location_id == location_id:
				_selected_location_id = ""
				_update_marker_feedback()
				_refresh_route_line()
				_animate_marker_scale(location_id, 1.0, 0.1)
		)

func _show_travel_banner(message: String, accent: Color) -> void:
	if not _travel_banner or not _travel_label:
		return
	_apply_banner_style(_travel_banner, accent)
	_travel_label.text = message
	_layout_banner()
	_travel_banner.visible = true
	_travel_banner.modulate = Color(1, 1, 1, 0)
	if _banner_tween and is_instance_valid(_banner_tween):
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.set_trans(Tween.TRANS_CUBIC)
	_banner_tween.set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(_travel_banner, "modulate:a", 1.0, 0.12)
	if not _map_transition_pending:
		_banner_tween.tween_interval(1.05)
		_banner_tween.tween_property(_travel_banner, "modulate:a", 0.0, 0.18)
		_banner_tween.tween_callback(func():
			if is_instance_valid(_travel_banner):
				_travel_banner.visible = false
		)

func _layout_banner() -> void:
	if not _travel_banner or not _travel_label or not _map_frame:
		return
	var banner_width: float = minf(460.0, maxf(220.0, _map_frame.size.x - 36.0))
	var banner_height := 42.0
	_travel_banner.size = Vector2(banner_width, banner_height)
	_travel_banner.position = Vector2(
		(_map_frame.size.x - banner_width) / 2.0,
		maxf(8.0, _map_frame.size.y - banner_height - 16.0)
	)
	_travel_label.position = Vector2(12, 0)
	_travel_label.size = Vector2(banner_width - 24.0, banner_height)

func _update_marker_feedback() -> void:
	var current_location := _location_for_scene(_current_scene_enum_name())
	for location_id in _marker_nodes.keys():
		var nodes: Dictionary = _marker_nodes[location_id]
		var is_current := str(location_id) == current_location
		var is_hovered := str(location_id) == _hovered_location_id
		var is_selected := str(location_id) == _selected_location_id
		var is_discovered := _is_location_discovered(str(location_id), current_location)
		var accent := _location_accent(str(location_id))
		if not is_discovered:
			accent = Color(0.62, 0.66, 0.72, 1.0)
		if nodes.has("ring"):
			var ring: Panel = nodes["ring"]
			_apply_ring_style(ring, accent)
			ring.visible = is_hovered or is_selected
			if is_selected:
				ring.modulate = Color(1, 1, 1, 0.95)
			elif is_hovered:
				ring.modulate = Color(1, 1, 1, 0.72)
		if nodes.has("label"):
			var label: Label = nodes["label"]
			if is_selected:
				label.add_theme_color_override("font_color", accent.lightened(0.2))
			elif is_hovered:
				label.add_theme_color_override("font_color", accent.lightened(0.1))
			elif is_current:
				label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.42))
			elif is_discovered:
				label.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0))
			else:
				label.add_theme_color_override("font_color", Color(0.55, 0.58, 0.66))

func _refresh_route_line() -> void:
	if not _route_line:
		return
	var current_location := _location_for_scene(_current_scene_enum_name())
	if _selected_location_id.is_empty() or current_location.is_empty() or _selected_location_id == current_location:
		_route_line.visible = false
		return
	if not _marker_nodes.has(current_location) or not _marker_nodes.has(_selected_location_id):
		_route_line.visible = false
		return
	_route_line.default_color = _location_accent(_selected_location_id)
	_route_line.points = PackedVector2Array([
		_get_marker_center(current_location),
		_get_marker_center(_selected_location_id),
	])
	_route_line.visible = true

func _get_marker_center(location_id: String) -> Vector2:
	if not _marker_nodes.has(location_id):
		return Vector2.ZERO
	var nodes: Dictionary = _marker_nodes[location_id]
	if not nodes.has("button"):
		return Vector2.ZERO
	var button: TextureButton = nodes["button"]
	return button.position + button.size / 2.0

func _apply_ring_style(ring: Panel, accent: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.08)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(42)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)
	style.shadow_size = 10
	ring.add_theme_stylebox_override("panel", style)

func _apply_banner_style(panel: Panel, accent: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.045, 0.92)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.32)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)

func _location_accent(location_id: String) -> Color:
	match location_id:
		"office":
			return Color(0.1, 0.9, 1.0, 1.0)
		"street":
			return Color(1.0, 0.45, 0.78, 1.0)
		"apartment":
			return Color(1.0, 0.78, 0.24, 1.0)
		"underground":
			return Color(0.24, 1.0, 0.76, 1.0)
		"anomaly":
			return Color(0.76, 0.34, 1.0, 1.0)
		_:
			return Color(0.0, 0.9, 1.0, 1.0)

func _show_location(location_id: String) -> void:
	if not LOCATION_DATA.has(location_id):
		return
	var current_location := _location_for_scene(_current_scene_enum_name())
	if not _is_location_discovered(location_id, current_location):
		_info_title.text = "未发现地点"
		_info_body.text = "[b]状态[/b]：尚未发现\n\n需要先从场景入口抵达该地点。"
		return
	var data: Dictionary = LOCATION_DATA[location_id]
	_info_title.text = str(data["name"])
	var npcs: Array = data["npcs"]
	var routes: Array = data["routes"]
	var npc_text := "无常驻 NPC" if npcs.is_empty() else "、".join(npcs)
	var route_text := "无" if routes.is_empty() else "、".join(routes)
	var current_tag := "当前位置\n" if str(data["scene"]) == _current_scene_enum_name() else ""
	var travel_state := "当前位置" if location_id == current_location else "可直达"
	_info_body.text = "[b]%s状态[/b]：%s\n\n[b]导航[/b]\n%s\n\n[b]常驻 NPC[/b]\n%s\n\n[b]传送关系[/b]\n%s" % [
		current_tag,
		str(data["status"]),
		travel_state,
		npc_text,
		route_text,
	]

func _current_scene_enum_name() -> String:
	var scene_manager := get_node_or_null("/root/SceneManager")
	if not scene_manager:
		return ""
	match scene_manager.current_scene:
		scene_manager.GameScene.OFFICE:
			return "OFFICE"
		scene_manager.GameScene.STREET:
			return "STREET"
		scene_manager.GameScene.UNDERGROUND:
			return "UNDERGROUND"
		scene_manager.GameScene.ANOMALY_SPACE:
			return "ANOMALY_SPACE"
		scene_manager.GameScene.APARTMENT:
			return "APARTMENT"
	return ""

func _location_for_scene(scene_name: String) -> String:
	for location_id in LOCATION_DATA.keys():
		if str(LOCATION_DATA[location_id]["scene"]) == scene_name:
			return location_id
	return ""

func _is_location_discovered(location_id: String, current_location: String = "") -> bool:
	if location_id == current_location:
		return true
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return true
	var discovered: Array = gm.discovered_areas
	return location_id in discovered

func _log_event(message: String) -> void:
	var log_panel = get_node_or_null("/root/LogPanel")
	if log_panel and log_panel.has_method("add_log"):
		log_panel.add_log(message)

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture = load(path)
		if texture is Texture2D:
			return texture
	return null
