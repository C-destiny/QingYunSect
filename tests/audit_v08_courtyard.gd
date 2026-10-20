extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _capture(mode: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://builds/v08-scene-audit/fusion7-%s-%dx%d.png" % [mode, root.size.x, root.size.y]) == OK)

func _run() -> void:
	root.get_node("SaveManager").save_path = "res://tests/.test_courtyard_audit.json"
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var state := root.get_node("GameState")
	assert(preload("res://scripts/world/courtyard_demo.gd").populate(state))
	main._refresh_resources()
	main._refresh_sect_progress()
	main._close_management_panel()
	for window_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = window_size
		main.sect_map.queue_redraw()
		await _capture("normal")
		main._on_building_selected(state.buildings[0])
		await _capture("wing-card")
		main._dismiss_building_card()
		main._on_hall_selected()
		await _capture("hall-card")
		main._dismiss_building_card()
		main.sect_map.start_placement(&"disciple_quarters")
		main.sect_map.hovered_cell = Vector2i(5, 4)
		main.sect_map.queue_redraw()
		await _capture("preview")
		main.sect_map.cancel_placement()
	main.queue_free()
	await process_frame
	print("PASS: local courtyard main hall, wing, foreground, cards and preview rendered in two sizes")
	quit()
