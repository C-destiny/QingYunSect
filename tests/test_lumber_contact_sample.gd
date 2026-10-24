extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var map: Control = load("res://scripts/world/sect_map.gd").new()
	root.add_child(map)
	var spec: Dictionary = map.get_building_visual(&"lumber_yard")
	# 样板必须路由到独立透明图，不能继续把六联图某格当新版。
	if spec["texture"] == map.unified_building_atlas:
		push_error("FAIL: lumber sample still uses an atlas cell")
		map.queue_free()
		quit(1)
		return
	var state := root.get_node("GameState")
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	var image: Image = spec["texture"].get_image()
	assert(image.get_width() == image.get_height())
	assert(image.get_pixel(0, 0).a < 0.01)
	assert(image.get_pixel(image.get_width() - 1, image.get_height() - 1).a < 0.01)
	assert(image.get_pixel(image.get_width() / 2, image.get_height() / 2).a > 0.8)
	var used := image.get_used_rect()
	assert(used.position.x >= 102 and used.position.y >= 102)
	assert(used.end.x <= 922 and used.end.y <= 922)
	var others := {}
	for kind: StringName in BuildingCatalog.BUILDINGS:
		if kind != &"lumber_yard":
			others[kind] = map.get_building_visual(kind)
	map.lumber_contact_sample = false
	var old_spec: Dictionary = map.get_building_visual(&"lumber_yard")
	assert(old_spec["texture"] != spec["texture"])
	assert(Rect2(Vector2.ZERO, image.get_size()).encloses(spec["source"]))
	for kind: StringName in others:
		assert(map.get_building_visual(kind) == others[kind])
	map.lumber_contact_sample = true
	for view: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080)]:
		map.size = view
		map.fixed_layout = true
		var frame: Dictionary = map.FixedView.site_frame(map, &"lumber_yard")
		var rect: Rect2 = frame["rect"]
		assert((rect.position + rect.size * spec["profile"]["foot"]).is_equal_approx(frame["foot"]))
		assert(map._is_sprite_hit(spec["texture"], spec["source"], rect, rect.position + rect.size * Vector2(0.5, 0.5)))
		assert(not map._is_sprite_hit(spec["texture"], spec["source"], rect, rect.position))
	assert(state.export_save_data() == snapshot)
	map.queue_free()
	await process_frame
	print("PASS: single lumber sprite alpha, unchanged other buildings, anchored feet, alpha picking and state unchanged")
	quit()
