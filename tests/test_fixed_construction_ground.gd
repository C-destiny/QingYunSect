extends SceneTree
const View = preload("res://scripts/world/fixed_sect_view.gd")
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const PATH := "res://tests/.test_construction23.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not View.new().has_method("construction_geometry"):
		print("FAIL: fixed construction still uses the old unscaled foot scaffold")
		quit(1)
		return
	root.get_node("SaveManager").save_path = PATH
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var map: Control = main.sect_map
	map.complete_sect = false # Candidate23's measured source-art construction plane.
	var state := root.get_node("GameState")
	state.resources["wood"] = 5000
	state.resources["spirit_stone"] = 5000
	for kind: StringName in BuildingCatalog.BUILDINGS:
		assert(Layout.construct(state, kind))
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	var checked_roofs := 0
	for size_value: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = size_value
		await process_frame
		await process_frame
		for kind: StringName in BuildingCatalog.BUILDINGS:
			var geometry: Dictionary = View.new().call("construction_geometry", map, kind)
			var base: PackedVector2Array = geometry["base"]
			var top: PackedVector2Array = geometry["top"]
			var hull: PackedVector2Array = geometry["hull"]
			assert(base.size() == 4 and top.size() == 4)
			for index: int in range(4):
				assert(is_equal_approx(top[index].x, base[index].x) and top[index].y < base[index].y)
			assert(View.hit(map, geometry["center"]) == kind, "visible scaffold center must select its own site")
			var frame: Dictionary = View.site_frame(map, kind)
			if kind == &"lumber_yard":
				# Independent reference-art measurement: base is near y335, not old foot y392.
				assert(Vector2(geometry["center"]).distance_to(Layout.point(Vector2(510, 338), map.size)) < 3 * frame["scale"])
			var spec: Dictionary = map.get_building_visual(kind)
			var rect: Rect2 = frame["rect"]
			var found_roof := false
			for y: float in [0.12, 0.18, 0.24, 0.30, 0.36, 0.42]:
				for x: float in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]:
					var local := rect.position + rect.size * Vector2(x, y)
					var screen: Vector2 = Transform2D(frame["sprite_transform"]) * local
					if not Geometry2D.is_point_in_polygon(screen, hull) and map._is_sprite_hit(spec["texture"], spec["source"], rect, local):
						assert(View.hit(map, screen) != kind, "invisible completed roof must not intercept construction clicks")
						found_roof = true
			if found_roof:
				checked_roofs += 1
	assert(checked_roofs >= 2, "fixture must exercise real opaque future-roof pixels outside scaffolds in both sizes")
	assert(state.export_save_data() == snapshot)
	state.process_construction(30)
	for kind: StringName in BuildingCatalog.BUILDINGS:
		assert(View.hit(map, View.plaque_rect(map, kind).get_center()) == kind)
	assert(root.get_node("SaveManager").save_game() and root.get_node("SaveManager").load_game())
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("PASS: seven grounded/scaled scaffolds, upright poles, visible hit and no phantom roof at both sizes, unchanged data and completed save/load")
	quit()
