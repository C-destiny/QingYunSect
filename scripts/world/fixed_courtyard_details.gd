extends RefCounted

const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
# 原图像素坐标的纯视觉构件；不修改地形格、玩家建筑或存档。
const DETAILS := [
	{"kind": "pine", "foot": Vector2(525, 380), "width": 100.0},
	{"kind": "pond", "foot": Vector2(1225, 705), "width": 145.0},
	{"kind": "pine", "foot": Vector2(1280, 720), "width": 88.0},
]

static func items(map: Control) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var scale_value := Layout.world_rect(map.size).size.x / Layout.ART_SIZE.x
	for detail: Dictionary in DETAILS:
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
