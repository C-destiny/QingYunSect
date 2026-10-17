extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	assert(state.get_current_development_goal_id() == &"sect_level_2")
	assert(not state.claim_development_goal(&"sect_level_2"))
	state.sect_level = 2
	var before := state.resources.duplicate(true)
	assert(state.claim_development_goal(&"sect_level_2"))
	assert(state.get_resource_amount(&"wood") == int(before["wood"]) + 40)
	assert(not state.claim_development_goal(&"sect_level_2"))
	assert(state.get_current_development_goal_id() == &"unlock_east")
	state.unlocked_regions.append("east")
	assert(state.claim_development_goal(&"unlock_east"))
	assert(state.claimed_development_goals == ["sect_level_2", "unlock_east"])

	var saved := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(saved))
	assert(restored.claimed_development_goals == state.claimed_development_goals)
	var invalid := saved.duplicate(true)
	invalid["claimed_development_goals"] = ["unlock_east"]
	var rollback := restored.export_save_data()
	assert(not restored.import_save_data(invalid))
	assert(restored.export_save_data() == rollback)
	invalid = saved.duplicate(true)
	invalid["claimed_development_goals"] = ["sect_level_2", "sect_level_2"]
	assert(not restored.import_save_data(invalid))
	assert(restored.export_save_data() == rollback)
	print("PASS: sequential development goals grant once, persist, and reject invalid claimed state")
	quit()
