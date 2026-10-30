extends SceneTree
func _init() -> void:
	var script = load("res://scripts/combat/single_run_simulation.gd")
	if script == null:
		printerr("FAIL: P5 simulation missing")
		quit(1)
		return
	var sim = script.new()
	var charge = script.new()
	charge.spawn_clock = 100
	charge.cooldown = 100
	charge.add_enemy("charger",Vector2(500,380))
	charge.enemies[0]["warning"] = 0.01
	charge.enemies[0]["target"] = Vector2(600,380)
	charge.step(0.02,Vector2.ZERO)
	assert(float(charge.enemies[0].get("dash_remaining",0)) > 0)
	sim.gain_experience(100)
	assert(sim.pending_choices > 1 and sim.choices().size() == 3)
	var t: float = sim.elapsed
	sim.step(1, Vector2.ONE)
	assert(sim.elapsed == t)
	while sim.pending_choices > 0:
		assert(sim.choose_upgrade(sim.choices()[0]))
	assert(not sim.choose_upgrade("unknown"))
	sim.elapsed = 450
	sim.step(0.01,Vector2.ZERO)
	assert(sim.boss_spawned)
	var bosses := 0
	for e: Dictionary in sim.enemies:
		if e["kind"] == "boss":
			bosses += 1
			e["hp"] = 0
	assert(bosses == 1)
	sim.step(0.01,Vector2.ZERO)
	assert(sim.phase == "victory")
	var frozen: float = sim.elapsed
	sim.step(1,Vector2.ONE)
	assert(sim.elapsed == frozen)
	var fresh = script.new()
	fresh.hp = 0
	fresh.step(1,Vector2.ZERO)
	assert(fresh.phase == "defeat" and fresh.enemies.is_empty())
	print("PASS: level queue, choice freeze, invalid upgrade, unique boss, terminal victory/defeat")
	quit()
