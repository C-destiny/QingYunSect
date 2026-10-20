extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := root.get_node("GameState")
	var map: Control = load("res://scripts/world/sect_map.gd").new()
	root.add_child(map)
	map.size = Vector2(1918, 1078)
	assert(not map.is_grid_visible())
	assert(state.start_construction(&"disciple_quarters", Vector2i(3, 3)))
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	# 固定坐标契约独立于推荐视觉区域；逐格核对改造前的空间规则未改变。
	var resource_cells := [Vector2i(1, 1), Vector2i(6, 1), Vector2i(2, 4)]
	for x: int in range(12):
		for y: int in range(8):
			var cell := Vector2i(x, y)
			var expected: bool = x < 8 and y < 6 and cell not in resource_cells
			expected = expected and cell not in [Vector2i(4, 3), Vector2i(3, 3)]
			var feedback: Dictionary = map.get_placement_feedback(cell)
			assert(bool(feedback["is_valid"]) == expected)
			assert(map.is_placement_valid(cell) == expected)
			assert(not String(feedback["reason"]).is_empty())
	assert(map.get_placement_feedback(Vector2i(3, 3))["category"] == "occupied")
	assert(map.get_placement_feedback(Vector2i(4, 3))["reason"] == "宗门主殿固定占地")
	assert(map.get_placement_feedback(Vector2i(1, 1))["category"] == "resource")
	assert(map.get_placement_feedback(Vector2i(8, 0))["category"] == "locked")
	assert(map.get_placement_feedback(Vector2i(-1, -1))["category"] == "outside")
	assert(map.get_placement_feedback(Vector2i(12, 8))["category"] == "outside")
	map.start_placement(&"disciple_quarters")
	assert(map.is_grid_visible())
	var requests: Array[Vector2i] = []
	map.placement_requested.connect(func(_kind: StringName, cell: Vector2i) -> void: requests.append(cell))
	for cell: Vector2i in [Vector2i(3, 3), Vector2i(1, 1), Vector2i(8, 0), Vector2i(-1, -1)]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = map._cell_to_screen(cell, map._map_origin())
		map._gui_input(click)
	assert(requests.is_empty())
	var valid_click := InputEventMouseButton.new()
	valid_click.button_index = MOUSE_BUTTON_LEFT
	valid_click.pressed = true
	valid_click.position = map._cell_to_screen(Vector2i(7, 5), map._map_origin())
	map._gui_input(valid_click)
	assert(requests == [Vector2i(7, 5)])
	map.cancel_placement()
	assert(not map.is_grid_visible())
	assert(state.export_save_data() == snapshot)
	# 已解锁后同一格立即变为可建，只依赖原永久解锁状态，不引入新推荐区限制。
	state.unlocked_regions.assign(["core", "east", "south"])
	assert(map.get_placement_feedback(Vector2i(8, 0))["is_valid"])
	assert(map.get_placement_feedback(Vector2i(11, 7))["is_valid"])
	state.unlocked_regions.assign(snapshot["unlocked_regions"])
	map.queue_free()
	await process_frame
	print("PASS: normal/build grid switch, 96-cell compatibility, reasons, invalid click rejection, and unchanged state")
	quit()
