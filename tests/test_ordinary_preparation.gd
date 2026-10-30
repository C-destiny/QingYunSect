extends SceneTree

const PATH := "res://tests/.test_ordinary_preparation.json"
const FAIL_PATH := "res://tests/missing-p3-directory/save.json"
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func snapshot(state: Node) -> Variant:
	return JSON.parse_string(JSON.stringify(state.export_save_data()))

func select_disciple(main: Control, id: int) -> void:
	main.roster_filter.select(0)
	main.selected_disciple_id = id
	main.roster_signature = ""
	main._refresh_disciple_roster()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = PATH
	manager.unix_time_provider = func() -> int: return 5000
	for suffix: String in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	main.set_process(false)
	main.autosave_timer.stop()
	check(state.disciples.size() == 3 and state.total_disciples == 3, "three free ordinary disciples, no extra core grants")
	var initial: Dictionary = state.export_save_data()
	check(state.import_save_data(initial) and state.import_save_data(initial), "repeat state load")
	check(state.disciples.size() == 3 and state.next_disciple_id == 4, "repeat load never duplicates gifts")
	check(is_equal_approx(state.get_food_consumption_per_minute(), 3.0), "one food per ordinary disciple per minute")
	var toggle := main.get_node_or_null("%DiscipleTrainingButton") as Button
	check(toggle != null, "selected disciple training action exists")
	if toggle != null:
		select_disciple(main, 1)
		check(toggle.disabled, "cannot train without completed training ground")
		check(state.start_construction(&"training_ground", Vector2i(3, 3)), "training ground fixture uses real construction")
		state.process_construction(10)
		check(not toggle.disabled, "construction completion enables training")
		state.set_disciple_job(1, &"forest")
		select_disciple(main, 1)
		check(toggle.text.contains("采集"), "switch explicitly warns collection stops")
		var before: Variant = snapshot(state)
		manager.save_path = FAIL_PATH
		toggle.pressed.emit()
		check(snapshot(state) == before, "training save failure rolls back job, production and training counters")
		check(main.get_node("%DiscipleActionStatus").text.contains("失败"), "failed training save shown honestly")
		manager.save_path = PATH
		toggle.pressed.emit()
		check(state.get_disciple(1)["job"] == "training" and state.training_disciples == 1, "selected worker now trains in one slot")
		check(state.get_assignment(&"forest") == 0, "same disciple cannot produce and train")
		state.process_training(60)
		check(float(state.get_disciple(1)["cultivation"]) > 0 and float(state.get_disciple(2)["cultivation"]) == 0, "training belongs to selected stable ID")
		state.set_disciple_job(2, &"training")
		select_disciple(main, 3)
		check(toggle.disabled, "shared training slots enforced")
		state.set_disciple_job(3, &"combat")
		select_disciple(main, 3)
		before = snapshot(state)
		toggle.pressed.emit()
		check(snapshot(state) == before and toggle.disabled, "training shortcut cannot silently remove old battle party")
		select_disciple(main, 1)
		main.roster_filter.select(3)
		main._on_roster_view_changed(3)
		toggle.pressed.emit()
		check(main.selected_disciple_id == 1 and state.get_disciple(1)["job"] == "idle", "stopping training retains acted-on disciple despite active filter")
	# Existing actions must be atomic across persistence failures too.
	select_disciple(main, 1)
	state.get_disciple(1)["cultivation"] = 10.0
	main._refresh_disciple_detail()
	var before: Variant = snapshot(state)
	manager.save_path = FAIL_PATH
	main._breakthrough_selected_disciple()
	check(snapshot(state) == before, "breakthrough save failure restores realm and cultivation")
	state.process_training(0.01)
	check(main.get_node("%DiscipleActionStatus").text.contains("失败"), "failed save feedback survives normal training tick")
	manager.save_path = PATH
	main._breakthrough_selected_disciple()
	check(state.get_disciple(1)["realm_level"] == 2 and state.get_disciple(1)["cultivation"] == 0.0, "breakthrough spends cultivation once")
	var weapon: int = state.create_equipment_instance(&"initiate_weapon", &"common")
	main.equipment_slot_selector.select(0)
	main._on_equipment_slot_selected(0)
	before = snapshot(state)
	manager.save_path = FAIL_PATH
	main._equip_selected_item()
	check(snapshot(state) == before and main.equipment_status.text.contains("失败"), "equip save failure restores ownership and gives no success message")
	manager.save_path = PATH
	main._equip_selected_item()
	check(state.get_equipment_owner(weapon) == 1, "equipment uses existing unique ownership")
	check(not state.equip_item(2, weapon), "cannot share one equipment instance")
	var second_weapon: int = state.create_equipment_instance(&"initiate_weapon", &"rare")
	var item_index := -1
	for index: int in range(main.equipment_inventory_selector.item_count):
		if int(main.equipment_inventory_selector.get_item_metadata(index)) == second_weapon:
			item_index = index
	check(item_index >= 0, "second weapon available")
	main.equipment_inventory_selector.select(item_index)
	main._on_equipment_inventory_selected(item_index)
	check(int(main.equipment_inventory_selector.get_item_metadata(main.equipment_inventory_selector.selected)) == second_weapon, "choosing second weapon survives refresh")
	main._equip_selected_item()
	check(state.get_equipment_owner(second_weapon) == 1 and state.get_equipment_owner(weapon) == 0, "equip uses chosen second instance, releases old item")
	before = snapshot(state)
	manager.save_path = FAIL_PATH
	main._unequip_selected_item()
	check(snapshot(state) == before and main.equipment_status.text.contains("失败"), "unequip save failure restores equipment")
	# A failed job edit of a battle member must restore the party and battle state.
	select_disciple(main, 3)
	check(state.start_auto_battle(1) and state.battle_running, "real running battle fixture")
	before = snapshot(state)
	main._on_disciple_job_selected(0)
	check(snapshot(state) == before, "job save failure restores battle membership and activity")
	manager.save_path = PATH
	select_disciple(main, 1)
	check(manager.save_game(), "save preparation")
	before = snapshot(state)
	check(manager.load_game() and snapshot(state) == before, "version3 round trip retains all characters, slots and equipment")
	for view_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = view_size
		main._open_management_panel(main.growth_heading)
		await process_frame
		await process_frame
		await process_frame
		if toggle != null:
			check(main.sidebar_scroll.get_global_rect().encloses(toggle.get_global_rect()), "selected training button reachable at top of growth drawer")
		check(Rect2(Vector2.ZERO, main.size).encloses(main.management_sidebar.get_rect()), "growth drawer fits viewport")
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	if failures == 0:
		print("PASS: ordinary preparation, selected training, capacity, activity exclusivity, save rollback and two-size growth UI")
	quit(1 if failures else 0)
