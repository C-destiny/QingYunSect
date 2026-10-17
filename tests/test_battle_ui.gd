extends SceneTree

const TEST_SAVE_PATH := "res://tests/.test_battle_ui.json"


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

	var progress: Label = main.get_node("%BattleProgressSummary")
	var members: Label = main.get_node("%BattlePartyMembers")
	var party_stats: Label = main.get_node("%BattleStats")
	var enemy_info: Label = main.get_node("%EnemyBattleInfo")
	var player_hp: Label = main.get_node("%PlayerBattleHpText")
	var enemy_hp: Label = main.get_node("%EnemyBattleHpText")
	var sidebar: Control = main.get_node("Layout/Body/Sidebar")
	var scroll: ScrollContainer = main.get_node("Layout/Body/Sidebar/Margin/Scroll")
	assert("选中关卡 1" in progress.text)
	assert("当前未挑战" in progress.text)
	assert("暂无参战弟子" in members.text)
	assert("山野狼群" in enemy_info.text)
	assert("生命120" in enemy_info.text)
	assert("攻击9" in enemy_info.text)
	assert("防御2" in enemy_info.text)

	state.get_idle_disciples()
	var disciple_id := int(state.disciples[0]["id"])
	var disciple_name := str(state.disciples[0]["name"])
	var initial_stats: Dictionary = state.get_disciple_battle_stats(disciple_id)
	assert(state.set_disciple_job(disciple_id, &"combat"))
	assert(state.start_auto_battle(1))
	assert(disciple_name in members.text)
	assert("炼气1层" in members.text)
	assert("生命%.0f 攻击%.0f 防御%.0f" % [initial_stats["hp"], initial_stats["attack"], initial_stats["defense"]] in members.text)
	assert("参战中" in members.text)
	assert("生命为队伍共用" in party_stats.text)
	assert("正在挑战 1.山门试炼" in progress.text)
	assert("我方共用生命：%.0f / %.0f" % [initial_stats["hp"], initial_stats["hp"]] in player_hp.text)
	assert("敌方生命：120 / 120" in enemy_hp.text)

	var disciple: Dictionary = state.get_disciple(disciple_id)
	disciple["cultivation"] = state.get_breakthrough_requirement(1)
	assert(state.breakthrough_disciple(disciple_id))
	var advanced_stats: Dictionary = state.get_disciple_battle_stats(disciple_id)
	assert("炼气2层" in members.text)
	assert("生命%.0f 攻击%.0f 防御%.0f" % [advanced_stats["hp"], advanced_stats["attack"], advanced_stats["defense"]] in members.text)

	state.stop_auto_battle()
	state.highest_unlocked_stage = 2
	assert(state.select_battle_stage(2))
	assert("选中关卡 2.林中除妖" in progress.text)
	assert("已解锁 1-2" in progress.text)
	assert("当前未挑战" in progress.text)
	assert("青木妖藤" in enemy_info.text)
	assert(manager.save_game())
	assert(state.set_disciple_job(disciple_id, &"idle"))
	assert("暂无参战弟子" in members.text)
	assert(manager.load_game())
	assert(disciple_name in members.text)
	assert("选中关卡 2.林中除妖" in progress.text)

	assert(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 1920)
	assert(int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 1080)
	assert(int(ProjectSettings.get_setting("display/window/size/window_width_override")) == 1280)
	assert(int(ProjectSettings.get_setting("display/window/size/window_height_override")) == 720)
	assert(sidebar.custom_minimum_size.x >= 420.0)
	assert(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	assert(progress.autowrap_mode != TextServer.AUTOWRAP_OFF)
	assert(members.autowrap_mode != TextServer.AUTOWRAP_OFF)

	main.queue_free()
	_cleanup()
	print("PASS: battle UI shows party, enemy, HP, stage progress, and synchronized state")
	quit()
