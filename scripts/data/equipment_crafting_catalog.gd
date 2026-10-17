class_name EquipmentCraftingCatalog
extends RefCounted

const EquipmentCatalogData = preload("res://scripts/data/equipment_catalog.gd")

const RECIPES := {
	"common": {
		"name": "普通",
		"required_forge_level": 1,
		"cost": {"wood": 80, "spirit_stone": 60, "food": 20},
	},
	"rare": {
		"name": "稀有",
		"required_forge_level": 2,
		"cost": {"wood": 160, "spirit_stone": 140, "food": 50},
	},
	"epic": {
		"name": "史诗",
		"required_forge_level": 3,
		"cost": {"wood": 320, "spirit_stone": 300, "food": 120},
	},
}


static func get_recipe(template_id: StringName, quality: StringName) -> Dictionary:
	if EquipmentCatalogData.get_template(template_id).is_empty():
		return {}
	return RECIPES.get(String(quality), {}).duplicate(true)


static func get_cost_text(template_id: StringName, quality: StringName) -> String:
	var recipe := get_recipe(template_id, quality)
	if recipe.is_empty():
		return "无效配方"
	var cost: Dictionary = recipe["cost"]
	return "木材%d 灵石%d 灵谷%d" % [
		int(cost.get("wood", 0)),
		int(cost.get("spirit_stone", 0)),
		int(cost.get("food", 0)),
	]
