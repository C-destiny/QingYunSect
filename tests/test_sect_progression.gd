extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	assert(state.get_idle_disciples() == 3)
	assert(state.get_sect_prosperity() == 45)
	assert(not state.can_upgrade_sect())
	state.buildings.append({
		"instance_id": 1, "type": "lumber_yard", "cell_x": 0, "cell_y": 0,
		"remaining": 0.0, "build_time": 5.0, "completed": true, "level": 3, "upgrading": false,
	})
	assert(state.get_sect_prosperity() == 105)
	assert(state.can_upgrade_sect())
	assert(state.upgrade_sect())
	assert(state.sect_level == 2)
	assert(is_equal_approx(state.get_sect_production_multiplier(), 1.05))
	assert(state.assign_disciple(&"forest"))
	var wood_before := state.get_resource_amount(&"wood")
	assert(state.process_production(&"forest", &"wood", 20.0, 60.0) == 36)
	assert(state.get_resource_amount(&"wood") == wood_before + 36)
	var saved := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(saved))
	assert(restored.sect_level == 2)
	assert(restored.get_sect_prosperity() == state.get_sect_prosperity())
	print("PASS: sect prosperity, level requirements, production bonus, and persistence")
	quit()
