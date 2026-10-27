extends RefCounted

const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const Complete = preload("res://scripts/world/complete_sect_view.gd")
const Garden = preload("res://scripts/world/fixed_courtyard_details.gd")
const Outline = preload("res://scripts/world/building_selection_outline.gd")
const Feedback = preload("res://scripts/world/fixed_site_feedback.gd")
const Blend = preload("res://scripts/world/fixed_courtyard_blend.gd")
const GARDEN_BACKDROP: Texture2D = preload("res://assets/environment/sect_garden_scene17.png")
const Planar = preload("res://scripts/world/planar_courtyard_sample.gd")

static func site_frame(map: Control, kind: StringName) -> Dictionary:
	if map.complete_sect:
		return Complete.site_frame(map, kind)
	var profile: Dictionary = map.MAIN_HALL_VISUAL if kind == &"hall" else map.get_building_visual(kind)["profile"]
	var frame := Layout.frame(kind, map.size, profile)
	var pose := Planar.sprite_transform(kind, frame["foot"]) if map.fixed_planar_sample and Planar.SITES.has(kind) else Transform2D.IDENTITY
	frame["sprite_transform"] = pose
	frame["entrance"] = pose * Vector2(frame["entrance"])
	return frame

static func plaque_rect(map: Control, kind: StringName) -> Rect2:
	if map.complete_sect:
		return Complete.plaque_rect(map, kind)
	var frame := site_frame(map, kind)
	var width := float(Layout.SITES[kind]["width"]) * float(frame["scale"])
	var offset := Vector2(width * 0.42, -width * 0.54)
	if Layout.SITES[kind].has("plaque_offset"):
		offset = Vector2(Layout.SITES[kind]["plaque_offset"]) * float(frame["scale"])
	return Rect2(frame["foot"] + offset, Vector2(43, 102) * float(frame["scale"]))

static func construction_geometry(map: Control, kind: StringName) -> Dictionary:
	if map.complete_sect:
		return Complete.construction_geometry(map, kind)
	var frame := site_frame(map, kind)
	var base := Planar.site_ground_quad(map, kind)
	if base.is_empty():
		# Court and field have no rectangular paving, but their temporary scaffold
		# still follows the future sprite's ground plane, not the legacy screen foot.
		var rect: Rect2 = frame["rect"]
		var pose: Transform2D = frame["sprite_transform"]
		var left := Vector2(0.06, 0.64)
		var front := Vector2(0.50, 0.86)
		var right := Vector2(0.94, 0.64)
		for uv: Vector2 in [left + right - front, right, front, left]:
			base.append(pose * (rect.position + rect.size * uv))
	var center := (base[0] + base[2]) * 0.5
	var top := PackedVector2Array()
	var hull_points := PackedVector2Array()
	var height := float(Layout.SITES[kind]["width"]) * float(frame["scale"]) * 0.27
	for index: int in range(4):
		base[index] = center + (base[index] - center) * 0.86
		top.append(base[index] - Vector2(0, height))
		hull_points.append(base[index])
		hull_points.append(top[index])
	return {"base": base, "top": top, "center": center, "hull": Geometry2D.convex_hull(hull_points), "scale": frame["scale"]}

static func draw_construction(map: Control, kind: StringName) -> void:
	var geometry := construction_geometry(map, kind)
	var base: PackedVector2Array = geometry["base"]
	var top: PackedVector2Array = geometry["top"]
	var selected: bool = map.fixed_selected_kind == kind
	var timber := Color("dfbc74") if selected else Color("96744a")
	var beam := Color("f0dca1") if selected else Color("b09264")
	var line_width := maxf(1.5, 2.5 * float(geometry["scale"]))
	for index: int in range(4):
		var next := (index + 1) % 4
		map.draw_line(base[index], top[index], timber, line_width, true)
		map.draw_line(top[index], top[next], beam, line_width, true)
		map.draw_line(base[index].lerp(top[index], 0.5), base[next].lerp(top[next], 0.5), timber, line_width * 0.65, true)
	# Two front braces, with no solid billboard obscuring the actual courtyard.
	map.draw_line(base[3], top[2], timber, line_width * 0.65, true)
	map.draw_line(base[2], top[1], timber, line_width * 0.65, true)

static func draw(map: Control, state: Node) -> void:
	if map.complete_sect:
		Complete.draw(map, state)
		return
	map.draw_texture_rect(map.DISTANT_CLOUDS, Rect2(Vector2.ZERO, map.size), false)
	if map.fixed_planar_sample:
		Planar.draw_background(map, GARDEN_BACKDROP)
		Planar.draw_ground(map)
	elif map.fixed_garden_scene:
		map.draw_texture_rect(GARDEN_BACKDROP, Layout.world_rect(map.size), false)
	elif map.fixed_courtyard_blend:
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
			map.draw_set_transform_matrix(frame["sprite_transform"])
			map.draw_texture_rect(map.MAIN_HALL_SAMPLE, frame["rect"], false)
			if map.fixed_selected_kind == kind:
				Outline.draw(map, map.MAIN_HALL_SAMPLE, Rect2(Vector2.ZERO, map.MAIN_HALL_SAMPLE.get_size()), frame["rect"])
			map.draw_set_transform_matrix(Transform2D.IDENTITY)
		elif not buildings.is_empty():
			var completed := false
			for building: Dictionary in buildings:
				completed = completed or bool(building["completed"])
			if completed:
				var spec: Dictionary = map.get_building_visual(kind)
				map.draw_set_transform_matrix(frame["sprite_transform"])
				map.draw_texture_rect_region(spec["texture"], frame["rect"], spec["source"])
				if map.fixed_selected_kind == kind:
					Outline.draw(map, spec["texture"], spec["source"], frame["rect"])
				map.draw_set_transform_matrix(Transform2D.IDENTITY)
			else:
				draw_construction(map, kind)
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
	if map.complete_sect:
		return Complete.hit(map, position)
	var kinds: Array = Layout.SITES.keys()
	kinds.sort_custom(func(a: StringName, b: StringName) -> bool: return Vector2(Layout.SITES[a]["foot"]).y > Vector2(Layout.SITES[b]["foot"]).y)
	for kind: StringName in kinds:
		var frame := site_frame(map, kind)
		var buildings := Layout.members(map.get_node("/root/GameState"), kind)
		var completed := false
		for building: Dictionary in buildings:
			completed = completed or bool(building["completed"])
		var constructing := not buildings.is_empty() and not completed
		if plaque_rect(map, kind).grow(4).has_point(position) or (not constructing and Rect2(frame["foot"] - Vector2(55, 28) * frame["scale"], Vector2(110, 56) * frame["scale"]).has_point(position)):
			return kind
		if not Feedback.describe(map.get_node("/root/GameState"), kind)["job"].is_empty() and Feedback.progress_rect(map, kind).has_point(position):
			return kind
		if constructing:
			if Geometry2D.is_point_in_polygon(position, construction_geometry(map, kind)["hull"]):
				return kind
			continue # A future opaque roof is not yet visible and must not catch clicks.
		var sprite_point: Vector2 = Transform2D(frame["sprite_transform"]).affine_inverse() * position
		if kind == &"hall":
			if map._is_sprite_hit(map.MAIN_HALL_SAMPLE, Rect2(Vector2.ZERO, map.MAIN_HALL_SAMPLE.get_size()), frame["rect"], sprite_point):
				return kind
		elif not buildings.is_empty():
			var spec: Dictionary = map.get_building_visual(kind)
			if map._is_sprite_hit(spec["texture"], spec["source"], frame["rect"], sprite_point):
				return kind
	return &""
