extends SceneTree

var stage: Control
var images := 0

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> Image:
	stage.refresh()
	stage.map_view.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	assert(shot.save_png("res://builds/v08-scene-audit/garden26-%s-%dx%d.png" % [label, root.size.x, root.size.y]) == OK)
	images += 1
	return shot

func _run() -> void:
	var state := root.get_node("GameState")
	stage = (load("res://scenes/samples/hall_courtyard.tscn") as PackedScene).instantiate() as Control
	root.add_child(stage)
	stage.set_process(false)
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		stage.close_card()
		stage.map_view.garden_enabled = false
		await capture("before")
		stage.map_view.garden_enabled = true
		stage.map_view.foreground_enabled = false
		var background_only := await capture("ground")
		stage.map_view.foreground_enabled = true
		var after := await capture("after")
		var map = stage.map_view
		var foreground: Dictionary = map.foreground_frame()
		var foreground_image: Image = foreground["texture"].get_image()
		var foreground_rect: Rect2 = foreground["rect"]
		var source: Rect2 = foreground["source"]
		var wing_rect: Rect2 = map.frame(&"disciple_quarters")["rect"]
		var wing_image: Image = map.QUARTERS_SAMPLE.get_image()
		var transform: Transform2D = root.get_final_transform() * map.get_global_transform_with_canvas()
		var changed := 0
		var overlaps := 0
		for y: int in range(0, 100):
			for x: int in range(0, 170):
				var uv := Vector2(x / 170.0, y / 100.0)
				var pixel := Vector2i(source.position + source.size * uv)
				if foreground_image.get_pixelv(pixel).a < 0.7:
					continue
				var at := foreground_rect.position + foreground_rect.size * uv
				var physical := Vector2i(transform * at)
				if background_only.get_pixelv(physical) == after.get_pixelv(physical):
					continue
				changed += 1
				if wing_rect.has_point(at):
					var wing_pixel := Vector2i((at - wing_rect.position) / wing_rect.size * Vector2(wing_image.get_size()))
					if wing_image.get_pixelv(wing_pixel).a > 0.7:
						overlaps += 1
		print("GARDEN26_FRAMEBUFFER size=%s changed=%d opaque-wing-overlap=%d" % [view, changed, overlaps])
		if changed < 100 or overlaps < 5:
			print("FAIL: foreground not visible or not correctly occluding the building base")
			quit(1)
			return
		if view.x == 1920:
			var pair := Image.create(3840, 1080, false, after.get_format())
			var before := Image.load_from_file("res://builds/v08-scene-audit/garden26-before-1920x1080.png")
			before.convert(after.get_format())
			pair.blit_rect(before, Rect2i(0, 0, 1920, 1080), Vector2i.ZERO)
			pair.blit_rect(after, Rect2i(0, 0, 1920, 1080), Vector2i(1920, 0))
			assert(pair.save_png("res://builds/v08-scene-audit/garden26-comparison.png") == OK)
		stage.select_site(&"disciple_quarters")
		await capture("card")
		stage.reset_demo()
		await capture("empty")
		stage.build_or_upgrade()
		state.process_construction(2)
		await capture("construction")
		state.process_construction(30)
		stage.build_or_upgrade()
		state.process_construction(2)
		stage.select_site(&"disciple_quarters")
		await capture("upgrade")
		state.process_construction(30)
		stage.close_card()
		var snapshot: Dictionary = state.export_save_data().duplicate(true)
		await capture("finished")
		assert(snapshot == state.export_save_data())
	stage.queue_free()
	await process_frame
	print("PASS: garden26 two-size %d GPU frames, visible foreground occlusion, card/construction/upgrade, unchanged state" % images)
	quit()
