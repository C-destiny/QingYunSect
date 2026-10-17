extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_v05_migration.json"


func _init() -> void:
	_cleanup()
	var state := preload("res://scripts/core/game_state.gd").new()
	var manager := preload("res://scripts/core/save_manager.gd").new()
	root.add_child(state)
	root.add_child(manager)
	manager.game_state = state
	manager.save_path = TEST_SAVE_PATH
	state.get_idle_disciples()

	var v05_state := state.export_save_data()
	v05_state.erase("equipment_inventory")
	v05_state.erase("next_equipment_instance_id")
	for disciple: Dictionary in v05_state["disciples"]:
		disciple.erase("profession")
		disciple.erase("equipment")
	_write_payload({"version": 1, "saved_at_unix": 1000, "game_state": v05_state})
	manager.unix_time_provider = func() -> int: return 1000
	assert(manager.load_game())
	assert(state.disciples[0]["profession"] == "sword")
	assert(state.disciples[1]["profession"] == "mage")
	assert(state.disciples[0]["equipment"] == {"weapon": 0, "armor": 0, "ring": 0})
	assert(state.equipment_inventory.is_empty())
	assert(state.next_equipment_instance_id == 1)
	assert(manager.save_game())
	var saved := _read_payload()
	assert(int(saved["version"]) == manager.SAVE_VERSION)
	assert(saved["game_state"]["disciples"][1]["profession"] == "mage")
	var missing_v2_schema := saved.duplicate(true)
	missing_v2_schema["game_state"].erase("equipment_inventory")
	_write_payload(missing_v2_schema)
	if FileAccess.file_exists(manager.get_backup_path()):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.get_backup_path()))
	var before_missing_schema := state.export_save_data()
	assert(not manager.load_game())
	assert(state.export_save_data() == before_missing_schema)

	var valid_equipment := {
		"id": 1,
		"template_id": "migration_test_sword",
		"slot": "weapon",
		"quality": "common",
		"stats": {"attack": 1.0},
	}
	var valid_state := state.export_save_data()
	valid_state["equipment_inventory"] = [valid_equipment]
	valid_state["next_equipment_instance_id"] = 2
	valid_state["disciples"][0]["equipment"]["weapon"] = 1
	assert(state.import_save_data(valid_state))
	var stable := state.export_save_data()

	var bad_profession := stable.duplicate(true)
	bad_profession["disciples"][0]["profession"] = "invalid"
	assert(not state.import_save_data(bad_profession))
	assert(state.export_save_data() == stable)

	var duplicate_id := stable.duplicate(true)
	duplicate_id["equipment_inventory"].append(valid_equipment.duplicate(true))
	assert(not state.import_save_data(duplicate_id))
	assert(state.export_save_data() == stable)

	var wrong_slot := stable.duplicate(true)
	wrong_slot["disciples"][0]["equipment"]["armor"] = 1
	wrong_slot["disciples"][0]["equipment"]["weapon"] = 0
	assert(not state.import_save_data(wrong_slot))
	assert(state.export_save_data() == stable)

	var multi_wear := stable.duplicate(true)
	multi_wear["disciples"][1]["equipment"]["weapon"] = 1
	assert(not state.import_save_data(multi_wear))
	assert(state.export_save_data() == stable)

	manager.unix_time_provider = Callable()
	_cleanup()
	print("PASS: V0.5 saves migrate to V0.6 professions and strict equipment references")
	quit()


func _write_payload(payload: Dictionary) -> void:
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(payload))
	file.close()


func _read_payload() -> Dictionary:
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	assert(file != null)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert(parsed is Dictionary)
	return parsed


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
