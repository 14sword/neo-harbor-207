extends "res://scripts/PET/pet_follow_base.gd"

func _configure_pet() -> void:
	follow_speed = 130.0
	catch_up_speed = 220.0
	_pet_name = "小负鼠"
	_move_animation = "walk"
	_idle_behaviors = ["walk", "idle", "idle", "move_closer"]
	_random_actions = ["walk"]
	_action_names = {"idle": "发呆", "walk": "散步"}
