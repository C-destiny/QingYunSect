extends RefCounted

# 只改固定场景的主殿—前庭—弟子居；所有坐标均为背景原图像素。
# 原背景保留，改稿仅在两个羽化窗口内参与渲染，不替换其他院落。
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const BACKGROUND: Texture2D = preload("res://assets/environment/sect_courtyard_fusion16.png")
const WINDOWS := [Rect2(490, 135, 525, 180), Rect2(825, 565, 340, 230)]
const PLANTING := [
	{"center": Vector2(594, 258), "extent": Vector2(53, 17)},
	{"center": Vector2(887, 271), "extent": Vector2(42, 15)},
	{"center": Vector2(918, 735), "extent": Vector2(44, 19)},
	{"center": Vector2(1058, 735), "extent": Vector2(64, 24)},
	{"center": Vector2(959, 662), "extent": Vector2(54, 20)},
]
const CONNECTIONS := {
	&"hall": {"end": Vector2(759, 290), "half_width": 21.0},
	&"disciple_quarters": {"end": Vector2(922, 742), "half_width": 10.0},
}

static func draw_background(map: Control) -> void:
	map.draw_texture_rect(map.MAP_BACKDROP, Layout.world_rect(map.size), false)
	for region: Rect2 in WINDOWS:
		# 10x10连续网格只在窗口内叠加，边界alpha为0，避免矩形贴图接缝。
		for y: int in range(10):
			for x: int in range(10):
				var points := PackedVector2Array()
				var uvs := PackedVector2Array()
				var colors := PackedColorArray()
				for offset: Vector2 in [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]:
					var t := (Vector2(x, y) + offset) / 10.0
					var source := region.position + region.size * t
					var edge := minf(minf(t.x, 1.0 - t.x), minf(t.y, 1.0 - t.y))
					points.append(Layout.point(source, map.size))
					uvs.append(source / Layout.ART_SIZE)
					colors.append(Color(1, 1, 1, smoothstep(0, 0.18, edge)))
				map.draw_polygon(points, colors, uvs, BACKGROUND)

static func occupied(state: Node, kind: StringName) -> bool:
	if kind == &"hall":
		return true
	for building: Dictionary in Layout.members(state, kind):
		if bool(building["completed"]):
			return true
	return false

static func entrance_route(map: Control, kind: StringName) -> PackedVector2Array:
	if not CONNECTIONS.has(kind):
		return PackedVector2Array()
	var profile: Dictionary = map.MAIN_HALL_VISUAL if kind == &"hall" else map.get_building_visual(kind)["profile"]
	var frame := Layout.frame(kind, map.size, profile)
	return PackedVector2Array([frame["entrance"], Layout.point(CONNECTIONS[kind]["end"], map.size)])

static func draw_ground(map: Control, state: Node) -> void:
	var scale_value := Layout.world_rect(map.size).size.x / Layout.ART_SIZE.x
	for bed: Dictionary in PLANTING:
		_draw_soft_bed(map, bed["center"], bed["extent"])
	for kind: StringName in CONNECTIONS:
		if not occupied(state, kind):
			continue
		var route := entrance_route(map, kind)
		var width := float(CONNECTIONS[kind]["half_width"]) * scale_value
		# 短连接落在现有同层平台，不越过长阶或另造抬高台基。
		var side := Vector2(width, -width * 0.28)
		var points := PackedVector2Array([route[0] - side, route[0] + side, route[1] + side, route[1] - side])
		map.draw_polygon(points, PackedColorArray([Color(0.86, 0.82, 0.72, 0.68), Color(0.90, 0.86, 0.76, 0.68), Color(0.90, 0.86, 0.76, 0), Color(0.86, 0.82, 0.72, 0)]))
		var segments := maxi(2, roundi(route[0].distance_to(route[1]) / (14 * scale_value)))
		for index: int in range(1, segments):
			var t := float(index) / segments
			var center := route[0].lerp(route[1], t)
			map.draw_line(center - side, center + side, Color(0.46, 0.45, 0.36, 0.19 * (1.0 - t)), scale_value, true)

static func _draw_soft_bed(map: Control, center: Vector2, extent: Vector2) -> void:
	# 不规则苔草边界以透明外环融入石板；固定纹理UV，不依赖随机数。
	for index: int in range(24):
		var a := TAU * float(index) / 24.0
		var b := TAU * float(index + 1) / 24.0
		var local_a := Vector2(cos(a), sin(a)) * (0.9 + 0.1 * sin(a * 5.0))
		var local_b := Vector2(cos(b), sin(b)) * (0.9 + 0.1 * sin(b * 5.0))
		var source := PackedVector2Array([center, center + local_a * extent, center + local_b * extent])
		var points := PackedVector2Array()
		for point: Vector2 in source:
			points.append(Layout.point(point, map.size))
		map.draw_polygon(points, PackedColorArray([Color(1.05, 1, 0.9, 0.92), Color(1, 1, 0.9, 0), Color(1, 1, 0.9, 0)]),
			PackedVector2Array([Vector2(0.5, 0.5), Vector2(0.5, 0.5) + local_a * 0.45, Vector2(0.5, 0.5) + local_b * 0.45]), map.TERRAIN_MOSS)
