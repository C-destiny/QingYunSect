extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	assert(state.get_idle_disciples() == 3)
	var first_id := int(state.disciples[0]["id"])
	var second_id := int(state.disciples[1]["id"])
	assert(state.set_disciple_job(first_id, &"forest"))
	assert(state.get_assignment(&"forest") == 1)
	assert(state.get_idle_disciples() == 2)
	assert(state.set_disciple_job(first_id, &"mine"))
	assert(state.get_assignment(&"forest") == 0)
	assert(state.get_assignment(&"mine") == 1)
	assert(not state.set_disciple_job(first_id, &"invalid"))
	assert(StringName(state.get_disciple(first_id)["job"]) == &"mine")
	assert(not state.set_disciple_job(first_id, &"training"))
	state.buildings.append({
		"instance_id": 1, "type": "training_ground", "cell_x": 0, "cell_y": 0,
		"remaining": 0.0, "build_time": 10.0, "completed": true, "level": 1,
	})
	assert(state.set_disciple_job(first_id, &"training"))
	assert(state.set_disciple_job(second_id, &"training"))
	assert(state.training_disciples == 2)
	var third_id := int(state.disciples[2]["id"])
	assert(not state.set_disciple_job(third_id, &"training"))
	assert(state.set_disciple_job(first_id, &"idle"))
	assert(state.set_disciple_job(third_id, &"training"))
	var saved := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(saved))
	assert(StringName(restored.get_disciple(first_id)["job"]) == &"idle")
	assert(StringName(restored.get_disciple(second_id)["job"]) == &"training")
	assert(StringName(restored.get_disciple(third_id)["job"]) == &"training")
	print("PASS: direct disciple job assignment, switching, capacity, and persistence")
	quit()
