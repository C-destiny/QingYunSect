extends RefCounted

# 纯表现坐标：同一平面两条轴，不改变104x52逻辑网格。
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const UNDERLAY: Texture2D = preload("res://assets/environment/sect_courtyard_ground19.png")
const LUMBER_CLEAR: Texture2D = preload("res://assets/environment/sect_lumber_clear21.png")
const ALL_CLEAR: Texture2D = preload("res://assets/environment/sect_sites_clear22.png")
const PAVING: Texture2D = preload("res://assets/environment/sect_limestone_paving.png")
const NEAR_MATERIAL: Texture2D = preload("res://assets/environment/sect_lumber_near24.png")
const AXIS_U := Vector2(1.0, 0.40)
const AXIS_V := Vector2(-1.0, 0.60)
const CLEAR_WINDOWS := [Rect2(500, 70, 520, 260), Rect2(865, 500, 375, 215)]
const ALL_CLEAR_WINDOWS := [
	Rect2(500, 70, 520, 260), Rect2(85, 175, 345, 160),
	Rect2(495, 390, 340, 170), Rect2(485, 510, 355, 175),
	Rect2(980, 280, 315, 165), Rect2(865, 500, 375, 215),
	Rect2(1270, 475, 365, 195),
]
# Three points on each source plinth: left, front, right. Roof edges are not ground axes.
# Main hall is stepped/irregular, so its points describe the compact supporting apron.
const SITE_BASES := {
	&"hall": [Vector2(0.05, 0.65), Vector2(0.56, 0.86), Vector2(0.96, 0.66)],
	&"scripture_library": [Vector2(20, 360) / 512, Vector2(260, 455) / 512, Vector2(482, 365) / 512],
	&"artifact_forge": [Vector2(24, 300) / 512, Vector2(240, 423) / 512, Vector2(488, 304) / 512],
	&"disciple_quarters": [Vector2(75, 779) / 1280, Vector2(615, 1060) / 1280, Vector2(1168, 780) / 1280],
	&"spirit_mine": [Vector2(23, 324) / 512, Vector2(245, 440) / 512, Vector2(491, 319) / 512],
}
const SITES := {
	&"hall": {"yard": Rect2(-115, -120, 260, 155), "path": Rect2(-12, 35, 24, 60)},
	&"disciple_quarters": {"yard": Rect2(-88, -135, 153, 165), "path": Rect2(-9, 30, 18, 35)},
}

static func sprite_transform(kind: StringName, foot: Vector2) -> Transform2D:
	if kind != &"disciple_quarters":
		return Transform2D.IDENTITY
	# 源弟子居两组地面边线约+0.53/-0.55，轻微仿射归一到+0.40/-0.60。
	# 主殿作为样板基准不变形；不旋转整栋，也不单独拉扯屋顶/台基。
	var vertical_scale := (AXIS_U.y + AXIS_V.y) / (0.53 + 0.55)
	var shear := AXIS_U.y - vertical_scale * 0.53
	var basis := Transform2D(Vector2(1, shear), Vector2(0, vertical_scale), Vector2.ZERO)
	basis.origin = foot - basis * foot
	return basis

static func project(origin: Vector2, local: Vector2, scale_value: float) -> Vector2:
	return origin + (AXIS_U * local.x + AXIS_V * local.y) * scale_value

static func quad(origin: Vector2, bounds: Rect2, scale_value: float) -> PackedVector2Array:
	return PackedVector2Array([
		project(origin, bounds.position, scale_value),
		project(origin, Vector2(bounds.end.x, bounds.position.y), scale_value),
		project(origin, bounds.end, scale_value),
		project(origin, Vector2(bounds.position.x, bounds.end.y), scale_value),
	])

static func draw_background(map: Control, original: Texture2D) -> void:
	map.draw_texture_rect(original, Layout.world_rect(map.size), false)
	# Only the approved local site windows change; distant scenery and paths use the original.
	var regions: Array = ALL_CLEAR_WINDOWS if map.all_ground_alignment else CLEAR_WINDOWS
	var underlay: Texture2D = ALL_CLEAR if map.all_ground_alignment else UNDERLAY
	for region: Rect2 in regions:
		var corners := PackedVector2Array([region.position, Vector2(region.end.x, region.position.y), region.end, Vector2(region.position.x, region.end.y)])
		for index: int in range(corners.size()):
			corners[index] = Layout.point(corners[index], map.size)
		draw_textured_patch(map, corners, underlay, region.position / Layout.ART_SIZE, region.size / Layout.ART_SIZE, 0.10)
	if map.lumber_ground_alignment:
		var region := Rect2(360, 285, 300, 160)
		var corners := PackedVector2Array([region.position, Vector2(region.end.x, region.position.y), region.end, Vector2(region.position.x, region.end.y)])
		for index: int in range(corners.size()):
			corners[index] = Layout.point(corners[index], map.size)
		draw_textured_patch(map, corners, LUMBER_CLEAR, region.position / Layout.ART_SIZE, region.size / Layout.ART_SIZE, 0.08)
	if map.near_material_sample:
		# High-resolution local repaint only; the building and its grounded paving are unchanged.
		var region := Rect2(345, 270, 330, 220)
		var corners := PackedVector2Array([region.position, Vector2(region.end.x, region.position.y), region.end, Vector2(region.position.x, region.end.y)])
		for index: int in range(corners.size()):
			corners[index] = Layout.point(corners[index], map.size)
		draw_textured_patch(map, corners, NEAR_MATERIAL, Vector2.ZERO, Vector2.ONE, 0.12)

static func draw_textured_patch(map: Control, corners: PackedVector2Array, texture: Texture2D, uv_origin: Vector2, uv_extent: Vector2, feather: float) -> void:
	# Coordinates are in map space. Bilinear interpolation also supports a projected yard.
	for y: int in range(10):
		for x: int in range(10):
			var points := PackedVector2Array()
			var uvs := PackedVector2Array()
			var colors := PackedColorArray()
			for offset: Vector2 in [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]:
				var t := (Vector2(x, y) + offset) / 10.0
				var source := corners[0].lerp(corners[1], t.x).lerp(corners[3].lerp(corners[2], t.x), t.y)
				var edge := minf(minf(t.x, 1.0 - t.x), minf(t.y, 1.0 - t.y))
				points.append(source)
				uvs.append(uv_origin + uv_extent * t)
				colors.append(Color(1, 1, 1, smoothstep(0, feather, edge)))
			map.draw_polygon(points, colors, uvs, texture)

static func lumber_yard_quad(view: Vector2) -> PackedVector2Array:
	# Measured on the opaque plinth, not the roof: (199,575)->(530,743)->(870,575).
	# Change the ground plane only; the building and its alpha hit-test remain upright.
	var u := Vector2(1, 168.0 / 331.0)
	var v := Vector2(-1, 168.0 / 340.0)
	var points := PackedVector2Array()
	for local: Vector2 in [Vector2(-52, -48), Vector2(52, -48), Vector2(52, 48), Vector2(-52, 48)]:
		points.append(Layout.point(Vector2(510, 338) + u * local.x + v * local.y, view))
	return points

static func site_ground_quad(map: Control, kind: StringName) -> PackedVector2Array:
	if kind == &"lumber_yard":
		return lumber_yard_quad(map.size)
	# The training sprite already includes its circular stone court; field needs soil/grass,
	# not another rectangular stone platform. Their old baked frames are removed above.
	if not SITE_BASES.has(kind):
		return PackedVector2Array()
	var frame: Dictionary = map.FixedView.site_frame(map, kind)
	var rect: Rect2 = frame["rect"]
	var pose: Transform2D = frame["sprite_transform"]
	var base: Array = SITE_BASES[kind]
	var left: Vector2 = pose * (rect.position + rect.size * Vector2(base[0]))
	var front: Vector2 = pose * (rect.position + rect.size * Vector2(base[1]))
	var right: Vector2 = pose * (rect.position + rect.size * Vector2(base[2]))
	var center := (left + right) * 0.5
	var corners := PackedVector2Array([left + right - front, right, front, left])
	var expansion := 1.04 if kind == &"hall" else 1.13
	for index: int in range(corners.size()):
		corners[index] = center + (corners[index] - center) * expansion
	return corners

static func draw_ground(map: Control) -> void:
	if map.all_ground_alignment:
		for kind: StringName in Layout.SITES:
			if kind == &"lumber_yard" and not map.lumber_ground_alignment:
				continue
			var corners := site_ground_quad(map, kind)
			if not corners.is_empty():
				draw_textured_patch(map, corners, PAVING, Vector2.ZERO, Vector2.ONE, 0.18)
	elif map.lumber_ground_alignment:
		# Map the existing top-down material, not a flat-color plate or a perspective-baked tile.
		draw_textured_patch(map, lumber_yard_quad(map.size), PAVING, Vector2.ZERO, Vector2.ONE, 0.16)
	for kind: StringName in SITES:
		var frame: Dictionary = map.FixedView.site_frame(map, kind)
		var origin: Vector2 = frame["entrance"]
		var scale_value := float(frame["scale"])
		# 正常画面仅使用已绘制的材质地面；几何轴留作开发检查，不再铺素色板。
		if map.planar_guides:
			map.draw_polyline(quad(origin, SITES[kind]["yard"], scale_value), Color("d8a558"), 1.5, true)
			map.draw_line(origin, project(origin, Vector2(65, 0), scale_value), Color("de6e63"), 2, true)
			map.draw_line(origin, project(origin, Vector2(0, 65), scale_value), Color("57b9cf"), 2, true)
