extends SceneTree

func _init() -> void:
	# Reference extraction only; no painted-content edit, sharpening or Python processing.
	var original := Image.load_from_file("res://assets/environment/sect_sites_clear22.png")
	var region := original.get_region(Rect2i(345, 270, 330, 220))
	var result := region.save_png("res://builds/material24-reference.png")
	print("PASS: extracted 330x220 reference" if result == OK else "FAIL: reference extraction")
	quit(0 if result == OK else 1)
