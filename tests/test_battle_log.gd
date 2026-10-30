extends SceneTree

func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	assert(state.set_disciple_job(int(state.disciples[0]["id"]), &"combat"))
	assert(state.start_auto_battle(1))
	state.process_battle(1.0)
	assert(state.battle_round_number == 1)
	assert("第1回合" in state.battle_log[-1] or "第1回合" in state.battle_log[-2])
	assert(state.process_battle(100.0))
	assert(state.last_battle_result["result"] == "胜利")
	assert("木材1" in state.last_battle_result["reward_text"])
	var wins: int = state.battle_victories
	var saved: Dictionary = state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(saved))
	assert(restored.battle_victories == wins)
	assert(restored.last_battle_result == state.last_battle_result)
	assert(restored.battle_log == state.battle_log)
	for index: int in range(50):
		restored._append_battle_log("事件%d" % index)
	assert(restored.battle_log.size() == restored.BATTLE_LOG_LIMIT)
	print("PASS: structured battle log, result persistence, and bounded capacity")
	quit()
