extends SceneTree
const Sim = preload("res://scripts/combat/single_run_simulation.gd")
var state: Node
var manager: Node
var service
func advance(seconds: float) -> void:
	state.process_production(&"forest",&"wood",12,seconds)
	state.process_production(&"mine",&"spirit_stone",8,seconds)
	state.process_production(&"field",&"food",10,seconds)
	state.process_disciple_consumption(seconds)
	state.process_training(seconds)
	state.process_medicine(seconds)
	state.process_construction(seconds)
func _init() -> void:
	call_deferred("run")
func run() -> void:
	state = load("res://scripts/core/game_state.gd").new()
	manager = load("res://scripts/core/save_manager.gd").new()
	root.add_child(state)
	root.add_child(manager)
	manager.game_state = state
	manager.save_path = "res://tests/.core_progression_loop.json"
	manager.unix_time_provider = func(): return 5000
	service = load("res://scripts/core/dungeon_service.gd").new(state,manager)
	state.get_idle_disciples()
	assert(state.set_disciple_job(2,&"forest"))
	assert(state.set_disciple_job(3,&"field"))
	for run_index: int in range(2):
		var stats: Dictionary = state.get_disciple_battle_stats(1)
		var id: int = service.begin(1)
		assert(id > 0)
		var sim := Sim.new()
		sim.configure(stats)
		var frames := 0
		while sim.phase == "combat" and frames < 13000:
			while sim.pending_choices > 0:
				var choices := sim.choices()
				var pick := choices[0]
				for candidate: String in ["multi","power","haste","orbit","guard","vitality","range","stride","orbit_range","recover"]:
					if candidate in choices:
						pick = candidate
						break
				assert(sim.choose_upgrade(pick))
			var angle: float = sim.elapsed * 0.55
			var target := Vector2(600+260*cos(angle),400+180*sin(angle))
			sim.step(0.05,(target-sim.player).normalized())
			advance(0.05)
			frames += 1
		assert(sim.phase in ["victory","defeat"])
		var wood: int = state.resources["wood"]
		assert(service.finish(id,sim.kills,sim.elapsed,sim.phase == "victory"))
		assert(not service.finish(id,sim.kills,sim.elapsed,sim.phase == "victory"))
		assert(state.resources["wood"] >= wood)
		print("CORE_RUN %d result=%s seconds=%.1f kills=%d hp=%.1f attack=%.1f" % [run_index+1,sim.phase,sim.elapsed,sim.kills,sim.hp,stats["attack"]])
		if run_index == 0:
			assert(state.set_disciple_job(2,&"mine"))
			advance(600)
			assert(state.start_construction(&"training_ground",Vector2i(0,0)))
			advance(60)
			assert(state.start_medicine())
			advance(60)
			assert(state.use_medicine(1))
			assert(state.set_disciple_job(1,&"training"))
			advance(600)
			assert(state.set_disciple_job(1,&"idle"))
			assert(state.breakthrough_disciple(1))
			assert(state.start_construction(&"scripture_library",Vector2i(1,0)))
			advance(60)
			assert(state.learn_technique(1,"edge"))
			assert(state.select_technique(1,"edge"))
			assert(state.get_disciple_battle_stats(1)["attack"] > stats["attack"])
		assert(manager.save_game())
		var before: Dictionary = state.export_save_data()
		assert(manager.load_game())
		assert(JSON.parse_string(JSON.stringify(state.export_save_data())) == JSON.parse_string(JSON.stringify(before)))

	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manager.save_path+suffix))
	manager.queue_free()
	state.queue_free()
	print("PASS: two actual simulated runs, production-funded medicine and techniques, growth and persistent settlement")
	quit()