extends RefCounted

const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const Garden = preload("res://scripts/world/fixed_courtyard_details.gd")
const Outline = preload("res://scripts/world/building_selection_outline.gd")
const Feedback = preload("res://scripts/world/fixed_site_feedback.gd")
const Blend = preload("res://scripts/world/fixed_courtyard_blend.gd")

static func site_frame(map: Control, kind: StringName) -> Dictionary:
	var profile: Dictionary = map.MAIN_HALL_VISUAL if kind == &"hall" else map.get_building_visual(kind)["profile"]
	return Layout.frame(kind, map.size, profile)

static func plaque_rect(map: Control, kind: StringName) -> Rect2:
	var frame := site_frame(map, kind)
	var width := float(Layout.SITES[kind]["width"]) * float(frame["scale"])
	return Rect2(frame["foot"] + Vector2(width * 0.42, -width * 0.54), Vector2(43, 102) * float(frame["scale"]))

static func draw(map: Control, state: Node) -> void:
	map.draw_texture_rect(map.DISTANT_CLOUDS, Rect2(Vector2.ZERO, map.size), false)
	if map.fixed_courtyard_blend:
		Blend.draw_background(map)
		Blend.draw_ground(map, state)
	else:
		map.draw_texture_rect(map.MAP_BACKDROP, Layout.world_rect(map.size), false)
	# 所有地面阴影先于主体；园林不参加占地或拾取。
	Garden.draw_ground(map, state)
	var kinds: Array = Layout.SITES.keys()
	kinds.sort_custom(func(a: StringName, b: StringName) -> bool: return Vector2(Layout.SITES[a]["foot"]).y < Vector2(Layout.SITES[b]["foot"]).y)
	var decorations := Garden.items(map)
	var decor_index := 0
	for kind: StringName in kinds:
		var frame := site_frame(map, kind)
		var foot: Vector2 = frame["foot"]
		while decor_index < decorations.size() and decorations[decor_index]["depth"] <= foot.y:
			Garden.draw_item(map, decorations[decor_index])
			decor_index += 1
		var buildings := Layout.members(state, kind)
		if kind == &"hall":
			map.draw_texture_rect(map.MAIN_HALL_SAMPLE, frame["rect"], false)
			if map.fixed_selected_kind == kind:
				Outline.draw(map, map.MAIN_HALL_SAMPLE, Rect2(Vector2.ZERO, map.MAIN_HALL_SAMPLE.get_size()), frame["rect"])
		elif not buildings.is_empty():
			var completed := false
			for building: Dictionary in buildings:
				completed = completed or bool(building["completed"])
			if completed:
				var spec: Dictionary = map.get_building_visual(kind)
				map.draw_texture_rect_region(spec["texture"], frame["rect"], spec["source"])
				if map.fixed_selected_kind == kind:
					Outline.draw(map, spec["texture"], spec["source"], frame["rect"])
			else:
				map._draw_construction_site(foot, Color("b7a67d"))
				if map.fixed_selected_kind == kind:
					Outline.draw_scaffold(map, foot)
	while decor_index < decorations.size():
		Garden.draw_item(map, decorations[decor_index])
		decor_index += 1
	# 纸牌最后绘制，前景树石不能遮住操作入口。
	for kind: StringName in kinds:
		var buildings := Layout.members(state, kind)
		var frame := site_frame(map, kind)
		var plaque := plaque_rect(map, kind)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("f4ead0")
		style.border_color = Color("9d8758")
		if map.fixed_hover_kind == kind:
			style.border_color = Color("eddbab")
		if map.fixed_selected_kind == kind:
			style.border_color = Color("e6bd56")
		style.set_border_width_all(2)
		style.set_corner_radius_all(5)
		style.shadow_size = 4
		style.shadow_color = Color(0, 0, 0, 0.25)
		map.draw_style_box(style, plaque)
		var name_text := String(Layout.SITES[kind]["name"])
		var font_size := maxi(13, roundi(18 * frame["scale"]))
		for index: int in range(name_text.length()):
			map.draw_string(ThemeDB.fallback_font, plaque.position + Vector2(5, 24 + index * 20) * frame["scale"], name_text.substr(index, 1), HORIZONTAL_ALIGNMENT_CENTER, plaque.size.x - 10, font_size, Color("203c40"))
		var feedback := Feedback.describe(state, kind)
		var status: String = feedback["label"]
		map.draw_string(ThemeDB.fallback_font, plaque.position + Vector2(3, plaque.size.y - 7), status, HORIZONTAL_ALIGNMENT_CENTER, plaque.size.x - 6, maxi(11, font_size - 4), Color("46615c"))
		Feedback.draw_progress(map, kind, feedback)
	for resource: Dictionary in map.resource_nodes:
		var at := Layout.point(Layout.RESOURCE_POINTS[resource["site_id"]], map.size)
		map._draw_map_label(at, "%s采集" % resource["resource_name"], 100, 13)

static func hit(map: Control, position: Vector2) -> StringName:
	var kinds: Array = Layout.SITES.keys()
	kinds.sort_custom(func(a: StringName, b: StringName) -> bool: return Vector2(Layout.SITES[a]["foot"]).y > Vector2(Layout.SITES[b]["foot"]).y)
	for kind: StringName in kinds:
		var frame := site_frame(map, kind)
		if plaque_rect(map, kind).grow(4).has_point(position) or Rect2(frame["foot"] - Vector2(55, 28) * frame["scale"], Vector2(110, 56) * frame["scale"]).has_point(position):
			return kind
		if not Feedback.describe(map.get_node("/root/GameState"), kind)["job"].is_empty() and Feedback.progress_rect(map, kind).has_point(position):
			return kind
		var buildings := Layout.members(map.get_node("/root/GameState"), kind)
		if kind == &"hall":
			if map._is_sprite_hit(map.MAIN_HALL_SAMPLE, Rect2(Vector2.ZERO, map.MAIN_HALL_SAMPLE.get_size()), frame["rect"], position):
				return kind
		elif not buildings.is_empty():
			var spec: Dictionary = map.get_building_visual(kind)
			if map._is_sprite_hit(spec["texture"], spec["source"], frame["rect"], position):
				return kind
	return &""
