extends SceneTree

const SIMULATED_SECONDS := 8 * 60 * 60

func _init() -> void:
	var started_ms := Time.get_ticks_msec()
	var memory_before := OS.get_static_memory_usage()
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	for disciple: Dictionary in state.disciples:
		assert(state.set_disciple_job(int(disciple["id"]), &"combat"))
	assert(state.start_auto_battle(1))
	var initial_wood := state.get_resource_amount(&"wood")
	var initial_stone := state.get_resource_amount(&"spirit_stone")
	var initial_food := state.get_resource_amount(&"food")
	var consumed_total := 0
	for second: int in range(SIMULATED_SECONDS):
		consumed_total += state.process_disciple_consumption(1.0)
		state.process_battle(1.0)
		if (second + 1) % 3600 == 0:
			var snapshot: Dictionary = state.export_save_data()
			assert(state.import_save_data(snapshot))
			assert(state.export_save_data() == snapshot)
	assert(state.battle_victories > 0)
	assert(state.get_resource_amount(&"wood") == initial_wood + state.battle_victories * 20)
	assert(state.get_resource_amount(&"spirit_stone") == initial_stone)
	assert(state.get_resource_amount(&"food") == initial_food + state.battle_victories * 10 - consumed_total)
	assert(state.battle_log.size() <= state.BATTLE_LOG_LIMIT)
	for resource_id: StringName in state.RESOURCE_IDS:
		assert(state.get_resource_amount(resource_id) >= 0)

	var failure_state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(failure_state)
	failure_state.get_idle_disciples()
	assert(failure_state.set_disciple_job(int(failure_state.disciples[0]["id"]), &"combat"))
	failure_state.highest_unlocked_stage = 5
	assert(failure_state.start_auto_battle(5))
	var failure_wood := failure_state.get_resource_amount(&"wood")
	failure_state.process_battle(120.0)
	assert(not failure_state.battle_running)
	assert(not failure_state.auto_battle_enabled)
	assert(failure_state.get_resource_amount(&"wood") == failure_wood)
	assert(failure_state.last_battle_result.get("result", "") == "失败")

	var elapsed_ms := Time.get_ticks_msec() - started_ms
	var memory_after := OS.get_static_memory_usage()
	print("EVIDENCE: simulated_hours=8 wall_ms=%d victories=%d consumed_food=%d log_entries=%d memory_before=%d memory_after=%d memory_delta=%d" % [elapsed_ms, state.battle_victories, consumed_total, state.battle_log.size(), memory_before, memory_after, memory_after - memory_before])
	print("PASS: 8-hour simulated battle, consumption, reward conservation, failure, and hourly save round trips")
	quit()
