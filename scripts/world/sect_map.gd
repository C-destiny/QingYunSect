extends Control

const ResourceCatalogData = preload("res://scripts/data/resource_catalog.gd")
const TerritoryCatalogData = preload("res://scripts/data/territory_catalog.gd")
const MAIN_HALL_SAMPLE: Texture2D = preload("res://assets/buildings/main-hall-sample.png")
const MAP_BACKDROP: Texture2D = preload("res://assets/environment/sect_floating_mountain.png")
const BUILDING_ATLAS: Texture2D = preload("res://assets/buildings/sect_buildings_atlas.png")
const LANDMARK_ATLAS: Texture2D = preload("res://assets/environment/sect_landmarks_atlas.png")

signal resource_selected(resource_data: Dictionary)
signal placement_requested(building_type: StringName, cell: Vector2i)
signal building_selected(building: Dictionary)
signal region_selected(region_id: StringName)

const GRID_SIZE := TerritoryCatalogData.MAP_SIZE
const TILE_SIZE := Vector2(104.0, 52.0)
const MAIN_HALL_CELL := Vector2i(4, 3)
const TILE_COLOR_A := Color(0.78, 0.88, 0.7, 0.17)
const TILE_COLOR_B := Color(0.62, 0.78, 0.66, 0.12)
const TILE_OUTLINE := Color(0.86, 0.9, 0.72, 0.48)
const SELECTED_OUTLINE := Color(0.86, 0.76, 0.37, 1.0)
const PAPER_WHITE := Color(0.9, 0.87, 0.75, 1.0)
const INK_TEAL := Color(0.075, 0.18, 0.19, 1.0)
const ROOF_TEAL := Color(0.08, 0.23, 0.25, 1.0)
const WARM_WOOD := Color(0.43, 0.27, 0.16, 1.0)
const STONE_LIGHT := Color(0.62, 0.64, 0.57, 1.0)
const GOLD_ACCENT := Color(0.82, 0.64, 0.25, 1.0)
const BUILDING_ATLAS_CELLS := Vector2i(4, 2)
const LANDMARK_ATLAS_CELLS := Vector2i(2, 2)
const BUILDING_ATLAS_INDEX := {
	&"disciple_quarters": Vector2i(0, 0),
	&"lumber_yard": Vector2i(1, 0),
	&"spirit_mine": Vector2i(2, 0),
	&"spirit_field": Vector2i(3, 0),
	&"training_ground": Vector2i(0, 1),
	&"artifact_forge": Vector2i(1, 1),
	&"scripture_library": Vector2i(2, 1),
}
# 脚点为图集格内的归一化地面位置；普通图集沿用原位置，主殿已按独立样板底座校准。
# 只影响渲染，不作为占地、点击或存档数据；尺寸单位为逻辑像素。
const MAIN_HALL_VISUAL := {"size": Vector2(330, 330), "foot": Vector2(0.5, 0.82)}
const BUILDING_VISUAL := {"size": Vector2(136, 153), "foot": Vector2(0.5, 0.5 + 55.0 / 153.0)}
const RESOURCE_VISUAL := {"size": Vector2(126, 84), "foot": Vector2(0.5, 0.5 + 41.0 / 84.0)}

const RESOURCE_ATLAS_INDEX := {
	&"forest": Vector2i(1, 0),
	&"mine": Vector2i(0, 1),
	&"field": Vector2i(1, 1),
}

var resource_nodes: Array[Dictionary] = [
	{"site_id": &"forest", "resource_id": &"wood", "cell": Vector2i(1, 1), "name": "青松林", "description": "宗门西侧的成片青松，可安排普通弟子伐木。", "reserve": 600, "rate": float(ResourceCatalogData.SITES[&"forest"]["rate"]), "resource_name": "木材", "color": Color(0.24, 0.68, 0.39, 1.0)},
	{"site_id": &"mine", "resource_id": &"spirit_stone", "cell": Vector2i(6, 1), "name": "浅层灵石矿", "description": "灵气稀薄但易于开采的矿脉，是宗门初期灵石来源。", "reserve": 420, "rate": float(ResourceCatalogData.SITES[&"mine"]["rate"]), "resource_name": "灵石", "color": Color(0.35, 0.73, 0.9, 1.0)},
	{"site_id": &"field", "resource_id": &"food", "cell": Vector2i(2, 4), "name": "荒芜灵田", "description": "经过整理即可种植灵谷，为弟子提供日常消耗。", "reserve": 500, "rate": float(ResourceCatalogData.SITES[&"field"]["rate"]), "resource_name": "灵谷", "color": Color(0.84, 0.67, 0.25, 1.0)},
]

var selected_cell := Vector2i(-1, -1)
var hovered_cell := Vector2i(-1, -1)
var placement_building: StringName = &""


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	GameState.assignments_changed.connect(queue_redraw)
	GameState.buildings_changed.connect(queue_redraw)
	GameState.territory_changed.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var origin := _map_origin()
	# 层级只在渲染端组织：远景→地面道路→接地影→深度物件→交互，HUD仍由主场景控制。
	_draw_backdrop(origin)
	_draw_ground_layer(origin)
	var items := get_world_draw_items()
	_draw_shadow_layer(items, origin)
	_draw_world_layer(items, origin)
	_draw_interaction_layer(origin)


func _draw_ground_layer(origin: Vector2) -> void:
	for sum_index: int in range(GRID_SIZE.x + GRID_SIZE.y - 1):
		for x: int in range(GRID_SIZE.x):
			var y := sum_index - x
			if y >= 0 and y < GRID_SIZE.y:
				_draw_tile(Vector2i(x, y), origin)
	_draw_region_connections(origin)
	_draw_hall_plaza(origin)


func _draw_hall_plaza(origin: Vector2) -> void:
	# 广场仅是地面装饰，覆盖相邻视觉区域但不参与占用、放置判定或存档。
	var center := _cell_to_screen(MAIN_HALL_CELL, origin) + Vector2(0, 25)
	var plaza := PackedVector2Array([
		center + Vector2(0, -66), center + Vector2(132, 0),
		center + Vector2(0, 66), center + Vector2(-132, 0),
	])
	draw_colored_polygon(plaza, Color(0.93, 0.90, 0.79, 0.25))
	# 低对比度石纹与既有米白台地融合，不用深色边线再造一层逻辑网格。
	draw_set_transform(center + Vector2(0, 20), 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 64, Color(0.60, 0.58, 0.49, 0.3), 1.2, true)
	draw_set_transform(Vector2.ZERO)


# 返回新的排序数组；不排序GameState.buildings、不改实例数据，失败由原有数据校验负责。
func get_world_draw_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = [{"kind": "hall", "cell": MAIN_HALL_CELL, "key": "hall"}]
	for building: Dictionary in GameState.buildings:
		items.append({
			"kind": "building", "cell": Vector2i(int(building["cell_x"]), int(building["cell_y"])),
			"key": "building:%d" % int(building["instance_id"]), "data": building,
		})
	for resource: Dictionary in resource_nodes:
		items.append({"kind": "resource", "cell": resource["cell"], "key": String(resource["site_id"]), "data": resource})
	# 等距投影脚点y与x+y成正比；同深度按x及稳定ID排序，避免读档/建造顺序改变遮挡。
	items.sort_custom(_is_world_item_before)
	return items


func _is_world_item_before(first: Dictionary, second: Dictionary) -> bool:
	var first_cell: Vector2i = first["cell"]
	var second_cell: Vector2i = second["cell"]
	if first_cell.x + first_cell.y != second_cell.x + second_cell.y:
		return first_cell.x + first_cell.y < second_cell.x + second_cell.y
	if first_cell.x != second_cell.x:
		return first_cell.x < second_cell.x
	return String(first["key"]) < String(second["key"])


func _draw_shadow_layer(items: Array[Dictionary], origin: Vector2) -> void:
	# 所有接地影先于建筑主体，防止后绘制建筑的影子盖在前一栋墙面上。
	var hall_center := _cell_to_screen(MAIN_HALL_CELL, origin)
	# 与左上光源对应的右下接地影独立于位图，后续可按底座轮廓校准。
	draw_set_transform(hall_center + Vector2(18, 12), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 104.0, Color(0.08, 0.12, 0.13, 0.14))
	draw_set_transform(Vector2.ZERO)
	for item: Dictionary in items:
		if item["kind"] == "building":
			var center := _cell_to_screen(item["cell"], origin)
			draw_circle(center + Vector2(0, 4), 34.0, Color(0.01, 0.02, 0.02, 0.28))


func _draw_world_layer(items: Array[Dictionary], origin: Vector2) -> void:
	for item: Dictionary in items:
		match item["kind"]:
			"hall": _draw_main_hall(origin)
			"building": _draw_building(item["data"], origin)
			"resource": _draw_resource(item["data"], origin)


func _draw_interaction_layer(origin: Vector2) -> void:
	# 标签、施工状态和选中反馈最后绘制，不能被相邻高屋顶盖住。
	_draw_map_label(_cell_to_screen(MAIN_HALL_CELL, origin) + Vector2(0, 31), "宗门大殿", 104)
	for building: Dictionary in GameState.buildings:
		_draw_building_status(building, origin)
	for resource: Dictionary in resource_nodes:
		var center := _cell_to_screen(resource["cell"], origin)
		if Vector2i(resource["cell"]) == selected_cell:
			draw_arc(center + Vector2(0, -14), 44.0, 0.0, TAU, 40, SELECTED_OUTLINE, 3.0, true)
		var workers := GameState.get_assignment(resource["site_id"])
		if workers > 0:
			_draw_map_label(center + Vector2(0, 20), "%d 人" % workers, 56, 14)
	_draw_placement_preview(origin)


func _draw_backdrop(origin: Vector2) -> void:
	if MAP_BACKDROP != null:
		draw_texture_rect(MAP_BACKDROP, Rect2(Vector2.ZERO, size), false)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.72, 0.9, 0.04), true)
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.12, 0.15, 1.0), true)
	var horizon := maxf(62.0, origin.y - 34.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon + 76), Vector2(size.x * 0.13, horizon - 28),
		Vector2(size.x * 0.27, horizon + 34), Vector2(size.x * 0.41, horizon - 60),
		Vector2(size.x * 0.56, horizon + 22), Vector2(size.x * 0.7, horizon - 42),
		Vector2(size.x * 0.86, horizon + 36), Vector2(size.x, horizon - 16),
		Vector2(size.x, horizon + 130), Vector2(0, horizon + 130),
	]), Color(0.16, 0.29, 0.31, 0.95))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon + 92), Vector2(size.x * 0.2, horizon + 10),
		Vector2(size.x * 0.37, horizon + 70), Vector2(size.x * 0.58, horizon - 2),
		Vector2(size.x * 0.8, horizon + 78), Vector2(size.x, horizon + 20),
		Vector2(size.x, horizon + 150), Vector2(0, horizon + 150),
	]), Color(0.22, 0.37, 0.37, 0.72))
	for cloud_index: int in range(8):
		var x := fmod(67.0 + float(cloud_index) * 173.0, maxf(size.x, 1.0))
		var y := horizon + 46.0 + sin(float(cloud_index) * 1.7) * 22.0
		_draw_cloud(Vector2(x, y), 0.7 + float(cloud_index % 3) * 0.12, Color(0.77, 0.82, 0.78, 0.13))


func _draw_cloud(center: Vector2, scale_value: float, color: Color) -> void:
	draw_circle(center + Vector2(-24, 2) * scale_value, 25.0 * scale_value, color)
	draw_circle(center + Vector2(0, -8) * scale_value, 34.0 * scale_value, color)
	draw_circle(center + Vector2(29, 4) * scale_value, 23.0 * scale_value, color)
	draw_rect(Rect2(center + Vector2(-47, 0) * scale_value, Vector2(92, 24) * scale_value), color, true)


func _cell_points(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -TILE_SIZE.y * 0.5),
		center + Vector2(TILE_SIZE.x * 0.5, 0.0),
		center + Vector2(0.0, TILE_SIZE.y * 0.5),
		center + Vector2(-TILE_SIZE.x * 0.5, 0.0),
	])


func _draw_tile(cell: Vector2i, origin: Vector2) -> void:
	var center := _cell_to_screen(cell, origin)
	var points := _cell_points(center)
	var unlocked := GameState.is_cell_unlocked(cell)
	if unlocked:
		var region_id := TerritoryCatalogData.get_region_for_cell(cell)
		var base := TILE_COLOR_A if (cell.x + cell.y) % 2 == 0 else TILE_COLOR_B
		if region_id == &"east":
			base = base.lerp(Color(0.55, 0.76, 0.76, 0.18), 0.32)
		elif region_id == &"south":
			base = base.lerp(Color(0.72, 0.82, 0.55, 0.18), 0.32)
		var cliff_depth := 17.0
		if cell.x == GRID_SIZE.x - 1 or not GameState.is_cell_unlocked(cell + Vector2i(1, 0)):
			draw_colored_polygon(PackedVector2Array([points[1], points[2], points[2] + Vector2(0, cliff_depth), points[1] + Vector2(0, cliff_depth)]), Color(0.22, 0.32, 0.34, 0.42))
		if cell.y == GRID_SIZE.y - 1 or not GameState.is_cell_unlocked(cell + Vector2i(0, 1)):
			draw_colored_polygon(PackedVector2Array([points[2], points[3], points[3] + Vector2(0, cliff_depth), points[2] + Vector2(0, cliff_depth)]), Color(0.18, 0.27, 0.29, 0.46))
		draw_colored_polygon(points, base)
		draw_line(points[3], points[0], base.lightened(0.16), 1.2, true)
	else:
		draw_colored_polygon(points, Color(0.46, 0.61, 0.66, 0.28))
		draw_line(points[3], points[0], Color(0.9, 0.96, 0.98, 0.38), 1.2, true)
	var outline := SELECTED_OUTLINE if cell == selected_cell else (TILE_OUTLINE if unlocked else Color(0.28, 0.34, 0.34, 0.36))
	var width := 3.0 if cell == selected_cell else 1.1
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), outline, width, true)
	if cell == hovered_cell and cell != selected_cell:
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.72, 0.82, 0.66, 0.94), 2.2, true)


func _draw_region_connections(origin: Vector2) -> void:
	var path_cells := [Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3), Vector2i(4, 4), Vector2i(4, 5), Vector2i(4, 6)]
	for cell: Vector2i in path_cells:
		if not GameState.is_cell_unlocked(cell):
			continue
		var center := _cell_to_screen(cell, origin)
		var stone := _cell_points(center)
		var inset := PackedVector2Array()
		for point: Vector2 in stone:
			inset.append(center + (point - center) * 0.48)
		draw_colored_polygon(inset, Color(0.52, 0.53, 0.47, 0.68))
		draw_polyline(PackedVector2Array([inset[0], inset[1], inset[2], inset[3], inset[0]]), Color(0.72, 0.7, 0.59, 0.48), 1.0, true)


func _draw_environment_details(origin: Vector2) -> void:
	var pine_cells := [Vector2i(0, 2), Vector2i(3, 0), Vector2i(7, 0), Vector2i(9, 2), Vector2i(10, 5), Vector2i(6, 7)]
	for cell: Vector2i in pine_cells:
		if GameState.is_cell_unlocked(cell) and not GameState.is_cell_occupied(cell):
			_draw_pine(_cell_to_screen(cell, origin) + Vector2(0, -12), 0.55)
	var rock_cells := [Vector2i(0, 4), Vector2i(8, 1), Vector2i(11, 4), Vector2i(7, 7)]
	for cell: Vector2i in rock_cells:
		if GameState.is_cell_unlocked(cell) and not GameState.is_cell_occupied(cell):
			var center := _cell_to_screen(cell, origin)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-13, 4), center + Vector2(-5, -16), center + Vector2(7, -20), center + Vector2(17, 5)]), Color(0.35, 0.41, 0.39, 1.0))
			draw_line(center + Vector2(-4, -14), center + Vector2(6, -18), Color(0.62, 0.66, 0.61, 0.8), 2.0, true)


func _draw_pine(base: Vector2, scale_value: float) -> void:
	draw_rect(Rect2(base + Vector2(-3, -23) * scale_value, Vector2(6, 27) * scale_value), Color(0.32, 0.22, 0.14, 1.0), true)
	for offset: Vector2 in [Vector2(0, -50), Vector2(-9, -36), Vector2(10, -31)]:
		var center := base + offset * scale_value
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, -20) * scale_value,
			center + Vector2(18, 15) * scale_value,
			center + Vector2(0, 9) * scale_value,
			center + Vector2(-18, 15) * scale_value,
		]), Color(0.12, 0.34, 0.27, 1.0))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hovered_cell = _screen_to_cell(event.position, _map_origin())
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var clicked_cell := _screen_to_cell(event.position, _map_origin())
		if clicked_cell != Vector2i(-1, -1) and not GameState.is_cell_unlocked(clicked_cell):
			selected_cell = clicked_cell
			region_selected.emit(TerritoryCatalogData.get_region_for_cell(clicked_cell))
			queue_redraw()
			accept_event()
			return
		if placement_building != &"":
			if is_placement_valid(clicked_cell):
				placement_requested.emit(placement_building, clicked_cell)
			accept_event()
			return
		for building: Dictionary in GameState.buildings:
			var building_cell := Vector2i(int(building["cell_x"]), int(building["cell_y"]))
			if building_cell == clicked_cell:
				selected_cell = clicked_cell
				building_selected.emit(building)
				queue_redraw()
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


func clear_selection() -> void:
	selected_cell = Vector2i(-1, -1)
	queue_redraw()


func is_placement_valid(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID_SIZE.x or cell.y >= GRID_SIZE.y:
		return false
	if not GameState.is_cell_unlocked(cell):
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
	var center := _cell_to_screen(MAIN_HALL_CELL, origin)
	if MAIN_HALL_SAMPLE != null:
		var tint := Color(1, 1, 1, 0.28) if _is_hall_occluding_active_building(origin) else Color.WHITE
		draw_texture_rect(MAIN_HALL_SAMPLE, get_grounded_rect(center, MAIN_HALL_VISUAL), false, tint)
		return
	if LANDMARK_ATLAS != null:
		_draw_grounded_atlas(LANDMARK_ATLAS, LANDMARK_ATLAS_CELLS, Vector2i(0, 0), center, MAIN_HALL_VISUAL)
		return
	draw_colored_polygon(PackedVector2Array([center + Vector2(-62, 5), center + Vector2(0, 22), center + Vector2(62, 5), center + Vector2(0, -12)]), Color(0.56, 0.57, 0.51, 1.0))
	for step_index: int in range(3):
		var half_width := 48.0 - float(step_index) * 7.0
		var y := -2.0 - float(step_index) * 7.0
		draw_rect(Rect2(center + Vector2(-half_width, y), Vector2(half_width * 2.0, 7)), STONE_LIGHT.darkened(float(step_index) * 0.05), true)
	draw_rect(Rect2(center + Vector2(-42, -62), Vector2(84, 58)), WARM_WOOD, true)
	for x_offset: float in [-31.0, -10.0, 10.0, 31.0]:
		draw_rect(Rect2(center + Vector2(x_offset - 3, -64), Vector2(6, 61)), Color(0.27, 0.13, 0.09, 1.0), true)
	_draw_roof(center + Vector2(0, -65), 70.0, 30.0, ROOF_TEAL)
	_draw_roof(center + Vector2(0, -88), 56.0, 25.0, ROOF_TEAL.lightened(0.04))
	draw_line(center + Vector2(-48, -88), center + Vector2(48, -88), GOLD_ACCENT, 2.2, true)
	_draw_banner(center + Vector2(-55, -55), Color(0.18, 0.43, 0.48, 1.0))
	_draw_banner(center + Vector2(55, -55), Color(0.18, 0.43, 0.48, 1.0))


func _is_hall_occluding_active_building(origin: Vector2) -> bool:
	# 主殿有视觉外延但不扩占地；操作其后方旧建筑时让主殿淡出，不能靠禁建解决遮挡。
	var hall_rect := get_grounded_rect(_cell_to_screen(MAIN_HALL_CELL, origin), MAIN_HALL_VISUAL)
	for building: Dictionary in GameState.buildings:
		var cell := Vector2i(int(building["cell_x"]), int(building["cell_y"]))
		if cell != selected_cell and cell != hovered_cell:
			continue
		if cell.x + cell.y <= MAIN_HALL_CELL.x + MAIN_HALL_CELL.y and hall_rect.has_point(_cell_to_screen(cell, origin)):
			return true
	return false


func _draw_resource(resource_data: Dictionary, origin: Vector2) -> void:
	var center := _cell_to_screen(resource_data["cell"], origin) + Vector2(0, -18)
	var site_id := StringName(resource_data["site_id"])
	if LANDMARK_ATLAS != null and RESOURCE_ATLAS_INDEX.has(site_id):
		_draw_grounded_atlas(LANDMARK_ATLAS, LANDMARK_ATLAS_CELLS, RESOURCE_ATLAS_INDEX[site_id], _cell_to_screen(resource_data["cell"], origin), RESOURCE_VISUAL)
		return
	draw_circle(center + Vector2(0, 17), 19.0, Color(0.02, 0.05, 0.05, 0.28))
	match site_id:
		&"forest":
			_draw_pine(center + Vector2(-7, 10), 0.42)
			_draw_pine(center + Vector2(9, 13), 0.34)
		&"mine":
			for crystal: PackedVector2Array in [
				PackedVector2Array([center + Vector2(-15, 12), center + Vector2(-9, -17), center + Vector2(0, 10)]),
				PackedVector2Array([center + Vector2(-4, 12), center + Vector2(4, -25), center + Vector2(13, 11)]),
				PackedVector2Array([center + Vector2(7, 13), center + Vector2(17, -10), center + Vector2(24, 14)]),
			]:
				draw_colored_polygon(crystal, Color(0.31, 0.7, 0.78, 1.0))
				draw_polyline(PackedVector2Array([crystal[0], crystal[1], crystal[2], crystal[0]]), Color(0.72, 0.94, 0.96, 0.88), 1.2, true)
		&"field":
			var patch := _cell_points(center + Vector2(0, 11))
			var inset := PackedVector2Array()
			for point: Vector2 in patch:
				inset.append(center + Vector2(0, 11) + (point - center - Vector2(0, 11)) * 0.42)
			draw_colored_polygon(inset, Color(0.54, 0.48, 0.2, 1.0))
			for line_index: int in range(4):
				var dx := -14.0 + float(line_index) * 9.0
				draw_line(center + Vector2(dx, 2), center + Vector2(dx + 7, 19), Color(0.82, 0.71, 0.3, 0.9), 2.0, true)

func _draw_building(building: Dictionary, origin: Vector2) -> void:
	var definition := BuildingCatalog.get_data(StringName(building["type"]))
	var cell := Vector2i(int(building["cell_x"]), int(building["cell_y"]))
	var center := _cell_to_screen(cell, origin)
	var building_type := StringName(building["type"])
	var level := int(building.get("level", 1))
	var completed := bool(building["completed"])
	if completed:
		if BUILDING_ATLAS != null and BUILDING_ATLAS_INDEX.has(building_type):
			var visual_scale := 1.0 + float(level - 1) * 0.055
			_draw_grounded_atlas(BUILDING_ATLAS, BUILDING_ATLAS_CELLS, BUILDING_ATLAS_INDEX[building_type], center, BUILDING_VISUAL, visual_scale)
			if level >= 3:
				draw_arc(center + Vector2(0, -32), 48.0, 0.0, TAU, 40, Color(0.45, 0.82, 1.0, 0.62), 2.0, true)
		else:
			_draw_completed_building(building_type, center, level)
	else:
		_draw_construction_site(center, Color(definition["color"]))


func _draw_building_status(building: Dictionary, origin: Vector2) -> void:
	var definition := BuildingCatalog.get_data(StringName(building["type"]))
	var cell := Vector2i(int(building["cell_x"]), int(building["cell_y"]))
	var center := _cell_to_screen(cell, origin)
	var level := int(building.get("level", 1))
	var completed := bool(building["completed"])
	var name_text: String = definition["name"]
	_draw_map_label(center + Vector2(0, 29), "%s Lv.%d" % [name_text, level], 102, 14)
	if cell == selected_cell:
		draw_arc(center + Vector2(0, 2), 46.0, 0.0, TAU, 40, SELECTED_OUTLINE, 3.0, true)
	if not completed:
		var progress := 1.0 - float(building["remaining"]) / float(building["build_time"])
		draw_rect(Rect2(center + Vector2(-36, 31), Vector2(72, 7)), Color(0.08, 0.1, 0.1, 0.9), true)
		draw_rect(Rect2(center + Vector2(-35, 32), Vector2(70.0 * progress, 5)), Color(0.85, 0.67, 0.28, 1.0), true)
	elif bool(building.get("upgrading", false)):
		var upgrade_progress := 1.0 - float(building.get("upgrade_remaining", 0.0)) / float(building.get("upgrade_time", 1.0))
		draw_arc(center + Vector2(0, -34), 38.0, -PI, PI * (upgrade_progress * 2.0 - 1.0), 28, Color(0.42, 0.78, 0.88, 0.82), 2.5, true)
		draw_rect(Rect2(center + Vector2(-36, 31), Vector2(72, 7)), Color(0.08, 0.1, 0.1, 0.9), true)
		draw_rect(Rect2(center + Vector2(-35, 32), Vector2(70.0 * upgrade_progress, 5)), Color(0.38, 0.72, 0.95, 1.0), true)


func _draw_completed_building(building_type: StringName, center: Vector2, level: int) -> void:
	match building_type:
		&"disciple_quarters":
			_draw_house(center, Color(0.5, 0.31, 0.2, 1.0), level)
			draw_rect(Rect2(center + Vector2(18, -18), Vector2(13, 18)), Color(0.67, 0.49, 0.26, 1.0), true)
		&"lumber_yard":
			_draw_house(center + Vector2(-10, 1), Color(0.38, 0.28, 0.17, 1.0), level)
			for log_index: int in range(3):
				draw_rect(Rect2(center + Vector2(14, -4 - log_index * 7), Vector2(25, 5)), Color(0.55, 0.34, 0.18, 1.0), true)
				draw_circle(center + Vector2(38, -1 - log_index * 7), 3.0, Color(0.78, 0.58, 0.32, 1.0))
		&"spirit_mine":
			_draw_house(center + Vector2(-13, 3), Color(0.34, 0.36, 0.35, 1.0), level)
			for offset: Vector2 in [Vector2(14, -8), Vector2(25, -17), Vector2(33, -5)]:
				var crystal := PackedVector2Array([center + offset + Vector2(-6, 8), center + offset + Vector2(0, -13), center + offset + Vector2(7, 8)])
				draw_colored_polygon(crystal, Color(0.3, 0.72, 0.82, 1.0))
		&"spirit_field":
			var field := PackedVector2Array([center + Vector2(0, -30), center + Vector2(43, -8), center + Vector2(0, 14), center + Vector2(-43, -8)])
			draw_colored_polygon(field, Color(0.48, 0.5, 0.2, 1.0))
			for row: int in range(4):
				var x := -28.0 + float(row) * 18.0
				draw_line(center + Vector2(x, -15), center + Vector2(x + 12, 4), Color(0.83, 0.72, 0.3, 1.0), 2.2, true)
			if level >= 2:
				draw_line(center + Vector2(-31, -4), center + Vector2(23, -31), Color(0.4, 0.72, 0.7, 0.75), 3.0, true)
		&"training_ground":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -37), center + Vector2(45, -14), center + Vector2(0, 10), center + Vector2(-45, -14)]), Color(0.5, 0.51, 0.48, 1.0))
			draw_arc(center + Vector2(0, -14), 22.0, 0, TAU, 32, GOLD_ACCENT, 2.2, true)
			draw_line(center + Vector2(-8, -23), center + Vector2(8, -5), Color(0.25, 0.31, 0.29, 1.0), 2.0, true)
			draw_line(center + Vector2(8, -23), center + Vector2(-8, -5), Color(0.25, 0.31, 0.29, 1.0), 2.0, true)
			_draw_banner(center + Vector2(-35, -28), Color(0.22, 0.46, 0.48, 1.0))
			if level >= 2:
				_draw_banner(center + Vector2(35, -28), Color(0.22, 0.46, 0.48, 1.0))
		&"artifact_forge":
			_draw_house(center + Vector2(-6, 1), Color(0.4, 0.24, 0.17, 1.0), level)
			draw_rect(Rect2(center + Vector2(23, -52), Vector2(12, 42)), Color(0.27, 0.24, 0.22, 1.0), true)
			draw_circle(center + Vector2(0, -15), 8.0, Color(0.95, 0.42, 0.12, 0.9))
			draw_circle(center + Vector2(0, -17), 4.0, Color(1.0, 0.76, 0.28, 1.0))
		&"scripture_library":
			draw_rect(Rect2(center + Vector2(-29, -65), Vector2(58, 61)), WARM_WOOD.darkened(0.12), true)
			_draw_roof(center + Vector2(0, -65), 43.0, 21.0, ROOF_TEAL)
			_draw_roof(center + Vector2(0, -43), 37.0, 18.0, ROOF_TEAL.lightened(0.03))
			for y_offset: float in [-56.0, -34.0, -14.0]:
				draw_rect(Rect2(center + Vector2(-17, y_offset), Vector2(34, 4)), GOLD_ACCENT.darkened(0.25), true)
	if level >= 2 and building_type not in [&"spirit_field", &"training_ground"]:
		draw_rect(Rect2(center + Vector2(-45, -24), Vector2(12, 23)), WARM_WOOD.darkened(0.08), true)
	if level >= 3:
		draw_circle(center + Vector2(0, -58), 29.0, Color(0.37, 0.77, 0.72, 0.1))
		draw_arc(center + Vector2(0, -58), 29.0, 0, TAU, 32, Color(0.52, 0.85, 0.78, 0.5), 1.2, true)


func _draw_house(center: Vector2, wall_color: Color, level: int) -> void:
	var half_width := 31.0 + float(level - 1) * 3.0
	draw_rect(Rect2(center + Vector2(-half_width, -43), Vector2(half_width * 2.0, 42)), wall_color, true)
	draw_rect(Rect2(center + Vector2(-6, -23), Vector2(12, 22)), Color(0.2, 0.12, 0.08, 1.0), true)
	_draw_roof(center + Vector2(0, -44), half_width + 10.0, 23.0, ROOF_TEAL)


func _draw_roof(center: Vector2, half_width: float, height: float, color: Color) -> void:
	var roof := PackedVector2Array([
		center + Vector2(-half_width, 0),
		center + Vector2(0, -height),
		center + Vector2(half_width, 0),
		center + Vector2(0, height * 0.32),
	])
	draw_colored_polygon(roof, color)
	draw_line(center + Vector2(-half_width, 0), center + Vector2(half_width, 0), color.lightened(0.22), 1.7, true)


func _draw_banner(base: Vector2, color: Color) -> void:
	draw_line(base, base + Vector2(0, 38), Color(0.45, 0.37, 0.24, 1.0), 2.0, true)
	draw_colored_polygon(PackedVector2Array([base + Vector2(2, 2), base + Vector2(15, 7), base + Vector2(2, 19)]), color)


# 输入逻辑脚点、视觉配置与缩放，返回绘制矩形；无绘制或状态副作用，配置由本模块保证有效。
func get_grounded_rect(ground: Vector2, profile: Dictionary, visual_scale: float = 1.0) -> Rect2:
	var draw_size: Vector2 = profile["size"] * visual_scale
	return Rect2(ground - draw_size * Vector2(profile["foot"]), draw_size)


func _draw_grounded_atlas(texture: Texture2D, atlas_cells: Vector2i, atlas_cell: Vector2i,
	ground: Vector2, profile: Dictionary, visual_scale: float = 1.0) -> void:
	var source_cell_size := texture.get_size() / Vector2(atlas_cells)
	var source_rect := Rect2(Vector2(atlas_cell) * source_cell_size, source_cell_size)
	draw_texture_rect_region(texture, get_grounded_rect(ground, profile, visual_scale), source_rect)


func _draw_map_label(center: Vector2, text: String, width: float, font_size: int = 16) -> void:
	var plaque := Rect2(center + Vector2(-width * 0.5, -font_size - 3), Vector2(width, font_size + 8))
	draw_style_box(_map_label_style(), plaque)
	draw_string(ThemeDB.fallback_font, center + Vector2(-width * 0.5, 1), text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, Color(0.98, 0.96, 0.86, 1.0))


func _map_label_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.12, 0.2, 0.88)
	style.border_color = Color(0.82, 0.66, 0.3, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style


func _draw_construction_site(center: Vector2, color: Color) -> void:
	draw_rect(Rect2(center + Vector2(-31, -35), Vector2(62, 34)), Color(color, 0.26), true)
	for x_offset: float in [-29.0, 0.0, 29.0]:
		draw_line(center + Vector2(x_offset, -48), center + Vector2(x_offset, 4), Color(0.5, 0.34, 0.2, 1.0), 3.0, true)
	draw_line(center + Vector2(-36, -39), center + Vector2(36, -39), Color(0.61, 0.43, 0.24, 1.0), 3.0, true)
	draw_line(center + Vector2(-34, -31), center + Vector2(28, -9), Color(0.61, 0.43, 0.24, 0.9), 2.0, true)


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

