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
	assert(root.get_texture().get_image().save_png("res://builds/v08-scene-audit/feedback14-%s-%dx%d.png" % [label, root.size.x, root.size.y]) == OK)

func both(label: String) -> void:
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await capture(label)

func _run() -> void:
	root.get_node("SaveManager").save_path = "res://tests/.test_feedback_audit.json"
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var state := root.get_node("GameState")
	state.resources["wood"] = 2000
	state.resources["spirit_stone"] = 2000
	main._refresh_resources()
	await both("empty")
	for kind: StringName in BuildingCatalog.BUILDINGS:
		assert(Layout.construct(state, kind))
	state.process_construction(2)
	await both("construction")
	state.process_construction(30)
	main._refresh_resources()
	await both("complete")
	assert(Layout.construct(state, &"disciple_quarters"))
	assert(state.start_building_upgrade(int(Layout.members(state, &"disciple_quarters")[0]["instance_id"])))
	state.process_construction(2)
	main._open_fixed_site(&"disciple_quarters")
	main.fixed_site_card.hide()
	await both("parallel-upgrade")
	main._open_fixed_site(&"disciple_quarters")
	await both("card")
	main.fixed_site_card.hide()
	state.process_construction(4)
	await both("upgrade-only")
	state.process_construction(30)
	main._refresh_resources()
	await both("finished")
	main.queue_free()
	await process_frame
	print("PASS: feedback14 empty, construction, complete, parallel upgrade, card and finished rendered in two sizes")
	quit()
