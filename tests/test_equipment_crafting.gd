extends SceneTree


func _complete_building(state: Node, building_type: StringName, cell: Vector2i) -> void:
	assert(state.start_construction(building_type, cell))
	state.process_construction(100.0)


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.resources = {"wood": 5000, "spirit_stone": 5000, "food": 5000}
	var resources_before := state.resources.duplicate(true)
	assert(state.craft_equipment(&"initiate_weapon", &"common") == 0)
	assert(state.resources == resources_before and state.equipment_inventory.is_empty())

	_complete_building(state, &"artifact_forge", Vector2i(0, 0))
	resources_before = state.resources.duplicate(true)
	var common_id := state.craft_equipment(&"initiate_weapon", &"common")
	assert(common_id > 0)
	assert(state.get_resource_amount(&"wood") == int(resources_before["wood"]) - 80)
	assert(state.get_resource_amount(&"spirit_stone") == int(resources_before["spirit_stone"]) - 60)
	assert(state.get_resource_amount(&"food") == int(resources_before["food"]) - 20)
	assert(state.equipment_crafts_completed == 1)

	resources_before = state.resources.duplicate(true)
	assert(state.craft_equipment(&"cloud_robe", &"rare") == 0)
	assert(state.resources == resources_before and state.equipment_inventory.size() == 1)
	assert(state.craft_equipment(&"missing", &"common") == 0)
	assert(state.craft_equipment(&"cloud_robe", &"mythic") == 0)

	var forge_id := int(state.buildings[0]["instance_id"])
	assert(state.start_building_upgrade(forge_id))
	state.process_construction(25.0)
	var rare_id := state.craft_equipment(&"cloud_robe", &"rare")
	assert(rare_id > 0 and state.get_equipment_instance(rare_id)["quality"] == "rare")
	assert(state.start_building_upgrade(forge_id))
	state.process_construction(40.0)
	var epic_id := state.craft_equipment(&"spirit_ring", &"epic")
	assert(epic_id > 0 and state.equipment_crafts_completed == 3)

	var saved := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(saved))
	assert(restored.equipment_crafts_completed == 3)
	assert(restored.equipment_inventory.size() == 3)
	assert(restored.EQUIPMENT_DROP_INTERVAL == 5)

	while restored.equipment_inventory.size() < restored.MAX_EQUIPMENT_INVENTORY:
		assert(restored.create_equipment_instance(&"spirit_ring", &"common") > 0)
	resources_before = restored.resources.duplicate(true)
	assert(restored.craft_equipment(&"spirit_ring", &"common") == 0)
	assert(restored.resources == resources_before)
	assert(restored.equipment_crafts_completed == 3)
	print("PASS: deterministic equipment crafting tiers, costs, capacity, persistence, and failure atomicity")
	quit()
