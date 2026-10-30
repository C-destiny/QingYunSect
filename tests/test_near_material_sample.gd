extends SceneTree
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const PATH := "res://tests/.test_material24.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.get_node("SaveManager").save_path = PATH
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	main.fixed_layout_preview = true # Explicit historical fixed-layout fixture.
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var map: Control = main.sect_map
	if map.get("near_material_sample") != true:
		print("FAIL: lumber near terrain still samples the low-detail whole-scene underlay")
		main.queue_free()
		await process_frame
		quit(1)
		return
	var texture := load("res://assets/environment/sect_lumber_near24.png") as Texture2D
	assert(texture != null and texture.get_width() >= 1320 and texture.get_height() >= 880)
	assert(absf(float(texture.get_width()) / texture.get_height() - 1.5) < 0.01)
	if not texture.get_image().has_mipmaps() or map.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS:
		print("FAIL: high-resolution terrain lacks minification filtering and aliases at game scale")
		main.queue_free()
		await process_frame
		quit(1)
		return
	var state := root.get_node("GameState")
	state.resources["wood"] = 5000
	state.resources["spirit_stone"] = 5000
	for kind: StringName in BuildingCatalog.BUILDINGS:
		assert(Layout.construct(state, kind))
	state.process_construction(30)
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await process_frame
		await process_frame
		for kind: StringName in Layout.SITES:
			var frame: Dictionary = map.FixedView.site_frame(map, kind)
			var construction: Dictionary = map.FixedView.construction_geometry(map, kind)
			var spec: Dictionary = map.get_building_visual(kind) if kind != &"hall" else {}
			map.near_material_sample = false
			assert(map.FixedView.site_frame(map, kind) == frame)
			assert(map.FixedView.construction_geometry(map, kind) == construction)
			if kind != &"hall":
				assert(map.get_building_visual(kind) == spec, "material experiment must not alter building sprites")
			assert(map.FixedView.hit(map, map.FixedView.plaque_rect(map, kind).get_center()) == kind)
			map.near_material_sample = true
	assert(state.export_save_data() == snapshot)
	main.queue_free()
	await process_frame
	print("PASS: high-resolution local terrain, unchanged building/ground/construction frames and hits, unchanged save data in both sizes")
	quit()
