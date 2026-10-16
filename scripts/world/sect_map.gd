extends Control

signal resource_selected(resource_data: Dictionary)
signal placement_requested(building_type: StringName, cell: Vector2i)

const GRID_SIZE := Vector2i(8, 6)
const TILE_SIZE := Vector2(104.0, 52.0)
const TILE_COLOR_A := Color(0.16, 0.28, 0.25, 1.0)
const TILE_COLOR_B := Color(0.13, 0.24, 0.22, 1.0)
const TILE_OUTLINE := Color(0.27, 0.43, 0.37, 0.72)
const SELECTED_OUTLINE := Color(0.86, 0.76, 0.37, 1.0)

var resource_nodes: Array[Dictionary] = [
	{"site_id": &"forest", "resource_id": &"wood", "cell": Vector2i(1, 1), "name": "青松林", "description": "宗门西侧的成片青松，可安排普通弟子伐木。", "reserve": 600, "rate": 12.0, "resource_name": "木材", "color": Color(0.24, 0.68, 0.39, 1.0)},
	{"site_id": &"mine", "resource_id": &"spirit_stone", "cell": Vector2i(6, 1), "name": "浅层灵石矿", "description": "灵气稀薄但易于开采的矿脉，是宗门初期灵石来源。", "reserve": 420, "rate": 8.0, "resource_name": "灵石", "color": Color(0.35, 0.73, 0.9, 1.0)},
	{"site_id": &"field", "resource_id": &"food", "cell": Vector2i(2, 4), "name": "荒芜灵田", "description": "经过整理即可种植灵谷，为弟子提供日常消耗。", "reserve": 500, "rate": 10.0, "resource_name": "灵谷", "color": Color(0.84, 0.67, 0.25, 1.0)},
]

var selected_cell := Vector2i(-1, -1)
var hovered_cell := Vector2i(-1, -1)
var placement_building: StringName = &""


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	GameState.assignments_changed.connect(queue_redraw)
	GameState.buildings_changed.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var origin := _map_origin()
	for sum_index: int in range(GRID_SIZE.x + GRID_SIZE.y - 1):
		for x: int in range(GRID_SIZE.x):
			var y := sum_index - x
			if y < 0 or y >= GRID_SIZE.y:
				continue
			var cell := Vector2i(x, y)
			var center := _cell_to_screen(cell, origin)
			var points := PackedVector2Array([
				center + Vector2(0.0, -TILE_SIZE.y * 0.5),
				center + Vector2(TILE_SIZE.x * 0.5, 0.0),
				center + Vector2(0.0, TILE_SIZE.y * 0.5),
				center + Vector2(-TILE_SIZE.x * 0.5, 0.0),
			])
			var fill := TILE_COLOR_A if (x + y) % 2 == 0 else TILE_COLOR_B
			draw_colored_polygon(points, fill)
			var outline := SELECTED_OUTLINE if cell == selected_cell else TILE_OUTLINE
			var width := 3.0 if cell == selected_cell else 1.2
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), outline, width, true)
			if cell == hovered_cell and cell != selected_cell:
				draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.68, 0.82, 0.72, 0.9), 2.0, true)

	for building: Dictionary in GameState.buildings:
		_draw_building(building, origin)
	_draw_main_hall(origin)
	for resource_data: Dictionary in resource_nodes:
		_draw_resource(resource_data, origin)
	_draw_placement_preview(origin)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hovered_cell = _screen_to_cell(event.position, _map_origin())
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var clicked_cell := _screen_to_cell(event.position, _map_origin())
		if placement_building != &"":
			if is_placement_valid(clicked_cell):
				placement_requested.emit(placement_building, clicked_cell)
			accept_event()
			return
		for resource_data: Dictionary in resource_nodes:
			if resource_data["cell"] == clicked_cell:
				selected_cell = clicked_cell
				resource_selected.emit(resource_data)
				queue_redraw()
				accept_event()
				return


func start_placement(building_type: StringName) -> void:
	placement_building = building_type
	selected_cell = Vector2i(-1, -1)
	queue_redraw()


func cancel_placement() -> void:
	placement_building = &""
	queue_redraw()


func is_placement_valid(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID_SIZE.x or cell.y >= GRID_SIZE.y:
		return false
	if GameState.is_cell_occupied(cell):
		return false
	for resource_data: Dictionary in resource_nodes:
		if resource_data["cell"] == cell:
			return false
	return true


func _map_origin() -> Vector2:
	return Vector2(size.x * 0.5, maxf(90.0, size.y * 0.18))


func _cell_to_screen(cell: Vector2i, origin: Vector2) -> Vector2:
	return origin + Vector2(float(cell.x - cell.y) * TILE_SIZE.x * 0.5, float(cell.x + cell.y) * TILE_SIZE.y * 0.5)


func _screen_to_cell(screen_position: Vector2, origin: Vector2) -> Vector2i:
	var local := screen_position - origin
	var grid_x := local.x / TILE_SIZE.x + local.y / TILE_SIZE.y
	var grid_y := local.y / TILE_SIZE.y - local.x / TILE_SIZE.x
	var cell := Vector2i(floori(grid_x + 0.5), floori(grid_y + 0.5))
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID_SIZE.x or cell.y >= GRID_SIZE.y:
		return Vector2i(-1, -1)
	return cell


func _draw_main_hall(origin: Vector2) -> void:
	var center := _cell_to_screen(Vector2i(4, 3), origin)
	draw_rect(Rect2(center + Vector2(-48, -58), Vector2(96, 66)), Color(0.35, 0.24, 0.18, 1.0), true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-64, -58), center + Vector2(0, -96), center + Vector2(64, -58), center + Vector2(0, -38)]), Color(0.18, 0.43, 0.39, 1.0))
	draw_string(ThemeDB.fallback_font, center + Vector2(-45, 34), "宗门大殿", HORIZONTAL_ALIGNMENT_CENTER, 90, 18, Color(0.88, 0.9, 0.78, 1.0))


func _draw_resource(resource_data: Dictionary, origin: Vector2) -> void:
	var center := _cell_to_screen(resource_data["cell"], origin) + Vector2(0, -18)
	var color: Color = resource_data["color"]
	draw_circle(center, 18.0, Color(color, 0.2))
	draw_circle(center, 11.0, color)
	draw_circle(center, 4.0, Color.WHITE)
	var workers := GameState.get_assignment(resource_data["site_id"])
	if workers > 0:
		draw_string(ThemeDB.fallback_font, center + Vector2(-18, 39), "%d 人" % workers, HORIZONTAL_ALIGNMENT_CENTER, 36, 15, Color(0.9, 0.94, 0.86, 1.0))


func _draw_building(building: Dictionary, origin: Vector2) -> void:
	var definition := BuildingCatalog.get_data(StringName(building["type"]))
	var cell := Vector2i(int(building["cell_x"]), int(building["cell_y"]))
	var center := _cell_to_screen(cell, origin)
	var color: Color = definition["color"]
	if not bool(building["completed"]):
		color = color.darkened(0.35)
	draw_rect(Rect2(center + Vector2(-34, -47), Vector2(68, 52)), color, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-43, -47), center + Vector2(0, -70), center + Vector2(43, -47), center + Vector2(0, -30)]), color.lightened(0.15))
	var name_text: String = definition["name"]
	draw_string(ThemeDB.fallback_font, center + Vector2(-42, 25), name_text, HORIZONTAL_ALIGNMENT_CENTER, 84, 15, Color(0.9, 0.92, 0.85, 1.0))
	if not bool(building["completed"]):
		var progress := 1.0 - float(building["remaining"]) / float(building["build_time"])
		draw_rect(Rect2(center + Vector2(-36, 31), Vector2(72, 7)), Color(0.08, 0.1, 0.1, 0.9), true)
		draw_rect(Rect2(center + Vector2(-35, 32), Vector2(70.0 * progress, 5)), Color(0.85, 0.67, 0.28, 1.0), true)


func _draw_placement_preview(origin: Vector2) -> void:
	if placement_building == &"" or hovered_cell == Vector2i(-1, -1):
		return
	var center := _cell_to_screen(hovered_cell, origin)
	var valid := is_placement_valid(hovered_cell)
	var preview_color := Color(0.35, 0.9, 0.52, 0.5) if valid else Color(0.95, 0.28, 0.25, 0.5)
	var points := PackedVector2Array([
		center + Vector2(0.0, -TILE_SIZE.y * 0.5),
		center + Vector2(TILE_SIZE.x * 0.5, 0.0),
		center + Vector2(0.0, TILE_SIZE.y * 0.5),
		center + Vector2(-TILE_SIZE.x * 0.5, 0.0),
	])
	draw_colored_polygon(points, preview_color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), preview_color.lightened(0.3), 3.0, true)

