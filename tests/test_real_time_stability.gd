extends SceneTree

const DURATION_SECONDS := 30 * 60

func _init() -> void:
	_run()


func _run() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	for disciple: Dictionary in state.disciples:
		assert(state.set_disciple_job(int(disciple["id"]), &"combat"))
	assert(state.start_auto_battle(1))
	var started_ms := Time.get_ticks_msec()
	var memory_before := OS.get_static_memory_usage()
	var last_ms := started_ms
	for second: int in range(DURATION_SECONDS):
		await create_timer(1.0).timeout
		var now_ms := Time.get_ticks_msec()
		var delta := float(now_ms - last_ms) / 1000.0
		last_ms = now_ms
		state.process_disciple_consumption(delta)
		state.process_battle(delta)
		assert(state.battle_log.size() <= state.BATTLE_LOG_LIMIT)
		assert(state.is_battle_party_consistent())
		if (second + 1) % 60 == 0:
			print("HEARTBEAT: real_minutes=%d victories=%d log_entries=%d memory=%d" % [(second + 1) / 60, state.battle_victories, state.battle_log.size(), OS.get_static_memory_usage()])
	var elapsed_ms := Time.get_ticks_msec() - started_ms
	var memory_after := OS.get_static_memory_usage()
	assert(elapsed_ms >= DURATION_SECONDS * 1000)
	assert(state.battle_victories > 0)
	print("EVIDENCE: real_elapsed_ms=%d victories=%d memory_before=%d memory_after=%d memory_delta=%d" % [elapsed_ms, state.battle_victories, memory_before, memory_after, memory_after - memory_before])
	print("PASS: 30-minute real-time integration stability")
	quit()
