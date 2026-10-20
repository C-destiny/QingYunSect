extends RefCounted

static func populate(state: Node) -> bool:
	if not state.buildings.is_empty():
		return false
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	state.resources["food"] = 1000
	state.sect_level = 5
	state.unlocked_regions.assign(["core", "east", "south"])
	if not state.start_construction(&"disciple_quarters", Vector2i(2, 6)):
		return false
	state.process_construction(30)
	return true
