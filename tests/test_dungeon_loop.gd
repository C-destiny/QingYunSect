extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var script = load("res://scripts/core/dungeon_service.gd")
	if script == null:
		printerr("FAIL: P6 settlement service missing")
		quit(1)
		return
	var state := root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = "res://tests/.dungeon_loop.json"
	manager.unix_time_provider = func() -> int: return 5000
	var service = script.new(state,manager)
	var id: int = service.begin(1)
	assert(id > 0)
	assert(not state.set_disciple_job(1,&"training"))
	var wood: int = state.get_resource_amount(&"wood")
	assert(service.finish(id,10,30,false))
	assert(state.get_resource_amount(&"wood") == wood+10)
	assert(not service.finish(id,10,30,false))
	id = service.begin(1)
	assert(service.finish(id,20,460,true))
	assert(state.dungeon_progress["pending_weapon"] == 1)
	assert(service.claim_weapon())
	assert(not service.claim_weapon())
	var before: String = JSON.stringify(state.export_save_data())
	manager.save_path = "res://tests/missing-p6/save.json"
	assert(service.begin(1) == 0)
	assert(JSON.parse_string(before) == JSON.parse_string(JSON.stringify(state.export_save_data())))
	manager.save_path = "res://tests/.dungeon_loop.json"
	assert(manager.load_game())
	assert(state.dungeon_progress["wins"] == 1)
	id = service.begin(1)
	assert(service.checkpoint(id,7,20))
	var before_failure: Variant = JSON.parse_string(JSON.stringify(state.export_save_data()))
	manager.save_path = "res://tests/missing-p6/save.json"
	assert(not service.finish(id,10,30,true))
	assert(before_failure == JSON.parse_string(JSON.stringify(state.export_save_data())))
	assert(not service.finish(id,10,460,true))
	assert(before_failure == JSON.parse_string(JSON.stringify(state.export_save_data())))
	manager.save_path = "res://tests/.dungeon_loop.json"
	assert(manager.load_game())
	wood = state.get_resource_amount(&"wood")
	assert(service.recover())
	assert(state.get_resource_amount(&"wood") == wood+7)
	assert(service.recover() and state.get_resource_amount(&"wood") == wood+7)
	while state.equipment_inventory.size() < state.MAX_EQUIPMENT_INVENTORY:
		assert(state.create_equipment_instance(&"cloud_robe",&"common") > 0)
	state.dungeon_progress["pending_weapon"] = 1
	assert(not service.claim_weapon() and state.dungeon_progress["pending_weapon"] == 1)
	var original: Dictionary = state.export_save_data()
	var bad: Dictionary = original.duplicate(true)
	bad["dungeon_progress"]["settled"] = -1
	assert(not state.import_save_data(bad))
	assert(JSON.parse_string(JSON.stringify(original)) == JSON.parse_string(JSON.stringify(state.export_save_data())))
	var legacy: Dictionary = original.duplicate(true)
	legacy.erase("dungeon_progress")
	assert(state.import_save_data(legacy))
	assert(state.dungeon_progress["sequence"] == 0 and state.disciples.size() == 3)
	assert(manager.save_game())
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.save_path+suffix))
	print("PASS: two runs, activity lock, one-time rewards, first-clear equipment, rollback and persistence")
	quit()
