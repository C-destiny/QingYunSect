extends SceneTree

func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	assert(state.set_disciple_job(int(state.disciples[0]["id"]), &"forest"))
	state.resources["wood"] = 0
	state.resources["food"] = 2
	var receipt: Dictionary = state.apply_offline_progress({
		"eligible": true,
		"effective_seconds": 120,
		"settlement_id": "economy-test",
	})
	assert(state.get_resource_amount(&"food") == 0)
	assert(state.get_resource_amount(&"wood") == 16)
	assert(receipt["resources"]["wood"] == 16)
	assert(receipt["food_consumed"] == 2)

	var fed := preload("res://scripts/core/game_state.gd").new()
	root.add_child(fed)
	fed.get_idle_disciples()
	assert(fed.set_disciple_job(int(fed.disciples[0]["id"]), &"forest"))
	assert(fed.set_disciple_job(int(fed.disciples[1]["id"]), &"field"))
	fed.resources = {"wood": 0, "spirit_stone": 0, "food": 10}
	var fed_receipt: Dictionary = fed.apply_offline_progress({"eligible": true, "effective_seconds": 60, "settlement_id": "fed"})
	assert(fed.get_resource_amount(&"wood") == 12)
	assert(fed.get_resource_amount(&"food") == 17)
	assert(fed_receipt["food_consumed"] == 3)

	var online := preload("res://scripts/core/game_state.gd").new()
	var offline := preload("res://scripts/core/game_state.gd").new()
	root.add_child(online)
	root.add_child(offline)
	for candidate: Node in [online, offline]:
		candidate.get_idle_disciples()
		assert(candidate.set_disciple_job(int(candidate.disciples[0]["id"]), &"forest"))
		candidate.resources = {"wood": 0, "spirit_stone": 0, "food": 2}
	for second: int in range(120):
		online.process_production(&"forest", &"wood", 12.0, 1.0)
		online.process_disciple_consumption(1.0)
	offline.apply_offline_progress({"eligible": true, "effective_seconds": 120, "settlement_id": "compare"})
	assert(absi(online.get_resource_amount(&"wood") - offline.get_resource_amount(&"wood")) <= 1)
	assert(online.get_resource_amount(&"food") == offline.get_resource_amount(&"food"))
	print("PASS: offline production uses shared rates and splits normal/hungry food phases")
	quit()
