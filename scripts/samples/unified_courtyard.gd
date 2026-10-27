extends "res://scripts/samples/hall_courtyard.gd"

func create_map() -> Control:
	return preload("res://scripts/samples/unified_courtyard_map.gd").new()

func _ready() -> void:
	super._ready()
	# Keep original state operations and card layout, replace only art comparison.
	for connection: Dictionary in compare.pressed.get_connections():
		compare.pressed.disconnect(connection["callable"])
	compare.text = "对照候选27"
	compare.pressed.connect(func() -> void:
		map_view.previous_enabled = not map_view.previous_enabled
		compare.text = "返回统一版28" if map_view.previous_enabled else "对照候选27"
		map_view.queue_redraw())
	for control: Node in action.get_parent().get_children():
		if control is Button and control.text == "接地对照":
			control.hide()
	print("UNIFIED_COURTYARD28: isolated visual redesign; formal save not loaded or saved")

func refresh() -> void:
	super.refresh()
	if is_instance_valid(info):
		info.text = info.text.replace("接地样板27", "统一庭院28")
