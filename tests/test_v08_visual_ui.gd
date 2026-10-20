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
	main.set_process(false)
	main.autosave_timer.stop()
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
	assert(main.get_node("Layout") is Control and not (main.get_node("Layout") is VBoxContainer))
	assert(main.get_node("Layout/Header").z_index > main.get_node("Layout/Body/MapPanel").z_index)
	for resource_name: String in ["Wood", "SpiritStone", "Food", "Disciples"]:
		var resource_button := main.get_node("%%%s" % resource_name) as Button
		assert(resource_button != null and resource_button.icon != null)
	assert(main.get_node("Layout/Body/BottomNav").visible)
	for button_name: String in [
		"OpenSectPanelButton",
		"OpenBuildPanelButton",
		"OpenDisciplesPanelButton",
		"OpenGrowthPanelButton",
		"OpenBattlePanelButton",
	]:
		var nav_button := main.get_node("%%%s" % button_name) as Button
		assert(nav_button != null and nav_button.icon != null)
	main._open_management_panel(main.get_node("%RosterHeading"))
	await process_frame
	await process_frame
	assert(sidebar.visible)
	var close_button := main.get_node("%CloseManagementButton") as Button
	assert(close_button.get_parent() == sidebar)
	close_button.pressed.emit()
	await process_frame
	assert(not sidebar.visible)
	main.get_node("%OpenBuildPanelButton").pressed.emit()
	await process_frame
	assert(sidebar.visible)
	main.get_node("%OpenBuildPanelButton").pressed.emit()
	assert(not sidebar.visible)
	# 每个入口只能显示该分类，数据刷新不得重新暴露其他分类内容。
	var module_cases := [
		["OpenSectPanelButton", "SectSection", "宗门管理"],
		["OpenBuildPanelButton", "BuildSection", "建设管理"],
		["OpenDisciplesPanelButton", "RosterSection", "弟子管理"],
		["OpenGrowthPanelButton", "EquipmentSection", "养成管理"],
		["OpenBattlePanelButton", "BattleSection", "挂机管理"],
	]
	var info := main.get_node("Layout/Body/Sidebar/Margin/Scroll/Info")
	for window_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = window_size
		await process_frame
		await process_frame
		var header: Control = main.get_node("Layout/Header")
		var nav: Control = main.get_node("Layout/Body/BottomNav")
		var bounds := Rect2(Vector2.ZERO, main.size)
		assert(bounds.encloses(header.get_global_rect()))
		assert(bounds.encloses(nav.get_global_rect()))
		assert(header.size.y <= 82.0 and nav.size.y <= 76.0)
		assert(is_equal_approx(nav.get_global_rect().get_center().x, main.size.x * 0.5))
		assert(header.get_global_rect().end.y < sidebar.get_global_rect().position.y)
		assert(sidebar.get_global_rect().end.y < nav.get_global_rect().position.y)
		# 缩减HUD不能裁掉资源文字、图标或遮住主殿脚点。
		for resource_name: String in ["Wood", "SpiritStone", "Food", "Disciples"]:
			var button: Button = main.get_node("%%%s" % resource_name)
			assert(header.get_global_rect().encloses(button.get_global_rect()))
			var text_width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			assert(text_width + button.get_theme_constant("icon_max_width") + 20.0 <= button.size.x)
		var hall_anchor: Vector2 = map._cell_to_screen(Vector2i(4, 3), map._map_origin()) + map.global_position
		assert(not header.get_global_rect().has_point(hall_anchor))
		assert(not nav.get_global_rect().has_point(hall_anchor))
		for module_case: Array in module_cases:
			main._close_management_panel()
			main.get_node("%" + module_case[0]).pressed.emit()
			await process_frame
			await process_frame
			assert(sidebar.visible)
			assert(sidebar.get_node("PanelTitle").text == module_case[2])
			main._refresh_resources()
			main._refresh_disciple_roster()
			for other_case: Array in module_cases:
				assert(info.get_node(other_case[1]).is_visible_in_tree() == (other_case == module_case))
			assert(sidebar.position.y < 200.0)
			assert(sidebar.get_global_rect().encloses(close_button.get_global_rect()))
			assert(absf(close_button.global_position.y - sidebar.get_node("PanelTitle").global_position.y) < 10.0)
			assert(main.sidebar_scroll.scroll_vertical == 0)
			# 专项可选截图使用真实渲染，常规无头回归不会等待渲染帧。
			if "--capture-preview" in OS.get_cmdline_user_args() and window_size == Vector2i(1280, 720):
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://builds/module-%s.png" % module_case[1])
			var cancel_event := InputEventAction.new()
			cancel_event.action = "ui_cancel"
			cancel_event.pressed = true
			main._unhandled_input(cancel_event)
			assert(not sidebar.visible)
	# 地图点击也应切到相应分类，不能沿用刚才的挂机分类。
	main._on_resource_selected(main.sect_map.resource_nodes[0])
	assert(info.get_node("SectSection").is_visible_in_tree())
	assert(info.get_node("SelectionSection").is_visible_in_tree())
	assert(not info.get_node("BattleSection").is_visible_in_tree())
	main._on_region_selected(&"east")
	assert(info.get_node("SelectionSection").is_visible_in_tree())
	main._close_management_panel()
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
	var ui_icon_atlas := load("res://assets/ui/qingyun_ui_icon_atlas.png") as Texture2D
	assert(map_backdrop != null and map_backdrop.get_width() >= 1600 and map_backdrop.get_height() >= 900)
	assert(building_atlas != null and building_atlas.get_width() >= 1600 and building_atlas.get_height() >= 900)
	assert(landmark_atlas != null and landmark_atlas.get_width() == 1536 and landmark_atlas.get_height() == 1024)
	assert(ui_icon_atlas != null and ui_icon_atlas.get_width() == 1284 and ui_icon_atlas.get_height() == 1225)
	assert(building_atlas.get_image().get_pixel(0, 0).a < 0.05)
	assert(landmark_atlas.get_image().get_pixel(0, 0).a < 0.05)
	assert(ui_icon_atlas.get_image().get_pixel(0, 0).a < 0.05)

	main.queue_free()
	_cleanup()
	print("PASS: V0.8 theme, full-map drawer navigation, map contract, painted environment atlases, and two transparent character models")
	quit()
