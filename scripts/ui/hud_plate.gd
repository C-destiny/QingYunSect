extends Control

var bottom := false

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if bottom:
		rect.position.y = 43
		rect.size.y -= 43
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.035, 0.10, 0.14, 0.94)
	plate.border_color = Color(0.66, 0.61, 0.43, 0.65)
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(32 if bottom else 26)
	plate.shadow_color = Color(0.01, 0.025, 0.035, 0.55)
	plate.shadow_size = 14
	plate.shadow_offset = Vector2(0, 6)
	draw_style_box(plate, rect)
	# 克制的云纹侧饰，保留中心信息和圆形入口的清晰轮廓。
	if bottom:
		for side: float in [-1.0, 1.0]:
			var edge := Vector2(24 if side < 0 else size.x - 24, size.y - 25)
			draw_polyline(PackedVector2Array([edge + Vector2(-side * 23, 8), edge,
				edge + Vector2(side * 8, -23), edge + Vector2(-side * 5, -38)]), Color(0.77, 0.65, 0.39, 0.65), 2.0, true)
