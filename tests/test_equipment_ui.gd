extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_equipment_ui.json"


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

	var detail: Label = main.get_node("%DiscipleDetail")
	var stats: Label = main.get_node("%EquipmentStats")
	var slot_selector: OptionButton = main.get_node("%EquipmentSlotSelector")
	var inventory_selector: OptionButton = main.get_node("%EquipmentInventorySelector")
	var equip_button: Button = main.get_node("%EquipButton")
	var unequip_button: Button = main.get_node("%UnequipButton")
	var scroll: ScrollContainer = main.get_node("Layout/Body/Sidebar/Margin/Scroll")
	assert("剑修" in detail.text)
	assert("境界基础" in stats.text and "职业修正后" in stats.text and "最终属性" in stats.text)
	assert(slot_selector.item_count == 3)
	assert(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)

	var disciple_id: int = main.selected_disciple_id
	var weapon_id: int = state.create_equipment_instance(&"initiate_weapon", &"rare")
	var armor_id: int = state.create_equipment_instance(&"cloud_robe", &"common")
	assert(weapon_id > 0 and armor_id > 0)
	await process_frame
	assert(inventory_selector.item_count == 1)
	assert(int(inventory_selector.get_item_metadata(0)) == weapon_id)
	assert(not equip_button.disabled)
	main._equip_selected_item()
	assert(int(state.get_disciple(disciple_id)["equipment"]["weapon"]) == weapon_id)
	assert("稀有·入门法器" in stats.text)
	assert("装备加成" in stats.text)
	assert(manager.has_save())
	assert(not unequip_button.disabled)
	main._unequip_selected_item()
	assert(int(state.get_disciple(disciple_id)["equipment"]["weapon"]) == 0)

	slot_selector.select(1)
	main._on_equipment_slot_selected(1)
	assert(int(inventory_selector.get_item_metadata(0)) == armor_id)
	assert(stats.autowrap_mode != TextServer.AUTOWRAP_OFF)
	main.queue_free()
	_cleanup()
	print("PASS: equipment UI shows profession/stat layers and saves three-slot equip operations")
	quit()
