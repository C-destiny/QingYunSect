extends RefCounted

# 从真实透明轮廓提取闭合线，按贴图/图集区域缓存；不改变拾取或占地。
static var cache: Dictionary = {}

static func contours(texture: Texture2D, source: Rect2) -> Array[PackedVector2Array]:
	var key := "%s:%s" % [texture.get_instance_id(), source]
	if cache.has(key):
		return cache[key]
	var image := texture.get_image().get_region(Rect2i(source))
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, 0.35)
	var result: Array[PackedVector2Array] = []
	for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, image.get_size()), 1.5):
		if polygon.size() < 3:
			continue
		# 过滤透明贴图边缘零碎亮点，保留屋檐/台基等独立部分。
		var area := 0.0
		for index: int in range(polygon.size()):
			area += polygon[index].cross(polygon[(index + 1) % polygon.size()])
		if absf(area) < 40.0:
			continue
		var normalized := PackedVector2Array()
		for point: Vector2 in polygon:
			normalized.append(point / Vector2(image.get_size()))
		normalized.append(normalized[0])
		result.append(normalized)
	cache[key] = result
	return result

static func draw(map: Control, texture: Texture2D, source: Rect2, target: Rect2) -> void:
	for contour: PackedVector2Array in contours(texture, source):
		var points := PackedVector2Array()
		for point: Vector2 in contour:
			points.append(target.position + point * target.size)
		map.draw_polyline(points, Color(0.16, 0.21, 0.16, 0.65), 4.5, true)
		map.draw_polyline(points, Color("f4d77f"), 2.0, true)

static func draw_scaffold(map: Control, center: Vector2) -> void:
	for x: float in [-29.0, 0.0, 29.0]:
		map.draw_line(center + Vector2(x, -48), center + Vector2(x, 4), Color("f4d77f"), 4, true)
	map.draw_line(center + Vector2(-36, -39), center + Vector2(36, -39), Color("f4d77f"), 4, true)
	map.draw_line(center + Vector2(-34, -31), center + Vector2(28, -9), Color("f4d77f"), 3, true)
