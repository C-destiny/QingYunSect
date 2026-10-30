extends SceneTree
func _init() -> void:
	call_deferred("run")
func capture(tag: String) -> void:
	for size: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = size
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/art/p6-%s-%d.png" % [tag,size.x])
func run() -> void:
	var manager := root.get_node("SaveManager")
	manager.save_path = "res://tests/.audit_dungeon_loop.json"
	manager.unix_time_provider = func() -> int: return 5000
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.save_path+suffix))
	var state := root.get_node("GameState")
	state.set_disciple_job(2,&"forest")
	state.set_disciple_job(3,&"field")
	var main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	main.selected_disciple_id = 1
	main._enter_practice()
	var arena = root.get_child(root.get_child_count()-1)
	arena.set_physics_process(false)
	arena.simulation.kills = 20
	arena.simulation.elapsed = 460
	arena.simulation.phase = "victory"
	arena._physics_process(0)
	await capture("victory")
	arena.exited.emit()
	await process_frame
	await capture("returned")
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.save_path+suffix))
	print("PASS: P6 fixture victory preview and persisted return settlement GPU screenshots")
	quit()
