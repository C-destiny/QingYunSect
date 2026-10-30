extends SceneTree


func _make_training_state(with_completed_library: bool = true) -> Node:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	state.buildings.append({"instance_id": 1, "type": "training_ground", "cell_x": 0, "cell_y": 0, "remaining": 0.0, "build_time": 10.0, "completed": true, "level": 1, "upgrading": false})
	state.buildings.append({"instance_id": 2, "type": "scripture_library", "cell_x": 1, "cell_y": 0, "remaining": 10.0 if not with_completed_library else 0.0, "build_time": 14.0, "completed": with_completed_library, "level": 1, "upgrading": false})
	state.next_building_id = 3
	assert(state.assign_training_disciple())
	return state


func _init() -> void:
	var online := _make_training_state()
	var online_gain: float = online.process_training(60.0)
	assert(is_equal_approx(online_gain, 1.2))

	var offline := _make_training_state()
	var receipt: Dictionary = offline.apply_offline_progress({"eligible": true, "effective_seconds": 60, "settlement_id": "training-check"})
	assert(is_equal_approx(float(receipt["cultivation_gained"]), online_gain))
	assert(is_equal_approx(float(offline.disciples[0]["cultivation"]), float(online.disciples[0]["cultivation"])))

	var constructing := _make_training_state(false)
	assert(is_equal_approx(constructing.get_training_rate_multiplier(), 1.0))
	var segmented: Dictionary = constructing.apply_offline_progress({"eligible": true, "effective_seconds": 20, "settlement_id": "segment-check"})
	assert(is_equal_approx(float(segmented["cultivation_gained"]), 10.0 / 60.0 + 1.2 * 10.0 / 60.0))

	var disciple_id := int(offline.disciples[0]["id"])
	assert(offline.set_disciple_job(disciple_id, &"combat"))
	assert(offline.training_disciples == 0)
	assert(disciple_id in offline.battle_party)
	assert(offline.EQUIPMENT_DROP_INTERVAL == 100)
	print("PASS: scripture bonuses match online/offline training, segment at completion, and preserve job exclusivity")
	quit()
