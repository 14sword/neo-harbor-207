extends Node2D

@export var scene_title: String = "特殊区域"
@export_enum("UNDERGROUND", "ANOMALY_SPACE") var scene_manager_scene_name: String = "UNDERGROUND"
@export var background_path: String = ""
@export var background_day_path: String = ""
@export var background_dusk_path: String = ""
@export var background_night_path: String = ""
@export var background_rain_night_path: String = ""
@export_enum("OFFICE", "STREET", "UNDERGROUND", "ANOMALY_SPACE", "APARTMENT") var return_scene_name: String = "STREET"
@export var prompt_key: String = "return_to_street"
@export_enum("NONE", "OFFICE", "STREET", "UNDERGROUND", "ANOMALY_SPACE", "APARTMENT", "RIFT_RUN") var portal_scene_name: String = "NONE"
@export var portal_prompt_key: String = "enter_anomaly_space"

@onready var background: Sprite2D = $Background

var _near_exit: bool = false
var _near_portal: bool = false

func _ready() -> void:
	var scene_manager = get_node_or_null("/root/SceneManager")
	_sync_scene_manager(scene_manager)

	var day_night = get_node_or_null("/root/DayNightManager")
	var phase_callable := Callable(self, "_on_phase_changed")
	if day_night and not day_night.phase_changed.is_connected(phase_callable):
		day_night.phase_changed.connect(phase_callable)

	_restore_background()

	if background:
		background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var player = get_tree().get_first_node_in_group("player")
	if player and scene_manager:
		player.global_position = scene_manager.get_spawn_position()
		_setup_camera_limits(player)

	var exit_zone = get_node_or_null("ReturnZone")
	if exit_zone:
		exit_zone.body_entered.connect(_on_return_entered)
		exit_zone.body_exited.connect(_on_return_exited)

	var portal_zone = get_node_or_null("AnomalyZone")
	if not portal_zone:
		portal_zone = get_node_or_null("RiftEntryZone")
	if portal_zone:
		portal_zone.body_entered.connect(_on_portal_entered)
		portal_zone.body_exited.connect(_on_portal_exited)
		if portal_zone is CollisionObject2D:
			portal_zone.input_pickable = true
			var input_callable := Callable(self, "_on_portal_input_event")
			if not portal_zone.input_event.is_connected(input_callable):
				portal_zone.input_event.connect(input_callable)

	_apply_rift_gate_state()

	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("进入" + scene_title)

func _sync_scene_manager(scene_manager: Node) -> void:
	if not scene_manager:
		return

	match scene_manager_scene_name:
		"UNDERGROUND":
			scene_manager.current_scene = scene_manager.GameScene.UNDERGROUND
		"ANOMALY_SPACE":
			scene_manager.current_scene = scene_manager.GameScene.ANOMALY_SPACE

func _restore_background() -> void:
	var selected_path = _select_background_path()
	if not background or selected_path == "":
		return
	if not ResourceLoader.exists(selected_path):
		push_warning("[SpecialScene] 背景资源不存在: " + selected_path)
		return

	var texture = load(selected_path)
	if texture is Texture2D:
		background.texture = texture

func _select_background_path() -> String:
	var selected_path = background_path
	var day_night = get_node_or_null("/root/DayNightManager")
	if day_night:
		match day_night.current_phase:
			day_night.DayPhase.DAY:
				selected_path = _fallback_path(background_day_path, background_path)
			day_night.DayPhase.DUSK:
				selected_path = _fallback_path(background_dusk_path, background_path)
			day_night.DayPhase.NIGHT:
				selected_path = _fallback_path(background_night_path, background_path)
			day_night.DayPhase.RAIN_NIGHT:
				selected_path = _fallback_path(background_rain_night_path, background_path)
	return selected_path

func _fallback_path(primary_path: String, fallback_path: String) -> String:
	if primary_path.strip_edges().is_empty():
		return fallback_path
	return primary_path

func _on_phase_changed(_new_phase) -> void:
	_restore_background()

func _process(_delta: float) -> void:
	if _near_exit and Input.is_action_just_pressed("interact"):
		_transition_to_return_scene()
	elif _near_portal and Input.is_action_just_pressed("interact"):
		_transition_to_portal_scene()

func _setup_camera_limits(player: Node) -> void:
	var camera = player.get_node_or_null("Camera2D")
	if not camera:
		return

	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0

	if background and background.texture:
		var tex_size = background.texture.get_size() * background.scale
		camera.limit_left = int(background.position.x - tex_size.x / 2.0)
		camera.limit_top = int(background.position.y - tex_size.y / 2.0)
		camera.limit_right = int(background.position.x + tex_size.x / 2.0)
		camera.limit_bottom = int(background.position.y + tex_size.y / 2.0)
	else:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 1672
		camera.limit_bottom = 941

func _transition_to_return_scene() -> void:
	_transition_to_named_scene(return_scene_name)

func _transition_to_portal_scene() -> void:
	if _is_portal_disabled():
		return
	_transition_to_named_scene(portal_scene_name)

func _transition_to_named_scene(target_scene_name: String) -> void:
	if not has_node("/root/SceneManager"):
		return
	var sm = get_node("/root/SceneManager")
	match target_scene_name:
		"OFFICE":
			sm.transition_to(sm.GameScene.OFFICE)
		"STREET":
			sm.transition_to(sm.GameScene.STREET)
		"UNDERGROUND":
			sm.transition_to(sm.GameScene.UNDERGROUND)
		"ANOMALY_SPACE":
			sm.transition_to(sm.GameScene.ANOMALY_SPACE)
		"APARTMENT":
			sm.transition_to(sm.GameScene.APARTMENT)
		"RIFT_RUN":
			sm.transition_to(sm.GameScene.RIFT_RUN)
		_:
			sm.transition_to(sm.GameScene.APARTMENT)

func _on_return_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_near_exit = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt(prompt_key)

func _on_return_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_near_exit = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_portal_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _is_portal_disabled():
		_near_portal = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt(portal_prompt_key)

func _on_portal_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_near_portal = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_portal_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_portal_disabled():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_transition_to_portal_scene()

func _apply_rift_gate_state() -> void:
	var visual: Sprite2D = get_node_or_null("RiftGateVisual")
	var aura: Sprite2D = get_node_or_null("RiftGateAura")
	var entry_fx: Node = get_node_or_null("RiftEntryFX")
	if not visual and not aura and not entry_fx:
		return
	var phase: int = 0
	var rift_manager = get_node_or_null("/root/RiftRunManager")
	if rift_manager and rift_manager.has_method("get_gate_phase"):
		phase = int(rift_manager.get_gate_phase())
	if entry_fx and entry_fx.has_method("set_gate_phase"):
		entry_fx.set_gate_phase(phase)
	var aura_alpha: float = 0.22 + phase * 0.08
	if aura:
		aura.modulate = Color(0.45 + phase * 0.05, 0.82, 1.0, min(aura_alpha, 0.62))
		aura.scale = Vector2.ONE * (0.36 + phase * 0.018)
	if visual:
		visual.modulate = Color(1.0, 1.0 - phase * 0.04, 1.0, 1.0)
		visual.scale = Vector2.ONE * (0.28 + phase * 0.01)

func _is_portal_disabled() -> bool:
	return portal_scene_name.strip_edges().is_empty() or portal_scene_name == "NONE"
