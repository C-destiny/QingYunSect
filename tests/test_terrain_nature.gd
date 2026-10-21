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
	for view: Vector2 in [Vector2(1278, 718), Vector2(1918, 1078)]:
		map.size = view
		for lift: float in [0.0, 24.0]:
			map.visual_plane_lift = lift
			var origin: Vector2 = map._map_origin()
			var bounds: Rect2 = Surface.make_plan(origin)["bounds"]
			for edge: Dictionary in Surface.natural_edges(origin):
				assert(edge["outer"].size() == 9)
				for point: Vector2 in edge["outer"]:
					var cell := Layout.unproject_continuous(point, origin)
					assert(Layout.project_continuous(cell, origin).is_equal_approx(point))
					if edge["side"] == 0:
						assert(cell.x >= bounds.end.x - 0.001)
					else:
						assert(cell.y >= bounds.end.y - 0.001)
			for center: Vector2 in [Vector2(0, 7), Vector2(11, 0), Vector2(11, 7), Vector2(2, 6)]:
				for cell: Vector2 in Surface.paved_patch_polygon(center, Vector2.ONE):
					assert(cell.x >= bounds.position.x - 0.001 and cell.x <= bounds.end.x + 0.001)
					assert(cell.y >= bounds.position.y - 0.001 and cell.y <= bounds.end.y + 0.001)
			var routes: Array[Dictionary] = map.get_courtyard_routes(origin)
			assert(routes.size() == 3)
			var approaches: Array[Dictionary] = map.get_terrain_approaches(origin)
			assert(routes[0]["start"].is_equal_approx(approaches[0]["end"]))
			assert(routes[1]["start"].is_equal_approx(approaches[1]["end"]))
			assert(routes[2]["start"].is_equal_approx(routes[1]["end"]))
			assert(Geometry2D.get_closest_point_to_segment(routes[2]["end"], routes[0]["start"], routes[0]["end"]).is_equal_approx(routes[2]["end"]))
			assert(Layout.unproject_continuous(routes[0]["end"], origin).distance_to(Vector2(3.25, bounds.end.y)) < 0.05)
			var pine_found := false
			for decor: Dictionary in map.get_courtyard_foreground(origin):
				if decor["key"] == "courtyard:pine":
					pine_found = true
			assert(pine_found)
	assert(state.export_save_data() == saved)
	assert(map.GARDEN_PINE.get_image().get_pixel(0, 0).a < 0.01)
	assert(state.start_construction(&"lumber_yard", Vector2i(3, 6)))
	for route: Dictionary in map.get_courtyard_routes(map._map_origin()):
		assert(route["owner"] != "hall")
	assert(state.buildings[0]["cell_x"] == 2 and state.buildings[0]["cell_y"] == 6)
	map.queue_free()
	await process_frame
	print("PASS: outward natural coast, clipped paving, continuous entry routes, obstruction yielding and pine alpha without state changes")
	quit()
