extends Node

signal resources_changed

const RESOURCE_IDS := [&"wood", &"spirit_stone", &"food"]

var resources: Dictionary = {
	"wood": 120,
	"spirit_stone": 80,
	"food": 150,
}

var total_disciples: int = 3
var assigned_disciples: int = 0


func get_resource_amount(resource_id: StringName) -> int:
	return int(resources.get(resource_id, 0))


func can_afford(cost: Dictionary) -> bool:
	for resource_id: Variant in cost:
		if get_resource_amount(StringName(resource_id)) < int(cost[resource_id]):
			return false
	return true


func spend_resources(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for resource_id: Variant in cost:
		resources[resource_id] = get_resource_amount(StringName(resource_id)) - int(cost[resource_id])
	resources_changed.emit()
	return true


func add_resource(resource_id: StringName, amount: int) -> void:
	if resource_id not in RESOURCE_IDS or amount <= 0:
		return
	resources[resource_id] = get_resource_amount(resource_id) + amount
	resources_changed.emit()

