extends Node

var _pet_scenes: Dictionary = {
	"fox": "res://scenes/fox.tscn",
	"opossum": "res://scenes/opossum.tscn",
	"eagle": "res://scenes/eagle.tscn",
	"frog": "res://scenes/frog.tscn"
}

var _pet_names: Dictionary = {
	"fox": "小狐狸",
	"opossum": "小负鼠",
	"eagle": "小老鹰",
	"frog": "小青蛙"
}

var _pet_order: Array[String] = ["fox", "opossum", "eagle", "frog"]
var _current_pet_index: int = 0
var _active_pet: Node = null
var _action_index: int = 0
var _fox_actions: Array[String] = ["crouch", "roll", "jump", "idle"]
var _last_tab_pressed: bool = false
var _last_p_pressed: bool = false

func _ready():
	print("[PetManager] 初始化完成")
	await get_tree().process_frame
	if not _is_on_login_scene():
		_ensure_pet_spawned()

func _ensure_pet_spawned():
	if _is_on_login_scene():
		return
	if _active_pet and is_instance_valid(_active_pet):
		var player = get_tree().get_first_node_in_group("player")
		if player:
			_active_pet.global_position = player.global_position + Vector2(-40, 20)
		return
	_spawn_pet(_pet_order[_current_pet_index])

func _process(_delta):
	if _is_on_login_scene():
		return
	if Input.is_physical_key_pressed(KEY_TAB):
		if not _last_tab_pressed:
			_switch_to_next_pet()
		_last_tab_pressed = true
	else:
		_last_tab_pressed = false
	
	if Input.is_physical_key_pressed(KEY_P):
		if not _last_p_pressed:
			_trigger_pet_action()
		_last_p_pressed = true
	else:
		_last_p_pressed = false

func _spawn_pet(pet_key: String):
	if _active_pet and is_instance_valid(_active_pet):
		if has_node("/root/SceneManager"):
			get_node("/root/SceneManager").unregister_persistent(_active_pet)
		_active_pet.queue_free()
	
	var scene_path = _pet_scenes.get(pet_key, "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		print("[PetManager] 无法加载宠物场景: " + scene_path)
		return
	
	var scene = load(scene_path) as PackedScene
	if scene == null:
		print("[PetManager] 场景加载失败: " + scene_path)
		return
	
	_active_pet = scene.instantiate()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_active_pet.global_position = player.global_position + Vector2(-40, 20)
	
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(_active_pet)
	else:
		add_child(_active_pet)
	
	if not _active_pet._player_ref or not is_instance_valid(_active_pet._player_ref):
		_active_pet._player_ref = get_tree().get_first_node_in_group("player")
		if _active_pet._player_ref:
			_active_pet.global_position = _active_pet._player_ref.global_position + Vector2(-40, 20)
	
	if _active_pet.has_method("set_pet_name"):
		_active_pet.set_pet_name(_pet_names.get(pet_key, pet_key))
	
	_action_index = 0
	
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("🐾 " + _pet_names.get(pet_key, pet_key) + "加入了你！")

func _switch_to_next_pet():
	_current_pet_index = (_current_pet_index + 1) % _pet_order.size()
	_spawn_pet(_pet_order[_current_pet_index])

func _trigger_pet_action():
	if not _active_pet or not is_instance_valid(_active_pet):
		return
	
	var pet_key = _pet_order[_current_pet_index]
	var actions: Array
	
	match pet_key:
		"fox":
			actions = _fox_actions
		"opossum":
			actions = ["idle", "walk"]
		"eagle":
			actions = ["idle", "attack"]
		"frog":
			actions = ["idle", "jump"]
		_:
			actions = ["idle"]
	
	_action_index = (_action_index + 1) % actions.size()
	var action = actions[_action_index]
	
	if _active_pet.has_method("play_action"):
		_active_pet.play_action(action)

func get_active_pet() -> Node:
	return _active_pet

func get_current_pet_name() -> String:
	return _pet_names.get(_pet_order[_current_pet_index], "")

func ensure_pet_in_scene():
	if _is_on_login_scene():
		return
	_ensure_pet_spawned()

func _is_on_login_scene() -> bool:
	var cs = get_tree().current_scene
	if cs and cs.scene_file_path.to_lower().find("character_select") != -1:
		return true
	return false
