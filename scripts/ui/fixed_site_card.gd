extends "res://scripts/ui/building_card.gd"

signal construct_requested(kind: StringName)
signal instance_requested(instance_id: int)

var site_kind: StringName = &""
var member_list: VBoxContainer

func _ready() -> void:
	super._ready()
	manage_button.hide()
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(294, 100)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	member_list = VBoxContainer.new()
	member_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(member_list)
	var column := get_child(0)
	column.add_child(scroll)
	column.move_child(scroll, 3)
	upgrade_requested.connect(func() -> void: construct_requested.emit(site_kind))
	close_requested.connect(hide)

func show_site(kind: StringName, state: Node, effect_text: String) -> void:
	site_kind = kind
	var definition := BuildingCatalog.get_data(kind)
	var layout = preload("res://scripts/world/fixed_sect_layout.gd")
	var members: Array[Dictionary] = layout.members(state, kind)
	title_label.text = "%s · 固定院落" % definition["name"]
	status_label.text = "%s\n建造：%s · %.0f秒\n%s" % [definition["description"], BuildingCatalog.get_cost_text(kind), definition["build_time"], effect_text]
	upgrade_button.text = "建造一座" if members.is_empty() else "扩建一座"
	upgrade_button.disabled = not state.can_afford(definition["cost"]) or layout.storage_cell(state) == Vector2i(-1, -1)
	for child: Node in member_list.get_children():
		member_list.remove_child(child)
		child.queue_free()
	if members.is_empty():
		var empty := Label.new()
		empty.text = "尚未建设 · 点击下方按钮开始施工"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", Color("244347"))
		member_list.add_child(empty)
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	for building: Dictionary in members:
		var button := Button.new()
		var state_text := "已完工" if building["completed"] else "施工 %.1f秒" % building["remaining"]
		if building.get("upgrading", false):
			state_text = "升级 %.1f秒" % building["upgrade_remaining"]
		button.text = "#%d · Lv.%d · %s　查看管理" % [building["instance_id"], building["level"], state_text]
		button.custom_minimum_size.y = 40
		button.pressed.connect(func() -> void: instance_requested.emit(int(building["instance_id"])))
		member_list.add_child(button)
	show()
