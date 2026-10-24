extends SceneTree
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
var main: Control

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	main.sect_map.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	assert(shot.save_png("res://builds/v08-scene-audit/construction23-%s-%dx%d.png" % [label, root.size.x, root.size.y]) == OK)
	var foot: Vector2 = root.get_final_transform() * main.sect_map.get_global_transform_with_canvas() * Layout.point(Vector2(510, 392), main.sect_map.size)
	var extent := Vector2(310, 270) * root.size.x / 1920.0
	assert(shot.get_region(Rect2i(foot - extent * Vector2(0.5, 0.76), extent)).save_png("res://builds/v08-scene-audit/construction23-%s-lumber-%dx%d.png" % [label, root.size.x, root.size.y]) == OK)

func _run() -> void:
	root.get_node("SaveManager").save_path = "res://tests/.test_construction23_audit.json"
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var state := root.get_node("GameState")
	state.resources["wood"] = 5000
	state.resources["spirit_stone"] = 5000
	for kind: StringName in BuildingCatalog.BUILDINGS:
		assert(Layout.construct(state, kind))
	state.process_construction(1)
	main._refresh_resources()
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await capture("working")
		main.sect_map.fixed_selected_kind = &"lumber_yard"
		await capture("selected")
		main._open_fixed_site(&"lumber_yard")
		await capture("card")
		main.fixed_site_card.hide()
		main.sect_map.fixed_selected_kind = &""
	assert(state.export_save_data() == snapshot)
	state.process_construction(30)
	main._refresh_resources()
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await capture("completed")
	main.queue_free()
	await process_frame
	print("PASS: construction23 seven active scaffolds, selection/card and normal completion at two sizes; capture does not advance game data")
	quit()
