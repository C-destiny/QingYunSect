class_name TerritoryCatalog
extends RefCounted

const MAP_SIZE := Vector2i(12, 8)
const REGION_IDS := [&"core", &"east", &"south"]

const REGIONS := {
	"core": {
		"name": "宗门本部",
		"origin": Vector2i(0, 0),
		"size": Vector2i(8, 6),
		"required_sect_level": 1,
		"cost": {},
		"requires": &"",
	},
	"east": {
		"name": "东麓林地",
		"origin": Vector2i(8, 0),
		"size": Vector2i(4, 6),
		"required_sect_level": 3,
		"cost": {"wood": 400, "spirit_stone": 180},
		"requires": &"core",
	},
	"south": {
		"name": "南坡灵壤",
		"origin": Vector2i(0, 6),
		"size": Vector2i(12, 2),
		"required_sect_level": 5,
		"cost": {"wood": 800, "spirit_stone": 400, "food": 300},
		"requires": &"east",
	},
}


static func get_data(region_id: StringName) -> Dictionary:
	return REGIONS.get(String(region_id), {})


static func get_cost_text(region_id: StringName) -> String:
	var cost: Dictionary = get_data(region_id).get("cost", {})
	var parts := PackedStringArray()
	if int(cost.get("wood", 0)) > 0:
		parts.append("木材%d" % int(cost["wood"]))
	if int(cost.get("spirit_stone", 0)) > 0:
		parts.append("灵石%d" % int(cost["spirit_stone"]))
	if int(cost.get("food", 0)) > 0:
		parts.append("灵谷%d" % int(cost["food"]))
	return "、".join(parts)


static func get_region_for_cell(cell: Vector2i) -> StringName:
	if cell.x < 0 or cell.y < 0 or cell.x >= MAP_SIZE.x or cell.y >= MAP_SIZE.y:
		return &""
	for region_id: StringName in REGION_IDS:
		var region := get_data(region_id)
		var origin: Vector2i = region["origin"]
		var size: Vector2i = region["size"]
		if cell.x >= origin.x and cell.y >= origin.y and cell.x < origin.x + size.x and cell.y < origin.y + size.y:
			return region_id
	return &""


static func normalize_unlocked_regions(raw_regions: Variant) -> Array[String]:
	var normalized: Array[String] = []
	if not raw_regions is Array:
		return normalized
	var seen: Dictionary = {}
	for raw_region: Variant in raw_regions:
		if not raw_region is String and not raw_region is StringName:
			return []
		var region_id := StringName(raw_region)
		if region_id not in REGION_IDS or seen.has(region_id):
			return []
		seen[region_id] = true
	if not seen.has(&"core"):
		return []
	for region_id: StringName in REGION_IDS:
		if not seen.has(region_id):
			continue
		var required := StringName(get_data(region_id).get("requires", &""))
		if required != &"" and not seen.has(required):
			return []
		normalized.append(String(region_id))
	return normalized
