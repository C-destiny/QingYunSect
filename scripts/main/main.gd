extends Control

const BattleCatalogData = preload("res://scripts/data/battle_catalog.gd")
const EquipmentCatalogData = preload("res://scripts/data/equipment_catalog.gd")
const EquipmentCraftingCatalogData = preload("res://scripts/data/equipment_crafting_catalog.gd")
const ProfessionCatalogData = preload("res://scripts/data/profession_catalog.gd")
const TerritoryCatalogData = preload("res://scripts/data/territory_catalog.gd")
const DevelopmentGoalCatalogData = preload("res://scripts/data/development_goal_catalog.gd")

@onready var wood_label: Button = %Wood
@onready var spirit_stone_label: Button = %SpiritStone
@onready var food_label: Button = %Food
@onready var disciples_label: Button = %Disciples
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
@onready var core_character_selector: OptionButton = %CoreCharacterSelector
@onready var core_character_preview: TextureRect = %CoreCharacterPreview
@onready var core_character_caption: Label = %CoreCharacterCaption
@onready var building_actions: HBoxContainer = %BuildingActions
@onready var demolish_button: Button = %DemolishButton
@onready var building_action_status: Label = %BuildingActionStatus
@onready var upgrade_button: Button = %UpgradeButton
@onready var disciple_selector: OptionButton = %DiscipleSelector
@onready var disciple_detail: Label = %DiscipleDetail
@onready var breakthrough_button: Button = %BreakthroughButton
@onready var disciple_job_selector: OptionButton = %DiscipleJobSelector
@onready var disciple_job_status: Label = %DiscipleJobStatus
@onready var roster_filter: OptionButton = %RosterFilter
@onready var roster_sort: OptionButton = %RosterSort
@onready var cultivation_progress: ProgressBar = %CultivationProgress
@onready var equipment_stats: Label = %EquipmentStats
@onready var equipment_slot_selector: OptionButton = %EquipmentSlotSelector
@onready var equipment_inventory_selector: OptionButton = %EquipmentInventorySelector
@onready var equip_button: Button = %EquipButton
@onready var unequip_button: Button = %UnequipButton
@onready var equipment_status: Label = %EquipmentStatus
@onready var craft_template_selector: OptionButton = %CraftTemplateSelector
@onready var craft_quality_selector: OptionButton = %CraftQualitySelector
@onready var craft_button: Button = %CraftButton
@onready var crafting_status: Label = %CraftingStatus
@onready var sect_level_status: Label = %SectLevelStatus
@onready var sect_progress: ProgressBar = %SectProgress
@onready var sect_upgrade_button: Button = %SectUpgradeButton
@onready var territory_status: Label = %TerritoryStatus
@onready var territory_unlock_button: Button = %TerritoryUnlockButton
@onready var management_sidebar: Control = $Layout/Body/Sidebar
@onready var sidebar_scroll: ScrollContainer = %Scroll
@onready var goal_status: Label = %GoalStatus
@onready var goal_resource_feedback: Label = %GoalResourceFeedback
@onready var claim_goal_button: Button = %ClaimGoalButton
@onready var nav_management_button: Button = %NavManagementButton
@onready var nav_disciples_button: Button = %NavDisciplesButton
@onready var nav_battle_button: Button = %NavBattleButton
@onready var close_management_button: Button = %CloseManagementButton
@onready var open_sect_panel_button: Button = %OpenSectPanelButton
@onready var open_build_panel_button: Button = %OpenBuildPanelButton
@onready var open_disciples_panel_button: Button = %OpenDisciplesPanelButton
@onready var open_growth_panel_button: Button = %OpenGrowthPanelButton
@onready var open_battle_panel_button: Button = %OpenBattlePanelButton
@onready var sect_heading: Label = %Heading
@onready var management_heading: Label = %BuildHeading
@onready var disciples_heading: Label = %RosterHeading
@onready var growth_heading: Label = %EquipmentHeading
@onready var battle_heading: Label = %BattleHeading
@onready var battle_party_status: Label = %BattlePartyStatus
@onready var join_battle_button: Button = %JoinBattleButton
@onready var leave_battle_button: Button = %LeaveBattleButton
@onready var battle_stage_selector: OptionButton = %BattleStageSelector
@onready var battle_progress_summary: Label = %BattleProgressSummary
@onready var battle_party_members: Label = %BattlePartyMembers
@onready var battle_stats: Label = %BattleStats
@onready var enemy_battle_info: Label = %EnemyBattleInfo
@onready var player_battle_hp_text: Label = %PlayerBattleHpText
@onready var player_battle_hp: ProgressBar = %PlayerBattleHp
@onready var enemy_battle_hp_text: Label = %EnemyBattleHpText
@onready var enemy_battle_hp: ProgressBar = %EnemyBattleHp
@onready var battle_status: Label = %BattleStatus
@onready var battle_log_label: Label = %BattleLog
@onready var last_battle_result_label: Label = %LastBattleResult
@onready var battle_toggle_button: Button = %BattleToggleButton
@onready var offline_summary_dialog: AcceptDialog = %OfflineSummaryDialog
@onready var offline_summary_text: Label = %OfflineSummaryText

var building_card: Control
var fixed_site_card: Control
var fixed_card_refresh := 0.0
var card_is_hall := false

var selected_resource: Dictionary = {}
var selected_building: StringName = &""
var build_buttons: Dictionary = {}
var selected_building_instance: int = 0
var selected_disciple_id: int = 0
const DISCIPLE_JOBS := [&"idle", &"forest", &"mine", &"field", &"training", &"combat"]
const CORE_CHARACTER_MODELS := [
	{
		"name": "崔云川",
		"title": "剑心守道",
		"summary": "青白银剑修视觉模型；玩法设想留待后续版本。",
		"texture": preload("res://assets/characters/cui_yunchuan_model.png"),
	},
	{
		"name": "周墨",
		"title": "机巧道人",
		"summary": "靛蓝青玉机关修士视觉模型；玩法设想留待后续版本。",
		"texture": preload("res://assets/characters/zhou_mo_model.png"),
	},
]
var roster_signature: String = ""
var current_sidebar_target: Control = null

# 分类只控制界面容器；数据刷新仍走原有GameState入口，隐藏页不会停止游戏逻辑。
const MANAGEMENT_SECTIONS := {
	"宗门": ["SectSection", "SelectionSection"],
	"建设": ["BuildSection", "SelectionSection"],
	"弟子": ["RecruitmentSection", "CharacterSection", "RosterSection", "DiscipleSelectionSection", "JobSection"],
	"养成": ["DiscipleSelectionSection", "TrainingSection", "EquipmentSection"],
	"挂机": ["DiscipleSelectionSection", "BattleSection"],
}


func _ready() -> void:
	if "--unified-courtyard-sample" in OS.get_cmdline_user_args():
		# Independent art sample branches before all formal-save checks.
		set_process(false)
		var unified := preload("res://scenes/samples/unified_courtyard.tscn").instantiate()
		get_parent().add_child.call_deferred(unified)
		queue_free()
		return
	if "--hall-courtyard-sample" in OS.get_cmdline_user_args():
		# This branch runs before any formal-save check or normal gameplay setup.
		set_process(false)
		var sample := preload("res://scenes/samples/hall_courtyard.tscn").instantiate()
		get_parent().add_child.call_deferred(sample)
		queue_free()
		return
	preload("res://scripts/ui/hud_styling.gd").apply(self)
	var full_demo := "--full-scene-demo" in OS.get_cmdline_user_args()
	var courtyard_demo := "--courtyard-demo" in OS.get_cmdline_user_args()
	var fixed_demo := "--fixed-layout-demo" in OS.get_cmdline_user_args() or "--fixed-layout-showcase" in OS.get_cmdline_user_args()
	sect_map.fixed_layout = not (full_demo or courtyard_demo or "--visual-sample" in OS.get_cmdline_user_args() or "--legacy-free-build" in OS.get_cmdline_user_args())
	sect_map.complete_sect = sect_map.fixed_layout and not "--legacy-fixed-art" in OS.get_cmdline_user_args()
	sect_map.structured_terrain = courtyard_demo
	var visual_demo := fixed_demo or courtyard_demo or full_demo or "--visual-sample" in OS.get_cmdline_user_args()
	if visual_demo:
		# 必须在首次has_save/load之前切换路径；演示模式不读取或覆盖正式玩家存档。
		SaveManager.save_path = "user://v08_full_visual_demo.json" if full_demo else "user://v08_hall_visual_demo.json"
		if courtyard_demo:
			SaveManager.save_path = "user://v08_courtyard_visual_demo.json"
		if fixed_demo:
			SaveManager.save_path = "user://v08_fixed_layout_demo.json"
	building_card = preload("res://scripts/ui/building_card.gd").new()
	add_child(building_card)
	building_card.close_requested.connect(_dismiss_building_card)
	building_card.manage_requested.connect(_manage_card_selection)
	building_card.upgrade_requested.connect(_upgrade_card_selection)
	fixed_site_card = preload("res://scripts/ui/fixed_site_card.gd").new()
	add_child(fixed_site_card)
	fixed_site_card.construct_requested.connect(_construct_fixed_site)
	fixed_site_card.instance_requested.connect(_select_fixed_instance)
	fixed_site_card.close_requested.connect(sect_map.clear_selection)
	sect_map.fixed_site_selected.connect(_open_fixed_site)
	resized.connect(func() -> void:
		if is_instance_valid(fixed_site_card) and fixed_site_card.visible:
			_open_fixed_site(fixed_site_card.site_kind))
	resized.connect(_refresh_building_card)
	sect_map.hall_selected.connect(_on_hall_selected)
	GameState.resources_changed.connect(_refresh_resources)
	GameState.assignments_changed.connect(_refresh_assignment)
	GameState.buildings_changed.connect(_refresh_buildings)
	GameState.recruitment_changed.connect(_refresh_recruitment)
	GameState.sustenance_changed.connect(_refresh_resources)
	GameState.training_changed.connect(_refresh_training)
	GameState.disciples_changed.connect(_refresh_disciple_roster)
	GameState.disciples_changed.connect(_refresh_battle)
	GameState.sect_progress_changed.connect(_refresh_sect_progress)
	GameState.buildings_changed.connect(_refresh_sect_progress)
	GameState.disciples_changed.connect(_refresh_sect_progress)
	GameState.training_changed.connect(_refresh_sect_progress)
	GameState.battle_changed.connect(_refresh_battle)
	GameState.equipment_changed.connect(_refresh_equipment_panel)
	GameState.equipment_changed.connect(_refresh_battle)
	GameState.territory_changed.connect(_refresh_territory)
	GameState.resources_changed.connect(_refresh_territory)
	GameState.resources_changed.connect(_refresh_development_goal)
	GameState.buildings_changed.connect(_refresh_development_goal)
	GameState.disciples_changed.connect(_refresh_development_goal)
	GameState.sect_progress_changed.connect(_refresh_development_goal)
	GameState.battle_changed.connect(_refresh_development_goal)
	GameState.territory_changed.connect(_refresh_development_goal)
	GameState.equipment_changed.connect(_refresh_development_goal)
	GameState.development_goal_changed.connect(_refresh_development_goal)
	sect_map.resource_selected.connect(_on_resource_selected)
	sect_map.placement_requested.connect(_on_placement_requested)
	sect_map.building_selected.connect(_on_building_selected)
	sect_map.region_selected.connect(_on_region_selected)
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
		&"artifact_forge": %ArtifactForgeButton,
		&"scripture_library": %ScriptureLibraryButton,
	}
	for building_id: StringName in build_buttons:
		build_buttons[building_id].pressed.connect(_start_building_placement.bind(building_id))
	cancel_build_button.pressed.connect(_cancel_building_placement)
	recruit_button.pressed.connect(_start_recruitment)
	core_character_selector.item_selected.connect(_on_core_character_selected)
	demolish_button.pressed.connect(_demolish_selected_building)
	upgrade_button.pressed.connect(_upgrade_selected_building)
	disciple_selector.item_selected.connect(_on_disciple_selected)
	breakthrough_button.pressed.connect(_breakthrough_selected_disciple)
	sect_upgrade_button.pressed.connect(_upgrade_sect)
	territory_unlock_button.pressed.connect(_unlock_next_region)
	claim_goal_button.pressed.connect(_claim_current_development_goal)
	nav_management_button.pressed.connect(_navigate_sidebar.bind(management_heading))
	nav_disciples_button.pressed.connect(_navigate_sidebar.bind(disciples_heading))
	nav_battle_button.pressed.connect(_navigate_sidebar.bind(battle_heading))
	close_management_button.pressed.connect(_request_close_management_panel)
	open_sect_panel_button.pressed.connect(_navigate_sidebar.bind(sect_heading))
	open_build_panel_button.pressed.connect(_navigate_sidebar.bind(management_heading))
	open_disciples_panel_button.pressed.connect(_navigate_sidebar.bind(disciples_heading))
	open_growth_panel_button.pressed.connect(_navigate_sidebar.bind(growth_heading))
	open_battle_panel_button.pressed.connect(_navigate_sidebar.bind(battle_heading))
	disciple_job_selector.item_selected.connect(_on_disciple_job_selected)
	roster_filter.item_selected.connect(_on_roster_view_changed)
	roster_sort.item_selected.connect(_on_roster_view_changed)
	join_battle_button.pressed.connect(_join_selected_disciple_to_battle)
	leave_battle_button.pressed.connect(_remove_selected_disciple_from_battle)
	battle_stage_selector.item_selected.connect(_on_battle_stage_selected)
	battle_toggle_button.pressed.connect(_toggle_battle)
	equipment_slot_selector.item_selected.connect(_on_equipment_slot_selected)
	equipment_inventory_selector.item_selected.connect(_on_equipment_inventory_selected)
	equip_button.pressed.connect(_equip_selected_item)
	unequip_button.pressed.connect(_unequip_selected_item)
	craft_template_selector.item_selected.connect(_on_crafting_selection_changed)
	craft_quality_selector.item_selected.connect(_on_crafting_selection_changed)
	craft_button.pressed.connect(_craft_selected_equipment)
	for filter_name: String in ["全部弟子", "空闲", "采集工作", "修炼中", "可突破", "战斗队伍"]:
		roster_filter.add_item(filter_name)
	for model: Dictionary in CORE_CHARACTER_MODELS:
		core_character_selector.add_item("%s · %s" % [model["name"], model["title"]])
	_refresh_core_character_preview()
	for sort_name: String in ["按姓名", "境界降序", "修为降序", "按岗位"]:
		roster_sort.add_item(sort_name)
	for job: StringName in DISCIPLE_JOBS:
		disciple_job_selector.add_item(GameState.get_disciple_job_text(job))
		disciple_job_selector.set_item_metadata(disciple_job_selector.item_count - 1, String(job))
	for slot: StringName in GameState.EQUIPMENT_SLOT_IDS:
		equipment_slot_selector.add_item(str(EquipmentCatalogData.SLOTS[String(slot)]))
		equipment_slot_selector.set_item_metadata(equipment_slot_selector.item_count - 1, String(slot))
	for template_id: String in EquipmentCatalogData.TEMPLATES:
		craft_template_selector.add_item(str(EquipmentCatalogData.TEMPLATES[template_id]["name"]))
		craft_template_selector.set_item_metadata(craft_template_selector.item_count - 1, template_id)
	for quality: StringName in GameState.EQUIPMENT_QUALITY_IDS:
		craft_quality_selector.add_item(str(EquipmentCatalogData.QUALITIES[String(quality)]["name"]))
		craft_quality_selector.set_item_metadata(craft_quality_selector.item_count - 1, String(quality))
	if not visual_demo and SaveManager.has_save():
		SaveManager.load_game()
	if visual_demo:
		if fixed_demo:
			GameState.resources["wood"] = 1000
			GameState.resources["spirit_stone"] = 1000
			GameState.resources["food"] = 1000
			if "--fixed-layout-showcase" in OS.get_cmdline_user_args():
				for kind: StringName in BuildingCatalog.BUILDINGS:
					preload("res://scripts/world/fixed_sect_layout.gd").construct(GameState, kind)
				GameState.process_construction(30)
		elif courtyard_demo:
			preload("res://scripts/world/courtyard_demo.gd").populate(GameState)
		elif full_demo:
			preload("res://scripts/world/visual_demo.gd").populate_full_scene(GameState)
		else:
			for cell: Vector2i in [Vector2i(3, 3), Vector2i(1, 5)]:
				GameState.start_construction(&"disciple_quarters", cell)
			GameState.process_construction(20)
		autosave_timer.stop()
		save_status.text = "独立演示存档"
		print("VISUAL_SAMPLE: isolated demo path; buildings=%d; formal save not loaded" % GameState.buildings.size())
	_refresh_resources()
	_refresh_assignment()
	_refresh_buildings()
	_refresh_recruitment()
	_refresh_disciple_roster()
	_refresh_sect_progress()
	_refresh_territory()
	_refresh_battle_stages()
	_refresh_battle()
	_refresh_crafting_panel()
	_refresh_development_goal()
	cancel_build_button.visible = not sect_map.fixed_layout
	if sect_map.fixed_layout:
		placement_status.text = "选择院落，消耗资源开始建设"
	if sect_map.complete_sect:
		preload("res://scripts/ui/complete_sect_hud.gd").apply(self)
	print("青云宗 V0.8 开发版：美术与UI定稿启动成功")


func _process(delta: float) -> void:
	_refresh_building_card()
	if is_instance_valid(fixed_site_card) and fixed_site_card.visible:
		fixed_card_refresh += delta
		if fixed_card_refresh >= 0.5:
			fixed_card_refresh = 0.0
			_open_fixed_site(fixed_site_card.site_kind)
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
	if GameState.process_battle(delta):
		_refresh_battle_stages()
		SaveManager.save_game()


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
	if sect_map.complete_sect:
		food_label.tooltip_text = food_label.text
		food_label.text = "灵谷  %d" % food_amount
		if GameState.get_sustenance_multiplier() < 1.0:
			food_label.text += " · 缺粮"
		disciples_label.tooltip_text = disciples_label.text
		disciples_label.text = "弟子 %d/%d" % [GameState.total_disciples, GameState.get_disciple_capacity()]
	if not build_buttons.is_empty():
		for building_id: StringName in build_buttons:
			var definition := BuildingCatalog.get_data(building_id)
			build_buttons[building_id].disabled = not GameState.can_afford(definition["cost"])
	_refresh_crafting_panel()


func _on_resource_selected(resource_data: Dictionary) -> void:
	sect_map.clear_selection()
	if is_instance_valid(fixed_site_card):
		fixed_site_card.hide()
	building_card.hide()
	selected_resource = resource_data
	selected_building_instance = 0
	_open_management_panel(sect_heading)
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
	if sect_map.fixed_layout:
		sect_map.fixed_selected_kind = StringName(building["type"])
	if is_instance_valid(fixed_site_card):
		fixed_site_card.hide()
	selected_resource = {}
	selected_building_instance = int(building.get("instance_id", 0))
	sect_map.selected_cell = Vector2i(building["cell_x"], building["cell_y"])
	sect_map.queue_redraw()
	card_is_hall = false
	_close_management_panel()
	assignment_status.visible = false
	production_status.visible = false
	assign_button.visible = false
	unassign_button.visible = false
	building_actions.visible = true
	_refresh_selected_building()
	building_card.show()
	_refresh_building_card()


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
	var state_text := "已完工" if completed else "施工中（%.1f秒）" % float(building["remaining"])
	if bool(building.get("upgrading", false)):
		state_text = "升级至等级%d（%.1f秒）" % [int(building.get("target_level", 2)), float(building.get("upgrade_remaining", 0.0))]
	selection_description.text = "%s\n\n状态：%s\n同类总效果：%s" % [
		definition["description"],
		state_text,
		total_effect,
	]
	var is_training_ground := building_type == &"training_ground" and completed
	assignment_status.visible = is_training_ground
	production_status.visible = is_training_ground
	assign_button.visible = is_training_ground
	unassign_button.visible = is_training_ground
	if is_training_ground:
		_refresh_training()
	var level := int(building.get("level", 1))
	upgrade_button.visible = completed
	upgrade_button.disabled = not GameState.can_upgrade_building(selected_building_instance)
	if level >= BuildingCatalog.MAX_BUILDING_LEVEL:
		upgrade_button.text = "已满级"
	elif bool(building.get("upgrading", false)):
		upgrade_button.text = "升级中"
	else:
		var upgrade_cost := BuildingCatalog.get_upgrade_cost(building_type, level + 1)
		upgrade_button.text = "升%d级\n%s" % [level + 1, _format_cost(upgrade_cost)]
	demolish_button.disabled = not GameState.can_demolish_building(selected_building_instance)
	if not demolish_button.disabled:
		building_action_status.text = "返还50%建造资源"
	elif bool(building.get("upgrading", false)):
		building_action_status.text = "升级期间不可拆除"
	elif building_type == &"training_ground":
		building_action_status.text = "请先停止场内弟子修炼"
	else:
		building_action_status.text = "拆除后人口将超过上限"


func _get_building_total_effect_text(building_type: StringName) -> String:
	var count := GameState.get_completed_building_count(building_type)
	var levels := GameState.get_completed_building_levels(building_type)
	var definition := BuildingCatalog.get_data(building_type)
	if definition.has("disciple_capacity"):
		return "%d座/总等级%d · 弟子上限 +%d" % [count, levels, levels * int(definition["disciple_capacity"])]
	if definition.has("production_bonus"):
		return "%d座/总等级%d · 采集效率 +%.0f%%" % [count, levels, float(levels) * float(definition["production_bonus"]) * 100.0]
	if definition.has("training_capacity"):
		return "%d座/总等级%d · 修炼位 %d · 速度×%.1f" % [count, levels, levels * int(definition["training_capacity"]), GameState.get_training_rate_multiplier()]
	if definition.has("forging_level"):
		return "%d座/总等级%d · 有效打造等级 %d" % [count, levels, GameState.get_forging_level()]
	if definition.has("training_bonus"):
		return "%d座/总等级%d · 演武修炼 +%.0f%%" % [count, levels, float(levels) * float(definition["training_bonus"]) * 100.0]
	return "%d座生效" % count


func _format_cost(cost: Dictionary) -> String:
	var parts := PackedStringArray()
	if int(cost.get("wood", 0)) > 0: parts.append("木%d" % int(cost["wood"]))
	if int(cost.get("spirit_stone", 0)) > 0: parts.append("石%d" % int(cost["spirit_stone"]))
	if int(cost.get("food", 0)) > 0: parts.append("谷%d" % int(cost["food"]))
	return " ".join(parts)


func _upgrade_selected_building() -> void:
	if not GameState.start_building_upgrade(selected_building_instance):
		building_action_status.text = "资源不足、建筑满级或当前无法升级"
		return
	building_action_status.text = "建筑升级已经开始"
	SaveManager.save_game()


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
	var sect_multiplier := GameState.get_sect_production_multiplier()
	var total_rate := float(selected_resource["rate"]) * multiplier * sect_multiplier * workforce_power
	assignment_status.text = "已分配 %d 人 · 空闲 %d 人" % [workers, GameState.get_idle_disciples()]
	production_status.text = "%s +%.1f/分钟 · 建筑 +%.0f%% · 境界 +%.0f%% · 宗门 +%.0f%%" % [
		selected_resource["resource_name"],
		total_rate,
		(building_multiplier - 1.0) * 100.0,
		realm_bonus,
		(sect_multiplier - 1.0) * 100.0,
	]
	if sustenance_multiplier < 1.0:
		production_status.text += " · 缺粮效率50%"


func _get_food_production_per_minute() -> float:
	return GameState.get_resource_income_per_minute(&"food")


func _navigate_sidebar(target: Control) -> void:
	if management_sidebar.visible and current_sidebar_target == target:
		_close_management_panel()
		return
	_open_management_panel(target)


func _open_management_panel(target: Control = null) -> void:
	if is_instance_valid(fixed_site_card):
		fixed_site_card.hide()
	building_card.hide()
	var module_name := "宗门"
	if target == management_heading:
		module_name = "建设"
	elif target == disciples_heading:
		module_name = "弟子"
	elif target == growth_heading:
		module_name = "养成"
	elif target == battle_heading:
		module_name = "挂机"
	var info := sidebar_scroll.get_node("Info")
	for section: Control in info.get_children():
		section.visible = String(section.name) in MANAGEMENT_SECTIONS[module_name]
	# 地图详情只进入对应分类，避免建设页混入资源派遣或宗门页混入建筑操作。
	info.get_node("SelectionSection").visible = (
		(module_name == "建设" and selected_building_instance > 0)
		or (module_name == "宗门" and not selected_resource.is_empty())
	)
	management_sidebar.get_node("PanelTitle").text = module_name + "管理"
	management_sidebar.visible = true
	for button: Button in [open_sect_panel_button, open_build_panel_button, open_disciples_panel_button, open_growth_panel_button, open_battle_panel_button]:
		button.active = button.caption == module_name
		if button.active:
			button.grab_focus()
	close_management_button.visible = true
	current_sidebar_target = target if is_instance_valid(target) else sect_heading
	sidebar_scroll.scroll_vertical = 0
	call_deferred("_ensure_sidebar_target_visible", current_sidebar_target)


func _ensure_sidebar_target_visible(_target: Control) -> void:
	# 容器显隐会延后更新高度；分类切换后从顶部开始，不能沿用上一页的滚动位置。
	await get_tree().process_frame
	await get_tree().process_frame
	if management_sidebar.visible:
		sidebar_scroll.scroll_vertical = 0


func _request_close_management_panel() -> void:
	get_viewport().set_input_as_handled()
	call_deferred("_close_management_panel")


func _close_management_panel() -> void:
	management_sidebar.visible = false
	for button: Button in [open_sect_panel_button, open_build_panel_button, open_disciples_panel_button, open_growth_panel_button, open_battle_panel_button]:
		button.active = false
	close_management_button.visible = false
	current_sidebar_target = null
	open_sect_panel_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_instance_valid(fixed_site_card) and fixed_site_card.visible:
		fixed_site_card.hide()
		sect_map.clear_selection()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and building_card.visible:
		_dismiss_building_card()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and management_sidebar.visible:
		_close_management_panel()
		get_viewport().set_input_as_handled()


func _format_resource_gaps(gaps: Dictionary) -> String:
	var parts := PackedStringArray()
	if int(gaps.get("wood", 0)) > 0: parts.append("木材还差%d" % int(gaps["wood"]))
	if int(gaps.get("spirit_stone", 0)) > 0: parts.append("灵石还差%d" % int(gaps["spirit_stone"]))
	if int(gaps.get("food", 0)) > 0: parts.append("灵谷还差%d" % int(gaps["food"]))
	return "资源已满足" if parts.is_empty() else "、".join(parts)


func _refresh_development_goal() -> void:
	if not is_instance_valid(goal_status):
		return
	var goal_id := GameState.get_current_development_goal_id()
	var flow_text := "资源流：木材%+.1f/分 · 灵石%+.1f/分 · 灵谷净%+.1f/分" % [
		GameState.get_resource_net_per_minute(&"wood"),
		GameState.get_resource_net_per_minute(&"spirit_stone"),
		GameState.get_resource_net_per_minute(&"food"),
	]
	if goal_id == &"":
		goal_status.text = "V0.7宗门发展目标已全部完成"
		goal_resource_feedback.text = "%s\n已领取 %d/%d 项一次性奖励" % [flow_text, GameState.claimed_development_goals.size(), DevelopmentGoalCatalogData.GOAL_IDS.size()]
		claim_goal_button.text = "全部目标已完成"
		claim_goal_button.disabled = true
		return
	var goal := DevelopmentGoalCatalogData.get_data(goal_id)
	var progress := GameState.get_development_goal_progress(goal_id)
	goal_status.text = "当前目标：%s\n%s（%d/%d）\n奖励：%s" % [
		goal["name"], goal["description"], int(progress.get("current", 0)), int(progress.get("target", 1)),
		DevelopmentGoalCatalogData.get_reward_text(goal_id),
	]
	goal_resource_feedback.text = "%s\n%s" % [flow_text, _format_resource_gaps(progress.get("resource_gaps", {}))]
	claim_goal_button.text = "领取目标奖励" if bool(progress.get("complete", false)) else "目标尚未完成"
	claim_goal_button.disabled = not GameState.can_claim_development_goal(goal_id)


func _claim_current_development_goal() -> void:
	var goal_id := GameState.get_current_development_goal_id()
	var rollback := GameState.export_save_data()
	if goal_id == &"" or not GameState.claim_development_goal(goal_id):
		_refresh_development_goal()
		return
	if not SaveManager.save_game():
		GameState.import_save_data(rollback)
		_refresh_development_goal()
		goal_resource_feedback.text = "目标奖励保存失败，领取状态与资源已恢复"
		return
	_refresh_development_goal()


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
			5: include = job == &"combat"
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
	_refresh_equipment_panel()
	_refresh_battle()


func _on_core_character_selected(_index: int) -> void:
	_refresh_core_character_preview()


func _refresh_core_character_preview() -> void:
	if not is_instance_valid(core_character_selector) or CORE_CHARACTER_MODELS.is_empty():
		return
	var index := clampi(core_character_selector.selected, 0, CORE_CHARACTER_MODELS.size() - 1)
	var model: Dictionary = CORE_CHARACTER_MODELS[index]
	core_character_preview.texture = model["texture"]
	core_character_caption.text = "%s · %s\n%s\nV0.8仅接入视觉模型，不新增角色数据" % [
		model["name"], model["title"], model["summary"],
	]


func _refresh_disciple_detail() -> void:
	var disciple := GameState.get_disciple(selected_disciple_id)
	if disciple.is_empty():
		disciple_detail.text = "暂无弟子"
		breakthrough_button.disabled = true
		disciple_job_selector.disabled = true
		cultivation_progress.value = 0.0
		_refresh_equipment_panel()
		return
	disciple_job_selector.disabled = false
	var realm_level := int(disciple.get("realm_level", 1))
	var cultivation := float(disciple.get("cultivation", 0.0))
	var gathering_bonus := float(realm_level - 1) * GameState.REALM_GATHERING_BONUS_PER_LEVEL * 100.0
	if realm_level >= GameState.REALM_MAX_LEVEL:
		cultivation_progress.max_value = 1.0
		cultivation_progress.value = 1.0
		disciple_detail.text = "姓名：%s\n境界：%s　职业：%s\n修为：%.1f　岗位：%s\n个人采集效率：+%.0f%%" % [
			disciple.get("name", "无名弟子"), GameState.get_realm_name(realm_level), ProfessionCatalogData.get_display_name(StringName(disciple.get("profession", ""))), cultivation,
			GameState.get_disciple_job_text(StringName(disciple.get("job", "idle"))), gathering_bonus,
		]
		breakthrough_button.text = "已达炼气九层"
	else:
		var requirement := GameState.get_breakthrough_requirement(realm_level)
		cultivation_progress.max_value = requirement
		cultivation_progress.value = cultivation
		disciple_detail.text = "姓名：%s\n境界：%s　职业：%s\n修为：%.1f / %.0f　岗位：%s\n个人采集效率：+%.0f%%" % [
			disciple.get("name", "无名弟子"), GameState.get_realm_name(realm_level), ProfessionCatalogData.get_display_name(StringName(disciple.get("profession", ""))), cultivation, requirement,
			GameState.get_disciple_job_text(StringName(disciple.get("job", "idle"))), gathering_bonus,
		]
		breakthrough_button.text = "突破至%s" % GameState.get_realm_name(realm_level + 1)
	breakthrough_button.disabled = not GameState.can_breakthrough(selected_disciple_id)
	var current_job := StringName(disciple.get("job", "idle"))
	for index: int in range(disciple_job_selector.item_count):
		var job := StringName(disciple_job_selector.get_item_metadata(index))
		disciple_job_selector.set_item_disabled(index, job == &"training" and current_job != &"training" and GameState.training_disciples >= GameState.get_training_capacity())
		if job == &"combat":
			disciple_job_selector.set_item_disabled(index, current_job != &"combat" and GameState.battle_party.size() >= BattleCatalogData.MAX_PARTY_SIZE)
		if job == current_job:
			disciple_job_selector.select(index)
	_refresh_equipment_panel()


func _get_selected_equipment_slot() -> StringName:
	var index := equipment_slot_selector.selected
	if index < 0 or index >= equipment_slot_selector.item_count:
		return &"weapon"
	return StringName(equipment_slot_selector.get_item_metadata(index))


func _format_equipment_stats(stats: Dictionary) -> String:
	return "生命%+.0f 攻击%+.0f 防御%+.0f" % [
		float(stats.get("hp", 0.0)), float(stats.get("attack", 0.0)), float(stats.get("defense", 0.0)),
	]


func _refresh_equipment_panel() -> void:
	if not is_instance_valid(equipment_stats) or not is_instance_valid(equipment_inventory_selector):
		return
	var disciple := GameState.get_disciple(selected_disciple_id)
	if disciple.is_empty():
		equipment_stats.text = "请选择弟子查看职业与装备属性"
		equipment_inventory_selector.clear()
		equipment_inventory_selector.add_item("暂无可管理装备")
		equipment_inventory_selector.set_item_metadata(0, 0)
		equip_button.disabled = true
		unequip_button.disabled = true
		return
	var stats := GameState.get_disciple_battle_stats(selected_disciple_id)
	var profession_name := ProfessionCatalogData.get_display_name(StringName(disciple.get("profession", "")))
	var equipped: Dictionary = disciple.get("equipment", {})
	var equipment_names := PackedStringArray()
	for slot: StringName in GameState.EQUIPMENT_SLOT_IDS:
		var item := GameState.get_equipment_instance(int(equipped.get(String(slot), 0)))
		equipment_names.append("%s：%s" % [EquipmentCatalogData.SLOTS[String(slot)], EquipmentCatalogData.get_display_name(item) if not item.is_empty() else "未装备"])
	equipment_stats.text = "职业：%s　装备库存：%d/%d\n境界基础　%s\n职业修正后　%s\n装备加成　%s\n最终属性　生命%.0f　攻击%.0f　防御%.0f\n当前穿戴\n%s" % [
		profession_name, GameState.equipment_inventory.size(), GameState.MAX_EQUIPMENT_INVENTORY,
		_format_equipment_stats(stats.get("realm_stats", {})), _format_equipment_stats(stats.get("profession_stats", {})),
		_format_equipment_stats(stats.get("equipment_bonus", {})), stats.get("hp", 0.0), stats.get("attack", 0.0), stats.get("defense", 0.0),
		"\n".join(equipment_names),
	]
	var selected_slot := _get_selected_equipment_slot()
	var current_id := int(equipped.get(String(selected_slot), 0))
	equipment_inventory_selector.clear()
	for item: Dictionary in GameState.equipment_inventory:
		if StringName(item.get("slot", "")) != selected_slot:
			continue
		var owner_id := GameState.get_equipment_owner(int(item.get("id", 0)))
		if owner_id != 0 and owner_id != selected_disciple_id:
			continue
		var label := "%s · %s%s" % [EquipmentCatalogData.get_display_name(item), _format_equipment_stats(item.get("stats", {})), "（已装备）" if int(item.get("id", 0)) == current_id else ""]
		equipment_inventory_selector.add_item(label)
		equipment_inventory_selector.set_item_metadata(equipment_inventory_selector.item_count - 1, int(item.get("id", 0)))
	if equipment_inventory_selector.item_count == 0:
		equipment_inventory_selector.add_item("该部位暂无可用装备")
		equipment_inventory_selector.set_item_metadata(0, 0)
	var selected_item_id := int(equipment_inventory_selector.get_item_metadata(equipment_inventory_selector.selected))
	equip_button.disabled = selected_item_id <= 0 or selected_item_id == current_id
	unequip_button.disabled = current_id <= 0
	_refresh_crafting_panel()


func _get_selected_crafting_template() -> StringName:
	if craft_template_selector.selected < 0 or craft_template_selector.selected >= craft_template_selector.item_count:
		return &""
	return StringName(craft_template_selector.get_item_metadata(craft_template_selector.selected))


func _get_selected_crafting_quality() -> StringName:
	if craft_quality_selector.selected < 0 or craft_quality_selector.selected >= craft_quality_selector.item_count:
		return &""
	return StringName(craft_quality_selector.get_item_metadata(craft_quality_selector.selected))


func _refresh_crafting_panel() -> void:
	if not is_instance_valid(crafting_status) or not is_instance_valid(craft_button):
		return
	var template_id := _get_selected_crafting_template()
	var quality := _get_selected_crafting_quality()
	var recipe := GameState.get_equipment_crafting_recipe(template_id, quality)
	if recipe.is_empty():
		crafting_status.text = "请选择有效的装备模板与品质"
		craft_button.disabled = true
		return
	var required_level := int(recipe.get("required_forge_level", 1))
	var forge_level := GameState.get_forging_level()
	crafting_status.text = "炼器等级 %d/3 · 需%d级 · %s · 库存%d/%d · 已打造%d件" % [
		forge_level, required_level, EquipmentCraftingCatalogData.get_cost_text(template_id, quality),
		GameState.equipment_inventory.size(), GameState.MAX_EQUIPMENT_INVENTORY, GameState.equipment_crafts_completed,
	]
	craft_button.text = "打造%s" % EquipmentCatalogData.TEMPLATES[String(template_id)]["name"]
	craft_button.disabled = not GameState.can_craft_equipment(template_id, quality)


func _on_crafting_selection_changed(_index: int) -> void:
	_refresh_crafting_panel()


func _craft_selected_equipment() -> void:
	var template_id := _get_selected_crafting_template()
	var quality := _get_selected_crafting_quality()
	var rollback := GameState.export_save_data()
	var instance_id := GameState.craft_equipment(template_id, quality)
	if instance_id <= 0:
		_refresh_crafting_panel()
		crafting_status.text = "无法打造：请检查炼器等级、资源和库存空间"
		return
	if not SaveManager.save_game():
		GameState.import_save_data(rollback)
		_refresh_crafting_panel()
		crafting_status.text = "打造存档失败，装备与资源已恢复"
		crafting_status.modulate = Color(0.9, 0.55, 0.42)
		return
	var equipment := GameState.get_equipment_instance(instance_id)
	_refresh_equipment_panel()
	crafting_status.text = "%s打造完成并已保存" % EquipmentCatalogData.get_display_name(equipment)
	crafting_status.modulate = Color(0.55, 0.85, 0.62)


func _on_equipment_slot_selected(_index: int) -> void:
	equipment_status.text = ""
	_refresh_equipment_panel()


func _on_equipment_inventory_selected(_index: int) -> void:
	_refresh_equipment_panel()


func _equip_selected_item() -> void:
	if selected_disciple_id <= 0 or equipment_inventory_selector.selected < 0:
		return
	var instance_id := int(equipment_inventory_selector.get_item_metadata(equipment_inventory_selector.selected))
	if instance_id > 0 and GameState.equip_item(selected_disciple_id, instance_id):
		equipment_status.text = "装备已穿戴并保存"
		equipment_status.modulate = Color(0.55, 0.85, 0.62)
		SaveManager.save_game()
	else:
		equipment_status.text = "无法穿戴：装备可能已被其他弟子占用"
		equipment_status.modulate = Color(0.9, 0.55, 0.42)
	_refresh_equipment_panel()


func _unequip_selected_item() -> void:
	if selected_disciple_id > 0 and GameState.unequip_item(selected_disciple_id, _get_selected_equipment_slot()):
		equipment_status.text = "装备已卸下并保存"
		equipment_status.modulate = Color(0.55, 0.85, 0.62)
		SaveManager.save_game()
	_refresh_equipment_panel()


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
		disciple_job_status.text = "无法调整岗位：修炼位或战斗队伍名额不足"
		disciple_job_status.modulate = Color(0.9, 0.55, 0.42)
		_refresh_disciple_detail()


func _breakthrough_selected_disciple() -> void:
	if GameState.breakthrough_disciple(selected_disciple_id):
		_refresh_disciple_roster()
		SaveManager.save_game()


func _refresh_sect_progress() -> void:
	var prosperity := GameState.get_sect_prosperity()
	var bonus := float(GameState.sect_level - 1) * GameState.SECT_PRODUCTION_BONUS_PER_LEVEL * 100.0
	if GameState.sect_level >= GameState.MAX_SECT_LEVEL:
		sect_level_status.text = "青云宗 等级%d · 繁荣%d · 采集+%.0f%%" % [GameState.sect_level, prosperity, bonus]
		sect_progress.max_value = 1.0
		sect_progress.value = 1.0
		sect_upgrade_button.text = "宗门已达当前最高等级"
		sect_upgrade_button.disabled = true
		return
	var requirement := GameState.get_next_sect_level_requirement()
	sect_level_status.text = "青云宗 等级%d · 繁荣%d/%d · 采集+%.0f%%" % [GameState.sect_level, prosperity, requirement, bonus]
	sect_progress.max_value = requirement
	sect_progress.value = prosperity
	sect_upgrade_button.text = "晋升宗门至等级%d" % (GameState.sect_level + 1)
	sect_upgrade_button.disabled = not GameState.can_upgrade_sect()


func _refresh_territory() -> void:
	if not is_instance_valid(territory_status) or not is_instance_valid(territory_unlock_button):
		return
	var unlocked_cells := 0
	var unlocked_names := PackedStringArray()
	for region_id: StringName in TerritoryCatalogData.REGION_IDS:
		if String(region_id) not in GameState.unlocked_regions:
			continue
		var region := TerritoryCatalogData.get_data(region_id)
		var region_size: Vector2i = region["size"]
		unlocked_cells += region_size.x * region_size.y
		unlocked_names.append(str(region["name"]))
	var next_region := GameState.get_next_locked_region()
	if next_region == &"":
		territory_status.text = "领地：%s · 已解锁全部 %d/%d 格" % ["、".join(unlocked_names), unlocked_cells, TerritoryCatalogData.MAP_SIZE.x * TerritoryCatalogData.MAP_SIZE.y]
		territory_unlock_button.text = "领地已全部开放"
		territory_unlock_button.disabled = true
		return
	var data := TerritoryCatalogData.get_data(next_region)
	var required_level := int(data.get("required_sect_level", 1))
	var cost_text := TerritoryCatalogData.get_cost_text(next_region)
	territory_status.text = "领地：%s · %d/%d格\n下一处：%s · 需宗门%d级 · %s" % [
		"、".join(unlocked_names), unlocked_cells, TerritoryCatalogData.MAP_SIZE.x * TerritoryCatalogData.MAP_SIZE.y,
		data["name"], required_level, cost_text,
	]
	territory_unlock_button.text = "解锁%s（%s）" % [data["name"], cost_text]
	territory_unlock_button.disabled = not GameState.can_unlock_region(next_region)


func _on_region_selected(region_id: StringName) -> void:
	var region := TerritoryCatalogData.get_data(region_id)
	if region.is_empty():
		return
	selected_resource = {}
	selected_building_instance = 0
	_open_management_panel(sect_heading)
	sidebar_scroll.get_node("Info/SelectionSection").show()
	building_actions.visible = false
	assignment_status.visible = false
	production_status.visible = false
	assign_button.visible = false
	unassign_button.visible = false
	selection_name.text = "%s · 尚未解锁" % region["name"]
	var required := StringName(region.get("requires", &""))
	var dependency_text := ""
	if required != &"" and String(required) not in GameState.unlocked_regions:
		dependency_text = "\n需先解锁%s。" % TerritoryCatalogData.get_data(required)["name"]
	selection_description.text = "需要宗门%d级，并消耗%s。%s" % [
		int(region.get("required_sect_level", 1)), TerritoryCatalogData.get_cost_text(region_id), dependency_text,
	]


func _unlock_next_region() -> void:
	var region_id := GameState.get_next_locked_region()
	if region_id == &"":
		return
	var rollback := GameState.export_save_data()
	if not GameState.unlock_region(region_id):
		_refresh_territory()
		_refresh_development_goal()
		return
	if not SaveManager.save_game():
		GameState.import_save_data(rollback)
		territory_status.text = "领地解锁保存失败，资源与领地状态已恢复"
		return
	selection_name.text = "%s · 已解锁" % TerritoryCatalogData.get_data(region_id)["name"]
	selection_description.text = "新的宗门建设区域已经开放。"
	_refresh_territory()


func _upgrade_sect() -> void:
	if GameState.upgrade_sect():
		_refresh_resources()
		_refresh_assignment()
		_refresh_sect_progress()
		_refresh_territory()
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
		var offline_window := SaveManager.get_pending_offline_window()
		var offline_receipt := SaveManager.settle_pending_offline_progress()
		_handle_offline_receipt(offline_window, offline_receipt)
		_refresh_resources()
		_refresh_assignment()
		_refresh_buildings()
		_refresh_recruitment()
		_refresh_battle_stages()
		_refresh_battle()
		_refresh_equipment_panel()
		_refresh_crafting_panel()
		_refresh_territory()


func _handle_offline_receipt(window: Dictionary, receipt: Dictionary) -> void:
	if window.is_empty():
		return
	var reason := str(window.get("reason", ""))
	if reason == "too_short":
		return
	if reason == "missing_anchor":
		offline_summary_dialog.title = "离线结算 · 已建立时间基线"
		offline_summary_text.text = "这是旧版本存档，缺少可靠的离线时间起点。\n本次不追溯发放收益；已从现在开始建立时间基线。"
		offline_summary_dialog.popup_centered()
		SaveManager.save_game()
		return
	if reason == "clock_moved_back":
		offline_summary_dialog.title = "离线结算 · 时间异常"
		offline_summary_text.text = "检测到系统时间早于存档时间。\n为保护存档，本次不计算离线收益。"
		offline_summary_dialog.popup_centered()
		return
	if not bool(receipt.get("success", false)):
		offline_summary_dialog.title = "离线结算 · 未完成"
		offline_summary_text.text = "离线收益结算失败，游戏状态已恢复。\n%s\n稍后可重新读取存档再试。" % str(receipt.get("message", "未知错误"))
		offline_summary_dialog.popup_centered()
		return
	offline_summary_dialog.title = "离线结算 · 收益已入账"
	offline_summary_text.text = _format_offline_receipt(window, receipt)
	offline_summary_dialog.popup_centered()


func _format_offline_receipt(window: Dictionary, receipt: Dictionary) -> String:
	var effective_seconds := int(window.get("effective_seconds", 0))
	var hours := effective_seconds / 3600
	var minutes := (effective_seconds % 3600) / 60
	var duration_text := "%d小时%d分钟" % [hours, minutes] if hours > 0 else "%d分钟" % minutes
	if effective_seconds < 60:
		duration_text = "%d秒" % effective_seconds
	var lines := PackedStringArray(["【离线结算回执】", "离线时长：%s" % duration_text])
	if bool(window.get("truncated", false)):
		lines.append("已达到8小时收益上限（实际离线时间更长）")
	var resource_delta: Dictionary = receipt.get("resources", {})
	lines.append("资源净变化：木材%+d　灵石%+d　灵谷%+d" % [
		int(resource_delta.get("wood", 0)),
		int(resource_delta.get("spirit_stone", 0)),
		int(resource_delta.get("food", 0)),
	])
	lines.append("弟子消耗灵谷：%d" % int(receipt.get("food_consumed", 0)))
	lines.append("演武修为：+%.1f" % float(receipt.get("cultivation_gained", 0.0)))
	lines.append("自动战斗胜利：%d场（%s）" % [int(receipt.get("battle_victories", 0)), _get_offline_battle_reason_text(str(receipt.get("battle_reason", "not_running")))])
	lines.append("获得装备：%s" % GameState.get_equipment_drop_text(receipt.get("equipment_drops", [])))
	lines.append("完成事项：建筑%d　升级%d　招募%d" % [
		int(receipt.get("construction_completed", 0)),
		int(receipt.get("upgrades_completed", 0)),
		int(receipt.get("recruited", 0)),
	])
	return "\n".join(lines)


func _get_offline_battle_reason_text(reason: String) -> String:
	match reason:
		"victory": return "持续挑战"
		"defeat": return "挑战失败并停止"
		"invalid_party": return "队伍异常并停止"
		"waiting": return "仍在重战等待"
		"partial": return "本场尚未结束"
		_: return "未开启自动战斗"


func _join_selected_disciple_to_battle() -> void:
	if selected_disciple_id > 0 and GameState.set_disciple_job(selected_disciple_id, &"combat"):
		SaveManager.save_game()
	else:
		battle_status.text = "无法入队：请选择弟子或先腾出队伍名额"


func _remove_selected_disciple_from_battle() -> void:
	var disciple := GameState.get_disciple(selected_disciple_id)
	if not disciple.is_empty() and StringName(disciple.get("job", "idle")) == &"combat" and GameState.set_disciple_job(selected_disciple_id, &"idle"):
		SaveManager.save_game()


func _refresh_battle_stages() -> void:
	var previous_stage := GameState.selected_battle_stage
	battle_stage_selector.clear()
	for stage_id: int in range(1, BattleCatalogData.get_stage_count() + 1):
		var stage: Dictionary = BattleCatalogData.get_stage(stage_id)
		var unlocked := stage_id <= GameState.highest_unlocked_stage
		var label := "%d. %s · %s" % [stage_id, stage["name"], BattleCatalogData.get_reward_text(stage_id)]
		if not unlocked:
			label += "（未解锁）"
		battle_stage_selector.add_item(label)
		battle_stage_selector.set_item_metadata(stage_id - 1, stage_id)
		battle_stage_selector.set_item_disabled(stage_id - 1, not unlocked)
	battle_stage_selector.select(clampi(previous_stage - 1, 0, battle_stage_selector.item_count - 1))


func _on_battle_stage_selected(index: int) -> void:
	if index < 0 or index >= battle_stage_selector.item_count:
		return
	if GameState.select_battle_stage(int(battle_stage_selector.get_item_metadata(index))):
		_refresh_battle()
		SaveManager.save_game()


func _toggle_battle() -> void:
	if GameState.auto_battle_enabled:
		GameState.stop_auto_battle()
	else:
		GameState.start_auto_battle()
	SaveManager.save_game()


func _refresh_battle() -> void:
	var names := PackedStringArray()
	var member_lines := PackedStringArray()
	for disciple_id: int in GameState.battle_party:
		var disciple := GameState.get_disciple(disciple_id)
		if not disciple.is_empty():
			var disciple_name := str(disciple.get("name", "无名弟子"))
			var realm_level := int(disciple.get("realm_level", 1))
			var member_stats := GameState.get_disciple_battle_stats(disciple_id)
			names.append(disciple_name)
			member_lines.append("• %s · 炼气%d层 · 生命%.0f 攻击%.0f 防御%.0f · 参战中" % [
				disciple_name, realm_level, member_stats["hp"], member_stats["attack"], member_stats["defense"],
			])
	battle_party_status.text = "战斗队伍 %d/%d：%s" % [GameState.battle_party.size(), BattleCatalogData.MAX_PARTY_SIZE, "、".join(names) if not names.is_empty() else "尚未编成"]
	battle_party_members.text = "\n".join(member_lines) if not member_lines.is_empty() else "暂无参战弟子；请从弟子名册选择成员入队。"
	var party := GameState.get_battle_party_stats()
	battle_stats.text = "队伍合计：生命%.0f · 攻击%.0f · 防御%.0f · 已胜%d场\n生命为队伍共用，不采用逐人受击。" % [party["hp"], party["attack"], party["defense"], GameState.battle_victories]
	var stage: Dictionary = BattleCatalogData.get_stage(GameState.selected_battle_stage)
	var active_stage_text := "当前未挑战"
	if GameState.get_battle_phase() == &"fighting":
		active_stage_text = "正在挑战 %d.%s" % [GameState.selected_battle_stage, stage["name"]]
	elif GameState.get_battle_phase() == &"repeat_wait":
		active_stage_text = "等待重战 %d.%s" % [GameState.selected_battle_stage, stage["name"]]
	battle_progress_summary.text = "选中关卡 %d.%s · %s\n已解锁 1-%d · 已通关至 %d/%d" % [
		GameState.selected_battle_stage, stage["name"], active_stage_text,
		GameState.highest_unlocked_stage, GameState.highest_cleared_stage, BattleCatalogData.get_stage_count(),
	]
	enemy_battle_info.text = "敌方：%s · 生命%.0f · 攻击%.0f · 防御%.0f\n胜利奖励：%s" % [
		stage["enemy"], stage["hp"], stage["attack"], stage["defense"],
		BattleCatalogData.get_reward_text(GameState.selected_battle_stage),
	]
	player_battle_hp.max_value = maxf(1.0, GameState.battle_player_max_hp)
	player_battle_hp.value = GameState.battle_player_hp
	enemy_battle_hp.max_value = maxf(1.0, GameState.battle_enemy_max_hp)
	enemy_battle_hp.value = GameState.battle_enemy_hp
	player_battle_hp_text.text = "我方共用生命：%.0f / %.0f" % [GameState.battle_player_hp, GameState.battle_player_max_hp]
	enemy_battle_hp_text.text = "敌方生命：%.0f / %.0f" % [GameState.battle_enemy_hp, GameState.battle_enemy_max_hp]
	player_battle_hp.tooltip_text = "我方生命 %.0f / %.0f" % [GameState.battle_player_hp, GameState.battle_player_max_hp]
	enemy_battle_hp.tooltip_text = "敌方生命 %.0f / %.0f" % [GameState.battle_enemy_hp, GameState.battle_enemy_max_hp]
	battle_status.text = GameState.battle_message
	var battle_phase := GameState.get_battle_phase()
	match battle_phase:
		&"fighting":
			battle_status.text = "【交战中】%s" % GameState.battle_message
			battle_status.modulate = Color("e5bd68")
		&"repeat_wait":
			battle_status.text = "【整备中】%s" % GameState.battle_message
			battle_status.modulate = Color("8fc7b0")
		_:
			battle_status.text = "【待命】%s" % GameState.battle_message
			battle_status.modulate = Color("b8c2b8")
	battle_log_label.text = "当前战报\n" + ("\n".join(GameState.battle_log) if not GameState.battle_log.is_empty() else "暂无战斗事件")
	if GameState.last_battle_result.is_empty():
		last_battle_result_label.text = "上一场结果：暂无"
		last_battle_result_label.modulate = Color("aab4aa")
	else:
		var result_text := str(GameState.last_battle_result.get("result", "未知"))
		last_battle_result_label.text = "上一场结果：%s · 关卡%d · 奖励%s" % [result_text, GameState.last_battle_result.get("stage_id", 0), GameState.last_battle_result.get("reward_text", "无")]
		last_battle_result_label.modulate = Color("83c69c") if "胜" in result_text else Color("d98f83")
	battle_toggle_button.text = "停止自动战斗" if GameState.auto_battle_enabled else "开始自动战斗"
	battle_toggle_button.disabled = GameState.battle_party.is_empty()
	battle_stage_selector.disabled = GameState.battle_running
	var selected := GameState.get_disciple(selected_disciple_id)
	var selected_in_party := not selected.is_empty() and StringName(selected.get("job", "idle")) == &"combat"
	join_battle_button.disabled = selected.is_empty() or selected_in_party or GameState.battle_party.size() >= BattleCatalogData.MAX_PARTY_SIZE
	leave_battle_button.disabled = not selected_in_party


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
	if sect_map.fixed_layout:
		_open_fixed_site(building_id)
		return
	building_card.hide()
	_close_management_panel()
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
	if sect_map.fixed_layout:
		placement_status.text = "固定院落模式，请选择院落建设"
		return
	if GameState.start_construction(building_id, cell):
		var definition := BuildingCatalog.get_data(building_id)
		placement_status.text = "%s开始施工（%.0f秒）" % [definition["name"], definition["build_time"]]
		selected_building = &""
		sect_map.cancel_placement()
		cancel_build_button.disabled = true
		SaveManager.save_game()
	else:
		placement_status.text = "无法在这里建造"


func _open_fixed_site(kind: StringName) -> void:
	if not sect_map.fixed_layout or BuildingCatalog.get_data(kind).is_empty():
		return
	building_card.hide()
	# 定时刷新不能重复关闭已关闭的抽屉，否则会把列表键盘焦点抢回底栏。
	if management_sidebar.visible:
		_close_management_panel()
	sect_map.fixed_selected_kind = kind
	sect_map.queue_redraw()
	fixed_site_card.show_site(kind, GameState, _get_building_total_effect_text(kind))
	var frame: Dictionary = sect_map.FixedView.site_frame(sect_map, kind)
	var offset: Vector2 = sect_map.global_position - global_position
	var rect: Rect2 = frame["rect"]
	var nav_top: float = $Layout/Body/BottomNav.global_position.y - global_position.y
	fixed_site_card.place_near(Rect2(rect.position + offset, rect.size), Rect2(Vector2(24, 104), Vector2(size.x - 48, nav_top - 120)))
	if sect_map.complete_sect:
		preload("res://scripts/ui/complete_sect_hud.gd").dock_card(self, fixed_site_card)


func _construct_fixed_site(kind: StringName) -> void:
	if not sect_map.fixed_layout:
		return
	var snapshot := GameState.export_save_data().duplicate(true)
	if not preload("res://scripts/world/fixed_sect_layout.gd").construct(GameState, kind):
		placement_status.text = "资源不足或宗门建设容量已满"
		return
	if not SaveManager.save_game():
		GameState.import_save_data(snapshot)
		placement_status.text = "保存失败，本次建设已撤回，资源未消耗"
	else:
		placement_status.text = "%s院落开始施工" % BuildingCatalog.get_data(kind)["name"]
	_open_fixed_site(kind)


func _select_fixed_instance(instance_id: int) -> void:
	var building := GameState.get_building(instance_id)
	if not building.is_empty():
		fixed_site_card.hide()
		_on_building_selected(building)


func _refresh_buildings() -> void:
	sect_map.queue_redraw()
	_refresh_assignment()
	_refresh_recruitment()
	_refresh_selected_building()
	_refresh_crafting_panel()
	var constructing := 0
	if is_instance_valid(fixed_site_card) and fixed_site_card.visible:
		_open_fixed_site(fixed_site_card.site_kind)
	var upgrading := 0
	for building: Dictionary in GameState.buildings:
		if not bool(building["completed"]):
			constructing += 1
		elif bool(building.get("upgrading", false)):
			upgrading += 1
	if constructing > 0 and selected_building == &"":
		placement_status.text = "施工中：%d 座建筑" % constructing
	elif upgrading > 0 and selected_building == &"":
		placement_status.text = "升级中：%d 座建筑" % upgrading



func _on_hall_selected() -> void:
	if sect_map.fixed_layout:
		sect_map.fixed_selected_kind = &"hall"
	if is_instance_valid(fixed_site_card):
		fixed_site_card.hide()
	sect_map.selected_cell = sect_map.MAIN_HALL_CELL
	sect_map.queue_redraw()
	_close_management_panel()
	card_is_hall = true
	selected_building_instance = 0
	building_card.show()
	_refresh_building_card()


func _dismiss_building_card() -> void:
	building_card.hide()
	sect_map.clear_selection()


func _manage_card_selection() -> void:
	_open_management_panel(sect_heading if card_is_hall else management_heading)


func _upgrade_card_selection() -> void:
	if card_is_hall:
		_upgrade_sect()
	else:
		_upgrade_selected_building()
	_refresh_building_card()


func _refresh_building_card() -> void:
	if not is_instance_valid(building_card) or not building_card.visible:
		return
	var building_visual_rect: Rect2 = sect_map.get_hall_ground_frame(sect_map._map_origin())["rect"]
	if card_is_hall:
		building_card.title_label.text = "宗门主殿 · Lv.%d" % GameState.sect_level
		building_card.status_label.text = sect_level_status.text + "\n固定主殿 · 宗门事务请进入详细管理"
		building_card.upgrade_button.text = "晋升宗门"
		building_card.upgrade_button.disabled = not GameState.can_upgrade_sect()
	else:
		var building: Dictionary = GameState.get_building(selected_building_instance)
		if building.is_empty():
			_dismiss_building_card()
			return
		var kind := StringName(building["type"])
		building_visual_rect = sect_map.get_building_visual_rect(building, sect_map._map_origin())
		building_card.title_label.text = "%s · Lv.%d" % [BuildingCatalog.get_data(kind)["name"], int(building["level"])]
		var status := "已完工"
		if not bool(building["completed"]):
			status = "施工中 · %.1f秒" % float(building["remaining"])
		elif bool(building.get("upgrading", false)):
			status = "升级中 · %.1f秒" % float(building["upgrade_remaining"])
		building_card.status_label.text = status + "\n" + _get_building_total_effect_text(kind)
		building_card.upgrade_button.text = upgrade_button.text
		building_card.upgrade_button.disabled = not GameState.can_upgrade_building(selected_building_instance)
	var map_offset: Vector2 = sect_map.global_position - global_position
	var visual_rect := Rect2(building_visual_rect.position + map_offset, building_visual_rect.size)
	var nav_top: float = $Layout/Body/BottomNav.global_position.y - global_position.y
	building_card.place_near(visual_rect, Rect2(Vector2(24, 104), Vector2(size.x - 48, nav_top - 120)))
	if sect_map.complete_sect:
		preload("res://scripts/ui/complete_sect_hud.gd").dock_card(self, building_card)
