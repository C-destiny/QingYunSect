extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_v08_visual_ui.json"


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	var manager := root.get_node("SaveManager")
	manager.save_path = TEST_SAVE_PATH
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame

	assert(main.theme != null)
	assert(main.theme.has_stylebox("normal", "Button"))
	assert(main.theme.has_stylebox("panel", "PanelContainer"))
	var body: Control = main.get_node("Layout/Body")
	var sidebar: Control = main.get_node("Layout/Body/Sidebar")
	var map: Control = main.get_node("%SectMap")
	assert(not (body is HBoxContainer))
	assert(sidebar.custom_minimum_size.x == 560.0)
	assert(not sidebar.visible)
	assert(main.get_node("Layout/Body/BottomNav").visible)
	for button_name: String in [
		"OpenSectPanelButton",
		"OpenBuildPanelButton",
		"OpenDisciplesPanelButton",
		"OpenGrowthPanelButton",
		"OpenBattlePanelButton",
	]:
		assert(main.get_node("%%%s" % button_name) is Button)
	main._open_management_panel(main.get_node("%RosterHeading"))
	assert(sidebar.visible)
	main._close_management_panel()
	assert(not sidebar.visible)
	assert(ProjectSettings.get_setting("display/window/size/viewport_width") == 1920)
	assert(ProjectSettings.get_setting("display/window/size/viewport_height") == 1080)
	assert(ProjectSettings.get_setting("display/window/size/window_width_override") == 1280)
	assert(ProjectSettings.get_setting("display/window/size/window_height_override") == 720)
	assert(map.GRID_SIZE == Vector2i(12, 8))
	assert(map.TILE_SIZE == Vector2(104.0, 52.0))

	var selector: OptionButton = main.get_node("%CoreCharacterSelector")
	var preview: TextureRect = main.get_node("%CoreCharacterPreview")
	var caption: Label = main.get_node("%CoreCharacterCaption")
	assert(selector.item_count == 2)
	assert("崔云川" in selector.get_item_text(0))
	assert("周墨" in selector.get_item_text(1))
	var first_texture := preview.texture
	selector.select(1)
	main._on_core_character_selected(1)
	assert(preview.texture != null and preview.texture != first_texture)
	assert("周墨" in caption.text)
	assert("不新增角色数据" in caption.text)

	for asset_path: String in [
		"res://assets/characters/cui_yunchuan_model.png",
		"res://assets/characters/zhou_mo_model.png",
	]:
		var texture := load(asset_path) as Texture2D
		assert(texture != null)
		var image := texture.get_image()
		assert(not image.is_empty())
		assert(image.get_width() == 1024 and image.get_height() == 1536)
		assert(image.get_pixel(0, 0).a < 0.05)
	var total_character_bytes := FileAccess.get_file_as_bytes("res://assets/characters/cui_yunchuan_model.png").size()
	total_character_bytes += FileAccess.get_file_as_bytes("res://assets/characters/zhou_mo_model.png").size()
	assert(total_character_bytes < 6 * 1024 * 1024)

	var map_backdrop := load("res://assets/environment/sect_floating_mountain.png") as Texture2D
	var building_atlas := load("res://assets/buildings/sect_buildings_atlas.png") as Texture2D
	var landmark_atlas := load("res://assets/environment/sect_landmarks_atlas.png") as Texture2D
	assert(map_backdrop != null and map_backdrop.get_width() >= 1600 and map_backdrop.get_height() >= 900)
	assert(building_atlas != null and building_atlas.get_width() >= 1600 and building_atlas.get_height() >= 900)
	assert(landmark_atlas != null and landmark_atlas.get_width() == 1536 and landmark_atlas.get_height() == 1024)
	assert(building_atlas.get_image().get_pixel(0, 0).a < 0.05)
	assert(landmark_atlas.get_image().get_pixel(0, 0).a < 0.05)

	main.queue_free()
	_cleanup()
	print("PASS: V0.8 theme, full-map drawer navigation, map contract, painted environment atlases, and two transparent character models")
	quit()
