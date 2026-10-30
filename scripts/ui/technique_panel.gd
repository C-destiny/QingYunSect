extends VBoxContainer
const Data = preload("res://scripts/data/technique_catalog.gd")
var state: Node
var manager: Node
var selected: Callable
var summary := Label.new()
var feedback := Label.new()
var learns: Dictionary = {}
var equips: Dictionary = {}
var stop := Button.new()
func setup(game: Node, saves: Node, selection: Callable) -> void:
	name = "TechniquePanel"
	state = game
	manager = saves
	selected = selection
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(summary)
	for id: String in Data.ITEMS:
		var learn := Button.new()
		var equip := Button.new()
		learn.text = "学习%s：%d灵石" % [Data.ITEMS[id]["name"],Data.COST]
		equip.text = "运转%s：%s" % [Data.ITEMS[id]["name"],Data.ITEMS[id]["effect"]]
		learn.pressed.connect(perform.bind(id,true))
		equip.pressed.connect(perform.bind(id,false))
		add_child(learn)
		add_child(equip)
		learns[id] = learn
		equips[id] = equip
	stop.text = "停止运转功法"
	stop.pressed.connect(perform.bind("",false))
	add_child(stop)
	add_child(feedback)
	refresh()
func _process(_delta: float) -> void:
	if state != null:
		refresh()
func refresh() -> void:
	var id := int(selected.call())
	var record: Dictionary = state.get_technique_record(id)
	summary.text = "永久功法 · 同时运转1门\n需已建藏经阁，学习后手动运转。\n当前：%s" % Data.ITEMS.get(record["active"],{"name":"未运转"})["name"]
	for key: String in Data.ITEMS:
		learns[key].disabled = not state.can_learn_technique(id,key)
		equips[key].disabled = not state.can_manage_technique(id) or key not in record["learned"] or record["active"] == key
	stop.disabled = not state.can_manage_technique(id) or record["active"] == ""
func perform(id: String, learning: bool) -> void:
	var before: Dictionary = state.export_save_data()
	var disciple_id := int(selected.call())
	var changed: bool = state.learn_technique(disciple_id,id) if learning else state.select_technique(disciple_id,id)
	if not changed:
		feedback.text = "条件不足，请检查藏经阁、灵石、学习状态及弟子活动。"
		return
	if not manager.save_game():
		state.import_save_data(before)
		feedback.text = "保存失败，功法操作已撤回"
	else:
		feedback.text = "功法操作已保存"
	refresh()