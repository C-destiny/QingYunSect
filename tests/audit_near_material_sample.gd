extends SceneTree
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
var main: Control

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> Image:
	main.sect_map.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	assert(shot.save_png("res://builds/v08-scene-audit/material24-%s-%dx%d.png" % [label, root.size.x, root.size.y]) == OK)
	var transform: Transform2D = root.get_final_transform() * main.sect_map.get_global_transform_with_canvas()
	var top_left: Vector2 = transform * Layout.point(Vector2(335, 245), main.sect_map.size)
	var bottom_right: Vector2 = transform * Layout.point(Vector2(685, 500), main.sect_map.size)
	assert(shot.get_region(Rect2i(top_left, bottom_right - top_left)).save_png("res://builds/v08-scene-audit/material24-%s-detail-%dx%d.png" % [label, root.size.x, root.size.y]) == OK)
	return shot

func _run() -> void:
	root.get_node("SaveManager").save_path = "res://tests/.test_material24_audit.json"
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var state := root.get_node("GameState")
	state.resources["wood"] = 5000
	state.resources["spirit_stone"] = 5000
	for kind: StringName in BuildingCatalog.BUILDINGS:
		assert(Layout.construct(state, kind))
	state.process_construction(30)
	main._refresh_resources()
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		main.fixed_site_card.hide()
		main.sect_map.near_material_sample = false
		var before := await capture("before")
		main.sect_map.near_material_sample = true
		var after := await capture("after")
		var transform: Transform2D = root.get_final_transform() * main.sect_map.get_global_transform_with_canvas()
		var changed := 0
		for y: int in range(286, 480, 5):
			for x: int in range(360, 660, 5):
				var pixel := Vector2i(transform * Layout.point(Vector2(x, y), main.sect_map.size))
				if before.get_pixelv(pixel) != after.get_pixelv(pixel):
					changed += 1
		# Sample every fifth physical pixel outside the local footprint, not just distant landmarks.
		var allowed := Rect2(transform * Layout.point(Vector2(345, 270), main.sect_map.size), (transform * Layout.point(Vector2(675, 490), main.sect_map.size)) - (transform * Layout.point(Vector2(345, 270), main.sect_map.size))).grow(2)
		var outside := 0
		for y: int in range(0, view.y, 5):
			for x: int in range(0, view.x, 5):
				if not allowed.has_point(Vector2(x, y)) and before.get_pixel(x, y) != after.get_pixel(x, y):
					outside += 1
		print("MATERIAL_FRAMEBUFFER: changed=%d outside=%d size=%s" % [changed, outside, view])
		if changed < 500 or outside != 0:
			print("FAIL: patch not applied locally or unrelated picture changed")
			quit(1)
			return
		if view.x == 1920:
			var top_left: Vector2 = transform * Layout.point(Vector2(335, 245), main.sect_map.size)
			var bottom_right: Vector2 = transform * Layout.point(Vector2(685, 500), main.sect_map.size)
			var region := Rect2i(top_left, bottom_right - top_left)
			var pair := Image.create(region.size.x * 2, region.size.y, false, Image.FORMAT_RGBA8)
			pair.blit_rect(before.get_region(region), Rect2i(Vector2i.ZERO, region.size), Vector2i.ZERO)
			pair.blit_rect(after.get_region(region), Rect2i(Vector2i.ZERO, region.size), Vector2i(region.size.x, 0))
			assert(pair.save_png("res://builds/v08-scene-audit/material24-comparison.png") == OK)
		main.sect_map.fixed_selected_kind = &"lumber_yard"
		await capture("selected")
		main._open_fixed_site(&"lumber_yard")
		await capture("card")
		main.fixed_site_card.hide()
		main.sect_map.fixed_selected_kind = &""
	assert(state.export_save_data() == snapshot)
	main.queue_free()
	await process_frame
	print("PASS: material24 two-size real before/after, local-only framebuffer changes, unchanged building state and selection/card; artistic cohesion needs human review")
	quit()
