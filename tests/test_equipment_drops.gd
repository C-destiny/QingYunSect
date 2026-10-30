extends SceneTree

const BattleCatalogData = preload("res://scripts/data/battle_catalog.gd")


func _new_state() -> Node:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	return state


func _prepare_party(state: Node) -> void:
	for disciple: Dictionary in state.disciples:
		assert(state.set_disciple_job(int(disciple["id"]), &"combat"))


func _init() -> void:
	var online := _new_state()
	_prepare_party(online)
	online.battle_victories = 99
	assert(online.start_auto_battle(1))
	var encounter_id: int = online.active_battle_encounter_id
	assert(online._complete_battle_victory(BattleCatalogData.get_stage(1), encounter_id))
	assert(online.battle_victories == 100)
	assert(online.equipment_inventory.size() == 1)
	var first_drop: Dictionary = online.equipment_inventory[0]
	assert(first_drop["template_id"] == "initiate_weapon")
	assert(first_drop["quality"] == "common")
	assert(online.last_battle_result["equipment_drops"].size() == 1)
	assert(not online._complete_battle_victory(BattleCatalogData.get_stage(1), encounter_id))
	assert(online.equipment_inventory.size() == 1)

	var offline := _new_state()
	_prepare_party(offline)
	assert(offline.start_auto_battle(1))
	offline.battle_victories = 99
	var receipt: Dictionary = offline.apply_offline_progress({"eligible": true, "effective_seconds": 600, "settlement_id": "drops"})
	var expected_drop_count: int = floori(float(offline.battle_victories) / float(offline.EQUIPMENT_DROP_INTERVAL))
	assert(receipt["equipment_drops"].size() == expected_drop_count)
	assert(offline.equipment_inventory.size() == expected_drop_count)
	for index: int in range(offline.equipment_inventory.size()):
		var expected: Dictionary = offline._get_equipment_drop_definition(index + 1)
		var actual: Dictionary = offline.equipment_inventory[index]
		assert(StringName(actual["template_id"]) == expected["template_id"])
		assert(StringName(actual["quality"]) == expected["quality"])

	var full := _new_state()
	while full.equipment_inventory.size() < full.MAX_EQUIPMENT_INVENTORY:
		assert(full.create_equipment_instance(&"spirit_ring", &"common") > 0)
	full.battle_victories = 99
	_prepare_party(full)
	assert(full.start_auto_battle(1))
	assert(full._complete_battle_victory(BattleCatalogData.get_stage(1), full.active_battle_encounter_id))
	assert(full.battle_victories == 100)
	assert(full.equipment_inventory.size() == full.MAX_EQUIPMENT_INVENTORY)
	assert(full.last_battle_result["equipment_drops"].is_empty())
	print("PASS: deterministic online and offline drops share milestones and respect inventory capacity")
	quit()
