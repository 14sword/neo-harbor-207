extends Node2D

const EFFECT_BASE := "res://assets/effects/underground/"
const FRAME_COUNT := 4

const TRAIN_START := Vector2(1320, 520)
const TRAIN_END := Vector2(1620, 520)

var _holo_notice: AnimatedSprite2D
var _maintenance_monitor: AnimatedSprite2D
var _portal_pulse: AnimatedSprite2D
var _train_light: Sprite2D
var _research_kit: Sprite2D
var _steam_sprites: Array[AnimatedSprite2D] = []
var _drip_sprites: Array[AnimatedSprite2D] = []

var _holo_alpha: float = 0.62
var _monitor_alpha: float = 0.68
var _train_alpha: float = 0.42
var _steam_alpha: float = 0.42
var _drip_alpha: float = 0.36
var _portal_alpha: float = 0.58

var _holo_tween: Tween
var _monitor_tween: Tween
var _train_tween: Tween

func _ready() -> void:
	_build_ambient_nodes()
	_connect_day_night_manager()
	_apply_phase(_get_current_phase())
	_restart_tweens()

func _exit_tree() -> void:
	_kill_tween(_holo_tween)
	_kill_tween(_monitor_tween)
	_kill_tween(_train_tween)

func _build_ambient_nodes() -> void:
	_holo_notice = _create_sheet_sprite(
		"HoloNotice",
		EFFECT_BASE + "holo_notice_sheet.png",
		Vector2(520, 260),
		Vector2(0.58, 0.58),
		26,
		5.0
	)
	_maintenance_monitor = _create_sheet_sprite(
		"MaintenanceMonitor",
		EFFECT_BASE + "maintenance_monitor_sheet.png",
		Vector2(1030, 205),
		Vector2(0.50, 0.50),
		24,
		4.0
	)
	_train_light = _create_static_sprite(
		"TrainLightSweep",
		EFFECT_BASE + "train_light_sweep.png",
		TRAIN_START,
		Vector2(0.78, 0.78),
		28
	)

	_steam_sprites.append(_create_sheet_sprite(
		"SteamPuffA",
		EFFECT_BASE + "steam_puff_sheet.png",
		Vector2(360, 690),
		Vector2(0.50, 0.50),
		32,
		5.0
	))
	_steam_sprites.append(_create_sheet_sprite(
		"SteamPuffB",
		EFFECT_BASE + "steam_puff_sheet.png",
		Vector2(1180, 720),
		Vector2(0.44, 0.44),
		32,
		4.2
	))

	_drip_sprites.append(_create_sheet_sprite(
		"DripReflectionA",
		EFFECT_BASE + "drip_reflection_sheet.png",
		Vector2(650, 790),
		Vector2(0.58, 0.58),
		30,
		4.0
	))
	_drip_sprites.append(_create_sheet_sprite(
		"DripReflectionB",
		EFFECT_BASE + "drip_reflection_sheet.png",
		Vector2(980, 760),
		Vector2(0.50, 0.50),
		30,
		3.4
	))

	_research_kit = _create_static_sprite(
		"SunYueResearchKit",
		EFFECT_BASE + "sun_yue_research_kit.png",
		Vector2(720, 635),
		Vector2(0.48, 0.48),
		31
	)
	_portal_pulse = _create_sheet_sprite(
		"PortalPulse",
		EFFECT_BASE + "portal_pulse_sheet.png",
		Vector2(836, 320),
		Vector2(0.66, 0.66),
		35,
		5.0
	)

func _create_sheet_sprite(
	node_name: String,
	texture_path: String,
	sprite_position: Vector2,
	sprite_scale: Vector2,
	sprite_z_index: int,
	fps: float
) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = node_name
	sprite.position = sprite_position
	sprite.scale = sprite_scale
	sprite.z_index = sprite_z_index
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.sprite_frames = _build_sprite_frames(texture_path, fps)
	sprite.animation = "default"
	sprite.play("default")
	add_child(sprite)
	return sprite

func _create_static_sprite(
	node_name: String,
	texture_path: String,
	sprite_position: Vector2,
	sprite_scale: Vector2,
	sprite_z_index: int
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.position = sprite_position
	sprite.scale = sprite_scale
	sprite.z_index = sprite_z_index
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var texture_resource: Resource = load(texture_path)
	if texture_resource is Texture2D:
		var texture: Texture2D = texture_resource as Texture2D
		sprite.texture = texture
	else:
		push_warning("[UndergroundAmbient] 素材加载失败: " + texture_path)
	add_child(sprite)
	return sprite

func _build_sprite_frames(texture_path: String, fps: float) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if not frames.has_animation("default"):
		frames.add_animation("default")
	frames.set_animation_loop("default", true)
	frames.set_animation_speed("default", fps)

	var texture_resource: Resource = load(texture_path)
	if not texture_resource is Texture2D:
		push_warning("[UndergroundAmbient] 动画素材加载失败: " + texture_path)
		return frames

	var texture: Texture2D = texture_resource as Texture2D
	var sheet_size: Vector2 = texture.get_size()
	var frame_width: float = sheet_size.x / float(FRAME_COUNT)
	for frame_idx in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_width * frame_idx, 0, frame_width, sheet_size.y)
		frames.add_frame("default", atlas)
	return frames

func _connect_day_night_manager() -> void:
	var day_night = get_node_or_null("/root/DayNightManager")
	if not day_night:
		return
	var phase_callable := Callable(self, "_on_phase_changed")
	if not day_night.phase_changed.is_connected(phase_callable):
		day_night.phase_changed.connect(phase_callable)

func _on_phase_changed(new_phase) -> void:
	_apply_phase(int(new_phase))
	_restart_tweens()

func _get_current_phase() -> int:
	var day_night = get_node_or_null("/root/DayNightManager")
	if day_night:
		return int(day_night.current_phase)
	return 0

func _apply_phase(phase: int) -> void:
	var settings := _phase_settings(phase)
	_holo_alpha = settings["holo_alpha"]
	_monitor_alpha = settings["monitor_alpha"]
	_train_alpha = settings["train_alpha"]
	_steam_alpha = settings["steam_alpha"]
	_drip_alpha = settings["drip_alpha"]
	_portal_alpha = settings["portal_alpha"]

	_set_item_alpha(_holo_notice, _holo_alpha)
	_set_item_alpha(_maintenance_monitor, _monitor_alpha)
	_set_item_alpha(_train_light, 0.0)
	_set_item_alpha(_research_kit, settings["kit_alpha"])
	_set_item_alpha(_portal_pulse, _portal_alpha)

	_holo_notice.speed_scale = settings["holo_speed"]
	_maintenance_monitor.speed_scale = settings["monitor_speed"]
	_portal_pulse.speed_scale = settings["portal_speed"]

	for sprite in _steam_sprites:
		_set_item_alpha(sprite, _steam_alpha)
		sprite.speed_scale = settings["steam_speed"]
		sprite.visible = settings["steam_visible"]
	for sprite in _drip_sprites:
		_set_item_alpha(sprite, _drip_alpha)
		sprite.speed_scale = settings["drip_speed"]
		sprite.visible = settings["drip_visible"]

func _phase_settings(phase: int) -> Dictionary:
	match phase:
		0:
			return {
				"holo_alpha": 0.50,
				"monitor_alpha": 0.46,
				"train_alpha": 0.22,
				"steam_alpha": 0.30,
				"drip_alpha": 0.20,
				"portal_alpha": 0.42,
				"kit_alpha": 0.86,
				"holo_speed": 0.85,
				"monitor_speed": 0.85,
				"portal_speed": 0.80,
				"steam_speed": 0.80,
				"drip_speed": 0.70,
				"steam_visible": true,
				"drip_visible": true,
			}
		1:
			return {
				"holo_alpha": 0.62,
				"monitor_alpha": 0.58,
				"train_alpha": 0.34,
				"steam_alpha": 0.38,
				"drip_alpha": 0.30,
				"portal_alpha": 0.54,
				"kit_alpha": 0.90,
				"holo_speed": 1.0,
				"monitor_speed": 1.0,
				"portal_speed": 0.95,
				"steam_speed": 0.92,
				"drip_speed": 0.85,
				"steam_visible": true,
				"drip_visible": true,
			}
		2:
			return {
				"holo_alpha": 0.76,
				"monitor_alpha": 0.78,
				"train_alpha": 0.48,
				"steam_alpha": 0.48,
				"drip_alpha": 0.38,
				"portal_alpha": 0.66,
				"kit_alpha": 0.94,
				"holo_speed": 1.12,
				"monitor_speed": 1.15,
				"portal_speed": 1.08,
				"steam_speed": 1.0,
				"drip_speed": 1.0,
				"steam_visible": true,
				"drip_visible": true,
			}
		_:
			return {
				"holo_alpha": 0.80,
				"monitor_alpha": 0.84,
				"train_alpha": 0.54,
				"steam_alpha": 0.58,
				"drip_alpha": 0.52,
				"portal_alpha": 0.72,
				"kit_alpha": 0.94,
				"holo_speed": 1.18,
				"monitor_speed": 1.25,
				"portal_speed": 1.16,
				"steam_speed": 1.12,
				"drip_speed": 1.2,
				"steam_visible": true,
				"drip_visible": true,
			}

func _set_item_alpha(item: CanvasItem, alpha: float) -> void:
	if not item:
		return
	var color := item.modulate
	color.a = clampf(alpha, 0.0, 1.0)
	item.modulate = color

func _restart_tweens() -> void:
	_start_holo_breath()
	_start_monitor_flicker()
	_start_train_sweep()

func _start_holo_breath() -> void:
	if not _holo_notice:
		return
	_kill_tween(_holo_tween)
	_holo_tween = create_tween()
	_holo_tween.set_loops()
	_holo_tween.tween_property(_holo_notice, "modulate:a", _holo_alpha * 0.72, 0.9)
	_holo_tween.tween_property(_holo_notice, "modulate:a", minf(_holo_alpha * 1.08, 1.0), 1.1)

func _start_monitor_flicker() -> void:
	if not _maintenance_monitor:
		return
	_kill_tween(_monitor_tween)
	_monitor_tween = create_tween()
	_monitor_tween.set_loops()
	_monitor_tween.tween_property(_maintenance_monitor, "modulate:a", _monitor_alpha * 0.55, 0.07)
	_monitor_tween.tween_property(_maintenance_monitor, "modulate:a", _monitor_alpha, 0.12)
	_monitor_tween.tween_interval(0.45)
	_monitor_tween.tween_property(_maintenance_monitor, "modulate:a", minf(_monitor_alpha * 1.08, 1.0), 0.05)
	_monitor_tween.tween_property(_maintenance_monitor, "modulate:a", _monitor_alpha * 0.82, 0.09)
	_monitor_tween.tween_interval(0.35)

func _start_train_sweep() -> void:
	if not _train_light:
		return
	_kill_tween(_train_tween)
	_reset_train_light()
	_train_tween = create_tween()
	_train_tween.set_loops()
	_train_tween.tween_interval(1.0)
	_train_tween.tween_callback(Callable(self, "_reset_train_light"))
	_train_tween.tween_property(_train_light, "modulate:a", _train_alpha, 0.22)
	_train_tween.parallel().tween_property(_train_light, "position", TRAIN_END, 2.1)
	_train_tween.tween_property(_train_light, "modulate:a", 0.0, 0.45)
	_train_tween.tween_interval(2.4)

func _reset_train_light() -> void:
	if not _train_light:
		return
	_train_light.position = TRAIN_START
	_set_item_alpha(_train_light, 0.0)

func _kill_tween(tween: Tween) -> void:
	if tween:
		tween.kill()
