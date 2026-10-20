extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.get_node("SaveManager").save_path = "res://tests/.test_open_scene_audit.json"
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	assert(preload("res://scripts/world/visual_demo.gd").populate_full_scene(root.get_node("GameState")))
	main._refresh_resources()
	main._refresh_sect_progress()
	main._close_management_panel()
	for window_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = window_size
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://builds/v08-scene-audit/open6-normal-%dx%d.png" % [window_size.x, window_size.y]) == OK)
	main.queue_free()
	await process_frame
	print("PASS: isolated open terrace scene rendered at two window sizes")
	quit()
