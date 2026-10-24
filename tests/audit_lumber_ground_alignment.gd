extends SceneTree
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
var main: Control
var before: Image

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> Image:
	main.sect_map.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	shot.save_png("res://builds/v08-scene-audit/lumber21-%s-%dx%d.png" % [label, root.size.x, root.size.y])
	var foot: Vector2 = root.get_final_transform() * main.sect_map.get_global_transform_with_canvas() * Layout.point(Layout.SITES[&"lumber_yard"]["foot"], main.sect_map.size)
	var extent := Vector2(310, 260) * root.size.x / 1920.0
	shot.get_region(Rect2i(foot - extent * Vector2(0.5, 0.72), extent)).save_png("res://builds/v08-scene-audit/lumber21-%s-detail-%dx%d.png" % [label, root.size.x, root.size.y])
	return shot

func _run() -> void:
	root.get_node("SaveManager").save_path = "res://tests/.test_lumber21_audit.json"
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
		main.sect_map.lumber_ground_alignment = false
		before = await capture("before")
		main.sect_map.lumber_ground_alignment = true
		var after := await capture("after")
		var changed := 0
		var outside := 0
		var to_screen: Transform2D = root.get_final_transform() * main.sect_map.get_global_transform_with_canvas()
		# Real framebuffer checks catch an unused geometry helper or an accidental full-background replacement.
		for y: int in range(318, 431, 5):
			for x: int in range(384, 638, 5):
				var pixel := Vector2i(to_screen * Layout.point(Vector2(x, y), main.sect_map.size))
				if before.get_pixelv(pixel) != after.get_pixelv(pixel):
					changed += 1
		for source: Vector2 in [Vector2(750, 280), Vector2(1100, 450), Vector2(1430, 650)]:
			var pixel := Vector2i(to_screen * Layout.point(source, main.sect_map.size))
			if before.get_pixelv(pixel) != after.get_pixelv(pixel):
				outside += 1
		print("FRAMEBUFFER: changed=%d outside=%d" % [changed, outside])
		if changed < 300 or outside != 0:
			print("FAIL: lumber ground not rendered or unrelated courtyard changed")
			quit(1)
			return
		main.sect_map.fixed_selected_kind = &"lumber_yard"
		await capture("selected")
		main._open_fixed_site(&"lumber_yard")
		await capture("card")
		main.fixed_site_card.hide()
		main.sect_map.fixed_selected_kind = &""
	assert(state.export_save_data() == snapshot)
	main.queue_free()
	await process_frame
	print("PASS: lumber21 same-state real ground before/after, unchanged other courtyards, selection/card and unchanged data in two sizes")
	quit()
