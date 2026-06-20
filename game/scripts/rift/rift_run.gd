extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $EnemySpawner
@onready var hud: CanvasLayer = $RiftHUD
@onready var tile_select: CanvasLayer = $RiftTileSelect
@onready var result_panel: CanvasLayer = $RiftResultPanel
@onready var background: Sprite2D = $Background
@onready var pause_panel: Panel = $PauseLayer/PausePanel
@onready var environment_manager: Node = $RiftEnvironmentManager

var _run_data: Dictionary = {}
var _result_open: bool = false
var _previous_max_fps: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_rift_framerate()
	_load_background()
	_bind_nodes()
	_start_run()

func _exit_tree() -> void:
	if _previous_max_fps >= 0:
		Engine.max_fps = _previous_max_fps

func _load_background() -> void:
	var path := "res://assets/rift/backgrounds/western_fantasy_dawn_data_rain.png"
	var tex := _load_texture(path)
	if tex:
		background.texture = tex
		background.position = Vector2(960, 540)
		background.scale = _scale_background(tex)
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _apply_rift_framerate() -> void:
	_previous_max_fps = Engine.max_fps
	Engine.max_fps = 120

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(path):
		var image := Image.new()
		var err := image.load(path)
		if err == OK:
			return ImageTexture.create_from_image(image)
	return null

func _scale_background(tex: Texture2D) -> Vector2:
	var size: Vector2 = tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ONE
	return Vector2(1920.0 / size.x, 1080.0 / size.y)

func _bind_nodes() -> void:
	if player:
		player.died.connect(_on_player_died)
		player.took_damage.connect(_on_player_took_damage)
	if spawner:
		spawner.node_cleared.connect(_on_node_cleared)
		spawner.wave_changed.connect(_on_wave_changed)
	if hud:
		hud.bind_player(player)
		hud.evacuate_requested.connect(_on_evacuate_requested)
	if tile_select:
		tile_select.tile_chosen.connect(_on_tile_chosen)
	if result_panel:
		result_panel.closed.connect(_return_to_anomaly_space)
	if pause_panel:
		pause_panel.visible = false

func _start_run() -> void:
	var manager = get_node_or_null("/root/RiftRunManager")
	if not manager:
		return
	_run_data = manager.start_run(0, manager.unlocked_difficulty)
	var tiles: Array = _run_data.get("tiles", [])
	if not tiles.is_empty() and environment_manager and environment_manager.has_method("apply_tile_environment"):
		environment_manager.apply_tile_environment(tiles[0], background)
	tile_select.show_tiles(_run_data)
	hud.set_run_progress(0, 9)

func _on_tile_chosen(tile_id: String) -> void:
	var manager = get_node_or_null("/root/RiftRunManager")
	if not manager:
		return
	var tile: Dictionary = manager.choose_tile(tile_id)
	if tile.is_empty():
		return
	tile_select.hide_tiles()
	hud.set_node_info(tile)
	if environment_manager and environment_manager.has_method("apply_tile_environment"):
		environment_manager.apply_tile_environment(tile, background)
	spawner.start_node(tile, int(_run_data.get("difficulty", 1)))

func _on_node_cleared(kill_count: int, damage_taken: float, combo_best: int) -> void:
	var manager = get_node_or_null("/root/RiftRunManager")
	if not manager:
		return
	manager.complete_current_node(kill_count, damage_taken, combo_best)
	_run_data = manager.active_run.duplicate(true)
	var cleared: int = _run_data.get("cleared_tiles", []).size()
	hud.set_run_progress(cleared, 9)
	if cleared >= 9:
		_show_result(manager.end_run("cleared"))
	else:
		await get_tree().create_timer(0.45).timeout
		tile_select.show_tiles(_run_data)

func _on_wave_changed(wave: int, total_waves: int, enemies_alive: int) -> void:
	hud.set_wave(wave, total_waves, enemies_alive)
	hud.set_kills(spawner.kill_count, spawner.combo_best)

func _on_player_took_damage(amount: float) -> void:
	if spawner:
		spawner.record_player_damage(amount)

func _on_player_died() -> void:
	if _result_open:
		return
	if spawner:
		spawner.clear_enemies()
	var manager = get_node_or_null("/root/RiftRunManager")
	if manager:
		_show_result(manager.end_run("defeated"))

func _on_evacuate_requested() -> void:
	if _result_open:
		return
	if spawner:
		spawner.clear_enemies()
	var manager = get_node_or_null("/root/RiftRunManager")
	if manager:
		_show_result(manager.end_run("evacuated"))

func _show_result(result: Dictionary) -> void:
	_result_open = true
	tile_select.hide_tiles()
	result_panel.show_result(result)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and not _result_open:
			_toggle_pause()

func _toggle_pause() -> void:
	if not pause_panel:
		return
	pause_panel.visible = not pause_panel.visible
	get_tree().paused = pause_panel.visible

func _return_to_anomaly_space() -> void:
	get_tree().paused = false
	if has_node("/root/SceneManager"):
		var sm = get_node("/root/SceneManager")
		sm.transition_to(sm.GameScene.ANOMALY_SPACE)
