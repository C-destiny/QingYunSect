extends SceneTree

var stage: Control
var failures := 0
var captures := 0

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> Image:
	stage.refresh()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if shot.save_png("res://builds/v08-scene-audit/unified28-%s-%dx%d.png" % [label, root.size.x, root.size.y]) != OK:
		failures += 1
	captures += 1
	return shot

func _run() -> void:
	if "--unified-courtyard-sample" not in OS.get_cmdline_user_args():
		print("FAIL: audit requires explicit unified sample entry")
		quit(1)
		return
	root.add_child(load("res://scenes/main/main.tscn").instantiate())
	await process_frame
	await process_frame
	stage = root.get_node_or_null("UnifiedCourtyardSample")
	if stage == null or root.get_node("SaveManager").save_path == "user://savegame.json":
		print("FAIL: unified entry must isolate formal save before loading")
		quit(1)
		return
	stage.set_process(false)
	var state := root.get_node("GameState")
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		stage.reset_demo()
		var empty := await capture("empty")
		stage.build_or_upgrade()
		state.process_construction(2)
		await capture("construction")
		stage.select_site(&"disciple_quarters")
		await capture("construction-card")
		state.process_construction(60)
		stage.close_card()
		var complete := await capture("complete")
		var changed := 0
		var map = stage.map_view
		var transform: Transform2D = root.get_final_transform() * map.get_global_transform_with_canvas()
		var wing_rect: Rect2 = map.frame(&"disciple_quarters")["rect"]
		for y: int in range(10, 90):
			for x: int in range(10, 90):
				var at := Vector2i(transform * (wing_rect.position + wing_rect.size * Vector2(x, y) / 100.0))
				if empty.get_pixelv(at) != complete.get_pixelv(at):
					changed += 1
		if changed < 1000:
			failures += 1
			print("FAIL: independent residence not visibly constructed")
		stage.select_site(&"hall")
		await capture("hall-card")
		stage.select_site(&"disciple_quarters")
		await capture("wing-card")
		stage.build_or_upgrade()
		state.process_construction(2)
		await capture("upgrading")
		state.process_construction(60)
		stage.close_card()
		var snapshot: Dictionary = state.export_save_data().duplicate(true)
		stage.compare.pressed.emit()
		await capture("previous27")
		stage.compare.pressed.emit()
		await capture("final")
		if state.export_save_data() != snapshot:
			failures += 1
		print("UNIFIED28_FRAMEBUFFER size=%s residence-visible-changed-samples=%d" % [view, changed])
	stage.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: unified28 actual isolated main entry, %d GPU frames, visible construction/cards/upgrade/compare and unchanged state" % captures)
	quit(1 if failures else 0)
