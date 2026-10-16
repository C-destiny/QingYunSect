extends SceneTree

# Read-only engineering probes: synthetic state, no player save writes.
func _init() -> void:
	call_deferred("_audit")

func _new_state() -> Node:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	return state

func _audit() -> void:
	var state := _new_state()
	state.set_disciple_job(1, &"combat")
	state.start_auto_battle(1)
	state.set_disciple_job(2, &"forest")
	print("AUDIT unrelated_job_stops_battle=", not state.battle_running)
	state.start_auto_battle(1)
	state.process_battle(20.0)
	state.set_disciple_job(1, &"idle")
	print("AUDIT empty_party_keeps_repeat_enabled=", state.auto_battle_enabled)
	state.process_battle(2.0)
	print("AUDIT stalled_repeat=", state.auto_battle_enabled and not state.battle_running and state.battle_restart_cooldown == 0.0)

	var source := _new_state()
	source.set_disciple_job(1, &"combat")
	source.set_disciple_job(2, &"combat")
	var saved: Dictionary = source.export_save_data()
	saved["battle_party"] = [1]
	var restored := _new_state()
	print("AUDIT omitted_combat_member_import_accepted=", restored.import_save_data(saved))
	var invalid: Dictionary = source.export_save_data()
	invalid["resources"]["wood"] = 9876
	invalid["disciples"][0]["id"] = -1
	var rejected: bool = not restored.import_save_data(invalid)
	print("AUDIT rejected_load_mutates_resources=", rejected and restored.get_resource_amount(&"wood") == 9876)

	var reward_state := _new_state()
	reward_state.set_disciple_job(1, &"combat")
	reward_state.start_auto_battle(1)
	reward_state.process_battle(20.0)
	var before: int = reward_state.get_resource_amount(&"wood")
	reward_state._complete_battle_victory(preload("res://scripts/data/battle_catalog.gd").get_stage(1))
	print("AUDIT direct_settlement_reentry_grants_again=", reward_state.get_resource_amount(&"wood") > before)

	var manager := root.get_node("SaveManager")
	manager.save_path = "res://tests/.audit_v03_unused.json"
	if FileAccess.file_exists(manager.save_path):
		push_error("Audit isolation path already exists; abort")
		quit(1)
		return
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	root.add_child(scene.instantiate())
	await process_frame
	print("AUDIT main_scene_instantiated_with_isolated_save_path")
	quit(0)
