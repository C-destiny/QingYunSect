extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	assert(not state.can_recruit_disciple())
	state.buildings.append({
		"instance_id": 1,
		"type": "disciple_quarters",
		"cell_x": 0,
		"cell_y": 0,
		"remaining": 0.0,
		"build_time": 6.0,
		"completed": true,
	})
	assert(state.get_disciple_capacity() == 5)
	var stones_before := state.get_resource_amount(&"spirit_stone")
	var food_before := state.get_resource_amount(&"food")
	assert(state.start_recruitment())
	assert(state.is_recruiting())
	assert(not state.start_recruitment())
	assert(state.get_resource_amount(&"spirit_stone") == stones_before - 25)
	assert(state.get_resource_amount(&"food") == food_before - 20)
	state.process_recruitment(2.0)
	var saved := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(saved))
	assert(restored.is_recruiting())
	assert(is_equal_approx(restored.recruitment_remaining, 3.0))
	restored.process_recruitment(3.1)
	assert(not restored.is_recruiting())
	assert(restored.total_disciples == 4)
	assert(restored.get_idle_disciples() == 4)
	print("PASS: disciple recruitment, capacity, cost, timer, and persistence")
	quit()
