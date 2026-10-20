extends RefCounted

# 局部庭院渲染配置，不包含占地、建筑身份或持久化字段。
static func make_plan(hall: Vector2, wing: Vector2, has_wing: bool) -> Dictionary:
	var plan := {"hall": hall, "hall_pad": Rect2(hall + Vector2(-170, -110), Vector2(340, 184.47)),
		"wing_pad": Rect2(), "road": PackedVector2Array(), "stairs": Rect2(),
		"foreground": [{"foot": hall + Vector2(126, 24), "width": 184.0, "target": "hall"}]}
	if not has_wing:
		return plan
	plan["wing_pad"] = Rect2(wing + Vector2(-100, -58), Vector2(200, 130.12))
	# 绕过台地间的山石，沿前庭下方汇入主阶，不用直线悬空跨过园林凹地。
	var start := wing + Vector2(-48, 45)
	var left_landing := hall + Vector2(-230, 190)
	var forecourt := hall + Vector2(-30, 310)
	var main_landing := hall + Vector2(220, 120)
	var entrance := hall + Vector2(100, 60)
	plan["road"] = PackedVector2Array([start, left_landing, forecourt, main_landing, entrance])
	# 主阶沿用已画好的地形，新增小踏步只贴在侧翼台基前，不悬空跨越凹地。
	plan["stairs"] = Rect2(wing + Vector2(-100, 4), Vector2(120, 67.4))
	plan["foreground"].append({"foot": wing + Vector2(27, 30), "width": 128.0, "target": "wing"})
	return plan

static func segment_quad(start: Vector2, finish: Vector2, width: float) -> PackedVector2Array:
	var across := (finish - start).normalized().orthogonal() * width * 0.5
	return PackedVector2Array([start + across, finish + across, finish - across, start - across])
