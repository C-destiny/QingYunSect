extends SceneTree


func _new_state() -> Node:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	return state


func _init() -> void:
	var state := _new_state()
	state._create_disciple()
	state._sync_aggregate_state_from_disciples()
	var first_id := int(state.disciples[0]["id"])
	var second_id := int(state.disciples[1]["id"])
	var third_id := int(state.disciples[2]["id"])
	var fourth_id := int(state.disciples[3]["id"])
	assert(state.set_disciple_job(first_id, &"combat"))
	assert(state.set_disciple_job(second_id, &"combat"))
	assert(state.set_disciple_job(third_id, &"combat"))
	assert(state.is_battle_party_consistent())
	assert(not state.set_disciple_job(fourth_id, &"combat"))
	assert(StringName(state.get_disciple(fourth_id)["job"]) == &"idle")
	assert(state.battle_party == [first_id, second_id, third_id])
	assert(state.assigned_disciples == 3)

	assert(state.start_auto_battle(1))
	var player_hp: float = state.battle_player_hp
	assert(state.set_disciple_job(fourth_id, &"forest"))
	assert(state.battle_running)
	assert(state.get_assignment(&"forest") == 1)
	assert(state.assigned_disciples == 4)
	assert(state.set_disciple_job(first_id, &"combat"))
	assert(state.battle_running)
	assert(is_equal_approx(state.battle_player_hp, player_hp))
	assert(state.set_disciple_job(first_id, &"idle"))
	assert(not state.battle_running)
	assert(not state.auto_battle_enabled)
	assert(first_id not in state.battle_party)
	assert(state.is_battle_party_consistent())
	assert(state.assigned_disciples == 3)

	var waiting_state := _new_state()
	var waiting_id := int(waiting_state.disciples[0]["id"])
	assert(waiting_state.set_disciple_job(waiting_id, &"combat"))
	assert(waiting_state.start_auto_battle(1))
	assert(waiting_state.process_battle(20.0))
	assert(waiting_state.get_battle_phase() == &"repeat_wait")
	assert(waiting_state.set_disciple_job(waiting_id, &"idle"))
	assert(waiting_state.get_battle_phase() == &"stopped")
	assert(is_zero_approx(waiting_state.battle_restart_cooldown))

	var missing_state := _new_state()
	var missing_id := int(missing_state.disciples[0]["id"])
	assert(missing_state.set_disciple_job(missing_id, &"combat"))
	assert(missing_state.start_auto_battle(1))
	missing_state.battle_party[0] = 999999
	assert(not missing_state.process_battle(1.0))
	assert(missing_state.get_battle_phase() == &"stopped")
	assert(not missing_state.auto_battle_enabled)

	var source := _new_state()
	var source_first := int(source.disciples[0]["id"])
	var source_second := int(source.disciples[1]["id"])
	assert(source.set_disciple_job(source_first, &"combat"))
	assert(source.set_disciple_job(source_second, &"combat"))
	var inconsistent_save: Dictionary = source.export_save_data()
	inconsistent_save["battle_party"] = [source_first]
	var rejected := _new_state()
	assert(not rejected.import_save_data(inconsistent_save))

	var legacy_save: Dictionary = source.export_save_data()
	legacy_save.erase("battle_party")
	var restored := _new_state()
	assert(restored.import_save_data(legacy_save))
	assert(restored.battle_party == [source_first, source_second])
	assert(restored.is_battle_party_consistent())
	print("PASS: combat jobs and battle party stay mutually exclusive and consistent")
	quit()
