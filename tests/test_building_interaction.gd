extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.resources["wood"] = 200
	state.resources["spirit_stone"] = 200
	assert(state.start_construction(&"lumber_yard", Vector2i(0, 0)))
	var lumber_id := int(state.buildings[0]["instance_id"])
	state.process_construction(6.0)
	assert(state.get_completed_building_count(&"lumber_yard") == 1)
	assert(is_equal_approx(state.get_production_multiplier(&"wood"), 1.25))
	var wood_before_refund := state.get_resource_amount(&"wood")
	var stone_before_refund := state.get_resource_amount(&"spirit_stone")
	var refund := state.demolish_building(lumber_id)
	assert(int(refund["wood"]) == 15)
	assert(int(refund["spirit_stone"]) == 7)
	assert(state.get_resource_amount(&"wood") == wood_before_refund + 15)
	assert(state.get_resource_amount(&"spirit_stone") == stone_before_refund + 7)
	assert(is_equal_approx(state.get_production_multiplier(&"wood"), 1.0))
	assert(state.start_construction(&"disciple_quarters", Vector2i(1, 0)))
	state.process_construction(7.0)
	var quarters_id := int(state.buildings[0]["instance_id"])
	state.total_disciples = 4
	assert(not state.can_demolish_building(quarters_id))
	assert(state.demolish_building(quarters_id).is_empty())
	state.total_disciples = 3
	assert(state.can_demolish_building(quarters_id))
	print("PASS: building selection data, totals, demolition refund, and capacity guard")
	quit()
