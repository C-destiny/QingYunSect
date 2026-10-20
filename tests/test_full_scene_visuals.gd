extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	state.resources["wood"] = 10000
	state.resources["spirit_stone"] = 10000
	state.unlocked_regions.assign(["core", "east", "south"])
	var map: Control = load("res://scripts/world/sect_map.gd").new()
	root.add_child(map)
	map.size = Vector2(1918, 1078)
	assert(map.unified_building_atlas != null)
	assert(map.unified_building_atlas.get_image().get_pixel(0, 0).a < 0.01)
	for kind: StringName in BuildingCatalog.BUILDINGS:
		assert(state.start_construction(kind, Vector2i(7, 5)))
		state.process_construction(30)
		var building: Dictionary = state.buildings[-1]
		var spec: Dictionary = map.get_building_visual(kind)
		assert(spec["texture"] != null and spec["source"].has_area())
		assert(Rect2(Vector2.ZERO, spec["texture"].get_size()).encloses(spec["source"]))
		var ground: Vector2 = map._cell_to_screen(Vector2i(7, 5), map._map_origin())
		for level: int in [1, 2, 3]:
			# 仅验证视觉等级契约，不写存档或改动运行升级公式。
			building["level"] = level
			var rect: Rect2 = map.get_building_visual_rect(building, map._map_origin())
			assert((rect.position + rect.size * spec["profile"]["foot"]).is_equal_approx(ground))
			var image: Image = spec["texture"].get_image()
			var hit := false
			for y: int in range(3, 8):
				for x: int in range(2, 8):
					var uv := Vector2(x, y) / 10.0
					var pixel := Vector2i(spec["source"].position + uv * spec["source"].size)
					if image.get_pixelv(pixel).a > 0.8:
						var point := rect.position + uv * rect.size
						assert(map._is_sprite_hit(spec["texture"], spec["source"], rect, point))
						assert(not map._pick_visual_building(point, map._map_origin()).is_empty())
						hit = true
			assert(hit)
		state.buildings.clear()
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for kind: StringName in BuildingCatalog.BUILDINGS:
		map.start_placement(kind)
		for x: int in range(12):
			for y: int in range(8):
				var cell := Vector2i(x, y)
				var expected := cell not in [Vector2i(4, 3), Vector2i(1, 1), Vector2i(6, 1), Vector2i(2, 4)]
				assert(map.is_placement_valid(cell) == expected)
	assert(state.export_save_data() == snapshot)
	# 宽台基脚点在池水外，也须让位；该纯渲染查询不能污染状态或禁止建造。
	var first_pond: Rect2 = map.get_garden_rect(map._map_origin())
	assert(first_pond.has_area())
	assert(state.start_construction(&"scripture_library", Vector2i(3, 5)))
	var before_garden: Dictionary = state.export_save_data().duplicate(true)
	var alternative: Rect2 = map.get_garden_rect(map._map_origin())
	assert(alternative != first_pond)
	assert(alternative.has_area())
	assert(state.export_save_data() == before_garden)
	assert(state.start_construction(&"disciple_quarters", Vector2i(6, 5)))
	assert(not map.get_garden_rect(map._map_origin()).has_area())
	state.buildings.clear()
	# 将全部七类建筑作为有效version 3状态往返，身份/坐标与其余字段必须保持。
	assert(preload("res://scripts/world/visual_demo.gd").populate_full_scene(state))
	var manager := root.get_node("SaveManager")
	manager.save_path = "res://tests/.test_full_scene_visuals.json"
	manager.unix_time_provider = func() -> int: return 5000
	assert(manager.save_game())
	var saved: Dictionary = state.export_save_data().duplicate(true)
	assert(manager.load_game())
	assert(JSON.parse_string(JSON.stringify(saved)) == JSON.parse_string(JSON.stringify(state.export_save_data())))
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.save_path + suffix))
	map.queue_free()
	await process_frame
	print("PASS: seven building visual profiles, three-level stable feet, alpha picking and all-cell soft zoning compatibility")
	quit()
