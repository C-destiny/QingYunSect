extends SceneTree
func _init() -> void:
	var model = load("res://scripts/combat/practice_simulation.gd").new()
	model.step(0.1, Vector2(1,1))
	assert(is_equal_approx(model.player.distance_to(Vector2(600,380)),24))
	model.paused = true
	var before: Vector2 = model.player
	var time: float = model.elapsed
	model.step(10, Vector2.ONE)
	assert(model.player == before and model.elapsed == time)
	model.paused = false
	model.step(10, Vector2.ONE)
	assert(model.player.x <= 1160 and model.player.y <= 700)
	model.enemies.clear()
	model.spawn_clock = 100
	model.cooldown = 100
	model.enemies.append({"pos":model.player, "hp":100.0,"warning":0.8,"target":model.player})
	var hp: float = model.hp
	model.step(0.4, Vector2.LEFT)
	model.step(0.5, Vector2.LEFT)
	assert(model.hp == hp)
	model.enemies[0]["target"] = model.player
	model.enemies[0]["warning"] = 0.1
	model.step(0.2, Vector2.ZERO)
	assert(model.hp < hp)
	print("PASS: normalized movement, arena bounds, pause, telegraph dodge and damage")
	quit()
