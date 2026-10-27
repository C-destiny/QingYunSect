extends SceneTree
const Planar = preload("res://scripts/world/planar_courtyard_sample.gd")
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const PATH := "res://tests/.test_all_ground22.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var planar := Planar.new()
	if not planar.has_method("site_ground_quad"):
		print("FAIL: only lumber has a calibrated ground; the other courtyards still use baked plot frames")
		quit(1)
		return
	root.get_node("SaveManager").save_path = PATH
	# This is a visual/save round-trip check, not an offline-time test. A real
	# second boundary can otherwise legitimately settle progress during load.
	root.get_node("SaveManager").unix_time_provider = func() -> int: return 5000
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var map: Control = main.sect_map
	map.complete_sect = false # Historical candidate22 plinth measurements, retained as a legacy-art regression.
	var state := root.get_node("GameState")
	state.resources["wood"] = 5000
	state.resources["spirit_stone"] = 5000
	for kind: StringName in BuildingCatalog.BUILDINGS:
		assert(Layout.construct(state, kind))
	state.process_construction(30)
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	# Independent hand-measured approximate slopes of each rendered plinth.
	# Quarters include its existing display calibration, not a new whole-building rotation.
	var slopes := {&"hall": Vector2(0.412, 0.50), &"scripture_library": Vector2(0.396, 0.405), &"lumber_yard": Vector2(0.508, 0.494), &"artifact_forge": Vector2(0.569, 0.480), &"disciple_quarters": Vector2(0.391, 0.560), &"spirit_mine": Vector2(0.523, 0.492)}
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await process_frame
		await process_frame
		for kind: StringName in Layout.SITES:
			var frame: Dictionary = map.FixedView.site_frame(map, kind)
			var pose: Transform2D = frame["sprite_transform"]
			var corners: PackedVector2Array = planar.call("site_ground_quad", map, kind)
			if kind in [&"training_ground", &"spirit_field"]:
				assert(corners.is_empty(), "round court and soil field must not receive rectangular paving")
			else:
				assert(corners.size() == 4)
				var u := (corners[1] - corners[0]).normalized()
				var v := (corners[3] - corners[0]).normalized()
				assert(absf(u.cross(Vector2(1, slopes[kind].x).normalized())) < 0.025, "wrong plinth U axis: " + String(kind))
				assert(absf(v.cross(Vector2(-1, slopes[kind].y).normalized())) < 0.025, "wrong plinth V axis: " + String(kind))
			assert((pose * Vector2(frame["foot"])).is_equal_approx(frame["foot"]))
			assert(absf(pose.x.x - 1.0) < 0.001 and absf(pose.y.x) < 0.001, "building columns must remain vertical")
			assert(map.FixedView.hit(map, map.FixedView.plaque_rect(map, kind).get_center()) == kind)
			map.all_ground_alignment = false
			assert(map.FixedView.site_frame(map, kind) == frame, "ground toggle must not move sprites or hit regions")
			map.all_ground_alignment = true
	assert(state.export_save_data() == snapshot)
	assert(root.get_node("SaveManager").save_game() and root.get_node("SaveManager").load_game())
	assert(JSON.parse_string(JSON.stringify(state.export_save_data())) == JSON.parse_string(JSON.stringify(snapshot)))
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("PASS: all eight sites, measured plinth axes, no rectangular court/field pad, unchanged sprites/hits and save roundtrip at both sizes")
	quit()
