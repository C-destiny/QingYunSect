extends Node

signal resources_changed
signal assignments_changed
signal buildings_changed

const RESOURCE_IDS := [&"wood", &"spirit_stone", &"food"]

var resources: Dictionary = {
	"wood": 120,
	"spirit_stone": 80,
	"food": 150,
}

var total_disciples: int = 3
var assigned_disciples: int = 0
var assignments: Dictionary = {}
var production_progress: Dictionary = {}
var buildings: Array[Dictionary] = []
var next_building_id: int = 1


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


func get_idle_disciples() -> int:
	return total_disciples - assigned_disciples


func get_assignment(site_id: StringName) -> int:
	return int(assignments.get(site_id, 0))


func assign_disciple(site_id: StringName) -> bool:
	if get_idle_disciples() <= 0:
		return false
	assignments[site_id] = get_assignment(site_id) + 1
	assigned_disciples += 1
	assignments_changed.emit()
	return true


func unassign_disciple(site_id: StringName) -> bool:
	var current := get_assignment(site_id)
	if current <= 0:
		return false
	assignments[site_id] = current - 1
	assigned_disciples -= 1
	assignments_changed.emit()
	return true


func process_production(site_id: StringName, resource_id: StringName, rate_per_minute: float, delta: float) -> int:
	var workers := get_assignment(site_id)
	if workers <= 0 or rate_per_minute <= 0.0:
		return 0
	var progress := float(production_progress.get(site_id, 0.0))
	progress += rate_per_minute * float(workers) * delta / 60.0
	var completed := floori(progress)
	production_progress[site_id] = progress - float(completed)
	if completed > 0:
		add_resource(resource_id, completed)
	return completed


func is_cell_occupied(cell: Vector2i) -> bool:
	if cell == Vector2i(4, 3):
		return true
	for building: Dictionary in buildings:
		if Vector2i(int(building["cell_x"]), int(building["cell_y"])) == cell:
			return true
	return false


func start_construction(building_type: StringName, cell: Vector2i) -> bool:
	var definition := BuildingCatalog.get_data(building_type)
	if definition.is_empty() or is_cell_occupied(cell):
		return false
	if not spend_resources(definition["cost"]):
		return false
	buildings.append({
		"instance_id": next_building_id,
		"type": String(building_type),
		"cell_x": cell.x,
		"cell_y": cell.y,
		"remaining": float(definition["build_time"]),
		"build_time": float(definition["build_time"]),
		"completed": false,
	})
	next_building_id += 1
	buildings_changed.emit()
	return true


func process_construction(delta: float) -> void:
	var changed := false
	for building: Dictionary in buildings:
		if bool(building["completed"]):
			continue
		building["remaining"] = maxf(0.0, float(building["remaining"]) - delta)
		if is_zero_approx(float(building["remaining"])):
			building["completed"] = true
		changed = true
	if changed:
		buildings_changed.emit()


func export_save_data() -> Dictionary:
	return {
		"resources": resources.duplicate(true),
		"total_disciples": total_disciples,
		"assignments": assignments.duplicate(true),
		"production_progress": production_progress.duplicate(true),
		"buildings": buildings.duplicate(true),
		"next_building_id": next_building_id,
	}


func import_save_data(data: Dictionary) -> bool:
	if not data.has("resources") or not data.has("assignments"):
		return false
	var loaded_resources: Dictionary = data["resources"]
	for resource_id: StringName in RESOURCE_IDS:
		var key := String(resource_id)
		if not loaded_resources.has(key):
			return false
		resources[key] = maxi(0, int(loaded_resources[key]))
	total_disciples = maxi(0, int(data.get("total_disciples", 3)))
	assignments.clear()
	assigned_disciples = 0
	var loaded_assignments: Dictionary = data["assignments"]
	for site_id: Variant in loaded_assignments:
		var worker_count := maxi(0, int(loaded_assignments[site_id]))
		assignments[String(site_id)] = worker_count
		assigned_disciples += worker_count
	if assigned_disciples > total_disciples:
		return false
	production_progress.clear()
	var loaded_progress: Dictionary = data.get("production_progress", {})
	for site_id: Variant in loaded_progress:
		production_progress[String(site_id)] = clampf(float(loaded_progress[site_id]), 0.0, 0.999999)
	buildings.clear()
	var loaded_buildings: Array = data.get("buildings", [])
	for raw_building: Variant in loaded_buildings:
		if not raw_building is Dictionary:
			return false
		var building: Dictionary = raw_building
		if BuildingCatalog.get_data(StringName(building.get("type", ""))).is_empty():
			return false
		buildings.append(building.duplicate(true))
	next_building_id = maxi(1, int(data.get("next_building_id", buildings.size() + 1)))
	resources_changed.emit()
	assignments_changed.emit()
	buildings_changed.emit()
	return true

