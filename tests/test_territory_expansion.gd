extends SceneTree


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	assert(state.unlocked_regions == ["core"])
	assert(state.is_cell_unlocked(Vector2i(0, 0)))
	assert(state.is_cell_unlocked(Vector2i(7, 5)))
	assert(not state.is_cell_unlocked(Vector2i(8, 0)))
	assert(not state.is_cell_unlocked(Vector2i(0, 6)))
	var resources_before := state.resources.duplicate(true)
	assert(not state.start_construction(&"lumber_yard", Vector2i(8, 0)))
	assert(state.resources == resources_before)

	state.sect_level = 3
	state.resources = {"wood": 1000, "spirit_stone": 1000, "food": 1000}
	assert(state.get_next_locked_region() == &"east")
	assert(state.can_unlock_region(&"east"))
	assert(state.unlock_region(&"east"))
	assert(state.unlocked_regions == ["core", "east"])
	assert(state.resources["wood"] == 600)
	assert(state.resources["spirit_stone"] == 820)
	assert(not state.unlock_region(&"east"))
	assert(state.start_construction(&"lumber_yard", Vector2i(8, 0)))
	assert(not state.can_unlock_region(&"south"))

	state.sect_level = 5
	state.resources = {"wood": 1000, "spirit_stone": 1000, "food": 1000}
	assert(state.can_unlock_region(&"south"))
	assert(state.unlock_region(&"south"))
	assert(state.unlocked_regions == ["core", "east", "south"])
	assert(state.is_cell_unlocked(Vector2i(11, 7)))
	assert(state.get_next_locked_region() == &"")
	assert(state.resources == {"wood": 200, "spirit_stone": 600, "food": 700})

	var saved := state.export_save_data()
	var restored := preload("res://scripts/core/game_state.gd").new()
	root.add_child(restored)
	assert(restored.import_save_data(saved))
	assert(restored.unlocked_regions == state.unlocked_regions)
	assert(restored.is_cell_unlocked(Vector2i(11, 7)))
	assert(restored.buildings == state.buildings)
	print("PASS: staged territory unlocks permanent 12x8 cells with level and resource gates")
	quit()
