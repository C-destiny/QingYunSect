extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_savegame.json"


func _init() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var cleanup_path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(cleanup_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(cleanup_path))
	var state := preload("res://scripts/core/game_state.gd").new()
	var manager := preload("res://scripts/core/save_manager.gd").new()
	root.add_child(state)
	root.add_child(manager)
	manager.game_state = state
	manager.save_path = TEST_SAVE_PATH
	state.resources["wood"] = 321
	assert(state.assign_disciple(&"forest"))
	assert(state.assign_disciple(&"mine"))
	state.production_progress["forest"] = 0.75
	assert(manager.save_game())
	state.resources["wood"] = 1
	state.assignments.clear()
	state.assigned_disciples = 0
	state.production_progress.clear()
	assert(manager.load_game())
	assert(state.get_resource_amount(&"wood") == 321)
	assert(state.get_assignment(&"forest") == 1)
	assert(state.get_assignment(&"mine") == 1)
	assert(state.assigned_disciples == 2)
	assert(is_equal_approx(float(state.production_progress["forest"]), 0.75))
	for suffix: String in ["", ".bak", ".tmp"]:
		var cleanup_path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(cleanup_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(cleanup_path))
	print("PASS: local save and load")
	quit()

