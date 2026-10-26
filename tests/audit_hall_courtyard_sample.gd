extends SceneTree

var stage: Control
var captures := 0

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	# The audit pauses automatic time; refresh the same UI after explicit state advancement.
	stage.refresh()
	stage.map_view.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if shot.save_png("res://builds/v08-scene-audit/hall25-%s-%dx%d.png" % [label, root.size.x, root.size.y]) != OK:
		print("FAIL: cannot write screenshot")
		quit(1)
		return
	captures += 1

func _run() -> void:
	if "--hall-courtyard-sample" not in OS.get_cmdline_user_args():
		print("FAIL: audit requires real explicit sample entry flag")
		quit(1)
		return
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	stage = root.get_node_or_null("HallCourtyardSample")
	if stage == null or root.get_node("SaveManager").save_path != "user://v08_hall_courtyard25_demo.json":
		print("FAIL: explicit entry did not reach isolated sample")
		quit(1)
		return
	stage.set_process(false)
	var state := root.get_node("GameState")
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		stage.close_card()
		await capture("complete")
		stage.select_site(&"hall")
		await capture("hall-card")
		stage.select_site(&"disciple_quarters")
		await capture("wing-card")
		stage.reset_demo()
		await capture("empty")
		stage.build_or_upgrade()
		state.process_construction(2)
		stage.refresh()
		await capture("construction")
		stage.select_site(&"disciple_quarters")
		await capture("construction-card")
		state.process_construction(30)
		stage.build_or_upgrade()
		state.process_construction(2)
		stage.refresh()
		await capture("upgrade-card")
		state.process_construction(30)
		stage.close_card()
		var snapshot: Dictionary = state.export_save_data().duplicate(true)
		await capture("finished")
		if snapshot != state.export_save_data():
			print("FAIL: capture changed gameplay")
			quit(1)
			return
	stage.queue_free()
	await process_frame
	print("PASS: hall25 actual main entry isolated, %d GPU frames at two sizes, completed/selection/cards/empty/paid construction/upgrade, render purity" % captures)
	quit()
