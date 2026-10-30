extends SceneTree

const Economy = preload("res://scripts/core/sect_economy.gd")
const Sites = preload("res://scripts/data/resource_catalog.gd")
var state: Node
var seconds := 0
var records: Array[Dictionary] = []
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func tick() -> void:
	for site: StringName in Sites.SITES:
		var data: Dictionary = Sites.get_site(site)
		state.process_production(site, StringName(data["resource_id"]), float(data["rate"]), 1.0)
	state.process_construction(1.0)
	state.process_recruitment(1.0)
	state.process_disciple_consumption(1.0)
	state.process_training(1.0)
	seconds += 1

func record(label: String) -> void:
	records.append({"node": label, "seconds": seconds, "resources": state.resources.duplicate(true),
		"population": state.total_disciples, "capacity": state.get_disciple_capacity(),
		"training": state.training_disciples, "flow": Economy.overview(state)["rows"]})

func construct(kind: StringName, cell: Vector2i) -> void:
	var cost: Dictionary = BuildingCatalog.get_data(kind)["cost"]
	while not state.can_afford(cost) and seconds < 3600:
		tick()
	check(state.start_construction(kind, cell), "reachable construction: " + String(kind))
	while seconds < 3600:
		var pending := false
		for building: Dictionary in state.buildings:
			pending = pending or not bool(building["completed"])
		if not pending:
			break
		tick()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	state = root.get_node("GameState")
	state.set_disciple_job(1, &"field")
	state.set_disciple_job(2, &"forest")
	state.set_disciple_job(3, &"mine")
	record("开局：三基础岗位")
	construct(&"disciple_quarters", Vector2i(3, 3))
	check(state.start_recruitment(), "recruitment affordable from initial resources")
	while state.is_recruiting() and seconds < 3600:
		tick()
	check(state.total_disciples == 4, "first expansion reached")
	state.set_disciple_job(4, &"field")
	record("首次扩容：第四名普通弟子")
	construct(&"training_ground", Vector2i(5, 5))
	state.set_disciple_job(4, &"training")
	record("培养准备：保留三生产岗、一修炼岗")
	construct(&"artifact_forge", Vector2i(7, 5))
	var recipe: Dictionary = state.get_equipment_crafting_recipe(&"initiate_weapon", &"common")
	while not state.can_afford(recipe["cost"]) and seconds < 3600:
		tick()
	var item: int = state.craft_equipment(&"initiate_weapon", &"common")
	check(item > 0 and state.equip_item(4, item), "first weapon craft and equip reachable")
	record("装备准备：主动副本尚未实现")
	check(state.claimed_development_goals.is_empty() and state.battle_victories == 0, "no goal rewards, battle rewards or gifted resources used")
	check(Economy.guidance(state)["id"] == "prepared", "preparation cannot masquerade as unlocked active dungeon")
	while int(state.get_disciple(4)["realm_level"]) < 3 and seconds < 3600:
		tick()
		if state.can_breakthrough(4):
			state.breakthrough_disciple(4)
	check(int(state.get_disciple(4)["realm_level"]) == 3, "training reaches realm3 in parallel without battle income")
	print("TRAINING_REALM3_SECONDS: " + str(seconds))
	for snapshot: Dictionary in records:
		check(snapshot["flow"]["food"]["net"] > 0.0, "positive sustainable food at node: " + snapshot["node"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/p2-validation"))
	var output := FileAccess.open("res://builds/p2-validation/resource-baseline.json", FileAccess.WRITE)
	check(output != null, "baseline artifact is writable")
	if output:
		output.store_string(JSON.stringify(records, "\t"))
	for snapshot: Dictionary in records:
		print("BASELINE: " + JSON.stringify(snapshot))
	if failures == 0:
		print("PASS: four-node resource progression from actual starting state without battle, rewards or resource injection")
	quit(1 if failures else 0)
