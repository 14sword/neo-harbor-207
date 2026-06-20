extends SceneTree

func _initialize():
	var errors = []
	
	print("====== VERIFY PLAYER SPRITES ======")
	var player_dir = "res://assets/characters/player/"
	var player_files = [
		"player_down_0.png", "player_down_1.png", "player_down_2.png",
		"player_up_0.png", "player_up_1.png", "player_up_2.png",
		"player_left_0.png", "player_left_1.png", "player_left_2.png",
		"player_right_0.png", "player_right_1.png", "player_right_2.png",
		"player_idle.png",
	]
	
	var found_count = 0
	for pf in player_files:
		var path = player_dir + pf
		if FileAccess.file_exists(path):
			found_count += 1
			var img = Image.new()
			var err = img.load(path)
			if err == OK:
				print("  FOUND: %s -> %dx%d" % [pf, img.get_width(), img.get_height()])
			else:
				print("  FOUND BUT CORRUPT: %s" % pf)
				errors.append("PLAYER CORRUPT: %s" % path)
		else:
			print("  MISSING: %s" % pf)
			errors.append("PLAYER MISSING: %s" % path)

	print("\n====== VERIFY PLAYER CLASS RUNTIME FRAMES ======")
	var player_classes = ["cipher", "chrome", "echo", "shadow"]
	var player_directions = ["down", "up", "left", "right"]
	var player_class_found = 0
	var player_class_expected = player_classes.size() * ((player_directions.size() * 3) + 5)
	for class_id in player_classes:
		var class_dir = player_dir + "classes/" + class_id + "/"
		for direction in player_directions:
			for frame_idx in range(3):
				var path = class_dir + class_id + "_" + direction + "_" + str(frame_idx) + ".png"
				if FileAccess.file_exists(path):
					var img = Image.new()
					var err = img.load(path)
					if err == OK and img.get_width() == 316 and img.get_height() == 329:
						player_class_found += 1
					else:
						print("  PLAYER CLASS FRAME INVALID: %s" % path)
						errors.append("PLAYER CLASS FRAME INVALID: %s" % path)
				else:
					print("  PLAYER CLASS FRAME MISSING: %s" % path)
					errors.append("PLAYER CLASS FRAME MISSING: %s" % path)
		for frame_idx in range(5):
			var path = class_dir + class_id + "_idle_" + str(frame_idx) + ".png"
			if FileAccess.file_exists(path):
				var img = Image.new()
				var err = img.load(path)
				if err == OK and img.get_width() == 316 and img.get_height() == 329:
					player_class_found += 1
				else:
					print("  PLAYER CLASS IDLE INVALID: %s" % path)
					errors.append("PLAYER CLASS IDLE INVALID: %s" % path)
			else:
				print("  PLAYER CLASS IDLE MISSING: %s" % path)
				errors.append("PLAYER CLASS IDLE MISSING: %s" % path)

	print("\n====== VERIFY NPC SPRITES ======")
	var npc_dir = "res://assets/characters/npcs/"
	var npc_names = ["张三", "李四", "王五"]
	var npc_base_found = 0
	
	for npc_name in npc_names:
		var path = npc_dir + npc_name + ".png"
		if FileAccess.file_exists(path):
			npc_base_found += 1
			var img = Image.new()
			var err = img.load(path)
			if err == OK:
				print("  FOUND: %s.png -> %dx%d" % [npc_name, img.get_width(), img.get_height()])
			else:
				print("  FOUND BUT CORRUPT: %s.png" % npc_name)
				errors.append("NPC BASE CORRUPT: %s" % path)
		else:
			print("  MISSING: %s.png" % npc_name)
			errors.append("NPC BASE MISSING: %s" % path)

	print("\n====== VERIFY RUNTIME NPC FRAMES ======")
	var runtime_dir = "res://assets/characters/npcs/runtime/"
	var npc_ids = ["zhang_san", "li_si", "wang_wu", "sun_yue", "he_zhen", "chen_xi", "zhao_lin", "liu_feng"]
	var directions = ["down", "up", "left", "right"]
	var runtime_found = 0
	var runtime_expected = npc_ids.size() * directions.size() * 3
	var idle_found = 0
	var idle_expected = 0
	for npc_id in npc_ids:
		for direction in directions:
			for frame_idx in range(3):
				var path = runtime_dir + npc_id + "/" + npc_id + "_" + direction + "_" + str(frame_idx) + ".png"
				if FileAccess.file_exists(path):
					var img = Image.new()
					var err = img.load(path)
					if err == OK:
						runtime_found += 1
					else:
						print("  RUNTIME CORRUPT: %s" % path)
						errors.append("RUNTIME CORRUPT: %s" % path)
				else:
					print("  RUNTIME MISSING: %s" % path)
					errors.append("RUNTIME MISSING: %s" % path)
		var expected_idle_count = 5
		idle_expected += expected_idle_count
		for frame_idx in range(expected_idle_count):
			var path = runtime_dir + npc_id + "/" + npc_id + "_idle_" + str(frame_idx) + ".png"
			if FileAccess.file_exists(path):
				var img = Image.new()
				var err = img.load(path)
				if err == OK:
					idle_found += 1
				else:
					print("  IDLE CORRUPT: %s" % path)
					errors.append("IDLE CORRUPT: %s" % path)
			else:
				print("  IDLE MISSING: %s" % path)
				errors.append("IDLE MISSING: %s" % path)

	print("\n====== VERIFY SELECT SPRITES ======")
	var select_dir = "res://assets/characters/select/"
	var classes = ["cipher", "chrome", "echo", "shadow"]
	var select_found = 0
	
	for cls in classes:
		var path = select_dir + cls + ".png"
		if FileAccess.file_exists(path):
			select_found += 1
			var img = Image.new()
			var err = img.load(path)
			if err == OK:
				print("  FOUND: %s.png" % cls)
			else:
				print("  FOUND BUT CORRUPT: %s.png" % cls)
				errors.append("SELECT CORRUPT: %s" % path)
		else:
			print("  MISSING: %s.png" % cls)
			errors.append("SELECT MISSING: %s" % path)

	print("\n====== VERIFY CLASS PORTRAITS ======")
	var portrait_found = 0
	for i in range(1, 5):
		var path = "res://assets/media/class_portrait/class_portrait_%03d.webp" % i
		if FileAccess.file_exists(path):
			var img = Image.new()
			var err = img.load(path)
			if err == OK:
				portrait_found += 1
				print("  FOUND: class_portrait_%03d.webp -> %dx%d" % [i, img.get_width(), img.get_height()])
			else:
				print("  FOUND BUT CORRUPT: class_portrait_%03d.webp" % i)
				errors.append("CLASS PORTRAIT CORRUPT: %s" % path)
		else:
			print("  MISSING: class_portrait_%03d.webp" % i)
			errors.append("CLASS PORTRAIT MISSING: %s" % path)

	print("\n====== VERIFY IMAGE2 NPC PORTRAITS ======")
	var generated_portraits_found = 0
	for npc_id in npc_ids:
		var path = "res://assets/characters/npcs/generated_portraits/" + npc_id + ".webp"
		if FileAccess.file_exists(path):
			var img = Image.new()
			var err = img.load(path)
			if err == OK and img.get_width() == 512 and img.get_height() == 512:
				generated_portraits_found += 1
				print("  FOUND: %s.webp -> 512x512" % npc_id)
			else:
				print("  PORTRAIT INVALID: %s" % path)
				errors.append("NPC PORTRAIT INVALID: %s" % path)
		else:
			print("  PORTRAIT MISSING: %s" % path)
			errors.append("NPC PORTRAIT MISSING: %s" % path)

	print("\n====== VERIFY SPECIAL SCENE BACKGROUNDS ======")
	var special_backgrounds_found = 0
	var special_background_dirs = {
		"underground": "res://assets/backgrounds/underground/",
		"anomaly_space": "res://assets/backgrounds/anomaly_space/",
	}
	var phases = ["白天.png", "傍晚.png", "黑夜.png", "雨夜.png"]
	for dir_name in special_background_dirs.keys():
		for phase_file in phases:
			var path = special_background_dirs[dir_name] + phase_file
			if FileAccess.file_exists(path):
				var img = Image.new()
				var err = img.load(path)
				if err == OK and img.get_width() == 1672 and img.get_height() == 941:
					special_backgrounds_found += 1
					print("  FOUND: %s/%s -> 1672x941" % [dir_name, phase_file])
				else:
					print("  SPECIAL BACKGROUND INVALID: %s" % path)
					errors.append("SPECIAL BACKGROUND INVALID: %s" % path)
			else:
				print("  SPECIAL BACKGROUND MISSING: %s" % path)
				errors.append("SPECIAL BACKGROUND MISSING: %s" % path)

	print("\n====== VERIFY UNDERGROUND AMBIENT EFFECTS ======")
	var underground_effects_found = 0
	var underground_effects = {
		"res://assets/effects/underground/holo_notice_sheet.png": Vector2i(1024, 256),
		"res://assets/effects/underground/maintenance_monitor_sheet.png": Vector2i(1024, 256),
		"res://assets/effects/underground/train_light_sweep.png": Vector2i(512, 160),
		"res://assets/effects/underground/steam_puff_sheet.png": Vector2i(1024, 256),
		"res://assets/effects/underground/drip_reflection_sheet.png": Vector2i(1024, 256),
		"res://assets/effects/underground/sun_yue_research_kit.png": Vector2i(320, 256),
		"res://assets/effects/underground/portal_pulse_sheet.png": Vector2i(1024, 256),
	}
	for path in underground_effects.keys():
		if FileAccess.file_exists(path):
			var img = Image.new()
			var err = img.load(path)
			if err == OK and img.get_size() == underground_effects[path]:
				underground_effects_found += 1
				print("  FOUND: %s -> %s" % [path, str(img.get_size())])
			else:
				print("  UNDERGROUND EFFECT INVALID: %s" % path)
				errors.append("UNDERGROUND EFFECT INVALID: %s" % path)
		else:
			print("  UNDERGROUND EFFECT MISSING: %s" % path)
			errors.append("UNDERGROUND EFFECT MISSING: %s" % path)

	print("\n====== VERIFY MAP AND TELEPORT UI ASSETS ======")
	var ui_assets_found = 0
	var ui_assets = [
		"res://assets/ui/map/cyber_town_overview.webp",
		"res://assets/ui/map/office.png",
		"res://assets/ui/map/street.png",
		"res://assets/ui/map/apartment.png",
		"res://assets/ui/map/underground.png",
		"res://assets/ui/map/anomaly.png",
		"res://assets/ui/map/locked.png",
		"res://assets/ui/map/current_beacon.png",
		"res://assets/ui/teleport/street_underground_entrance.png",
		"res://assets/ui/teleport/return_to_street_pad.png",
		"res://assets/ui/teleport/underground_anomaly_portal.png",
		"res://assets/ui/teleport/return_to_underground_rift.png",
	]
	for path in ui_assets:
		if FileAccess.file_exists(path):
			var img = Image.new()
			var err = img.load(path)
			if err == OK:
				ui_assets_found += 1
				print("  FOUND: %s -> %dx%d" % [path, img.get_width(), img.get_height()])
			else:
				print("  UI ASSET CORRUPT: %s" % path)
				errors.append("UI ASSET CORRUPT: %s" % path)
		else:
			print("  UI ASSET MISSING: %s" % path)
			errors.append("UI ASSET MISSING: %s" % path)

	print("\n====== RESULT ======")
	print("Player sprites found: %d/%d" % [found_count, player_files.size()])
	print("Player class runtime frames found: %d/%d" % [player_class_found, player_class_expected])
	print("NPC base sprites found: %d/3 (张三/李四/王五)" % npc_base_found)
	print("NPC runtime frames found: %d/%d" % [runtime_found, runtime_expected])
	print("NPC idle frames found: %d/%d" % [idle_found, idle_expected])
	print("Select sprites found: %d/4" % select_found)
	print("Class portraits found: %d/4" % portrait_found)
	print("Image2 NPC portraits found: %d/%d" % [generated_portraits_found, npc_ids.size()])
	print("Special backgrounds found: %d/8" % special_backgrounds_found)
	print("Underground ambient effects found: %d/%d" % [underground_effects_found, underground_effects.size()])
	print("Map and teleport UI assets found: %d/%d" % [ui_assets_found, ui_assets.size()])
	
	if errors.is_empty():
		quit(0)
	else:
		print("\n====== ERRORS ======")
		for error in errors:
			print(error)
		quit(1)
