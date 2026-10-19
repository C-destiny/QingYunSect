extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := root.get_node("GameState")
	var map: Control = load("res://scripts/world/sect_map.gd").new()
	root.add_child(map)
	map.size = Vector2(1918, 1078)
	# 用相反的建造顺序覆盖前后关系；不经过主场景或SaveManager，不访问玩家存档。
	assert(state.start_construction(&"disciple_quarters", Vector2i(5, 4)))
	assert(state.start_construction(&"lumber_yard", Vector2i(0, 0)))
	assert(state.start_construction(&"disciple_quarters", Vector2i(3, 3)))
	var saved_before: Dictionary = state.export_save_data().duplicate(true)
	var first_items: Array[Dictionary] = map.get_world_draw_items()
	assert(state.export_save_data() == saved_before)
	assert(first_items[0]["kind"] == "building")
	assert(first_items[0]["cell"] == Vector2i(0, 0))
	assert(first_items[-1]["cell"] == Vector2i(5, 4))
	var first_keys: Array[String] = []
	for item: Dictionary in first_items:
		first_keys.append(item["key"])
	state.buildings.reverse()
	var reversed_snapshot: Dictionary = state.export_save_data().duplicate(true)
	var reversed_keys: Array[String] = []
	for item: Dictionary in map.get_world_draw_items():
		reversed_keys.append(item["key"])
	assert(first_keys == reversed_keys)
	assert(state.export_save_data() == reversed_snapshot)

	var ground: Vector2 = map._cell_to_screen(Vector2i(4, 3), map._map_origin())
	for profile: Dictionary in [map.MAIN_HALL_VISUAL, map.BUILDING_VISUAL, map.RESOURCE_VISUAL]:
		for visual_scale: float in [1.0, 1.055, 1.11]:
			var rect: Rect2 = map.get_grounded_rect(ground, profile, visual_scale)
			# 改等级/缩放时，素材脚点必须仍落在同一个逻辑格中心。
			assert((rect.position + rect.size * Vector2(profile["foot"])).is_equal_approx(ground))
	assert(map.MAIN_HALL_SAMPLE.get_image().get_pixel(0, 0).a < 0.01)
	assert(map.MAIN_HALL_VISUAL["size"].x > map.BUILDING_VISUAL["size"].x)
	# 新增视觉组织不能让原本合法的空格失效，也不能改变固定资源/主殿占位。
	assert(map.is_placement_valid(Vector2i(3, 4)))
	map.hovered_cell = Vector2i(3, 3)
	assert(map._is_hall_occluding_active_building(map._map_origin()))
	map.hovered_cell = Vector2i(5, 4)
	assert(not map._is_hall_occluding_active_building(map._map_origin()))
	assert(not map.is_placement_valid(Vector2i(4, 3)))
	assert(not map.is_placement_valid(Vector2i(1, 1)))
	assert(not map.is_placement_valid(Vector2i(8, 0)))
	assert(state.export_save_data() == reversed_snapshot)
	map.queue_free()
	await process_frame
	print("PASS: depth sorting independent of save order, immutable data, stable feet, and placement compatibility")
	quit()
