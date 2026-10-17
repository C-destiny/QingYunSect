extends SceneTree

const SIMULATED_SECONDS := 8 * 60 * 60


func _add_completed_building(state: Node, building_type: String, cell: Vector2i, level: int) -> void:
	state.buildings.append({
		"instance_id": state.next_building_id, "type": building_type, "cell_x": cell.x, "cell_y": cell.y,
		"remaining": 0.0, "build_time": 1.0, "completed": true, "level": level, "upgrading": false,
	})
	state.next_building_id += 1


func _init() -> void:
	var started_ms := Time.get_ticks_msec()
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.resources = {"wood": 100000, "spirit_stone": 100000, "food": 100000}
	state.sect_level = 5
	state.unlocked_regions = ["core", "east", "south"]
	_add_completed_building(state, "disciple_quarters", Vector2i(0, 0), 2)
	_add_completed_building(state, "lumber_yard", Vector2i(1, 0), 3)
	_add_completed_building(state, "spirit_mine", Vector2i(2, 0), 3)
	_add_completed_building(state, "spirit_field", Vector2i(3, 0), 3)
	_add_completed_building(state, "training_ground", Vector2i(4, 0), 3)
	_add_completed_building(state, "artifact_forge", Vector2i(5, 0), 3)
	_add_completed_building(state, "scripture_library", Vector2i(6, 0), 3)
	state.get_idle_disciples()
	while state.total_disciples < state.get_disciple_capacity():
		state._create_disciple()
	assert(state.set_disciple_job(int(state.disciples[0]["id"]), &"forest"))
	assert(state.set_disciple_job(int(state.disciples[1]["id"]), &"mine"))
	assert(state.set_disciple_job(int(state.disciples[2]["id"]), &"field"))
	assert(state.set_disciple_job(int(state.disciples[3]["id"]), &"training"))
	for index: int in range(4, 7):
		assert(state.set_disciple_job(int(state.disciples[index]["id"]), &"combat"))
	assert(state.start_auto_battle(1))
	assert(state.craft_equipment(&"initiate_weapon", &"common") > 0)
	assert(state.craft_equipment(&"cloud_robe", &"rare") > 0)
	assert(state.craft_equipment(&"spirit_ring", &"epic") > 0)
	var before := state.resources.duplicate(true)
	var receipt: Dictionary = state.apply_offline_progress({"eligible": true, "effective_seconds": SIMULATED_SECONDS, "settlement_id": "v07-eight-hours"})
	assert(int(receipt["battle_victories"]) > 0)
	assert(is_equal_approx(float(receipt["cultivation_gained"]), 3.2 * 8.0 * 60.0))
	for resource_id: StringName in state.RESOURCE_IDS:
		assert(state.get_resource_amount(resource_id) >= 0)
	assert(state.get_resource_amount(&"wood") > int(before["wood"]))
	assert(state.equipment_inventory.size() <= state.MAX_EQUIPMENT_INVENTORY)
	assert(state.battle_log.size() <= state.BATTLE_LOG_LIMIT)

	state.disciples[3]["realm_level"] = 3
	for goal_id: StringName in preload("res://scripts/data/development_goal_catalog.gd").GOAL_IDS:
		assert(state.claim_development_goal(goal_id))
	var after_goals := state.resources.duplicate(true)
	assert(not state.claim_development_goal(&"unlock_south"))
	assert(state.resources == after_goals)

	var snapshot := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(snapshot))
	assert(restored.export_save_data() == snapshot)
	var elapsed_ms := Time.get_ticks_msec() - started_ms
	print("EVIDENCE: v07_simulated_hours=8 wall_ms=%d victories=%d cultivation=%.1f inventory=%d wood_delta=%d" % [elapsed_ms, int(receipt["battle_victories"]), float(receipt["cultivation_gained"]), state.equipment_inventory.size(), state.get_resource_amount(&"wood") - int(before["wood"])])
	print("PASS: V0.7 eight-hour territory, buildings, crafting, training, goals, battle, and save integration")
	quit()
