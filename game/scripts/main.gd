extends Node2D

@onready var npc_zhang: Node2D = $NPCs/NPC_Zhang
@onready var npc_li: Node2D = $NPCs/NPC_Li
@onready var npc_wang: Node2D = $NPCs/NPC_Wang

var api_client: Node = null
var status_update_timer: float = 0.0
var interaction_timer: float = 0.0
const INTERACTION_INTERVAL: float = 90.0

var _near_exit: bool = false

func _ready():
	if OS.is_debug_build():
		print("[INFO] 主场景初始化")
	
	var background: Sprite2D = $Background
	if background:
		background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	api_client = get_node_or_null("/root/APIClient")
	if api_client:
		api_client.npc_status_received.connect(_on_npc_status_received)
		api_client.npc_interaction_received.connect(_on_npc_interaction_received)
		api_client.get_batch_dialogue()

	var player = get_tree().get_first_node_in_group("player")
	if player:
		_setup_camera_limits(player)

	var exit_door = get_node_or_null("ExitDoor")
	if exit_door:
		exit_door.body_entered.connect(_on_exit_door_entered)
		exit_door.body_exited.connect(_on_exit_door_exited)

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
		camera.limit_right = 1280
		camera.limit_bottom = 720

func _process(delta: float):
	status_update_timer += delta
	if status_update_timer >= Config.NPC_STATUS_UPDATE_INTERVAL:
		status_update_timer = 0.0
		if api_client:
			api_client.get_batch_dialogue()
	
	interaction_timer += delta
	if interaction_timer >= INTERACTION_INTERVAL:
		interaction_timer = 0.0
		if api_client:
			api_client.get_npc_interactions()

	if _near_exit and Input.is_action_just_pressed("interact"):
		_transition_to_street()

func _on_exit_door_entered(body: Node2D):
	if body.is_in_group("player"):
		_near_exit = true
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("show_prompt"):
			prompt.show_prompt("exit_office")

func _on_exit_door_exited(body: Node2D):
	if body.is_in_group("player"):
		_near_exit = false
		var prompt = get_tree().get_first_node_in_group("interaction_prompt")
		if prompt and prompt.has_method("hide_prompt"):
			prompt.hide_prompt()

func _transition_to_street():
	if has_node("/root/SceneManager"):
		_log_event("🚪 离开办公室，前往街区")
		get_node("/root/SceneManager").transition_to(get_node("/root/SceneManager").GameScene.STREET)

func _on_npc_status_received(dialogues: Dictionary):
	print("[INFO] 更新NPC状态: ", dialogues)
	for npc_name in dialogues:
		var dialogue = dialogues[npc_name]
		update_npc_dialogue(npc_name, dialogue)

func _on_npc_interaction_received(interactions: Array):
	for interaction in interactions:
		var npc1_id = interaction.get("npc1_id", "")
		var npc1_dialogue = interaction.get("npc1_dialogue", "")
		var npc2_id = interaction.get("npc2_id", "")
		var npc2_dialogue = interaction.get("npc2_dialogue", "")
		
		var npc1_node = get_npc_node_by_id(npc1_id)
		var npc2_node = get_npc_node_by_id(npc2_id)
		
		if npc1_node and npc1_dialogue:
			npc1_node.update_dialogue(npc1_dialogue)
		if npc2_node and npc2_dialogue:
			npc2_node.update_dialogue(npc2_dialogue)
		
		var name1 = interaction.get("npc1_name", npc1_id)
		var name2 = interaction.get("npc2_name", npc2_id)
		_log_event("💬 " + name1 + "和" + name2 + "在聊天")

func update_npc_dialogue(npc_name: String, dialogue: String):
	var npc_node = get_npc_node(npc_name)
	if npc_node and npc_node.has_method("update_dialogue"):
		npc_node.update_dialogue(dialogue)

func get_npc_node(npc_name: String) -> Node2D:
	match npc_name:
		"张三", "zhang_san":
			return npc_zhang
		"李四", "li_si":
			return npc_li
		"王五", "wang_wu":
			return npc_wang
		_:
			return null

func get_npc_node_by_id(npc_id: String) -> Node2D:
	match npc_id:
		"zhang_san":
			return npc_zhang
		"li_si":
			return npc_li
		"wang_wu":
			return npc_wang
		_:
			return null

func _log_event(message: String):
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)
