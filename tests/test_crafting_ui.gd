extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_crafting_ui.json"


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
	state.resources = {"wood": 5000, "spirit_stone": 5000, "food": 5000}
	state.buildings.append({
		"instance_id": state.next_building_id, "type": "artifact_forge", "cell_x": 0, "cell_y": 0,
		"remaining": 0.0, "build_time": 12.0, "completed": true, "level": 3, "upgrading": false,
	})
	state.next_building_id += 1
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame

	var template_selector: OptionButton = main.get_node("%CraftTemplateSelector")
	var quality_selector: OptionButton = main.get_node("%CraftQualitySelector")
	var craft_button: Button = main.get_node("%CraftButton")
	var status: Label = main.get_node("%CraftingStatus")
	assert(template_selector.item_count == 3 and quality_selector.item_count == 3)
	assert("炼器等级 3/3" in status.text)
	assert(not craft_button.disabled)
	var before: Dictionary = state.resources.duplicate(true)
	main._craft_selected_equipment()
	assert(state.equipment_inventory.size() == 1)
	assert(state.equipment_crafts_completed == 1)
	assert(state.get_resource_amount(&"wood") == int(before["wood"]) - 80)
	assert(manager.has_save())

	quality_selector.select(1)
	main._on_crafting_selection_changed(1)
	var rollback: Dictionary = state.export_save_data()
	manager.save_path = "res://tests/missing-directory/crafting.json"
	main._craft_selected_equipment()
	assert(state.export_save_data() == rollback)
	assert("已恢复" in status.text)
	main.queue_free()
	_cleanup()
	print("PASS: crafting UI fixed recipes, successful save, and save-failure rollback")
	quit()
