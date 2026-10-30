extends SceneTree

var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not FileAccess.file_exists("res://scripts/core/sect_economy.gd"):
		printerr("FAIL: resource development analysis is not implemented")
		quit(1)
		return
	var economy = load("res://scripts/core/sect_economy.gd")
	var state := root.get_node("GameState")
	var initial: Dictionary = state.export_save_data().duplicate(true)
	var report: Dictionary = economy.overview(state)
	check(is_equal_approx(float(report["rows"]["food"]["minutes"]), 50.0), "initial food runway 150/3 = 50 minutes")
	check(economy.guidance(state)["id"] == "food", "initial advice directs to food before expansion")
	check(state.export_save_data() == initial, "analysis leaves full state unchanged")
	check(state.set_disciple_job(1, &"field"), "assign free starting field")
	check(state.set_disciple_job(2, &"forest"), "assign forest")
	check(state.set_disciple_job(3, &"mine"), "assign mine")
	report = economy.overview(state)
	check(is_equal_approx(float(report["rows"]["wood"]["income"]), 12.0), "wood actual formula")
	check(is_equal_approx(float(report["rows"]["food"]["net"]), 7.0), "food production minus all disciples")
	check(report["rows"]["food"]["minutes"] == -1.0, "positive flow does not invent depletion")
	check(economy.guidance(state)["id"] == "disciple_quarters", "next expand housing")
	var before: Dictionary = state.export_save_data().duplicate(true)
	var projection: Dictionary = economy.estimate_cost(state, {"wood": 144, "spirit_stone": 96})
	check(is_equal_approx(float(projection["minutes"]), 2.0), "parallel resource waiting uses max, not sum")
	check(state.export_save_data() == before, "cost estimation never spends resources")
	state.set_disciple_job(2, &"idle")
	check(economy.estimate_cost(state, {"wood": 144})["minutes"] == -1.0, "zero income has no false completion countdown")
	state.set_disciple_job(2, &"forest")
	state.resources["food"] = 0
	report = economy.overview(state)
	check(report["hungry"] and report["rows"]["food"]["status"] == "hungry", "zero food explicit starvation")
	check(is_equal_approx(float(report["rows"]["wood"]["income"]), 6.0), "starvation retains half production")
	check(is_equal_approx(float(report["rows"]["food"]["net"]), 2.0), "existing field can recover without new building")
	check(economy.guidance(state)["action"] == "site", "recovery uses free site, no mandatory building")
	state.set_disciple_job(1, &"forest")
	check(economy.guidance(state)["action"] == "disciples", "full workforce with no food redirects to usable job transfer")
	state.set_disciple_job(1, &"field")
	state.resources["food"] = 1
	check(economy.overview(state)["hungry"] == false, "restoring food updates immediately")
	state.set_disciple_job(1, &"idle")
	state.resources["food"] = 3
	check(economy.overview(state)["rows"]["food"]["status"] == "warning", "one minute food runway warns")
	state.import_save_data(initial)
	check(state.claimed_development_goals.is_empty(), "new guidance does not add reward markers")
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	check(state.start_construction(&"disciple_quarters", Vector2i(3, 3)), "five-person fixture housing")
	state.process_construction(6)
	for index: int in range(2):
		check(state.start_recruitment(), "five-person fixture recruitment")
		state.process_recruitment(5)
	for disciple: Dictionary in state.disciples:
		state.set_disciple_job(int(disciple["id"]), &"field" if int(disciple["id"]) == 1 else &"forest")
	state.resources["food"] = 0
	check(is_zero_approx(float(economy.overview(state)["rows"]["food"]["net"])), "one hungry farmer cannot feed five disciples")
	check(economy.guidance(state)["action"] == "disciples", "understaffed existing field with full workforce opens job transfer")
	state.import_save_data(initial)
	if failures == 0:
		print("PASS: read-only resource flow, food runway, starvation recovery, development guidance, cost estimation and old reward compatibility")
	quit(1 if failures else 0)
