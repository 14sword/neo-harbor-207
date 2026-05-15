extends Node2D

@onready var background: Sprite2D = $Background

var _near_exit: bool = false
var _near_computer: bool = false
var _near_bed: bool = false
var _near_balcony: bool = false
var _near_tv: bool = false
var _near_talisman: bool = false
var _near_plant: bool = false
var _near_clothesline: bool = false
var _near_railing: bool = false
var _near_fridge: bool = false
var _interaction_locked: bool = false
var _exit_indicator: Node2D = null
var _exit_glow: PointLight2D = null

var _plant_watered_today: bool = false
var _plant_water_count: int = 0
var _last_water_day: int = -1
var _sleep_count: int = 0
var _fridge_check_count: int = 0

var _event_timer: float = 0.0

static var _water_particle_material: ParticleProcessMaterial = null
static var _water_particle_texture: Texture2D = null

var _day_events: Array[Dictionary] = [
	{"text": "📱 收到快递通知：您的包裹已到达楼下智能柜。", "weight": 3},
	{"text": "🌤️ 天气播报：今日多云，适合外出。", "weight": 2},
	{"text": "🍜 外卖提醒：附近新店开业，限时8折。", "weight": 2},
	{"text": "📡 hologram广告更新：DATAWHALE招聘季开始。", "weight": 1},
]

var _rain_events: Array[Dictionary] = [
	{"text": "⚡ 远处传来雷声，窗户微微震动。", "weight": 3},
	{"text": "💡 灯光短暂闪烁了一下。", "weight": 3},
	{"text": "🚁 一辆飞车拖尾划过雨幕。", "weight": 2},
	{"text": "🔊 电流杂音从墙壁传来。", "weight": 2},
]

var _anomaly_events: Array[Dictionary] = [
	{"text": "💻 终端自动启动，屏幕上闪过一串未知代码...", "weight": 3},
	{"text": "📱 收到一条没有来源的通知：[数据删除]", "weight": 2},
	{"text": "🔮 紫色像素从角落飘过，转瞬即逝。", "weight": 2},
	{"text": "📻 收音机自动开启，播放着不存在的广播频率...", "weight": 2},
	{"text": "🌌 天空裂缝闪烁了一下，像有什么在注视这里。", "weight": 1},
]

func _ready():

	if background:
		background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var player = get_tree().get_first_node_in_group("player")
	if player and has_node("/root/SceneManager"):
		player.global_position = get_node("/root/SceneManager").get_spawn_position()
		_setup_camera_limits(player)
	
	var exit_zone = get_node_or_null("ApartmentExit")
	if exit_zone:
		exit_zone.body_entered.connect(_on_exit_entered)
		exit_zone.body_exited.connect(_on_exit_exited)
	
	_connect_interaction_zone("ComputerZone", "_on_computer_entered", "_on_computer_exited")
	_connect_interaction_zone("BedZone", "_on_bed_entered", "_on_bed_exited")
	_connect_interaction_zone("BalconyZone", "_on_balcony_entered", "_on_balcony_exited")
	_connect_interaction_zone("TVZone", "_on_tv_entered", "_on_tv_exited")
	_connect_interaction_zone("TalismanZone", "_on_talisman_entered", "_on_talisman_exited")
	_connect_interaction_zone("PlantZone", "_on_plant_entered", "_on_plant_exited")
	_connect_interaction_zone("ClotheslineZone", "_on_clothesline_entered", "_on_clothesline_exited")
	_connect_interaction_zone("RailingZone", "_on_railing_entered", "_on_railing_exited")
	_connect_interaction_zone("FridgeZone", "_on_fridge_entered", "_on_fridge_exited")
	
	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)
	
	_event_timer = randf_range(10.0, 20.0)
	
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("🏠 回到了公寓")
	
	_create_exit_indicator()

	if has_node("/root/PetManager"):
		get_node("/root/PetManager").ensure_pet_in_scene()

func _create_exit_indicator():
	_exit_indicator = Node2D.new()
	_exit_indicator.name = "ExitIndicator"
	_exit_indicator.position = Vector2(836, 820)
	_exit_indicator.z_index = 40
	add_child(_exit_indicator)
	
	_exit_glow = PointLight2D.new()
	_exit_glow.energy = 0.3
	_exit_glow.color = Color(0.0, 0.6, 1.0, 0.5)
	_exit_glow.texture = _create_indicator_texture()
	_exit_glow.scale = Vector2(2, 2)
	_exit_glow.z_index = 40
	_exit_indicator.add_child(_exit_glow)
	
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(_exit_glow, "energy", 0.5, 1.2)
	pulse_tween.tween_property(_exit_glow, "energy", 0.2, 1.2)

func _create_indicator_texture() -> Texture2D:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for x in range(64):
		for y in range(64):
			var dist = Vector2(x - 32, y - 32).length() / 32.0
			var alpha = max(0, 1.0 - dist)
			alpha = pow(alpha, 2.0)
			img.set_pixel(x, y, Color(0.0, 0.8, 1.0, alpha))
	return ImageTexture.create_from_image(img)

func _connect_interaction_zone(zone_name: String, enter_func: String, exit_func: String):
	var zone = get_node_or_null(zone_name)
	if zone:
		zone.body_entered.connect(Callable(self, enter_func))
		zone.body_exited.connect(Callable(self, exit_func))

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

func _process(delta):
	_event_timer -= delta
	if _event_timer <= 0:
		_trigger_random_event()
		_event_timer = randf_range(15.0, 30.0)

	if _interaction_locked:
		return

	if _near_exit and Input.is_action_just_pressed("interact"):
		_transition_to_street()
	elif _near_computer and Input.is_action_just_pressed("interact"):
		_interact_computer()
	elif _near_bed and Input.is_action_just_pressed("interact"):
		_interact_bed()
	elif _near_balcony and Input.is_action_just_pressed("interact"):
		_interact_balcony()
	elif _near_tv and Input.is_action_just_pressed("interact"):
		_interact_tv()
	elif _near_talisman and Input.is_action_just_pressed("interact"):
		_interact_talisman()
	elif _near_plant and Input.is_action_just_pressed("interact"):
		_interact_plant()
	elif _near_clothesline and Input.is_action_just_pressed("interact"):
		_interact_clothesline()
	elif _near_railing and Input.is_action_just_pressed("interact"):
		_interact_railing()
	elif _near_fridge and Input.is_action_just_pressed("interact"):
		_interact_fridge()

func _transition_to_street():
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").transition_to(get_node("/root/SceneManager").GameScene.STREET)

func _interact_computer():
	var forum_scene = load("res://scenes/forum_ui.tscn")
	if forum_scene:
		var forum = forum_scene.instantiate()
		add_child(forum)
		forum.closed.connect(_on_overlay_closed)
		_interaction_locked = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _interact_bed():
	_sleep_count += 1
	if has_node("/root/QuestManager"):
		get_node("/root/QuestManager").on_interaction("sleep")
	var overlay_scene = load("res://scenes/sleep_overlay.tscn")
	if overlay_scene:
		var overlay = overlay_scene.instantiate()
		add_child(overlay)
		overlay.start_transition(_on_sleep_phase_switch)
		overlay.finished.connect(_on_overlay_closed)
		_interaction_locked = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_sleep_phase_switch():
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		dnm.toggle_day_night()

func _on_overlay_closed():
	_interaction_locked = false
	_restore_current_prompt()

func _restore_current_prompt():
	var prompt = get_tree().get_first_node_in_group("interaction_prompt")
	if not prompt or not prompt.has_method("show_prompt"):
		return
	if _near_computer:
		prompt.show_prompt("use_computer")
	elif _near_bed:
		prompt.show_prompt("use_bed")
	elif _near_balcony:
		prompt.show_prompt("observe_city")
	elif _near_tv:
		prompt.show_prompt("watch_tv")
	elif _near_talisman:
		prompt.show_prompt("check_talisman")
	elif _near_plant:
		prompt.show_prompt("check_plant")
	elif _near_clothesline:
		prompt.show_prompt("check_clothesline")
	elif _near_railing:
		prompt.show_prompt("lean_railing")
	elif _near_fridge:
		prompt.show_prompt("open_fridge")
	elif _near_exit:
		prompt.show_prompt("exit_apartment")

func _interact_balcony():
	if has_node("/root/QuestManager"):
		get_node("/root/QuestManager").on_interaction("balcony")
	var balcony_scene = load("res://scenes/balcony_overlay.tscn")
	if balcony_scene:
		var overlay = balcony_scene.instantiate()
		add_child(overlay)
		overlay.closed.connect(_on_overlay_closed)
		_interaction_locked = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _interact_tv():
	if has_node("/root/QuestManager"):
		get_node("/root/QuestManager").on_interaction("tv")
	var tv_scene = load("res://scenes/tv_overlay.tscn")
	if tv_scene:
		var overlay = tv_scene.instantiate()
		add_child(overlay)
		overlay.closed.connect(_on_overlay_closed)
		_interaction_locked = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _interact_talisman():
	if has_node("/root/QuestManager"):
		get_node("/root/QuestManager").on_interaction("talisman")
	var talisman_scene = load("res://scenes/talisman_overlay.tscn")
	if talisman_scene:
		var overlay = talisman_scene.instantiate()
		add_child(overlay)
		overlay.closed.connect(_on_overlay_closed)
		_interaction_locked = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _interact_plant():
	_check_daily_reset()
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if dnm.current_phase == dnm.DayPhase.NIGHT:
			if has_node("/root/LogPanel"):
				get_node("/root/LogPanel").add_log("🌿 植物似乎在微微发光...不太对劲")
			return
		elif dnm.current_phase == dnm.DayPhase.RAIN_NIGHT:
			if has_node("/root/LogPanel"):
				get_node("/root/LogPanel").add_log("🌿 植物叶片上挂着水珠，看起来很新鲜")
			return
	if _plant_watered_today:
		if has_node("/root/LogPanel"):
			get_node("/root/LogPanel").add_log("🌿 植物今天已经浇过水了，不用再浇")
		return
	_plant_watered_today = true
	_plant_water_count += 1
	_create_water_particles()
	if has_node("/root/QuestManager"):
		get_node("/root/QuestManager").on_interaction("water_plant")
	var plant_desc = "🌿 多肉植物状态良好，叶片饱满"
	if _plant_water_count >= 10:
		plant_desc = "🌿 多肉植物长势喜人，已经开出了小花！"
	elif _plant_water_count >= 5:
		plant_desc = "🌿 多肉植物在你的照料下越来越茂盛了"
	elif _plant_water_count >= 3:
		plant_desc = "🌿 给多肉植物浇了水，叶片更加饱满了"
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(plant_desc + " (累计浇水" + str(_plant_water_count) + "次)")

func _check_daily_reset():
	var today = _get_today_id()
	if today != _last_water_day:
		_plant_watered_today = false
		_last_water_day = today

func _get_today_id() -> int:
	if has_node("/root/WorldCalendar"):
		return get_node("/root/WorldCalendar").current_day
	return Time.get_date_dict_from_system().get("yday", 0)

func _create_water_particles():
	var plant_zone = get_node_or_null("PlantZone")
	if not plant_zone:
		return

	if not _water_particle_material:
		var pm = ParticleProcessMaterial.new()
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 30.0
		pm.initial_velocity_min = 30.0
		pm.initial_velocity_max = 80.0
		pm.gravity = Vector3(0, 98, 0)
		pm.scale_min = 1.0
		pm.scale_max = 3.0
		pm.color = Color(0.4, 0.7, 1.0, 0.8)
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(0.4, 0.7, 1.0, 0.8))
		gradient.add_point(0.5, Color(0.3, 0.6, 1.0, 0.5))
		gradient.add_point(1.0, Color(0.2, 0.5, 0.9, 0.0))
		var color_ramp = GradientTexture1D.new()
		color_ramp.gradient = gradient
		color_ramp.width = 256
		pm.color_ramp = color_ramp
		_water_particle_material = pm

	if not _water_particle_texture:
		var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		_water_particle_texture = ImageTexture.create_from_image(img)

	var particles = GPUParticles2D.new()
	particles.position = plant_zone.position
	particles.z_index = 30
	particles.amount = 20
	particles.lifetime = 1.0
	particles.explosiveness = 0.3
	particles.randomness = 0.5
	particles.emitting = true
	particles.process_material = _water_particle_material.duplicate()
	particles.texture = _water_particle_texture
	add_child(particles)
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(particles.queue_free)

func _interact_clothesline():
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if dnm.current_phase == dnm.DayPhase.NIGHT:
			if has_node("/root/LogPanel"):
				get_node("/root/LogPanel").add_log("👕 晾衣架上多了一件不认识的衣服...")
			return
		elif dnm.current_phase == dnm.DayPhase.RAIN_NIGHT:
			if has_node("/root/LogPanel"):
				get_node("/root/LogPanel").add_log("👕 衣物被雨水打湿了，应该早点收进来")
			return
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("👕 衣物在微风中轻轻摆动，今天是个好天气")

func _interact_railing():
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if dnm.current_phase == dnm.DayPhase.NIGHT:
			if has_node("/root/LogPanel"):
				get_node("/root/LogPanel").add_log("🌑 栏杆上有一层薄薄的紫色霜...温度异常低")
			return
		elif dnm.current_phase == dnm.DayPhase.RAIN_NIGHT:
			if has_node("/root/LogPanel"):
				get_node("/root/LogPanel").add_log("🌧️ 雨水打在栏杆上，冰凉的触感")
			return
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("🌆 靠在栏杆上，城市的喧嚣从下方传来")

func _interact_fridge():
	_fridge_check_count += 1
	if has_node("/root/QuestManager"):
		get_node("/root/QuestManager").on_interaction("fridge")
	var items_day = ["牛奶 x1", "方便面 x3", "合成蛋白棒 x5", "矿泉水 x2", "剩饭 x1"]
	var items_rain = ["牛奶 x1", "方便面 x3", "矿泉水 x2", "深夜外卖 x1"]
	var items_night = ["牛奶 x1", "??? x1", "矿泉水 x2", "冰箱里多了一样不认识的东西"]
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if dnm.current_phase == dnm.DayPhase.NIGHT:
			if has_node("/root/LogPanel"):
				get_node("/root/LogPanel").add_log("🧊 打开冰箱: " + items_night[randi() % items_night.size()])
			return
		elif dnm.current_phase == dnm.DayPhase.RAIN_NIGHT:
			if has_node("/root/LogPanel"):
				get_node("/root/LogPanel").add_log("🧊 打开冰箱: " + items_rain[randi() % items_rain.size()])
			return
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("🧊 打开冰箱: " + items_day[randi() % items_day.size()])

func _trigger_random_event():
	var events: Array[Dictionary]
	
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		match dnm.current_phase:
			dnm.DayPhase.DAY, dnm.DayPhase.DUSK:
				events = _day_events
			dnm.DayPhase.RAIN_NIGHT:
				events = _rain_events
			dnm.DayPhase.NIGHT:
				events = _anomaly_events
	
	if events.is_empty():
		return
	
	var total_weight = 0
	for e in events:
		total_weight += e.get("weight", 1)
	
	var roll = randi() % total_weight
	var cumulative = 0
	for e in events:
		cumulative += e.get("weight", 1)
		if roll < cumulative:
			if has_node("/root/LogPanel"):
				get_node("/root/LogPanel").add_log(e.get("text", ""))
			break

func _on_exit_entered(body):
	if body.is_in_group("player"):
		_near_exit = true
		if _exit_glow:
			_exit_glow.energy = 0.8
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("exit_apartment")

func _on_exit_exited(body):
	if body.is_in_group("player"):
		_near_exit = false
		if _exit_glow:
			_exit_glow.energy = 0.3
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_computer_entered(body):
	if body.is_in_group("player"):
		_near_computer = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("use_computer")

func _on_computer_exited(body):
	if body.is_in_group("player"):
		_near_computer = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_bed_entered(body):
	if body.is_in_group("player"):
		_near_bed = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("use_bed")

func _on_bed_exited(body):
	if body.is_in_group("player"):
		_near_bed = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_balcony_entered(body):
	if body.is_in_group("player"):
		_near_balcony = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("observe_city")
		if has_node("ApartmentAmbient"):
			get_node("ApartmentAmbient").set_player_near_balcony(true)

func _on_balcony_exited(body):
	if body.is_in_group("player"):
		_near_balcony = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()
		if has_node("ApartmentAmbient"):
			get_node("ApartmentAmbient").set_player_near_balcony(false)

func _on_tv_entered(body):
	if body.is_in_group("player"):
		_near_tv = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("watch_tv")

func _on_tv_exited(body):
	if body.is_in_group("player"):
		_near_tv = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_talisman_entered(body):
	if body.is_in_group("player"):
		_near_talisman = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("check_talisman")

func _on_talisman_exited(body):
	if body.is_in_group("player"):
		_near_talisman = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_plant_entered(body):
	if body.is_in_group("player"):
		_near_plant = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("check_plant")

func _on_plant_exited(body):
	if body.is_in_group("player"):
		_near_plant = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_clothesline_entered(body):
	if body.is_in_group("player"):
		_near_clothesline = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("check_clothesline")

func _on_clothesline_exited(body):
	if body.is_in_group("player"):
		_near_clothesline = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_railing_entered(body):
	if body.is_in_group("player"):
		_near_railing = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("lean_railing")

func _on_railing_exited(body):
	if body.is_in_group("player"):
		_near_railing = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_fridge_entered(body):
	if body.is_in_group("player"):
		_near_fridge = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("open_fridge")

func _on_fridge_exited(body):
	if body.is_in_group("player"):
		_near_fridge = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _on_phase_changed(_new_phase):
	_apply_apartment_background()

func _apply_apartment_background():
	if not background:
		return
	
	if not has_node("/root/DayNightManager"):
		return
	
	var dnm = get_node("/root/DayNightManager")
	var bg_path = ""
	
	match dnm.current_phase:
		dnm.DayPhase.DAY:
			bg_path = "res://assets/backgrounds/apartment/白天.png"
		dnm.DayPhase.DUSK:
			bg_path = "res://assets/backgrounds/apartment/白天.png"
		dnm.DayPhase.NIGHT:
			bg_path = "res://assets/backgrounds/apartment/黑夜.png"
		dnm.DayPhase.RAIN_NIGHT:
			bg_path = "res://assets/backgrounds/apartment/雨夜.png"
	
	if bg_path != "" and ResourceLoader.exists(bg_path):
		background.texture = load(bg_path)
