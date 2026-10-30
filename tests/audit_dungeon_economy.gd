extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var script = load("res://scripts/core/game_state.gd")
	var state: Node = script.new()
	root.add_child(state)
	for id: int in [1,2,3]:
		state.set_disciple_job(id,&"combat")
	state.start_auto_battle(1)
	for i: int in range(450):
		state.process_battle(1)
	print("450s legacy stage1: victories=%d wood_gain=%d food_gain=%d equipment=%d" % [state.battle_victories,state.get_resource_amount(&"wood")-120,state.get_resource_amount(&"food")-150,state.equipment_inventory.size()])
	state.free()
	quit()
