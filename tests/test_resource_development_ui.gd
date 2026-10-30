extends SceneTree

const PATH := "res://tests/.test_resource_development_ui.json"
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager := root.get_node("SaveManager")
	manager.save_path = PATH
	manager.unix_time_provider = func() -> int: return 5000
	for suffix: String in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var state := root.get_node("GameState")
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var panel: VBoxContainer = main.economy_panel
	check(panel.flow.text.contains("产出") and panel.flow.text.contains("消耗"), "real income/consumption breakdown")
	check(panel.food_status.text.contains("50.0分钟"), "opening runway")
	var before: Dictionary = state.export_save_data().duplicate(true)
	panel.action_button.pressed.emit()
	check(main.selected_resource.get("site_id") == &"field", "food advice opens free resource site")
	check(state.export_save_data() == before, "navigation does not assign, charge or grant rewards")
	state.set_disciple_job(1, &"field")
	state.set_disciple_job(2, &"forest")
	state.set_disciple_job(3, &"mine")
	check(panel.current_step["id"] == "disciple_quarters", "job change refreshes guide")
	before = state.export_save_data().duplicate(true)
	panel.action_button.pressed.emit()
	check(main.sect_map.placement_building == &"disciple_quarters", "housing advice enters free preview")
	check(state.export_save_data() == before, "construction advice does not auto-build")
	main._cancel_building_placement()
	state.resources["food"] = 0
	state.resources_changed.emit()
	check(panel.food_status.text.contains("50%") and panel.food_status.text.contains("恢复"), "starvation recovery updates on signal")
	check(main.wood_label.tooltip_text.contains("净+6.0"), "resource hover uses same starvation formula")
	state.resources["food"] = 150
	state.resources_changed.emit()
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main._open_management_panel(main.sect_heading)
		await process_frame
		await process_frame
		check(panel.size.x <= main.sidebar_scroll.size.x, "economy content wraps inside drawer")
		check(Rect2(Vector2.ZERO, main.size).encloses(main.management_sidebar.get_rect()), "drawer remains within screen")
	check(state.start_construction(&"disciple_quarters", Vector2i(3, 3)), "five-person UI fixture housing")
	state.process_construction(6)
	for index: int in range(2):
		check(state.start_recruitment(), "five-person UI fixture recruit")
		state.process_recruitment(5)
	state.set_disciple_job(4, &"forest")
	state.set_disciple_job(5, &"mine")
	state.resources["food"] = 0
	state.resources_changed.emit()
	check(panel.current_step["action"] == "disciples", "insufficient existing field routes to job transfer")
	before = state.export_save_data().duplicate(true)
	panel.action_button.pressed.emit()
	check(main.management_sidebar.get_node("PanelTitle").text == "弟子管理", "job transfer destination is usable")
	check(state.export_save_data() == before, "job transfer navigation does not change jobs or charge")
	await process_frame
	await process_frame
	await process_frame
	check(main.sidebar_scroll.get_global_rect().encloses(main.disciple_job_selector.get_global_rect()), "job transfer selector scrolls into view, not behind character preview")
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	if failures == 0:
		print("PASS: economy UI, dynamic guidance, navigation without mutations, starvation hover and both-size drawer")
	quit(1 if failures else 0)
