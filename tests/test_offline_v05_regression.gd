extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_offline_v05_regression.json"
const EIGHT_HOURS := 8 * 60 * 60


func _init() -> void:
	_cleanup()
	var manager := preload("res://scripts/core/save_manager.gd").new()
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	root.add_child(manager)
	manager.game_state = state
	manager.save_path = TEST_SAVE_PATH

	var zero := manager.calculate_offline_window(1000, 1000)
	var one := manager.calculate_offline_window(1000, 1001)
	var exact_cap := manager.calculate_offline_window(1000, 1000 + EIGHT_HOURS)
	var over_cap := manager.calculate_offline_window(1000, 1000 + EIGHT_HOURS * 2)
	assert(zero["reason"] == "too_short" and not zero["eligible"])
	assert(one["eligible"] and one["effective_seconds"] == 1)
	assert(exact_cap["effective_seconds"] == EIGHT_HOURS and not exact_cap["truncated"])
	assert(over_cap["effective_seconds"] == EIGHT_HOURS and over_cap["truncated"])

	state.get_idle_disciples()
	assert(state.set_disciple_job(int(state.disciples[0]["id"]), &"forest"))
	assert(state.set_disciple_job(int(state.disciples[1]["id"]), &"field"))
	state.resources = {"wood": 0, "spirit_stone": 0, "food": 50}
	var start_usec := Time.get_ticks_usec()
	var receipt := state.apply_offline_progress(exact_cap)
	var elapsed_msec := float(Time.get_ticks_usec() - start_usec) / 1000.0
	assert(elapsed_msec < 1000.0)
	assert(receipt["effective_seconds"] == EIGHT_HOURS)
	assert(state.get_resource_amount(&"wood") > 0)
	assert(state.get_resource_amount(&"food") >= 0)

	manager.unix_time_provider = func() -> int: return 50000
	assert(manager.save_game())
	var saved_state := state.export_save_data()
	state.resources["wood"] = 0
	manager.unix_time_provider = func() -> int: return 50000
	assert(manager.load_game())
	assert(state.get_resource_amount(&"wood") == int(saved_state["resources"]["wood"]))
	assert(manager.get_pending_offline_window()["reason"] == "too_short")

	manager.unix_time_provider = Callable()
	_cleanup()
	print("PASS: V0.5 boundaries, 8-hour analytical performance, and save round-trip")
	quit()


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
