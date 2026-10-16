extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	assert(state.get_idle_disciples() == 3)
	assert(state.assign_disciple(&"forest"))
	assert(state.assign_disciple(&"forest"))
	assert(state.assign_disciple(&"mine"))
	assert(not state.assign_disciple(&"field"))
	assert(state.get_assignment(&"forest") == 2)
	assert(state.get_idle_disciples() == 0)
	var produced := state.process_production(&"forest", &"wood", 12.0, 60.0)
	assert(produced == 24)
	assert(state.get_resource_amount(&"wood") == 144)
	assert(state.unassign_disciple(&"forest"))
	assert(state.get_idle_disciples() == 1)
	print("PASS: disciple assignment and production")
	quit()

