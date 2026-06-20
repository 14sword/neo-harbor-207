extends CanvasLayer

signal tile_chosen(tile_id: String)

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBox/Header/TitleLabel
@onready var subtitle_label: Label = $Panel/VBox/Header/SubtitleLabel
@onready var grid: GridContainer = $Panel/VBox/TileGrid

func _ready() -> void:
	visible = false
	_apply_theme()

func _apply_theme() -> void:
	var tm = get_node_or_null("/root/UIThemeManager")
	if tm and panel:
		panel.add_theme_stylebox_override("panel", tm.make_panel_style(10, 2, 10))
		for label in [title_label, subtitle_label]:
			if label:
				tm.apply_font_to_label(label, 18 if label == title_label else 13)

func show_tiles(run_data: Dictionary) -> void:
	visible = true
	for child in grid.get_children():
		child.queue_free()
	var cleared: Array = run_data.get("cleared_tiles", [])
	var tiles: Array = run_data.get("tiles", [])
	if subtitle_label:
		subtitle_label.text = "已清除 %d/%d 个镶片，选择下一块空间。" % [cleared.size(), tiles.size()]
	for tile in tiles:
		_add_tile_button(tile)

func hide_tiles() -> void:
	visible = false

func _add_tile_button(tile: Dictionary) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(220, 112)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = _tile_text(tile)
	btn.disabled = bool(tile.get("locked", false)) or bool(tile.get("cleared", false))
	btn.tooltip_text = tile.get("modifier", "")
	var c: Color = tile.get("color", Color(0.0, 0.9, 1.0, 1.0))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(c.r * 0.12, c.g * 0.12, c.b * 0.12, 0.94)
	style.border_color = Color(c.r, c.g, c.b, 0.68)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(c.r * 0.20, c.g * 0.20, c.b * 0.20, 0.98)
	btn.add_theme_stylebox_override("hover", hover)
	btn.pressed.connect(func(): tile_chosen.emit(tile.get("id", "")))
	grid.add_child(btn)

func _tile_text(tile: Dictionary) -> String:
	var status := ""
	if tile.get("cleared", false):
		status = "[已清除]\n"
	elif tile.get("locked", false):
		status = "[锁定]\n"
	var type_text := _type_name(tile.get("type", "normal"))
	return "%s%s  %02d\n%s · %s\n%s / %s" % [
		status,
		type_text,
		int(tile.get("index", 0)) + 1,
		tile.get("layer_name", "未知层"),
		tile.get("realm_name", "未知世界"),
		tile.get("time_name", tile.get("time_phase", "未知时相")),
		tile.get("weather_name", tile.get("weather", "未知天气")),
	]

func _type_name(tile_type: String) -> String:
	match tile_type:
		"event": return "异闻"
		"elite": return "精英"
		"shop": return "商店"
		"boss": return "首领"
		_: return "普通"
