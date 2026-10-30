extends SceneTree

const PATH := "res://tests/.audit_resource_development.json"
var main: Control

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var destination := "res://docs/art/p2-economy-%s-%d.png" % [label, root.size.x]
	if root.get_texture().get_image().save_png(destination) != OK:
		printerr("FAIL: capture " + destination)
		quit(1)

func _run() -> void:
	var manager := root.get_node("SaveManager")
	manager.save_path = PATH
	manager.unix_time_provider = func() -> int: return 5000
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var state := root.get_node("GameState")
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main._open_management_panel(main.sect_heading)
		await capture("opening")
	state.set_disciple_job(1, &"field")
	state.set_disciple_job(2, &"forest")
	state.set_disciple_job(3, &"mine")
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main._open_management_panel(main.sect_heading)
		await capture("stable")
	state.resources["food"] = 0
	state.resources_changed.emit()
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main._open_management_panel(main.sect_heading)
		await capture("hungry")
		main.economy_panel.action_button.pressed.emit()
		await capture("site")
	state.resources["food"] = 150
	state.start_construction(&"disciple_quarters", Vector2i(3, 3))
	state.process_construction(6)
	for index: int in range(2):
		state.start_recruitment()
		state.process_recruitment(5)
	state.set_disciple_job(4, &"forest")
	state.set_disciple_job(5, &"mine")
	state.resources["food"] = 0
	state.resources_changed.emit()
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main._open_management_panel(main.sect_heading)
		await capture("transfer-advice")
		main.economy_panel.action_button.pressed.emit()
		await capture("transfer-roster")
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("PASS: P2 GPU opening, positive flows, hunger recovery and resource navigation in both sizes")
	quit()
