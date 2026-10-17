class_name ProfessionCatalog
extends RefCounted

const PROFESSIONS := {
	"sword": {
		"name": "剑修",
		"description": "攻守均衡，生命与防御更稳",
		"multipliers": {"hp": 1.10, "attack": 1.10, "defense": 1.05},
	},
	"mage": {
		"name": "法修",
		"description": "术法爆发更强，但身法防护较弱",
		"multipliers": {"hp": 0.90, "attack": 1.25, "defense": 0.90},
	},
}


static func get_data(profession_id: StringName) -> Dictionary:
	return PROFESSIONS.get(String(profession_id), {})


static func is_valid(profession_id: StringName) -> bool:
	return not get_data(profession_id).is_empty()


static func get_display_name(profession_id: StringName) -> String:
	return str(get_data(profession_id).get("name", "未知职业"))


static func apply_to_stats(profession_id: StringName, base_stats: Dictionary) -> Dictionary:
	var profession := get_data(profession_id)
	if profession.is_empty():
		return {}
	var multipliers: Dictionary = profession["multipliers"]
	return {
		"hp": float(base_stats.get("hp", 0.0)) * float(multipliers["hp"]),
		"attack": float(base_stats.get("attack", 0.0)) * float(multipliers["attack"]),
		"defense": float(base_stats.get("defense", 0.0)) * float(multipliers["defense"]),
	}
