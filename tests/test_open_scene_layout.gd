extends SceneTree

const ProjectionData = preload("res://scripts/world/sect_projection.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	var map: Control = load("res://scripts/world/sect_map.gd").new()
	root.add_child(map)
	var requests: Array[Vector2i] = []
	map.placement_requested.connect(func(_kind: StringName, cell: Vector2i) -> void: requests.append(cell))
	map.start_placement(&"disciple_quarters")
	assert(map.GRID_SIZE == Vector2i(12, 8))
	assert(map.TILE_SIZE == Vector2(104, 52))
	assert(map.MAIN_HALL_CELL == Vector2i(4, 3))
	# 游戏以1920逻辑画布缩放到1280窗口；物理窗口尺寸不等于地图逻辑尺寸。
	for view_size: Vector2 in [Vector2(1918, 1078), Vector2(2558, 1438)]:
		map.size = view_size
		var origin: Vector2 = map._map_origin()
		for x: int in range(12):
			for y: int in range(8):
				var cell := Vector2i(x, y)
				var center: Vector2 = map._cell_to_screen(cell, origin)
				assert(Rect2(Vector2.ZERO, view_size).has_point(center))
				# 中心及内部偏移均反向映射到原逻辑格；不随新构图写回位置。
				for offset: Vector2 in [Vector2.ZERO, Vector2(12, 4), Vector2(-12, -4)]:
					assert(map._screen_to_cell(center + offset, origin) == cell)
				assert(map._cell_points(center).size() == 4)
				if map.is_placement_valid(cell):
					var previous_count := requests.size()
					var click := InputEventMouseButton.new()
					click.button_index = MOUSE_BUTTON_LEFT
					click.pressed = true
					click.position = center
					map._gui_input(click)
					assert(requests.size() == previous_count + 1 and requests[-1] == cell)
		var old_step := ProjectionData.project(Vector2i(1, 0), Vector2.ZERO).length()
		var new_step: float = (map._cell_to_screen(Vector2i(1, 0), origin) - map._cell_to_screen(Vector2i.ZERO, origin)).length()
		assert(is_equal_approx(new_step / old_step, 1.45))
		assert(map._screen_to_cell(map._cell_to_screen(Vector2i(12, 8), origin), origin) == Vector2i(-1, -1))
	assert(state.export_save_data() == snapshot)
	map.queue_free()
	await process_frame
	print("PASS: unchanged 12x8/104x52 contract, expanded visual spacing, all-cell inverse mapping and immutable state")
	quit()
