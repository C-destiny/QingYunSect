extends SceneTree

const BattleCatalogData = preload("res://scripts/data/battle_catalog.gd")
const TEST_SAVE_PATH := "res://tests/.test_battle_reward_settlement.json"
const INVALID_SAVE_PATH := "res://tests/.missing_reward_save_dir/save.json"

var last_save_success: bool = true
var last_save_message: String = ""


func _new_state() -> Node:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	return state


func _new_manager(state: Node, path: String) -> Node:
	var manager := preload("res://scripts/core/save_manager.gd").new()
	root.add_child(manager)
	manager.game_state = state
	manager.save_path = path
	manager.save_completed.connect(_on_save_completed)
	return manager


func _on_save_completed(success: bool, message: String) -> void:
	last_save_success = success
	last_save_message = message


func _init() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	var state := _new_state()
	var manager := _new_manager(state, TEST_SAVE_PATH)
	var disciple_id := int(state.disciples[0]["id"])
	assert(state.set_disciple_job(disciple_id, &"combat"))
	assert(state.start_auto_battle(1))
	var encounter_id: int = state.active_battle_encounter_id
	assert(encounter_id > 0)
	assert(manager.save_game())

	var wood_before: int = state.get_resource_amount(&"wood")
	var food_before: int = state.get_resource_amount(&"food")
	assert(state.process_battle(20.0))
	assert(state.last_settled_battle_encounter_id == encounter_id)
	assert(state.get_resource_amount(&"wood") == wood_before + 20)
	assert(state.get_resource_amount(&"food") == food_before + 10)
	assert(state.battle_victories == 1)
	assert(not state._complete_battle_victory(BattleCatalogData.get_stage(1), encounter_id))
	assert(state.get_resource_amount(&"wood") == wood_before + 20)
	assert(state.battle_victories == 1)

	manager.save_path = INVALID_SAVE_PATH
	last_save_success = true
	last_save_message = ""
	assert(not manager.save_game())
	assert(not last_save_success)
	assert(last_save_message != "已保存")

	var replayed := _new_state()
	var replay_manager := _new_manager(replayed, TEST_SAVE_PATH)
	assert(replay_manager.load_game())
	assert(replayed.active_battle_encounter_id == encounter_id)
	assert(replayed.process_battle(20.0))
	assert(replayed.battle_victories == 1)
	assert(replayed.get_resource_amount(&"wood") == wood_before + 20)
	assert(replay_manager.save_game())

	var settled := _new_state()
	var settled_manager := _new_manager(settled, TEST_SAVE_PATH)
	assert(settled_manager.load_game())
	assert(settled.battle_victories == 1)
	assert(settled.get_resource_amount(&"wood") == wood_before + 20)
	assert(not settled._complete_battle_victory(BattleCatalogData.get_stage(1), encounter_id))
	assert(settled.get_resource_amount(&"wood") == wood_before + 20)

	var legacy_save: Dictionary = state.export_save_data()
	legacy_save.erase("battle_encounter_sequence")
	legacy_save.erase("active_battle_encounter_id")
	legacy_save.erase("last_settled_battle_encounter_id")
	legacy_save["battle_running"] = true
	legacy_save["auto_battle_enabled"] = true
	var legacy := _new_state()
	assert(legacy.import_save_data(legacy_save))
	assert(legacy.active_battle_encounter_id > 0)
	assert(legacy.active_battle_encounter_id == legacy.battle_encounter_sequence)

	var stopped := _new_state()
	var stopped_id := int(stopped.disciples[0]["id"])
	assert(stopped.set_disciple_job(stopped_id, &"combat"))
	assert(stopped.start_auto_battle(1))
	var stopped_encounter: int = stopped.active_battle_encounter_id
	var stopped_wood: int = stopped.get_resource_amount(&"wood")
	stopped.stop_auto_battle()
	assert(not stopped._complete_battle_victory(BattleCatalogData.get_stage(1), stopped_encounter))
	assert(stopped.get_resource_amount(&"wood") == stopped_wood)

	var all_resources := _new_state()
	var all_resources_id := int(all_resources.disciples[0]["id"])
	assert(all_resources.set_disciple_job(all_resources_id, &"combat"))
	all_resources.highest_unlocked_stage = 2
	var stage_two_wood: int = all_resources.get_resource_amount(&"wood")
	var stage_two_stone: int = all_resources.get_resource_amount(&"spirit_stone")
	var stage_two_food: int = all_resources.get_resource_amount(&"food")
	assert(all_resources.start_auto_battle(2))
	assert(all_resources._complete_battle_victory(BattleCatalogData.get_stage(2), all_resources.active_battle_encounter_id))
	assert(all_resources.get_resource_amount(&"wood") == stage_two_wood + 30)
	assert(all_resources.get_resource_amount(&"spirit_stone") == stage_two_stone + 8)
	assert(all_resources.get_resource_amount(&"food") == stage_two_food + 12)
	assert(all_resources.battle_victories == 1)

	var failed := _new_state()
	var failed_id := int(failed.disciples[0]["id"])
	assert(failed.set_disciple_job(failed_id, &"combat"))
	assert(failed.start_auto_battle(1))
	var failed_wood: int = failed.get_resource_amount(&"wood")
	failed.battle_player_hp = 1.0
	assert(not failed.process_battle(1.0))
	assert(not failed.battle_running)
	assert(failed.battle_victories == 0)
	assert(failed.get_resource_amount(&"wood") == failed_wood)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	print("PASS: battle reward settlement is traceable, idempotent, and save failures stay visible")
	quit()
