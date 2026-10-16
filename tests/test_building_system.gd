extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	assert(not state.is_cell_occupied(Vector2i(0, 0)))
	assert(state.is_cell_occupied(Vector2i(4, 3)))
	assert(state.start_construction(&"lumber_yard", Vector2i(0, 0)))
	assert(state.get_resource_amount(&"wood") == 90)
	assert(state.get_resource_amount(&"spirit_stone") == 65)
	assert(state.is_cell_occupied(Vector2i(0, 0)))
	assert(not state.start_construction(&"spirit_field", Vector2i(0, 0)))
	assert(not bool(state.buildings[0]["completed"]))
	state.process_construction(5.1)
	assert(bool(state.buildings[0]["completed"]))
	var saved := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(saved))
	assert(restored.buildings.size() == 1)
	assert(bool(restored.buildings[0]["completed"]))
	assert(restored.is_cell_occupied(Vector2i(0, 0)))
	print("PASS: building placement, cost, construction, and persistence")
	quit()

