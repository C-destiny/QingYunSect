extends SceneTree

var failures := 0

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		print("FAIL: ", label)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage = load("res://scenes/samples/hall_courtyard.tscn").instantiate()
	root.add_child(stage)
	stage.set_process(false)
	await process_frame
	if stage.map_view.get("garden_enabled") != true:
		print("FAIL: sample has no coherent garden and separately grounded foreground")
		stage.queue_free()
		await process_frame
		quit(1)
		return
	var state := root.get_node("GameState")
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await process_frame
		var map = stage.map_view
		var foreground: Dictionary = map.foreground_frame()
		var image: Image = foreground["texture"].get_image()
		check(image.detect_alpha() != Image.ALPHA_NONE, "foreground really has transparency")
		check(foreground["source"].size.x > 50 and foreground["source"].size.y > 30, "foreground has visible body")
		var footprint: Rect2 = foreground["rect"]
		for kind: StringName in [&"hall", &"disciple_quarters"]:
			var frame: Dictionary = map.frame(kind)
			check(not footprint.grow(5).has_point(frame["entrance"]), "garden leaves entrance clear: " + str(kind))
			var rect: Rect2 = frame["rect"]
			var selected := false
			for y: int in range(2, 8):
				for x: int in range(2, 8):
					if map.pick(rect.position + rect.size * Vector2(x, y) / 10) == kind:
						selected = true
			check(selected, "garden keeps both buildings independently selectable")
		var before: Rect2 = map.frame(&"hall")["rect"]
		stage.compare.pressed.emit()
		check(not map.garden_enabled, "comparison button really switches to original courtyard")
		check(before == map.frame(&"hall")["rect"], "before/after compare keeps main hall frame")
		stage.compare.pressed.emit()
		check(map.garden_enabled, "comparison button returns to garden")
		map.foreground_enabled = false
		map.queue_redraw()
		await process_frame
		map.foreground_enabled = true
		map.queue_redraw()
		await process_frame
		check(snapshot == state.export_save_data(), "landscape/foreground never mutate gameplay or saved cells")
	stage.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: hall garden alpha, entrance clearance, dual-size selection, before/after frame and unchanged state")
	quit(1 if failures else 0)
