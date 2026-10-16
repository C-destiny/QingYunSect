extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	assert(state.get_idle_disciples() == 3)
	assert(state.disciples.size() == 3)
	assert(str(state.disciples[0]["name"]) != str(state.disciples[1]["name"]))
	var first_id := int(state.disciples[0]["id"])
	assert(state.assign_disciple(&"forest"))
	assert(StringName(state.get_disciple(first_id)["job"]) == &"forest")
	state.get_disciple(first_id)["realm_level"] = 3
	assert(is_equal_approx(state.get_site_workforce_power(&"forest"), 1.1))
	var wood_before := state.get_resource_amount(&"wood")
	assert(state.process_production(&"forest", &"wood", 12.0, 60.0) == 13)
	assert(state.get_resource_amount(&"wood") == wood_before + 13)
	state.get_disciple(first_id)["realm_level"] = 1
	state.get_disciple(first_id)["cultivation"] = 10.0
	assert(state.can_breakthrough(first_id))
	assert(state.breakthrough_disciple(first_id))
	assert(int(state.get_disciple(first_id)["realm_level"]) == 2)
	assert(is_equal_approx(float(state.get_disciple(first_id)["cultivation"]), 0.0))
	assert(state.unassign_disciple(&"forest"))
	state.buildings.append({
		"instance_id": 1, "type": "training_ground", "cell_x": 0, "cell_y": 0,
		"remaining": 0.0, "build_time": 10.0, "completed": true, "level": 1,
	})
	assert(state.assign_training_disciple())
	assert(is_equal_approx(state.process_training(60.0), 1.0))
	assert(is_equal_approx(float(state.get_disciple(first_id)["cultivation"]), 1.0))
	var saved := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(saved))
	var restored_disciple := restored.get_disciple(first_id)
	assert(str(restored_disciple["name"]) == str(state.get_disciple(first_id)["name"]))
	assert(int(restored_disciple["realm_level"]) == 2)
	assert(StringName(restored_disciple["job"]) == &"training")
	assert(is_equal_approx(float(restored_disciple["cultivation"]), 1.0))
	restored_disciple["realm_level"] = 9
	restored_disciple["cultivation"] = 999.0
	assert(not restored.can_breakthrough(first_id))
	var legacy_save := saved.duplicate(true)
	legacy_save.erase("disciples")
	legacy_save.erase("next_disciple_id")
	var migrated := preload("res://scripts/core/game_state.gd").new()
	root.add_child(migrated)
	assert(migrated.import_save_data(legacy_save))
	assert(migrated.disciples.size() == state.total_disciples)
	assert(migrated.training_disciples == 1)
	print("PASS: disciple roster, names, jobs, realms, gathering bonus, breakthrough, and persistence")
	quit()
