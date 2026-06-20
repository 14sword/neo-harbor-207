extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	await _verify_forum_ui(errors)
	await _verify_tv_ui(errors)
	if errors.is_empty():
		print("VERIFY FORUM TV UI: OK")
		quit(0)
	else:
		print("VERIFY FORUM TV UI: FAILED")
		for err in errors:
			push_error(err)
		quit(1)

func _verify_forum_ui(errors: Array[String]) -> void:
	var packed = load("res://scenes/forum_ui.tscn")
	if not packed is PackedScene:
		errors.append("ForumUI scene missing")
		return
	var forum = packed.instantiate()
	root.add_child(forum)
	await process_frame

	for category in ["都市新闻", "异常报告", "生活杂谈", "DATAWHALE公告"]:
		forum._on_category_selected(category)
		await process_frame
		var posts = forum._forum_data.get_posts(category, forum._forum_data.get_phase_key())
		if posts.is_empty():
			errors.append("Forum category has no posts: " + category)
			continue
		forum._on_post_selected(posts[0])
		await process_frame
		if not (forum._post_image.texture is Texture2D):
			errors.append("Forum image did not load for category: " + category)

	forum.queue_free()

func _verify_tv_ui(errors: Array[String]) -> void:
	var packed = load("res://scenes/tv_overlay.tscn")
	if not packed is PackedScene:
		errors.append("TVOverlay scene missing")
		return
	var dnm = root.get_node_or_null("DayNightManager")
	var phases = []
	if dnm:
		phases = [dnm.DayPhase.DAY, dnm.DayPhase.RAIN_NIGHT, dnm.DayPhase.NIGHT]
	else:
		phases = [0]

	for phase in phases:
		if dnm:
			dnm.current_phase = phase
		var tv = packed.instantiate()
		root.add_child(tv)
		await process_frame
		if tv._news_pool.size() < 5:
			errors.append("TV news pool too small for phase: " + str(phase))
		for i in range(tv._news_pool.size()):
			tv._current_index = i
			tv._show_current()
			await process_frame
			var item = tv._news_pool[i]
			if not str(item.get("image_category", "")).begins_with("tv_"):
				errors.append("TV item missing explicit tv image category: " + str(item))
			if not (tv._news_image.texture is Texture2D):
				errors.append("TV image did not load for item: " + item.get("title", ""))
		tv.queue_free()
		await process_frame
