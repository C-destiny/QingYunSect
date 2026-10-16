extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_offline_atomic.json"

func _init() -> void:
	_cleanup()
	var state := preload("res://scripts/core/game_state.gd").new()
	var manager := preload("res://scripts/core/save_manager.gd").new()
	root.add_child(state)
	root.add_child(manager)
	manager.game_state = state
	manager.save_path = TEST_SAVE_PATH
	manager.unix_time_provider = func() -> int: return 2000
	state.get_idle_disciples()
	assert(state.set_disciple_job(int(state.disciples[0]["id"]), &"forest"))
	state.resources["wood"] = 0
	manager.pending_offline_window = manager.calculate_offline_window(1940, 2000)
	var settled: Dictionary = manager.settle_pending_offline_progress()
	assert(settled["success"] and settled["applied"])
	assert(state.get_resource_amount(&"wood") == 12)
	assert(manager.get_pending_offline_window().is_empty())
	var second: Dictionary = manager.settle_pending_offline_progress()
	assert(not second["success"])
	assert(state.get_resource_amount(&"wood") == 12)

	var rollback_before: Dictionary = state.export_save_data()
	manager.pending_offline_window = manager.calculate_offline_window(2000, 2060)
	manager.save_path = "res://tests/missing-directory/offline.json"
	var failed: Dictionary = manager.settle_pending_offline_progress()
	assert(not failed["success"] and not failed["applied"])
	assert(state.export_save_data() == rollback_before)
	assert(not manager.get_pending_offline_window().is_empty())
	_cleanup()
	print("PASS: offline settlement saves once, prevents repeats, and rolls back on save failure")
	quit()


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
