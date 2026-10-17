extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_equipment_drop_atomic.json"


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _init() -> void:
	_cleanup()
	var state := preload("res://scripts/core/game_state.gd").new()
	var manager := preload("res://scripts/core/save_manager.gd").new()
	root.add_child(state)
	root.add_child(manager)
	manager.game_state = state
	manager.unix_time_provider = func() -> int: return 3000
	state.get_idle_disciples()
	for disciple: Dictionary in state.disciples:
		assert(state.set_disciple_job(int(disciple["id"]), &"combat"))
	state.battle_victories = 4
	assert(state.start_auto_battle(1))
	var before: Dictionary = state.export_save_data()
	manager.save_path = "res://tests/missing-directory/drop.json"
	manager.pending_offline_window = manager.calculate_offline_window(2940, 3000)
	var failed: Dictionary = manager.settle_pending_offline_progress()
	assert(not failed["success"] and not failed["applied"])
	assert(state.export_save_data() == before)
	assert(not manager.get_pending_offline_window().is_empty())

	manager.save_path = TEST_SAVE_PATH
	var settled: Dictionary = manager.settle_pending_offline_progress()
	assert(settled["success"] and settled["applied"])
	assert(settled["equipment_drops"].size() > 0)
	assert(state.equipment_inventory.size() == settled["equipment_drops"].size())
	var equipment_after := state.equipment_inventory.duplicate(true)
	var second: Dictionary = manager.settle_pending_offline_progress()
	assert(not second["success"])
	assert(state.equipment_inventory == equipment_after)
	_cleanup()
	print("PASS: offline equipment drops roll back on save failure and cannot settle twice")
	quit()
