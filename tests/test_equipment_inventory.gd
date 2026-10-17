extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	var common_weapon := state.create_equipment_instance(&"initiate_weapon", &"common")
	var rare_armor := state.create_equipment_instance(&"cloud_robe", &"rare")
	var epic_ring := state.create_equipment_instance(&"spirit_ring", &"epic")
	assert(common_weapon == 1 and rare_armor == 2 and epic_ring == 3)
	assert(state.next_equipment_instance_id == 4)
	assert(float(state.get_equipment_instance(common_weapon)["stats"]["attack"]) == 4.0)
	assert(float(state.get_equipment_instance(rare_armor)["stats"]["hp"]) == 30.0)
	assert(float(state.get_equipment_instance(epic_ring)["stats"]["attack"]) == 4.5)
	assert(state.create_equipment_instance(&"missing", &"common") == 0)
	assert(state.create_equipment_instance(&"initiate_weapon", &"mythic") == 0)
	assert(state.next_equipment_instance_id == 4)
	while state.equipment_inventory.size() < state.MAX_EQUIPMENT_INVENTORY:
		assert(state.create_equipment_instance(&"spirit_ring", &"common") > 0)
	var next_when_full := state.next_equipment_instance_id
	assert(state.create_equipment_instance(&"spirit_ring", &"common") == 0)
	assert(state.next_equipment_instance_id == next_when_full)

	var round_trip := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(round_trip))
	assert(restored.equipment_inventory == state.equipment_inventory)
	var tampered := round_trip.duplicate(true)
	tampered["equipment_inventory"][0]["stats"]["attack"] = 999.0
	var unchanged := restored.export_save_data()
	assert(not restored.import_save_data(tampered))
	assert(restored.export_save_data() == unchanged)
	var oversized := round_trip.duplicate(true)
	var extra := preload("res://scripts/data/equipment_catalog.gd").build_instance(
		int(oversized["next_equipment_instance_id"]), &"spirit_ring", &"common"
	)
	oversized["equipment_inventory"].append(extra)
	assert(not restored.import_save_data(oversized))
	assert(restored.export_save_data() == unchanged)
	print("PASS: equipment catalog creates unique canonical three-slot quality instances")
	quit()
