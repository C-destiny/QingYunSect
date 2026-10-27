extends SceneTree

const View = preload("res://scripts/world/complete_sect_view.gd")
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const PATH := "res://tests/.audit_complete29.json"
var main: Control

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var destination := "res://builds/complete29-check/%s-%dx%d.png" % [label, root.size.x, root.size.y]
	if root.get_texture().get_image().save_png(destination) != OK:
		printerr("FAIL: capture " + destination)
		quit(1)

func _run() -> void:
	var state := root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = PATH
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	state.set_process(false)
	View.prepare()
	var image := View.atlas.get_image()
	print("ART29: dimensions=%s alpha=%s origin=%s" % [image.get_size(), image.detect_alpha(), image.get_pixel(0, 0)])
	for kind: StringName in View.SITES:
		var source: Rect2 = View.sources[kind]
		var region := image.get_region(Rect2i(source))
		print("ART29: %s bounds=%s used=%s" % [kind, source, region.get_used_rect()])
	state.resources["wood"] = 3000
	state.resources["spirit_stone"] = 3000
	state.resources["food"] = 3000
	main._refresh_resources()
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main.sect_map.queue_redraw()
		await capture("empty")
	for kind: StringName in BuildingCatalog.BUILDINGS:
		main._construct_fixed_site(kind)
	main.fixed_site_card.hide()
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main.sect_map.queue_redraw()
		await capture("construction")
	state.process_construction(30)
	main._refresh_resources()
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main.sect_map.queue_redraw()
		await capture("built")
		main._open_fixed_site(&"disciple_quarters")
		await capture("residence-card")
		main.fixed_site_card.hide()
		for pair: Array in [["management", main.sect_heading], ["build-menu", main.management_heading], ["disciples", main.disciples_heading], ["growth", main.growth_heading], ["battle", main.battle_heading]]:
			main._open_management_panel(pair[1])
			await capture(pair[0])
		main._close_management_panel()
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("PASS: complete29 real GPU captures in two sizes, empty/construction/completed, group card and all five original management modules")
	quit()
