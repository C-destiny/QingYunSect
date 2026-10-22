extends RefCounted

const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
# 原图像素坐标的纯视觉构件；不修改地形格、玩家建筑或存档。
const DETAILS := [
	{"kind": "pine", "foot": Vector2(525, 380), "width": 100.0},
	{"kind": "pond", "foot": Vector2(1225, 705), "width": 145.0},
	{"kind": "pine", "foot": Vector2(1280, 720), "width": 88.0},
]
const SAMPLE_DETAILS := [
	# 局部样板：少量前后景包住台基，避开正门和主路；其余院落不推广。
	{"kind": "pine", "foot": Vector2(591, 252), "width": 112.0},
	{"kind": "pine", "foot": Vector2(884, 276), "width": 98.0},
	{"kind": "pine", "foot": Vector2(1064, 739), "width": 108.0},
	{"kind": "pine", "foot": Vector2(918, 735), "width": 82.0},
	{"kind": "pine", "foot": Vector2(940, 664), "width": 92.0},
]

static func items(map: Control) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if map.fixed_garden_scene:
		return result # 新背景已有同风格园林，撤掉旧版重复盆景/水池贴片。
	var scale_value := Layout.world_rect(map.size).size.x / Layout.ART_SIZE.x
	var details: Array = DETAILS.duplicate()
	if map.fixed_courtyard_blend:
		details.append_array(SAMPLE_DETAILS)
	for detail: Dictionary in details:
		var texture: Texture2D = map.GARDEN_PINE if detail["kind"] == "pine" else map.GARDEN_POND
		var extent := Vector2(detail["width"], float(detail["width"]) * texture.get_height() / texture.get_width()) * scale_value
		var foot := Layout.point(detail["foot"], map.size)
		var rect := Rect2(foot - extent * Vector2(0.5, 0.84), extent)
		result.append({"kind": detail["kind"], "rect": rect, "foot": foot, "depth": foot.y})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["depth"] < b["depth"])
	return result

static func draw_item(map: Control, item: Dictionary) -> void:
	var texture: Texture2D = map.GARDEN_PINE if item["kind"] == "pine" else map.GARDEN_POND
	map.draw_texture_rect(texture, item["rect"], false)

static func shadow(map: Control, foot: Vector2, width: float, depth: float, opacity: float) -> void:
	# 外浅内深的接地影，方向与背景左上光一致；避免单块黑椭圆。
	for ring: int in range(8, 0, -1):
		var extent := Vector2(width, depth) * (0.62 + float(ring) * 0.065)
		map.draw_set_transform(foot, 0, Vector2(1, extent.y / extent.x))
		map.draw_circle(Vector2.ZERO, extent.x, Color(0.10, 0.16, 0.16, opacity / 8.0))
	map.draw_set_transform(Vector2.ZERO)

static func draw_ground(map: Control, state: Node) -> void:
	for kind: StringName in Layout.SITES:
		var occupied := kind == &"hall"
		for building: Dictionary in Layout.members(state, kind):
			occupied = occupied or bool(building["completed"])
		if not occupied:
			continue
		var profile: Dictionary = map.MAIN_HALL_VISUAL if kind == &"hall" else map.get_building_visual(kind)["profile"]
		var frame: Dictionary = Layout.frame(kind, map.size, profile)
		var scale_value := float(frame["scale"])
		var width := float(Layout.SITES[kind]["width"]) * scale_value
		if map.fixed_garden_scene:
			shadow(map, frame["foot"] + Vector2(5, 3) * scale_value, width * 0.34, width * 0.06, 0.12)
			continue # 不再用独立灰石片/苔草斑覆盖新背景。
		if map.fixed_courtyard_blend and kind in [&"hall", &"disciple_quarters"]:
			# 宽而浅的环境影加近台基接触影，不用孤立的深黑椭圆托住整栋楼。
			shadow(map, frame["foot"] + Vector2(12, 7) * scale_value, width * 0.43, width * 0.10, 0.14)
			shadow(map, frame["foot"] + Vector2(2, 2) * scale_value, width * 0.29, width * 0.045, 0.16)
			continue # 样板使用连续入口铺装，取消原先孤立的四边形短石。
		shadow(map, frame["foot"] + Vector2(10, 7) * scale_value, width * 0.38, width * 0.095, 0.22)
		# 只补门前短接地石，不重铺台基，不跨背景长阶或悬崖。
		var entrance: Vector2 = frame["entrance"]
		var horizontal := Vector2(14, 5) * scale_value
		var forward := Vector2(-9, 5) * scale_value
		var points := PackedVector2Array([entrance - horizontal, entrance + horizontal, entrance + horizontal + forward, entrance - horizontal + forward])
		map.draw_colored_polygon(points, Color("c9c3a9"))
		map.draw_polyline(PackedVector2Array([points[3], points[2], points[1]]), Color(0.38, 0.41, 0.35, 0.35), scale_value, true)
	for item: Dictionary in items(map):
		shadow(map, item["foot"], item["rect"].size.x * 0.32, item["rect"].size.y * 0.065, 0.16)
