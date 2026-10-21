extends Control

const SectProjectionData = preload("res://scripts/world/sect_projection.gd")
const SceneLayout = preload("res://scripts/world/sect_scene_layout.gd")
const TerrainSurface = preload("res://scripts/world/sect_terrain_surface.gd")
const DISTANT_CLOUDS: Texture2D = preload("res://assets/environment/sect_cloud_distance.png")
const TERRAIN_PAVING: Texture2D = preload("res://assets/environment/sect_limestone_paving.png")
const TERRAIN_CLIFF: Texture2D = preload("res://assets/environment/sect_cliff_material.png")

const ResourceCatalogData = preload("res://scripts/data/resource_catalog.gd")
const TerritoryCatalogData = preload("res://scripts/data/territory_catalog.gd")
const GARDEN_POND: Texture2D = preload("res://assets/environment/hall-garden-pond.png")
const QUARTERS_SAMPLE: Texture2D = preload("res://assets/buildings/disciple-quarters-sample.png")
const MAIN_HALL_SAMPLE: Texture2D = preload("res://assets/buildings/main-hall-sample.png")
const MAP_BACKDROP: Texture2D = preload("res://assets/environment/sect_open_terraces.png")
const BUILDING_ATLAS: Texture2D = preload("res://assets/buildings/sect_buildings_atlas.png")
const LANDMARK_ATLAS: Texture2D = preload("res://assets/environment/sect_landmarks_atlas.png")

signal hall_selected
signal resource_selected(resource_data: Dictionary)
signal placement_requested(building_type: StringName, cell: Vector2i)
signal building_selected(building: Dictionary)
signal region_selected(region_id: StringName)

var GRID_SIZE: Vector2i:
	get:
		return TerritoryCatalogData.MAP_SIZE
const TILE_SIZE := SectProjectionData.TILE_SIZE
const MAIN_HALL_CELL := SectProjectionData.MAIN_HALL_CELL
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
const MAIN_HALL_VISUAL := {"size": Vector2(390, 390), "foot": Vector2(0.5, 0.82), "entrance": Vector2(0.28, 0.79), "shadow_offset": Vector2(12, 17)}
const QUARTERS_VISUAL := {"size": Vector2(172, 172), "foot": Vector2(0.5, 0.83), "entrance": Vector2(0.31, 0.805)}
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
var hovered_position := Vector2.ZERO
var placement_building: StringName = &""
# 命中检测缓存解压后的图像；只在鼠标查询时采样，不在每帧重复从GPU读取。
var hit_images: Dictionary = {}
var unified_building_atlas: Texture2D = preload("res://assets/buildings/sect-buildings-unified.png")
var courtyard_atlas: Texture2D = preload("res://assets/environment/courtyard_fusion_atlas.png")
var structured_terrain := false # 独立局部样板开关，未验收前不替换全图。
var terrain_detail_stage := 3 # 审图：0地基、1入口和外沿阶、2栏杆、3园林。
var visual_plane_lift := 0.0 # 仅验证共面视觉标高，默认0；不写建筑或存档。
# 生成图并非均匀四格，按实际透明边界取样，避免把相邻素材带进运行图。
const COURTYARD_SOURCES := {
	"hall": Rect2(0, 64, 940, 510), "wing": Rect2(955, 182, 581, 378),
	"stairs": Rect2(80, 575, 730, 410), "rail": Rect2(820, 615, 640, 380),
}
const UNIFIED_ATLAS_PATH := "res://assets/buildings/sect-buildings-unified.png"
const UNIFIED_INDICES := {
	&"lumber_yard": Vector2i(0, 0), &"spirit_mine": Vector2i(1, 0),
	&"spirit_field": Vector2i(2, 0), &"training_ground": Vector2i(0, 1),
	&"artifact_forge": Vector2i(1, 1), &"scripture_library": Vector2i(2, 1),
}
const BUILDING_WIDTHS := {
	&"lumber_yard": 178.0, &"spirit_mine": 168.0, &"spirit_field": 192.0,
	&"training_ground": 194.0, &"artifact_forge": 180.0, &"scripture_library": 166.0,
}


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
	if courtyard_atlas == null:
		_draw_sample_garden(origin)
	_draw_courtyard_ground(origin)
	_draw_building_approaches(origin)
	if not is_grid_visible():
		_draw_locked_regions(origin)
		_draw_hall_plaza(origin)
		return
	for sum_index: int in range(GRID_SIZE.x + GRID_SIZE.y - 1):
		for x: int in range(GRID_SIZE.x):
			var y := sum_index - x
			if y >= 0 and y < GRID_SIZE.y:
				_draw_tile(Vector2i(x, y), origin)
	# 正式底图已有道路，不再叠一套独立菱形石板；无底图时才使用程序道路。
	if MAP_BACKDROP == null:
		_draw_region_connections(origin)
	_draw_hall_plaza(origin)


func _draw_building_approaches(origin: Vector2) -> void:
	if structured_terrain:
		return # 建筑自带入口直接落在共享地面上，不重复补台阶或小平台。
	# 短石径随建筑脚点落地，只做地表衔接；不连接成长道路、不加入占地。
	var wing := get_courtyard_wing(origin) if courtyard_atlas != null else {}
	for building: Dictionary in GameState.buildings:
		if not wing.is_empty() and int(building["instance_id"]) == int(wing["instance_id"]):
			continue
		if not bool(building["completed"]):
			continue
		var kind := StringName(building["type"])
		if kind in [&"spirit_field", &"training_ground"]:
			continue
		var cell := Vector2i(building["cell_x"], building["cell_y"])
		var foot := _cell_to_screen(cell, origin)
		for step: int in range(3):
			var center := foot + Vector2(0, 9 + step * 9)
			var slab := PackedVector2Array([center + Vector2(0, -7), center + Vector2(21, 0),
				center + Vector2(0, 7), center + Vector2(-21, 0)])
			draw_colored_polygon(slab, Color(0.88, 0.85, 0.75, 0.50))
			draw_line(center + Vector2(-21, 0), center + Vector2(0, 7), Color(0.41, 0.43, 0.37, 0.22), 1.0, true)


func get_courtyard_wing(origin: Vector2) -> Dictionary:
	var hall := _cell_to_screen(MAIN_HALL_CELL, origin)
	var best: Dictionary = {}
	var best_distance := 520.0 * 520.0
	for building: Dictionary in GameState.buildings:
		if not bool(building["completed"]) or StringName(building["type"]) not in [&"disciple_quarters", &"scripture_library"]:
			continue
		var foot := _cell_to_screen(Vector2i(building["cell_x"], building["cell_y"]), origin)
		if foot.x > hall.x - 160.0:
			continue
		var distance := foot.distance_squared_to(hall)
		if distance < best_distance or (is_equal_approx(distance, best_distance) and not best.is_empty() and int(building["instance_id"]) < int(best["instance_id"])):
			best = building
			best_distance = distance
	return best


func get_courtyard_plan(origin: Vector2) -> Dictionary:
	var wing := get_courtyard_wing(origin)
	var plan := TerrainSurface.make_plan(origin)
	plan["wing_id"] = int(wing.get("instance_id", 0))
	return plan


func _draw_courtyard_ground(origin: Vector2) -> void:
	if structured_terrain:
		TerrainSurface.draw_surface(self, origin, TERRAIN_PAVING, TERRAIN_CLIFF)
		if terrain_detail_stage >= 1:
			for approach: Dictionary in get_terrain_approaches(origin):
				TerrainSurface.draw_approach(self, approach["start"], approach["end"], approach["width"])
			TerrainSurface.draw_edge_stairs(self, origin, TERRAIN_PAVING, TERRAIN_CLIFF)


func get_courtyard_foreground(origin: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not structured_terrain or terrain_detail_stage < 2:
		return result
	var plan := get_courtyard_plan(origin)
	for entry: Dictionary in plan["foreground"].slice(0, 1): # 本轮只审一段栏杆，不一次铺满。
		var foot: Vector2 = entry["foot"]
		var width := float(entry["width"])
		var rect := Rect2(foot - Vector2(width * 0.5, width * 380.0 / 640.0 * 0.65), Vector2(width, width * 380.0 / 640.0))
		var blocked := false
		# 外缘纯视觉栏杆：任何旧建筑或新施工进入落点时均退让。
		for building: Dictionary in GameState.buildings:
			if rect.grow(4).intersects(_visual_base(get_building_visual_rect(building, origin))):
				blocked = true
				break
		if not blocked:
			result.append({"kind": "decor", "key": entry["key"], "cell": _screen_to_cell(foot, origin),
				"depth": (foot.y - origin.y) / (TILE_SIZE.y * 0.5 * SceneLayout.GROUND_SPACING),
				"rect": rect})
	if terrain_detail_stage >= 3:
		var garden := get_structured_garden_rect(origin)
		if garden.has_area():
			var foot := garden.position + garden.size * Vector2(0.5, 0.8)
			result.append({"kind": "decor", "key": "courtyard:garden", "cell": _screen_to_cell(foot, origin),
				"depth": (foot.y - origin.y) / (TILE_SIZE.y * 0.5 * SceneLayout.GROUND_SPACING), "rect": garden})
	return result


func _draw_courtyard_foreground(item: Dictionary) -> void:
	var tint := Color(1, 1, 1, 0.32) if is_grid_visible() else Color.WHITE
	if item["key"] == "courtyard:garden":
		draw_texture_rect(GARDEN_POND, item["rect"], false, tint)
	else:
		draw_texture_rect_region(courtyard_atlas, item["rect"], COURTYARD_SOURCES["rail"], tint)


# 无入参，返回是否显示完整建造网格；只读，不改变地图、资源或存档。
func is_grid_visible() -> bool:
	return placement_building != &""


func _draw_locked_regions(origin: Vector2) -> void:
	# 常态仅绘制整片锁区的轻雾与边界，不能用96条格线把经营场景变成编辑器。
	for region_id: StringName in TerritoryCatalogData.REGION_IDS:
		if String(region_id) in GameState.unlocked_regions:
			continue
		var region := TerritoryCatalogData.get_data(region_id)
		var first: Vector2i = region["origin"]
		var extent: Vector2i = region["size"]
		var points := PackedVector2Array([
			_cell_to_screen(first, origin) + Vector2(0, -TILE_SIZE.y * 0.5) * SceneLayout.GROUND_SPACING,
			_cell_to_screen(first + Vector2i(extent.x - 1, 0), origin) + Vector2(TILE_SIZE.x * 0.5, 0) * SceneLayout.GROUND_SPACING,
			_cell_to_screen(first + extent - Vector2i.ONE, origin) + Vector2(0, TILE_SIZE.y * 0.5) * SceneLayout.GROUND_SPACING,
			_cell_to_screen(first + Vector2i(0, extent.y - 1), origin) - Vector2(TILE_SIZE.x * 0.5, 0) * SceneLayout.GROUND_SPACING,
		])
		draw_colored_polygon(points, Color(0.72, 0.80, 0.79, 0.12))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]),
			Color(0.78, 0.83, 0.73, 0.3), 1.2, true)
		var center := (points[0] + points[2]) * 0.5
		_draw_map_label(center + Vector2(0, 26), "%s · 未解锁" % region["name"], 212, 16)


func _draw_hall_plaza(origin: Vector2) -> void:
	if courtyard_atlas != null:
		return
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
	if courtyard_atlas != null:
		for decor: Dictionary in get_courtyard_foreground(_map_origin()):
			items.append(decor)
	# 等距投影脚点y与x+y成正比；同深度按x及稳定ID排序，避免读档/建造顺序改变遮挡。
	items.sort_custom(_is_world_item_before)
	return items


func _is_world_item_before(first: Dictionary, second: Dictionary) -> bool:
	var first_cell: Vector2i = first["cell"]
	var second_cell: Vector2i = second["cell"]
	var first_depth := float(first.get("depth", first_cell.x + first_cell.y))
	var second_depth := float(second.get("depth", second_cell.x + second_cell.y))
	if first_depth != second_depth:
		return first_depth < second_depth
	if first_cell.x != second_cell.x:
		return first_cell.x < second_cell.x
	return String(first["key"]) < String(second["key"])


func _draw_shadow_layer(items: Array[Dictionary], origin: Vector2) -> void:
	# 所有接地影先于建筑主体，防止后绘制建筑的影子盖在前一栋墙面上。
	var hall_frame := get_hall_ground_frame(origin)
	var hall_center: Vector2 = hall_frame["foot"]
	# 与左上光源对应的右下接地影独立于位图，后续可按底座轮廓校准。
	draw_set_transform(hall_frame["shadow"], 0.0, Vector2(1.0, 0.27))
	draw_circle(Vector2.ZERO, 145.0, Color(0.08, 0.12, 0.13, 0.12))
	draw_set_transform(hall_center + Vector2(0, 10), 0.0, Vector2(1.0, 0.17))
	draw_circle(Vector2.ZERO, 130.0, Color(0.06, 0.09, 0.10, 0.08))
	draw_set_transform(Vector2.ZERO)
	for item: Dictionary in items:
		if item["kind"] == "building":
			var frame := get_building_ground_frame(item["data"], origin)
			var spec := get_building_visual(StringName(item["data"]["type"]))
			var radius := float(spec["profile"]["size"].x) * 0.27
			draw_set_transform(frame["shadow"], 0.0, Vector2(1.0, 0.38))
			draw_circle(Vector2.ZERO, radius, Color(0.07, 0.10, 0.11, 0.13))
			draw_set_transform(Vector2.ZERO)


func _draw_world_layer(items: Array[Dictionary], origin: Vector2) -> void:
	for item: Dictionary in items:
		match item["kind"]:
			"hall": _draw_main_hall(origin)
			"building": _draw_building(item["data"], origin)
			"resource": _draw_resource(item["data"], origin)
			"decor": _draw_courtyard_foreground(item)


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
	if structured_terrain:
		draw_texture_rect(DISTANT_CLOUDS, Rect2(Vector2.ZERO, size), false)
		return
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
		center + Vector2(0.0, -TILE_SIZE.y * 0.5) * SceneLayout.GROUND_SPACING,
		center + Vector2(TILE_SIZE.x * 0.5, 0.0) * SceneLayout.GROUND_SPACING,
		center + Vector2(0.0, TILE_SIZE.y * 0.5) * SceneLayout.GROUND_SPACING,
		center + Vector2(-TILE_SIZE.x * 0.5, 0.0) * SceneLayout.GROUND_SPACING,
	])


func _draw_tile(cell: Vector2i, origin: Vector2) -> void:
	var center := _cell_to_screen(cell, origin)
	var points := _cell_points(center)
	var feedback := get_placement_feedback(cell)
	var fill := Color(0.43, 0.68, 0.53, 0.08)
	var outline := Color(0.57, 0.74, 0.60, 0.38)
	if feedback["category"] == "locked":
		fill = Color(0.65, 0.56, 0.32, 0.12)
		outline = Color(0.79, 0.70, 0.45, 0.45)
	elif not feedback["is_valid"]:
		fill = Color(0.27, 0.49, 0.66, 0.14)
		outline = Color(0.38, 0.63, 0.79, 0.55)
	draw_colored_polygon(points, fill)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), outline, 1.0, true)


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
		hovered_position = event.position
		hovered_cell = _screen_to_cell(event.position, _map_origin())
		if placement_building == &"":
			var visible_building := _pick_visual_building(event.position, _map_origin())
			if not visible_building.is_empty():
				hovered_cell = Vector2i(int(visible_building["cell_x"]), int(visible_building["cell_y"]))
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var clicked_cell := _screen_to_cell(event.position, _map_origin())
		# 建造预览仍只判逻辑格；普通选择先按实际可见贴图找建筑，屋顶高度不再造成点偏。
		if placement_building == &"":
			var visible_building := _pick_visual_building(event.position, _map_origin())
			if not visible_building.is_empty():
				selected_cell = Vector2i(int(visible_building["cell_x"]), int(visible_building["cell_y"]))
				building_selected.emit(visible_building)
				queue_redraw()
				accept_event()
				return
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

		if placement_building == &"" and (clicked_cell == MAIN_HALL_CELL or not _is_hall_occluding_active_building(_map_origin())):
			var hall_rect: Rect2 = get_hall_ground_frame(_map_origin())["rect"]
			if clicked_cell == MAIN_HALL_CELL or _is_sprite_hit(MAIN_HALL_SAMPLE,
				Rect2(Vector2.ZERO, MAIN_HALL_SAMPLE.get_size()), hall_rect, event.position):
				selected_cell = MAIN_HALL_CELL
				hall_selected.emit()
				queue_redraw()
				accept_event()
				return


func _is_sprite_hit(texture: Texture2D, source_rect: Rect2, destination: Rect2, point: Vector2) -> bool:
	if not destination.has_point(point):
		return false
	var texture_id := texture.get_instance_id()
	if not hit_images.has(texture_id):
		hit_images[texture_id] = texture.get_image()
	var image: Image = hit_images[texture_id]
	var uv := (point - destination.position) / destination.size
	var pixel := Vector2i(source_rect.position + source_rect.size * uv)
	pixel.x = clampi(pixel.x, 0, image.get_width() - 1)
	pixel.y = clampi(pixel.y, 0, image.get_height() - 1)
	# 排除低透明阴影与边缘光晕，避免透明画布拦截邻格操作。
	return image.get_pixelv(pixel).a > 0.12


func _pick_visual_building(point: Vector2, origin: Vector2) -> Dictionary:
	var items := get_world_draw_items()
	items.reverse()
	# 与绘制顺序相反查询；主殿/资源点挡在前面时仍交给原地面格交互，不穿透抢选后方屋顶。
	for item: Dictionary in items:
		if item["kind"] == "decor":
			continue # 前景纯视觉，不拦截屋顶/原地面格选择。
		var ground := _cell_to_screen(item["cell"], origin)
		if item["kind"] == "hall":
			if not _is_hall_occluding_active_building(origin) and _is_sprite_hit(
				MAIN_HALL_SAMPLE, Rect2(Vector2.ZERO, MAIN_HALL_SAMPLE.get_size()),
				get_hall_ground_frame(origin)["rect"], point
			):
				return {}
		elif item["kind"] == "resource":
			var cell_size := LANDMARK_ATLAS.get_size() / Vector2(LANDMARK_ATLAS_CELLS)
			var source := Rect2(Vector2(RESOURCE_ATLAS_INDEX[item["data"]["site_id"]]) * cell_size, cell_size)
			if _is_sprite_hit(LANDMARK_ATLAS, source, get_grounded_rect(ground, RESOURCE_VISUAL), point):
				return {}
		elif bool(item["data"]["completed"]):
			var building: Dictionary = item["data"]
			var spec := get_building_visual(StringName(building["type"]))
			if _is_sprite_hit(spec["texture"], spec["source"], get_building_visual_rect(building, origin), point):
				return building
	return {}


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


# 输入逻辑格，返回原有空间合法性；委托同一只读反馈入口，避免显示与放置规则分叉。
func is_placement_valid(cell: Vector2i) -> bool:
	return bool(get_placement_feedback(cell)["is_valid"])


# 输入逻辑格，返回is_valid、category、reason；只读，不检查价格或增加软分区限制。
func get_placement_feedback(cell: Vector2i) -> Dictionary:
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID_SIZE.x or cell.y >= GRID_SIZE.y:
		return {"is_valid": false, "category": "outside", "reason": "超出地图边界"}
	if not GameState.is_cell_unlocked(cell):
		var region := TerritoryCatalogData.get_data(TerritoryCatalogData.get_region_for_cell(cell))
		return {"is_valid": false, "category": "locked", "reason": "%s尚未解锁" % region["name"]}
	if GameState.is_cell_occupied(cell):
		var reason := "宗门主殿固定占地" if cell == MAIN_HALL_CELL else "已有建筑占用"
		return {"is_valid": false, "category": "occupied", "reason": reason}
	for resource: Dictionary in resource_nodes:
		if resource["cell"] == cell:
			return {"is_valid": false, "category": "resource", "reason": "%s资源点占用" % resource["name"]}
	return {"is_valid": true, "category": "available", "reason": "可建造"}


func _map_origin() -> Vector2:
	return SceneLayout.origin(size) - Vector2(0, visual_plane_lift if structured_terrain else 0.0)


func _cell_to_screen(cell: Vector2i, origin: Vector2) -> Vector2:
	return SceneLayout.project_continuous(Vector2(cell), origin)


func _screen_to_cell(screen_position: Vector2, origin: Vector2) -> Vector2i:
	return SectProjectionData.unproject(SceneLayout.to_projection(screen_position, origin), origin, TerritoryCatalogData.get_map_bounds())


func _draw_main_hall(origin: Vector2) -> void:
	var center := _cell_to_screen(MAIN_HALL_CELL, origin)
	if MAIN_HALL_SAMPLE != null:
		var tint := Color(1, 1, 1, 0.28) if _is_hall_occluding_active_building(origin) else Color.WHITE
		draw_texture_rect(MAIN_HALL_SAMPLE, get_hall_ground_frame(origin)["rect"], false, tint)
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
	var hall_rect: Rect2 = get_hall_ground_frame(origin)["rect"]
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
		var spec := get_building_visual(building_type)
		draw_texture_rect_region(spec["texture"], get_building_visual_rect(building, origin), spec["source"])
	else:
		_draw_construction_site(center, Color(definition["color"]))


func _draw_building_status(building: Dictionary, origin: Vector2) -> void:
	var definition := BuildingCatalog.get_data(StringName(building["type"]))
	var cell := Vector2i(int(building["cell_x"]), int(building["cell_y"]))
	var center := _cell_to_screen(cell, origin)
	var level := int(building.get("level", 1))
	var completed := bool(building["completed"])
	var name_text: String = definition["name"]
	# 完工且被主殿遮住的旧建筑平时不隔着屋顶显示标签；悬停/选中仍透显并保留信息。
	var hall_rect: Rect2 = get_hall_ground_frame(origin)["rect"]
	if completed and cell.x + cell.y <= MAIN_HALL_CELL.x + MAIN_HALL_CELL.y and hall_rect.has_point(center):
		if cell != selected_cell and cell != hovered_cell:
			return
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
	if placement_building == &"":
		# 普通模式只保留当前选中格的轮廓，不显示整张逻辑网格。
		if selected_cell != Vector2i(-1, -1):
			var points := _cell_points(_cell_to_screen(selected_cell, origin))
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]),
				SELECTED_OUTLINE, 2.0, true)
		return
	if hovered_cell == Vector2i(-1, -1) and hovered_position == Vector2.ZERO:
		return
	var feedback := get_placement_feedback(hovered_cell)
	var is_valid := bool(feedback["is_valid"])
	var center := hovered_position if feedback["category"] == "outside" else _cell_to_screen(hovered_cell, origin)
	if feedback["category"] != "outside":
		var spec := get_building_visual(placement_building)
		var tint := Color(1, 1, 1, 0.42) if is_valid else Color(1, 0.35, 0.25, 0.28)
		draw_texture_rect_region(spec["texture"], get_preview_ground_frame(hovered_cell, origin)["rect"], spec["source"], tint)
		var preview_color := Color(0.35, 0.82, 0.48, 0.4) if is_valid else Color(0.89, 0.30, 0.25, 0.4)
		var points := _cell_points(center)
		draw_colored_polygon(points, preview_color)
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]),
			preview_color.lightened(0.3), 3.0, true)
		if not is_valid:
			# 红色配叉形和原因文字，不能仅靠颜色区分占用与可建。
			draw_line(center + Vector2(-9, -7), center + Vector2(9, 7), PAPER_WHITE, 2.0, true)
			draw_line(center + Vector2(9, -7), center + Vector2(-9, 7), PAPER_WHITE, 2.0, true)
	var status := "可建造：%s" % BuildingCatalog.get_data(placement_building)["name"] if is_valid else "不可建造：%s" % feedback["reason"]
	# 提示始终位于地图安全范围，越界时跟随鼠标位置，不用无效格坐标投影。
	var label_center := Vector2(clampf(center.x, 158.0, size.x - 158.0), clampf(center.y - 42.0, 150.0, size.y - 130.0))
	_draw_map_label(label_center, status, 304, 18)


func _draw_sample_garden(origin: Vector2) -> void:
	# 样板地景只画在建筑/网格下，不加入占地或交互集合，满图旧档仍可正常使用。
	var hall := _cell_to_screen(MAIN_HALL_CELL, origin)
	var pond_rect := get_garden_rect(origin)
	if pond_rect.has_area():
		draw_texture_rect(GARDEN_POND, pond_rect, false)
	var end := hall + Vector2(50, 120)
	draw_colored_polygon(PackedVector2Array([hall + Vector2(-23, 16), hall + Vector2(23, 16),
		end + Vector2(23, 0), end - Vector2(23, 0)]), Color(0.94, 0.91, 0.82, 0.30))


func get_garden_rect(origin: Vector2) -> Rect2:
	var hall := _cell_to_screen(MAIN_HALL_CELL, origin)
	# 地景向既有/新建建筑让位，不改任何合法格；没有空处就只保留既有底图园林。
	for offset: Vector2 in [Vector2(-195, 105), Vector2(-40, 180)]:
		var pond := hall + offset
		var pond_rect := Rect2(pond - Vector2(115, 69), Vector2(230, 138))
		var occupied_visually := false
		for building: Dictionary in GameState.buildings:
			# 检查台基所在的下半部而非整片屋顶；保留正常的前后遮挡，避免池水穿入墙脚。
			var visual := get_building_visual_rect(building, origin)
			var base := Rect2(visual.position + Vector2(visual.size.x * 0.12, visual.size.y * 0.58),
				Vector2(visual.size.x * 0.76, visual.size.y * 0.34))
			if pond_rect.grow(8).intersects(base):
				occupied_visually = true
				break
		if not occupied_visually:
			return pond_rect
	return Rect2()


# 绘制、alpha命中、建造预览和小卡共用配置；等级只缩放视觉，不改占地。
func get_building_visual(building_type: StringName) -> Dictionary:
	if building_type == &"disciple_quarters":
		return {"texture": QUARTERS_SAMPLE, "source": Rect2(Vector2.ZERO, QUARTERS_SAMPLE.get_size()), "profile": QUARTERS_VISUAL}
	var texture := unified_building_atlas if unified_building_atlas != null else BUILDING_ATLAS
	var cells := Vector2(3, 2) if unified_building_atlas != null else Vector2(BUILDING_ATLAS_CELLS)
	var index: Vector2i = UNIFIED_INDICES[building_type] if unified_building_atlas != null else BUILDING_ATLAS_INDEX[building_type]
	var frame := texture.get_size() / cells
	var width := float(BUILDING_WIDTHS[building_type])
	var foot := Vector2(0.5, 0.80) if unified_building_atlas != null else Vector2(BUILDING_VISUAL["foot"])
	return {"texture": texture, "source": Rect2(Vector2(index) * frame, frame),
		"profile": {"size": Vector2(width, width * frame.y / frame.x), "foot": foot}}


func get_building_visual_rect(building: Dictionary, origin: Vector2) -> Rect2:
	return get_building_ground_frame(building, origin)["rect"]


func get_building_ground_frame(building: Dictionary, origin: Vector2) -> Dictionary:
	var spec := get_building_visual(StringName(building["type"]))
	var cell := Vector2i(building["cell_x"], building["cell_y"])
	return SceneLayout.ground_frame(Vector2(cell), origin, spec["profile"],
		1.0 + float(int(building.get("level", 1)) - 1) * 0.055)


func get_hall_ground_frame(origin: Vector2) -> Dictionary:
	return SceneLayout.ground_frame(Vector2(MAIN_HALL_CELL), origin, MAIN_HALL_VISUAL)


func get_preview_ground_frame(cell: Vector2i, origin: Vector2) -> Dictionary:
	return SceneLayout.ground_frame(Vector2(cell), origin, get_building_visual(placement_building)["profile"])


func _terrain_obstacles(origin: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var hall: Rect2 = get_hall_ground_frame(origin)["rect"]
	result.append({"owner": "hall", "rect": _visual_base(hall)})
	for building: Dictionary in GameState.buildings:
		result.append({"owner": str(building["instance_id"]), "rect": _visual_base(get_building_visual_rect(building, origin))})
	for resource: Dictionary in resource_nodes:
		var rect := get_grounded_rect(_cell_to_screen(resource["cell"], origin), RESOURCE_VISUAL)
		result.append({"owner": String(resource["site_id"]), "rect": _visual_base(rect)})
	return result


func _visual_base(rect: Rect2) -> Rect2:
	return Rect2(rect.position + rect.size * Vector2(0.12, 0.58), rect.size * Vector2(0.76, 0.34))


func get_terrain_approaches(origin: Vector2) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = [{"owner": "hall", "frame": get_hall_ground_frame(origin), "width": 52.0, "length": 78.0}]
	var wing := get_courtyard_wing(origin)
	if not wing.is_empty():
		candidates.append({"owner": str(wing["instance_id"]), "frame": get_building_ground_frame(wing, origin), "width": 27.0, "length": 48.0})
	var result: Array[Dictionary] = []
	var obstacles := _terrain_obstacles(origin)
	for candidate: Dictionary in candidates:
		var start: Vector2 = candidate["frame"]["entrance"]
		var finish := start + Vector2(-1, 0.5) * float(candidate["length"])
		var quad := TerrainSurface.approach_quad(start, finish, candidate["width"])
		var blocked := false
		for obstacle: Dictionary in obstacles:
			if obstacle["owner"] == candidate["owner"]:
				continue # 仅自身入口接缝允许延伸至自身台基，其他构件必须让位。
			if Geometry2D.intersect_polygons(quad, _rect_polygon(obstacle["rect"].grow(4))).size() > 0:
				blocked = true
				break
		if not blocked:
			result.append({"start": start, "end": finish, "width": candidate["width"], "owner": candidate["owner"], "quad": quad})
	return result


func _rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])


func get_structured_garden_rect(origin: Vector2) -> Rect2:
	var hall: Vector2 = get_hall_ground_frame(origin)["foot"]
	var top: PackedVector2Array = TerrainSurface.make_plan(origin)["top"]
	for offset: Vector2 in [Vector2(180, 145), Vector2(240, 75)]:
		var garden := Rect2(hall + offset - Vector2(105, 63), Vector2(210, 126))
		var blocked := false
		for corner: Vector2 in _rect_polygon(garden):
			if not Geometry2D.is_point_in_polygon(corner, top):
				blocked = true
		for obstacle: Dictionary in _terrain_obstacles(origin):
			if garden.grow(8).intersects(obstacle["rect"]):
				blocked = true
		for approach: Dictionary in get_terrain_approaches(origin):
			if Geometry2D.intersect_polygons(_rect_polygon(garden.grow(8)), approach["quad"]).size() > 0:
				blocked = true
		if not blocked:
			return garden
	return Rect2() # 没有安全位置就隐藏地景，绝不搬玩家建筑或减少合法格。
