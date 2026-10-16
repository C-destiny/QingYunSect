extends SceneTree

const BattleCatalogData := preload("res://scripts/data/battle_catalog.gd")

func _init() -> void:
	assert(BattleCatalogData.ROUND_TIME == 1.0)
	assert(BattleCatalogData.RESTART_DELAY == 2.0)
	var realm_one: Dictionary = BattleCatalogData.get_disciple_stats(1)
	var realm_five: Dictionary = BattleCatalogData.get_disciple_stats(5)
	var realm_nine: Dictionary = BattleCatalogData.get_disciple_stats(9)
	assert(realm_one == {"hp": 100.0, "attack": 10.0, "defense": 5.0})
	assert(realm_five == {"hp": 180.0, "attack": 22.0, "defense": 13.0})
	assert(realm_nine == {"hp": 260.0, "attack": 34.0, "defense": 21.0})
	assert(BattleCatalogData.calculate_damage(10.0, 99.0) == 1.0)
	assert(BattleCatalogData.get_stage(1)["rewards"] == {"wood": 20, "food": 10})
	assert(BattleCatalogData.get_stage(5)["rewards"] == {"wood": 50, "spirit_stone": 40, "food": 30})
	print("PASS: V0.4 battle and production balance baseline remains unchanged")
	quit()
