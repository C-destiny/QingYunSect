extends RefCounted

const Symbols = preload("res://scripts/ui/hud_symbols.gd")
const Emblem = preload("res://scripts/ui/hud_emblem_button.gd")
const Plate = preload("res://scripts/ui/hud_plate.gd")

static func apply(main: Control) -> void:
	var header: PanelContainer = main.get_node("Layout/Header")
	header.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	header.get_node("Margin/Row/Brand").custom_minimum_size.x = 120
	var title: Label = header.get_node("Margin/Row/Brand/Title")
	title.add_theme_color_override("font_color", Color("f5e8c7"))
	title.add_theme_color_override("font_shadow_color", Color("102a36"))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.add_theme_constant_override("shadow_outline_size", 3)
	var resources: Control = header.get_node("Margin/Row/Resources")
	resources.set_script(Plate)
	resources.resized.connect(resources.queue_redraw)
	for entry: Array in [["Wood", "wood"], ["SpiritStone", "stone"], ["Food", "food"], ["Disciples", "people"]]:
		var button: Button = main.get_node("%" + entry[0])
		button.icon = Symbols.make_texture(entry[1])
		button.add_theme_constant_override("icon_max_width", 38)
		button.custom_minimum_size.x = 160 if entry[0] in ["Wood", "SpiritStone"] else (390 if entry[0] == "Food" else 250)
	var nav: PanelContainer = main.get_node("Layout/Body/BottomNav")
	nav.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	nav.offset_left = -450
	nav.offset_right = 450
	nav.offset_top = -160
	nav.offset_bottom = -10
	var backing := Control.new()
	backing.set_script(Plate)
	backing.bottom = true
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nav.add_child(backing)
	nav.move_child(backing, 0)
	# PanelContainer 会使背景与内容同尺寸；背景位于按钮下，不拦截输入。
	backing.resized.connect(backing.queue_redraw)
	for entry: Array in [["OpenSectPanelButton", "sect"], ["OpenBuildPanelButton", "build"], ["OpenDisciplesPanelButton", "people"], ["OpenGrowthPanelButton", "growth"], ["OpenBattlePanelButton", "battle"]]:
		var button: Button = main.get_node("%" + entry[0])
		var caption := button.text
		button.set_script(Emblem)
		button.configure(caption, Symbols.make_texture(entry[1]))
	main.management_sidebar.offset_bottom = -174
