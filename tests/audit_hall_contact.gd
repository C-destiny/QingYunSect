extends SceneTree

var stage: Control
var failures := 0

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> Image:
	stage.refresh()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if shot.save_png("res://builds/v08-scene-audit/contact27-%s-%dx%d.png" % [label, root.size.x, root.size.y]) != OK:
		failures += 1
	return shot

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/v08-scene-audit")
	stage = load("res://scenes/samples/hall_courtyard.tscn").instantiate()
	root.add_child(stage)
	stage.set_process(false)
	var state := root.get_node("GameState")
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		stage.close_card()
		stage.map_view.contact_enabled = false
		var before := await capture("before")
		stage.map_view.contact_enabled = true
		var after := await capture("after")
		var changed := 0
		var outside := 0
		var transform: Transform2D = root.get_final_transform() * stage.map_view.get_global_transform_with_canvas()
		var frame: Rect2 = stage.map_view.frame(&"hall")["rect"]
		var region := Rect2(transform * frame.position, frame.size * transform.get_scale()).grow(25)
		for y: int in range(view.y):
			for x: int in range(view.x):
				if before.get_pixel(x, y) != after.get_pixel(x, y):
					changed += 1
					if not region.has_point(Vector2(x, y)):
						outside += 1
		print("CONTACT27_FRAMEBUFFER size=%s changed=%d outside-hall=%d" % [view, changed, outside])
		if changed < 100 or outside != 0:
			failures += 1
			print("FAIL: contact must be visible and confined to hall")
		# Export original-scale crops, including the whole plinth and entrance.
		var crop := Rect2i(Vector2i(transform * (frame.position + frame.size * Vector2(0, 0.55))), Vector2i(frame.size * transform.get_scale() * Vector2(1.04, 0.36)))
		var left := before.get_region(crop)
		var right := after.get_region(crop)
		var pair := Image.create(left.get_width() * 2, left.get_height(), false, after.get_format())
		pair.blit_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), Vector2i.ZERO)
		pair.blit_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), Vector2i(left.get_width(), 0))
		if pair.save_png("res://builds/v08-scene-audit/contact27-detail-%dx%d.png" % [view.x, view.y]) != OK:
			failures += 1
		stage.select_site(&"hall")
		await capture("hall-card")
		stage.close_card()
		if snapshot != state.export_save_data():
			failures += 1
	stage.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: contact27 GPU dual-size local change, hall card, native detail pairs and unchanged state")
	quit(1 if failures else 0)
