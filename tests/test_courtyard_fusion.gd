extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	assert(preload("res://scripts/world/courtyard_demo.gd").populate(state))
	var map: Control = load("res://scripts/world/sect_map.gd").new()
	root.add_child(map)
	map.size = Vector2(1918, 1078)
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	var origin: Vector2 = map._map_origin()
	var plan: Dictionary = map.get_courtyard_plan(origin)
	assert(plan["wing_id"] == state.buildings[0]["instance_id"])
	assert(plan["road"].size() >= 3 and plan["hall_pad"].has_area() and plan["wing_pad"].has_area())
	assert(map.courtyard_atlas.get_image().get_pixel(0, 0).a < 0.01)
	var image_rect := Rect2(Vector2.ZERO, map.courtyard_atlas.get_size())
	for source: Rect2 in map.COURTYARD_SOURCES.values():
		assert(image_rect.encloses(source))
	var items: Array[Dictionary] = map.get_world_draw_items()
	var hall_index := -1
	var wing_index := -1
	var main_rail_index := -1
	var wing_rail_index := -1
	for index: int in range(items.size()):
		match items[index]["key"]:
			"hall": hall_index = index
			"courtyard:hall": main_rail_index = index
			"courtyard:wing": wing_rail_index = index
		if items[index]["kind"] == "building":
			wing_index = index
	assert(main_rail_index > hall_index and wing_rail_index > wing_index)
	# 栏杆确实遮住部分台基，但这一透明像素轮廓不能阻断下方建筑选择。
	var building: Dictionary = state.buildings[0]
	var spec: Dictionary = map.get_building_visual(StringName(building["type"]))
	var visual: Rect2 = map.get_building_visual_rect(building, origin)
	var overlap: Rect2 = visual.intersection(items[wing_rail_index]["rect"])
	var covered_and_clickable := false
	for x: int in range(16):
		for y: int in range(16):
			var point := overlap.position + overlap.size * Vector2((x + 0.5) / 16.0, (y + 0.5) / 16.0)
			if map._is_sprite_hit(spec["texture"], spec["source"], visual, point) and map._is_sprite_hit(map.courtyard_atlas, map.COURTYARD_SOURCES["rail"], items[wing_rail_index]["rect"], point):
				assert(map._pick_visual_building(point, origin).get("instance_id", 0) == building["instance_id"])
				covered_and_clickable = true
	assert(covered_and_clickable)
	for x: int in range(12):
		for y: int in range(8):
			var cell := Vector2i(x, y)
			var expected := cell not in [Vector2i(4, 3), Vector2i(1, 1), Vector2i(6, 1), Vector2i(2, 4), Vector2i(2, 6)]
			assert(map.is_placement_valid(cell) == expected)
	assert(state.export_save_data() == snapshot)
	# 其他建筑进入装饰落点时栏杆让位，包括尚在施工中的建筑。
	assert(state.start_construction(&"lumber_yard", Vector2i(5, 3)))
	for item: Dictionary in map.get_courtyard_foreground(origin):
		assert(item["key"] != "courtyard:hall")
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
	print("PASS: local courtyard plan, sorted foreground, visible occlusion with click-through, all-cell legality, yielding and save round trip")
	quit()
