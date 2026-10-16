extends SceneTree

func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	state.buildings.append({
		"instance_id": 1, "type": "training_ground", "cell_x": 0, "cell_y": 0,
		"remaining": 2.0, "build_time": 10.0, "completed": false, "level": 1, "upgrading": false,
	})
	state.buildings.append({
		"instance_id": 2, "type": "lumber_yard", "cell_x": 1, "cell_y": 0,
		"remaining": 0.0, "build_time": 5.0, "completed": true, "level": 1,
		"upgrading": true, "upgrade_remaining": 3.0, "upgrade_time": 10.0, "target_level": 2,
	})
	state.next_building_id = 3
	state.recruitment_remaining = 4.0
	state.resources["food"] = 100
	var receipt: Dictionary = state.apply_offline_progress({"eligible": true, "effective_seconds": 5, "settlement_id": "activities"})
	assert(bool(state.buildings[0]["completed"]))
	assert(int(state.buildings[1]["level"]) == 2 and not bool(state.buildings[1]["upgrading"]))
	assert(state.total_disciples == 4)
	assert(receipt["construction_completed"] == 1)
	assert(receipt["upgrades_completed"] == 1)
	assert(receipt["recruited"] == 1)

	assert(state.set_disciple_job(int(state.disciples[0]["id"]), &"training"))
	var cultivation_before := float(state.disciples[0]["cultivation"])
	var training: Dictionary = state.apply_offline_progress({"eligible": true, "effective_seconds": 60, "settlement_id": "training"})
	assert(float(state.disciples[0]["cultivation"]) > cultivation_before)
	assert(float(training["cultivation_gained"]) > 0.0)
	print("PASS: offline construction, upgrade, recruitment, and training advance once")
	quit()
