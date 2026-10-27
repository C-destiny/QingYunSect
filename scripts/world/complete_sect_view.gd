extends RefCounted

const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const Feedback = preload("res://scripts/world/fixed_site_feedback.gd")
const Outline = preload("res://scripts/world/building_selection_outline.gd")
const ART_SIZE := Vector2(1672, 941)
const GROUND_PATH := "res://assets/environment/complete-sect29-ground.png"
const ATLAS_PATH := "res://assets/buildings/complete-sect29-atlas.png"
# Source-pixel display positions only. Never write these into building cells.
const SITES := {
	&"hall": {"index": Vector2i(0, 0), "foot": Vector2(950, 292), "width": 365.0, "plaque": Vector2(775, 98)},
	&"scripture_library": {"index": Vector2i(1, 0), "foot": Vector2(330, 260), "width": 230.0, "plaque": Vector2(178, 135)},
	&"disciple_quarters": {"index": Vector2i(2, 0), "foot": Vector2(650, 502), "width": 385.0, "plaque": Vector2(422, 344)},
	&"lumber_yard": {"index": Vector2i(3, 0), "foot": Vector2(225, 593), "width": 295.0, "plaque": Vector2(76, 493)},
	&"spirit_mine": {"index": Vector2i(0, 1), "foot": Vector2(1390, 445), "width": 285.0, "plaque": Vector2(1215, 319)},
	&"spirit_field": {"index": Vector2i(1, 1), "foot": Vector2(460, 778), "width": 400.0, "plaque": Vector2(250, 666)},
	&"training_ground": {"index": Vector2i(2, 1), "foot": Vector2(950, 755), "width": 370.0, "plaque": Vector2(737, 640)},
	&"artifact_forge": {"index": Vector2i(3, 1), "foot": Vector2(1315, 865), "width": 300.0, "plaque": Vector2(1130, 760)},
}
const RESOURCE_POINTS := {&"forest": Vector2(152, 652), &"mine": Vector2(1442, 492), &"field": Vector2(470, 836)}
static var sources: Dictionary = {}
static var atlas: Texture2D
static var ground: Texture2D

static func world_rect(view: Vector2) -> Rect2:
	var available := Vector2(maxf(320, view.x - 400), maxf(200, view.y - 180))
	var extent := ART_SIZE * minf(available.x / ART_SIZE.x, available.y / ART_SIZE.y)
	return Rect2(Vector2(8 + (available.x - extent.x) * 0.5, 88 + (available.y - extent.y) * 0.5), extent)

static func point(source: Vector2, view: Vector2) -> Vector2:
	var world := world_rect(view)
	return world.position + source * world.size / ART_SIZE

static func prepare() -> void:
	if atlas != null:
		return
	atlas = load(ATLAS_PATH) as Texture2D
	ground = load(GROUND_PATH) as Texture2D
	# Generation did not produce equal columns. Use inspected, non-overlapping bounds.
	sources = {
		&"hall": Rect2(0, 110, 531, 390),
		&"scripture_library": Rect2(532, 108, 333, 392),
		&"disciple_quarters": Rect2(866, 225, 430, 280),
		&"lumber_yard": Rect2(1297, 181, 375, 325),
		&"spirit_mine": Rect2(0, 550, 433, 365),
		&"spirit_field": Rect2(434, 555, 405, 365),
		&"training_ground": Rect2(840, 550, 454, 370),
		&"artifact_forge": Rect2(1296, 543, 376, 375),
	}

static func is_built(state: Node, kind: StringName) -> bool:
	if kind == &"hall":
		return true
	for building: Dictionary in Layout.members(state, kind):
		if building["completed"]:
			return true
	return false

static func site_frame(map: Control, kind: StringName) -> Dictionary:
	prepare()
	var source: Rect2 = sources[kind]
	var scale_value := world_rect(map.size).size.x / ART_SIZE.x
	var width := float(SITES[kind]["width"]) * scale_value
	var extent := Vector2(width, width * source.size.y / source.size.x)
	var foot := point(SITES[kind]["foot"], map.size)
	var rect := Rect2(foot - extent * Vector2(0.5, 1.0), extent)
	return {"foot": foot, "rect": rect, "entrance": foot - Vector2(0, 6) * scale_value,
		"shadow": foot, "scale": scale_value, "sprite_transform": Transform2D.IDENTITY}

static func plaque_rect(map: Control, kind: StringName) -> Rect2:
	var scale_value := world_rect(map.size).size.x / ART_SIZE.x
	return Rect2(point(SITES[kind]["plaque"], map.size), Vector2(49, 117) * scale_value)

static func construction_geometry(map: Control, kind: StringName) -> Dictionary:
	var frame := site_frame(map, kind)
	var foot: Vector2 = frame["foot"]
	var width := float(SITES[kind]["width"]) * float(frame["scale"])
	var base := PackedVector2Array([foot + Vector2(0, -width * 0.30), foot + Vector2(width * 0.40, -width * 0.15), foot, foot + Vector2(-width * 0.40, -width * 0.15)])
	var top := PackedVector2Array()
	var hull := PackedVector2Array()
	for at: Vector2 in base:
		top.append(at - Vector2(0, width * 0.26))
		hull.append(at)
		hull.append(top[-1])
	return {"base": base, "top": top, "hull": Geometry2D.convex_hull(hull), "center": foot - Vector2(0, width * 0.15), "scale": frame["scale"]}

static func draw(map: Control, state: Node) -> void:
	prepare()
	map.draw_rect(Rect2(Vector2.ZERO, map.size), Color("172d31"))
	map.draw_texture_rect(ground, world_rect(map.size), false)
	var kinds: Array = SITES.keys()
	kinds.sort_custom(func(a: StringName, b: StringName) -> bool: return SITES[a]["foot"].y < SITES[b]["foot"].y)
	for kind: StringName in kinds:
		if is_built(state, kind):
			var rect: Rect2 = site_frame(map, kind)["rect"]
			map.draw_texture_rect_region(atlas, rect, sources[kind])
			if map.fixed_selected_kind == kind:
				Outline.draw(map, atlas, sources[kind], rect)
		elif not Layout.members(state, kind).is_empty():
			var geometry := construction_geometry(map, kind)
			var color := Color("e7ce8d") if map.fixed_selected_kind == kind else Color("99734b")
			for index: int in range(4):
				map.draw_line(geometry["base"][index], geometry["top"][index], color, 2.5, true)
				map.draw_line(geometry["top"][index], geometry["top"][(index + 1) % 4], color, 2.5, true)
			map.draw_line(geometry["base"][3], geometry["top"][2], color, 2.0, true)
	for kind: StringName in kinds:
		var rect := plaque_rect(map, kind)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("f2e6ca")
		style.border_color = Color("ead090") if kind in [map.fixed_selected_kind, map.fixed_hover_kind] else Color("a48e63")
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		style.shadow_size = 3
		style.shadow_color = Color(0, 0, 0, 0.25)
		map.draw_style_box(style, rect)
		var name_text := String(Layout.SITES[kind]["name"])
		var scale_value := float(site_frame(map, kind)["scale"])
		var font_size := maxi(14, roundi(21 * scale_value))
		for index: int in range(name_text.length()):
			map.draw_string(ThemeDB.fallback_font, rect.position + Vector2(5, (25 + index * 24) * scale_value), name_text.substr(index, 1), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10, font_size, Color("273c35"))
		var feedback := Feedback.describe(state, kind)
		map.draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 2, rect.end.y - 7), feedback["label"], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 4, maxi(11, font_size - 6), Color("546044"))
		Feedback.draw_progress(map, kind, feedback)
	for resource: Dictionary in map.resource_nodes:
		var at := point(RESOURCE_POINTS[resource["site_id"]], map.size)
		map._draw_map_label(at, "%s采集" % resource["resource_name"], 94, 13)

static func hit(map: Control, position: Vector2) -> StringName:
	# Nameplates always exist, including a vacant court. No invisible future roof is clickable.
	for kind: StringName in SITES:
		if plaque_rect(map, kind).grow(3).has_point(position):
			return kind
		if not Feedback.describe(map.get_node("/root/GameState"), kind)["job"].is_empty() and Feedback.progress_rect(map, kind).has_point(position):
			return kind
	var kinds: Array = SITES.keys()
	kinds.sort_custom(func(a: StringName, b: StringName) -> bool: return SITES[a]["foot"].y > SITES[b]["foot"].y)
	for kind: StringName in kinds:
		var state := map.get_node("/root/GameState")
		if is_built(state, kind):
			if map._is_sprite_hit(atlas, sources[kind], site_frame(map, kind)["rect"], position):
				return kind
		elif not Layout.members(state, kind).is_empty() and Geometry2D.is_point_in_polygon(position, construction_geometry(map, kind)["hull"]):
			return kind
	return &""
