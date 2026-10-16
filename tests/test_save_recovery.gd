extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_save_recovery.json"

var last_load_success: bool = false
var last_load_message: String = ""


func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(content)
	file.close()


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _on_load_completed(success: bool, message: String) -> void:
	last_load_success = success
	last_load_message = message


func _init() -> void:
	_cleanup()
	var state := preload("res://scripts/core/game_state.gd").new()
	var manager := preload("res://scripts/core/save_manager.gd").new()
	root.add_child(state)
	root.add_child(manager)
	manager.game_state = state
	manager.save_path = TEST_SAVE_PATH
	manager.load_completed.connect(_on_load_completed)

	state.resources["wood"] = 100
	assert(manager.save_game())
	assert(not FileAccess.file_exists(manager.get_temp_path()))
	state.resources["wood"] = 200
	assert(manager.save_game())
	assert(FileAccess.file_exists(manager.get_backup_path()))
	assert(not FileAccess.file_exists(manager.get_temp_path()))

	_write_text(TEST_SAVE_PATH, "{broken json")
	state.resources["wood"] = 999
	assert(manager.load_game())
	assert(last_load_success)
	assert("备份" in last_load_message)
	assert(state.get_resource_amount(&"wood") == 100)
	assert(manager.load_game())
	assert(state.get_resource_amount(&"wood") == 100)

	_write_text(manager.get_backup_path(), "also broken")
	state.resources["wood"] = 777
	var before_broken_load: Dictionary = state.export_save_data()
	assert(not manager.load_game())
	assert(not last_load_success)
	assert(state.export_save_data() == before_broken_load)

	var invalid_payload := {
		"version": manager.SAVE_VERSION,
		"saved_at_unix": 0,
		"game_state": state.export_save_data(),
	}
	invalid_payload["game_state"]["resources"]["wood"] = 8888
	invalid_payload["game_state"]["disciples"][0]["id"] = -1
	_write_text(TEST_SAVE_PATH, JSON.stringify(invalid_payload))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.get_backup_path()))
	var before_invalid_load: Dictionary = state.export_save_data()
	assert(not manager.load_game())
	assert(state.export_save_data() == before_invalid_load)

	var direct_invalid: Dictionary = state.export_save_data()
	direct_invalid["resources"]["wood"] = 4321
	direct_invalid["disciples"][0]["id"] = -2
	var before_direct_import: Dictionary = state.export_save_data()
	assert(not state.import_save_data(direct_invalid))
	assert(state.export_save_data() == before_direct_import)

	_cleanup()
	print("PASS: atomic save replacement, backup recovery, and transactional load rollback")
	quit()
