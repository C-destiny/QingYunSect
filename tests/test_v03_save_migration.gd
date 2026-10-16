extends SceneTree


func _new_state() -> Node:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	return state


func _as_v03_save(data: Dictionary) -> Dictionary:
	var legacy := data.duplicate(true)
	legacy.erase("battle_encounter_sequence")
	legacy.erase("active_battle_encounter_id")
	legacy.erase("last_settled_battle_encounter_id")
	return legacy


func _init() -> void:
	var fighting_source := _new_state()
	var fighter_id := int(fighting_source.disciples[0]["id"])
	assert(fighting_source.set_disciple_job(fighter_id, &"combat"))
	assert(fighting_source.start_auto_battle(1))
	fighting_source.process_battle(1.0)
	var fighting_save := _as_v03_save(fighting_source.export_save_data())
	var fighting_restored := _new_state()
	assert(fighting_restored.import_save_data(fighting_save))
	assert(fighting_restored.get_battle_phase() == &"fighting")
	assert(fighting_restored.active_battle_encounter_id > 0)
	assert(is_equal_approx(fighting_restored.battle_enemy_hp, fighting_source.battle_enemy_hp))

	var waiting_source := _new_state()
	var waiting_id := int(waiting_source.disciples[0]["id"])
	assert(waiting_source.set_disciple_job(waiting_id, &"combat"))
	assert(waiting_source.start_auto_battle(1))
	assert(waiting_source.process_battle(20.0))
	var waiting_wood: int = waiting_source.get_resource_amount(&"wood")
	var waiting_wins: int = waiting_source.battle_victories
	var waiting_save := _as_v03_save(waiting_source.export_save_data())
	var waiting_restored := _new_state()
	assert(waiting_restored.import_save_data(waiting_save))
	assert(waiting_restored.get_battle_phase() == &"repeat_wait")
	assert(waiting_restored.active_battle_encounter_id == 0)
	assert(waiting_restored.get_resource_amount(&"wood") == waiting_wood)
	assert(waiting_restored.battle_victories == waiting_wins)
	assert(not waiting_restored.process_battle(waiting_restored.BATTLE_RESTART_DELAY))
	assert(waiting_restored.get_battle_phase() == &"fighting")
	assert(waiting_restored.get_resource_amount(&"wood") == waiting_wood)

	var stopped_source := _new_state()
	var stopped_id := int(stopped_source.disciples[0]["id"])
	assert(stopped_source.set_disciple_job(stopped_id, &"combat"))
	assert(stopped_source.start_auto_battle(1))
	stopped_source.stop_auto_battle()
	var stopped_save := _as_v03_save(stopped_source.export_save_data())
	var stopped_restored := _new_state()
	assert(stopped_restored.import_save_data(stopped_save))
	assert(stopped_restored.get_battle_phase() == &"stopped")
	assert(stopped_restored.active_battle_encounter_id == 0)

	var older_save := stopped_save.duplicate(true)
	older_save.erase("disciples")
	older_save.erase("next_disciple_id")
	older_save.erase("battle_party")
	older_save.erase("battle_running")
	older_save.erase("auto_battle_enabled")
	older_save.erase("battle_restart_cooldown")
	older_save["assignments"] = {"forest": 1}
	older_save["training_disciples"] = 0
	older_save["total_disciples"] = 3
	var older_restored := _new_state()
	assert(older_restored.import_save_data(older_save))
	assert(older_restored.total_disciples == 3)
	assert(older_restored.get_assignment(&"forest") == 1)
	assert(older_restored.training_disciples == 0)
	assert(older_restored.get_battle_phase() == &"stopped")

	var invalid_type := fighting_save.duplicate(true)
	invalid_type["resources"] = []
	var unchanged: Dictionary = fighting_restored.export_save_data()
	assert(not fighting_restored.import_save_data(invalid_type))
	assert(fighting_restored.export_save_data() == unchanged)

	var contradictory := fighting_save.duplicate(true)
	contradictory["battle_running"] = false
	contradictory["auto_battle_enabled"] = true
	contradictory["battle_restart_cooldown"] = 0.0
	assert(not fighting_restored.import_save_data(contradictory))
	assert(fighting_restored.export_save_data() == unchanged)
	print("PASS: V0.3 fighting, repeat-wait, stopped, and older saves migrate safely")
	quit()
