extends SceneTree

const PATH := "res://tests/.audit_free_build.json"
var main: Control

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	main.sect_map.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://docs/art/p1-free-%s-%d.png" % [label, root.size.x]
	if root.get_texture().get_image().save_png(path) != OK:
		printerr("FAIL: screenshot " + path)
		quit(1)

func _run() -> void:
	var state := root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = PATH
	manager.unix_time_provider = func() -> int: return 5000
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	state.resources["wood"] = 3000
	state.resources["spirit_stone"] = 3000
	state.resources["food"] = 3000
	main._refresh_resources()
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		await capture("empty")
	main._start_building_placement(&"disciple_quarters")
	main._on_placement_requested(&"disciple_quarters", Vector2i(3, 3))
	main._start_building_placement(&"disciple_quarters")
	main._on_placement_requested(&"disciple_quarters", Vector2i(7, 5))
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main._start_building_placement(&"lumber_yard")
		main.sect_map.hovered_cell = Vector2i(5, 5)
		await capture("construction")
		main._cancel_building_placement()
	state.process_construction(20)
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		await capture("built")
		main._on_building_selected(state.buildings[1])
		await capture("selected")
		main._dismiss_building_card()
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("PASS: free-build GPU empty, paid construction, grid, independent buildings and selection in both sizes")
	quit()
