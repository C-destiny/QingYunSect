class_name BuildingCatalog
extends RefCounted

const BUILDINGS := {
	&"disciple_quarters": {
		"name": "弟子居",
		"description": "供普通弟子休息的居所。完工后弟子上限 +2。",
		"cost": {"wood": 40, "spirit_stone": 10},
		"build_time": 6.0,
		"disciple_capacity": 2,
		"color": Color(0.55, 0.38, 0.23, 1.0),
	},
	&"lumber_yard": {
		"name": "伐木场",
		"description": "整理木材。完工后木材采集效率 +25%。",
		"cost": {"wood": 30, "spirit_stone": 15},
		"build_time": 5.0,
		"production_resource": &"wood",
		"production_bonus": 0.25,
		"color": Color(0.38, 0.58, 0.29, 1.0),
	},
	&"spirit_mine": {
		"name": "采灵坊",
		"description": "处理矿石并汇聚灵气。完工后灵石采集效率 +25%。",
		"cost": {"wood": 50, "spirit_stone": 25},
		"build_time": 8.0,
		"production_resource": &"spirit_stone",
		"production_bonus": 0.25,
		"color": Color(0.31, 0.51, 0.68, 1.0),
	},
	&"spirit_field": {
		"name": "灵田",
		"description": "种植供宗门使用的灵谷。完工后灵谷采集效率 +25%。",
		"cost": {"wood": 35, "spirit_stone": 20},
		"build_time": 7.0,
		"production_resource": &"food",
		"production_bonus": 0.25,
		"color": Color(0.65, 0.57, 0.25, 1.0),
	},
	&"training_ground": {
		"name": "演武场",
		"description": "弟子修炼与切磋的场所。每座提供2个修炼位。",
		"cost": {"wood": 60, "spirit_stone": 40},
		"build_time": 10.0,
		"training_capacity": 2,
		"cultivation_rate": 1.0,
		"color": Color(0.58, 0.28, 0.25, 1.0),
	},
}


static func get_data(building_id: StringName) -> Dictionary:
	return BUILDINGS.get(building_id, {})


static func get_cost_text(building_id: StringName) -> String:
	var data := get_data(building_id)
	var cost: Dictionary = data.get("cost", {})
	return "木%d 灵%d" % [int(cost.get("wood", 0)), int(cost.get("spirit_stone", 0))]

