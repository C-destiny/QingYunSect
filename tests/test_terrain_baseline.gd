extends SceneTree

const Layout = preload("res://scripts/world/sect_scene_layout.gd")
const Surface = preload("res://scripts/world/sect_terrain_surface.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	assert(preload("res://scripts/world/courtyard_demo.gd").populate(state))
	var map: Control = load("res://scripts/world/sect_map.gd").new()
	root.add_child(map)
	map.structured_terrain = true
	var saved: Dictionary = state.export_save_data().duplicate(true)
	var emitted: Array[Vector2i] = []
	map.placement_requested.connect(func(_kind: StringName, cell: Vector2i) -> void: emitted.append(cell))
	for view: Vector2 in [Vector2(1278, 718), Vector2(1918, 1078)]:
		map.size = view
		for lift: float in [0.0, 24.0]:
			map.visual_plane_lift = lift
			var origin: Vector2 = map._map_origin()
			assert(origin.is_equal_approx(Layout.origin(view) - Vector2(0, lift)))
			var hall: Dictionary = map.get_hall_ground_frame(origin)
			assert((hall["rect"].position + hall["rect"].size * map.MAIN_HALL_VISUAL["foot"]).is_equal_approx(hall["foot"]))
			assert(hall["shadow"].is_equal_approx(hall["foot"] + map.MAIN_HALL_VISUAL["shadow_offset"]))
			for kind: StringName in BuildingCatalog.BUILDINGS:
				map.start_placement(kind)
				var preview: Dictionary = map.get_preview_ground_frame(Vector2i(7, 5), origin)
				for level: int in [1, 2, 3]:
					var fixture := {"type": kind, "cell_x": 7, "cell_y": 5, "level": level}
					var frame: Dictionary = map.get_building_ground_frame(fixture, origin)
					assert(frame["foot"].is_equal_approx(preview["foot"]))
					var profile: Dictionary = map.get_building_visual(kind)["profile"]
					assert((frame["rect"].position + frame["rect"].size * profile["foot"]).is_equal_approx(frame["foot"]))
					assert((frame["rect"].position + frame["rect"].size * profile.get("entrance", profile["foot"])).is_equal_approx(frame["entrance"]))
					if level == 1:
						assert(frame["rect"].is_equal_approx(preview["rect"]))
			map.start_placement(&"disciple_quarters")
			for stage: int in range(4):
				map.terrain_detail_stage = stage
				for x: int in range(12):
					for y: int in range(8):
						var cell := Vector2i(x, y)
						var point: Vector2 = map._cell_to_screen(cell, origin)
						assert(map._screen_to_cell(point, origin) == cell)
						var before := emitted.size()
						var event := InputEventMouseButton.new()
						event.button_index = MOUSE_BUTTON_LEFT
						event.pressed = true
						event.position = point
						map._gui_input(event)
						if map.is_placement_valid(cell):
							assert(emitted.size() == before + 1 and emitted[-1] == cell)
						else:
							assert(emitted.size() == before)
			for step: Dictionary in Surface.edge_stair_plan(origin):
				assert(step["logical_y"] >= Surface.make_plan(origin)["bounds"].end.y)
			var approaches: Array[Dictionary] = map.get_terrain_approaches(origin)
			assert(approaches.size() == 2)
			assert(approaches[0]["start"].is_equal_approx(hall["entrance"]))
	assert(state.export_save_data() == saved)
	map.visual_plane_lift = 0.0
	map.cancel_placement()
	var first: Rect2 = map.get_structured_garden_rect(map._map_origin())
	assert(first.has_area())
	assert(state.start_construction(&"lumber_yard", Vector2i(8, 4)))
	var second: Rect2 = map.get_structured_garden_rect(map._map_origin())
	assert(second != first)
	assert(state.start_construction(&"lumber_yard", Vector2i(8, 3)))
	assert(not map.get_structured_garden_rect(map._map_origin()).has_area())
	# 即使地景被隐藏，原合法格仍可直接建造，身份/位置由原GameState维护。
	assert(state.buildings[0]["cell_x"] == 2 and state.buildings[0]["cell_y"] == 6)
	map.queue_free()
	await process_frame
	print("PASS: shared ground frame, entrances, shadows, level previews, 1536 real input mappings, exterior stair drop and garden yielding")
	quit()
