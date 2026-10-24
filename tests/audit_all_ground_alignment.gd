extends SceneTree
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
var main: Control
var sheet: Image

func _init() -> void:
	call_deferred("_run")

func capture(label: String, details: bool = false) -> Image:
	main.sect_map.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	assert(shot.save_png("res://builds/v08-scene-audit/grounds22-%s-%dx%d.png" % [label, root.size.x, root.size.y]) == OK)
	if details:
		var index := 0
		for kind: StringName in Layout.SITES:
			var foot: Vector2 = root.get_final_transform() * main.sect_map.get_global_transform_with_canvas() * Layout.point(Layout.SITES[kind]["foot"], main.sect_map.size)
			var extent := (Vector2(390, 360) if kind == &"hall" else Vector2(310, 270)) * root.size.x / 1920.0
			var anchor := Vector2(0.5, 0.85 if kind == &"hall" else 0.76)
			var detail := shot.get_region(Rect2i(foot - extent * anchor, extent))
			assert(detail.save_png("res://builds/v08-scene-audit/grounds22-%s-%s-%dx%d.png" % [label, kind, root.size.x, root.size.y]) == OK)
			if label == "after" and root.size.x == 1920:
				sheet.blit_rect(detail, Rect2i(Vector2i.ZERO, detail.get_size()), Vector2i((index % 4) * 390, (index / 4) * 360))
			index += 1
	return shot

func _run() -> void:
	root.get_node("SaveManager").save_path = "res://tests/.test_ground22_audit.json"
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var state := root.get_node("GameState")
	state.resources["wood"] = 5000
	state.resources["spirit_stone"] = 5000
	root.size = Vector2i(1920, 1080)
	await capture("empty")
	assert(Layout.construct(state, &"lumber_yard"))
	await capture("construction")
	for kind: StringName in BuildingCatalog.BUILDINGS:
		if kind != &"lumber_yard":
			assert(Layout.construct(state, kind))
	state.process_construction(30)
	main._refresh_resources()
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	sheet = Image.create(1560, 720, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("182326"))
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		main.fixed_site_card.hide()
		main.sect_map.all_ground_alignment = false
		var before := await capture("before", true)
		main.sect_map.all_ground_alignment = true
		var after := await capture("after", true)
		var to_screen: Transform2D = root.get_final_transform() * main.sect_map.get_global_transform_with_canvas()
		for kind: StringName in Layout.SITES:
			if kind == &"lumber_yard":
				continue
			var changed := 0
			var foot: Vector2 = Layout.SITES[kind]["foot"]
			for y: int in range(-55, 26, 5):
				for x: int in range(-125, 126, 5):
					var pixel := Vector2i(to_screen * Layout.point(foot + Vector2(x, y), main.sect_map.size))
					if before.get_pixelv(pixel) != after.get_pixelv(pixel):
						changed += 1
			print("SITE_FRAMEBUFFER: %s %dpx width=%d" % [kind, changed, view.x])
			if changed < 30:
				print("FAIL: site still uses old ground: " + String(kind))
				quit(1)
				return
		for source: Vector2 in [Vector2(1500, 200), Vector2(1400, 800), Vector2(50, 500), Vector2(900, 450)]:
			var pixel := Vector2i(to_screen * Layout.point(source, main.sect_map.size))
			assert(before.get_pixelv(pixel) == after.get_pixelv(pixel), "unrelated scenery/path sample changed")
		for kind: StringName in Layout.SITES:
			main.sect_map.fixed_selected_kind = kind
			await capture("selected-" + String(kind))
			main._open_fixed_site(kind)
			await capture("card-" + String(kind))
			main.fixed_site_card.hide()
			main.sect_map.fixed_selected_kind = &""
	assert(sheet.save_png("res://builds/v08-scene-audit/grounds22-contact-sheet.png") == OK)
	assert(state.export_save_data() == snapshot)
	main.queue_free()
	await process_frame
	print("PASS: grounds22 all eight native detail crops, two-size real before/after, seven changed grounds, four unchanged scenery/path samples, every selection/card, empty/construction and unchanged state")
	quit()
