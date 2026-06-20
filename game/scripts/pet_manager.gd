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
var _active_pet_key: String = ""
var _pet_scene_cache: Dictionary = {}
var _pet_instance_cache: Dictionary = {}
var _action_index: int = 0
var _fox_actions: Array[String] = ["crouch", "roll", "jump", "idle"]
var _last_tab_pressed: bool = false
var _last_p_pressed: bool = false

func _ready():
	_preload_pet_scenes()
	print("[PetManager] 初始化完成")
	await get_tree().process_frame
	if not _is_on_login_scene():
		_ensure_pet_spawned()

func _ensure_pet_spawned():
	if _is_on_login_scene():
		return
	if _active_pet and is_instance_valid(_active_pet):
		var pet_key = _active_pet_key if _active_pet_key != "" else _pet_order[_current_pet_index]
		_attach_pet_to_current_scene(_active_pet)
		_activate_pet(_active_pet, pet_key)
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
	if _active_pet_key == pet_key and _active_pet and is_instance_valid(_active_pet):
		_attach_pet_to_current_scene(_active_pet)
		_activate_pet(_active_pet, pet_key)
		_position_pet_near_player(_active_pet)
		return

	var pet = _get_or_create_pet(pet_key)
	if not pet:
		return

	if _active_pet and is_instance_valid(_active_pet):
		_deactivate_pet(_active_pet)

	_attach_pet_to_current_scene(pet)
	_activate_pet(pet, pet_key)

	_action_index = 0

	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log("🐾 " + _pet_names.get(pet_key, pet_key) + "加入了你！")

func _preload_pet_scenes() -> void:
	for pet_key in _pet_order:
		_get_pet_scene(pet_key)

func _get_pet_scene(pet_key: String) -> PackedScene:
	if _pet_scene_cache.has(pet_key):
		return _pet_scene_cache[pet_key]

	var scene_path = _pet_scenes.get(pet_key, "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		print("[PetManager] 无法加载宠物场景: " + scene_path)
		return null

	var scene = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE) as PackedScene
	if scene == null:
		print("[PetManager] 场景加载失败: " + scene_path)
		return null

	_pet_scene_cache[pet_key] = scene
	return scene

func _get_or_create_pet(pet_key: String) -> Node:
	if _pet_instance_cache.has(pet_key):
		var cached_pet = _pet_instance_cache[pet_key]
		if is_instance_valid(cached_pet):
			return cached_pet
		_pet_instance_cache.erase(pet_key)

	var scene = _get_pet_scene(pet_key)
	if scene == null:
		return null

	var pet = scene.instantiate()
	_pet_instance_cache[pet_key] = pet
	return pet

func _attach_pet_to_current_scene(pet: Node) -> void:
	var target_parent: Node = get_tree().current_scene
	if not target_parent:
		target_parent = self

	if pet.get_parent() and pet.get_parent() != target_parent:
		pet.get_parent().remove_child(pet)
	if pet.get_parent() != target_parent:
		target_parent.add_child(pet)

func _activate_pet(pet: Node, pet_key: String) -> void:
	_active_pet = pet
	_active_pet_key = pet_key
	_active_pet.visible = true
	_active_pet.process_mode = Node.PROCESS_MODE_INHERIT

	if _active_pet.has_method("set_pet_name"):
		_active_pet.set_pet_name(_pet_names.get(pet_key, pet_key))

	_refresh_pet_player_ref(_active_pet)
	_position_pet_near_player(_active_pet)

	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").register_persistent(_active_pet)

func _deactivate_pet(pet: Node) -> void:
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").unregister_persistent(pet)
	pet.visible = false
	pet.process_mode = Node.PROCESS_MODE_DISABLED
	if pet.has_node("AnimatedSprite2D"):
		var animator = pet.get_node("AnimatedSprite2D")
		if animator is AnimatedSprite2D and animator.sprite_frames and animator.sprite_frames.has_animation("idle"):
			animator.play("idle")

func _refresh_pet_player_ref(pet: Node) -> void:
	pet.set("_player_ref", get_tree().get_first_node_in_group("player"))

func _position_pet_near_player(pet: Node) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		pet.global_position = player.global_position + Vector2(-40, 20)

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
