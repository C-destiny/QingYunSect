extends SceneTree
const PlanarData = preload("res://scripts/world/planar_courtyard_sample.gd")
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const PATH := "res://tests/.test_planar_courtyard.json"
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var manager := root.get_node("SaveManager")
	manager.save_path = PATH
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var map: Control = main.sect_map
	map.complete_sect = false # Preserve candidate18's sprite basis/ground regression independently of29.
	var state := root.get_node("GameState")
	assert(map.fixed_planar_sample)
	assert(PlanarData.UNDERLAY.get_size() == Layout.ART_SIZE)
	assert(PlanarData.AXIS_U.cross(PlanarData.AXIS_V) > 0.9)
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	assert(Layout.construct(state, &"disciple_quarters"))
	state.process_construction(6)
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await process_frame
		await process_frame
		for kind: StringName in PlanarData.SITES:
			var frame: Dictionary = map.FixedView.site_frame(map, kind)
			var pose: Transform2D = frame["sprite_transform"]
			assert((pose * Vector2(frame["foot"])).is_equal_approx(frame["foot"]))
			if kind == &"disciple_quarters":
				assert(absf(pose.basis_xform(Vector2(1, 0.53)).cross(PlanarData.AXIS_U)) < 0.0001)
				assert(absf(pose.basis_xform(Vector2(-1, 0.55)).cross(PlanarData.AXIS_V)) < 0.0001)
			var origin: Vector2 = frame["entrance"]
			var yard: Rect2 = PlanarData.SITES[kind]["yard"]
			var path: Rect2 = PlanarData.SITES[kind]["path"]
			assert(is_equal_approx(yard.end.y, path.position.y))
			var corners := PlanarData.quad(origin, yard, frame["scale"])
			assert(absf((corners[1] - corners[0]).cross(PlanarData.AXIS_U)) < 0.001)
			assert(absf((corners[3] - corners[0]).cross(PlanarData.AXIS_V)) < 0.001)
			assert(map.FixedView.hit(map, map.FixedView.plaque_rect(map, kind).get_center()) == kind)
			var rect: Rect2 = frame["rect"]
			var local_point := rect.position + rect.size * Vector2(0.5, 0.60)
			var screen_point := pose * local_point
			assert((pose.affine_inverse() * screen_point).is_equal_approx(local_point))
			assert(map.FixedView.hit(map, screen_point) == kind)
		map.planar_guides = true
		map.queue_redraw()
		await process_frame
	assert(state.export_save_data() == snapshot)
	assert(manager.save_game() and manager.load_game())
	assert(JSON.parse_string(JSON.stringify(state.export_save_data())) == JSON.parse_string(JSON.stringify(snapshot)))
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("PASS: planar axes, calibrated sprite basis, anchored feet, exact path join, both-size inverse alpha hit and unchanged saves")
	quit()
