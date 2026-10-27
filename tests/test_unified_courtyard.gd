extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL: ", message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists("res://scenes/samples/unified_courtyard.tscn"):
		print("FAIL: unified art sample is not implemented")
		quit(1)
		return
	var stage = load("res://scenes/samples/unified_courtyard.tscn").instantiate()
	stage.showcase_on_start = false
	root.add_child(stage)
	stage.set_process(false)
	await process_frame
	var state := root.get_node("GameState")
	check(root.get_node("SaveManager").save_path != "user://savegame.json", "sample isolates formal save")
	check(state.buildings.is_empty(), "empty mode has no free residential building")
	var before_resources: Dictionary = state.resources.duplicate(true)
	stage.build_or_upgrade()
	var building: Dictionary = state.buildings[0]
	var definition := BuildingCatalog.get_data(&"disciple_quarters")
	for key: String in definition["cost"]:
		check(state.resources[key] == before_resources[key] - definition["cost"][key], "original paid cost " + key)
	check(not building["completed"], "original timed construction")
	var identity: int = building["instance_id"]
	var cell := Vector2i(building["cell_x"], building["cell_y"])
	state.process_construction(float(definition["build_time"]) + 1)
	stage.build_or_upgrade()
	state.process_construction(60)
	check(int(state.buildings[0]["level"]) == 2, "original upgrade still completes")
	check(int(state.buildings[0]["instance_id"]) == identity, "visual redesign keeps instance ID")
	check(Vector2i(state.buildings[0]["cell_x"], state.buildings[0]["cell_y"]) == cell, "visual redesign keeps saved cells")
	var map = stage.map_view
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await process_frame
		for kind: StringName in [&"hall", &"disciple_quarters"]:
			var texture: Texture2D = map.sprite(kind)
			check(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "building really transparent " + str(kind))
			var frame: Dictionary = map.frame(kind)
			var rect: Rect2 = frame["rect"]
			var hits := 0
			for y: int in range(1, 10):
				for x: int in range(1, 10):
					if map.pick(rect.position + rect.size * Vector2(x, y) / 10.0) == kind:
						hits += 1
			check(hits > 5, "independently selectable opaque silhouette " + str(kind))
			stage.select_site(kind)
			check(stage.card.visible and not stage.card.title_label.text.is_empty(), "details remain usable " + str(kind))
		stage.close_card()
		map.queue_redraw()
		await process_frame
		check(snapshot == state.export_save_data(), "render and selection never mutate saved gameplay")
	stage.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: unified art alpha, independent selection, paid timed construction/upgrade and unchanged IDs/cells/state")
	quit(1 if failures else 0)
