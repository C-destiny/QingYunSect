extends SceneTree

const PATH := "res://tests/.test_free_build_default.json"
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	cleanup()
	var state := root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = PATH
	manager.unix_time_provider = func() -> int: return 5000
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var map: Control = main.sect_map
	check(not map.fixed_layout and not map.complete_sect, "normal entry uses free map without fixed precinct backdrop")
	check(map.structured_terrain, "free grid uses continuous terrain instead of painted terrace gaps")
	check(main.cancel_build_button.visible, "free placement cancel is reachable")
	check(state.buildings.is_empty(), "opening ordinary game grants no demo buildings")
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	var before: Dictionary = state.export_save_data().duplicate(true)
	main._start_building_placement(&"disciple_quarters")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	main._unhandled_input(cancel)
	check(map.placement_building == &"" and state.export_save_data() == before, "Esc cancels without charging")
	main._start_building_placement(&"disciple_quarters")
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	main._unhandled_input(right_click)
	check(map.placement_building == &"" and state.export_save_data() == before, "right click cancels without charging")
	for bad_cell: Vector2i in [Vector2i(4, 3), Vector2i(1, 1), Vector2i(8, 1), Vector2i(-1, -1)]:
		main._on_placement_requested(&"disciple_quarters", bad_cell)
		check(state.export_save_data() == before, "invalid placement leaves state unchanged: " + str(bad_cell))
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		await process_frame
		await process_frame
		var cell := Vector2i(3, 3) if view_size.x == 1280 else Vector2i(7, 5)
		main._start_building_placement(&"disciple_quarters")
		check(map.is_grid_visible(), "placement shows grid")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = map._cell_to_screen(cell, map._map_origin())
		map._gui_input(click)
		var record: Dictionary = {}
		for item: Dictionary in state.buildings:
			if Vector2i(item["cell_x"], item["cell_y"]) == cell:
				record = item
		check(not record.is_empty(), "mouse builds at chosen cell in both sizes")
		if not record.is_empty():
			check(not record["completed"] and record["remaining"] == 6.0, "original construction time preserved")
		check(not map.is_grid_visible(), "placement exits after successful build")
	state.process_construction(20)
	check(state.resources["wood"] == 920 and state.resources["spirit_stone"] == 980, "each of two constructions charged once")
	if state.buildings.size() == 2:
		check(map.get_building_ground_frame(state.buildings[0], map._map_origin())["rect"] != map.get_building_ground_frame(state.buildings[1], map._map_origin())["rect"], "same type retains independent free positions")
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	check(manager.save_game() and manager.load_game(), "version3 round trip")
	check(JSON.parse_string(JSON.stringify(state.export_save_data())) == JSON.parse_string(JSON.stringify(snapshot)), "old IDs, positions and levels preserved")
	manager.save_path = "res://tests/missing-free-build-directory/fail.json"
	main._start_building_placement(&"spirit_field")
	main._on_placement_requested(&"spirit_field", Vector2i(5, 5))
	check(JSON.parse_string(JSON.stringify(state.export_save_data())) == JSON.parse_string(JSON.stringify(snapshot)), "failed save rolls back resources, instance IDs and construction")
	check(map.placement_building == &"spirit_field", "failed save keeps retryable placement")
	manager.save_path = PATH
	main.queue_free()
	await process_frame
	cleanup()
	if failures == 0:
		print("PASS: default free build, cancel, both-size mouse placement, invalid cells, independent instances, old-state round trip and save rollback")
	quit(1 if failures else 0)
