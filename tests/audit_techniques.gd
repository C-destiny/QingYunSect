extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var manager := root.get_node("SaveManager")
	manager.save_path = "res://tests/.audit_techniques.json"
	manager.unix_time_provider = func(): return 5000
	var state := root.get_node("GameState")
	var main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	main.selected_disciple_id = 1
	main._refresh_disciple_roster()
	var panel = main.disciple_training_button.get_parent().get_node("TechniquePanel")
	assert(state.start_construction(&"training_ground",Vector2i(0,0)))
	state.process_construction(60)
	state.resources["food"] = 100
	state.resources["spirit_stone"] = 100
	assert(state.start_medicine())
	state.process_medicine(60)
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	assert(state.start_construction(&"scripture_library",Vector2i(1,0)))
	state.process_construction(999)
	assert(state.learn_technique(1,"edge"))
	assert(state.learn_technique(1,"guard"))
	assert(state.select_technique(1,"edge"))
	for size: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = size
		main._open_management_panel(main.growth_heading)
		for frame: int in range(5):
			await process_frame
		main.sidebar_scroll.ensure_control_visible(panel)
		await process_frame
		await RenderingServer.frame_post_draw
		assert(panel.stop.is_visible_in_tree())
		assert(root.get_texture().get_image().save_png("res://docs/art/p7-techniques-%d.png" % size.x) == OK)
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.save_path+suffix))
	print("PASS: technique panel is reachable at two sizes")
	quit()