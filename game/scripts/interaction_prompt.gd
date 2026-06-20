extends CanvasLayer

@onready var prompt_container: Panel = $PromptContainer
@onready var action_label: Label = $PromptContainer/Content/ActionLabel

var current_npc_name: String = ""
var fade_tween: Tween = null
var pulse_tween: Tween = null
var is_prompt_visible: bool = false

var name_map = {
	"zhang_san": "张三",
	"li_si": "李四",
	"wang_wu": "王五",
	"chen_xi": "陈曦",
	"zhao_lin": "赵霖",
	"sun_yue": "孙悦",
	"liu_feng": "刘风",
	"he_zhen": "何真"
}

var exit_map = {
	"exit_office": "离开办公室",
	"enter_office": "进入 DATAWHALE",
	"exit_street": "返回办公室",
	"enter_apartment": "进入公寓",
	"enter_underground": "进入地下站台",
	"enter_anomaly_space": "进入异常空间",
	"exit_apartment": "前往街区",
	"return_to_street": "返回街区",
	"return_to_underground": "返回地下站台",
	"return_to_apartment": "返回公寓",
	"enter_rift": "进入万界裂隙",
	"use_computer": "使用电脑",
	"use_bed": "睡觉",
	"observe_city": "观察城市",
	"watch_tv": "看电视",
	"check_talisman": "查看电子符纸",
	"check_plant": "查看植物",
	"check_clothesline": "查看晾衣架",
	"lean_railing": "靠在栏杆上",
	"open_fridge": "打开冰箱"
}

func _ready():
	add_to_group("interaction_prompt")
	prompt_container.visible = false
	_apply_theme()
	_apply_fonts()
	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").phase_changed.connect(_on_phase_changed)

func _on_phase_changed(_new_phase):
	_apply_theme()

func _apply_theme():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	var t = tm.get_theme()
	var style = prompt_container.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		var dup = style.duplicate() as StyleBoxFlat
		dup.bg_color = t["panel_bg"]
		dup.border_color = t["panel_border"]
		dup.shadow_color = t["panel_shadow"]
		prompt_container.add_theme_stylebox_override("panel", dup)
	var key_label = prompt_container.get_node_or_null("Content/KeyLabel")
	if key_label:
		key_label.add_theme_color_override("font_color", t["accent_color"])
	action_label.add_theme_color_override("font_color", t["text_color"])

func _apply_fonts():
	if not has_node("/root/UIThemeManager"):
		return
	var tm = get_node("/root/UIThemeManager")
	var key_label = prompt_container.get_node_or_null("Content/KeyLabel")
	if key_label:
		tm.apply_font_to_label(key_label, 17)
	tm.apply_font_to_label(action_label, 15)

func show_prompt(npc_id: String):
	var display_text = ""

	if name_map.has(npc_id):
		display_text = "按 [E] 与 " + name_map[npc_id] + " 对话"
	elif exit_map.has(npc_id):
		display_text = "按 [E] " + exit_map[npc_id]
	else:
		display_text = "按 [E] 交互"

	if current_npc_name == display_text and is_prompt_visible:
		return

	current_npc_name = display_text
	action_label.text = display_text

	if fade_tween:
		fade_tween.kill()
	if pulse_tween:
		pulse_tween.kill()

	prompt_container.visible = true
	prompt_container.modulate = Color(1, 1, 1, 0)

	fade_tween = create_tween()
	fade_tween.tween_property(prompt_container, "modulate", Color(1, 1, 1, 1), 0.25)
	fade_tween.set_trans(Tween.TRANS_CUBIC)

	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(prompt_container, "scale", Vector2(1.05, 1.05), 0.8)
	pulse_tween.tween_property(prompt_container, "scale", Vector2(1.0, 1.0), 0.8)
	pulse_tween.set_trans(Tween.TRANS_SINE)

	is_prompt_visible = true

func hide_prompt():
	if not is_prompt_visible:
		return

	if fade_tween:
		fade_tween.kill()
	if pulse_tween:
		pulse_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(prompt_container, "modulate", Color(1, 1, 1, 0), 0.2)
	fade_tween.tween_callback(func(): 
		prompt_container.visible = false
		prompt_container.scale = Vector2(1, 1)
	)
	fade_tween.set_trans(Tween.TRANS_CUBIC)

	current_npc_name = ""
	is_prompt_visible = false
