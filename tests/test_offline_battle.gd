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
	var stage: Dictionary = preload("res://scripts/data/battle_catalog.gd").get_stage(1)
	var party: Dictionary = state.get_battle_party_stats()
	var damage := preload("res://scripts/data/battle_catalog.gd").calculate_damage(float(party["attack"]), float(stage["defense"]))
	var win_rounds := ceili(float(stage["hp"]) / damage)
	var fight_seconds := float(win_rounds) * state.BATTLE_ROUND_TIME
	var expected_victories := 1 + floori((600.0 - fight_seconds) / (fight_seconds + state.BATTLE_RESTART_DELAY))
	var receipt: Dictionary = state.apply_offline_progress({"eligible": true, "effective_seconds": 600, "settlement_id": "battle"})
	assert(receipt["battle_victories"] == expected_victories)
	assert(state.get_resource_amount(&"wood") == wood_before + expected_victories * 20)
	assert(state.get_resource_amount(&"food") == food_before - 30 + expected_victories * 10)
	assert(state.highest_unlocked_stage == 2)
	assert(state.selected_battle_stage == 1)
	assert(state.auto_battle_enabled)
	assert(state.get_battle_phase() in [&"fighting", &"repeat_wait"])
	if state.battle_running:
		assert(is_zero_approx(state.battle_restart_cooldown))
	else:
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
