class_name EquipmentCatalog
extends RefCounted

const SLOT_IDS := [&"weapon", &"armor", &"ring"]
const QUALITY_IDS := [&"common", &"rare", &"epic"]

const SLOTS := {
	"weapon": "武器",
	"armor": "衣服",
	"ring": "戒指",
}

const QUALITIES := {
	"common": {"name": "普通", "multiplier": 1.0},
	"rare": {"name": "稀有", "multiplier": 1.5},
	"epic": {"name": "史诗", "multiplier": 2.25},
}

const TEMPLATES := {
	"initiate_weapon": {"name": "入门法器", "slot": "weapon", "base_stats": {"attack": 4.0}},
	"cloud_robe": {"name": "云纹衣", "slot": "armor", "base_stats": {"hp": 20.0, "defense": 2.0}},
	"spirit_ring": {"name": "聚灵戒", "slot": "ring", "base_stats": {"hp": 10.0, "attack": 2.0, "defense": 1.0}},
}


static func get_template(template_id: StringName) -> Dictionary:
	return TEMPLATES.get(String(template_id), {})


static func get_quality(quality_id: StringName) -> Dictionary:
	return QUALITIES.get(String(quality_id), {})


static func build_instance(instance_id: int, template_id: StringName, quality_id: StringName) -> Dictionary:
	var template := get_template(template_id)
	var quality := get_quality(quality_id)
	if instance_id <= 0 or template.is_empty() or quality.is_empty():
		return {}
	var stats: Dictionary = {}
	var multiplier := float(quality["multiplier"])
	for stat_id: Variant in template["base_stats"]:
		stats[String(stat_id)] = float(template["base_stats"][stat_id]) * multiplier
	return {
		"id": instance_id,
		"template_id": String(template_id),
		"slot": str(template["slot"]),
		"quality": String(quality_id),
		"stats": stats,
	}


static func normalize_instance(raw_equipment: Variant) -> Dictionary:
	if not raw_equipment is Dictionary:
		return {}
	var equipment: Dictionary = raw_equipment
	var canonical := build_instance(
		int(equipment.get("id", 0)),
		StringName(equipment.get("template_id", "")),
		StringName(equipment.get("quality", ""))
	)
	if canonical.is_empty() or str(equipment.get("slot", "")) != str(canonical["slot"]):
		return {}
	var raw_stats: Variant = equipment.get("stats", {})
	if not raw_stats is Dictionary:
		return {}
	var expected_stats: Dictionary = canonical["stats"]
	if raw_stats.size() != expected_stats.size():
		return {}
	for stat_id: Variant in expected_stats:
		if not raw_stats.has(stat_id) or typeof(raw_stats[stat_id]) not in [TYPE_INT, TYPE_FLOAT]:
			return {}
		if not is_equal_approx(float(raw_stats[stat_id]), float(expected_stats[stat_id])):
			return {}
	return canonical


static func get_display_name(equipment: Dictionary) -> String:
	var template := get_template(StringName(equipment.get("template_id", "")))
	var quality := get_quality(StringName(equipment.get("quality", "")))
	if template.is_empty() or quality.is_empty():
		return "无效装备"
	return "%s·%s" % [quality["name"], template["name"]]
