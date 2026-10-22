extends SceneTree
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
var main: Control
func _init() -> void:
	call_deferred("_run")
func both(label: String) -> void:
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		main.sect_map.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("res://builds/v08-scene-audit/garden17-%s-%dx%d.png" % [label, view.x, view.y])
		assert(error == OK)
func _run() -> void:
	root.get_node("SaveManager").save_path = "res://tests/.test_garden_audit.json"
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var state := root.get_node("GameState")
	state.resources["wood"] = 5000
	state.resources["spirit_stone"] = 5000
	main._refresh_resources()
	await both("empty")
	for kind: StringName in BuildingCatalog.BUILDINGS:
		assert(Layout.construct(state, kind))
	state.process_construction(2)
	await both("construction")
	state.process_construction(30)
	main._refresh_resources()
	await both("complete")
	main._open_fixed_site(&"disciple_quarters")
	await both("card")
	main._dismiss_building_card()
	main.fixed_site_card.hide()
	main.sect_map.fixed_selected_kind = &"training_ground"
	await both("selected")
	main.sect_map.fixed_selected_kind = &""
	assert(state.start_building_upgrade(int(Layout.members(state, &"disciple_quarters")[0]["instance_id"])))
	state.process_construction(2)
	await both("upgrade")
	main.queue_free()
	await process_frame
	print("PASS: garden17 empty/construction/complete/card/outline/upgrade, two resolutions rendered")
	quit()
