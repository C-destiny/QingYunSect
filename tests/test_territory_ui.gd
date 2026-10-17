extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_territory_ui.json"


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	var state := root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = TEST_SAVE_PATH
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	var map: Control = main.get_node("%SectMap")
	var status: Label = main.get_node("%TerritoryStatus")
	var button: Button = main.get_node("%TerritoryUnlockButton")
	assert(map.GRID_SIZE == Vector2i(12, 8))
	assert("48/96格" in status.text)
	assert(not map.is_placement_valid(Vector2i(8, 0)))
	assert(button.disabled)

	state.sect_level = 3
	state.resources = {"wood": 1000, "spirit_stone": 1000, "food": 1000}
	main._refresh_territory()
	assert(not button.disabled)
	main._unlock_next_region()
	assert(state.unlocked_regions == ["core", "east"])
	assert(map.is_placement_valid(Vector2i(8, 0)))
	assert("72/96格" in status.text)
	assert(manager.has_save())

	state.sect_level = 5
	state.resources = {"wood": 1000, "spirit_stone": 1000, "food": 1000}
	var rollback: Dictionary = state.export_save_data()
	manager.save_path = "res://tests/missing-directory/territory.json"
	main._unlock_next_region()
	assert(state.export_save_data() == rollback)
	assert("保存失败" in status.text)
	assert(not map.is_placement_valid(Vector2i(0, 6)))

	main.queue_free()
	_cleanup()
	print("PASS: territory UI shows 12x8 locks, unlock progress, and save-failure rollback")
	quit()
