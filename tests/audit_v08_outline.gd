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
	assert(root.get_texture().get_image().save_png("res://builds/v08-scene-audit/outline13-%s-%dx%d.png" % [label, root.size.x, root.size.y]) == OK)

func _run() -> void:
	root.get_node("SaveManager").save_path = "res://tests/.test_outline_audit.json"
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var state := root.get_node("GameState")
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		main._open_fixed_site(&"disciple_quarters")
		main.fixed_site_card.hide()
		await capture("empty-selected")
	assert(Layout.construct(state, &"disciple_quarters"))
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await capture("scaffold-selected")
	state.process_construction(30)
	for kind: StringName in BuildingCatalog.BUILDINGS:
		if kind != &"disciple_quarters":
			assert(Layout.construct(state, kind))
	state.process_construction(30)
	main._refresh_resources()
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		for kind: StringName in Layout.SITES:
			if kind == &"hall":
				main._on_hall_selected()
				main.building_card.hide()
			else:
				main._open_fixed_site(kind)
				main.fixed_site_card.hide()
			await capture(String(kind))
			assert(main.sect_map.fixed_selected_kind == kind)
		main.sect_map.clear_selection()
		await capture("clear")
		main.sect_map.fixed_layout = false
		main.sect_map.selected_cell = main.sect_map.MAIN_HALL_CELL
		await capture("legacy-hall")
		main.sect_map.fixed_layout = true
	assert(state.export_save_data() == snapshot)
	main.queue_free()
	await process_frame
	print("PASS: outline13 all eight selected silhouettes, empty/scaffold, clear selection and legacy hall in two sizes; state unchanged")
	quit()
