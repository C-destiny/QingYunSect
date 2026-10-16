extends SceneTree

func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	for disciple: Dictionary in state.disciples:
		assert(state.set_disciple_job(int(disciple["id"]), &"combat"))
	assert(state.start_auto_battle(1))
	var wood_before := state.get_resource_amount(&"wood")
	var food_before := state.get_resource_amount(&"food")
	var receipt: Dictionary = state.apply_offline_progress({"eligible": true, "effective_seconds": 600, "settlement_id": "battle"})
	assert(receipt["battle_victories"] == 86)
	assert(state.get_resource_amount(&"wood") == wood_before + 86 * 20)
	assert(state.get_resource_amount(&"food") == food_before - 30 + 86 * 10)
	assert(state.highest_unlocked_stage == 2)
	assert(state.selected_battle_stage == 1)
	assert(state.auto_battle_enabled)
	assert(state.battle_restart_cooldown > 0.0)

	var failure := preload("res://scripts/core/game_state.gd").new()
	root.add_child(failure)
	failure.get_idle_disciples()
	assert(failure.set_disciple_job(int(failure.disciples[0]["id"]), &"combat"))
	failure.highest_unlocked_stage = 5
	assert(failure.start_auto_battle(5))
	var failed: Dictionary = failure.apply_offline_progress({"eligible": true, "effective_seconds": 600, "settlement_id": "failure"})
	assert(failed["battle_victories"] == 0)
	assert(failed["battle_reason"] == "defeat")
	assert(not failure.auto_battle_enabled)
	print("PASS: analytical offline battle handles repeat rewards, no stage advance, and defeat")
	quit()
