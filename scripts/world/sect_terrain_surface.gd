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

static func draw_surface(canvas: Control, origin: Vector2, ground: Texture2D, rock: Texture2D) -> void:
	var plan := make_plan(origin)
	var top: PackedVector2Array = plan["top"]
	# 悬崖只在连续地面的外缘生成，不能穿过任何合法建筑脚点。
	for edge: Vector2i in [Vector2i(1, 2), Vector2i(2, 3)]:
		var start := top[edge.x]
		var finish := top[edge.y]
		var count := maxi(1, ceili(start.distance_to(finish) / 64.0))
		for index: int in range(count):
			var a := start.lerp(finish, float(index) / count)
			var b := start.lerp(finish, float(index + 1) / count)
			var da := Vector2(0, 154 + sin(float(index) * 2.3) * 12)
			var db := Vector2(0, 154 + sin(float(index + 1) * 2.3) * 12)
			var face := PackedVector2Array([a, b, b + db, a + da])
			# 整条崖壁连续取材质UV，不能将带瀑布/花木的场景切片逐段重复。
			var u0 := float(index) / count
			var u1 := float(index + 1) / count
			var uvs := PackedVector2Array([Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 0.7), Vector2(u0, 0.7)])
			var shade := Color(0.8, 0.87, 0.88, 1) if edge.x == 1 else Color(0.94, 0.96, 0.92, 1)
			canvas.draw_polygon(face, PackedColorArray([shade]), uvs, rock)
			canvas.draw_line(a + Vector2(0, 10), a + da, Color(0.12, 0.22, 0.23, 0.2), 1.4, true)
		canvas.draw_line(start + Vector2(0, 7), finish + Vector2(0, 7), Color(0.23, 0.29, 0.26, 0.6), 8, true)
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
			canvas.draw_polygon(quad, PackedColorArray([Color.WHITE]), PackedVector2Array([Vector2.ZERO, Vector2(uv_end.x, 0), uv_end, Vector2(0, uv_end.y)]), ground)
			y += 2.0
		x += 2.0
	canvas.draw_polyline(PackedVector2Array([top[1], top[2], top[3]]), Color("bdb8a3"), 3.0, true)

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
	var across := Vector2(1, 0.5).normalized() * width * 0.5
	return PackedVector2Array([start - across, start + across, finish + across, finish - across])

static func draw_approach(canvas: Control, start: Vector2, finish: Vector2, width: float) -> void:
	var quad := approach_quad(start, finish, width)
	canvas.draw_colored_polygon(quad, Color(0.91, 0.88, 0.78, 0.68))
	canvas.draw_polyline(PackedVector2Array([quad[0], quad[3], quad[2], quad[1]]), Color(0.64, 0.60, 0.47, 0.42), 1.2, true)
	for index: int in range(1, 5):
		var center := start.lerp(finish, float(index) / 5.0)
		var across := Vector2(1, 0.5).normalized() * width * 0.48
		canvas.draw_line(center - across, center + across, Color(0.66, 0.63, 0.54, 0.25), 1.0, true)
