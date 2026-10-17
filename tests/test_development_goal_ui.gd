extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_development_goal_ui.json"


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	var state := root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = TEST_SAVE_PATH
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	var status: Label = main.get_node("%GoalStatus")
	var feedback: Label = main.get_node("%GoalResourceFeedback")
	var claim_button: Button = main.get_node("%ClaimGoalButton")
	assert("初具规模" in status.text)
	assert("资源流" in feedback.text)
	assert(claim_button.disabled)
	state.sect_level = 2
	state.sect_progress_changed.emit()
	assert(not claim_button.disabled)
	var before: Dictionary = state.resources.duplicate(true)
	main._claim_current_development_goal()
	assert(state.claimed_development_goals == ["sect_level_2"])
	assert(state.get_resource_amount(&"wood") == int(before["wood"]) + 40)
	assert("开拓东麓" in status.text)
	assert(manager.has_save())

	state.unlocked_regions.append("east")
	main._refresh_development_goal()
	var rollback: Dictionary = state.export_save_data()
	manager.save_path = "res://tests/missing-directory/goals.json"
	main._claim_current_development_goal()
	assert(state.export_save_data() == rollback)
	assert("已恢复" in feedback.text)
	assert(main.get_node("%NavManagementButton") is Button)
	assert(main.get_node("%NavDisciplesButton") is Button)
	assert(main.get_node("%NavBattleButton") is Button)
	assert(main.get_node("%OpenSectPanelButton") is Button)
	assert(main.get_node("%OpenBuildPanelButton") is Button)
	assert(main.get_node("%OpenDisciplesPanelButton") is Button)
	assert(main.get_node("%OpenGrowthPanelButton") is Button)
	assert(main.get_node("%OpenBattlePanelButton") is Button)
	main.queue_free()
	_cleanup()
	print("PASS: development goal UI shows progress, resource flow, navigation, save, and rollback")
	quit()
