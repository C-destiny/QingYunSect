extends SceneTree

const BattleCatalogData = preload("res://scripts/data/battle_catalog.gd")
const BuildingCatalogData = preload("res://scripts/data/building_catalog.gd")
const ResourceCatalogData = preload("res://scripts/data/resource_catalog.gd")


func _init() -> void:
	assert(ResourceCatalogData.get_site(&"forest")["rate"] == 12.0)
	assert(ResourceCatalogData.get_site(&"mine")["rate"] == 8.0)
	assert(ResourceCatalogData.get_site(&"field")["rate"] == 10.0)
	assert(BuildingCatalogData.MAX_BUILDING_LEVEL == 3)
	assert(BuildingCatalogData.get_data(&"disciple_quarters")["cost"] == {"wood": 40, "spirit_stone": 10})
	assert(BuildingCatalogData.get_data(&"training_ground")["cost"] == {"wood": 60, "spirit_stone": 40})

	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	assert(state.MAX_SECT_LEVEL == 5)
	assert(state.SECT_LEVEL_REQUIREMENTS == [0, 100, 250, 500, 900])
	assert(state.get_food_consumption_per_minute() == 3.0)
	assert(state.EQUIPMENT_DROP_INTERVAL == 5)
	for disciple: Dictionary in state.disciples:
		assert(state.set_disciple_job(int(disciple["id"]), &"combat"))
	var party: Dictionary = state.get_battle_party_stats()
	assert(is_equal_approx(float(party["attack"]), 34.5))
	var stage: Dictionary = BattleCatalogData.get_stage(1)
	var damage := BattleCatalogData.calculate_damage(float(party["attack"]), float(stage["defense"]))
	var win_rounds := ceili(float(stage["hp"]) / damage)
	assert(win_rounds == 4)
	assert(is_equal_approx(float(win_rounds) * BattleCatalogData.ROUND_TIME + BattleCatalogData.RESTART_DELAY, 6.0))
	assert(stage["rewards"] == {"wood": 20, "food": 10})
	print("PASS: V0.7 economy baseline reproduces production, growth, battle, and drop values")
	quit()
