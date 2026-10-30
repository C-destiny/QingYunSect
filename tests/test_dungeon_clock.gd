extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var manager := root.get_node("SaveManager")
	manager.save_path = "res://tests/.dungeon_clock.json"
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
	var before: Variant = JSON.parse_string(JSON.stringify(state.export_save_data()))
	arena.simulation.paused = true
	arena._physics_process(1)
	assert(before == JSON.parse_string(JSON.stringify(state.export_save_data())))
	arena.simulation.paused = false
	arena._physics_process(1)
	assert(float(state.production_progress.get("forest",0)) > 0)
	arena.simulation.gain_experience(12)
	before = JSON.parse_string(JSON.stringify(state.export_save_data()))
	arena._physics_process(1)
	assert(before == JSON.parse_string(JSON.stringify(state.export_save_data())))
	arena.simulation.pending_choices = 0
	manager.save_completed.connect(func(ok: bool,_message: String) -> void:
		if ok:
			manager.save_path = "res://tests/missing-p6/save.json",CONNECT_ONE_SHOT)
	arena._restart_run()
	assert(arena.run_id == 0)
	var elapsed: float = arena.simulation.elapsed
	arena.simulation.paused = false
	arena._physics_process(1)
	assert(arena.simulation.elapsed == elapsed)
	manager.save_path = "res://tests/.dungeon_clock.json"
	arena._restart_run()
	assert(arena.run_id > 0 and arena.simulation.elapsed == 0)
	arena.exited.emit()
	await process_frame
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.save_path+suffix))
	print("PASS: sect combat clock, pause/upgrade freeze and failed restart guard")
	quit()
