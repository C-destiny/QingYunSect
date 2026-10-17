extends SceneTree

const OUTPUT_PATH := "res://builds/v08-art-preview.png"
const DRAWER_OUTPUT_PATH := "res://builds/v08-art-preview-drawer.png"
const TEST_SAVE_PATH := "res://tests/.capture_v08_art_preview.json"
var state: Node


func _init() -> void:
	call_deferred("_capture")


func _add_building(building_type: StringName, cell: Vector2i, level: int) -> void:
	state.buildings.append({
		"instance_id": state.next_building_id,
		"type": building_type,
		"cell_x": cell.x,
		"cell_y": cell.y,
		"remaining": 0.0,
		"build_time": 1.0,
		"completed": true,
		"level": level,
		"upgrading": false,
	})
	state.next_building_id += 1


func _capture() -> void:
	root.size = Vector2i(1920, 1080)
	state = root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = TEST_SAVE_PATH
	state.buildings.clear()
	_add_building(&"disciple_quarters", Vector2i(0, 0), 1)
	_add_building(&"lumber_yard", Vector2i(2, 0), 2)
	_add_building(&"spirit_mine", Vector2i(4, 0), 3)
	_add_building(&"spirit_field", Vector2i(7, 0), 1)
	_add_building(&"training_ground", Vector2i(0, 4), 2)
	_add_building(&"artifact_forge", Vector2i(4, 4), 3)
	_add_building(&"scripture_library", Vector2i(6, 4), 2)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for frame_index: int in range(5):
		await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(OUTPUT_PATH)
	assert(error == OK)
	main._navigate_sidebar(main.get_node("%BuildHeading"))
	for frame_index: int in range(5):
		await process_frame
	var drawer_image := root.get_texture().get_image()
	var drawer_error := drawer_image.save_png(DRAWER_OUTPUT_PATH)
	assert(drawer_error == OK)
	print("PASS: saved V0.8 art previews to %s and %s" % [OUTPUT_PATH, DRAWER_OUTPUT_PATH])
	quit()
