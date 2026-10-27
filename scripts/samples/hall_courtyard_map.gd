extends "res://scripts/world/sect_map.gd"

signal site_selected(kind: StringName)

const BACKGROUND: Texture2D = preload("res://assets/environment/hall_courtyard25.png")
const GARDEN_BACKGROUND: Texture2D = preload("res://assets/environment/hall_courtyard26.png")
const GARDEN_FOREGROUND: Texture2D = preload("res://assets/environment/hall_garden_foreground26.png")
const Outline25 = preload("res://scripts/world/building_selection_outline.gd")
const Garden25 = preload("res://scripts/world/fixed_courtyard_details.gd")
const CANVAS := Vector2(1672, 941)
const DISPLAY := {
	&"hall": {"foot": Vector2(1000, 430), "width": 500.0},
	&"disciple_quarters": {"foot": Vector2(550, 560), "width": 300.0},
}
var selected: StringName = &""
var garden_enabled := true
var foreground_enabled := true
var foreground_source := Rect2()
var contact_enabled := true

# Traced on the original 1280px hall sprite: lower stone/plinth edge, including
# the three stairs. Pure presentation; never used for picking or occupancy.
const HALL_CONTACT_EDGE := [
	Vector2(37, 795), Vector2(80, 814), Vector2(79, 841),
	Vector2(137, 864), Vector2(183, 842), Vector2(262, 878),
	Vector2(262, 947), Vector2(435, 1017), Vector2(511, 984),
	Vector2(634, 1033), Vector2(657, 1027), Vector2(731, 1065),
	Vector2(820, 1024), Vector2(934, 1073), Vector2(963, 1061),
	Vector2(1008, 1077), Vector2(1075, 1051), Vector2(1088, 1061),
	Vector2(1172, 1019), Vector2(1170, 987), Vector2(1226, 962),
	Vector2(1226, 915),
]

func hall_contact_geometry() -> Dictionary:
	var rect: Rect2 = frame(&"hall")["rect"]
	var edge := PackedVector2Array()
	for at: Vector2 in HALL_CONTACT_EDGE:
		edge.append(rect.position + rect.size * at / 1280.0)
	var apron := PackedVector2Array()
	# Two shallow rows extend the central stair's own axes, not a new platform.
	for at: Vector2 in [Vector2(262, 947), Vector2(435, 1017), Vector2(394, 1039), Vector2(221, 969)]:
		apron.append(rect.position + rect.size * at / 1280.0)
	return {"edge": edge, "apron": apron, "cast": rect.size * Vector2(0.026, 0.018)}

func _draw_hall_contact() -> void:
	var geometry := hall_contact_geometry()
	var edge: PackedVector2Array = geometry["edge"]
	var cast: Vector2 = geometry["cast"]
	# Shallow stone courses bridge the stair edge. No opaque rectangular plinth.
	var apron: PackedVector2Array = geometry["apron"]
	for row: int in range(2):
		for column: int in range(5):
			var near_left := apron[0].lerp(apron[1], column / 5.0)
			var near_right := apron[0].lerp(apron[1], (column + 1) / 5.0)
			var far_left := apron[3].lerp(apron[2], column / 5.0)
			var far_right := apron[3].lerp(apron[2], (column + 1) / 5.0)
			var slab := PackedVector2Array([
				near_left.lerp(far_left, row / 2.0), near_right.lerp(far_right, row / 2.0),
				near_right.lerp(far_right, (row + 1) / 2.0), near_left.lerp(far_left, (row + 1) / 2.0)])
			draw_colored_polygon(slab, Color(0.66, 0.65, 0.60, 0.30 + (column % 2) * 0.04))
			draw_line(slab[3], slab[2], Color(0.31, 0.33, 0.31, 0.17), 0.7, true)
			draw_line(slab[1], slab[2], Color(0.31, 0.33, 0.31, 0.13), 0.6, true)
	# Feathered edge strips follow every stair/plinth turn. Keeping only the
	# local ribbon prevents an ellipse or a large dark polygon under the court.
	for layer: int in range(7, 0, -1):
		var offset := cast * (layer / 7.0)
		for i: int in range(edge.size() - 1):
			var strip := PackedVector2Array([edge[i], edge[i + 1], edge[i + 1] + offset, edge[i] + offset])
			if absf((edge[i + 1] - edge[i]).cross(offset)) > 0.01:
				draw_colored_polygon(strip, Color(0.12, 0.16, 0.17, 0.022))
	var scale_value := world_rect().size.x / CANVAS.x
	draw_polyline(edge, Color(0.10, 0.13, 0.13, 0.26), 2.3 * scale_value, true)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	foreground_source = Rect2(GARDEN_FOREGROUND.get_image().get_used_rect())
	mouse_exited.connect(func() -> void: tooltip_text = "")

func foreground_frame() -> Dictionary:
	# Alpha>0 includes the soft ground haze; the measured opaque moss edge ends at
	# y=862 in the source, i.e. 84% of the used frame. Anchor that contact, not the canvas.
	var extent := Vector2(190, 190 * foreground_source.size.y / foreground_source.size.x) * world_rect().size.x / CANVAS.x
	return {"texture": GARDEN_FOREGROUND, "source": foreground_source,
		"rect": Rect2(point(Vector2(670, 590)) - extent * Vector2(0.5, 0.84), extent)}

func world_rect() -> Rect2:
	var extent := CANVAS * minf(size.x / CANVAS.x, size.y / CANVAS.y)
	return Rect2((size - extent) * 0.5, extent)

func point(source: Vector2) -> Vector2:
	var world := world_rect()
	return world.position + source * world.size / CANVAS

func frame(kind: StringName) -> Dictionary:
	var scale_value := world_rect().size.x / CANVAS.x
	var profile: Dictionary = MAIN_HALL_VISUAL if kind == &"hall" else QUARTERS_VISUAL
	var extent := Vector2.ONE * float(DISPLAY[kind]["width"]) * scale_value
	var foot := point(DISPLAY[kind]["foot"])
	var rect := Rect2(foot - extent * Vector2(profile["foot"]), extent)
	return {"rect": rect, "foot": foot, "entrance": rect.position + extent * Vector2(profile["entrance"]), "scale": scale_value}

func wing() -> Dictionary:
	var members := FixedLayout.members(GameState, &"disciple_quarters")
	return {} if members.is_empty() else members[0]

func scaffold() -> Dictionary:
	var rect: Rect2 = frame(&"disciple_quarters")["rect"]
	# Three measured points on the original quarters plinth; same projection as the sprite.
	var left := rect.position + rect.size * Vector2(75, 779) / 1280.0
	var front := rect.position + rect.size * Vector2(615, 1060) / 1280.0
	var right := rect.position + rect.size * Vector2(1168, 780) / 1280.0
	var base := PackedVector2Array([left + right - front, right, front, left])
	var top := PackedVector2Array()
	var hull := PackedVector2Array()
	for at: Vector2 in base:
		top.append(at - Vector2(0, rect.size.y * 0.23))
		hull.append(at)
		hull.append(top[-1])
	return {"base": base, "top": top, "hull": Geometry2D.convex_hull(hull)}

func pick(at: Vector2) -> StringName:
	var building := wing()
	if not building.is_empty():
		if not building["completed"]:
			if Geometry2D.is_point_in_polygon(at, scaffold()["hull"]):
				return &"disciple_quarters"
		elif _is_sprite_hit(QUARTERS_SAMPLE, Rect2(Vector2.ZERO, QUARTERS_SAMPLE.get_size()), frame(&"disciple_quarters")["rect"], at):
			return &"disciple_quarters"
	if _is_sprite_hit(MAIN_HALL_SAMPLE, Rect2(Vector2.ZERO, MAIN_HALL_SAMPLE.get_size()), frame(&"hall")["rect"], at):
		return &"hall"
	return &""

func _draw() -> void:
	draw_texture_rect(DISTANT_CLOUDS, Rect2(Vector2.ZERO, size), false)
	draw_texture_rect(GARDEN_BACKGROUND if garden_enabled else BACKGROUND, world_rect(), false)
	for kind: StringName in [&"hall", &"disciple_quarters"]:
		var building := wing() if kind == &"disciple_quarters" else {}
		if kind != &"hall" and building.is_empty():
			continue
		var visual := frame(kind)
		var rect: Rect2 = visual["rect"]
		if kind == &"hall" and contact_enabled:
			_draw_hall_contact()
		else:
			Garden25.shadow(self, visual["foot"] + Vector2(5, 3) * visual["scale"], rect.size.x * 0.34, rect.size.y * 0.035, 0.16)
		if kind == &"disciple_quarters" and not building["completed"]:
			var geometry := scaffold()
			for i: int in range(4):
				var color := Color("e8c66d") if selected == kind else Color("886442")
				draw_line(geometry["base"][i], geometry["top"][i], color, 3, true)
				draw_line(geometry["top"][i], geometry["top"][(i + 1) % 4], color, 3, true)
		else:
			var texture: Texture2D = MAIN_HALL_SAMPLE if kind == &"hall" else QUARTERS_SAMPLE
			draw_texture_rect(texture, rect, false)
			if selected == kind:
				Outline25.draw(self, texture, Rect2(Vector2.ZERO, texture.get_size()), rect)
	if garden_enabled and foreground_enabled:
		# Grounded in the new flat planting pocket, after the lower wing (depth 560).
		# It may hide a base corner, but never participates in occupancy or hit mapping.
		var foreground := foreground_frame()
		draw_texture_rect_region(foreground["texture"], foreground["rect"], foreground["source"])

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var kind := pick(event.position)
		tooltip_text = "主殿 · 点击查看" if kind == &"hall" else ("弟子居 · 点击建设管理" if kind != &"" else "")
		mouse_default_cursor_shape = CURSOR_ARROW if kind == &"" else CURSOR_POINTING_HAND
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		site_selected.emit(pick(event.position))
		accept_event()
