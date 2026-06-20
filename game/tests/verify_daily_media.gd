extends SceneTree

func _initialize():
	var errors: Array[String] = []
	_verify_media_assets(errors)
	await _verify_media_manager(errors)
	await _verify_daily_profile(errors)
	if errors.is_empty():
		print("VERIFY DAILY MEDIA: OK")
		quit(0)
	else:
		print("VERIFY DAILY MEDIA: FAILED")
		for err in errors:
			push_error(err)
		quit(1)

func _verify_media_assets(errors: Array[String]) -> void:
	var groups = {
		"terminal_news": 2,
		"terminal_anomaly": 2,
		"terminal_life": 2,
		"terminal_datawhale": 2,
		"tv_weather": 2,
		"tv_city": 2,
		"tv_life": 2,
		"tv_traffic": 2,
		"tv_anomaly": 2,
	}
	for category in groups:
		for i in range(1, int(groups[category]) + 1):
			var path = "res://assets/media/%s/%s_%03d.png" % [category, category, i]
			if not FileAccess.file_exists(path):
				errors.append("Missing media asset: " + path)
				continue
			var tex = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
			if not (tex is Texture2D):
				errors.append("Corrupt media asset: " + path)
				continue
			if tex.get_width() != 1024 or tex.get_height() != 576:
				errors.append("Unexpected media size: %s -> %dx%d" % [path, tex.get_width(), tex.get_height()])

func _verify_media_manager(errors: Array[String]) -> void:
	await process_frame
	var media_manager = root.get_node_or_null("MediaManager")
	if media_manager == null:
		errors.append("MediaManager autoload missing")
		return
	for category in ["terminal_news", "terminal_anomaly", "terminal_life", "terminal_datawhale", "tv_weather", "tv_city", "tv_life", "tv_traffic", "tv_anomaly"]:
		if media_manager.get_image_count(category) != 2:
			errors.append("MediaManager image count mismatch for " + category)
		var tex = media_manager.get_image_by_index(category, 0)
		if not (tex is Texture2D):
			errors.append("MediaManager failed to load texture for " + category)

func _verify_daily_profile(errors: Array[String]) -> void:
	var cal = root.get_node_or_null("WorldCalendar")
	if cal == null:
		cal = load("res://scripts/world_calendar.gd").new()
		cal.name = "WorldCalendar"
		root.add_child(cal)
	cal.current_day = 73

	var generator = root.get_node_or_null("DailyWorldGenerator")
	if generator == null:
		generator = load("res://scripts/daily_world_generator.gd").new()
		generator.name = "DailyWorldGenerator"
		root.add_child(generator)
	await process_frame

	generator._refresh_daily_data()
	var profile_a = generator.get_daily_profile()
	generator._refresh_daily_data()
	var profile_b = generator.get_daily_profile()
	if JSON.stringify(profile_a) != JSON.stringify(profile_b):
		errors.append("Daily profile is not deterministic for the same day")

	cal.current_day = 109
	generator._refresh_daily_data()
	var profile_c = generator.get_daily_profile()
	if JSON.stringify(profile_a) == JSON.stringify(profile_c):
		errors.append("Daily profile did not change after changing day")

	for phase in ["day", "rain", "night"]:
		var news = generator.get_daily_news_items(phase)
		if news.size() < 5:
			errors.append("Expected at least 5 news items for phase: " + phase)
		for item in news:
			var image_category = item.get("image_category", "")
			if not image_category.begins_with("tv_"):
				errors.append("TV news missing tv_* image category: " + str(item))

	var forum_data = load("res://scripts/forum_data.gd").new()
	var injected_found = false
	for post in forum_data.get_posts("都市新闻", "day"):
		if post.get("image_category", "") == "terminal_news":
			injected_found = true
			break
	if not injected_found:
		errors.append("Forum daily injection missing terminal_news image category")
