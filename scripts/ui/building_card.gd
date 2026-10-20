extends PanelContainer

signal close_requested
signal manage_requested
signal upgrade_requested

var title_label: Label
var status_label: Label
var upgrade_button: Button
var close_button: Button
var manage_button: Button

func _ready() -> void:
	z_index = 35
	custom_minimum_size = Vector2(330, 220)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("f3ead6")
	paper.border_color = Color("aa8e54")
	paper.set_border_width_all(2)
	paper.set_corner_radius_all(9)
	paper.content_margin_left = 18
	paper.content_margin_right = 18
	paper.content_margin_top = 14
	paper.content_margin_bottom = 16
	paper.shadow_size = 8
	paper.shadow_color = Color(0.02, 0.06, 0.07, 0.3)
	add_theme_stylebox_override("panel", paper)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 23)
	heading.add_child(title_label)
	close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(38, 36)
	close_button.tooltip_text = "关闭建筑信息（Esc）"
	close_button.pressed.connect(func() -> void:
		get_viewport().set_input_as_handled()
		close_requested.emit.call_deferred())
	heading.add_child(close_button)
	column.add_child(HSeparator.new())
	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(294, 78)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 18)
	column.add_child(status_label)
	for label: Label in [title_label, status_label]:
		label.add_theme_color_override("font_color", Color("244347"))
		label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	upgrade_button = Button.new()
	upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_button.pressed.connect(func() -> void: upgrade_requested.emit())
	actions.add_child(upgrade_button)
	manage_button = Button.new()
	manage_button.text = "详细管理"
	manage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manage_button.pressed.connect(func() -> void: manage_requested.emit())
	actions.add_child(manage_button)
	hide()

func place_near(visual_rect: Rect2, safe_rect: Rect2) -> void:
	# 四向候选先限制在安全区，再按遮挡面积选位；同分保留靠近建筑的侧面。
	size = get_combined_minimum_size()
	var candidates: Array[Vector2] = [
		Vector2(visual_rect.end.x + 20, visual_rect.position.y + 30),
		Vector2(visual_rect.position.x - size.x - 20, visual_rect.position.y + 30),
		Vector2(visual_rect.get_center().x - size.x * 0.5, visual_rect.end.y + 20),
		Vector2(visual_rect.get_center().x - size.x * 0.5, visual_rect.position.y - size.y - 20),
	]
	var least_overlap := INF
	for candidate: Vector2 in candidates:
		candidate = Vector2(clampf(candidate.x, safe_rect.position.x, maxf(safe_rect.position.x, safe_rect.end.x - size.x)),
			clampf(candidate.y, safe_rect.position.y, maxf(safe_rect.position.y, safe_rect.end.y - size.y)))
		var overlap := Rect2(candidate, size).intersection(visual_rect.grow(12)).get_area()
		if overlap < least_overlap:
			least_overlap = overlap
			position = candidate
		if is_zero_approx(overlap):
			break
