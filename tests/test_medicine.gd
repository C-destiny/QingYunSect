extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var state = load("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	assert(not state.start_medicine())
	assert(state.start_construction(&"training_ground", Vector2i(0, 0)))
	state.process_construction(999)
	state.resources["food"] = 100
	state.resources["spirit_stone"] = 100
	assert(state.start_medicine())
	assert(state.resources["food"] == 80 and state.resources["spirit_stone"] == 92)
	assert(not state.start_medicine())
	state.process_medicine(59)
	assert(state.medicine["stock"] == 0)
	var snapshot: Dictionary = state.export_save_data()
	assert(state.import_save_data(snapshot))
	state.process_medicine(1)
	assert(state.medicine["stock"] == 1)
	var disciple: Dictionary = state.get_disciple(1)
	var cultivation: float = disciple["cultivation"]
	assert(state.use_medicine(1))
	assert(disciple["cultivation"] == cultivation + 5)
	assert(not state.use_medicine(1))
	assert(state.start_medicine())
	state.apply_offline_progress({"eligible":true,"effective_seconds":60,"settlement_id":"medicine"})
	assert(state.medicine["stock"] == 1)
	var before: Dictionary = state.export_save_data()
	for bad: Variant in [{"stock":-1,"remaining":0},{"stock":0.5,"remaining":0},{"stock":0,"remaining":61},{"stock":20,"remaining":1}]:
		var corrupt: Dictionary = before.duplicate(true)
		corrupt["medicine"] = bad
		assert(not state.import_save_data(corrupt))
		assert(state.export_save_data() == before)
	var old: Dictionary = before.duplicate(true)
	old.erase("medicine")
	assert(state.import_save_data(old))
	assert(state.medicine == {"stock":0,"remaining":0.0})
	var manager = load("res://scripts/core/save_manager.gd").new()
	root.add_child(manager)
	manager.game_state = state
	manager.save_path = "res://tests/.missing_medicine_folder/save.json"
	var panel = load("res://scripts/ui/medicine_panel.gd").new()
	root.add_child(panel)
	panel.setup(state,manager,func(): return 1)
	var rollback: Dictionary = state.export_save_data()
	panel.perform(false)
	assert(state.export_save_data() == rollback)
	assert("撤回" in panel.feedback.text)
	state.medicine["stock"] = 1
	rollback = state.export_save_data()
	panel.perform(true)
	assert(state.export_save_data() == rollback)
	panel.queue_free()
	manager.queue_free()
	state.queue_free()
	print("PASS: medicine costs, timer, offline, migration, illegal data and save rollback")
	quit()