extends "res://scripts/PET/pet_follow_base.gd"

func _configure_pet() -> void:
	follow_speed = 120.0
	catch_up_speed = 200.0
	_pet_name = "小青蛙"
	_move_animation = "jump"
	_idle_behaviors = ["jump", "idle", "idle", "move_closer"]
	_random_actions = ["jump"]
	_action_names = {"idle": "发呆", "jump": "跳跃"}
