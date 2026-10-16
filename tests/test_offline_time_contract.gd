extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_offline_time.json"

func _init() -> void:
	_cleanup()
	var state := preload("res://scripts/core/game_state.gd").new()
	var manager := preload("res://scripts/core/save_manager.gd").new()
	root.add_child(state)
	root.add_child(manager)
	manager.game_state = state
	manager.save_path = TEST_SAVE_PATH

	assert(manager.calculate_offline_window(100, 100)["reason"] == "too_short")
	assert(manager.calculate_offline_window(100, 99)["reason"] == "clock_moved_back")
	assert(manager.calculate_offline_window(0, 100)["reason"] == "missing_anchor")
	var normal: Dictionary = manager.calculate_offline_window(100, 3700)
	assert(normal["eligible"] and normal["effective_seconds"] == 3600)
	assert(not normal["truncated"] and normal["reason"] == "eligible")
	var capped: Dictionary = manager.calculate_offline_window(100, 100 + 12 * 60 * 60)
	assert(capped["raw_seconds"] == 12 * 60 * 60)
	assert(capped["effective_seconds"] == manager.MAX_OFFLINE_SECONDS)
	assert(capped["truncated"] and capped["reason"] == "capped")

	manager.unix_time_provider = func() -> int: return 1000
	assert(manager.save_game())
	manager.unix_time_provider = func() -> int: return 4600
	assert(manager.load_game())
	var loaded_window := manager.get_pending_offline_window()
	assert(loaded_window["effective_seconds"] == 3600)
	assert(loaded_window["settlement_id"] == "1000:4600")
	manager.clear_pending_offline_window()
	assert(manager.get_pending_offline_window().is_empty())

	var legacy_payload := {
		"version": manager.SAVE_VERSION,
		"game_state": state.export_save_data(),
	}
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(legacy_payload))
	file.close()
	assert(manager.load_game())
	assert(manager.get_pending_offline_window()["reason"] == "missing_anchor")

	_cleanup()
	print("PASS: offline time cap, clock anomaly, save anchor, and legacy migration contract")
	quit()


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
