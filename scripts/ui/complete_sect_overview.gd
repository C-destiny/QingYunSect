extends PanelContainer

var main: Control
var summary: Label
var battle_summary: Label

func configure(owner_main: Control) -> void:
	main = owner_main
	set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	offset_left = -378
	offset_right = -10
	offset_top = 92
	offset_bottom = -96
	z_index = 9
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ede3cb")
	style.border_color = Color("9e8d67")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 24
	style.content_margin_bottom = 20
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 15)
	add_child(column)
	var title := Label.new()
	title.text = "青云宗 · 宗门总览"
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("263d38"))
	column.add_child(title)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_color_override("font_color", Color("40534a"))
	summary.add_theme_font_size_override("font_size", 19)
	column.add_child(summary)
	column.add_child(HSeparator.new())
	var hint := Label.new()
	hint.text = "点击院落查看建设与升级\n所有院落沿用原资源与工期"
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color("6f715b"))
	column.add_child(hint)
	var captions := ["招募弟子", "岗位分配", "修炼与突破", "装备与锻造", "挂机战斗"]
	var targets: Array[Control] = [main.disciples_heading, main.disciples_heading, main.growth_heading, main.growth_heading, main.battle_heading]
	for index: int in range(captions.size()):
		var button := Button.new()
		button.text = captions[index]
		button.custom_minimum_size.y = 62
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(main._open_management_panel.bind(targets[index]))
		column.add_child(button)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	battle_summary = Label.new()
	battle_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_summary.add_theme_font_size_override("font_size", 18)
	battle_summary.add_theme_color_override("font_color", Color("40534a"))
	column.add_child(battle_summary)
	for child: Node in column.get_children():
		if child is Label:
			child.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	var state := main.get_node("/root/GameState")
	for signal_name: StringName in [&"resources_changed", &"buildings_changed", &"disciples_changed", &"sect_progress_changed", &"battle_changed"]:
		state.connect(signal_name, refresh)
	refresh()
	refresh_visibility()

func refresh() -> void:
	summary.text = "宗门等级  %d\n弟子  %d / %d\n院落建筑  %d 座" % [main.get_node("/root/GameState").sect_level, main.get_node("/root/GameState").total_disciples, main.get_node("/root/GameState").get_disciple_capacity(), main.get_node("/root/GameState").buildings.size()]
	battle_summary.text = "挂机与队伍\n" + main.battle_party_status.text

func refresh_visibility() -> void:
	visible = not (main.management_sidebar.visible or main.building_card.visible or main.fixed_site_card.visible)
