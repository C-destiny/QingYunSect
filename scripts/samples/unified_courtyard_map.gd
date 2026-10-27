extends "res://scripts/samples/hall_courtyard_map.gd"

const GROUND28: Texture2D = preload("res://assets/environment/courtyard-unified28.png")
const HALL28: Texture2D = preload("res://assets/buildings/hall-unified28.png")
const WING28: Texture2D = preload("res://assets/buildings/quarters-unified28.png")
# Measured alpha>0.1 bounds; exclude near-invisible generation haze, especially
# on the wing canvas border. Coordinates are source pixels, not logical cells.
const SOURCES28 := {
	&"hall": Rect2(24, 60, 1550, 872),
	&"disciple_quarters": Rect2(63, 66, 1548, 825),
}
const SITES28 := {
	&"hall": {"foot": Vector2(1175, 510), "width": 760.0, "entrance": Vector2(0.40, 0.96),
		"base": [Vector2(0, 0.77), Vector2(0.77, 1), Vector2(1, 0.79), Vector2(0.25, 0.62)]},
	&"disciple_quarters": {"foot": Vector2(490, 535), "width": 500.0, "entrance": Vector2(0.64, 0.95),
		"base": [Vector2(0.05, 0.78), Vector2(0.32, 1), Vector2(0.96, 0.79), Vector2(0.70, 0.62)]},
}
var previous_enabled := false

func sprite(kind: StringName) -> Texture2D:
	return HALL28 if kind == &"hall" else WING28

func frame(kind: StringName) -> Dictionary:
	if previous_enabled:
		return super.frame(kind)
	var site: Dictionary = SITES28[kind]
	var source: Rect2 = SOURCES28[kind]
	var scale_value := world_rect().size.x / CANVAS.x
	var extent := Vector2(site["width"], float(site["width"]) * source.size.y / source.size.x) * scale_value
	var foot := point(site["foot"])
	var rect := Rect2(foot - extent * Vector2(0.5, 1), extent)
	return {"rect": rect, "foot": foot, "entrance": rect.position + rect.size * Vector2(site["entrance"]), "scale": scale_value}

func _base(kind: StringName) -> PackedVector2Array:
	var rect: Rect2 = frame(kind)["rect"]
	var points := PackedVector2Array()
	for uv: Vector2 in SITES28[kind]["base"]:
		points.append(rect.position + rect.size * uv)
	return points

func scaffold() -> Dictionary:
	if previous_enabled:
		return super.scaffold()
	var base := _base(&"disciple_quarters")
	var top := PackedVector2Array()
	var hull := PackedVector2Array()
	var rect: Rect2 = frame(&"disciple_quarters")["rect"]
	for at: Vector2 in base:
		top.append(at - Vector2(0, rect.size.y * 0.55))
		hull.append(at)
		hull.append(top[-1])
	return {"base": base, "top": top, "hull": Geometry2D.convex_hull(hull)}

func pick(at: Vector2) -> StringName:
	if previous_enabled:
		return super.pick(at)
	var building := wing()
	if not building.is_empty():
		if not building["completed"]:
			if Geometry2D.is_point_in_polygon(at, scaffold()["hull"]):
				return &"disciple_quarters"
		elif _is_sprite_hit(WING28, SOURCES28[&"disciple_quarters"], frame(&"disciple_quarters")["rect"], at):
			return &"disciple_quarters"
	if _is_sprite_hit(HALL28, SOURCES28[&"hall"], frame(&"hall")["rect"], at):
		return &"hall"
	return &""

func _draw() -> void:
	if previous_enabled:
		super._draw()
		return
	draw_texture_rect(GROUND28, world_rect(), false)
	for kind: StringName in [&"hall", &"disciple_quarters"]:
		var building := wing() if kind == &"disciple_quarters" else {}
		if kind != &"hall" and building.is_empty():
			continue
		var visual := frame(kind)
		var rect: Rect2 = visual["rect"]
		if kind == &"disciple_quarters" and not building["completed"]:
			var geometry := scaffold()
			for i: int in range(4):
				var color := Color("e8c66d") if selected == kind else Color("886442")
				draw_line(geometry["base"][i], geometry["top"][i], color, 3, true)
				draw_line(geometry["top"][i], geometry["top"][(i + 1) % 4], color, 3, true)
			continue
		var base := _base(kind)
		for ring: int in range(6, 0, -1):
			var shadow := PackedVector2Array()
			for at: Vector2 in base:
				shadow.append(at + Vector2(1.4, 1.0) * ring * float(visual["scale"]))
			draw_colored_polygon(shadow, Color(0.08, 0.13, 0.13, 0.035))
		draw_texture_rect_region(sprite(kind), rect, SOURCES28[kind])
		if selected == kind:
			Outline25.draw(self, sprite(kind), SOURCES28[kind], rect)
