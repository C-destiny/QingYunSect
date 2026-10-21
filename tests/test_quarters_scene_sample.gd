extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_quarters_scene_sample.json"
const SAMPLE_CELL := Vector2i(3, 3)


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
	manager.unix_time_provider = func() -> int: return 5000
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.sect_map.fixed_layout = false # 显式回归保留的自由建造备份链路。
	main.set_process(false)
	main.autosave_timer.stop()
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	var map: Control = main.sect_map
	await process_frame
	var definition: Dictionary = BuildingCatalog.get_data(&"disciple_quarters")
	var initial_capacity: int = state.get_disciple_capacity()
	# 从原UI意图到地图信号再到建造/保存，验证新视觉没有绕开真实操作链。
	main._start_building_placement(&"disciple_quarters")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = map._cell_to_screen(SAMPLE_CELL, map._map_origin())
	map._gui_input(click)
	assert(state.buildings.size() == 1)
	var instance_id: int = state.buildings[0]["instance_id"]
	assert(not bool(state.get_building(instance_id)["completed"]))
	assert(state.get_disciple_capacity() == initial_capacity)
	assert(state.get_resource_amount(&"wood") == 1000 - int(definition["cost"]["wood"]))
	assert(FileAccess.file_exists(TEST_SAVE_PATH))
	state.process_construction(float(definition["build_time"]))
	assert(state.get_disciple_capacity() == initial_capacity + int(definition["disciple_capacity"]))
	map._gui_input(click)
	assert(main.selected_building_instance == instance_id)
	assert(main.building_card.visible)
	assert(not main.management_sidebar.visible)
	assert(map._is_hall_occluding_active_building(map._map_origin()))
	var feet: Vector2 = map._cell_to_screen(SAMPLE_CELL, map._map_origin())
	var initial_rect: Rect2 = map.get_grounded_rect(feet, map.QUARTERS_VISUAL)
	var roof_point := initial_rect.position + initial_rect.size * Vector2(0.5, 0.4)
	assert(int(map._pick_visual_building(roof_point, map._map_origin())["instance_id"]) == instance_id)
	assert(not map._is_sprite_hit(map.QUARTERS_SAMPLE, Rect2(Vector2.ZERO, map.QUARTERS_SAMPLE.get_size()),
		initial_rect, initial_rect.position + Vector2.ONE))
	for target_level: int in [2, 3]:
		assert(state.start_building_upgrade(instance_id))
		assert(not state.can_demolish_building(instance_id))
		# 既有version 3字段往返必须保留施工/升级、ID和原地块，不擅迁到推荐区。
		assert(manager.save_game())
		var saved: Dictionary = state.export_save_data().duplicate(true)
		assert(manager.load_game())
		# JSON解析将整数字段读为浮点；比较持久化后的完整JSON值，不能把类型归一化误判为数据丢失。
		var after: Dictionary = state.export_save_data()
		assert(JSON.parse_string(JSON.stringify(after)) == JSON.parse_string(JSON.stringify(saved)))
		state.process_construction(BuildingCatalog.get_upgrade_time(&"disciple_quarters", target_level))
		var building: Dictionary = state.get_building(instance_id)
		assert(int(building["level"]) == target_level)
		assert(Vector2i(building["cell_x"], building["cell_y"]) == SAMPLE_CELL)
		var rect: Rect2 = map.get_grounded_rect(feet, map.QUARTERS_VISUAL, 1.0 + (target_level - 1) * 0.055)
		assert((rect.position + rect.size * Vector2(map.QUARTERS_VISUAL["foot"])).is_equal_approx(feet))
	assert(state.get_disciple_capacity() == initial_capacity + int(definition["disciple_capacity"]) * 3)
	assert(not state.can_upgrade_building(instance_id))
	# 非推荐位置仍能自由建造，软分区不得变成数据层禁建或产能惩罚。
	assert(map.is_placement_valid(Vector2i(7, 5)))
	assert(state.start_construction(&"disciple_quarters", Vector2i(7, 5)))
	assert(state.can_demolish_building(instance_id))
	var refund: Dictionary = state.demolish_building(instance_id)
	assert(not refund.is_empty())
	assert(state.get_building(instance_id).is_empty())
	assert(map.is_placement_valid(SAMPLE_CELL))
	assert(manager.save_game())
	assert(manager.load_game())
	assert(state.get_building(instance_id).is_empty())
	assert(manager.SAVE_VERSION == 3)
	assert(map.QUARTERS_SAMPLE.get_image().get_pixel(0, 0).a < 0.01)
	assert(map.QUARTERS_VISUAL["size"].x < map.MAIN_HALL_VISUAL["size"].x)
	main.queue_free()
	await process_frame
	_cleanup()
	print("PASS: residence UI placement, selection, levels, capacity, version 3 round trips, free location, and demolition")
	quit()
