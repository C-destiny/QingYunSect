extends VBoxContainer
var state: Node
var manager: Node
var selected: Callable
var summary := Label.new()
var make_button := Button.new()
var use_button := Button.new()
var feedback := Label.new()
func setup(game: Node, save: Node, selection: Callable) -> void:
	state = game
	manager = save
	selected = selection
	name = "MedicinePanel"
	for control: Control in [summary, make_button, use_button, feedback]:
		add_child(control)
	for label: Label in [summary, feedback]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	make_button.text = "制作修炼丹：20灵谷 + 8灵石 / 60秒"
	use_button.text = "给选中弟子服用：修为 +5"
	make_button.pressed.connect(func(): perform(false))
	use_button.pressed.connect(func(): perform(true))
	refresh()
func _process(_delta: float) -> void:
	if state != null:
		refresh()
func refresh() -> void:
	summary.text = "修炼丹（试制） · 库存 %d/20\n%s\n需已建演武场；突破仍只消耗修为。" % [state.medicine["stock"], "制作剩余 %.0f 秒" % ceil(float(state.medicine["remaining"])) if float(state.medicine["remaining"]) > 0 else "当前未制作"]
	make_button.disabled = not state.can_start_medicine()
	use_button.disabled = not state.can_use_medicine(int(selected.call()))
func perform(use: bool) -> void:
	var before: Dictionary = state.export_save_data()
	var changed: bool = state.use_medicine(int(selected.call())) if use else state.start_medicine()
	if not changed:
		feedback.text = "条件不足：检查库存、资源、演武场及弟子活动。"
		return
	if not manager.save_game():
		state.import_save_data(before)
		feedback.text = "保存失败，操作已撤回，可重试"
	else:
		feedback.text = "已服用并保存" if use else "已开始制作并保存"
	refresh()