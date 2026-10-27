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
	var map = stage.map_view
	if map.get("contact_enabled") != true:
		print("FAIL: main hall has no contour-grounded contact treatment")
		quit(1)
		return
	var state := root.get_node("GameState")
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await process_frame
		var before: Dictionary = map.frame(&"hall")
		var geometry: Dictionary = map.hall_contact_geometry()
		var edge: PackedVector2Array = geometry["edge"]
		check(edge.size() > 10, "contact follows stepped plinth rather than oval")
		for at: Vector2 in edge:
			check(before["rect"].has_point(at), "contact remains on actual sprite base")
		var cast: Vector2 = geometry["cast"]
		check(cast.x > 0 and cast.y > 0, "upper-left light casts down-right")
		check(cast.length() < before["rect"].size.x * 0.05, "cast stays local to plinth")
		var apron: PackedVector2Array = geometry["apron"]
		check(apron.size() == 4, "narrow apron follows main stair")
		check((apron[0] - apron[1]).length() < before["rect"].size.x * 0.2, "apron does not become a new large foundation")
		var entrance: Vector2 = before["entrance"]
		var picked: StringName = map.pick(entrance)
		map.contact_enabled = false
		map.queue_redraw()
		await process_frame
		map.contact_enabled = true
		map.queue_redraw()
		await process_frame
		check(before == map.frame(&"hall"), "comparison never moves hall or entrance")
		check(picked == map.pick(entrance), "contact scenery never changes picking")
		check(snapshot == state.export_save_data(), "render changes never mutate gameplay")
	stage.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: hall contact contour, local cast, narrow apron, dual-size mapping/picking and unchanged state")
	quit(1 if failures else 0)
