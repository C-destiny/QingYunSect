extends Control

const Layout25 = preload("res://scripts/world/fixed_sect_layout.gd")
var showcase_on_start := true
var map_view: Control
var card: PanelContainer
var info: Label
var action: Button
var compare: Button
var baseline: Dictionary

func create_map() -> Control:
	return preload("res://scripts/samples/hall_courtyard_map.gd").new()

func _ready() -> void:
	# Explicit standalone entry: no formal save read, load, autosave or save on exit.
	SaveManager.save_path = "user://v08_hall_courtyard25_demo.json"
	theme = preload("res://assets/ui/themes/qingyun_theme.tres")
	GameState.resources["wood"] = 1000
	GameState.resources["spirit_stone"] = 1000
	baseline = GameState.export_save_data().duplicate(true)
	map_view = create_map()
	add_child(map_view)
	map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_view.site_selected.connect(select_site)
	card = preload("res://scripts/ui/building_card.gd").new()
	add_child(card)
	card.manage_button.hide()
	card.close_requested.connect(close_card)
	card.upgrade_requested.connect(build_or_upgrade)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = 14
	panel.offset_bottom = 76
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.035, 0.10, 0.12, 0.86)
	backing.border_color = Color("9d8758")
	backing.set_border_width_all(1)
	backing.set_corner_radius_all(10)
	backing.content_margin_left = 16
	backing.content_margin_right = 12
	backing.content_margin_top = 8
	backing.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", backing)
	add_child(panel)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	panel.add_child(bar)
	info = Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("font_size", 20)
	bar.add_child(info)
	action = Button.new()
	action.pressed.connect(build_or_upgrade)
	bar.add_child(action)
	compare = Button.new()
	compare.text = "对照原庭院"
	compare.pressed.connect(func() -> void:
		map_view.garden_enabled = not map_view.garden_enabled
		compare.text = "对照原庭院" if map_view.garden_enabled else "返回园林版"
		map_view.queue_redraw())
	bar.add_child(compare)
	var contact := Button.new()
	contact.text = "接地对照"
	contact.tooltip_text = "同一园林与建筑状态，开关主殿台基接地修正"
	contact.pressed.connect(func() -> void:
		map_view.contact_enabled = not map_view.contact_enabled
		contact.text = "接地对照" if map_view.contact_enabled else "返回修整"
		map_view.queue_redraw())
	bar.add_child(contact)
	var reset := Button.new()
	reset.text = "施工试玩"
	reset.tooltip_text = "仅重置本次独立演示，按原资源和时间建设；不操作玩家存档"
	reset.pressed.connect(reset_demo)
	bar.add_child(reset)
	resized.connect(refresh)
	if showcase_on_start:
		build_or_upgrade()
		GameState.process_construction(30)
		close_card()
	refresh()
	print("HALL_COURTYARD27: isolated sample; formal save not loaded or saved")

func _process(delta: float) -> void:
	GameState.process_construction(delta)
	refresh()

func refresh() -> void:
	if not is_instance_valid(map_view) or not is_instance_valid(info):
		return
	var building: Dictionary = map_view.wing()
	var status := "未建 · 原成本施工"
	if not building.is_empty():
		status = "Lv.%d" % int(building["level"])
		if not building["completed"]:
			status = "施工 %.1f秒" % float(building["remaining"])
		elif building.get("upgrading", false):
			status = "升级 %.1f秒" % float(building["upgrade_remaining"])
	info.text = "青云宗 · 接地样板27　木材%d · 灵石%d　%s" % [GameState.resources["wood"], GameState.resources["spirit_stone"], status]
	action.text = "建设弟子居" if building.is_empty() else "升级弟子居"
	action.disabled = not GameState.can_afford(BuildingCatalog.get_data(&"disciple_quarters")["cost"]) if building.is_empty() else not GameState.can_upgrade_building(int(building["instance_id"]))
	if card.visible:
		_update_card()
	map_view.queue_redraw()

func select_site(kind: StringName) -> void:
	if kind == &"":
		close_card()
		return
	map_view.selected = kind
	card.show()
	_update_card()
	map_view.queue_redraw()

func _update_card() -> void:
	var hall: bool = map_view.selected == &"hall"
	card.title_label.text = "主殿 · 固定中枢" if hall else "弟子居 · 侧翼院落"
	var building: Dictionary = map_view.wing()
	var definition := BuildingCatalog.get_data(&"disciple_quarters")
	var cost: Dictionary = definition["cost"]
	var duration := float(definition["build_time"])
	var operation := "建设"
	if not building.is_empty() and building["completed"]:
		var target := int(building["level"]) + 1
		if target <= BuildingCatalog.MAX_BUILDING_LEVEL:
			operation = "升级至Lv.%d" % target
			cost = BuildingCatalog.get_upgrade_cost(&"disciple_quarters", target)
			duration = BuildingCatalog.get_upgrade_time(&"disciple_quarters", target)
		else:
			operation = "已满级"
			cost = {}
			duration = 0
	var parts := PackedStringArray()
	for entry: Array in [["wood", "木材"], ["spirit_stone", "灵石"], ["food", "灵谷"]]:
		if int(cost.get(entry[0], 0)) > 0:
			parts.append("%s%d" % [entry[1], cost[entry[0]]])
	card.status_label.text = "主殿保持固定。\n此入口仅展示独立庭院样板；正式存档未加载。" if hall else ("%s：%s · %.0f秒\n%s\n正式存档未加载，资源与工期沿用原规则。" % [operation, "、".join(parts), duration, info.text.get_slice("　", 2)])
	card.upgrade_button.visible = not hall
	card.upgrade_button.text = action.text if is_instance_valid(action) else "建设弟子居"
	card.upgrade_button.disabled = action.disabled if is_instance_valid(action) else false
	card.place_near(map_view.frame(map_view.selected)["rect"], Rect2(Vector2(24, 88), size - Vector2(48, 112)))

func close_card() -> void:
	card.hide()
	map_view.selected = &""
	map_view.queue_redraw()

func build_or_upgrade() -> void:
	var building: Dictionary = map_view.wing()
	if building.is_empty():
		Layout25.construct(GameState, &"disciple_quarters")
	else:
		GameState.start_building_upgrade(int(building["instance_id"]))
	refresh()

func reset_demo() -> void:
	GameState.import_save_data(baseline.duplicate(true))
	close_card()
	refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_card()
		get_viewport().set_input_as_handled()
