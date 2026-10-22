extends RefCounted

const ART_SIZE := Vector2(1672, 941)
# 固定场景脚点，单位为环境原图像素；绝不写回旧建筑cell_x/y。
const SITES := {
	&"hall": {"foot": Vector2(755, 230), "width": 310.0, "name": "主殿"},
	&"scripture_library": {"foot": Vector2(263, 285), "width": 225.0, "name": "藏经阁"},
	&"lumber_yard": {"foot": Vector2(510, 392), "width": 180.0, "name": "伐木场", "plaque_offset": Vector2(-105, -90)},
	&"artifact_forge": {"foot": Vector2(660, 503), "width": 215.0, "name": "炼器坊"},
	&"training_ground": {"foot": Vector2(1130, 402), "width": 245.0, "name": "演武场"},
	&"disciple_quarters": {"foot": Vector2(1040, 645), "width": 235.0, "name": "弟子居"},
	&"spirit_field": {"foot": Vector2(660, 625), "width": 235.0, "name": "灵田"},
	&"spirit_mine": {"foot": Vector2(1450, 600), "width": 220.0, "name": "采灵坊"},
}
const RESOURCE_POINTS := {&"forest": Vector2(175, 405), &"mine": Vector2(1560, 665), &"field": Vector2(550, 680)}

static func world_rect(view: Vector2) -> Rect2:
	var scale_value := minf(view.x / ART_SIZE.x, (view.y - 68.0) / ART_SIZE.y)
	var extent := ART_SIZE * scale_value
	return Rect2(Vector2((view.x - extent.x) * 0.5, 68), extent)

static func point(source: Vector2, view: Vector2) -> Vector2:
	var world := world_rect(view)
	return world.position + source * (world.size / ART_SIZE)

static func frame(kind: StringName, view: Vector2, profile: Dictionary) -> Dictionary:
	var scale_value := world_rect(view).size.x / ART_SIZE.x
	var site: Dictionary = SITES[kind]
	var foot := point(site["foot"], view)
	var width := float(site["width"]) * scale_value
	var extent := Vector2(width, width * float(profile["size"].y) / float(profile["size"].x))
	var rect := Rect2(foot - extent * Vector2(profile["foot"]), extent)
	return {"foot": foot, "rect": rect, "entrance": rect.position + extent * Vector2(profile.get("entrance", profile["foot"])), "shadow": foot + Vector2(8, 6), "scale": scale_value}

static func members(state: Node, kind: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for building: Dictionary in state.buildings:
		if StringName(building["type"]) == kind:
			result.append(building)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["instance_id"]) < int(b["instance_id"]))
	return result

# 复用既有数据格作为内部存储；玩家不选格，不迁移旧实例，不跳过原解锁/占用规则。
static func storage_cell(state: Node) -> Vector2i:
	var bounds := preload("res://scripts/data/territory_catalog.gd").get_map_bounds()
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			if cell in [Vector2i(4, 3), Vector2i(1, 1), Vector2i(6, 1), Vector2i(2, 4)]:
				continue
			if state.is_cell_unlocked(cell) and not state.is_cell_occupied(cell):
				return cell
	return Vector2i(-1, -1)

static func construct(state: Node, kind: StringName) -> bool:
	if not SITES.has(kind) or kind == &"hall":
		return false
	var cell := storage_cell(state)
	return cell != Vector2i(-1, -1) and state.start_construction(kind, cell)
