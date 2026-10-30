extends SceneTree

const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const Garden = preload("res://scripts/world/fixed_courtyard_details.gd")
const PATH := "res://tests/.test_garden_scene.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var state := root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = PATH
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	main.fixed_layout_preview = true # Explicit historical fixed-layout fixture.
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var map: Control = main.sect_map
	map.fixed_planar_sample = false # 历史候选17渲染链夹具。
	assert(map.fixed_layout and map.fixed_garden_scene)
	assert(map.FixedView.GARDEN_BACKDROP.get_size() == Layout.ART_SIZE)
	assert(Garden.items(map).is_empty())
	state.resources["wood"] = 5000
	state.resources["spirit_stone"] = 5000
	for kind: StringName in BuildingCatalog.BUILDINGS:
		assert(Layout.construct(state, kind))
	state.process_construction(30)
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for size_value: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = size_value
		await process_frame
		await process_frame
		for kind: StringName in Layout.SITES:
			var frame: Dictionary = map.FixedView.site_frame(map, kind)
			assert(Layout.world_rect(map.size).has_point(frame["foot"]))
			assert(map.FixedView.hit(map, map.FixedView.plaque_rect(map, kind).get_center()) == kind)
			if kind == &"hall":
				main._on_hall_selected()
			else:
				main._open_fixed_site(kind)
			main._dismiss_building_card()
			main.fixed_site_card.hide()
		map.queue_redraw()
		await process_frame
	assert(state.export_save_data() == snapshot)
	assert(manager.save_game() and manager.load_game())
	assert(JSON.parse_string(JSON.stringify(state.export_save_data())) == JSON.parse_string(JSON.stringify(snapshot)))
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("PASS: garden background dimensions, removed old decals, all fixed sites both-size input, unchanged data/save round trip")
	quit()
