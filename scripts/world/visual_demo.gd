extends RefCounted

# 只允许显式演示/隔离测试调用；普通读档不运行、不迁移或补送建筑。
const PLACEMENTS := {
	&"disciple_quarters": Vector2i(1, 5), &"lumber_yard": Vector2i(0, 6),
	&"spirit_mine": Vector2i(8, 4), &"spirit_field": Vector2i(4, 7),
	&"training_ground": Vector2i(8, 1), &"artifact_forge": Vector2i(10, 5),
	&"scripture_library": Vector2i(0, 3),
}

static func populate_full_scene(state: Node) -> bool:
	if not state.buildings.is_empty():
		return false
	state.resources["wood"] = 10000
	state.resources["spirit_stone"] = 10000
	state.resources["food"] = 10000
	state.sect_level = 5
	state.unlocked_regions.assign(["core", "east", "south"])
	for kind: StringName in PLACEMENTS:
		if not state.start_construction(kind, PLACEMENTS[kind]):
			return false
	state.process_construction(30)
	state.resources["wood"] = 480
	state.resources["spirit_stone"] = 320
	state.resources["food"] = 450
	return true
