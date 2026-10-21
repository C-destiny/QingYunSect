extends SceneTree

const Layout = preload("res://scripts/world/fixed_sect_layout.gd")
const Feedback = preload("res://scripts/world/fixed_site_feedback.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	var map: Control = load("res://scripts/world/sect_map.gd").new()
	root.add_child(map)
	map.size = Vector2(1918, 1078)
	map.fixed_layout = true
	check(Feedback.describe(state, &"disciple_quarters")["label"] == "待建", "空院落应待建")
	state.resources["wood"] = 1000
	state.resources["spirit_stone"] = 1000
	check(Layout.construct(state, &"disciple_quarters"), "原付费建设")
	state.process_construction(2)
	var first := Feedback.describe(state, &"disciple_quarters")
	check(first["label"] == "施工" and is_equal_approx(first["job"]["remaining"], 4), "真实施工剩余时间")
	check(is_equal_approx(first["job"]["progress"], 1.0 / 3.0), "真实施工进度")
	check(Layout.construct(state, &"disciple_quarters"), "第二实例并行")
	var parallel := Feedback.describe(state, &"disciple_quarters")
	check(parallel["job_count"] == 2 and parallel["job"]["id"] == state.buildings[0]["instance_id"], "并行展示最早完成项")
	state.process_construction(10)
	check(Feedback.describe(state, &"disciple_quarters")["job"].is_empty(), "完工后移除进度条")
	check(state.start_building_upgrade(int(state.buildings[0]["instance_id"])), "原升级流程")
	state.process_construction(1)
	var upgrade := Feedback.describe(state, &"disciple_quarters")
	check(upgrade["job"]["name"] == "升级" and upgrade["job"]["progress"] > 0, "升级与建设区分")
	var snapshot: Dictionary = state.export_save_data().duplicate(true)
	for size_value: Vector2 in [Vector2(1278, 718), Vector2(1918, 1078)]:
		map.size = size_value
		var point := Feedback.progress_rect(map, &"disciple_quarters").get_center()
		check(map.FixedView.hit(map, point) == &"disciple_quarters", "进度牌可点击")
		var motion := InputEventMouseMotion.new()
		motion.position = point
		map._gui_input(motion)
		check(map.fixed_hover_kind == &"disciple_quarters" and map.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "院落悬停指针")
		check(map.tooltip_text.contains("弟子居") and map.tooltip_text.contains("升级"), "真实悬停摘要")
		var resource_point: Vector2 = Layout.point(Layout.RESOURCE_POINTS[&"forest"], map.size)
		motion.position = resource_point
		map._gui_input(motion)
		check(map.fixed_hover_kind == &"" and map.tooltip_text.contains("采集"), "资源悬停优先级")
		motion.position = Vector2(4, 4)
		map._gui_input(motion)
		check(map.tooltip_text.is_empty() and map.mouse_default_cursor_shape == Control.CURSOR_ARROW, "空白区域无误导指针")
		map.mouse_exited.emit()
		check(map.fixed_hover_kind == &"" and map.tooltip_text.is_empty(), "离开地图清理")
	check(state.export_save_data() == snapshot, "表现查询不可改写存档数据")
	map.queue_free()
	await process_frame
	print("%s: fixed site paid construction, parallel/upgrade progress, completion cleanup, hover/resource priority, two sizes, unchanged data (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
