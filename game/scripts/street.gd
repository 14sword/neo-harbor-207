extends Node2D

@onready var background: Sprite2D = $Background

var api_client: Node = null
var _bubble_timer: float = 0.0
const BUBBLE_INTERVAL_MIN: float = 15.0
const BUBBLE_INTERVAL_MAX: float = 30.0
var _next_bubble_interval: float = 20.0

var _building_bubbles: Dictionary = {}
var _near_exit: bool = false
var _near_datawhale: bool = false
var _near_apartment: bool = false
var _apartment_indicator: Node2D = null
var _apartment_glow: PointLight2D = null

var _rain_night_effects: Node = null

var _day_ambient_particles: GPUParticles2D = null
var _dust_timer: float = 0.0

func _ready():
	print("[Street] 街区场景初始化")

	if background:
		background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	api_client = get_node_or_null("/root/APIClient")

	_init_building_bubbles()

	var player = get_tree().get_first_node_in_group("player")
	if player and has_node("/root/SceneManager"):
		player.global_position = get_node("/root/SceneManager").get_spawn_position()
		_setup_camera_limits(player)

	var exit_zone = get_node_or_null("ExitZone")
	if exit_zone:
		exit_zone.body_entered.connect(_on_exit_zone_entered)
		exit_zone.body_exited.connect(_on_exit_zone_exited)

	var datawhale_entrance = get_node_or_null("DatawhaleEntrance")
	if datawhale_entrance:
		datawhale_entrance.body_entered.connect(_on_datawhale_entered)
		datawhale_entrance.body_exited.connect(_on_datawhale_exited)

	var apartment_entrance = get_node_or_null("ApartmentEntrance")
	if apartment_entrance:
		apartment_entrance.body_entered.connect(_on_apartment_entered)
		apartment_entrance.body_exited.connect(_on_apartment_exited)

	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)
		_apply_street_background()

	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("🏙️ 来到了赛博朋克街区")

	_init_rain_night_effects()
	_init_day_ambient()
	_create_apartment_indicator()

func _create_apartment_indicator():
	_apartment_indicator = Node2D.new()
	_apartment_indicator.name = "ApartmentIndicator"
	_apartment_indicator.position = Vector2(1100, 700)
	_apartment_indicator.z_index = 40
	add_child(_apartment_indicator)
	
	_apartment_glow = PointLight2D.new()
	_apartment_glow.energy = 0.3
	_apartment_glow.color = Color(0.0, 0.6, 1.0, 0.5)
	_apartment_glow.texture = _create_indicator_texture()
	_apartment_glow.scale = Vector2(2, 2)
	_apartment_glow.z_index = 40
	_apartment_indicator.add_child(_apartment_glow)
	
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(_apartment_glow, "energy", 0.5, 1.2)
	pulse_tween.tween_property(_apartment_glow, "energy", 0.2, 1.2)

func _create_indicator_texture() -> Texture2D:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for x in range(64):
		for y in range(64):
			var dist = Vector2(x - 32, y - 32).length() / 32.0
			var alpha = max(0, 1.0 - dist)
			alpha = pow(alpha, 2.0)
			img.set_pixel(x, y, Color(0.0, 0.8, 1.0, alpha))
	return ImageTexture.create_from_image(img)

func _init_rain_night_effects():
	var rne_script = load("res://scripts/rain_night_effects.gd")
	if rne_script == null:
		print("[Street] 无法加载 rain_night_effects.gd")
		return

	_rain_night_effects = Node2D.new()
	_rain_night_effects.name = "RainNightEffects"
	_rain_night_effects.set_script(rne_script)
	add_child(_rain_night_effects)

	if has_node("/root/EnvironmentManager"):
		var env = get_node("/root/EnvironmentManager")
		env.neon_flickered.connect(_on_neon_flicker)
		env.window_toggled.connect(_on_window_toggle)
		env.drone_spawned.connect(_on_drone_spawn)
		env.late_night_event_triggered.connect(_on_late_night_event)

	_apply_rain_visibility()

func _init_day_ambient():
	_day_ambient_particles = GPUParticles2D.new()
	_day_ambient_particles.name = "DayAmbient"
	_day_ambient_particles.z_index = 44
	_day_ambient_particles.amount = 8
	_day_ambient_particles.lifetime = 10.0
	_day_ambient_particles.explosiveness = 0.0
	_day_ambient_particles.randomness = 0.7
	_day_ambient_particles.position = Vector2(836, 470)
	_day_ambient_particles.process_mode = Node.PROCESS_MODE_INHERIT

	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0.3, 0.1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0.5, -0.2, 0)
	pm.scale_min = 1.0
	pm.scale_max = 3.0
	pm.color = Color(1.0, 0.95, 0.8, 0.15)
	pm.emission_box_extents = Vector3(800, 400, 0)

	_day_ambient_particles.process_material = pm
	_day_ambient_particles.emitting = false
	add_child(_day_ambient_particles)

func _apply_rain_visibility():
	var is_rain_night = false
	if has_node("/root/DayNightManager"):
		is_rain_night = get_node("/root/DayNightManager").is_rain()

	if _rain_night_effects and _rain_night_effects.has_method("set_effects_visible"):
		_rain_night_effects.set_effects_visible(is_rain_night)

	_update_day_ambient()

func _update_day_ambient():
	if _day_ambient_particles == null:
		return

	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if dnm.is_day() or dnm.is_dusk():
			_day_ambient_particles.emitting = true
		else:
			_day_ambient_particles.emitting = false

func _process(delta: float):
	_bubble_timer += delta
	if _bubble_timer >= _next_bubble_interval:
		_bubble_timer = 0.0
		_next_bubble_interval = randf_range(BUBBLE_INTERVAL_MIN, BUBBLE_INTERVAL_MAX)
		_show_random_bubble()

	if _near_exit and Input.is_action_just_pressed("interact"):
		_transition_to_office()

	if _near_datawhale and Input.is_action_just_pressed("interact"):
		_transition_to_office()

	if _near_apartment and Input.is_action_just_pressed("interact"):
		_transition_to_apartment()

	if _day_ambient_particles and _day_ambient_particles.emitting:
		_dust_timer += delta
		if _dust_timer > 20.0:
			_dust_timer = 0.0
			if randf() < 0.3:
				_day_ambient_particles.emitting = false
				await get_tree().create_timer(randf_range(2.0, 5.0)).timeout
				_day_ambient_particles.emitting = true

func _on_exit_zone_entered(body: Node2D):
	if body.is_in_group("player"):
		_near_exit = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("exit_street")

func _on_exit_zone_exited(body: Node2D):
	if body.is_in_group("player"):
		_near_exit = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_datawhale_entered(body: Node2D):
	if body.is_in_group("player"):
		_near_datawhale = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("enter_office")

func _on_datawhale_exited(body: Node2D):
	if body.is_in_group("player"):
		_near_datawhale = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_apartment_entered(body: Node2D):
	if body.is_in_group("player"):
		_near_apartment = true
		if _apartment_glow:
			_apartment_glow.energy = 0.8
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("enter_apartment")

func _on_apartment_exited(body: Node2D):
	if body.is_in_group("player"):
		_near_apartment = false
		if _apartment_glow:
			_apartment_glow.energy = 0.3
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _transition_to_office():
	if has_node("/root/SceneManager"):
		_log_event("🚪 返回办公室")
		get_node("/root/SceneManager").transition_to(get_node("/root/SceneManager").GameScene.OFFICE)

func _transition_to_apartment():
	if has_node("/root/SceneManager"):
		_log_event("🏠 进入公寓")
		get_node("/root/SceneManager").transition_to(get_node("/root/SceneManager").GameScene.APARTMENT)

func _apply_street_background():
	if not has_node("/root/DayNightManager"):
		return

	var dnm = get_node("/root/DayNightManager")
	var bg = get_tree().get_first_node_in_group("background")
	if bg and bg is Sprite2D:
		var bg_map = dnm.street_backgrounds
		var bg_path = bg_map.get(dnm.current_phase, "")
		if bg_path != "" and ResourceLoader.exists(bg_path):
			bg.texture = load(bg_path)

	_apply_rain_visibility()

func _on_phase_changed(_new_phase):
	_apply_street_background()

func _init_building_bubbles():
	_building_bubbles = {
		"RAMEN-YA": {
			"position": Vector2(210, 640),
			"messages": [
				"今日限定：海鲜拉面",
				"味增拉面半价",
				"新口味：赛博辣味",
				"热腾腾的拉面等你",
				"本店使用合成小麦",
				"老板今天心情不错"
			]
		},
		"BYTE BREW CAFE": {
			"position": Vector2(1340, 290),
			"messages": [
				"新品：量子浓缩咖啡",
				"会员积分双倍",
				"深夜营业中",
				"WiFi密码: DATAWHALE2024",
				"……咖啡机好像有意识了"
			]
		},
		"NEO HARBOUR": {
			"position": Vector2(836, 115),
			"messages": [
				"DATAWHALE 招聘中",
				"AI改变世界",
				"加入我们",
				"未来已来",
				"▓▓▓数据异常异常▓▓▓",
				"ION 联网服务升级"
			]
		},
		"地下铁": {
			"position": Vector2(140, 790),
			"messages": [
				"下一班列车延迟",
				"末班车23:30",
				"请勿拥挤",
				"注意安全",
				"3号线因信号故障暂停",
				"……隧道深处传来奇怪回声"
			]
		},
		"TAXI": {
			"position": Vector2(780, 810),
			"messages": [
				"空车·随时出发",
				"夜间加收20%",
				"目的地不限",
				"……司机好像认识你",
				"今日特价：去DATAWHALE半价"
			]
		},
		"自动售货机": {
			"position": Vector2(420, 545),
			"messages": [
				"……你今天看起来很累。",
				"需要一罐能量饮料吗？",
				"叮——",
				"今日特价：赛博可乐",
				"……别走。",
				"我检测到你的压力值偏高。"
			]
		},
		"居民楼": {
			"position": Vector2(500, 200),
			"messages": [
				"请勿喧哗",
				"302室外卖到了",
				"电梯维修中",
				"物业费已逾期",
				"今夜有异常噪音报告",
				"楼下的猫又在看什么？"
			]
		},
	}

func _show_random_bubble():
	var buildings = _building_bubbles.keys()
	if buildings.size() == 0:
		return

	var building_name = buildings[randi() % buildings.size()]
	var building = _building_bubbles[building_name]
	var messages = building["messages"]
	var msg = messages[randi() % messages.size()]
	var pos = building["position"]

	var is_night = false
	var is_rain = false
	if has_node("/root/DayNightManager"):
		is_night = get_node("/root/DayNightManager").is_night()
		is_rain = get_node("/root/DayNightManager").is_rain()

	var panel = Panel.new()
	panel.position = pos - Vector2(80, 15)
	panel.z_index = 59
	panel.custom_minimum_size = Vector2(200, 36)

	var style = StyleBoxFlat.new()
	if is_rain:
		style.bg_color = Color(0.03, 0.04, 0.10, 0.93)
		style.set_border_width_all(2)
		style.border_color = Color(0, 0.75, 0.9, 0.7)
		style.set_corner_radius_all(10)
		style.shadow_color = Color(0, 0.75, 0.9, 0.4)
		style.shadow_size = 5
	elif is_night:
		style.bg_color = Color(0.04, 0.04, 0.12, 0.92)
		style.set_border_width_all(2)
		style.border_color = Color(0, 0.94, 1, 0.8)
		style.set_corner_radius_all(10)
		style.shadow_color = Color(0, 0.94, 1, 0.5)
		style.shadow_size = 6
	else:
		style.bg_color = Color(0.06, 0.06, 0.15, 0.85)
		style.set_border_width_all(2)
		style.border_color = Color(0, 0.94, 1, 0.5)
		style.set_corner_radius_all(10)
		style.shadow_color = Color(0, 0.94, 1, 0.25)
		style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = msg
	label.position = pos - Vector2(70, 8)
	label.z_index = 60
	label.add_theme_font_size_override("font_size", 13)
	if is_rain:
		label.add_theme_color_override("font_color", Color(0.6, 0.82, 0.92, 0.92))
		label.add_theme_color_override("font_shadow_color", Color(0, 0.65, 0.8, 0.35))
		label.add_theme_constant_override("shadow_outline_size", 3)
	elif is_night:
		label.add_theme_color_override("font_color", Color(0, 0.94, 1, 0.95))
		label.add_theme_color_override("font_shadow_color", Color(0, 0.94, 1, 0.4))
		label.add_theme_constant_override("shadow_outline_size", 3)
	else:
		label.add_theme_color_override("font_color", Color(0.85, 0.92, 0.95, 0.9))
		label.add_theme_color_override("font_shadow_color", Color(0, 0.94, 1, 0.3))
		label.add_theme_constant_override("shadow_outline_size", 2)

	add_child(panel)
	add_child(label)

	panel.modulate = Color(1, 1, 1, 0)
	label.modulate = Color(1, 1, 1, 0)

	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.5)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 1), 0.5)
	tween.tween_interval(3.0)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func():
		if is_instance_valid(panel):
			panel.queue_free()
		if is_instance_valid(label):
			label.queue_free()
	)

func _on_neon_flicker(_building_id: String):
	if _rain_night_effects and _rain_night_effects.has_method("trigger_anomaly"):
		pass

func _on_window_toggle(_building_id: String, _window_index: int, _is_on: bool):
	pass

func _on_drone_spawn(_drone_id: String):
	_log_event("🛸 无人机飞过街区上空")

func _on_late_night_event(event_id: String):
	if _rain_night_effects and _rain_night_effects.has_method("trigger_anomaly"):
		_rain_night_effects.trigger_anomaly(event_id)

func _setup_camera_limits(player: Node):
	var camera = player.get_node_or_null("Camera2D")
	if not camera:
		return
	
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	var bg = get_tree().get_first_node_in_group("background")
	if bg and bg is Sprite2D and bg.texture:
		var tex_size = bg.texture.get_size()
		camera.limit_left = bg.position.x - tex_size.x / 2.0
		camera.limit_top = bg.position.y - tex_size.y / 2.0
		camera.limit_right = bg.position.x + tex_size.x / 2.0
		camera.limit_bottom = bg.position.y + tex_size.y / 2.0
	else:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 1672
		camera.limit_bottom = 941

func _log_event(message: String):
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)
