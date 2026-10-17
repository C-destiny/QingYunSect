extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_v06_save_recovery.json"


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


func _init() -> void:
	_cleanup()
	var state := preload("res://scripts/core/game_state.gd").new()
	var manager := preload("res://scripts/core/save_manager.gd").new()
	root.add_child(state)
	root.add_child(manager)
	manager.game_state = state
	manager.save_path = TEST_SAVE_PATH
	manager.unix_time_provider = func() -> int: return 4000
	state.get_idle_disciples()
	var disciple_id := int(state.disciples[0]["id"])
	var weapon_id := state.create_equipment_instance(&"initiate_weapon", &"rare")
	assert(state.equip_item(disciple_id, weapon_id))
	assert(manager.save_game())
	state.resources["wood"] += 1
	assert(manager.save_game())
	assert(FileAccess.file_exists(manager.get_backup_path()))

	_write_text(TEST_SAVE_PATH, "{broken v06 save")
	assert(state.unequip_item(disciple_id, &"weapon"))
	state.equipment_inventory.clear()
	assert(manager.load_game())
	assert(state.equipment_inventory.size() == 1)
	assert(int(state.get_disciple(disciple_id)["equipment"]["weapon"]) == weapon_id)
	assert(state.get_equipment_instance(weapon_id)["quality"] == "rare")
	assert(state.get_disciple_battle_stats(disciple_id)["equipment_bonus"]["attack"] == 6.0)
	manager.unix_time_provider = Callable()
	_cleanup()
	print("PASS: V0.6 equipped inventory survives atomic save backup recovery")
	quit()
