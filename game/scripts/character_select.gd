extends Control

var _selected_class: int = 0
var _last_class_preview_requested: int = -1
var _anim_time: float = 0.0
var _fade_active: bool = true
var _status_timer: float = 0.0
var _status_idx: int = 0
var _info_timer: float = 0.0
var _info_idx: int = 0
var _anomaly_timer: float = 0.0
var _next_anomaly_time: float = 18.0
var _anomaly_active: bool = false
var _current_accent: Color = Color(0, 0.85, 1, 1)
var _class_tabs_data: Array = []
var _idle_frames: Array[Texture2D] = []
var _idle_frame_idx: int = 0
var _idle_timer: float = 0.0
const IDLE_FRAME_INTERVAL: float = 0.12
var _use_anime_style: bool = false
var _texture_cache: Dictionary = {}
var _frame_counter: int = 0

var _left_field_labels: Array = []
var _left_field_values: Array = []
var _left_bar: ProgressBar = null
var _left_bar_val_lbl: Label = null
var _stat_bars: Dictionary = {}
var _skill_labels: Array = []
var _affinity_labels: Array = []

const CLASS_DATA = [
	{
		"id": 0,
		"name_cn": "数据分析师",
		"name_en": "CIPHER",
		"color": Color(0, 0.85, 1, 1),
		"desc": "精通数据分析与系统入侵，能发现隐藏在数据中的维度坐标",
		"stats": {"int": 18, "per": 12, "agi": 8, "cha": 10},
		"skills": ["数据透视", "系统入侵"],
		"sprite_path": "res://assets/characters/select/cipher.png",
		"identity_type": "DATAWHALE Data Analyst",
		"residence": "Neo Harbor - Block 09",
		"sync_rate": 87,
		"risk_level": "LOW RISK",
		"credit_rating": "C+",
		"network_status": "已同步",
		"keywords": ["数据透视", "系统侵入", "异常分析"],
		"initial_affinity": {"zhang_san": "张三"},
	},
	{
		"id": 1,
		"name_cn": "义体战士",
		"name_en": "CHROME",
		"color": Color(1, 0.5, 0.15, 1),
		"desc": "经过深度义体改造的战斗专家，在街头生存中无往不利",
		"stats": {"int": 8, "per": 10, "agi": 14, "cha": 6},
		"skills": ["义体过载", "护盾生成"],
		"sprite_path": "res://assets/characters/select/chrome.png",
		"identity_type": "Street Cyborg Operative",
		"residence": "Neo Harbor - Block 17",
		"sync_rate": 72,
		"risk_level": "MONITORED",
		"credit_rating": "B",
		"network_status": "检测中",
		"keywords": ["义体同步", "力量强化", "近战适配"],
		"initial_affinity": {"liu_feng": "刘风"},
	},
	{
		"id": 2,
		"name_cn": "灵能感知者",
		"name_en": "ECHO",
		"color": Color(0.95, 0.2, 0.7, 1),
		"desc": "天生对维度裂缝敏感，能看到常人无法察觉的异常现象",
		"stats": {"int": 12, "per": 18, "agi": 8, "cha": 10},
		"skills": ["维度感知", "灵能冲击"],
		"sprite_path": "res://assets/characters/select/echo.png",
		"identity_type": "Psionic Resonance Specialist",
		"residence": "Neo Harbor - Block 03",
		"sync_rate": 94,
		"risk_level": "ELEVATED",
		"credit_rating": "A-",
		"network_status": "异常波动",
		"keywords": ["灵能共鸣", "异常感知", "现实裂隙"],
		"initial_affinity": {"sun_yue": "孙悦"},
	},
	{
		"id": 3,
		"name_cn": "暗影潜行者",
		"name_en": "SHADOW",
		"color": Color(0.3, 1, 0.5, 1),
		"desc": "游走于暗巷与黑市之间的情报专家，信息网络遍布全城",
		"stats": {"int": 10, "per": 10, "agi": 18, "cha": 8},
		"skills": ["隐匿行踪", "信息网络"],
		"sprite_path": "res://assets/characters/select/shadow.png",
		"identity_type": "Shadow Network Agent",
		"residence": "Neo Harbor - Block 22",
		"sync_rate": 65,
		"risk_level": "MONITORED",
		"credit_rating": "C",
		"network_status": "加密通道",
		"keywords": ["隐匿协议", "网络潜伏", "情报渗透"],
		"initial_affinity": {"zhao_lin": "赵霖"},
	},
]

const STATUS_MESSAGES = [
	"正在同步城市身份档案...",
	"正在连接 Neo Harbor 网络...",
	"正在读取精神适配数据...",
	"正在验证接入权限...",
	"正在加载城市地图数据...",
	"身份协议握手完成...",
	"正在扫描维度坐标...",
	"城市安全协议已激活...",
]

const CITY_INFO_POOL = [
	"Neo Harbor 降雨概率：78%",
	"高架列车延迟运行",
	"DATAWHALE 招聘实习分析员",
	"检测到未识别网络信号",
	"城市空气质量：良",
	"Block 09 区域网络维护中",
	"义体诊所预约已满",
	"维度监测站：正常",
	"黑市交易指数上升 3.2%",
	"Neo Harbor 港口货运正常",
	"DATAWHALE 年度报告发布",
	"异常现象报告：0 件",
	"城市电力供应稳定",
	"地下数据链路流量增加",
	"Block 17 发生小型停电",
	"量子咖啡推出新饮品",
]

const ANOMALY_MESSAGES = [
	"WARNING: UNAUTHORIZED SIGNAL DETECTED",
	"UNKNOWN PROTOCOL CONNECTED",
	"ANOMALY DETECTED IN SECTOR 7",
	"DIMENSIONAL RIFT SIGNATURE FOUND",
	"DATA CORRUPTION IN BLOCK 12",
	"UNAUTHORIZED ACCESS ATTEMPT LOGGED",
]

@onready var _city_bg: ColorRect = $CityNetworkBG
@onready var _scan_overlay: ColorRect = $ScanLineOverlay
@onready var _glitch_overlay: ColorRect = $GlitchOverlay
@onready var _status_label: Label = $MainLayout/HeaderArea/StatusLabel
@onready var _archive_content: VBoxContainer = $MainLayout/ContentArea/LeftPanel/LeftContent/ArchiveContent
@onready var _class_tabs: HBoxContainer = $MainLayout/ContentArea/LeftPanel/LeftContent/ClassTabs
@onready var _char_anim_rect: TextureRect = $MainLayout/ContentArea/CenterPanel/CenterContent/CharacterDisplay/CharAnim
@onready var _codename_label: Label = $MainLayout/ContentArea/CenterPanel/CenterContent/CodenameLabel
@onready var _scan_bar: ColorRect = $MainLayout/ContentArea/CenterPanel/CenterContent/ScanBar
@onready var _class_cn_name: Label = $MainLayout/ContentArea/CenterPanel/CenterContent/ClassCnName
@onready var _class_desc: Label = $MainLayout/ContentArea/CenterPanel/CenterContent/ClassDesc
@onready var _class_trait: HBoxContainer = $MainLayout/ContentArea/CenterPanel/CenterContent/ClassTrait
@onready var _trait_bar: ColorRect = $MainLayout/ContentArea/CenterPanel/CenterContent/ClassTrait/TraitBar
@onready var _trait_label: Label = $MainLayout/ContentArea/CenterPanel/CenterContent/ClassTrait/TraitLabel
@onready var _stats_box: VBoxContainer = $MainLayout/ContentArea/RightPanel/RightContent/StatsBox
@onready var _skills_box: VBoxContainer = $MainLayout/ContentArea/RightPanel/RightContent/SkillsBox
@onready var _affinity_box: VBoxContainer = $MainLayout/ContentArea/RightPanel/RightContent/AffinityBox
@onready var _info_stream: Label = $MainLayout/FooterArea/InfoStream
@onready var _name_input: LineEdit = $MainLayout/FooterArea/InputRow/NameInput
@onready var _confirm_btn: Button = $MainLayout/FooterArea/InputRow/ConfirmBtn
@onready var _anomaly_label: Label = $AnomalyLabel
@onready var _style_label: Label = $StyleIndicator

func _ready() -> void:
	if has_node("FoxIcon"):
		get_node("FoxIcon").queue_free()
		push_warning("已移除非法 FoxIcon 节点")
	if has_node("LogButton"):
		get_node("LogButton").queue_free()
		push_warning("已移除非法 LogButton 节点")

	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _fade_active = false)
	_build_class_tabs()
	_apply_input_styles()
	_apply_confirm_styles()
	_fix_center_content_spacing()
	_connect_signals()
	_build_static_panels()
	_select_class(0)
	_next_anomaly_time = 30.0 + randf() * 15.0
	_update_style_indicator()

func _process(delta: float) -> void:
	_anim_time += delta
	_update_idle_animation(delta)

	_frame_counter += 1
	if _frame_counter & 1:
		_update_shaders(delta)

	_update_status_text(delta)
	_update_info_stream(delta)
	_update_anomaly(delta)
	_update_scan_bar(delta)

func _update_shaders(_delta: float) -> void:
	if _city_bg and _city_bg.material:
		_city_bg.material.set_shader_parameter("time", _anim_time)
	if _scan_overlay and _scan_overlay.material:
		_scan_overlay.material.set_shader_parameter("time", _anim_time)
	if _glitch_overlay and _glitch_overlay.material:
		_glitch_overlay.material.set_shader_parameter("time", _anim_time)

func _update_status_text(delta: float) -> void:
	_status_timer += delta
	if _status_timer >= 3.0:
		_status_timer = 0.0
		_status_idx = (_status_idx + 1) % STATUS_MESSAGES.size()
		if _status_label:
			var tw = create_tween()
			tw.tween_property(_status_label, "modulate:a", 0.0, 0.3)
			tw.tween_callback(func(): _status_label.text = STATUS_MESSAGES[_status_idx])
			tw.tween_property(_status_label, "modulate:a", 1.0, 0.3)

func _update_info_stream(delta: float) -> void:
	_info_timer += delta
	if _info_timer >= 5.0:
		_info_timer = 0.0
		_info_idx = (_info_idx + 1) % CITY_INFO_POOL.size()
		if _info_stream:
			var tw = create_tween()
			tw.tween_property(_info_stream, "modulate:a", 0.0, 0.3)
			tw.tween_callback(func(): _info_stream.text = "▸ " + CITY_INFO_POOL[_info_idx])
			tw.tween_property(_info_stream, "modulate:a", 1.0, 0.3)

func _update_anomaly(delta: float) -> void:
	if _anomaly_active:
		return
	_anomaly_timer += delta
	if _anomaly_timer >= _next_anomaly_time:
		_anomaly_timer = 0.0
		_next_anomaly_time = 30.0 + randf() * 15.0
		_trigger_anomaly()

func _trigger_anomaly() -> void:
	_anomaly_active = true
	var msg = ANOMALY_MESSAGES[randi() % ANOMALY_MESSAGES.size()]
	var duration = 0.3 + randf() * 0.5

	if _glitch_overlay and _glitch_overlay.material:
		_glitch_overlay.visible = true
		_glitch_overlay.material.set_shader_parameter("intensity", 0.3)

	if _anomaly_label:
		_anomaly_label.text = msg
		_anomaly_label.visible = true
		_anomaly_label.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(_anomaly_label, "modulate:a", 1.0, 0.1)
		tw.tween_interval(duration)
		tw.tween_property(_anomaly_label, "modulate:a", 0.0, 0.2)
		tw.tween_callback(func():
			_anomaly_label.visible = false
		)

	var tw2 = create_tween()
	tw2.tween_interval(duration + 0.3)
	tw2.tween_callback(func():
		if _glitch_overlay and _glitch_overlay.material:
			_glitch_overlay.visible = false
			_glitch_overlay.material.set_shader_parameter("intensity", 0.0)
		_anomaly_active = false
	)

func _update_scan_bar(_delta: float) -> void:
	if not _scan_bar:
		return
	var y_offset = sin(_anim_time * 2.0) * 30.0
	_scan_bar.position.y = y_offset
	_scan_bar.modulate.a = 0.4 + sin(_anim_time * 3.0) * 0.3

func _update_idle_animation(delta: float) -> void:
	if _idle_frames.size() <= 1 or not _char_anim_rect:
		return
	_idle_timer += delta
	if _idle_timer >= IDLE_FRAME_INTERVAL:
		_idle_timer -= IDLE_FRAME_INTERVAL
		_idle_frame_idx = (_idle_frame_idx + 1) % _idle_frames.size()
		if _char_anim_rect.texture != _idle_frames[_idle_frame_idx]:
			_char_anim_rect.texture = _idle_frames[_idle_frame_idx]

func _build_class_tabs() -> void:
	if not _class_tabs:
		return
	for data in CLASS_DATA:
		var btn = Button.new()
		btn.text = data["name_en"]
		btn.custom_minimum_size = Vector2(80, 28)
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(data.color.r * 0.08, data.color.g * 0.08, data.color.b * 0.08, 0.9)
		normal_style.set_border_width_all(1)
		normal_style.border_color = Color(data.color.r, data.color.g, data.color.b, 0.3)
		normal_style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", normal_style)
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(data.color.r * 0.15, data.color.g * 0.15, data.color.b * 0.15, 0.95)
		hover_style.set_border_width_all(1)
		hover_style.border_color = Color(data.color.r, data.color.g, data.color.b, 0.6)
		hover_style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_color_override("font_color", Color(data.color.r, data.color.g, data.color.b, 0.7))
		btn.add_theme_color_override("font_hover_color", data.color)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_on_tab_press.bind(data["id"]))
		btn.mouse_entered.connect(_on_class_hovered.bind(data))
		btn.mouse_exited.connect(_on_class_unhovered)
		_class_tabs.add_child(btn)
		_class_tabs_data.append({"btn": btn, "data": data, "idx": data["id"]})

func _on_tab_press(idx: int) -> void:
	_select_class(idx)

func _on_class_hovered(data: Dictionary) -> void:
	if _glitch_overlay and _glitch_overlay.material:
		_glitch_overlay.visible = true
		_glitch_overlay.material.set_shader_parameter("intensity", 0.15)
	if _scan_overlay and _scan_overlay.material:
		_scan_overlay.material.set_shader_parameter("line_color", Color(data.color.r, data.color.g, data.color.b, 0.06))
	_play_scan_animation()

func _on_class_unhovered() -> void:
	if _glitch_overlay and not _anomaly_active and _glitch_overlay.material:
		_glitch_overlay.visible = false
		_glitch_overlay.material.set_shader_parameter("intensity", 0.0)
	if _scan_overlay and _scan_overlay.material and _selected_class >= 0 and _selected_class < CLASS_DATA.size():
		var ccm_data = CLASS_DATA[_selected_class]
		_scan_overlay.material.set_shader_parameter("line_color", Color(ccm_data.color.r, ccm_data.color.g, ccm_data.color.b, 0.03))

func _apply_input_styles() -> void:
	if not _name_input:
		return
	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.02, 0.03, 0.06, 0.9)
	ns.set_border_width_all(1)
	ns.border_color = Color(0.3, 0.35, 0.45, 0.5)
	ns.set_corner_radius_all(4)
	_name_input.add_theme_stylebox_override("normal", ns)
	var fs = StyleBoxFlat.new()
	fs.bg_color = Color(0.02, 0.03, 0.06, 0.9)
	fs.set_border_width_all(2)
	fs.border_color = Color(0, 0.85, 1, 0.7)
	fs.set_corner_radius_all(4)
	fs.shadow_color = Color(0, 0.85, 1, 0.2)
	fs.shadow_size = 8
	_name_input.add_theme_stylebox_override("focus", fs)
	_name_input.add_theme_color_override("font_color", Color(0.82, 0.85, 0.92, 1))
	_name_input.add_theme_color_override("caret_color", Color(0, 0.85, 1, 1))
	_name_input.add_theme_color_override("placeholder_color", Color(0.35, 0.4, 0.5, 0.6))

func _apply_confirm_styles() -> void:
	if not _confirm_btn:
		return
	var bn = StyleBoxFlat.new()
	bn.bg_color = Color(0, 0.75, 0.95, 1)
	bn.set_corner_radius_all(6)
	_confirm_btn.add_theme_stylebox_override("normal", bn)
	var bh = StyleBoxFlat.new()
	bh.bg_color = Color(0.3, 1, 1, 1)
	bh.set_corner_radius_all(6)
	bh.shadow_color = Color(0, 0.85, 1, 0.45)
	bh.shadow_size = 10
	_confirm_btn.add_theme_stylebox_override("hover", bh)
	var bp = StyleBoxFlat.new()
	bp.bg_color = Color(0, 0.6, 0.75, 1)
	bp.set_corner_radius_all(6)
	_confirm_btn.add_theme_stylebox_override("pressed", bp)
	_confirm_btn.add_theme_color_override("font_color", Color(0.02, 0.02, 0.05, 1))
	_confirm_btn.add_theme_font_size_override("font_size", 15)

func _connect_signals() -> void:
	if _confirm_btn:
		_confirm_btn.pressed.connect(_on_confirm)
	if has_node("/root/MediaManager"):
		get_node("/root/MediaManager").class_portrait_ready.connect(_on_class_portrait_ready)

func _build_static_panels() -> void:
	if _archive_content:
		var field_defs = [
			{"label": "身份类型", "type": "text"},
			{"label": "居住区域", "type": "text"},
			{"label": "精神适配率", "type": "bar"},
			{"label": "异常接触等级", "type": "risk"},
			{"label": "城市信用等级", "type": "text"},
			{"label": "最近网络活动", "type": "status"},
		]
		for field in field_defs:
			var row = VBoxContainer.new()
			row.add_theme_constant_override("separation", 2)
			var lbl = Label.new()
			lbl.text = field["label"]
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55, 0.7))
			row.add_child(lbl)
			var val = Label.new()
			val.add_theme_font_size_override("font_size", 13)
			val.add_theme_color_override("font_color", Color(0.82, 0.85, 0.92, 1))
			_left_field_labels.append(lbl)
			_left_field_values.append(val)
			if field["type"] == "bar":
				var hbox = HBoxContainer.new()
				hbox.add_theme_constant_override("separation", 6)
				_left_bar = ProgressBar.new()
				_left_bar.max_value = 100.0
				_left_bar.value = 0.0
				_left_bar.custom_minimum_size = Vector2(120, 12)
				_left_bar.show_percentage = false
				var bar_bg = StyleBoxFlat.new()
				bar_bg.bg_color = Color(0.08, 0.1, 0.15, 0.8)
				bar_bg.set_corner_radius_all(2)
				_left_bar.add_theme_stylebox_override("background", bar_bg)
				hbox.add_child(_left_bar)
				_left_bar_val_lbl = Label.new()
				_left_bar_val_lbl.add_theme_font_size_override("font_size", 12)
				hbox.add_child(_left_bar_val_lbl)
				row.add_child(hbox)
			else:
				row.add_child(val)
			_archive_content.add_child(row)
	if _stats_box:
		for key in ["int", "per", "agi", "cha"]:
			var hbox = HBoxContainer.new()
			hbox.custom_minimum_size = Vector2(0, 22)
			hbox.add_theme_constant_override("separation", 6)
			var key_lbl = Label.new()
			key_lbl.custom_minimum_size = Vector2(80, 20)
			key_lbl.add_theme_font_size_override("font_size", 11)
			key_lbl.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68, 1))
			hbox.add_child(key_lbl)
			var bar = ProgressBar.new()
			bar.max_value = 20
			bar.value = 0.0
			bar.custom_minimum_size = Vector2(100, 10)
			bar.show_percentage = false
			var bar_bg = StyleBoxFlat.new()
			bar_bg.bg_color = Color(0.08, 0.1, 0.15, 0.7)
			bar_bg.set_corner_radius_all(2)
			bar.add_theme_stylebox_override("background", bar_bg)
			hbox.add_child(bar)
			var val_lbl = Label.new()
			val_lbl.custom_minimum_size = Vector2(24, 20)
			val_lbl.add_theme_font_size_override("font_size", 12)
			hbox.add_child(val_lbl)
			_stats_box.add_child(hbox)
			_stat_bars[key] = {"label": key_lbl, "bar": bar, "val_lbl": val_lbl}
	if _skills_box:
		for i in range(2):
			var hbox = HBoxContainer.new()
			hbox.custom_minimum_size = Vector2(0, 20)
			hbox.add_theme_constant_override("separation", 6)
			var icon = Label.new()
			icon.text = ">>"
			icon.custom_minimum_size = Vector2(20, 18)
			icon.add_theme_font_size_override("font_size", 12)
			hbox.add_child(icon)
			var lbl = Label.new()
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.86, 1))
			hbox.add_child(lbl)
			_skills_box.add_child(hbox)
			_skill_labels.append({"hbox": hbox, "icon": icon, "label": lbl})
	if _affinity_box:
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 20)
		hbox.add_theme_constant_override("separation", 6)
		var icon = Label.new()
		icon.text = "◈"
		icon.custom_minimum_size = Vector2(20, 18)
		icon.add_theme_font_size_override("font_size", 12)
		hbox.add_child(icon)
		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.86, 1))
		hbox.add_child(lbl)
		_affinity_box.add_child(hbox)
		_affinity_labels.append({"hbox": hbox, "icon": icon, "label": lbl})

func _select_class(idx: int) -> void:
	_selected_class = idx
	var data = CLASS_DATA[idx]
	_current_accent = data.color
	_load_idle_animation(idx)
	_update_tab_styles()
	_update_left_panel(data)
	_update_center_panel(data)
	_update_right_panel(data)
	_transition_bg_color(data.color)
	_play_scan_animation()

func _load_idle_animation(class_id: int) -> void:
	_idle_frames.clear()
	_idle_frame_idx = 0
	_idle_timer = 0.0

	var class_names = ["cipher", "chrome", "echo", "shadow"]
	if class_id < 0 or class_id >= class_names.size():
		return
	var cname = class_names[class_id]
	var style_prefix = "anime_" if _use_anime_style else ""
	var cache_key = style_prefix + cname

	if _texture_cache.has(cache_key):
		_idle_frames = _texture_cache[cache_key]
	else:
		var subdir = "anime/" if _use_anime_style else ""
		var base_path = "res://assets/characters/select/idle/" + subdir + cname
		for i in range(12):
			var path = base_path + "/" + cname + "_idle_%d.jpg" % i
			if ResourceLoader.exists(path):
				var tex = load(path)
				if tex:
					_idle_frames.append(tex)
		_texture_cache[cache_key] = _idle_frames

	if _idle_frames.size() > 0 and _char_anim_rect:
		_char_anim_rect.texture = _idle_frames[0]
	elif _char_anim_rect:
		_char_anim_rect.texture = null

func _toggle_visual_style() -> void:
	_use_anime_style = not _use_anime_style
	_select_class(_selected_class)
	_update_style_indicator()

func _update_style_indicator() -> void:
	if not _style_label:
		return
	if _use_anime_style:
		_style_label.text = "[ F5 ] 二次元风格 ANIME"
	else:
		_style_label.text = "[ F5 ] 写实赛博 REALISTIC"

func _update_tab_styles() -> void:
	for tab_info in _class_tabs_data:
		var btn = tab_info["btn"]
		var data = tab_info["data"]
		var is_selected = tab_info["idx"] == _selected_class
		var s = StyleBoxFlat.new()
		s.set_corner_radius_all(4)
		if is_selected:
			s.bg_color = Color(data.color.r * 0.2, data.color.g * 0.2, data.color.b * 0.2, 0.95)
			s.set_border_width_all(2)
			s.border_color = data.color
			s.shadow_color = Color(data.color.r, data.color.g, data.color.b, 0.3)
			s.shadow_size = 8
			btn.add_theme_color_override("font_color", data.color)
		else:
			s.bg_color = Color(data.color.r * 0.08, data.color.g * 0.08, data.color.b * 0.08, 0.9)
			s.set_border_width_all(1)
			s.border_color = Color(data.color.r, data.color.g, data.color.b, 0.3)
			btn.add_theme_color_override("font_color", Color(data.color.r, data.color.g, data.color.b, 0.7))
		btn.add_theme_stylebox_override("normal", s)

func _update_left_panel(data: Dictionary) -> void:
	if _left_field_values.size() < 6:
		return
	_left_field_values[0].text = str(data["identity_type"])
	_left_field_values[1].text = str(data["residence"])
	_left_bar_val_lbl.text = str(data["sync_rate"]) + "%"
	_left_bar_val_lbl.add_theme_color_override("font_color", data.color)
	var bar_fg = StyleBoxFlat.new()
	bar_fg.bg_color = Color(data.color.r, data.color.g, data.color.b, 0.75)
	bar_fg.set_corner_radius_all(2)
	_left_bar.add_theme_stylebox_override("fill", bar_fg)
	var tw = create_tween()
	tw.tween_property(_left_bar, "value", float(data["sync_rate"]), 0.4).set_ease(Tween.EASE_OUT)
	_left_field_values[3].text = str(data["risk_level"])
	var risk_color = Color(0.3, 0.9, 0.5, 1)
	if str(data["risk_level"]) == "MONITORED":
		risk_color = Color(1, 0.7, 0.2, 1)
	elif str(data["risk_level"]) == "ELEVATED":
		risk_color = Color(0.9, 0.3, 0.5, 1)
	_left_field_values[3].add_theme_color_override("font_color", risk_color)
	_left_field_values[4].text = str(data["credit_rating"])
	_left_field_values[5].text = str(data["network_status"])

func _fix_center_content_spacing() -> void:
	pass

func _update_center_panel(data: Dictionary) -> void:
	if _codename_label:
		_codename_label.text = data["name_en"]
		_codename_label.add_theme_color_override("font_color", data.color)
	if _class_cn_name:
		_class_cn_name.text = data["name_cn"]
	if _class_desc:
		_class_desc.text = data["desc"]
	if _scan_bar:
		_scan_bar.color = Color(data.color.r, data.color.g, data.color.b, 1)
	if _class_trait:
		_class_trait.visible = true
	if _trait_bar:
		_trait_bar.color = Color(data.color.r, data.color.g, data.color.b, 0.6)
	if _trait_label:
		var ccm_data = {}
		if has_node("/root/CharacterClassManager"):
			ccm_data = get_node("/root/CharacterClassManager").CLASS_DATA.get(data["id"], {})
		var aliases = ccm_data.get("aliases", [])
		if aliases.size() > 0:
			var alias = aliases[randi() % aliases.size()]
			_trait_label.text = "> " + data["name_en"] + " // " + alias
		else:
			_trait_label.text = "> " + data["name_en"] + " // " + data["keywords"][0]
		_trait_label.add_theme_color_override("font_color", Color(data.color.r, data.color.g, data.color.b, 0.85))

	_request_class_preview(data["id"])

func _update_right_panel(data: Dictionary) -> void:
	_update_stats(data)
	_update_skills(data)
	_update_affinity(data)

func _update_stats(data: Dictionary) -> void:
	var stat_labels = {"int": "INT 智力", "per": "PER 感知", "agi": "AGI 敏捷", "cha": "CHA 社交"}
	for key in ["int", "per", "agi", "cha"]:
		if not _stat_bars.has(key):
			continue
		var s = _stat_bars[key]
		s["label"].text = stat_labels[key]
		s["val_lbl"].text = str(int(data["stats"][key]))
		s["val_lbl"].add_theme_color_override("font_color", data.color)
		var bar_fg = StyleBoxFlat.new()
		bar_fg.bg_color = Color(data.color.r, data.color.g, data.color.b, 0.7)
		bar_fg.set_corner_radius_all(2)
		s["bar"].add_theme_stylebox_override("fill", bar_fg)
		var stat_order = ["int", "per", "agi", "cha"]
		var delay = float(stat_order.find(key)) * 0.1
		var tw = create_tween()
		tw.tween_interval(delay)
		tw.tween_property(s["bar"], "value", float(data["stats"][key]), 0.4).set_ease(Tween.EASE_OUT)

func _update_skills(data: Dictionary) -> void:
	var skills = data.get("skills", [])
	for i in range(_skill_labels.size()):
		if i < skills.size():
			_skill_labels[i]["hbox"].visible = true
			_skill_labels[i]["icon"].add_theme_color_override("font_color", data.color)
			_skill_labels[i]["label"].text = skills[i]
		else:
			_skill_labels[i]["hbox"].visible = false

func _update_affinity(data: Dictionary) -> void:
	var affinity = data.get("initial_affinity", {})
	var idx = 0
	for npc_id in affinity:
		if idx < _affinity_labels.size():
			_affinity_labels[idx]["hbox"].visible = true
			_affinity_labels[idx]["icon"].add_theme_color_override("font_color", Color(1, 0.5, 0.7, 0.8))
			_affinity_labels[idx]["label"].text = str(affinity[npc_id]) + " +10"
		idx += 1
	for i in range(idx, _affinity_labels.size()):
		_affinity_labels[i]["hbox"].visible = false

func _transition_bg_color(target_color: Color) -> void:
	if not _city_bg or not _city_bg.material:
		return
	var accent = Color(target_color.r, target_color.g, target_color.b, 0.15)
	var tw = create_tween()
	tw.tween_property(_city_bg.material, "shader_parameter/accent_color", accent, 0.6)

	if _scan_overlay and _scan_overlay.material:
		var scan_color = Color(target_color.r, target_color.g, target_color.b, 0.03)
		var tw2 = create_tween()
		tw2.tween_property(_scan_overlay.material, "shader_parameter/line_color", scan_color, 0.6)

func _play_scan_animation() -> void:
	if not _scan_bar:
		return
	_scan_bar.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(_scan_bar, "modulate:a", 1.0, 0.2)
	tw.tween_property(_scan_bar, "modulate:a", 0.4, 0.3)

func _input(event: InputEvent) -> void:
	if _fade_active:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				_navigate(-1)
				get_viewport().set_input_as_handled()
			KEY_RIGHT:
				_navigate(1)
				get_viewport().set_input_as_handled()
			KEY_ENTER:
				_on_confirm()
				get_viewport().set_input_as_handled()
			KEY_F5:
				_toggle_visual_style()
				get_viewport().set_input_as_handled()

func _navigate(dir: int) -> void:
	var next_idx = wrapi(_selected_class + dir, 0, CLASS_DATA.size())
	_select_class(next_idx)

func _request_class_preview(class_id: int) -> void:
	if class_id == _last_class_preview_requested:
		return
	_last_class_preview_requested = class_id
	if not has_node("/root/MediaManager"):
		return
	var mm = get_node("/root/MediaManager")
	if not mm.has_method("request_class_portrait"):
		return
	mm.request_class_portrait(class_id)

func _on_class_portrait_ready(_class_id: int, texture: Texture2D) -> void:
	pass

func _on_confirm() -> void:
	if _selected_class < 0 or _fade_active:
		return
	_fade_active = true
	var pname = ""
	if _name_input:
		pname = _name_input.text.strip_edges()
	if pname.is_empty():
		pname = "玩家"

	if _glitch_overlay:
		_glitch_overlay.visible = true
		_glitch_overlay.material.set_shader_parameter("intensity", 0.3)

	var tw = create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(self, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	await tw.finished

	if has_node("/root/CharacterClassManager"):
		get_node("/root/CharacterClassManager").select_class(_selected_class, pname)
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game()
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").transition_to(get_node("/root/SceneManager").GameScene.APARTMENT)
	else:
		push_error("SceneManager missing!")
		modulate.a = 1.0
		_fade_active = false
