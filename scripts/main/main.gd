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

var selected_resource: Dictionary = {}


func _ready() -> void:
	GameState.resources_changed.connect(_refresh_resources)
	GameState.assignments_changed.connect(_refresh_assignment)
	sect_map.resource_selected.connect(_on_resource_selected)
	assign_button.pressed.connect(_assign_disciple)
	unassign_button.pressed.connect(_unassign_disciple)
	_refresh_resources()
	_refresh_assignment()
	print("青云宗 V0.1：弟子分配与自动采集启动成功")


func _process(delta: float) -> void:
	for resource_data: Dictionary in sect_map.resource_nodes:
		GameState.process_production(
			resource_data["site_id"],
			resource_data["resource_id"],
			resource_data["rate"],
			delta
		)


func _refresh_resources() -> void:
	wood_label.text = "木材  %d" % GameState.get_resource_amount("wood")
	spirit_stone_label.text = "灵石  %d" % GameState.get_resource_amount("spirit_stone")
	food_label.text = "灵谷  %d" % GameState.get_resource_amount("food")
	disciples_label.text = "弟子  %d/%d" % [GameState.assigned_disciples, GameState.total_disciples]


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
	var total_rate := float(selected_resource["rate"]) * float(workers)
	assignment_status.text = "已分配 %d 人 · 空闲 %d 人" % [workers, GameState.get_idle_disciples()]
	production_status.text = "%s +%.0f/分钟" % [selected_resource["resource_name"], total_rate]

