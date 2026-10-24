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
	var image := root.get_texture().get_image()
	assert(image.save_png("res://builds/v08-scene-audit/lumber20-%s-%dx%d.png" % [label, root.size.x, root.size.y]) == OK)
	if label in ["before", "after"]:
		var foot: Vector2 = root.get_final_transform() * main.sect_map.get_global_transform_with_canvas() * Layout.point(Layout.SITES[&"lumber_yard"]["foot"], main.sect_map.size)
		var extent := Vector2(280, 230) * root.size.x / 1920.0
		var region := Rect2i(foot - extent * Vector2(0.5, 0.78), extent)
		assert(image.get_region(region).save_png("res://builds/v08-scene-audit/lumber20-%s-detail-%dx%d.png" % [label, root.size.x, root.size.y]) == OK)
func _run() -> void:
	root.get_node("SaveManager").save_path = "res://tests/.test_lumber20_audit.json"
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
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		main.fixed_site_card.hide()
		main.sect_map.lumber_contact_sample = false
		await capture("before")
		main.sect_map.lumber_contact_sample = true
		await capture("after")
		main.sect_map.fixed_selected_kind = &"lumber_yard"
		await capture("selected")
		main._open_fixed_site(&"lumber_yard")
		await capture("card")
		main._dismiss_building_card()
		main.fixed_site_card.hide()
		main.sect_map.fixed_selected_kind = &""
	main.queue_free()
	await process_frame
	print("PASS: lumber20 same-state before/after, alpha outline and management card in two sizes")
	quit()
