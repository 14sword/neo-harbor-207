extends CanvasLayer

const CORNER_RADIUS_SM: int = 4
const CORNER_RADIUS_MD: int = 8
const CORNER_RADIUS_LG: int = 14
const SPACING_SM: int = 4
const SPACING_MD: int = 8
const SPACING_LG: int = 16
const ANIM_FAST: float = 0.1
const ANIM_NORMAL: float = 0.25
const ANIM_SLOW: float = 0.4
const FONT_SIZE_SM: int = 11
const FONT_SIZE_MD: int = 14
const FONT_SIZE_LG: int = 18
const FONT_SIZE_XL: int = 22
const FONT_SIZE_XXL: int = 36

var font_regular: FontFile
var font_mono: FontFile

var _current_phase: String = "day"

var themes: Dictionary = {
	"day": {
		"panel_bg": Color(0.93, 0.90, 0.84, 0.94),
		"panel_border": Color(0.72, 0.53, 0.31, 0.7),
		"panel_shadow": Color(0.72, 0.53, 0.31, 0.2),
		"panel_corner": 14,
		"title_bar_bg": Color(0.88, 0.82, 0.7, 0.9),
		"title_color": Color(0.25, 0.16, 0.06),
		"text_color": Color(0.22, 0.17, 0.10),
		"secondary_color": Color(0.52, 0.42, 0.28),
		"accent_color": Color(0.83, 0.58, 0.42),
		"border_accent": Color(0.72, 0.53, 0.31),
		"close_bg": Color(0.77, 0.4, 0.23),
		"close_border": Color(0.9, 0.45, 0.25, 0.7),
		"success_color": Color(0.42, 0.69, 0.37),
		"warning_color": Color(0.9, 0.7, 0.2),
		"progress_bg": Color(0.88, 0.82, 0.7, 0.6),
		"progress_fill": Color(0.38, 0.65, 0.33),
		"card_bg": Color(0.84, 0.80, 0.72, 0.95),
		"card_border": Color(0.72, 0.53, 0.31, 0.6),
		"card_corner": 8,
		"hint_color": Color(0.45, 0.35, 0.22),
		"separator_color": Color(0.72, 0.53, 0.31, 0.3),
		"indicator_color": Color(0.72, 0.53, 0.31),
		"quest_type_dialogue": Color(0.25, 0.55, 0.85),
		"quest_type_exploration": Color(0.3, 0.7, 0.4),
		"quest_type_collection": Color(0.85, 0.6, 0.2),
		"quest_type_daily": Color(0.65, 0.4, 0.8),
		"quest_type_hidden": Color(0.85, 0.25, 0.3),
		"quest_type_story": Color(0.66, 0.34, 0.88),
		"scroll_bg": Color(0.91, 0.87, 0.79, 0.6),
		"filter_active_bg": Color(0.72, 0.53, 0.31, 0.3),
		"filter_inactive_bg": Color(0.88, 0.82, 0.7, 0.4),
		"quest_count_color": Color(0.72, 0.53, 0.31),
		"quest_active_glow": Color(0.42, 0.69, 0.37, 0.3),
		"quest_complete_tint": Color(0.55, 0.50, 0.40, 0.75),
		"dialogue_player_color": Color(0.25, 0.55, 0.85),
		"dialogue_npc_color": Color(0.83, 0.58, 0.42),
		"ambient_normal_bg": Color(0.91, 0.87, 0.79, 0.85),
		"ambient_normal_border": Color(0.72, 0.53, 0.31, 0.5),
		"ambient_normal_text": Color(0.25, 0.16, 0.06),
		"gradient_start": Color(0.83, 0.58, 0.42),
		"gradient_end": Color(0.42, 0.69, 0.37),
	},
	"dusk": {
		"panel_bg": Color(0.1, 0.055, 0.03, 0.95),
		"panel_border": Color(0.9, 0.6, 0.2, 0.7),
		"panel_shadow": Color(0.8, 0.4, 0.1, 0.3),
		"panel_corner": 12,
		"title_bar_bg": Color(0.13, 0.06, 0.03, 0.85),
		"title_color": Color(1.0, 0.85, 0.6),
		"text_color": Color(0.95, 0.9, 0.85),
		"secondary_color": Color(0.8, 0.6, 0.27),
		"accent_color": Color(1.0, 0.53, 0.2),
		"border_accent": Color(0.9, 0.6, 0.2),
		"close_bg": Color(0.7, 0.3, 0.15),
		"close_border": Color(0.9, 0.4, 0.2, 0.7),
		"success_color": Color(0.9, 0.6, 0.2),
		"warning_color": Color(1.0, 0.7, 0.2),
		"progress_bg": Color(0.15, 0.08, 0.04, 0.8),
		"progress_fill": Color(0.9, 0.6, 0.2),
		"card_bg": Color(0.12, 0.06, 0.03, 0.97),
		"card_border": Color(0.9, 0.6, 0.2, 0.5),
		"card_corner": 7,
		"hint_color": Color(0.8, 0.6, 0.27),
		"separator_color": Color(0.9, 0.6, 0.2, 0.3),
		"indicator_color": Color(0.9, 0.6, 0.2),
		"quest_type_dialogue": Color(0.3, 0.6, 0.9),
		"quest_type_exploration": Color(0.4, 0.8, 0.5),
		"quest_type_collection": Color(0.95, 0.7, 0.25),
		"quest_type_daily": Color(0.75, 0.45, 0.9),
		"quest_type_hidden": Color(0.95, 0.3, 0.35),
		"quest_type_story": Color(0.8, 0.45, 1.0),
		"scroll_bg": Color(0.12, 0.06, 0.03, 0.7),
		"filter_active_bg": Color(0.9, 0.6, 0.2, 0.3),
		"filter_inactive_bg": Color(0.15, 0.08, 0.04, 0.5),
		"quest_count_color": Color(0.9, 0.6, 0.2),
		"quest_active_glow": Color(0.9, 0.6, 0.2, 0.3),
		"quest_complete_tint": Color(0.45, 0.35, 0.25, 0.75),
		"dialogue_player_color": Color(0.3, 0.6, 0.9),
		"dialogue_npc_color": Color(1.0, 0.53, 0.2),
		"ambient_normal_bg": Color(0.12, 0.06, 0.03, 0.85),
		"ambient_normal_border": Color(0.9, 0.6, 0.2, 0.5),
		"ambient_normal_text": Color(0.95, 0.9, 0.85),
		"gradient_start": Color(1.0, 0.53, 0.2),
		"gradient_end": Color(0.9, 0.6, 0.2),
	},
	"night": {
		"panel_bg": Color(0.04, 0.055, 0.1, 0.96),
		"panel_border": Color(0, 0.93, 1, 0.6),
		"panel_shadow": Color(0, 0.93, 1, 0.25),
		"panel_corner": 10,
		"title_bar_bg": Color(0.024, 0.04, 0.08, 0.9),
		"title_color": Color(0, 0.93, 1),
		"text_color": Color(0.88, 0.89, 0.94),
		"secondary_color": Color(0.42, 0.44, 0.58),
		"accent_color": Color(0, 0.93, 1),
		"border_accent": Color(0, 0.93, 1),
		"close_bg": Color(0.8, 0.2, 0.2),
		"close_border": Color(1, 0.3, 0.3, 0.7),
		"success_color": Color(0.3, 1.0, 0.57),
		"warning_color": Color(1.0, 0.85, 0.2),
		"progress_bg": Color(0.05, 0.06, 0.11, 0.8),
		"progress_fill": Color(0, 0.93, 1),
		"card_bg": Color(0.05, 0.07, 0.14, 0.96),
		"card_border": Color(0, 0.93, 1, 0.5),
		"card_corner": 6,
		"hint_color": Color(0.42, 0.44, 0.58),
		"separator_color": Color(0, 0.93, 1, 0.3),
		"indicator_color": Color(0, 0.93, 1),
		"quest_type_dialogue": Color(0.3, 0.65, 1.0),
		"quest_type_exploration": Color(0.2, 0.9, 0.5),
		"quest_type_collection": Color(1.0, 0.75, 0.2),
		"quest_type_daily": Color(0.75, 0.45, 1.0),
		"quest_type_hidden": Color(1.0, 0.3, 0.4),
		"quest_type_story": Color(0.86, 0.56, 1.0),
		"scroll_bg": Color(0.05, 0.07, 0.14, 0.8),
		"filter_active_bg": Color(0, 0.93, 1, 0.2),
		"filter_inactive_bg": Color(0.05, 0.07, 0.14, 0.6),
		"quest_count_color": Color(0, 0.93, 1),
		"quest_active_glow": Color(0, 0.93, 1, 0.3),
		"quest_complete_tint": Color(0.28, 0.28, 0.38, 0.75),
		"dialogue_player_color": Color(0.3, 0.65, 1.0),
		"dialogue_npc_color": Color(0, 0.93, 1),
		"ambient_normal_bg": Color(0.05, 0.07, 0.14, 0.85),
		"ambient_normal_border": Color(0, 0.93, 1, 0.5),
		"ambient_normal_text": Color(0.88, 0.89, 0.94),
		"gradient_start": Color(0, 0.93, 1),
		"gradient_end": Color(0.3, 1.0, 0.57),
	}
}

func _ready():
	_load_fonts()
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		dnm.phase_changed.connect(_on_phase_changed)
		_update_phase()

func _load_fonts():
	font_regular = _try_load_font("res://assets/fonts/LXGWWenKai-Regular.ttf")
	font_mono = _try_load_font("res://assets/fonts/LXGWWenKaiMono-Regular.ttf")

func _try_load_font(path: String) -> FontFile:
	if ResourceLoader.exists(path):
		var res = ResourceLoader.load(path)
		if res is FontFile:
			return res
	var abs_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var data = load(path)
		if data is FontFile:
			return data
		if data != null:
			var font = FontFile.new()
			font.font_data = data
			return font
	return null

func _on_phase_changed(_new_phase):
	_update_phase()

func _update_phase():
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		match dnm.current_phase:
			DayNightManager.DayPhase.DAY:
				_current_phase = "day"
			DayNightManager.DayPhase.DUSK:
				_current_phase = "dusk"
			_:
				_current_phase = "night"
	else:
		_current_phase = "night"

func get_theme() -> Dictionary:
	return themes.get(_current_phase, themes["night"])

func get_phase() -> String:
	return _current_phase

func is_night() -> bool:
	return _current_phase == "night"

func is_day() -> bool:
	return _current_phase == "day"

func make_panel_style(corner: int = -1, border_w: int = 2, shadow_size: int = 6) -> StyleBoxFlat:
	var t = get_theme()
	var style = StyleBoxFlat.new()
	style.bg_color = t["panel_bg"]
	style.border_color = t["panel_border"]
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(corner if corner >= 0 else t["panel_corner"])
	style.shadow_color = t["panel_shadow"]
	style.shadow_size = shadow_size
	return style

func make_title_bar_style() -> StyleBoxFlat:
	var t = get_theme()
	var style = StyleBoxFlat.new()
	style.bg_color = t["title_bar_bg"]
	style.set_corner_radius_all(0)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func make_card_style() -> StyleBoxFlat:
	var t = get_theme()
	var style = StyleBoxFlat.new()
	style.bg_color = t["card_bg"]
	style.border_color = t["card_border"]
	style.set_border_width_all(1)
	style.set_corner_radius_all(t["card_corner"])
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = t["panel_shadow"]
	style.shadow_size = 4
	return style

func make_close_button_styles() -> Dictionary:
	var t = get_theme()
	var normal = StyleBoxFlat.new()
	normal.bg_color = t["close_bg"]
	normal.set_corner_radius_all(14)
	normal.set_border_width_all(2)
	normal.border_color = t["close_border"]
	normal.shadow_color = Color(1, 0, 0, 0.15)
	normal.shadow_size = 3

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(t["close_bg"].r + 0.1, t["close_bg"].g + 0.05, t["close_bg"].b + 0.05)
	hover.set_corner_radius_all(14)
	hover.set_border_width_all(2)
	hover.border_color = Color(t["close_border"].r, t["close_border"].g, t["close_border"].b, 0.9)
	hover.shadow_color = Color(1, 0, 0, 0.25)
	hover.shadow_size = 5

	return {"normal": normal, "hover": hover}

func make_separator() -> ColorRect:
	var t = get_theme()
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = t["separator_color"]
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sep

func apply_font_to_label(label: Label, size: int = 15, is_mono: bool = false):
	if is_mono and font_mono:
		label.add_theme_font_override("font", font_mono)
	elif font_regular:
		label.add_theme_font_override("font", font_regular)
	label.add_theme_font_size_override("font_size", size)

func apply_font_bold_to_label(label: Label, size: int = 16):
	apply_font_to_label(label, size)
	label.add_theme_constant_override("outline_size", 0)

func apply_font_to_rich_text(rt: RichTextLabel, size: int = 15, is_mono: bool = false):
	if is_mono and font_mono:
		rt.add_theme_font_override("normal_font", font_mono)
	elif font_regular:
		rt.add_theme_font_override("normal_font", font_regular)
	rt.add_theme_font_size_override("normal_font_size", size)

func apply_font_to_button(btn: Button, size: int = 15, is_mono: bool = false):
	if is_mono and font_mono:
		btn.add_theme_font_override("font", font_mono)
	elif font_regular:
		btn.add_theme_font_override("font", font_regular)
	btn.add_theme_font_size_override("font_size", size)

func apply_font_to_line_edit(le: LineEdit, size: int = 17):
	if font_regular:
		le.add_theme_font_override("font", font_regular)
	le.add_theme_font_size_override("font_size", size)

func get_breathing_border_alpha(time_sec: float) -> float:
	return 0.3 + sin(time_sec * 3.14) * 0.2

func make_breathing_border_style(time_sec: float) -> StyleBoxFlat:
	var t = get_theme()
	var alpha = get_breathing_border_alpha(time_sec)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(t["panel_bg"].r, t["panel_bg"].g, t["panel_bg"].b, t["panel_bg"].a)
	style.border_color = Color(t["border_accent"].r, t["border_accent"].g, t["border_accent"].b, alpha)
	style.set_border_width_all(2)
	style.set_corner_radius_all(t["panel_corner"])
	style.shadow_color = Color(t["panel_shadow"].r, t["panel_shadow"].g, t["panel_shadow"].b, alpha * 0.5)
	style.shadow_size = 4
	return style

const RARITY_COLORS: Dictionary = {
	"common": Color(0.7, 0.7, 0.7),
	"rare": Color(0.3, 0.6, 1.0),
	"epic": Color(0.7, 0.3, 0.9),
	"legendary": Color(1.0, 0.75, 0.2),
}

const RARITY_LABELS: Dictionary = {
	"common": "普通",
	"rare": "稀有",
	"epic": "史诗",
	"legendary": "传说",
}

func get_rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, RARITY_COLORS["common"])

func get_rarity_label(rarity: String) -> String:
	return RARITY_LABELS.get(rarity, "未知")

func make_item_card_style(rarity: String = "common") -> StyleBoxFlat:
	var rarity_color = get_rarity_color(rarity)
	var t = get_theme()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(t["card_bg"].r, t["card_bg"].g, t["card_bg"].b, t["card_bg"].a)
	style.border_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(t["card_corner"])
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.15)
	style.shadow_size = 3
	return style

func get_quest_type_color(type_name: String) -> Color:
	var t = get_theme()
	var key = "quest_type_" + type_name
	if t.has(key):
		return t[key]
	return t.get("accent_color", Color(1, 1, 1))

func get_quest_type_icon(type_name: String) -> String:
	match type_name:
		"dialogue": return "💬"
		"exploration": return "🔍"
		"collection": return "📦"
		"daily": return "🔄"
		"hidden": return "👻"
		"story": return "📖"
		_: return "◈"

func make_quest_type_tag(type_name: String) -> StyleBoxFlat:
	var color = get_quest_type_color(type_name)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.2)
	style.border_color = Color(color.r, color.g, color.b, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(CORNER_RADIUS_SM)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

func make_progress_bar_styles() -> Dictionary:
	var t = get_theme()
	var bg = StyleBoxFlat.new()
	bg.bg_color = t["progress_bg"]
	bg.set_corner_radius_all(CORNER_RADIUS_SM)
	bg.content_margin_left = 2
	bg.content_margin_right = 2
	bg.content_margin_top = 2
	bg.content_margin_bottom = 2
	var fill = StyleBoxFlat.new()
	fill.bg_color = t["progress_fill"]
	fill.set_corner_radius_all(CORNER_RADIUS_SM)
	return {"bg": bg, "fill": fill}

func make_accept_button_styles() -> Dictionary:
	var t = get_theme()
	var normal = StyleBoxFlat.new()
	normal.bg_color = t["success_color"]
	normal.set_corner_radius_all(CORNER_RADIUS_MD)
	normal.set_border_width_all(1)
	normal.border_color = Color(t["success_color"].r, t["success_color"].g, t["success_color"].b, 0.8)
	normal.shadow_color = Color(t["success_color"].r, t["success_color"].g, t["success_color"].b, 0.3)
	normal.shadow_size = 2
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(t["success_color"].r + 0.1, t["success_color"].g + 0.05, t["success_color"].b + 0.05)
	hover.set_corner_radius_all(CORNER_RADIUS_MD)
	hover.set_border_width_all(1)
	hover.border_color = Color(t["success_color"].r, t["success_color"].g, t["success_color"].b, 1.0)
	hover.shadow_color = Color(t["success_color"].r, t["success_color"].g, t["success_color"].b, 0.5)
	hover.shadow_size = 4
	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(t["success_color"].r - 0.1, t["success_color"].g - 0.05, t["success_color"].b - 0.05)
	pressed.set_corner_radius_all(CORNER_RADIUS_MD)
	pressed.set_border_width_all(1)
	pressed.border_color = Color(t["success_color"].r, t["success_color"].g, t["success_color"].b, 1.0)
	return {"normal": normal, "hover": hover, "pressed": pressed}

func make_filter_button_styles(is_active: bool) -> Dictionary:
	var t = get_theme()
	var bg_color = t["filter_active_bg"] if is_active else t["filter_inactive_bg"]
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.set_corner_radius_all(CORNER_RADIUS_MD)
	normal.set_border_width_all(1)
	normal.border_color = Color(bg_color.r, bg_color.g, bg_color.b, 0.8) if is_active else Color(bg_color.r, bg_color.g, bg_color.b, 0.3)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(bg_color.r, bg_color.g, bg_color.b, bg_color.a + 0.15)
	hover.set_corner_radius_all(CORNER_RADIUS_MD)
	hover.set_border_width_all(1)
	hover.border_color = Color(bg_color.r, bg_color.g, bg_color.b, 1.0) if is_active else Color(bg_color.r, bg_color.g, bg_color.b, 0.5)
	hover.content_margin_left = 10
	hover.content_margin_right = 10
	hover.content_margin_top = 5
	hover.content_margin_bottom = 5
	var font_color = t["title_color"] if is_active else t["secondary_color"]
	return {"normal": normal, "hover": hover, "font_color": font_color}

func make_scroll_container_style() -> StyleBoxFlat:
	var t = get_theme()
	var style = StyleBoxFlat.new()
	style.bg_color = t.get("scroll_bg", t["card_bg"])
	style.border_color = Color(t["card_border"].r, t["card_border"].g, t["card_border"].b, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(CORNER_RADIUS_MD)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
