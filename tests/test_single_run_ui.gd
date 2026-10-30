extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var arena = load("res://scripts/combat/single_run_arena.gd").new()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.simulation.gain_experience(100)
	arena._physics_process(0)
	assert(arena.choice_panel.get_child_count() == 3)
	arena.choice_panel.get_child(0).pressed.emit()
	assert(arena.simulation.pending_choices > 0)
	arena._physics_process(0)
	assert(arena.choice_panel.get_child_count() == 3)
	arena.get_child(0).get_child(0).get_child(2).get_child(1).pressed.emit()
	assert(arena.simulation.level == 1 and arena.simulation.levels.is_empty() and arena.simulation.enemies.is_empty())
	for id: String in arena.simulation.UPGRADES:
		arena.simulation.levels[id] = 3
	arena.simulation.pending_choices = 1
	assert(arena.simulation.choices() == ["recover"])
	assert(not arena.simulation.choose_upgrade("power"))
	assert(arena.simulation.choose_upgrade("recover"))
	if DisplayServer.get_name() != "headless":
		arena._restart_run()
		arena.simulation.gain_experience(12)
		for size: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
			root.size = size
			arena._physics_process(0)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			assert(arena.choice_panel.get_global_rect().end.x <= root.size.x)
			root.get_texture().get_image().save_png("res://docs/art/p5-upgrades-%d.png" % size.x)
		arena.simulation.pending_choices = 0
		arena.simulation.elapsed = 451
		arena.simulation.boss_spawned = true
		for kind: String in ["chaser","ranged","charger","boss"]:
			arena.simulation.add_enemy(kind,Vector2(200+arena.simulation.enemies.size()*200,350))
		for size: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
			root.size = size
			arena._physics_process(0)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/art/p5-boss-%d.png" % size.x)
	arena.queue_free()
	await process_frame
	print("PASS: upgrade UI, queued choices, cap fallback and clean restart")
	quit()
