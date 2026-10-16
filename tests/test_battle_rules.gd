extends SceneTree

const BattleCatalogData = preload("res://scripts/data/battle_catalog.gd")


func _init() -> void:
	var state := preload("res://scripts/core/game_state.gd").new()
	root.add_child(state)
	state.get_idle_disciples()
	var disciple_id := int(state.disciples[0]["id"])
	assert(state.set_disciple_job(disciple_id, &"combat"))

	var level_one := BattleCatalogData.get_disciple_stats(1)
	var level_nine := BattleCatalogData.get_disciple_stats(9)
	assert(level_one == {"hp": 100.0, "attack": 10.0, "defense": 5.0})
	assert(level_nine == {"hp": 260.0, "attack": 34.0, "defense": 21.0})
	assert(is_equal_approx(BattleCatalogData.calculate_damage(3.0, 99.0), 1.0))
	assert(is_equal_approx(BattleCatalogData.calculate_damage(15.0, 4.0), 11.0))

	assert(state.get_battle_phase() == &"stopped")
	assert(state.start_auto_battle(1))
	assert(state.get_battle_phase() == &"fighting")
	state.process_battle(1.0)
	var player_hp_after_round := state.battle_player_hp
	var enemy_hp_after_round := state.battle_enemy_hp
	var round_progress_after_round := state.battle_round_progress
	assert(not state.start_auto_battle(1))
	assert(is_equal_approx(state.battle_player_hp, player_hp_after_round))
	assert(is_equal_approx(state.battle_enemy_hp, enemy_hp_after_round))
	assert(is_equal_approx(state.battle_round_progress, round_progress_after_round))
	assert(not state.process_battle(0.0))
	assert(not state.process_battle(-10.0))
	assert(is_equal_approx(state.battle_enemy_hp, enemy_hp_after_round))

	var disciple := state.get_disciple(disciple_id)
	disciple["cultivation"] = state.get_breakthrough_requirement(1)
	assert(state.breakthrough_disciple(disciple_id))
	assert(is_equal_approx(state.battle_player_max_hp, 100.0))
	state.process_battle(1.0)
	assert(is_equal_approx(state.battle_enemy_hp, enemy_hp_after_round - 11.0))

	var wood_before := state.get_resource_amount(&"wood")
	assert(state.process_battle(1000.0))
	assert(state.get_battle_phase() == &"repeat_wait")
	assert(state.battle_victories == 1)
	assert(state.get_resource_amount(&"wood") == wood_before + 20)
	assert(not state.process_battle(0.5))
	assert(state.get_battle_phase() == &"repeat_wait")
	assert(not state.process_battle(state.BATTLE_RESTART_DELAY))
	assert(state.get_battle_phase() == &"fighting")
	assert(state.battle_victories == 1)

	state.stop_auto_battle()
	assert(state.get_battle_phase() == &"stopped")
	assert(not state.auto_battle_enabled)
	assert(is_zero_approx(state.battle_restart_cooldown))
	print("PASS: centralized battle formulas and explicit state transition contract")
	quit()
