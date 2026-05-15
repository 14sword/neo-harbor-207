extends Node2D

var _rain_particles: GPUParticles2D
var _rain_drip_particles: Array = []
var _neon_reflection_overlay: ColorRect
var _fog_overlay: ColorRect
var _neon_lights: Dictionary = {}
var _window_lights: Dictionary = {}
var _drone_sprite: Sprite2D
var _drone_light: PointLight2D
var _drone_active: bool = false
var _drone_timer: float = 0.0

var _neon_flicker_timers: Dictionary = {}
var _window_toggle_timers: Dictionary = {}

const MAP_WIDTH: float = 1672.0
const MAP_HEIGHT: float = 941.0

var _time: float = 0.0

var _cached_glow_texture: Texture2D = null

var _neon_positions: Dictionary = {
	"ramen_sign": Vector2(165, 585),
	"cafe_sign": Vector2(1320, 265),
	"datawhale_sign": Vector2(1340, 790),
	"subway_sign": Vector2(120, 765),
	"billboard_main": Vector2(786, 95),
	"vending_machine": Vector2(420, 520),
}

var _window_positions: Dictionary = {
	"ramen_win": {"pos": Vector2(220, 540), "color": Color(1, 0.85, 0.6, 0.0)},
	"cafe_win": {"pos": Vector2(1280, 240), "color": Color(0.6, 0.8, 1, 0.0)},
	"dw_win": {"pos": Vector2(1280, 670), "color": Color(0.3, 0.6, 1, 0.0)},
	"apartment_win": {"pos": Vector2(1050, 180), "color": Color(1, 0.9, 0.7, 0.0)},
	"office_win": {"pos": Vector2(1180, 200), "color": Color(0.4, 0.7, 1, 0.0)},
}

var _drone_paths: Array = [
	[Vector2(200, 200), Vector2(500, 150), Vector2(900, 180), Vector2(1300, 160), Vector2(1450, 200)],
	[Vector2(1300, 250), Vector2(1000, 280), Vector2(600, 260), Vector2(300, 290)],
]

func _ready():
	print("[RainNightEffects] 雨夜特效系统初始化")
	_cached_glow_texture = _create_glow_texture()
	_create_rain_system()
	_create_neon_reflection()
	_create_fog_overlay()
	_create_neon_lights()
	_create_window_lights()
	_create_drone()

func _process(delta: float):
	_time += delta
	_update_rain_intensity()
	_update_neon_flicker(delta)
	_update_window_lights(delta)
	_update_drone(delta)
	_update_fog_pulse()

func _create_rain_system():
	_rain_particles = GPUParticles2D.new()
	_rain_particles.name = "RainSystem"
	_rain_particles.z_index = 52
	_rain_particles.amount = 120
	_rain_particles.emitting = true
	_rain_particles.process_mode = Node.PROCESS_MODE_INHERIT
	_rain_particles.position = Vector2(MAP_WIDTH / 2, -30)

	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0.15, 1.0, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 450.0
	pm.initial_velocity_max = 600.0
	pm.gravity = Vector3(50, 150, 0)
	pm.scale_min = 0.4
	pm.scale_max = 0.8
	pm.color = Color(0.65, 0.72, 0.88, 0.35)
	pm.emission_box_extents = Vector3(MAP_WIDTH * 0.6, 10, 0)

	_rain_particles.process_material = pm
	_rain_particles.lifetime = 1.2
	_rain_particles.explosiveness = 0.0
	_rain_particles.randomness = 0.25

	add_child(_rain_particles)

	var drip_positions = [Vector2(175, 575), Vector2(1295, 255), Vector2(135, 755)]
	for drip_pos in drip_positions:
		var drip = _create_drip_particle(drip_pos)
		_rain_drip_particles.append(drip)
		add_child(drip)

func _create_drip_particle(pos: Vector2) -> GPUParticles2D:
	var drip = GPUParticles2D.new()
	drip.name = "RainDrip"
	drip.z_index = 51
	drip.amount = 2
	drip.emitting = true
	drip.process_mode = Node.PROCESS_MODE_INHERIT
	drip.position = pos

	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0.05, 1.0, 0)
	pm.spread = 5.0
	pm.initial_velocity_min = 80.0
	pm.initial_velocity_max = 120.0
	pm.gravity = Vector3(20, 80, 0)
	pm.scale_min = 0.3
	pm.scale_max = 0.5
	pm.color = Color(0.6, 0.7, 0.9, 0.4)

	drip.process_material = pm
	drip.lifetime = 0.8
	drip.explosiveness = 0.0
	drip.randomness = 0.4

	return drip

func _create_neon_reflection():
	_neon_reflection_overlay = ColorRect.new()
	_neon_reflection_overlay.name = "NeonReflection"
	_neon_reflection_overlay.position = Vector2(-MAP_WIDTH / 2, -MAP_HEIGHT / 2)
	_neon_reflection_overlay.size = Vector2(MAP_WIDTH, MAP_HEIGHT)
	_neon_reflection_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_neon_reflection_overlay.z_index = 45
	_neon_reflection_overlay.color = Color(0, 0.08, 0.12, 0.15)

	add_child(_neon_reflection_overlay)

	var reflection_spots = [
		{"pos": Vector2(210, 640), "color": Color(1, 0.4, 0.3, 0.12), "size": Vector2(120, 40)},
		{"pos": Vector2(1340, 320), "color": Color(0.3, 0.5, 1, 0.10), "size": Vector2(100, 35)},
		{"pos": Vector2(1340, 830), "color": Color(0.2, 0.4, 1, 0.10), "size": Vector2(140, 50)},
		{"pos": Vector2(140, 820), "color": Color(0, 0.9, 0.6, 0.10), "size": Vector2(90, 40)},
		{"pos": Vector2(786, 140), "color": Color(0.8, 0.2, 0.9, 0.08), "size": Vector2(200, 30)},
	]

	for spot in reflection_spots:
		var glow = ColorRect.new()
		glow.position = spot["pos"] - spot["size"] / 2
		glow.size = spot["size"]
		glow.z_index = 46
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.color = spot["color"]

		var glow_style = StyleBoxFlat.new()
		glow_style.bg_color = spot["color"]
		glow_style.set_corner_radius_all(4)
		glow.add_theme_stylebox_override("panel", glow_style)

		add_child(glow)

func _create_fog_overlay():
	_fog_overlay = ColorRect.new()
	_fog_overlay.name = "FogOverlay"
	_fog_overlay.position = Vector2(-MAP_WIDTH / 2, -MAP_HEIGHT / 2)
	_fog_overlay.size = Vector2(MAP_WIDTH, MAP_HEIGHT)
	_fog_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_overlay.z_index = 53
	_fog_overlay.color = Color(0.08, 0.09, 0.14, 0.12)

	add_child(_fog_overlay)

func _create_neon_lights():
	for neon_id in _neon_positions:
		var pos = _neon_positions[neon_id]
		var light = PointLight2D.new()
		light.name = "Neon_" + neon_id
		light.position = pos
		light.texture = _cached_glow_texture
		light.z_index = 47
		light.scale = Vector2(2.5, 2.5)

		if "sign" in neon_id or "billboard" in neon_id:
			light.color = Color(0.9, 0.2, 0.8, 0.5)
			light.energy = 0.7
		elif "vending" in neon_id:
			light.color = Color(1, 0.4, 0.3, 0.4)
			light.energy = 0.35
		else:
			light.color = Color(0, 0.9, 1, 0.5)
			light.energy = 0.5

		_neon_lights[neon_id] = light
		_neon_flicker_timers[neon_id] = randf_range(0.0, 5.0)
		add_child(light)

func _create_window_lights():
	for win_id in _window_positions:
		var data = _window_positions[win_id]
		var light = PointLight2D.new()
		light.name = "Window_" + win_id
		light.position = data["pos"]
		light.texture = _cached_glow_texture
		light.z_index = 46
		light.scale = Vector2(1.8, 1.8)
		light.color = data["color"]
		light.energy = 0.0

		_window_lights[win_id] = light
		_window_toggle_timers[win_id] = randf_range(5.0, 25.0)
		add_child(light)

		if randf() < 0.35:
			light.energy = randf_range(0.2, 0.5)
			light.color.a = randf_range(0.4, 0.7)

func _create_drone():
	_drone_sprite = Sprite2D.new()
	_drone_sprite.name = "DroneSprite"
	_drone_sprite.z_index = 48
	_drone_sprite.position = Vector2(-100, -100)
	_drone_sprite.scale = Vector2(0.4, 0.4)
	_drone_sprite.visible = false

	var drone_img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(16):
		for y in range(16):
			var cx = 8.0
			var cy = 8.0
			var dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy))
			if dist < 6:
				drone_img.set_pixel(x, y, Color(0.5, 0.55, 0.6, 0.9))
			elif dist < 8:
				drone_img.set_pixel(x, y, Color(0.3, 0.35, 0.45, 0.5))
			else:
				drone_img.set_pixel(x, y, Color(0, 0, 0, 0))
	_drone_sprite.texture = ImageTexture.create_from_image(drone_img)

	_drone_light = PointLight2D.new()
	_drone_light.name = "DroneLight"
	_drone_light.texture = _cached_glow_texture
	_drone_light.z_index = 48
	_drone_light.scale = Vector2(1.5, 1.5)
	_drone_light.color = Color(0, 0.85, 0.7, 0.4)
	_drone_light.energy = 0.3

	_drone_sprite.add_child(_drone_light)
	add_child(_drone_sprite)

func _update_rain_intensity():
	var intensity_mod = 0.92 + sin(_time * 0.3) * 0.08
	if _rain_particles:
		_rain_particles.modulate = Color(1, 1, 1, intensity_mod)

	for drip in _rain_drip_particles:
		if is_instance_valid(drip):
			drip.modulate = Color(1, 1, 1, intensity_mod * 0.8)

func _update_neon_flicker(delta: float):
	for neon_id in _neon_lights:
		var light = _neon_lights[neon_id]
		if not is_instance_valid(light):
			continue

		_neon_flicker_timers[neon_id] -= delta
		if _neon_flicker_timers[neon_id] <= 0:
			_neon_flicker_timers[neon_id] = randf_range(3.0, 8.0)

			var flicker_target = randf_range(0.82, 1.0)
			var base_energy = 0.5
			if "sign" in neon_id or "billboard" in neon_id:
				base_energy = 0.7
			elif "vending" in neon_id:
				base_energy = 0.35

			var tween = create_tween()
			tween.tween_property(light, "energy", flicker_target * base_energy * 1.2, 0.08)
			tween.tween_property(light, "energy", flicker_target * base_energy, 0.12)

func _update_window_lights(delta: float):
	for win_id in _window_lights:
		var light = _window_lights[win_id]
		if not is_instance_valid(light):
			continue

		_window_toggle_timers[win_id] -= delta
		if _window_toggle_timers[win_id] <= 0:
			_window_toggle_timers[win_id] = randf_range(10.0, 30.0)

			if randf() < 0.3:
				if light.energy > 0.1:
					var tween = create_tween()
					tween.tween_property(light, "energy", 0.0, 1.5)
					tween.tween_property(light, "color:a", 0.0, 1.5)
				else:
					var base_energy = randf_range(0.2, 0.5)
					var base_alpha = randf_range(0.4, 0.7)
					light.energy = base_energy
					light.color.a = base_alpha

					var tween = create_tween()
					tween.tween_property(light, "energy", base_energy * 1.3, 0.4)
					tween.tween_property(light, "energy", base_energy, 0.3)

func _update_drone(delta: float):
	_drone_timer += delta
	if _drone_timer > 30.0 and not _drone_active:
		if randf() < 0.015:
			_start_drone_flight()
			_drone_timer = 0.0

	if _drone_active:
		_advance_drone(delta)

func _start_drone_flight():
	_drone_active = true
	var paths = _drone_paths
	var selected_path = paths[randi() % paths.size()]
	_drone_sprite.position = selected_path[0]
	_drone_sprite.modulate = Color(1, 1, 1, 0)
	_drone_sprite.visible = true

	var tween = create_tween()
	tween.tween_property(_drone_sprite, "modulate", Color(1, 1, 1, 0.8), 1.0)

	if _drone_light:
		_drone_light.energy = 0.3

	_drone_current_path = selected_path
	_drone_segment_index = 0
	_drone_segment_progress = 0.0

var _drone_current_path: Array = []
var _drone_segment_index: int = 0
var _drone_segment_progress: float = 0.0

func _advance_drone(delta: float):
	if _drone_segment_index >= _drone_current_path.size() - 1:
		var tween = create_tween()
		tween.tween_property(_drone_sprite, "modulate", Color(1, 1, 1, 0), 2.0)
		tween.tween_callback(func():
			_drone_active = false
			_drone_sprite.visible = false
		)
		return

	var from_pos = _drone_current_path[_drone_segment_index]
	var to_pos = _drone_current_path[_drone_segment_index + 1]
	_drone_segment_progress += delta * 0.04

	if _drone_segment_progress >= 1.0:
		_drone_segment_progress = 0.0
		_drone_segment_index += 1
		return

	var current_pos = from_pos.lerp(to_pos, _drone_segment_progress)
	_drone_sprite.position = current_pos

	if _drone_light:
		_drone_light.energy = 0.25 + sin(_time * 4.0) * 0.1

func _update_fog_pulse():
	var fog_alpha = 0.10 + sin(_time * 0.15) * 0.03 + sin(_time * 0.07) * 0.02
	if _fog_overlay:
		_fog_overlay.color = Color(0.08, 0.09, 0.14, fog_alpha)

	if _neon_reflection_overlay:
		var ref_alpha = 0.15 + sin(_time * 0.2) * 0.04
		_neon_reflection_overlay.color = Color(0, 0.08, 0.12, ref_alpha)

func set_effects_visible(vis: bool):
	if _rain_particles:
		_rain_particles.emitting = vis
	for drip in _rain_drip_particles:
		if is_instance_valid(drip):
			drip.emitting = vis

	if _neon_reflection_overlay:
		_neon_reflection_overlay.visible = vis
	if _fog_overlay:
		_fog_overlay.visible = vis

	for neon_id in _neon_lights:
		var light = _neon_lights[neon_id]
		if is_instance_valid(light):
			light.visible = vis

	for win_id in _window_lights:
		var light = _window_lights[win_id]
		if is_instance_valid(light):
			light.visible = vis

func trigger_anomaly(event_type: String):
	match event_type:
		"glitch_billboard":
			var billboard_light = _neon_lights.get("billboard_main")
			if is_instance_valid(billboard_light):
				var tween = create_tween()
				tween.tween_property(billboard_light, "color", Color(1, 0, 0, 0.9), 0.1)
				tween.tween_property(billboard_light, "color", Color(0.9, 0.2, 0.8, 0.5), 0.15)
				tween.tween_property(billboard_light, "color", Color(1, 0, 0, 0.9), 0.1)
				tween.tween_property(billboard_light, "color", Color(0.9, 0.2, 0.8, 0.5), 0.3)
		"window_anomaly":
			var random_windows = _window_lights.keys()
			if random_windows.size() > 0:
				var target_win = random_windows[randi() % random_windows.size()]
				var light = _window_lights[target_win]
				if is_instance_valid(light):
					light.energy = 0.8
					light.color = Color(0.7, 0.1, 0.9, 0.9)
					var tween = create_tween()
					tween.tween_interval(3.0)
					tween.tween_callback(func():
						if is_instance_valid(light):
							light.energy = 0.0
							light.color = _window_positions.get(target_win, {}).get("color", Color(0, 0, 0, 0))
					)

func _create_glow_texture() -> Texture2D:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for x in range(64):
		for y in range(64):
			var center = Vector2(31.5, 31.5)
			var dist = Vector2(x, y).distance_to(center) / 32.0
			var glow = max(0, 1.0 - dist)
			glow = pow(glow, 2.5)
			img.set_pixel(x, y, Color(1, 1, 1, glow))
	return ImageTexture.create_from_image(img)
