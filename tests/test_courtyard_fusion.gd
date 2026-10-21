extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	assert(preload("res://scripts/world/courtyard_demo.gd").populate(state))
	var map: Control = load("res://scripts/world/sect_map.gd").new()
	root.add_child(map)
	assert(not map.structured_terrain)
	map.structured_terrain = true
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for view_size: Vector2 in [Vector2(1278, 718), Vector2(1918, 1078)]:
		map.size = view_size
		var origin: Vector2 = map._map_origin()
		var plan: Dictionary = map.get_courtyard_plan(origin)
		assert(plan["wing_id"] == state.buildings[0]["instance_id"])
		assert(plan["height"] == 0.0 and plan["top"].size() == 4)
		for old_overlay: String in ["road", "hall_pad", "wing_pad", "stairs"]:
			assert(not plan.has(old_overlay))
		# 所有逻辑格及四角均须有地面，不能因装饰减少建造空间。
		for x: int in range(12):
			for y: int in range(8):
				var cell := Vector2i(x, y)
				var center: Vector2 = map._cell_to_screen(cell, origin)
				assert(center.is_equal_approx(preload("res://scripts/world/sect_scene_layout.gd").project_continuous(Vector2(cell), origin)))
				assert(map._screen_to_cell(center, origin) == cell)
				assert(Geometry2D.is_point_in_polygon(center, plan["top"]))
				for corner: Vector2 in map._cell_points(center):
					assert(Geometry2D.is_point_in_polygon(corner, plan["top"]))
				var expected := cell not in [Vector2i(4, 3), Vector2i(1, 1), Vector2i(6, 1), Vector2i(2, 4), Vector2i(2, 6)]
				assert(map.is_placement_valid(cell) == expected)
		var items: Array[Dictionary] = map.get_world_draw_items()
		var hall_index := -1
		var wing_index := -1
		var rail_index := -1
		for index: int in range(items.size()):
			match items[index]["key"]:
				"hall": hall_index = index
				"courtyard:edge-left": rail_index = index
			if items[index]["kind"] == "building":
				wing_index = index
		assert(rail_index > hall_index and rail_index > wing_index)
		# 前景进入排序后，建筑实际透明轮廓仍应可选。
		var building: Dictionary = state.buildings[0]
		var spec: Dictionary = map.get_building_visual(StringName(building["type"]))
		var visual: Rect2 = map.get_building_visual_rect(building, origin)
		# 遍历实际精灵轮廓，排序中的装饰不应截断其选择。
		var picked_pixels := 0
		for x: int in range(32):
			for y: int in range(32):
				var point := visual.position + visual.size * Vector2((x + 0.5) / 32.0, (y + 0.5) / 32.0)
				if map._is_sprite_hit(spec["texture"], spec["source"], visual, point):
					assert(map._pick_visual_building(point, origin).get("instance_id", 0) == building["instance_id"])
					picked_pixels += 1
		assert(picked_pixels > 50)
	assert(state.export_save_data() == snapshot)
	# 边缘施工时装饰让位，不禁止原有合法建造。
	assert(state.start_construction(&"lumber_yard", Vector2i(1, 7)))
	for item: Dictionary in map.get_courtyard_foreground(map._map_origin()):
		assert(item["key"] != "courtyard:edge-left")
	var manager := root.get_node("SaveManager")
	manager.save_path = "res://tests/.test_courtyard_fusion.json"
	manager.unix_time_provider = func() -> int: return 5000
	assert(manager.save_game())
	var saved: Dictionary = state.export_save_data().duplicate(true)
	assert(manager.load_game())
	assert(JSON.parse_string(JSON.stringify(state.export_save_data())) == JSON.parse_string(JSON.stringify(saved)))
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.save_path + suffix))
	map.queue_free()
	await process_frame
	print("PASS: shared terrain covers all 96 cells, inverse projection, depth, click-through, yielding and unchanged save round trip")
	quit()
