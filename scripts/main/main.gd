extends Control

@onready var wood_label: Label = %Wood
@onready var spirit_stone_label: Label = %SpiritStone
@onready var food_label: Label = %Food
@onready var disciples_label: Label = %Disciples
@onready var sect_map: Control = %SectMap
@onready var selection_name: Label = %SelectionName
@onready var selection_description: Label = %SelectionDescription


func _ready() -> void:
	GameState.resources_changed.connect(_refresh_resources)
	sect_map.resource_selected.connect(_on_resource_selected)
	_refresh_resources()
	print("青云宗 V0.1：宗门地图与资源状态启动成功")


func _refresh_resources() -> void:
	wood_label.text = "木材  %d" % GameState.get_resource_amount("wood")
	spirit_stone_label.text = "灵石  %d" % GameState.get_resource_amount("spirit_stone")
	food_label.text = "灵谷  %d" % GameState.get_resource_amount("food")
	disciples_label.text = "弟子  %d/%d" % [GameState.assigned_disciples, GameState.total_disciples]


func _on_resource_selected(resource_data: Dictionary) -> void:
	selection_name.text = str(resource_data["name"])
	selection_description.text = "%s\n\n储量：%d\n产出：%s" % [
		resource_data["description"],
		resource_data["reserve"],
		resource_data["yield_text"],
	]

