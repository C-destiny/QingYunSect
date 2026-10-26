extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: ", message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists("res://scenes/samples/hall_courtyard.tscn"):
		print("FAIL: independent runnable hall/courtyard sample is missing")
		quit(1)
		return
	var stage = load("res://scenes/samples/hall_courtyard.tscn").instantiate()
	stage.showcase_on_start = false
	root.add_child(stage)
	stage.set_process(false)
	await process_frame
	var state := root.get_node("GameState")
	check(root.get_node("SaveManager").save_path == "user://v08_hall_courtyard25_demo.json", "sample must not use formal save")
	check(state.buildings.is_empty(), "empty sample does not give free buildings")
	var before: Dictionary = state.resources.duplicate(true)
	stage.build_or_upgrade()
	check(state.buildings.size() == 1, "paid construction creates one original building")
	var definition := BuildingCatalog.get_data(&"disciple_quarters")
	for key: String in definition["cost"]:
		check(state.resources[key] == before[key] - definition["cost"][key], "original build cost: " + key)
	var building: Dictionary = state.buildings[0]
	var identity: int = building["instance_id"]
	var cell := Vector2i(building["cell_x"], building["cell_y"])
	check(not building["completed"], "construction is not instantly completed")
	var scaffold: Dictionary = stage.map_view.scaffold()
	check(stage.map_view.pick((scaffold["base"][2] + scaffold["top"][0]) * 0.5) == &"disciple_quarters", "visible construction scaffold is selectable")
	var future_rect: Rect2 = stage.map_view.frame(&"disciple_quarters")["rect"]
	# y=0.2 is inside the actual raised back scaffold; use the empty area above it.
	check(stage.map_view.pick(future_rect.position + future_rect.size * Vector2(0.5, 0.1)) == &"", "empty area above the visible scaffold cannot intercept clicks")
	var spent: Dictionary = state.resources.duplicate(true)
	stage.build_or_upgrade()
	check(state.resources == spent, "busy construction ignores duplicate action")
	state.process_construction(float(definition["build_time"]) - 0.1)
	check(not building["completed"], "original duration must elapse")
	state.process_construction(0.2)
	check(building["completed"], "original completion works")
	stage.select_site(&"disciple_quarters")
	check(stage.card.status_label.text.contains("木材80") and stage.card.status_label.text.contains("灵石20"), "completed building card quotes the actual next upgrade price")
	var upgrade_before: Dictionary = state.resources.duplicate(true)
	var upgrade_cost := BuildingCatalog.get_upgrade_cost(&"disciple_quarters", 2)
	stage.build_or_upgrade()
	check(building["upgrading"], "existing upgrade path works")
	for key: String in upgrade_cost:
		check(state.resources[key] == upgrade_before[key] - upgrade_cost[key], "original upgrade cost: " + key)
	var upgrading_resources: Dictionary = state.resources.duplicate(true)
	stage.build_or_upgrade()
	check(state.resources == upgrading_resources, "busy upgrade ignores duplicate action")
	check(building["instance_id"] == identity and Vector2i(building["cell_x"], building["cell_y"]) == cell, "visual sample preserves identity/cell")
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await process_frame
		for kind: StringName in [&"hall", &"disciple_quarters"]:
			var frame: Dictionary = stage.map_view.frame(kind)
			var rect: Rect2 = frame["rect"]
			var picked := false
			var hit_point := Vector2.ZERO
			for y: int in range(2, 9):
				for x: int in range(2, 9):
					if stage.map_view.pick(rect.position + rect.size * Vector2(x, y) / 10) == kind:
						picked = true
						hit_point = rect.position + rect.size * Vector2(x, y) / 10
			check(picked, "visible sprite is selectable at " + str(view) + " " + str(kind))
			var click := InputEventMouseButton.new()
			click.position = hit_point
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			stage.map_view._gui_input(click)
			await process_frame
			check(stage.card.visible and stage.map_view.selected == kind, "map click signal opens correct card")
			check(Rect2(Vector2.ZERO, stage.size).encloses(stage.card.get_rect()), "card stays inside window")
		stage.card.close_button.pressed.emit()
		await process_frame
		await process_frame
		check(not stage.card.visible and stage.map_view.selected == &"", "close clears selection")
		check(stage.map_view.pick(Vector2(5, 5)) == &"", "distant sky does not select a building")
		var snapshot: Dictionary = state.export_save_data().duplicate(true)
		stage.map_view.queue_redraw()
		await process_frame
		check(state.export_save_data() == snapshot, "render/hit/card do not mutate data")
	state.process_construction(30)
	check(building["level"] == 2 and not building["upgrading"], "original upgrade completes")
	stage.reset_demo()
	check(state.buildings.is_empty() and state.resources["wood"] == 1000, "reset affects only isolated demo baseline")
	check(stage.map_view.pick(stage.map_view.frame(&"disciple_quarters")["foot"]) == &"", "unbuilt future sprite must not catch clicks")
	stage.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: hall courtyard isolated paid construction/upgrade, dual-size selection/card, identity/cell and render purity")
	quit(1 if failures else 0)
