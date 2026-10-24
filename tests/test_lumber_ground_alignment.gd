extends SceneTree

const Planar = preload("res://scripts/world/planar_courtyard_sample.gd")
const Layout = preload("res://scripts/world/fixed_sect_layout.gd")

func _init() -> void:
	var planar := Planar.new()
	# Removing the calibrated ground renderer must fail, not silently keep the baked plot.
	if not planar.has_method("lumber_yard_quad"):
		print("FAIL: lumber background still has an independently oriented baked rectangle")
		quit(1)
		return
	for view: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080)]:
		var points: PackedVector2Array = planar.call("lumber_yard_quad", view)
		# Independently measured opaque plinth edges on lumber-contact20.png:
		# left (199,575) -> front (530,743) -> right (870,575).
		var left_front := Vector2(331, 168).normalized()
		var right_front := Vector2(-340, 168).normalized()
		if points.size() != 4 or absf((points[1] - points[0]).normalized().cross(left_front)) > 0.015 or absf((points[3] - points[0]).normalized().cross(right_front)) > 0.015:
			print("FAIL: ground seams are not parallel to the measured lumber plinth")
			quit(1)
			return
		var scale_value := Layout.world_rect(view).size.x / Layout.ART_SIZE.x
		var front := Layout.point(Vector2(514, 375), view)
		if not Geometry2D.is_point_in_polygon(front, points) or front.distance_to(points[2]) > 22 * scale_value:
			print("FAIL: lumber front edge is outside or detached from its compact yard")
			quit(1)
			return
		if Planar.sprite_transform(&"lumber_yard", front) != Transform2D.IDENTITY:
			print("FAIL: whole building was tilted to compensate for the background")
			quit(1)
			return
	print("PASS: lumber ground matches measured plinth axes, compact front apron and upright building at both sizes")
	quit()
