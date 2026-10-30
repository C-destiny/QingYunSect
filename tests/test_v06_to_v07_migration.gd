extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_v07_migration.json"


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


func _init() -> void:
	_cleanup()
	var state := preload("res://scripts/core/game_state.gd").new()
	var manager := preload("res://scripts/core/save_manager.gd").new()
	root.add_child(state)
	root.add_child(manager)
	manager.game_state = state
	manager.save_path = TEST_SAVE_PATH
	manager.unix_time_provider = func() -> int: return 5000
	state.get_idle_disciples()
	var disciple_id := int(state.disciples[0]["id"])
	var weapon_id := state.create_equipment_instance(&"initiate_weapon", &"rare")
	assert(state.equip_item(disciple_id, weapon_id))
	assert(state.start_construction(&"lumber_yard", Vector2i(0, 0)))
	var v06_state := state.export_save_data()
	v06_state.erase("unlocked_regions")
	v06_state.erase("equipment_crafts_completed")
	_write_payload({"version": 2, "saved_at_unix": 5000, "game_state": v06_state})
	assert(manager.load_game())
	assert(state.unlocked_regions == ["core"])
	assert(state.equipment_crafts_completed == 0)
	assert(int(state.get_disciple(disciple_id)["equipment"]["weapon"]) == weapon_id)
	assert(state.buildings[0]["cell_x"] == 0 and state.buildings[0]["cell_y"] == 0)
	assert(manager.save_game())
	var migrated := _read_payload()
	assert(int(migrated["version"]) == manager.SAVE_VERSION)
	assert(migrated["game_state"]["unlocked_regions"] == ["core"])
	assert(int(migrated["game_state"]["equipment_crafts_completed"]) == 0)
	assert(migrated["game_state"]["claimed_development_goals"] == [])
	var early_v07 := migrated.duplicate(true)
	early_v07["game_state"].erase("claimed_development_goals")
	_write_payload(early_v07)
	assert(manager.load_game())
	assert(state.claimed_development_goals.is_empty())

	var missing_regions := migrated.duplicate(true)
	missing_regions["game_state"].erase("unlocked_regions")
	_write_payload(missing_regions)
	if FileAccess.file_exists(manager.get_backup_path()):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.get_backup_path()))
	var before_missing := state.export_save_data()
	assert(not manager.load_game())
	assert(state.export_save_data() == before_missing)

	var valid_expanded := before_missing.duplicate(true)
	valid_expanded["unlocked_regions"] = ["core", "east"]
	valid_expanded["equipment_crafts_completed"] = 7
	valid_expanded["buildings"].append({
		"instance_id": int(valid_expanded["next_building_id"]),
		"type": "disciple_quarters", "cell_x": 8, "cell_y": 0,
		"remaining": 0.0, "build_time": 6.0, "completed": true,
		"level": 1, "upgrading": false,
	})
	valid_expanded["next_building_id"] = int(valid_expanded["next_building_id"]) + 1
	assert(state.import_save_data(valid_expanded))
	assert(state.is_cell_unlocked(Vector2i(8, 0)))
	assert(state.equipment_crafts_completed == 7)
	var stable := state.export_save_data()

	var invalid_cases: Array[Dictionary] = []
	var unknown := stable.duplicate(true)
	unknown["unlocked_regions"] = ["core", "unknown"]
	invalid_cases.append(unknown)
	var duplicate := stable.duplicate(true)
	duplicate["unlocked_regions"] = ["core", "east", "east"]
	invalid_cases.append(duplicate)
	var missing_dependency := stable.duplicate(true)
	missing_dependency["unlocked_regions"] = ["core", "south"]
	invalid_cases.append(missing_dependency)
	var locked_building := stable.duplicate(true)
	locked_building["unlocked_regions"] = ["core"]
	invalid_cases.append(locked_building)
	var out_of_bounds := stable.duplicate(true)
	out_of_bounds["buildings"][-1]["cell_x"] = 12
	invalid_cases.append(out_of_bounds)
	var negative_crafts := stable.duplicate(true)
	negative_crafts["equipment_crafts_completed"] = -1
	invalid_cases.append(negative_crafts)
	for invalid: Dictionary in invalid_cases:
		assert(not state.import_save_data(invalid))
		assert(state.export_save_data() == stable)

	manager.unix_time_provider = Callable()
	_cleanup()
	print("PASS: V0.6 version 2 migrates to strict V0.7 territory and crafting contract")
	quit()
