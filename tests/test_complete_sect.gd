extends SceneTree

const PATH := "res://tests/.test_complete_sect.json"
var failures := 0

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _init() -> void:
	call_deferred("_run")

func cleanup() -> void:
	for suffix: String in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func _run() -> void:
	cleanup()
	var state := root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = PATH
	manager.unix_time_provider = func() -> int: return 5000
	var original: Dictionary = state.export_save_data().duplicate(true)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	check(main.sect_map.get("complete_sect") == true, "formal game must show complete sect, not two-building sample")
	if failures > 0:
		main.queue_free()
		await process_frame
		cleanup()
		quit(1)
		return
	check(state.export_save_data() == original, "opening new visual must not alter state")
	check(main.food_label.mouse_filter != Control.MOUSE_FILTER_IGNORE and main.disciples_label.mouse_filter != Control.MOUSE_FILTER_IGNORE, "original food/workforce details must remain reachable by hover")
	var stored_food: int = state.resources["food"]
	state.resources["food"] = 0
	main._refresh_resources()
	check(main.food_label.text.contains("缺粮"), "starvation warning remains visible in compact HUD")
	state.resources["food"] = stored_food
	main._refresh_resources()
	var view = load("res://scripts/world/complete_sect_view.gd")
	view.prepare()
	var atlas_image: Image = view.atlas.get_image()
	check(atlas_image.detect_alpha() == Image.ALPHA_BLEND, "independent production atlas has real alpha")
	check(atlas_image.get_pixel(0, 0).a < 0.01, "atlas background is transparent")
	check(view.SITES.size() == 8, "main hall plus seven existing functional precincts")
	for kind: StringName in view.SITES:
		check(view.is_built(state, kind) == (kind == &"hall"), "empty sites do not show free completed buildings")
	state.resources["wood"] = 3000
	state.resources["spirit_stone"] = 3000
	for kind: StringName in BuildingCatalog.BUILDINGS:
		var before: Dictionary = state.resources.duplicate(true)
		main._construct_fixed_site(kind)
		var record: Dictionary = state.buildings[-1]
		var definition: Dictionary = BuildingCatalog.get_data(kind)
		check(not record["completed"] and record["remaining"] == definition["build_time"], "original construction time")
		check(state.resources["wood"] == before["wood"] - definition["cost"]["wood"], "original wood cost")
		check(not view.is_built(state, kind), "construction cannot reveal finished structure")
	main.fixed_site_card.hide()
	for size_value: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = size_value
		await process_frame
		for kind: StringName in BuildingCatalog.BUILDINGS:
			var geometry: Dictionary = view.construction_geometry(main.sect_map, kind)
			check(view.hit(main.sect_map, geometry["center"]) == kind, "visible construction scaffold is independently clickable")
			var rect: Rect2 = view.site_frame(main.sect_map, kind)["rect"]
			var unseen_roof := rect.position + rect.size * Vector2(0.5, 0.15)
			if not Geometry2D.is_point_in_polygon(unseen_roof, geometry["hull"]) and not view.plaque_rect(main.sect_map, kind).grow(4).has_point(unseen_roof):
				check(view.hit(main.sect_map, unseen_roof) != kind, "unbuilt future roof does not intercept clicks")
	state.process_construction(30)
	var records: Array = state.buildings.duplicate(true)
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for size_value: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = size_value
		await process_frame
		await process_frame
		for kind: StringName in view.SITES:
			check(view.is_built(state, kind), "all paid completed sites visible")
			var plaque: Rect2 = main.sect_map.FixedView.plaque_rect(main.sect_map, kind)
			check(main.sect_map.FixedView.hit(main.sect_map, plaque.get_center()) == kind, "both-size distinct site selection: " + String(kind))
			check(view.world_rect(main.sect_map.size).encloses(plaque), "nameplate stays inside map")
			var source: Rect2 = view.sources[kind]
			var frame: Dictionary = view.site_frame(main.sect_map, kind)
			var picked_opaque := false
			for uv: Vector2 in [Vector2(0.5, 0.4), Vector2(0.4, 0.6), Vector2(0.6, 0.6), Vector2(0.5, 0.75)]:
				var pixel := Vector2i(source.position + source.size * uv)
				if atlas_image.get_pixelv(pixel).a > 0.8 and view.hit(main.sect_map, frame["rect"].position + frame["rect"].size * uv) == kind:
					picked_opaque = true
			check(picked_opaque, "actual opaque building pixels select their own precinct: " + String(kind))
		check(main.get_node_or_null("CompleteOverview") != null, "right-side complete-game overview")
		for heading: Control in [main.sect_heading, main.management_heading, main.disciples_heading, main.growth_heading, main.battle_heading]:
			main._open_management_panel(heading)
			await process_frame
			check(main.management_sidebar.visible, "all five original management categories available")
			check(main.sidebar_scroll.get_node("Info").get_children().any(func(section: Control) -> bool: return section.visible), "management category has real controls")
		main._close_management_panel()
	check(state.buildings == records, "visuals and navigation preserve IDs, cells, levels and counts")
	manager.save_path = "res://tests/missing-complete29-directory/fail.json"
	main._construct_fixed_site(&"disciple_quarters")
	check(JSON.stringify(state.export_save_data()) == JSON.stringify(snapshot), "failed save rolls back full construction state")
	manager.save_path = PATH
	check(manager.save_game() and manager.load_game(), "complete-game isolated save/load")
	check(JSON.parse_string(JSON.stringify(state.export_save_data())) == JSON.parse_string(JSON.stringify(snapshot)), "save round trip unchanged")
	main.queue_free()
	await process_frame
	cleanup()
	if failures == 0:
		print("PASS: complete sect default, eight precincts, original paid construction, both-size picking, full navigation and save compatibility")
	quit(1 if failures > 0 else 0)
