extends RefCounted

const LayoutData = preload("res://scripts/world/sect_scene_layout.gd")
const TerritoryData = preload("res://scripts/data/territory_catalog.gd")

# 首轮采用同一标高，先保证全部合法格有连续地面。纯视觉高度尚不进入存档或玩法。
static func make_plan(origin: Vector2) -> Dictionary:
	var logical := TerritoryData.get_map_bounds()
	var bounds := Rect2(Vector2(logical.position) - Vector2(0.6, 0.6), Vector2(logical.size) + Vector2(0.2, 0.2))
	var first := bounds.position
	var last := bounds.end
	var top := PackedVector2Array([
		LayoutData.project_continuous(first, origin),
		LayoutData.project_continuous(Vector2(last.x, first.y), origin),
		LayoutData.project_continuous(last, origin),
		LayoutData.project_continuous(Vector2(first.x, last.y), origin),
	])
	return {"bounds": bounds, "top": top, "height": 0.0,
		"foreground": [
			{"foot": LayoutData.project_continuous(Vector2(1.0, last.y - 0.05), origin), "width": 184.0, "key": "courtyard:edge-left"},
			{"foot": LayoutData.project_continuous(Vector2(last.x - 0.05, 5.5), origin), "width": 184.0, "key": "courtyard:edge-right"},
		]}

static func natural_edges(origin: Vector2) -> Array[Dictionary]:
	var bounds: Rect2 = make_plan(origin)["bounds"]
	var result: Array[Dictionary] = []
	var lobes := [0.0, 0.42, 0.76, 0.31, 0.82, 0.38, 0.62, 0.27, 0.0]
	for side: int in range(2):
		var inner := PackedVector2Array()
		var outer := PackedVector2Array()
		for index: int in range(lobes.size()):
			var t := float(index) / float(lobes.size() - 1)
			var cell := Vector2(bounds.end.x, lerpf(bounds.position.y, bounds.end.y, t)) if side == 0 else Vector2(lerpf(bounds.end.x, bounds.position.x, t), bounds.end.y)
			inner.append(LayoutData.project_continuous(cell, origin))
			# 只向逻辑矩形外侧扩出岩岸，不能切掉边缘合法格。
			cell += Vector2(float(lobes[index]), 0) if side == 0 else Vector2(0, float(lobes[index]))
			outer.append(LayoutData.project_continuous(cell, origin))
		result.append({"inner": inner, "outer": outer, "side": side})
	return result

static func cliff_drop(vertex_index: int) -> Vector2:
	return Vector2(sin(float(vertex_index) * 1.7) * 8, 145 + sin(float(vertex_index) * 2.3) * 27)

static func draw_surface(canvas: Control, origin: Vector2, ground: Texture2D, rock: Texture2D, moss: Texture2D = null) -> void:
	var plan := make_plan(origin)
	var top: PackedVector2Array = plan["top"]
	# 悬崖只在连续地面的外缘生成，不能穿过任何合法建筑脚点。
	for edge: Dictionary in natural_edges(origin):
		var outer: PackedVector2Array = edge["outer"]
		var inner: PackedVector2Array = edge["inner"]
		var count := outer.size() - 1
		for index: int in range(count):
			var a := outer[index]
			var b := outer[index + 1]
			var vertex := int(edge["side"]) * count + index
			var da := cliff_drop(vertex)
			var db := cliff_drop(vertex + 1)
			var face := PackedVector2Array([a, b, b + db, a + da])
			# 整条崖壁连续取材质UV，不能将带瀑布/花木的场景切片逐段重复。
			var u0 := float(index) / count
			var u1 := float(index + 1) / count
			var uvs := PackedVector2Array([Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 0.7), Vector2(u0, 0.7)])
			var shade := Color(0.8, 0.87, 0.88, 1) if edge["side"] == 0 else Color(0.94, 0.96, 0.92, 1)
			canvas.draw_polygon(face, PackedColorArray([shade, shade, Color(shade, 0.28), Color(shade, 0.28)]), uvs, rock)
			canvas.draw_line(a + Vector2(0, 8), a + da * 0.68, Color(0.12, 0.22, 0.23, 0.20), 1.4, true)
			if moss != null:
				var raw := PackedVector2Array([inner[index], inner[index + 1], b, a])
				var raw_uv := PackedVector2Array([Vector2.ZERO, Vector2(1, 0), Vector2(1, 0.28), Vector2(0, 0.28)])
				var apron := PackedVector2Array()
				var apron_uv := PackedVector2Array()
				for point_index: int in range(raw.size()):
					if apron.is_empty() or not raw[point_index].is_equal_approx(apron[-1]):
						apron.append(raw[point_index])
						apron_uv.append(raw_uv[point_index])
				if apron.size() > 2 and apron[0].is_equal_approx(apron[-1]):
					apron.resize(apron.size() - 1)
					apron_uv.resize(apron_uv.size() - 1)
				if apron.size() >= 3:
					canvas.draw_polygon(apron, PackedColorArray([Color(1.12, 1.13, 1.06)]), apron_uv, moss)
		canvas.draw_polyline(outer, Color(0.3, 0.37, 0.26, 0.45), 2.0, true)
	# 所有铺装来自同一个平面映射，不再在建筑脚下重复叠平台。
	var bounds: Rect2 = plan["bounds"]
	var x := bounds.position.x
	while x < bounds.end.x - 0.001:
		var y := bounds.position.y
		while y < bounds.end.y - 0.001:
			var end := Vector2(minf(x + 2.0, bounds.end.x), minf(y + 2.0, bounds.end.y))
			var quad := PackedVector2Array([
				LayoutData.project_continuous(Vector2(x, y), origin),
				LayoutData.project_continuous(Vector2(end.x, y), origin),
				LayoutData.project_continuous(end, origin),
				LayoutData.project_continuous(Vector2(x, end.y), origin),
			])
			var uv_end := (end - Vector2(x, y)) / 2.0
			canvas.draw_polygon(quad, PackedColorArray([Color.WHITE]), PackedVector2Array([Vector2.ZERO, Vector2(uv_end.x, 0), uv_end, Vector2(0, uv_end.y)]), moss if moss != null else ground)
			y += 2.0
		x += 2.0
	if moss != null:
		for edge: Dictionary in natural_edges(origin):
			var inner: PackedVector2Array = edge["inner"]
			var inward := LayoutData.project_continuous(Vector2(-0.65, 0) if edge["side"] == 0 else Vector2(0, -0.65), Vector2.ZERO)
			for index: int in range(inner.size() - 1):
				canvas.draw_polygon(PackedVector2Array([inner[index], inner[index + 1], inner[index + 1] + inward, inner[index] + inward]),
					PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0), Color(1, 1, 1, 0)]),
					PackedVector2Array([Vector2.ZERO, Vector2(1, 0), Vector2(1, 0.5), Vector2(0, 0.5)]), moss)
	else:
		canvas.draw_polyline(PackedVector2Array([top[1], top[2], top[3]]), Color("bdb8a3"), 3.0, true)

static func draw_meadow(canvas: Control, center: Vector2, radius: Vector2, moss: Texture2D) -> void:
	for index: int in range(24):
		var angle := TAU * float(index) / 24.0
		var next := TAU * float(index + 1) / 24.0
		var a := Vector2(cos(angle), sin(angle))
		var b := Vector2(cos(next), sin(next))
		var pa := center + a * radius * (1.0 + 0.06 * sin(float(index) * 1.9))
		var pb := center + b * radius * (1.0 + 0.06 * sin(float(index + 1) * 1.9))
		canvas.draw_polygon(PackedVector2Array([center, pa, pb]),
			PackedColorArray([Color(1, 1, 1, 0.88), Color(1, 1, 1, 0), Color(1, 1, 1, 0)]),
			PackedVector2Array([Vector2(0.5, 0.5), (a + Vector2.ONE) * 0.5, (b + Vector2.ONE) * 0.5]), moss)

static func paved_patch_polygon(center: Vector2, extent: Vector2) -> PackedVector2Array:
	var normalized := PackedVector2Array([Vector2(-1, -0.7), Vector2(-0.7, -1), Vector2(0.7, -1), Vector2(1, -0.7),
		Vector2(1, 0.7), Vector2(0.7, 1), Vector2(-0.7, 1), Vector2(-1, 0.7)])
	var polygon := PackedVector2Array()
	for point: Vector2 in normalized:
		polygon.append(center + point * extent)
	var bounds: Rect2 = make_plan(Vector2.ZERO)["bounds"]
	var clipped := Geometry2D.intersect_polygons(polygon, PackedVector2Array([bounds.position, bounds.position + Vector2(bounds.size.x, 0), bounds.end, bounds.position + Vector2(0, bounds.size.y)]))
	return clipped[0] if not clipped.is_empty() else PackedVector2Array()

static func draw_paved_patch(canvas: Control, origin: Vector2, center: Vector2, extent: Vector2, paving: Texture2D) -> void:
	var polygon := paved_patch_polygon(center, extent)
	if polygon.size() < 3:
		return
	# 与台阶/入口维持同一石材尺度，不能将整幅纹理拉伸成几块巨砖。
	for x: int in range(floori(center.x - extent.x), ceili(center.x + extent.x), 2):
		for y: int in range(floori(center.y - extent.y), ceili(center.y + extent.y), 2):
			var start := Vector2(x, y)
			var tile := PackedVector2Array([start, start + Vector2(2, 0), start + Vector2(2, 2), start + Vector2(0, 2)])
			for clipped: PackedVector2Array in Geometry2D.intersect_polygons(polygon, tile):
				var points := PackedVector2Array()
				var uvs := PackedVector2Array()
				for cell: Vector2 in clipped:
					points.append(LayoutData.project_continuous(cell, origin))
					uvs.append((cell - start) * 0.5)
				canvas.draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, paving)
	var border := PackedVector2Array()
	for cell: Vector2 in polygon:
		border.append(LayoutData.project_continuous(cell, origin))
	border.append(border[0])
	canvas.draw_polyline(border, Color(0.81, 0.78, 0.65, 0.65), 2.0, true)

# 台阶只在可建造矩形之外形成视觉落差，绝不抬高或切断内部逻辑格。
static func edge_stair_plan(origin: Vector2) -> Array[Dictionary]:
	var bounds: Rect2 = make_plan(origin)["bounds"]
	var result: Array[Dictionary] = []
	for index: int in range(6):
		var y0 := bounds.end.y + float(index) * 0.16
		var y1 := y0 + 0.16
		var drop := Vector2(0, float(index) * 4.0)
		var quad := PackedVector2Array([
			LayoutData.project_continuous(Vector2(2.7, y0), origin) + drop,
			LayoutData.project_continuous(Vector2(3.8, y0), origin) + drop,
			LayoutData.project_continuous(Vector2(3.8, y1), origin) + drop,
			LayoutData.project_continuous(Vector2(2.7, y1), origin) + drop])
		result.append({"quad": quad, "logical_y": y0, "drop": drop.y})
	return result

static func draw_edge_stairs(canvas: Control, origin: Vector2, paving: Texture2D, rock: Texture2D) -> void:
	# 下端必须有承托落台，不能把一截阶梯悬挂在崖面上。
	var edge_y := float(make_plan(origin)["bounds"].end.y)
	var landing := PackedVector2Array([
		LayoutData.project_continuous(Vector2(2.4, edge_y + 0.96), origin) + Vector2(0, 24),
		LayoutData.project_continuous(Vector2(4.1, edge_y + 0.96), origin) + Vector2(0, 24),
		LayoutData.project_continuous(Vector2(4.1, edge_y + 1.5), origin) + Vector2(0, 24),
		LayoutData.project_continuous(Vector2(2.4, edge_y + 1.5), origin) + Vector2(0, 24)])
	for edge: Vector2i in [Vector2i(1, 2), Vector2i(2, 3)]:
		canvas.draw_polygon(PackedVector2Array([landing[edge.x], landing[edge.y], landing[edge.y] + Vector2(0, 42), landing[edge.x] + Vector2(0, 42)]),
			PackedColorArray([Color(0.83, 0.89, 0.87)]),
			PackedVector2Array([Vector2(0.2, 0.1), Vector2(0.6, 0.1), Vector2(0.6, 0.55), Vector2(0.2, 0.55)]), rock)
	canvas.draw_polygon(landing, PackedColorArray([Color.WHITE]),
		PackedVector2Array([Vector2.ZERO, Vector2(0.7, 0), Vector2(0.7, 0.4), Vector2(0, 0.4)]), paving)
	for step: Dictionary in edge_stair_plan(origin):
		var quad: PackedVector2Array = step["quad"]
		canvas.draw_polygon(quad, PackedColorArray([Color(1, 0.99, 0.94)]),
			PackedVector2Array([Vector2.ZERO, Vector2(0.5, 0), Vector2(0.5, 0.18), Vector2(0, 0.18)]), paving)
		canvas.draw_colored_polygon(PackedVector2Array([quad[2], quad[3], quad[3] + Vector2(0, 4), quad[2] + Vector2(0, 4)]), Color("a7a18e"))
		canvas.draw_line(quad[2], quad[3], Color("e0d8c2"), 1.4, true)

static func approach_quad(start: Vector2, finish: Vector2, width: float) -> PackedVector2Array:
	var across := Vector2(1, 0.5).normalized() * width * 0.5 if finish.x <= start.x else Vector2(-1, 0.5).normalized() * width * 0.5
	return PackedVector2Array([start - across, start + across, finish + across, finish - across])

static func draw_approach(canvas: Control, start: Vector2, finish: Vector2, width: float, paving: Texture2D = null) -> void:
	var quad := approach_quad(start, finish, width)
	if paving != null:
		canvas.draw_polygon(quad, PackedColorArray([Color.WHITE]), PackedVector2Array([Vector2.ZERO, Vector2(0.35, 0), Vector2(0.35, 1), Vector2(0, 1)]), paving)
	else:
		canvas.draw_colored_polygon(quad, Color(0.91, 0.88, 0.78, 0.68))
	canvas.draw_polyline(PackedVector2Array([quad[0], quad[3], quad[2], quad[1]]), Color(0.64, 0.60, 0.47, 0.42), 1.2, true)
	for index: int in range(1, 5):
		var center := start.lerp(finish, float(index) / 5.0)
		var across: Vector2 = (quad[1] - quad[0]) * 0.48
		canvas.draw_line(center - across, center + across, Color(0.66, 0.63, 0.54, 0.25), 1.0, true)
