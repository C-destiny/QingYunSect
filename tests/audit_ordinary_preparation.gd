extends SceneTree

const PATH := "res://tests/.audit_ordinary_preparation.json"
var main: Control

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	for frame: int in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var destination := "res://docs/art/p3-ordinary-%s-%d.png" % [label, root.size.x]
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
	main.selected_disciple_id = 1
	main._refresh_disciple_roster()
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main._open_management_panel(main.growth_heading)
		await capture("opening")
	state.start_construction(&"training_ground", Vector2i(3, 3))
	state.process_construction(10)
	main.disciple_training_button.pressed.emit()
	state.process_training(120)
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main._open_management_panel(main.growth_heading)
		await capture("training")
	# Isolated screenshot fixture only; these items are not a runtime gift.
	state.create_equipment_instance(&"initiate_weapon", &"rare")
	main._equip_selected_item()
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main._open_management_panel(main.growth_heading)
		for frame: int in range(4):
			await process_frame
		main.sidebar_scroll.ensure_control_visible(main.equipment_stats)
		await capture("equipped")
	manager.save_path = "res://tests/missing-p3-directory/save.json"
	main.disciple_training_button.pressed.emit()
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main._open_management_panel(main.growth_heading)
		await capture("save-failure")
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("PASS: ordinary preparation opening, training, equipped stats and save failure GPU captures at both sizes")
	quit()
