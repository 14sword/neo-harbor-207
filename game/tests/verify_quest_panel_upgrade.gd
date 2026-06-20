extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var qm = root.get_node_or_null("/root/QuestManager")
	if not qm:
		errors.append("QuestManager autoload missing")
	else:
		_reset_quest_manager(qm)
		_verify_quest_api(qm, errors)
		await _verify_quest_panel_pool(qm, errors)
	print("====== VERIFY QUEST PANEL UPGRADE ======")
	if errors.is_empty():
		print("Quest panel upgrade checks passed")
		_finish(0)
		return
	for error in errors:
		print(error)
	_finish(1)

func _reset_quest_manager(qm: Node) -> void:
	qm._init_quests()
	qm._apply_default_quest_metadata()
	qm._dialogue_counts.clear()
	qm._interaction_counts.clear()
	qm._daily_dialogue_counts.clear()
	qm._daily_interaction_counts.clear()
	qm._tracked_quest_id = ""
	qm.refresh_contextual_recommendations()

func _verify_quest_api(qm: Node, errors: Array[String]) -> void:
	var story_rows: Array = qm.get_quest_view_data("story", false)
	if story_rows.is_empty():
		errors.append("STORY_FILTER_EMPTY")
	for row in story_rows:
		if row is Dictionary and str(row.get("type_key", "")) != "story":
			errors.append("STORY_FILTER_LEAKED_OTHER_TYPE")

	var hidden_rows: Array = qm.get_quest_view_data("hidden", false)
	for row in hidden_rows:
		if row is Dictionary and str(row.get("type_key", "")) != "hidden":
			errors.append("HIDDEN_FILTER_LEAKED_OTHER_TYPE")

	if not qm.accept_quest("first_chat"):
		errors.append("ACCEPT_FIRST_CHAT_FAILED")
	if not qm.track_quest("first_chat"):
		errors.append("TRACK_FIRST_CHAT_FAILED")
	var tracked: Dictionary = qm.get_tracked_quest_display_data()
	if tracked.is_empty() or str(tracked.get("id", "")) != "first_chat":
		errors.append("TRACKED_DATA_INVALID")

	qm.on_dialogue_with_npc("zhang_san")
	var archive: Array = qm.get_completed_archive_data()
	if archive.is_empty() or str(archive[0].get("id", "")) != "first_chat":
		errors.append("COMPLETED_ARCHIVE_MISSING_FIRST_CHAT")
	if int(archive[0].get("completed_day", -1)) < 0:
		errors.append("COMPLETED_DAY_NOT_WRITTEN")

	qm.accept_quest("daily_chat")
	qm.on_dialogue_with_npc("li_si")
	var daily_done := false
	for row in qm.get_completed_archive_data():
		if row is Dictionary and str(row.get("id", "")) == "daily_chat":
			daily_done = true
			break
	if not daily_done:
		errors.append("DAILY_DID_NOT_COMPLETE")
	qm.reset_daily_quests()
	var daily_rows: Array = qm.get_quest_view_data("daily", false)
	if daily_rows.is_empty() or str(daily_rows[0].get("status", "")) != "可接取":
		errors.append("DAILY_RESET_DID_NOT_RETURN_AVAILABLE")

	var cal = root.get_node_or_null("WorldCalendar")
	if cal:
		cal.current_day = 73
	var dwg = root.get_node_or_null("DailyWorldGenerator")
	if dwg:
		dwg._refresh_daily_data()
	qm.refresh_contextual_recommendations()
	var has_recommendation := false
	for row in qm.get_quest_view_data("all", false):
		if row is Dictionary and not str(row.get("recommended_reason", "")).is_empty():
			has_recommendation = true
			break
	if not has_recommendation:
		errors.append("CONTEXT_RECOMMENDATION_MISSING")

func _verify_quest_panel_pool(qm: Node, errors: Array[String]) -> void:
	var scene: PackedScene = load("res://scenes/quest_panel.tscn")
	var panel: Node = scene.instantiate()
	root.add_child(panel)
	await process_frame
	panel.show_panel()
	await process_frame
	await create_timer(0.35).timeout
	_verify_panel_is_on_screen(panel, errors)
	var slot_count: int = panel._list_slots.size()
	var first_slot: Variant = panel._list_slots[0] if slot_count > 0 else null
	var live_rows: Array = qm.get_quest_view_data("all", false)
	if slot_count < live_rows.size():
		errors.append("QUEST_PANEL_SLOT_POOL_TOO_SMALL:" + str(slot_count) + "/" + str(live_rows.size()))
	if _visible_slot_count(panel) != live_rows.size():
		errors.append("QUEST_PANEL_VISIBLE_SLOT_COUNT_MISMATCH:" + str(_visible_slot_count(panel)) + "/" + str(live_rows.size()))
	if not panel._summary_labels.has("active") or not panel._summary_labels.has("archived"):
		errors.append("QUEST_PANEL_SUMMARY_MISSING")
	if not panel._detail_box or panel._detail_box.get_node_or_null("QuestDetailHero") == null:
		errors.append("QUEST_PANEL_DETAIL_HERO_MISSING")
	panel.refresh_quests()
	await process_frame
	if panel._list_slots.size() != slot_count:
		errors.append("QUEST_PANEL_SLOT_COUNT_CHANGED")
	if slot_count == 0 or panel._list_slots[0] != first_slot:
		errors.append("QUEST_PANEL_SLOT_OBJECT_NOT_REUSED")
	panel._on_filter_pressed("story")
	await process_frame
	if panel._current_filter != "story":
		errors.append("QUEST_PANEL_FILTER_NOT_SET")
	panel._on_filter_pressed("completed")
	await process_frame
	if panel._current_filter != "completed":
		errors.append("QUEST_PANEL_COMPLETED_FILTER_NOT_SET")
	panel.queue_free()
	await process_frame

func _verify_panel_is_on_screen(panel: Node, errors: Array[String]) -> void:
	var rect: Rect2 = panel.main_panel.get_global_rect()
	var viewport_size: Vector2 = root.get_visible_rect().size
	if rect.position.x < -0.5:
		errors.append("QUEST_PANEL_LEFT_CLIPPED:" + str(rect.position.x))
	if rect.position.y < -0.5:
		errors.append("QUEST_PANEL_TOP_CLIPPED:" + str(rect.position.y))
	if rect.end.x > viewport_size.x + 0.5:
		errors.append("QUEST_PANEL_RIGHT_CLIPPED:" + str(rect.end.x) + "/" + str(viewport_size.x))
	if rect.end.y > viewport_size.y + 0.5:
		errors.append("QUEST_PANEL_BOTTOM_CLIPPED:" + str(rect.end.y) + "/" + str(viewport_size.y))

func _visible_slot_count(panel: Node) -> int:
	var count := 0
	for slot in panel._list_slots:
		if slot is Button and slot.visible:
			count += 1
	return count

func _finish(code: int) -> void:
	var audio = root.get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("stop_bgm"):
		audio.stop_bgm()
	quit(code)
