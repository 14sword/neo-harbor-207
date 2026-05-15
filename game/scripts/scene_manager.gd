extends Node

enum GameScene { OFFICE, STREET, UNDERGROUND, ANOMALY_SPACE, APARTMENT }

var current_scene: GameScene = GameScene.APARTMENT
var _transitioning: bool = false
var _pending_scene: GameScene = GameScene.APARTMENT
var _previous_scene: GameScene = GameScene.APARTMENT

signal scene_changed(scene: GameScene)

var _fade_overlay: ColorRect = null
var _persistent_nodes: Array[Node] = []

func _ready():
	print("[SceneManager] 初始化完成")
	_create_fade_overlay()

func _create_fade_overlay():
	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "SceneFadeOverlay"
	_fade_overlay.color = Color(0, 0, 0, 0)
	_fade_overlay.z_index = 100
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer = CanvasLayer.new()
	layer.name = "FadeLayer"
	layer.layer = 100
	layer.add_child(_fade_overlay)
	add_child(layer)

func register_persistent(node: Node):
	if not _persistent_nodes.has(node):
		_persistent_nodes.append(node)

func unregister_persistent(node: Node):
	_persistent_nodes.erase(node)

func transition_to(target: GameScene) -> void:
	if _transitioning:
		return
	_transitioning = true
	_pending_scene = target

	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game()

	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	for node in _persistent_nodes:
		if is_instance_valid(node) and node.get_parent():
			node.get_parent().remove_child(node)
			add_child(node)

	var fade_out = create_tween()
	fade_out.tween_property(_fade_overlay, "color", Color(0, 0, 0, 1), 0.4)
	fade_out.tween_callback(_do_scene_change)

func _do_scene_change():
	_previous_scene = current_scene
	current_scene = _pending_scene

	var scene_path = ""
	match _pending_scene:
		GameScene.OFFICE:
			scene_path = "res://scenes/main.tscn"
		GameScene.STREET:
			scene_path = "res://scenes/street.tscn"
		GameScene.UNDERGROUND:
			scene_path = "res://scenes/underground.tscn"
		GameScene.ANOMALY_SPACE:
			scene_path = "res://scenes/anomaly_space.tscn"
		GameScene.APARTMENT:
			scene_path = "res://scenes/apartment.tscn"
		_:
			scene_path = "res://scenes/apartment.tscn"

	get_tree().change_scene_to_file(scene_path)

	await get_tree().process_frame
	await get_tree().process_frame

	var new_scene = get_tree().current_scene
	for node in _persistent_nodes:
		if is_instance_valid(node) and node.get_parent() == self:
			remove_child(node)
			if new_scene:
				new_scene.add_child(node)
	
	if has_node("/root/PetManager"):
		var pet = get_node("/root/PetManager").get_active_pet()
		if pet and is_instance_valid(pet):
			var player = get_tree().get_first_node_in_group("player")
			if player:
				pet.global_position = player.global_position + Vector2(-40, 20)

	if has_node("/root/DayNightManager"):
		get_node("/root/DayNightManager").rebuild_effects()

	scene_changed.emit(_pending_scene)

	var fade_in = create_tween()
	fade_in.tween_property(_fade_overlay, "color", Color(0, 0, 0, 0), 0.4)
	fade_in.tween_callback(func():
		_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_transitioning = false
	)

func get_spawn_position() -> Vector2:
	match current_scene:
		GameScene.OFFICE:
			if _previous_scene == GameScene.STREET:
				return Vector2(640, 640)
			return Vector2(640, 550)
		GameScene.STREET:
			if _previous_scene == GameScene.APARTMENT:
				return Vector2(1100, 700)
			return Vector2(836, 700)
		GameScene.APARTMENT:
			return Vector2(836, 700)
		_:
			return Vector2(640, 600)

func is_office() -> bool:
	return current_scene == GameScene.OFFICE

func is_street() -> bool:
	return current_scene == GameScene.STREET

func is_apartment() -> bool:
	return current_scene == GameScene.APARTMENT

func get_scene_name() -> String:
	match current_scene:
		GameScene.OFFICE: return "办公室"
		GameScene.STREET: return "街区"
		GameScene.APARTMENT: return "公寓"
		_: return "未知"
