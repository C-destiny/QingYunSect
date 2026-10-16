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
@onready var building_actions: HBoxContainer = %BuildingActions
@onready var demolish_button: Button = %DemolishButton
@onready var building_action_status: Label = %BuildingActionStatus
@onready var disciple_selector: OptionButton = %DiscipleSelector
@onready var disciple_detail: Label = %DiscipleDetail
@onready var breakthrough_button: Button = %BreakthroughButton
@onready var disciple_job_selector: OptionButton = %DiscipleJobSelector
@onready var disciple_job_status: Label = %DiscipleJobStatus
@onready var roster_filter: OptionButton = %RosterFilter
@onready var roster_sort: OptionButton = %RosterSort
@onready var cultivation_progress: ProgressBar = %CultivationProgress

var selected_resource: Dictionary = {}
var selected_building: StringName = &""
var build_buttons: Dictionary = {}
var selected_building_instance: int = 0
var selected_disciple_id: int = 0
const DISCIPLE_JOBS := [&"idle", &"forest", &"mine", &"field", &"training"]
var roster_signature: String = ""


func _ready() -> void:
	GameState.resources_changed.connect(_refresh_resources)
	GameState.assignments_changed.connect(_refresh_assignment)
	GameState.buildings_changed.connect(_refresh_buildings)
	GameState.recruitment_changed.connect(_refresh_recruitment)
	GameState.sustenance_changed.connect(_refresh_resources)
	GameState.training_changed.connect(_refresh_training)
	GameState.disciples_changed.connect(_refresh_disciple_roster)
	sect_map.resource_selected.connect(_on_resource_selected)
	sect_map.placement_requested.connect(_on_placement_requested)
	sect_map.building_selected.connect(_on_building_selected)
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
	demolish_button.pressed.connect(_demolish_selected_building)
	disciple_selector.item_selected.connect(_on_disciple_selected)
	breakthrough_button.pressed.connect(_breakthrough_selected_disciple)
	disciple_job_selector.item_selected.connect(_on_disciple_job_selected)
	roster_filter.item_selected.connect(_on_roster_view_changed)
	roster_sort.item_selected.connect(_on_roster_view_changed)
	for filter_name: String in ["全部弟子", "空闲", "采集工作", "修炼中", "可突破"]:
		roster_filter.add_item(filter_name)
	for sort_name: String in ["按姓名", "境界降序", "修为降序", "按岗位"]:
		roster_sort.add_item(sort_name)
	for job: StringName in DISCIPLE_JOBS:
		disciple_job_selector.add_item(GameState.get_disciple_job_text(job))
		disciple_job_selector.set_item_metadata(disciple_job_selector.item_count - 1, String(job))
	if SaveManager.has_save():
		SaveManager.load_game()
	_refresh_resources()
	_refresh_assignment()
	_refresh_buildings()
	_refresh_recruitment()
	_refresh_disciple_roster()
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
	GameState.process_disciple_consumption(delta)
	GameState.process_training(delta)


func _refresh_resources() -> void:
	wood_label.text = "木材  %d" % GameState.get_resource_amount("wood")
	spirit_stone_label.text = "灵石  %d" % GameState.get_resource_amount("spirit_stone")
	var food_rate := _get_food_production_per_minute()
	var food_net := food_rate - GameState.get_food_consumption_per_minute()
	var food_amount := GameState.get_resource_amount("food")
	if food_net < 0.0:
		var sustain_minutes := float(food_amount) / -food_net
		food_label.text = "灵谷 %d · 净%.1f/分 · %.1f分" % [food_amount, food_net, sustain_minutes]
	else:
		food_label.text = "灵谷 %d · 净+%.1f/分" % [food_amount, food_net]
	disciples_label.text = "弟子  %d/%d · 上限 %d" % [
		GameState.assigned_disciples,
		GameState.total_disciples,
		GameState.get_disciple_capacity(),
	]
	if GameState.get_sustenance_multiplier() < 1.0:
		disciples_label.text += " · 缺粮"
	if not build_buttons.is_empty():
		for building_id: StringName in build_buttons:
			var definition := BuildingCatalog.get_data(building_id)
			build_buttons[building_id].disabled = not GameState.can_afford(definition["cost"])


func _on_resource_selected(resource_data: Dictionary) -> void:
	selected_resource = resource_data
	selected_building_instance = 0
	building_actions.visible = false
	assignment_status.visible = true
	production_status.visible = true
	assign_button.visible = true
	unassign_button.visible = true
	assign_button.text = "派遣一人"
	unassign_button.text = "撤回一人"
	selection_name.text = str(resource_data["name"])
	selection_description.text = "%s\n\n储量：%d" % [
		resource_data["description"],
		resource_data["reserve"],
	]
	_refresh_assignment()


func _on_building_selected(building: Dictionary) -> void:
	selected_resource = {}
	selected_building_instance = int(building.get("instance_id", 0))
	assignment_status.visible = false
	production_status.visible = false
	assign_button.visible = false
	unassign_button.visible = false
	building_actions.visible = true
	_refresh_selected_building()


func _refresh_selected_building() -> void:
	if selected_building_instance <= 0:
		return
	var building := GameState.get_building(selected_building_instance)
	if building.is_empty():
		selected_building_instance = 0
		building_actions.visible = false
		sect_map.clear_selection()
		return
	var building_type := StringName(building.get("type", ""))
	var definition := BuildingCatalog.get_data(building_type)
	var completed := bool(building.get("completed", false))
	selection_name.text = "%s · 等级 %d" % [definition["name"], int(building.get("level", 1))]
	var total_effect := _get_building_total_effect_text(building_type)
	selection_description.text = "%s\n\n状态：%s\n同类总效果：%s" % [
		definition["description"],
		"已完工" if completed else "施工中（%.1f秒）" % float(building["remaining"]),
		total_effect,
	]
	var is_training_ground := building_type == &"training_ground" and completed
	assignment_status.visible = is_training_ground
	production_status.visible = is_training_ground
	assign_button.visible = is_training_ground
	unassign_button.visible = is_training_ground
	if is_training_ground:
		_refresh_training()
	demolish_button.disabled = not GameState.can_demolish_building(selected_building_instance)
	if not demolish_button.disabled:
		building_action_status.text = "返还50%建造资源"
	elif building_type == &"training_ground":
		building_action_status.text = "请先停止场内弟子修炼"
	else:
		building_action_status.text = "拆除后人口将超过上限"


func _get_building_total_effect_text(building_type: StringName) -> String:
	var count := GameState.get_completed_building_count(building_type)
	var definition := BuildingCatalog.get_data(building_type)
	if definition.has("disciple_capacity"):
		return "%d座生效 · 弟子上限 +%d" % [count, count * int(definition["disciple_capacity"])]
	if definition.has("production_bonus"):
		return "%d座生效 · 采集效率 +%.0f%%" % [count, float(count) * float(definition["production_bonus"]) * 100.0]
	if definition.has("training_capacity"):
		return "%d座生效 · 修炼位 %d" % [count, count * int(definition["training_capacity"])]
	return "%d座生效" % count


func _is_training_ground_selected() -> bool:
	if selected_building_instance <= 0:
		return false
	var building := GameState.get_building(selected_building_instance)
	return not building.is_empty() and bool(building.get("completed", false)) and StringName(building.get("type", "")) == &"training_ground"


func _refresh_training() -> void:
	if not _is_training_ground_selected():
		return
	assignment_status.text = "修炼弟子 %d/%d · 空闲 %d 人" % [
		GameState.training_disciples,
		GameState.get_training_capacity(),
		GameState.get_idle_disciples(),
	]
	production_status.text = "宗门修为 %.1f · +%.1f/分钟" % [GameState.cultivation_points, GameState.get_cultivation_per_minute()]
	assign_button.text = "安排修炼"
	unassign_button.text = "停止修炼"
	assign_button.disabled = GameState.get_idle_disciples() <= 0 or GameState.training_disciples >= GameState.get_training_capacity()
	unassign_button.disabled = GameState.training_disciples <= 0


func _demolish_selected_building() -> void:
	var refund := GameState.demolish_building(selected_building_instance)
	if refund.is_empty():
		building_action_status.text = "当前无法拆除该建筑"
		return
	selected_building_instance = 0
	building_actions.visible = false
	selection_name.text = "建筑已拆除"
	selection_description.text = "返还木材%d、灵石%d。" % [int(refund.get("wood", 0)), int(refund.get("spirit_stone", 0))]
	sect_map.clear_selection()
	SaveManager.save_game()


func _assign_disciple() -> void:
	if _is_training_ground_selected():
		GameState.assign_training_disciple()
		return
	if selected_resource.is_empty():
		return
	GameState.assign_disciple(selected_resource["site_id"])


func _unassign_disciple() -> void:
	if _is_training_ground_selected():
		GameState.unassign_training_disciple()
		return
	if selected_resource.is_empty():
		return
	GameState.unassign_disciple(selected_resource["site_id"])


func _refresh_assignment() -> void:
	_refresh_resources()
	if _is_training_ground_selected():
		_refresh_training()
		return
	var has_selection := not selected_resource.is_empty()
	assign_button.disabled = not has_selection or GameState.get_idle_disciples() <= 0
	unassign_button.disabled = not has_selection
	if not has_selection:
		assignment_status.text = "已分配 0 人 · 空闲 %d 人" % GameState.get_idle_disciples()
		production_status.text = "选择资源点后安排弟子"
		return
	var workers := GameState.get_assignment(selected_resource["site_id"])
	unassign_button.disabled = workers <= 0
	var building_multiplier := GameState.get_production_multiplier(selected_resource["resource_id"])
	var sustenance_multiplier := GameState.get_sustenance_multiplier()
	var multiplier := building_multiplier * sustenance_multiplier
	var workforce_power := GameState.get_site_workforce_power(selected_resource["site_id"])
	var realm_bonus := (workforce_power / float(workers) - 1.0) * 100.0 if workers > 0 else 0.0
	var total_rate := float(selected_resource["rate"]) * multiplier * workforce_power
	assignment_status.text = "已分配 %d 人 · 空闲 %d 人" % [workers, GameState.get_idle_disciples()]
	production_status.text = "%s +%.1f/分钟 · 建筑 +%.0f%% · 境界 +%.0f%%" % [
		selected_resource["resource_name"],
		total_rate,
		(building_multiplier - 1.0) * 100.0,
		realm_bonus,
	]
	if sustenance_multiplier < 1.0:
		production_status.text += " · 缺粮效率50%"


func _get_food_production_per_minute() -> float:
	for resource_data: Dictionary in sect_map.resource_nodes:
		if StringName(resource_data["resource_id"]) == &"food":
			return float(resource_data["rate"]) * GameState.get_site_workforce_power(resource_data["site_id"]) * GameState.get_production_multiplier(&"food") * GameState.get_sustenance_multiplier()
	return 0.0


func _refresh_disciple_roster() -> void:
	var visible_disciples := _get_visible_disciples()
	var signature_parts := PackedStringArray([str(roster_filter.selected), str(roster_sort.selected)])
	for disciple: Dictionary in visible_disciples:
		signature_parts.append("%d:%d:%d:%s" % [
			int(disciple.get("id", 0)), int(disciple.get("realm_level", 1)),
			floori(float(disciple.get("cultivation", 0.0))), str(disciple.get("job", "idle")),
		])
	var new_signature := "|".join(signature_parts)
	if new_signature != roster_signature:
		roster_signature = new_signature
		var previous_id := selected_disciple_id
		disciple_selector.clear()
		for disciple: Dictionary in visible_disciples:
			var marker := " ★" if GameState.can_breakthrough(int(disciple.get("id", 0))) else ""
			disciple_selector.add_item("%s · %s · %s%s" % [
				disciple.get("name", "无名弟子"),
				GameState.get_realm_name(int(disciple.get("realm_level", 1))),
				GameState.get_disciple_job_text(StringName(disciple.get("job", "idle"))), marker,
			])
			disciple_selector.set_item_metadata(disciple_selector.item_count - 1, int(disciple.get("id", 0)))
		if disciple_selector.item_count > 0:
			var target_index := 0
			for index: int in range(disciple_selector.item_count):
				if int(disciple_selector.get_item_metadata(index)) == previous_id:
					target_index = index
					break
			disciple_selector.select(target_index)
			selected_disciple_id = int(disciple_selector.get_item_metadata(target_index))
		else:
			selected_disciple_id = 0
	_refresh_disciple_detail()


func _get_visible_disciples() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for disciple: Dictionary in GameState.disciples:
		var job := StringName(disciple.get("job", "idle"))
		var include := true
		match roster_filter.selected:
			1: include = job == &"idle"
			2: include = job in [&"forest", &"mine", &"field"]
			3: include = job == &"training"
			4: include = GameState.can_breakthrough(int(disciple.get("id", 0)))
		if include:
			result.append(disciple)
	match roster_sort.selected:
		0: result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["name"]).naturalnocasecmp_to(str(b["name"])) < 0)
		1: result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["realm_level"]) > int(b["realm_level"]))
		2: result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["cultivation"]) > float(b["cultivation"]))
		3: result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["job"]).naturalnocasecmp_to(str(b["job"])) < 0)
	return result


func _on_roster_view_changed(_index: int) -> void:
	roster_signature = ""
	_refresh_disciple_roster()


func _on_disciple_selected(index: int) -> void:
	if index < 0 or index >= disciple_selector.item_count:
		return
	selected_disciple_id = int(disciple_selector.get_item_metadata(index))
	_refresh_disciple_detail()


func _refresh_disciple_detail() -> void:
	var disciple := GameState.get_disciple(selected_disciple_id)
	if disciple.is_empty():
		disciple_detail.text = "暂无弟子"
		breakthrough_button.disabled = true
		disciple_job_selector.disabled = true
		cultivation_progress.value = 0.0
		return
	disciple_job_selector.disabled = false
	var realm_level := int(disciple.get("realm_level", 1))
	var cultivation := float(disciple.get("cultivation", 0.0))
	var gathering_bonus := float(realm_level - 1) * GameState.REALM_GATHERING_BONUS_PER_LEVEL * 100.0
	if realm_level >= GameState.REALM_MAX_LEVEL:
		cultivation_progress.max_value = 1.0
		cultivation_progress.value = 1.0
		disciple_detail.text = "%s · %s\n修为 %.1f · 岗位：%s\n个人采集加成 +%.0f%%" % [
			disciple.get("name", "无名弟子"), GameState.get_realm_name(realm_level), cultivation,
			GameState.get_disciple_job_text(StringName(disciple.get("job", "idle"))), gathering_bonus,
		]
		breakthrough_button.text = "已达炼气九层"
	else:
		var requirement := GameState.get_breakthrough_requirement(realm_level)
		cultivation_progress.max_value = requirement
		cultivation_progress.value = cultivation
		disciple_detail.text = "%s · %s\n修为 %.1f / %.0f · 岗位：%s\n个人采集加成 +%.0f%%" % [
			disciple.get("name", "无名弟子"), GameState.get_realm_name(realm_level), cultivation, requirement,
			GameState.get_disciple_job_text(StringName(disciple.get("job", "idle"))), gathering_bonus,
		]
		breakthrough_button.text = "突破至%s" % GameState.get_realm_name(realm_level + 1)
	breakthrough_button.disabled = not GameState.can_breakthrough(selected_disciple_id)
	var current_job := StringName(disciple.get("job", "idle"))
	for index: int in range(disciple_job_selector.item_count):
		var job := StringName(disciple_job_selector.get_item_metadata(index))
		disciple_job_selector.set_item_disabled(index, job == &"training" and current_job != &"training" and GameState.training_disciples >= GameState.get_training_capacity())
		if job == current_job:
			disciple_job_selector.select(index)


func _on_disciple_job_selected(index: int) -> void:
	if index < 0 or index >= disciple_job_selector.item_count or selected_disciple_id <= 0:
		return
	var job := StringName(disciple_job_selector.get_item_metadata(index))
	if GameState.set_disciple_job(selected_disciple_id, job):
		var disciple := GameState.get_disciple(selected_disciple_id)
		disciple_job_status.text = "%s已调整为：%s" % [disciple.get("name", "该弟子"), GameState.get_disciple_job_text(job)]
		disciple_job_status.modulate = Color(0.55, 0.85, 0.62)
		SaveManager.save_game()
	else:
		disciple_job_status.text = "无法调整岗位：演武场修炼位不足"
		disciple_job_status.modulate = Color(0.9, 0.55, 0.42)
		_refresh_disciple_detail()


func _breakthrough_selected_disciple() -> void:
	if GameState.breakthrough_disciple(selected_disciple_id):
		_refresh_disciple_roster()
		SaveManager.save_game()


func _save_game() -> void:
	SaveManager.save_game()


func _load_game() -> void:
	SaveManager.load_game()


func _autosave() -> void:
	if GameState.assigned_disciples > 0 or GameState.is_recruiting() or GameState.training_disciples > 0:
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
	_refresh_selected_building()
	var constructing := 0
	for building: Dictionary in GameState.buildings:
		if not bool(building["completed"]):
			constructing += 1
	if constructing > 0 and selected_building == &"":
		placement_status.text = "施工中：%d 座建筑" % constructing

