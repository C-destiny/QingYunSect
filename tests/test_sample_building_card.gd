extends SceneTree

const TEST_PATH := "res://tests/.test_sample_building_card.json"
const ProjectionData = preload("res://scripts/world/sect_projection.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + suffix))
	var manager := root.get_node("SaveManager")
	manager.save_path = TEST_PATH
	var state := root.get_node("GameState")
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.sect_map.fixed_layout = false # 历史自由地图/边缘卡片回归；固定场景另有专项。
	main.set_process(false)
	main.autosave_timer.stop()
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	assert(state.start_construction(&"disciple_quarters", Vector2i(3, 3)))
	assert(state.start_construction(&"disciple_quarters", Vector2i(7, 5)))
	state.process_construction(20)
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	var map: Control = main.sect_map
	assert(preload("res://scripts/data/territory_catalog.gd").get_map_bounds() == Rect2i(0, 0, 12, 8))
	# 同一投影可解释扩展范围，不会根据新地图尺寸重排旧格；不改变生产配置。
	for bounds: Rect2i in [Rect2i(0, 0, 12, 8), Rect2i(0, 0, 32, 24)]:
		for x: int in range(bounds.size.x):
			for y: int in range(bounds.size.y):
				var cell := Vector2i(x, y)
				var point := ProjectionData.project(cell, Vector2(100, 200))
				assert(ProjectionData.unproject(point, Vector2(100, 200), bounds) == cell)
	for window_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = window_size
		await process_frame
		# 两侧都放不下时，上方仍有空位；旧的仅左右夹取会盖住建筑。
		var safe := Rect2(24, 104, 700, 650)
		var wide_building := Rect2(270, 440, 210, 180)
		main.building_card.place_near(wide_building, safe)
		assert(safe.encloses(main.building_card.get_rect()))
		assert(not main.building_card.get_rect().intersects(wide_building))
		for kind: StringName in BuildingCatalog.BUILDINGS:
			for level: int in range(1, 4):
				for cell: Vector2i in [Vector2i(0, 0), Vector2i(11, 0), Vector2i(0, 7), Vector2i(11, 7), Vector2i(5, 4)]:
					var fixture := {"type": kind, "cell_x": cell.x, "cell_y": cell.y, "level": level}
					var visual: Rect2 = map.get_building_visual_rect(fixture, map._map_origin())
					visual.position += map.global_position - main.global_position
					var viewport_safe := Rect2(Vector2(24, 104), main.size - Vector2(48, 214))
					main.building_card.place_near(visual, viewport_safe)
					assert(viewport_safe.encloses(main.building_card.get_rect()))
					assert(not main.building_card.get_rect().intersects(visual))
		for building: Dictionary in state.buildings:
			main._on_building_selected(building)
			await process_frame
			main._refresh_building_card()
			assert(main.building_card.visible and not main.management_sidebar.visible)
			var card_rect: Rect2 = main.building_card.get_global_rect()
			assert(Rect2(Vector2.ZERO, main.size).encloses(card_rect))
			assert(not card_rect.intersects(main.get_node("Layout/Body/BottomNav").get_global_rect()))
			var cell := Vector2i(building["cell_x"], building["cell_y"])
			var visual_rect: Rect2 = map.get_grounded_rect(map._cell_to_screen(cell, map._map_origin()) + map.global_position, map.QUARTERS_VISUAL)
			assert(not card_rect.intersects(visual_rect))
			main.building_card.manage_button.pressed.emit()
			assert(main.management_sidebar.visible and not main.building_card.visible)
		main._on_hall_selected()
		assert(main.building_card.visible and main.card_is_hall)
		var cancel := InputEventAction.new()
		cancel.action = "ui_cancel"
		cancel.pressed = true
		main._unhandled_input(cancel)
		assert(not main.building_card.visible)
		main._on_building_selected(state.buildings[0])
		main.building_card.close_button.pressed.emit()
		await process_frame
		assert(not main.building_card.visible)
		main._on_building_selected(state.buildings[0])
		main._start_building_placement(&"disciple_quarters")
		assert(not main.building_card.visible and not main.management_sidebar.visible)
		assert(map.placement_building == &"disciple_quarters")
		main._cancel_building_placement()
	var hall_click := InputEventMouseButton.new()
	hall_click.button_index = MOUSE_BUTTON_LEFT
	hall_click.pressed = true
	hall_click.position = map._cell_to_screen(map.MAIN_HALL_CELL, map._map_origin())
	map._gui_input(hall_click)
	assert(main.building_card.visible and main.card_is_hall)
	assert(map.GARDEN_POND.get_image().get_pixel(0, 0).a < 0.01)
	assert(state.export_save_data() == snapshot)
	main._on_building_selected(state.buildings[0])
	var instance_id: int = state.buildings[0]["instance_id"]
	main.building_card.upgrade_button.pressed.emit()
	assert(state.get_building(instance_id)["upgrading"])
	assert(FileAccess.file_exists(TEST_PATH))
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + suffix))
	print("PASS: expansion-ready projection, unchanged state, card edge placement, close/manage/Esc/placement and upgrade intent")
	quit()
