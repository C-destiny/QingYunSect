extends RefCounted
var state: Node
var manager: Node
var last_message := ""
func _init(game: Node, saves: Node) -> void:
	state = game
	manager = saves
func commit(before: Dictionary) -> bool:
	if not manager.save_game():
		state.import_save_data(before)
		return false
	state.resources_changed.emit()
	state.disciples_changed.emit()
	state.equipment_changed.emit()
	return true
func begin(disciple_id: int) -> int:
	var d: Dictionary = state.get_disciple(disciple_id)
	if not state.dungeon_progress["active"].is_empty() or d.is_empty() or d.get("job") != "idle" or state.auto_battle_enabled:
		return 0
	var before: Dictionary = state.export_save_data()
	var id := int(state.dungeon_progress["sequence"])+1
	state.dungeon_progress["sequence"] = id
	state.dungeon_progress["active"] = {"id":id,"disciple_id":disciple_id,"kills":0,"elapsed":0.0}
	return id if commit(before) else 0
func checkpoint(id: int, kills: int, elapsed: float) -> bool:
	var a: Dictionary = state.dungeon_progress["active"]
	if a.is_empty() or int(a["id"]) != id or kills < int(a["kills"]) or kills > 500 or not is_finite(elapsed) or elapsed < float(a["elapsed"]) or elapsed > 600:
		return false
	var before: Dictionary = state.export_save_data()
	a["kills"] = kills
	a["elapsed"] = elapsed
	return commit(before)
func finish(id: int, kills: int, elapsed: float, victory: bool) -> bool:
	var a: Dictionary = state.dungeon_progress["active"]
	if a.is_empty() or int(a["id"]) != id or kills < int(a["kills"]) or kills > 500 or not is_finite(elapsed) or elapsed < float(a["elapsed"]) or elapsed > 600 or (victory and elapsed < 450):
		return false
	var before: Dictionary = state.export_save_data()
	var basic := mini(kills,60)
	state.resources["wood"] += basic+(30 if victory else 0)
	state.resources["spirit_stone"] += basic+(20 if victory else 0)
	state.resources["food"] += 20 if victory else 0
	if victory:
		if int(state.dungeon_progress["wins"]) == 0:
			state.dungeon_progress["pending_weapon"] = 1
		state.dungeon_progress["wins"] += 1
	state.dungeon_progress["settled"] = id
	state.dungeon_progress["active"] = {}
	var saved := commit(before)
	if saved:
		last_message = "结算已保存：木材+%d，灵石+%d，灵谷+%d" % [basic+(30 if victory else 0),basic+(20 if victory else 0),20 if victory else 0]
	return saved
func recover() -> bool:
	var a: Dictionary = state.dungeon_progress["active"]
	return true if a.is_empty() else finish(int(a["id"]),int(a["kills"]),float(a["elapsed"]),false)
func claim_weapon() -> bool:
	if int(state.dungeon_progress["pending_weapon"]) == 0 or state.equipment_inventory.size() >= state.MAX_EQUIPMENT_INVENTORY:
		return false
	var before: Dictionary = state.export_save_data()
	if state.create_equipment_instance(&"initiate_weapon",&"rare") <= 0:
		return false
	state.dungeon_progress["pending_weapon"] = 0
	return commit(before)
