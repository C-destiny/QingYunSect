extends SceneTree

# 审计只生成隔离夹具与真实渲染证据，不读取玩家存档，也不代表视觉验收通过。
const OUTPUT_DIRECTORY := "res://builds/v08-scene-audit"
const TEST_SAVE_PATH := "res://tests/.test_v08_scene_audit.json"
const QUARTERS_CELL := Vector2i(3, 3)


func _init() -> void:
	call_deferred("_run")


func _capture(main: Control, map: Control, window_size: Vector2i, mode: String) -> void:
	root.size = window_size
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var filename := "%s/stage2-%s-%dx%d.png" % [
		OUTPUT_DIRECTORY, mode, window_size.x, window_size.y,
	]
	assert(root.get_texture().get_image().save_png(filename) == OK)
	var center: Vector2 = map._cell_to_screen(Vector2i(4, 3), map._map_origin())
	print("EVIDENCE: mode=%s window=%s map_size=%s hall_anchor=%s panel_visible=%s" % [
		mode, window_size, map.size, center, main.management_sidebar.visible,
	])


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	var manager := root.get_node("SaveManager")
	manager.save_path = TEST_SAVE_PATH
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	main._close_management_panel()
	var state := root.get_node("GameState")
	var map: Control = main.sect_map
	# 样板使用真实建造入口生成合成建筑；夹具不保存，原建筑与玩家库存不受影响。
	assert(state.start_construction(&"disciple_quarters", QUARTERS_CELL))
	state.process_construction(float(BuildingCatalog.get_data(&"disciple_quarters")["build_time"]))
	assert(bool(state.buildings[0]["completed"]))
	assert(map.GRID_SIZE == Vector2i(12, 8))
	assert(map.TILE_SIZE == Vector2(104, 52))
	assert(state.is_cell_occupied(Vector2i(4, 3)))
	# 坐标往返验证只检查现状契约；不把通过此检查解释为贴图已正确接地。
	for x: int in range(map.GRID_SIZE.x):
		for y: int in range(map.GRID_SIZE.y):
			var cell := Vector2i(x, y)
			assert(map._screen_to_cell(map._cell_to_screen(cell, map._map_origin()), map._map_origin()) == cell)
	for window_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		map.cancel_placement()
		map.clear_selection()
		await _capture(main, map, window_size, "normal")
		map.start_placement(&"disciple_quarters")
		map.hovered_cell = Vector2i(5, 4)
		map.queue_redraw()
		await _capture(main, map, window_size, "construction")
	for asset: Texture2D in [map.MAP_BACKDROP, map.BUILDING_ATLAS, map.LANDMARK_ATLAS]:
		print("EVIDENCE: asset=%s dimensions=%s" % [asset.resource_path, asset.get_size()])
		var asset_image := asset.get_image()
		print("EVIDENCE: alpha corner=%.3f upper_center=%.3f center=%.3f" % [
			asset_image.get_pixel(0, 0).a,
			asset_image.get_pixel(asset_image.get_width() / 2, 0).a,
			asset_image.get_pixel(asset_image.get_width() / 2, asset_image.get_height() / 2).a,
		])
	main.queue_free()
	await process_frame
	print("PASS: isolated visual baseline capture only; artistic quality awaits review")
	quit()
