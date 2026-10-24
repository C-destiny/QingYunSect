extends SceneTree
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
var main: Control
var failed := false
func _init() -> void:
	call_deferred("_run")
func both(label: String) -> void:
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		main.sect_map.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		var error := capture.save_png("res://builds/v08-scene-audit/courtyard19-%s-%dx%d.png" % [label, view.x, view.y])
		assert(error == OK)
		if label == "empty":
			# 实际渲染院坪必须有材质细节，而不是几种纯色组成的网格板。
			var shades := {}
			for y: int in range(260, 276, 2):
				for x: int in range(720, 760, 2):
					var at: Vector2 = root.get_final_transform() * main.sect_map.get_global_transform_with_canvas() * Layout.point(Vector2(x, y), main.sect_map.size)
					var pixel := capture.get_pixelv(Vector2i(at))
					shades[Vector3i(roundi(pixel.r * 32), roundi(pixel.g * 32), roundi(pixel.b * 32))] = true
			print("GROUND_QA view=", view, " shades=", shades.size(), " map=", main.sect_map.get_global_rect())
			if shades.size() <= 30:
				failed = true
				push_error("FAIL: 院坪仍为素色板，石材变化不足")
func _run() -> void:
	root.get_node("SaveManager").save_path = "res://tests/.test_planar_audit.json"
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var state := root.get_node("GameState")
	state.resources["wood"] = 5000
	state.resources["spirit_stone"] = 5000
	main._refresh_resources()
	await both("empty")
	assert(Layout.construct(state, &"disciple_quarters"))
	state.process_construction(2)
	await both("construction")
	state.process_construction(30)
	await both("sample")
	main.sect_map.planar_guides = true
	await both("guides")
	main.sect_map.planar_guides = false
	for kind: StringName in BuildingCatalog.BUILDINGS:
		if kind != &"disciple_quarters":
			assert(Layout.construct(state, kind))
	state.process_construction(30)
	main._refresh_resources()
	await both("context")
	main.sect_map.fixed_selected_kind = &"disciple_quarters"
	await both("selected")
	main._open_fixed_site(&"disciple_quarters")
	await both("card")
	main.queue_free()
	await process_frame
	if not failed:
		print("PASS: courtyard19 textured ground, empty, construction, sample, guide axes, full context, outline and card in two sizes")
	quit(1 if failed else 0)
