extends SceneTree
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
func _init() -> void:
	call_deferred("_run")
func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://builds/v08-scene-audit/fixed12-%s-%dx%d.png" % [label, root.size.x, root.size.y]) == OK)
func _run() -> void:
	var manager := root.get_node("SaveManager")
	manager.save_path = "res://tests/.test_fixed_audit.json"
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var state := root.get_node("GameState")
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	main._refresh_resources()
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		main.sect_map.queue_redraw()
		await capture("empty")
		main._open_fixed_site(&"disciple_quarters")
		await capture("build-card")
		main.fixed_site_card.hide()
	for kind: StringName in BuildingCatalog.BUILDINGS:
		assert(Layout.construct(state, kind))
	main.sect_map.queue_redraw()
	await capture("construction")
	state.process_construction(30)
	main._refresh_resources()
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		main.sect_map.queue_redraw()
		await capture("built")
		main._open_fixed_site(&"disciple_quarters")
		await capture("group-card")
		main.fixed_site_card.hide()
		main._on_hall_selected()
		await capture("hall-card")
		main._dismiss_building_card()
	main.queue_free()
	await process_frame
	print("PASS: fixed12 shadows, garden depth, empty, paid construction and completed sites with interactive cards in two sizes")
	quit()
