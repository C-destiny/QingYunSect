extends Control

@onready var wood_label: Label = %Wood
@onready var spirit_stone_label: Label = %SpiritStone
@onready var food_label: Label = %Food
@onready var disciples_label: Label = %Disciples
@onready var sect_map: Control = %SectMap
@onready var selection_name: Label = %SelectionName
@onready var selection_description: Label = %SelectionDescription
@onready var assignment_status: Label = %AssignmentStatus
@onready var production_status: Label = %ProductionStatus
@onready var assign_button: Button = %AssignButton
@onready var unassign_button: Button = %UnassignButton
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var save_status: Label = %SaveStatus
@onready var autosave_timer: Timer = %AutosaveTimer
@onready var placement_status: Label = %PlacementStatus
@onready var cancel_build_button: Button = %CancelBuildButton
@onready var recruit_button: Button = %RecruitButton
@onready var recruitment_status: Label = %RecruitmentStatus

var selected_resource: Dictionary = {}
var selected_building: StringName = &""
var build_buttons: Dictionary = {}


func _ready() -> void:
	GameState.resources_changed.connect(_refresh_resources)
	GameState.assignments_changed.connect(_refresh_assignment)
	GameState.buildings_changed.connect(_refresh_buildings)
	GameState.recruitment_changed.connect(_refresh_recruitment)
	sect_map.resource_selected.connect(_on_resource_selected)
	sect_map.placement_requested.connect(_on_placement_requested)
	assign_button.pressed.connect(_assign_disciple)
	unassign_button.pressed.connect(_unassign_disciple)
	save_button.pressed.connect(_save_game)
	load_button.pressed.connect(_load_game)
	autosave_timer.timeout.connect(_autosave)
	SaveManager.save_completed.connect(_on_save_completed)
	SaveManager.load_completed.connect(_on_load_completed)
	build_buttons = {
		&"disciple_quarters": %DiscipleQuartersButton,
		&"lumber_yard": %LumberYardButton,
		&"spirit_mine": %SpiritMineButton,
		&"spirit_field": %SpiritFieldButton,
		&"training_ground": %TrainingGroundButton,
	}
	for building_id: StringName in build_buttons:
		build_buttons[building_id].pressed.connect(_start_building_placement.bind(building_id))
	cancel_build_button.pressed.connect(_cancel_building_placement)
	recruit_button.pressed.connect(_start_recruitment)
	if SaveManager.has_save():
		SaveManager.load_game()
	_refresh_resources()
	_refresh_assignment()
	_refresh_buildings()
	_refresh_recruitment()
	print("青云宗 V0.1：建筑系统启动成功")


func _process(delta: float) -> void:
	for resource_data: Dictionary in sect_map.resource_nodes:
		GameState.process_production(
			resource_data["site_id"],
			resource_data["resource_id"],
			resource_data["rate"],
			delta
		)
	GameState.process_construction(delta)
	if GameState.process_recruitment(delta):
		SaveManager.save_game()


func _refresh_resources() -> void:
	wood_label.text = "木材  %d" % GameState.get_resource_amount("wood")
	spirit_stone_label.text = "灵石  %d" % GameState.get_resource_amount("spirit_stone")
	food_label.text = "灵谷  %d" % GameState.get_resource_amount("food")
	disciples_label.text = "弟子  %d/%d · 上限 %d" % [
		GameState.assigned_disciples,
		GameState.total_disciples,
		GameState.get_disciple_capacity(),
	]
	if not build_buttons.is_empty():
		for building_id: StringName in build_buttons:
			var definition := BuildingCatalog.get_data(building_id)
			build_buttons[building_id].disabled = not GameState.can_afford(definition["cost"])


func _on_resource_selected(resource_data: Dictionary) -> void:
	selected_resource = resource_data
	selection_name.text = str(resource_data["name"])
	selection_description.text = "%s\n\n储量：%d" % [
		resource_data["description"],
		resource_data["reserve"],
	]
	_refresh_assignment()


func _assign_disciple() -> void:
	if selected_resource.is_empty():
		return
	GameState.assign_disciple(selected_resource["site_id"])


func _unassign_disciple() -> void:
	if selected_resource.is_empty():
		return
	GameState.unassign_disciple(selected_resource["site_id"])


func _refresh_assignment() -> void:
	_refresh_resources()
	var has_selection := not selected_resource.is_empty()
	assign_button.disabled = not has_selection or GameState.get_idle_disciples() <= 0
	unassign_button.disabled = not has_selection
	if not has_selection:
		assignment_status.text = "已分配 0 人 · 空闲 %d 人" % GameState.get_idle_disciples()
		production_status.text = "选择资源点后安排弟子"
		return
	var workers := GameState.get_assignment(selected_resource["site_id"])
	unassign_button.disabled = workers <= 0
	var multiplier := GameState.get_production_multiplier(selected_resource["resource_id"])
	var total_rate := float(selected_resource["rate"]) * multiplier * float(workers)
	assignment_status.text = "已分配 %d 人 · 空闲 %d 人" % [workers, GameState.get_idle_disciples()]
	production_status.text = "%s +%.1f/分钟 · 建筑加成 +%.0f%%" % [
		selected_resource["resource_name"],
		total_rate,
		(multiplier - 1.0) * 100.0,
	]


func _save_game() -> void:
	SaveManager.save_game()


func _load_game() -> void:
	SaveManager.load_game()


func _autosave() -> void:
	if GameState.assigned_disciples > 0 or GameState.is_recruiting():
		SaveManager.save_game()


func _on_save_completed(success: bool, message: String) -> void:
	save_status.text = message
	save_status.modulate = Color(0.55, 0.85, 0.62) if success else Color(0.9, 0.45, 0.4)
	load_button.disabled = not SaveManager.has_save()


func _on_load_completed(success: bool, message: String) -> void:
	save_status.text = message
	save_status.modulate = Color(0.55, 0.85, 0.62) if success else Color(0.9, 0.45, 0.4)
	load_button.disabled = not SaveManager.has_save()
	if success:
		_refresh_resources()
		_refresh_assignment()
		_refresh_buildings()
		_refresh_recruitment()


func _start_recruitment() -> void:
	if GameState.start_recruitment():
		recruitment_status.text = "正在招募普通弟子……"
		SaveManager.save_game()
	else:
		_refresh_recruitment()


func _refresh_recruitment() -> void:
	recruit_button.disabled = not GameState.can_recruit_disciple()
	if GameState.is_recruiting():
		recruitment_status.text = "招募中：剩余 %.1f 秒" % GameState.recruitment_remaining
		return
	if GameState.total_disciples >= GameState.get_disciple_capacity():
		recruitment_status.text = "弟子人数已达上限，请先建造弟子居"
		return
	if not GameState.can_afford(GameState.RECRUIT_COST):
		recruitment_status.text = "资源不足：需要灵石25、灵谷20"
		return
	recruitment_status.text = "可招募普通弟子 · 灵石25 灵谷20"


func _start_building_placement(building_id: StringName) -> void:
	var definition := BuildingCatalog.get_data(building_id)
	if not GameState.can_afford(definition["cost"]):
		placement_status.text = "资源不足：%s" % BuildingCatalog.get_cost_text(building_id)
		return
	selected_building = building_id
	sect_map.start_placement(building_id)
	cancel_build_button.disabled = false
	placement_status.text = "放置 %s · 点击绿色格子" % definition["name"]


func _cancel_building_placement() -> void:
	selected_building = &""
	sect_map.cancel_placement()
	cancel_build_button.disabled = true
	placement_status.text = "选择建筑开始建造"


func _on_placement_requested(building_id: StringName, cell: Vector2i) -> void:
	if GameState.start_construction(building_id, cell):
		var definition := BuildingCatalog.get_data(building_id)
		placement_status.text = "%s开始施工（%.0f秒）" % [definition["name"], definition["build_time"]]
		selected_building = &""
		sect_map.cancel_placement()
		cancel_build_button.disabled = true
		SaveManager.save_game()
	else:
		placement_status.text = "无法在这里建造"


func _refresh_buildings() -> void:
	sect_map.queue_redraw()
	_refresh_assignment()
	_refresh_recruitment()
	var constructing := 0
	for building: Dictionary in GameState.buildings:
		if not bool(building["completed"]):
			constructing += 1
	if constructing > 0 and selected_building == &"":
		placement_status.text = "施工中：%d 座建筑" % constructing

