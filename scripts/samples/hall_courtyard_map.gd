extends "res://scripts/world/sect_map.gd"

signal site_selected(kind: StringName)

const BACKGROUND: Texture2D = preload("res://assets/environment/hall_courtyard25.png")
const Outline25 = preload("res://scripts/world/building_selection_outline.gd")
const Garden25 = preload("res://scripts/world/fixed_courtyard_details.gd")
const CANVAS := Vector2(1672, 941)
const DISPLAY := {
	&"hall": {"foot": Vector2(1000, 430), "width": 500.0},
	&"disciple_quarters": {"foot": Vector2(550, 560), "width": 300.0},
}
var selected: StringName = &""

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_exited.connect(func() -> void: tooltip_text = "")

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
	draw_texture_rect(BACKGROUND, world_rect(), false)
	for kind: StringName in [&"hall", &"disciple_quarters"]:
		var building := wing() if kind == &"disciple_quarters" else {}
		if kind != &"hall" and building.is_empty():
			continue
		var visual := frame(kind)
		var rect: Rect2 = visual["rect"]
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

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var kind := pick(event.position)
		tooltip_text = "主殿 · 点击查看" if kind == &"hall" else ("弟子居 · 点击建设管理" if kind != &"" else "")
		mouse_default_cursor_shape = CURSOR_ARROW if kind == &"" else CURSOR_POINTING_HAND
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		site_selected.emit(pick(event.position))
		accept_event()
