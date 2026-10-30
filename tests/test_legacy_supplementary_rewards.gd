extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1

func _init() -> void:
	for stage_id: int in range(1, 6):
		var online := preload("res://scripts/core/game_state.gd").new()
		var offline := preload("res://scripts/core/game_state.gd").new()
		root.add_child(online)
		root.add_child(offline)
		for state: Node in [online, offline]:
			state.get_idle_disciples()
			for disciple: Dictionary in state.disciples:
				disciple["realm_level"] = 9
				assert(state.set_disciple_job(int(disciple["id"]), &"combat"))
			state.highest_unlocked_stage = 5
			assert(state.start_auto_battle(stage_id))
		for second: int in range(450):
			online.process_battle(1.0)
		offline.apply_offline_progress({"eligible": true, "effective_seconds": 450, "settlement_id": "balance"})
		var wood: int = online.get_resource_amount(&"wood") - 120
		var stone: int = online.get_resource_amount(&"spirit_stone") - 80
		check(wood < 90 and stone < 80, "legacy resources must remain supplementary")
		check(online.equipment_inventory.is_empty(), "450s legacy farming must not flood equipment")
		check(online.battle_victories == offline.battle_victories, "online/offline victories match")
		check(online.get_resource_amount(&"wood") == offline.get_resource_amount(&"wood"), "online/offline rewards match")
		print("stage=%d victories=%d wood=%d stone=%d equipment=%d" % [stage_id, online.battle_victories, wood, stone, online.equipment_inventory.size()])
		online.free()
		offline.free()
	if failures > 0:
		quit(1)
		return
	print("PASS: five strong-party stages have bounded supplementary rewards online and offline")
	quit()