extends Button

var caption := ""
var symbol: Texture2D
var active := false:
	set(value):
		active = value
		queue_redraw()

func configure(label: String, texture: Texture2D) -> void:
	caption = label
	symbol = texture
	text = ""
	icon = null
	tooltip_text = label
	custom_minimum_size = Vector2(150, 132)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if symbol == null:
		return
	var center := Vector2(size.x * 0.5, 46)
	var lit := active or is_hovered() or has_focus()
	# 先画柔和落影，再画暗玉圆形底座，图标保持透明轮廓。
	for ring: int in range(5, 0, -1):
		draw_circle(center + Vector2(0, 5), 44 + ring * 1.5, Color(0.015, 0.035, 0.045, 0.035))
	if lit:
		draw_circle(center, 47, Color(0.92, 0.71, 0.33, 0.14))
	draw_circle(center, 43, Color("102b36") if not lit else Color("24434a"))
	draw_arc(center, 43, 0, TAU, 96, Color("ddbe7b") if lit else Color("9d9374"), 1.8, true)
	draw_arc(center, 38, PI * 1.08, PI * 1.92, 40, Color(0.86, 0.76, 0.53, 0.3), 1, true)
	if lit:
		var tip := center + Vector2(0, -46)
		draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -6), tip + Vector2(4, 0), tip + Vector2(0, 6), tip - Vector2(4, 0)]), Color("ead39d"))
	var shift := Vector2(0, 2) if is_pressed() else Vector2.ZERO
	draw_texture_rect(symbol, Rect2(center - Vector2(26, 26) + shift, Vector2(52, 52)), false)
	var font := get_theme_font("font")
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var baseline := Vector2((size.x - width) * 0.5, 123)
	draw_string(font, baseline + Vector2(1, 2), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0, 0, 0, 0.65))
	draw_string(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f4ead4"))
