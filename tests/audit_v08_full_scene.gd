extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _capture(main: Control, mode: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://builds/v08-scene-audit/full4-%s-%dx%d.png" % [mode, root.size.x, root.size.y]
	assert(root.get_texture().get_image().save_png(path) == OK)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/v08-scene-audit"))
	root.get_node("SaveManager").save_path = "res://tests/.test_full_scene_audit.json"
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var state := root.get_node("GameState")
	assert(preload("res://scripts/world/visual_demo.gd").populate_full_scene(state))
	var map: Control = main.sect_map
	main._refresh_resources()
	main._refresh_sect_progress()
	main._close_management_panel()
	for window_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = window_size
		map.clear_selection()
		map.hovered_cell = Vector2i(-1, -1)
		await _capture(main, "normal")
		for kind: StringName in BuildingCatalog.BUILDINGS:
			map.start_placement(kind)
			map.hovered_cell = Vector2i(5, 5)
			map.queue_redraw()
			await _capture(main, "preview-" + String(kind))
		map.cancel_placement()
		for building: Dictionary in state.buildings:
			main._on_building_selected(building)
			await _capture(main, "card-" + String(building["type"]))
			main._dismiss_building_card()
	main.queue_free()
	await process_frame
	print("PASS: full-map isolated seven-building scene, previews and cards captured; visual acceptance remains with owner")
	quit()
