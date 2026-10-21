extends SceneTree
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const PATH := "res://tests/.test_fixed_layout.json"
func _init() -> void:
	call_deferred("_run")
func cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
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
	assert(main.sect_map.fixed_layout)
	assert(not main.cancel_build_button.visible)
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	assert(state.start_construction(&"disciple_quarters", Vector2i(7, 5)))
	assert(state.start_construction(&"disciple_quarters", Vector2i(3, 3)))
	state.process_construction(20)
	state.buildings[0]["level"] = 2
	var old_records: Array = state.buildings.duplicate(true)
	var before: Dictionary = state.export_save_data().duplicate(true)
	var frame_a: Dictionary = main.sect_map.get_building_ground_frame(state.buildings[0], main.sect_map._map_origin())
	var frame_b: Dictionary = main.sect_map.get_building_ground_frame(state.buildings[1], main.sect_map._map_origin())
	assert(frame_a["rect"] == frame_b["rect"])
	assert(state.export_save_data() == before)
	main._start_building_placement(&"disciple_quarters")
	assert(main.fixed_site_card.visible and main.sect_map.placement_building == &"")
	assert(state.export_save_data() == before)
	main._on_placement_requested(&"disciple_quarters", Vector2i(5, 5))
	assert(state.export_save_data() == before)
	main.fixed_site_card.upgrade_button.pressed.emit()
	assert(state.buildings.size() == 3)
	assert(state.resources["wood"] == before["resources"]["wood"] - 40)
	assert(state.resources["spirit_stone"] == before["resources"]["spirit_stone"] - 10)
	assert(not state.buildings[-1]["completed"] and state.buildings[-1]["remaining"] == 6.0)
	assert(state.buildings[0] == old_records[0] and state.buildings[1] == old_records[1])
	assert(manager.has_save())
	state.process_construction(6)
	assert(state.get_disciple_capacity() == state.BASE_DISCIPLE_CAPACITY + 8)
	main._open_fixed_site(&"disciple_quarters")
	assert(main.fixed_site_card.member_list.get_child_count() == 3)
	main.fixed_site_card.member_list.get_child(1).pressed.emit()
	assert(main.selected_building_instance == int(old_records[1]["instance_id"]))
	assert(main.building_card.visible and not main.fixed_site_card.visible)
	main._dismiss_building_card()
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await process_frame
		await process_frame
		for kind: StringName in Layout.SITES:
			var point: Vector2 = main.sect_map.FixedView.plaque_rect(main.sect_map, kind).get_center()
			assert(main.sect_map.FixedView.hit(main.sect_map, point) == kind)
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			click.position = point
			main.sect_map._gui_input(click)
			if kind == &"hall":
				assert(main.building_card.visible and main.card_is_hall)
				main._dismiss_building_card()
			else:
				assert(main.fixed_site_card.visible and main.fixed_site_card.site_kind == kind)
				await process_frame
				assert(Rect2(Vector2.ZERO, main.size).encloses(main.fixed_site_card.get_rect()))
				assert(not main.fixed_site_card.get_global_rect().intersects(main.get_node("Layout/Body/BottomNav").get_global_rect()))
				main.fixed_site_card.hide()
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	manager.save_path = "res://tests/missing-fixed-directory/fail.json"
	main._construct_fixed_site(&"spirit_field")
	assert(JSON.stringify(state.export_save_data()) == JSON.stringify(snapshot))
	manager.save_path = PATH
	assert(manager.save_game() and manager.load_game())
	assert(JSON.parse_string(JSON.stringify(state.export_save_data())) == JSON.parse_string(JSON.stringify(snapshot)))
	state.resources["wood"] = 0
	var poor: Dictionary = state.export_save_data().duplicate(true)
	assert(not Layout.construct(state, &"artifact_forge"))
	assert(state.export_save_data() == poor)
	main.queue_free()
	await process_frame
	cleanup()
	print("PASS: fixed default, legacy placement disabled, paid timed construction, old multi-instance preservation, group selection, both-size input, rollback and save round trip")
	quit()
