extends SceneTree
const PATH := "res://tests/.practice_entry.json"
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var manager := root.get_node("SaveManager")
	manager.save_path = PATH
	manager.unix_time_provider = func() -> int: return 5000
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var state := root.get_node("GameState")
	var main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var before: Dictionary = state.export_save_data()
	main._enter_practice()
	assert(not main.visible and main.process_mode == Node.PROCESS_MODE_DISABLED)
	var arena = root.get_child(root.get_child_count()-1)
	arena._physics_process(0)
	arena.set_physics_process(false)
	arena.simulation.enemies.append({"pos":Vector2(700,380),"hp":24.0,"warning":0.8,"target":Vector2(600,380)})
	if DisplayServer.get_name() != "headless":
		for resolution: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
			root.size = resolution
			arena.queue_redraw()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/art/p4-practice-%d.png" % resolution.x)
	arena.exited.emit()
	await process_frame
	assert(main.visible and main.process_mode != Node.PROCESS_MODE_DISABLED)
	var after: Dictionary = state.export_save_data()
	after.erase("dungeon_progress")
	before.erase("dungeon_progress")
	assert(after == before)
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("PASS: practice enters, freezes sect, exits and preserves permanent state")
	quit()
