extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_offline_ui.json"

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	var state := root.get_node("GameState")
	var manager := root.get_node("SaveManager")
	manager.save_path = TEST_SAVE_PATH
	manager.unix_time_provider = func() -> int: return 1000
	state.get_idle_disciples()
	assert(state.set_disciple_job(int(state.disciples[0]["id"]), &"forest"))
	assert(manager.save_game())
	manager.unix_time_provider = func() -> int: return 4600
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	var dialog: AcceptDialog = main.get_node("%OfflineSummaryDialog")
	var summary: Label = main.get_node("%OfflineSummaryText")
	assert(dialog.visible)
	assert("离线时长：1小时0分钟" in summary.text)
	assert("资源净变化" in summary.text)
	assert("未开启自动战斗" in summary.text)
	assert(summary.autowrap_mode != TextServer.AUTOWRAP_OFF)
	assert(int(ProjectSettings.get_setting("display/window/size/window_width_override")) == 1280)
	assert(int(ProjectSettings.get_setting("display/window/size/window_height_override")) == 720)
	assert(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 1920)
	assert(int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 1080)
	assert(manager.get_pending_offline_window().is_empty())
	dialog.hide()
	assert(manager.load_game())
	await process_frame
	assert(not dialog.visible)
	main.get_node("%AutosaveTimer").stop()
	main.free()
	manager.unix_time_provider = Callable()
	_cleanup()
	print("PASS: offline summary settles on load, displays receipt, and does not repeat")
	quit()


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var path := TEST_SAVE_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
