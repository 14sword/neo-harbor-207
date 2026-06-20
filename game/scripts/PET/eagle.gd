extends "res://scripts/PET/pet_follow_base.gd"

func _configure_pet() -> void:
	follow_speed = 170.0
	catch_up_speed = 280.0
	_pet_name = "小老鹰"
	_move_animation = "attack"
	_idle_behaviors = ["attack", "idle", "idle", "move_closer"]
	_random_actions = ["attack"]
	_action_names = {"idle": "发呆", "attack": "展翅"}
