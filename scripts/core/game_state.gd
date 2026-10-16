extends Node

const BattleCatalogData = preload("res://scripts/data/battle_catalog.gd")

signal resources_changed
signal assignments_changed
signal buildings_changed
signal recruitment_changed
signal sustenance_changed
signal training_changed
signal disciples_changed
signal sect_progress_changed
signal battle_changed

const RESOURCE_IDS := [&"wood", &"spirit_stone", &"food"]
const BASE_DISCIPLE_CAPACITY := 3
const RECRUIT_COST := {"spirit_stone": 25, "food": 20}
const RECRUIT_TIME := 5.0
const FOOD_CONSUMPTION_PER_DISCIPLE := 1.0
const HUNGRY_PRODUCTION_MULTIPLIER := 0.5
const REALM_MAX_LEVEL := 9
const REALM_GATHERING_BONUS_PER_LEVEL := 0.05
const DISCIPLE_SURNAMES := ["沈", "顾", "陆", "苏", "林", "叶", "楚", "白", "宁", "江"]
const DISCIPLE_GIVEN_NAMES := ["青竹", "云舟", "明溪", "知远", "怀瑾", "清和", "景行", "若谷", "星河", "长风"]
const MAX_SECT_LEVEL := 5
const SECT_LEVEL_REQUIREMENTS := [0, 100, 250, 500, 900]
const SECT_PRODUCTION_BONUS_PER_LEVEL := 0.05
const BATTLE_ROUND_TIME := BattleCatalogData.ROUND_TIME
const BATTLE_RESTART_DELAY := BattleCatalogData.RESTART_DELAY
const BATTLE_LOG_LIMIT := 30

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
var recruitment_remaining: float = 0.0
var food_consumption_progress: float = 0.0
var training_disciples: int = 0
var cultivation_points: float = 0.0
var disciples: Array[Dictionary] = []
var next_disciple_id: int = 1
var sect_level: int = 1
var battle_party: Array[int] = []
var selected_battle_stage: int = 1
var highest_unlocked_stage: int = 1
var highest_cleared_stage: int = 0
var battle_victories: int = 0
var battle_encounter_sequence: int = 0
var active_battle_encounter_id: int = 0
var last_settled_battle_encounter_id: int = 0
var battle_running: bool = false
var auto_battle_enabled: bool = false
var battle_player_hp: float = 0.0
var battle_player_max_hp: float = 0.0
var battle_enemy_hp: float = 0.0
var battle_enemy_max_hp: float = 0.0
var battle_round_progress: float = 0.0
var battle_restart_cooldown: float = 0.0
var battle_message: String = "请先编成队伍并选择关卡"
var battle_round_number: int = 0
var battle_log: Array[String] = []
var last_battle_result: Dictionary = {}


func _append_battle_log(message: String) -> void:
	battle_log.append(message)
	while battle_log.size() > BATTLE_LOG_LIMIT:
		battle_log.pop_front()


func _ready() -> void:
	_ensure_disciple_records()


func _ensure_disciple_records() -> void:
	if not disciples.is_empty() or total_disciples <= 0:
		return
	var desired_total := total_disciples
	for index: int in range(desired_total):
		_create_disciple()
	_sync_aggregate_state_from_disciples()


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
	_ensure_disciple_records()
	return total_disciples - assigned_disciples


func _create_disciple() -> Dictionary:
	var name_index := next_disciple_id - 1
	var disciple := {
		"id": next_disciple_id,
		"name": DISCIPLE_SURNAMES[name_index % DISCIPLE_SURNAMES.size()] + DISCIPLE_GIVEN_NAMES[int(name_index / DISCIPLE_SURNAMES.size()) % DISCIPLE_GIVEN_NAMES.size()],
		"realm_level": 1,
		"cultivation": 0.0,
		"job": "idle",
	}
	next_disciple_id += 1
	disciples.append(disciple)
	total_disciples = disciples.size()
	return disciple


func get_disciple(disciple_id: int) -> Dictionary:
	_ensure_disciple_records()
	for disciple: Dictionary in disciples:
		if int(disciple.get("id", 0)) == disciple_id:
			return disciple
	return {}


func get_realm_name(realm_level: int) -> String:
	const NUMERALS := ["一", "二", "三", "四", "五", "六", "七", "八", "九"]
	return "炼气%s层" % NUMERALS[clampi(realm_level, 1, REALM_MAX_LEVEL) - 1]


func get_breakthrough_requirement(realm_level: int) -> float:
	if realm_level >= REALM_MAX_LEVEL:
		return 0.0
	return float(realm_level * 10)


func can_breakthrough(disciple_id: int) -> bool:
	var disciple := get_disciple(disciple_id)
	if disciple.is_empty():
		return false
	var realm_level := int(disciple.get("realm_level", 1))
	return realm_level < REALM_MAX_LEVEL and float(disciple.get("cultivation", 0.0)) >= get_breakthrough_requirement(realm_level)


func breakthrough_disciple(disciple_id: int) -> bool:
	if not can_breakthrough(disciple_id):
		return false
	var disciple := get_disciple(disciple_id)
	var realm_level := int(disciple["realm_level"])
	disciple["cultivation"] = float(disciple["cultivation"]) - get_breakthrough_requirement(realm_level)
	disciple["realm_level"] = realm_level + 1
	disciples_changed.emit()
	assignments_changed.emit()
	return true


func get_disciple_job_text(job: StringName) -> String:
	match job:
		&"forest": return "青松林伐木"
		&"mine": return "灵石矿采掘"
		&"field": return "灵田耕作"
		&"training": return "演武场修炼"
		&"combat": return "外山战斗"
		_: return "空闲"


func can_set_disciple_job(disciple_id: int, job: StringName) -> bool:
	if job not in [&"idle", &"forest", &"mine", &"field", &"training", &"combat"]:
		return false
	var disciple := get_disciple(disciple_id)
	if disciple.is_empty():
		return false
	var current_job := StringName(disciple.get("job", "idle"))
	if current_job == job:
		return true
	if job == &"training" and training_disciples >= get_training_capacity():
		return false
	if job == &"combat" and current_job != &"combat" and battle_party.size() >= BattleCatalogData.MAX_PARTY_SIZE:
		return false
	return true


func set_disciple_job(disciple_id: int, job: StringName) -> bool:
	if not can_set_disciple_job(disciple_id, job):
		return false
	var disciple := get_disciple(disciple_id)
	var current_job := StringName(disciple.get("job", "idle"))
	if current_job == job:
		return true
	var party_changed := current_job == &"combat" or job == &"combat"
	if current_job == &"combat":
		battle_party.erase(disciple_id)
	if job == &"combat" and disciple_id not in battle_party:
		battle_party.append(disciple_id)
	disciple["job"] = String(job)
	if party_changed and (battle_running or auto_battle_enabled):
		stop_auto_battle("队伍发生变化，战斗已停止")
	_sync_aggregate_state_from_disciples()
	assignments_changed.emit()
	training_changed.emit()
	disciples_changed.emit()
	battle_changed.emit()
	return true


func get_combat_job_disciple_ids() -> Array[int]:
	var result: Array[int] = []
	for disciple: Dictionary in disciples:
		if StringName(disciple.get("job", "idle")) == &"combat":
			result.append(int(disciple.get("id", 0)))
	result.sort()
	return result


func is_battle_party_consistent() -> bool:
	if battle_party.size() > BattleCatalogData.MAX_PARTY_SIZE:
		return false
	var party_ids := battle_party.duplicate()
	party_ids.sort()
	for index: int in range(1, party_ids.size()):
		if party_ids[index] == party_ids[index - 1]:
			return false
	for disciple_id: int in party_ids:
		var disciple := get_disciple(disciple_id)
		if disciple.is_empty() or StringName(disciple.get("job", "idle")) != &"combat":
			return false
	return party_ids == get_combat_job_disciple_ids()


func get_site_workforce_power(site_id: StringName) -> float:
	_ensure_disciple_records()
	var power := 0.0
	for disciple: Dictionary in disciples:
		if StringName(disciple.get("job", "idle")) != site_id:
			continue
		var realm_level := int(disciple.get("realm_level", 1))
		power += 1.0 + float(realm_level - 1) * REALM_GATHERING_BONUS_PER_LEVEL
	return power


func _sync_aggregate_state_from_disciples() -> void:
	assignments.clear()
	training_disciples = 0
	assigned_disciples = 0
	total_disciples = disciples.size()
	for disciple: Dictionary in disciples:
		var job := StringName(disciple.get("job", "idle"))
		if job in [&"forest", &"mine", &"field"]:
			assignments[String(job)] = int(assignments.get(String(job), 0)) + 1
			assigned_disciples += 1
		elif job == &"training":
			training_disciples += 1
			assigned_disciples += 1
		elif job == &"combat":
			assigned_disciples += 1


func get_disciple_battle_stats(disciple_id: int) -> Dictionary:
	var disciple := get_disciple(disciple_id)
	if disciple.is_empty():
		return {}
	return BattleCatalogData.get_disciple_stats(int(disciple.get("realm_level", 1)))


func get_battle_party_stats() -> Dictionary:
	var result := {"hp": 0.0, "attack": 0.0, "defense": 0.0}
	for disciple_id: int in battle_party:
		var stats := get_disciple_battle_stats(disciple_id)
		if stats.is_empty():
			continue
		result["hp"] += float(stats["hp"])
		result["attack"] += float(stats["attack"])
		result["defense"] += float(stats["defense"])
	return result


func select_battle_stage(stage_id: int) -> bool:
	if battle_running and stage_id != selected_battle_stage:
		return false
	if stage_id < 1 or stage_id > highest_unlocked_stage or BattleCatalogData.get_stage(stage_id).is_empty():
		return false
	selected_battle_stage = stage_id
	battle_changed.emit()
	return true


func get_battle_phase() -> StringName:
	if battle_running:
		return &"fighting"
	if auto_battle_enabled and battle_restart_cooldown > 0.0:
		return &"repeat_wait"
	return &"stopped"


func start_auto_battle(stage_id: int = selected_battle_stage) -> bool:
	if battle_running:
		return false
	if battle_party.is_empty() or not is_battle_party_consistent() or not select_battle_stage(stage_id):
		battle_message = "需要至少一名战斗弟子，且关卡必须已解锁"
		battle_changed.emit()
		return false
	var stage: Dictionary = BattleCatalogData.get_stage(stage_id)
	var party_stats := get_battle_party_stats()
	battle_player_max_hp = float(party_stats["hp"])
	battle_player_hp = battle_player_max_hp
	battle_enemy_max_hp = float(stage["hp"])
	battle_enemy_hp = battle_enemy_max_hp
	battle_round_progress = 0.0
	battle_round_number = 0
	battle_log.clear()
	battle_restart_cooldown = 0.0
	battle_encounter_sequence += 1
	active_battle_encounter_id = battle_encounter_sequence
	battle_running = true
	auto_battle_enabled = true
	battle_message = "正在挑战%s · %s" % [stage["name"], stage["enemy"]]
	_append_battle_log("开始挑战 %s（场次%d）" % [stage["name"], active_battle_encounter_id])
	battle_changed.emit()
	return true


func stop_auto_battle(message: String = "已停止自动战斗") -> void:
	if battle_running or auto_battle_enabled:
		_append_battle_log("战斗停止：%s" % message)
	battle_running = false
	auto_battle_enabled = false
	active_battle_encounter_id = 0
	battle_restart_cooldown = 0.0
	battle_message = message
	battle_changed.emit()


func process_battle(delta: float) -> bool:
	if delta <= 0.0:
		return false
	if (battle_running or auto_battle_enabled) and (battle_party.is_empty() or not is_battle_party_consistent()):
		stop_auto_battle("战斗队伍数据异常，自动战斗已停止")
		return false
	if not battle_running:
		if auto_battle_enabled and battle_restart_cooldown > 0.0:
			battle_restart_cooldown = maxf(0.0, battle_restart_cooldown - delta)
			if is_zero_approx(battle_restart_cooldown):
				start_auto_battle(selected_battle_stage)
		return false
	battle_round_progress += delta
	var won := false
	var changed := false
	while battle_running and battle_round_progress >= BATTLE_ROUND_TIME:
		changed = true
		battle_round_progress -= BATTLE_ROUND_TIME
		battle_round_number += 1
		var stage: Dictionary = BattleCatalogData.get_stage(selected_battle_stage)
		var party_stats := get_battle_party_stats()
		var party_damage := BattleCatalogData.calculate_damage(float(party_stats["attack"]), float(stage["defense"]))
		battle_enemy_hp = maxf(0.0, battle_enemy_hp - party_damage)
		_append_battle_log("第%d回合：我方造成%.0f伤害" % [battle_round_number, party_damage])
		if is_zero_approx(battle_enemy_hp):
			won = _complete_battle_victory(stage, active_battle_encounter_id)
			break
		var enemy_damage := BattleCatalogData.calculate_damage(float(stage["attack"]), float(party_stats["defense"]))
		battle_player_hp = maxf(0.0, battle_player_hp - enemy_damage)
		_append_battle_log("第%d回合：敌方造成%.0f伤害" % [battle_round_number, enemy_damage])
		if is_zero_approx(battle_player_hp):
			var failed_encounter_id := active_battle_encounter_id
			battle_running = false
			auto_battle_enabled = false
			active_battle_encounter_id = 0
			battle_message = "挑战失败，调整队伍或提升境界后再来"
			last_battle_result = {"result": "失败", "stage_id": selected_battle_stage, "encounter_id": failed_encounter_id, "reward_text": "无"}
			_append_battle_log("战斗失败：未获得奖励")
			break
		battle_message = "第%d轮 · 我方造成%.0f伤害，敌方造成%.0f伤害" % [
			battle_round_number, party_damage, enemy_damage,
		]
	if changed:
		battle_changed.emit()
	return won


func _complete_battle_victory(stage: Dictionary, encounter_id: int = -1) -> bool:
	if encounter_id < 0:
		encounter_id = active_battle_encounter_id
	if stage != BattleCatalogData.get_stage(selected_battle_stage):
		return false
	var rewards: Dictionary = stage.get("rewards", {})
	if not _can_grant_battle_rewards(encounter_id, rewards):
		return false
	last_settled_battle_encounter_id = encounter_id
	for resource_id: Variant in rewards:
		resources[String(resource_id)] = get_resource_amount(StringName(resource_id)) + int(rewards[resource_id])
	battle_victories += 1
	highest_cleared_stage = maxi(highest_cleared_stage, selected_battle_stage)
	highest_unlocked_stage = mini(BattleCatalogData.get_stage_count(), maxi(highest_unlocked_stage, selected_battle_stage + 1))
	battle_running = false
	active_battle_encounter_id = 0
	battle_restart_cooldown = BATTLE_RESTART_DELAY if auto_battle_enabled else 0.0
	battle_message = "胜利！%s已回流宗门，%.0f秒后再次挑战" % [BattleCatalogData.get_reward_text(selected_battle_stage), BATTLE_RESTART_DELAY]
	last_battle_result = {"result": "胜利", "stage_id": selected_battle_stage, "encounter_id": encounter_id, "reward_text": BattleCatalogData.get_reward_text(selected_battle_stage)}
	_append_battle_log("战斗胜利：获得%s" % BattleCatalogData.get_reward_text(selected_battle_stage))
	resources_changed.emit()
	return true


func _can_grant_battle_rewards(encounter_id: int, rewards: Dictionary) -> bool:
	if not battle_running or encounter_id <= 0 or encounter_id != active_battle_encounter_id:
		return false
	if encounter_id <= last_settled_battle_encounter_id:
		return false
	for resource_id: Variant in rewards:
		if StringName(resource_id) not in RESOURCE_IDS or int(rewards[resource_id]) < 0:
			return false
	return true


func get_disciple_capacity() -> int:
	var capacity := BASE_DISCIPLE_CAPACITY
	for building: Dictionary in buildings:
		if not bool(building.get("completed", false)):
			continue
		var definition := BuildingCatalog.get_data(StringName(building.get("type", "")))
		capacity += int(definition.get("disciple_capacity", 0)) * int(building.get("level", 1))
	return capacity


func is_recruiting() -> bool:
	return recruitment_remaining > 0.0


func can_recruit_disciple() -> bool:
	_ensure_disciple_records()
	return not is_recruiting() and total_disciples < get_disciple_capacity() and can_afford(RECRUIT_COST)


func start_recruitment() -> bool:
	if not can_recruit_disciple() or not spend_resources(RECRUIT_COST):
		return false
	recruitment_remaining = RECRUIT_TIME
	recruitment_changed.emit()
	return true


func process_recruitment(delta: float) -> bool:
	if not is_recruiting() or delta <= 0.0:
		return false
	recruitment_remaining = maxf(0.0, recruitment_remaining - delta)
	var completed := false
	if is_zero_approx(recruitment_remaining):
		_ensure_disciple_records()
		_create_disciple()
		assignments_changed.emit()
		disciples_changed.emit()
		completed = true
	recruitment_changed.emit()
	return completed


func get_production_multiplier(resource_id: StringName) -> float:
	var multiplier := 1.0
	for building: Dictionary in buildings:
		if not bool(building.get("completed", false)):
			continue
		var definition := BuildingCatalog.get_data(StringName(building.get("type", "")))
		if StringName(definition.get("production_resource", &"")) == resource_id:
			multiplier += float(definition.get("production_bonus", 0.0)) * float(building.get("level", 1))
	return multiplier


func get_sect_prosperity() -> int:
	var prosperity := floori(cultivation_points)
	for building: Dictionary in buildings:
		if bool(building.get("completed", false)):
			prosperity += int(building.get("level", 1)) * 20
	for disciple: Dictionary in disciples:
		prosperity += 10 + int(disciple.get("realm_level", 1)) * 5
	return prosperity


func get_next_sect_level_requirement() -> int:
	if sect_level >= MAX_SECT_LEVEL:
		return 0
	return int(SECT_LEVEL_REQUIREMENTS[sect_level])


func get_sect_production_multiplier() -> float:
	return 1.0 + float(sect_level - 1) * SECT_PRODUCTION_BONUS_PER_LEVEL


func can_upgrade_sect() -> bool:
	return sect_level < MAX_SECT_LEVEL and get_sect_prosperity() >= get_next_sect_level_requirement()


func upgrade_sect() -> bool:
	if not can_upgrade_sect():
		return false
	sect_level += 1
	sect_progress_changed.emit()
	return true


func get_building(instance_id: int) -> Dictionary:
	for building: Dictionary in buildings:
		if int(building.get("instance_id", 0)) == instance_id:
			return building
	return {}


func get_completed_building_count(building_type: StringName) -> int:
	var count := 0
	for building: Dictionary in buildings:
		if bool(building.get("completed", false)) and StringName(building.get("type", "")) == building_type:
			count += 1
	return count


func get_completed_building_levels(building_type: StringName) -> int:
	var levels := 0
	for building: Dictionary in buildings:
		if bool(building.get("completed", false)) and StringName(building.get("type", "")) == building_type:
			levels += int(building.get("level", 1))
	return levels


func get_training_capacity() -> int:
	var definition := BuildingCatalog.get_data(&"training_ground")
	return get_completed_building_levels(&"training_ground") * int(definition.get("training_capacity", 0))


func get_training_rate_multiplier() -> float:
	var extra_levels := get_completed_building_levels(&"training_ground") - get_completed_building_count(&"training_ground")
	return 1.0 + float(extra_levels) * 0.5


func get_cultivation_per_minute() -> float:
	var definition := BuildingCatalog.get_data(&"training_ground")
	return float(training_disciples) * float(definition.get("cultivation_rate", 0.0)) * get_training_rate_multiplier()


func assign_training_disciple() -> bool:
	if get_idle_disciples() <= 0 or training_disciples >= get_training_capacity():
		return false
	for disciple: Dictionary in disciples:
		if StringName(disciple.get("job", "idle")) == &"idle":
			disciple["job"] = "training"
			break
	_sync_aggregate_state_from_disciples()
	assignments_changed.emit()
	training_changed.emit()
	disciples_changed.emit()
	return true


func unassign_training_disciple() -> bool:
	if training_disciples <= 0:
		return false
	for index: int in range(disciples.size() - 1, -1, -1):
		if StringName(disciples[index].get("job", "idle")) == &"training":
			disciples[index]["job"] = "idle"
			break
	_sync_aggregate_state_from_disciples()
	assignments_changed.emit()
	training_changed.emit()
	disciples_changed.emit()
	return true


func process_training(delta: float) -> float:
	if training_disciples <= 0 or delta <= 0.0:
		return 0.0
	var definition := BuildingCatalog.get_data(&"training_ground")
	var gain_per_disciple := float(definition.get("cultivation_rate", 0.0)) * get_training_rate_multiplier() * delta / 60.0
	var gained := 0.0
	for disciple: Dictionary in disciples:
		if StringName(disciple.get("job", "idle")) != &"training":
			continue
		disciple["cultivation"] = float(disciple.get("cultivation", 0.0)) + gain_per_disciple
		gained += gain_per_disciple
	cultivation_points += gained
	training_changed.emit()
	disciples_changed.emit()
	return gained


func can_demolish_building(instance_id: int) -> bool:
	var building := get_building(instance_id)
	if building.is_empty():
		return false
	if bool(building.get("upgrading", false)):
		return false
	if bool(building.get("completed", false)) and StringName(building.get("type", "")) == &"disciple_quarters":
		var definition := BuildingCatalog.get_data(&"disciple_quarters")
		var capacity_after := get_disciple_capacity() - int(definition.get("disciple_capacity", 0)) * int(building.get("level", 1))
		var reserved_population := total_disciples + (1 if is_recruiting() else 0)
		if reserved_population > capacity_after:
			return false
	if bool(building.get("completed", false)) and StringName(building.get("type", "")) == &"training_ground":
		var definition := BuildingCatalog.get_data(&"training_ground")
		var training_capacity_after := get_training_capacity() - int(definition.get("training_capacity", 0)) * int(building.get("level", 1))
		if training_disciples > training_capacity_after:
			return false
	return true


func demolish_building(instance_id: int) -> Dictionary:
	if not can_demolish_building(instance_id):
		return {}
	for index: int in range(buildings.size()):
		var building: Dictionary = buildings[index]
		if int(building.get("instance_id", 0)) != instance_id:
			continue
		var definition := BuildingCatalog.get_data(StringName(building.get("type", "")))
		var refund: Dictionary = {}
		var cost: Dictionary = definition.get("cost", {})
		for resource_id: Variant in cost:
			var amount := floori(float(cost[resource_id]) * 0.5)
			refund[String(resource_id)] = amount
			resources[String(resource_id)] = get_resource_amount(StringName(resource_id)) + amount
		buildings.remove_at(index)
		resources_changed.emit()
		buildings_changed.emit()
		return refund
	return {}


func can_upgrade_building(instance_id: int) -> bool:
	var building := get_building(instance_id)
	if building.is_empty() or not bool(building.get("completed", false)) or bool(building.get("upgrading", false)):
		return false
	var level := int(building.get("level", 1))
	if level >= BuildingCatalog.MAX_BUILDING_LEVEL:
		return false
	var cost := BuildingCatalog.get_upgrade_cost(StringName(building.get("type", "")), level + 1)
	return can_afford(cost)


func start_building_upgrade(instance_id: int) -> bool:
	if not can_upgrade_building(instance_id):
		return false
	var building := get_building(instance_id)
	var target_level := int(building.get("level", 1)) + 1
	var building_type := StringName(building.get("type", ""))
	if not spend_resources(BuildingCatalog.get_upgrade_cost(building_type, target_level)):
		return false
	var upgrade_time := BuildingCatalog.get_upgrade_time(building_type, target_level)
	building["upgrading"] = true
	building["upgrade_remaining"] = upgrade_time
	building["upgrade_time"] = upgrade_time
	building["target_level"] = target_level
	buildings_changed.emit()
	return true


func get_sustenance_multiplier() -> float:
	return 1.0 if get_resource_amount(&"food") > 0 else HUNGRY_PRODUCTION_MULTIPLIER


func get_food_consumption_per_minute() -> float:
	_ensure_disciple_records()
	return float(total_disciples) * FOOD_CONSUMPTION_PER_DISCIPLE


func process_disciple_consumption(delta: float) -> int:
	if total_disciples <= 0 or delta <= 0.0:
		return 0
	food_consumption_progress += get_food_consumption_per_minute() * delta / 60.0
	var requested := floori(food_consumption_progress)
	if requested <= 0:
		return 0
	food_consumption_progress -= float(requested)
	var consumed := mini(requested, get_resource_amount(&"food"))
	if consumed > 0:
		resources["food"] = get_resource_amount(&"food") - consumed
		resources_changed.emit()
	if consumed < requested:
		food_consumption_progress = 0.0
	sustenance_changed.emit()
	return consumed


func get_assignment(site_id: StringName) -> int:
	return int(assignments.get(site_id, 0))


func assign_disciple(site_id: StringName) -> bool:
	if get_idle_disciples() <= 0:
		return false
	for disciple: Dictionary in disciples:
		if StringName(disciple.get("job", "idle")) == &"idle":
			disciple["job"] = String(site_id)
			break
	_sync_aggregate_state_from_disciples()
	assignments_changed.emit()
	disciples_changed.emit()
	return true


func unassign_disciple(site_id: StringName) -> bool:
	var current := get_assignment(site_id)
	if current <= 0:
		return false
	for index: int in range(disciples.size() - 1, -1, -1):
		if StringName(disciples[index].get("job", "idle")) == site_id:
			disciples[index]["job"] = "idle"
			break
	_sync_aggregate_state_from_disciples()
	assignments_changed.emit()
	disciples_changed.emit()
	return true


func process_production(site_id: StringName, resource_id: StringName, rate_per_minute: float, delta: float) -> int:
	var workforce_power := get_site_workforce_power(site_id)
	if workforce_power <= 0.0 or rate_per_minute <= 0.0:
		return 0
	var progress := float(production_progress.get(site_id, 0.0))
	progress += rate_per_minute * get_production_multiplier(resource_id) * get_sect_production_multiplier() * get_sustenance_multiplier() * workforce_power * delta / 60.0
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
		"level": 1,
		"upgrading": false,
	})
	next_building_id += 1
	buildings_changed.emit()
	return true


func process_construction(delta: float) -> void:
	var changed := false
	for building: Dictionary in buildings:
		if not bool(building["completed"]):
			building["remaining"] = maxf(0.0, float(building["remaining"]) - delta)
			if is_zero_approx(float(building["remaining"])):
				building["completed"] = true
			changed = true
		elif bool(building.get("upgrading", false)):
			building["upgrade_remaining"] = maxf(0.0, float(building.get("upgrade_remaining", 0.0)) - delta)
			if is_zero_approx(float(building["upgrade_remaining"])):
				building["level"] = int(building.get("target_level", int(building.get("level", 1)) + 1))
				building["upgrading"] = false
			changed = true
	if changed:
		buildings_changed.emit()


func export_save_data() -> Dictionary:
	_ensure_disciple_records()
	return {
		"resources": resources.duplicate(true),
		"total_disciples": total_disciples,
		"assignments": assignments.duplicate(true),
		"production_progress": production_progress.duplicate(true),
		"buildings": buildings.duplicate(true),
		"next_building_id": next_building_id,
		"recruitment_remaining": recruitment_remaining,
		"food_consumption_progress": food_consumption_progress,
		"training_disciples": training_disciples,
		"cultivation_points": cultivation_points,
		"disciples": disciples.duplicate(true),
		"next_disciple_id": next_disciple_id,
		"sect_level": sect_level,
		"battle_party": battle_party.duplicate(),
		"selected_battle_stage": selected_battle_stage,
		"highest_unlocked_stage": highest_unlocked_stage,
		"highest_cleared_stage": highest_cleared_stage,
		"battle_victories": battle_victories,
		"battle_encounter_sequence": battle_encounter_sequence,
		"active_battle_encounter_id": active_battle_encounter_id,
		"last_settled_battle_encounter_id": last_settled_battle_encounter_id,
		"battle_running": battle_running,
		"auto_battle_enabled": auto_battle_enabled,
		"battle_player_hp": battle_player_hp,
		"battle_player_max_hp": battle_player_max_hp,
		"battle_enemy_hp": battle_enemy_hp,
		"battle_enemy_max_hp": battle_enemy_max_hp,
		"battle_round_progress": battle_round_progress,
		"battle_restart_cooldown": battle_restart_cooldown,
		"battle_message": battle_message,
		"battle_round_number": battle_round_number,
		"battle_log": battle_log.duplicate(),
		"last_battle_result": last_battle_result.duplicate(true),
	}


func import_save_data(data: Dictionary) -> bool:
	var rollback_data := export_save_data()
	if _import_save_data_in_place(data):
		return true
	if not _import_save_data_in_place(rollback_data):
		push_error("读档失败后无法恢复原游戏状态")
	return false


func _import_save_data_in_place(data: Dictionary) -> bool:
	if not data.has("resources") or not data.has("assignments"):
		return false
	if not data["resources"] is Dictionary or not data["assignments"] is Dictionary:
		return false
	var loaded_resources: Dictionary = data["resources"]
	for resource_id: StringName in RESOURCE_IDS:
		var key := String(resource_id)
		if not loaded_resources.has(key) or typeof(loaded_resources[key]) not in [TYPE_INT, TYPE_FLOAT]:
			return false
		resources[key] = maxi(0, int(loaded_resources[key]))
	var saved_total := maxi(0, int(data.get("total_disciples", 3)))
	var loaded_assignments: Dictionary = data["assignments"]
	production_progress.clear()
	var loaded_progress_value: Variant = data.get("production_progress", {})
	if not loaded_progress_value is Dictionary:
		return false
	var loaded_progress: Dictionary = loaded_progress_value
	for site_id: Variant in loaded_progress:
		production_progress[String(site_id)] = clampf(float(loaded_progress[site_id]), 0.0, 0.999999)
	buildings.clear()
	var loaded_buildings_value: Variant = data.get("buildings", [])
	if not loaded_buildings_value is Array:
		return false
	var loaded_buildings: Array = loaded_buildings_value
	for raw_building: Variant in loaded_buildings:
		if not raw_building is Dictionary:
			return false
		var building: Dictionary = raw_building
		if BuildingCatalog.get_data(StringName(building.get("type", ""))).is_empty():
			return false
		buildings.append(building.duplicate(true))
	cultivation_points = maxf(0.0, float(data.get("cultivation_points", 0.0)))
	disciples.clear()
	next_disciple_id = 1
	var loaded_disciples_value: Variant = data.get("disciples", [])
	if not loaded_disciples_value is Array:
		return false
	var loaded_disciples: Array = loaded_disciples_value
	if not loaded_disciples.is_empty():
		var used_ids: Dictionary = {}
		for raw_disciple: Variant in loaded_disciples:
			if not raw_disciple is Dictionary:
				return false
			var disciple: Dictionary = raw_disciple.duplicate(true)
			var disciple_id := int(disciple.get("id", 0))
			var realm_level := int(disciple.get("realm_level", 1))
			var job := StringName(disciple.get("job", "idle"))
			if disciple_id <= 0 or used_ids.has(disciple_id) or realm_level < 1 or realm_level > REALM_MAX_LEVEL:
				return false
			if job not in [&"idle", &"forest", &"mine", &"field", &"training", &"combat"]:
				return false
			used_ids[disciple_id] = true
			disciple["name"] = str(disciple.get("name", "无名弟子"))
			disciple["realm_level"] = realm_level
			disciple["cultivation"] = maxf(0.0, float(disciple.get("cultivation", 0.0)))
			disciple["job"] = String(job)
			disciples.append(disciple)
		next_disciple_id = maxi(int(data.get("next_disciple_id", 1)), int(used_ids.keys().max()) + 1)
	else:
		for index: int in range(saved_total):
			_create_disciple()
		var cursor := 0
		for site_id: Variant in loaded_assignments:
			var worker_count := maxi(0, int(loaded_assignments[site_id]))
			for worker_index: int in range(worker_count):
				if cursor >= disciples.size():
					return false
				disciples[cursor]["job"] = String(site_id)
				cursor += 1
		var legacy_training := maxi(0, int(data.get("training_disciples", 0)))
		for training_index: int in range(legacy_training):
			if cursor >= disciples.size():
				return false
			disciples[cursor]["job"] = "training"
			cursor += 1
		if cultivation_points > 0.0 and not disciples.is_empty():
			var recipients: Array[Dictionary] = []
			for disciple: Dictionary in disciples:
				if StringName(disciple["job"]) == &"training":
					recipients.append(disciple)
			if recipients.is_empty():
				recipients.append(disciples[0])
			for disciple: Dictionary in recipients:
				disciple["cultivation"] = cultivation_points / float(recipients.size())
	_sync_aggregate_state_from_disciples()
	battle_party.clear()
	if data.has("battle_party"):
		var loaded_party_value: Variant = data["battle_party"]
		if not loaded_party_value is Array:
			return false
		var loaded_party: Array = loaded_party_value
		for raw_id: Variant in loaded_party:
			var disciple_id := int(raw_id)
			var disciple := get_disciple(disciple_id)
			if disciple.is_empty() or StringName(disciple.get("job", "idle")) != &"combat" or disciple_id in battle_party:
				return false
			battle_party.append(disciple_id)
	else:
		for disciple: Dictionary in disciples:
			if StringName(disciple.get("job", "idle")) == &"combat":
				battle_party.append(int(disciple["id"]))
	if not is_battle_party_consistent():
		return false
	if total_disciples != saved_total or training_disciples > get_training_capacity():
		return false
	next_building_id = maxi(1, int(data.get("next_building_id", buildings.size() + 1)))
	recruitment_remaining = clampf(float(data.get("recruitment_remaining", 0.0)), 0.0, RECRUIT_TIME)
	food_consumption_progress = clampf(float(data.get("food_consumption_progress", 0.0)), 0.0, 0.999999)
	sect_level = clampi(int(data.get("sect_level", 1)), 1, MAX_SECT_LEVEL)
	highest_unlocked_stage = clampi(int(data.get("highest_unlocked_stage", 1)), 1, BattleCatalogData.get_stage_count())
	highest_cleared_stage = clampi(int(data.get("highest_cleared_stage", 0)), 0, BattleCatalogData.get_stage_count())
	selected_battle_stage = clampi(int(data.get("selected_battle_stage", 1)), 1, highest_unlocked_stage)
	battle_victories = maxi(0, int(data.get("battle_victories", 0)))
	var has_encounter_tracking := data.has("battle_encounter_sequence") or data.has("active_battle_encounter_id") or data.has("last_settled_battle_encounter_id")
	if has_encounter_tracking and (not data.has("battle_encounter_sequence") or not data.has("active_battle_encounter_id") or not data.has("last_settled_battle_encounter_id")):
		return false
	battle_encounter_sequence = maxi(0, int(data.get("battle_encounter_sequence", 0)))
	active_battle_encounter_id = maxi(0, int(data.get("active_battle_encounter_id", 0)))
	last_settled_battle_encounter_id = maxi(0, int(data.get("last_settled_battle_encounter_id", 0)))
	if last_settled_battle_encounter_id > battle_encounter_sequence:
		return false
	battle_running = bool(data.get("battle_running", false)) and not battle_party.is_empty()
	auto_battle_enabled = bool(data.get("auto_battle_enabled", false)) and not battle_party.is_empty()
	if battle_running:
		if has_encounter_tracking:
			if active_battle_encounter_id <= last_settled_battle_encounter_id or active_battle_encounter_id > battle_encounter_sequence:
				return false
		else:
			battle_encounter_sequence = last_settled_battle_encounter_id + 1
			active_battle_encounter_id = battle_encounter_sequence
	elif has_encounter_tracking and active_battle_encounter_id != 0:
		return false
	else:
		active_battle_encounter_id = 0
	battle_player_max_hp = maxf(0.0, float(data.get("battle_player_max_hp", 0.0)))
	battle_player_hp = clampf(float(data.get("battle_player_hp", battle_player_max_hp)), 0.0, battle_player_max_hp)
	battle_enemy_max_hp = maxf(0.0, float(data.get("battle_enemy_max_hp", 0.0)))
	battle_enemy_hp = clampf(float(data.get("battle_enemy_hp", battle_enemy_max_hp)), 0.0, battle_enemy_max_hp)
	battle_round_progress = clampf(float(data.get("battle_round_progress", 0.0)), 0.0, BATTLE_ROUND_TIME)
	battle_restart_cooldown = maxf(0.0, float(data.get("battle_restart_cooldown", 0.0)))
	battle_message = str(data.get("battle_message", "请先编成队伍并选择关卡"))
	battle_round_number = maxi(0, int(data.get("battle_round_number", 0)))
	var loaded_log: Variant = data.get("battle_log", [])
	var loaded_result: Variant = data.get("last_battle_result", {})
	if not loaded_log is Array or not loaded_result is Dictionary:
		return false
	battle_log.clear()
	for entry: Variant in loaded_log:
		battle_log.append(str(entry))
	while battle_log.size() > BATTLE_LOG_LIMIT:
		battle_log.pop_front()
	last_battle_result = loaded_result.duplicate(true)
	if battle_running:
		if not auto_battle_enabled or not is_zero_approx(battle_restart_cooldown) or battle_player_hp <= 0.0 or battle_enemy_hp <= 0.0:
			return false
	elif auto_battle_enabled:
		if battle_restart_cooldown <= 0.0:
			return false
	elif battle_restart_cooldown > 0.0:
		return false
	if total_disciples + (1 if is_recruiting() else 0) > get_disciple_capacity():
		return false
	resources_changed.emit()
	assignments_changed.emit()
	buildings_changed.emit()
	recruitment_changed.emit()
	sustenance_changed.emit()
	training_changed.emit()
	disciples_changed.emit()
	sect_progress_changed.emit()
	battle_changed.emit()
	return true

