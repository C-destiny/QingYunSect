extends RefCounted

const Overview = preload("res://scripts/ui/complete_sect_overview.gd")

static func panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

static func apply(main: Control) -> void:
	var header: PanelContainer = main.get_node("Layout/Header")
	header.offset_left = 8
	header.offset_right = -8
	header.offset_top = 8
	header.offset_bottom = 78
	header.add_theme_stylebox_override("panel", panel_style(Color("19383c"), Color("a38e62")))
	var resources: Control = header.get_node("Margin/Row/Resources")
	# Retain the original resource buttons/signals; the painted backing is redundant here.
	resources.set_script(null)
	for button: Button in [main.wood_label, main.spirit_stone_label, main.food_label, main.disciples_label]:
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.custom_minimum_size.x = 215 if button == main.disciples_label else 185
		button.add_theme_constant_override("icon_max_width", 30)
		button.add_theme_font_size_override("font_size", 21)
	var nav: PanelContainer = main.get_node("Layout/Body/BottomNav")
	nav.offset_left = -500
	nav.offset_right = 500
	nav.offset_top = -82
	nav.offset_bottom = -8
	nav.add_theme_stylebox_override("panel", panel_style(Color("19383c"), Color("a38e62")))
	for child: Node in nav.get_children():
		if child.get_script() == preload("res://scripts/ui/hud_plate.gd"):
			child.hide()
	for button: Button in [main.open_sect_panel_button, main.open_build_panel_button, main.open_disciples_panel_button, main.open_growth_panel_button, main.open_battle_panel_button]:
		button.compact = true
		button.custom_minimum_size = Vector2(175, 58)
		button.queue_redraw()
	main.management_sidebar.offset_top = 94
	main.management_sidebar.offset_bottom = -94
	var overview := PanelContainer.new()
	overview.name = "CompleteOverview"
	overview.set_script(Overview)
	main.add_child(overview)
	overview.configure(main)
	main.building_card.visibility_changed.connect(overview.refresh_visibility)
	main.fixed_site_card.visibility_changed.connect(overview.refresh_visibility)
	main.management_sidebar.visibility_changed.connect(overview.refresh_visibility)
	main._refresh_resources()

static func dock_card(main: Control, card: Control) -> void:
	card.position = Vector2(main.size.x - card.size.x - 18, 100)
	card.position.y = minf(card.position.y, main.size.y - 100 - card.size.y)
