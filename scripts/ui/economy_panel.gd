extends VBoxContainer

const Economy = preload("res://scripts/core/sect_economy.gd")
signal guidance_requested(step: Dictionary)

var flow: Label
var food_status: Label
var next_step: Label
var action_button: Button
var current_step: Dictionary = {}

func _ready() -> void:
	name = "EconomyPanel"
	add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = "宗门资源与发展"
	title.add_theme_font_size_override("font_size", 21)
	add_child(title)
	flow = _label(16)
	food_status = _label(16)
	next_step = _label(17)
	action_button = Button.new()
	action_button.custom_minimum_size.y = 42
	action_button.pressed.connect(func() -> void: guidance_requested.emit(current_step))
	add_child(action_button)
	var state := get_node("/root/GameState")
	for signal_name: StringName in [&"resources_changed", &"assignments_changed", &"buildings_changed", &"disciples_changed", &"training_changed", &"recruitment_changed", &"equipment_changed", &"sustenance_changed", &"sect_progress_changed"]:
		state.connect(signal_name, refresh)
	refresh()

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label

func refresh() -> void:
	var state := get_node("/root/GameState")
	var report := Economy.overview(state)
	var lines := PackedStringArray()
	for id: String in Economy.RESOURCE_INFO:
		var row: Dictionary = report["rows"][id]
		lines.append("%s %d · 产出%.1f / 消耗%.1f / 净%+.1f 每分" % [row["name"], row["amount"], row["income"], row["consumption"], row["net"]])
	flow.text = "\n".join(lines)
	var food: Dictionary = report["rows"]["food"]
	if report["hungry"]:
		food_status.text = "缺粮：生产效率50%。" + ("粮食正增长，继续生产可恢复。" if float(food["net"]) > 0.0 else "请调派弟子种粮。")
	elif float(food["minutes"]) >= 0.0:
		food_status.text = "%s按当前收支，粮食约可维持%.1f分钟。" % ["口粮预警 · " if food["status"] == "warning" else "", food["minutes"]]
	else:
		food_status.text = "口粮净增长，当前岗位可维持。" if float(food["net"]) > 0.0 else "口粮收支持平。"
	food_status.add_theme_color_override("font_color", Color("efc574") if report["hungry"] or food["status"] == "warning" else Color("a6c7b1"))
	current_step = Economy.guidance(state)
	next_step.text = "建议下一步：%s\n%s" % [current_step["title"], current_step["body"]]
	var captions := {"site": "查看生产岗位", "build": "选择建造位置", "build_menu": "查看建设", "disciples": "查看弟子与招募", "growth": "查看养成与装备"}
	action_button.text = captions.get(current_step["action"], "查看详情")
