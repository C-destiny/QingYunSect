extends SceneTree

const Blend = preload("res://scripts/world/fixed_courtyard_blend.gd")
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const Garden = preload("res://scripts/world/fixed_courtyard_details.gd")
const PATH := "res://tests/.test_courtyard_blend.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var state := root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = PATH
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	var map: Control = main.sect_map
	map.fixed_garden_scene = false # 保留候选16局部绘制链的回归夹具，不代表当前普通场景。
	assert(map.fixed_layout and map.fixed_courtyard_blend)
	assert(Blend.BACKGROUND.get_size() == Layout.ART_SIZE)
	assert(Blend.occupied(state, &"hall"))
	assert(not Blend.occupied(state, &"disciple_quarters"))
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	assert(Layout.construct(state, &"disciple_quarters"))
	assert(not Blend.occupied(state, &"disciple_quarters"))
	state.process_construction(6)
	assert(Blend.occupied(state, &"disciple_quarters"))
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for view: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view
		await process_frame
		await process_frame
		for kind: StringName in Blend.CONNECTIONS:
			var route := Blend.entrance_route(map, kind)
			var frame: Dictionary = map.FixedView.site_frame(map, kind)
			assert(route.size() == 2 and route[0].is_equal_approx(frame["entrance"]))
			assert(route[0].distance_to(route[1]) < 180)
			assert(Layout.world_rect(map.size).has_point(route[1]))
			assert(map.FixedView.hit(map, map.FixedView.plaque_rect(map, kind).get_center()) == kind)
		var previous := -INF
		for item: Dictionary in Garden.items(map):
			assert(item["depth"] >= previous)
			assert(Rect2(Vector2.ZERO, map.size).encloses(item["rect"]))
			previous = item["depth"]
		assert(Garden.items(map).size() == 8)
		map.fixed_courtyard_blend = false
		assert(Garden.items(map).size() == 3)
		map.fixed_courtyard_blend = true
		map.queue_redraw()
		await process_frame
	assert(state.export_save_data() == snapshot)
	assert(manager.save_game() and manager.load_game())
	assert(JSON.parse_string(JSON.stringify(state.export_save_data())) == JSON.parse_string(JSON.stringify(snapshot)))
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	print("PASS: courtyard blend source dimensions, occupied states, entrance continuity, two-size depth/input and unchanged save round trip")
	quit()
