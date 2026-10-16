extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.resources["food"] = 10
	assert(is_equal_approx(state.get_food_consumption_per_minute(), 3.0))
	assert(state.process_disciple_consumption(20.0) == 1)
	assert(state.get_resource_amount(&"food") == 9)
	assert(is_equal_approx(state.get_sustenance_multiplier(), 1.0))
	state.resources["food"] = 0
	assert(is_equal_approx(state.get_sustenance_multiplier(), 0.5))
	assert(state.assign_disciple(&"forest"))
	var wood_before := state.get_resource_amount(&"wood")
	assert(state.process_production(&"forest", &"wood", 12.0, 10.0) == 1)
	assert(state.get_resource_amount(&"wood") == wood_before + 1)
	state.food_consumption_progress = 0.75
	var saved := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(saved))
	assert(is_equal_approx(restored.food_consumption_progress, 0.75))
	print("PASS: disciple food consumption, hunger penalty, and persistence")
	quit()
