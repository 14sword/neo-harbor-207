extends "res://scripts/PET/pet_follow_base.gd"

func _configure_pet() -> void:
	follow_speed = 150.0
	catch_up_speed = 250.0
	_pet_name = "小狐狸"
	_move_animation = "run"
	_idle_behaviors = ["crouch", "idle", "idle", "move_closer"]
	_random_actions = ["crouch", "roll", "jump"]
	_action_names = {
		"idle": "发呆",
		"run": "奔跑",
		"jump": "跳跃",
		"crouch": "蹲下",
		"roll": "翻滚",
		"dizzy": "眩晕",
		"hurt": "受伤",
		"victory": "胜利"
	}
