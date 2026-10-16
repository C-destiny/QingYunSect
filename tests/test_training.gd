extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.buildings.append({
		"instance_id": 1,
		"type": "training_ground",
		"cell_x": 0,
		"cell_y": 0,
		"remaining": 0.0,
		"build_time": 10.0,
		"completed": true,
		"level": 1,
	})
	assert(state.get_training_capacity() == 2)
	assert(state.assign_training_disciple())
	assert(state.assign_training_disciple())
	assert(not state.assign_training_disciple())
	assert(state.assigned_disciples == 2)
	assert(state.get_idle_disciples() == 1)
	assert(is_equal_approx(state.process_training(30.0), 1.0))
	assert(is_equal_approx(state.cultivation_points, 1.0))
	assert(not state.can_demolish_building(1))
	var saved := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(saved))
	assert(restored.training_disciples == 2)
	assert(restored.assigned_disciples == 2)
	assert(is_equal_approx(restored.cultivation_points, 1.0))
	assert(restored.unassign_training_disciple())
	assert(not restored.can_demolish_building(1))
	assert(restored.unassign_training_disciple())
	assert(restored.can_demolish_building(1))
	print("PASS: training assignment, cultivation, capacity, demolition guard, and persistence")
	quit()
