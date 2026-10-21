extends SceneTree

const Outline = preload("res://scripts/world/building_selection_outline.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# L形验证凹角与透明空白，防止退化成包围框或底部圈。
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(4, 4, 24, 8), Color.WHITE)
	image.fill_rect(Rect2i(4, 4, 8, 24), Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	var contours := Outline.contours(texture, Rect2(0, 0, 32, 32))
	assert(contours.size() == 1)
	assert(Geometry2D.is_point_in_polygon(Vector2(0.25, 0.25), contours[0]))
	assert(not Geometry2D.is_point_in_polygon(Vector2(0.75, 0.75), contours[0]))
	var map: Control = load("res://scripts/world/sect_map.gd").new()
	root.add_child(map)
	var state := root.get_node("GameState")
	var before: Dictionary = state.export_save_data().duplicate(true)
	for kind: StringName in map.FixedLayout.SITES:
		var spec: Dictionary = {"texture": map.MAIN_HALL_SAMPLE, "source": Rect2(Vector2.ZERO, map.MAIN_HALL_SAMPLE.get_size())} if kind == &"hall" else map.get_building_visual(kind)
		var paths: Array[PackedVector2Array] = Outline.contours(spec["texture"], spec["source"])
		assert(not paths.is_empty())
		var minimum := Vector2.ONE
		var maximum := Vector2.ZERO
		for path: PackedVector2Array in paths:
			assert(path[0] == path[-1])
			for point: Vector2 in path:
				assert(point.x >= 0 and point.y >= 0 and point.x <= 1 and point.y <= 1)
				minimum = minimum.min(point)
				maximum = maximum.max(point)
		assert(minimum.y < 0.4 and maximum.y > 0.65)
		assert(maximum.x - minimum.x > 0.5)
		var cache_size: int = Outline.cache.size()
		assert(Outline.contours(spec["texture"], spec["source"]) == paths)
		assert(Outline.cache.size() == cache_size)
	assert(state.export_save_data() == before)
	map.queue_free()
	await process_frame
	print("PASS: concave alpha silhouette, all eight buildings roof-to-base contours, atlas isolation, closed normalized paths and cache without state changes")
	quit()
