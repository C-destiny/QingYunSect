extends RefCounted

const Layout = preload("res://scripts/world/fixed_sect_layout.gd")

# 只从真实实例读取表现数据；并行施工展示最早完成的一项。
static func describe(state: Node, kind: StringName) -> Dictionary:
	if kind == &"hall":
		return {"label": "Lv.%d" % state.sect_level, "tooltip": "主殿 · Lv.%d\n点击查看宗门发展与晋升" % state.sect_level, "job": {}}
	var members := Layout.members(state, kind)
	var jobs: Array[Dictionary] = []
	var completed := 0
	var highest_level := 0
	for building: Dictionary in members:
		if building["completed"]:
			completed += 1
			highest_level = maxi(highest_level, int(building["level"]))
		var upgrading := bool(building.get("upgrading", false))
		if not building["completed"] or upgrading:
			var remaining := float(building.get("upgrade_remaining", 0.0)) if upgrading else float(building["remaining"])
			var duration := float(building.get("upgrade_time", 1.0)) if upgrading else float(building["build_time"])
			jobs.append({"id": int(building["instance_id"]), "name": "升级" if upgrading else "施工", "remaining": remaining,
				"progress": clampf(1.0 - remaining / maxf(duration, 0.001), 0.0, 1.0)})
	jobs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(a["remaining"], b["remaining"]):
			return a["remaining"] < b["remaining"]
		return a["id"] < b["id"])
	var label := "待建"
	if completed > 0:
		label = "Lv.%d" % highest_level if members.size() == 1 else "%d座" % members.size()
	elif not jobs.is_empty():
		label = "施工"
	var summary := "尚未建设"
	if not members.is_empty():
		summary = "%d座 · 尚无完工建筑" % members.size() if completed == 0 else "%d座 · 已完工%d座 · 最高Lv.%d" % [members.size(), completed, highest_level]
	var tooltip := "%s · %s" % [Layout.SITES[kind]["name"], summary]
	if not jobs.is_empty():
		tooltip += "\n%s剩余%.1f秒 · 共%d项进行中" % [jobs[0]["name"], jobs[0]["remaining"], jobs.size()]
	tooltip += "\n点击建设或查看各建筑实例"
	return {"label": label, "tooltip": tooltip, "job": {} if jobs.is_empty() else jobs[0], "job_count": jobs.size()}

static func progress_rect(map: Control, kind: StringName) -> Rect2:
	var plaque: Rect2 = map.FixedView.plaque_rect(map, kind)
	return Rect2(plaque.position.x - 34, plaque.end.y + 5, 112, 33)

static func draw_progress(map: Control, kind: StringName, description: Dictionary) -> void:
	var job: Dictionary = description["job"]
	if job.is_empty():
		return
	var rect := progress_rect(map, kind)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.15, 0.17, 0.94)
	style.border_color = Color("a38b59")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	map.draw_style_box(style, rect)
	var suffix := " · %d项" % description["job_count"] if description["job_count"] > 1 else ""
	map.draw_string(ThemeDB.fallback_font, rect.position + Vector2(5, 16), "%s %.0f秒%s" % [job["name"], ceilf(job["remaining"]), suffix], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10, 12, Color("f6e7ba"))
	var bar := Rect2(rect.position + Vector2(5, 23), Vector2(rect.size.x - 10, 4))
	map.draw_rect(bar, Color("344b47"))
	map.draw_rect(Rect2(bar.position, Vector2(bar.size.x * job["progress"], bar.size.y)), Color("8ac4b0") if job["name"] == "升级" else Color("d6b56b"))
