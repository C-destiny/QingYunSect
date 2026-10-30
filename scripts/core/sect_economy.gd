extends RefCounted

# Read-only projections. Production, costs, jobs and persistence stay in the existing state.
const BuildingData = preload("res://scripts/data/building_catalog.gd")
const CraftingData = preload("res://scripts/data/equipment_crafting_catalog.gd")
const RESOURCE_INFO := {
	"wood": {"name": "木材", "use": "建设、升级与装备打造"},
	"spirit_stone": {"name": "灵石", "use": "建设、招募、打造、制丹与功法学习"},
	"food": {"name": "灵谷", "use": "弟子口粮、招募、打造与制丹"},
}

static func overview(state: Node) -> Dictionary:
	var rows := {}
	var hungry: bool = state.get_sustenance_multiplier() < 1.0
	for id: String in RESOURCE_INFO:
		var amount: int = state.get_resource_amount(StringName(id))
		var income: float = state.get_resource_income_per_minute(StringName(id))
		var consumption: float = state.get_food_consumption_per_minute() if id == "food" else 0.0
		var net: float = state.get_resource_net_per_minute(StringName(id))
		var minutes := float(amount) / -net if net < 0.0 else -1.0
		var status := "surplus" if net > 0.0 else ("deficit" if net < 0.0 else "balanced")
		if id == "food":
			if hungry:
				status = "hungry"
			elif minutes >= 0.0 and minutes <= 30.0:
				status = "warning"
		rows[id] = {"amount": amount, "income": income, "consumption": consumption, "net": net,
			"minutes": minutes, "status": status, "name": RESOURCE_INFO[id]["name"], "use": RESOURCE_INFO[id]["use"]}
	return {"rows": rows, "hungry": hungry}

static func estimate_cost(state: Node, cost: Dictionary) -> Dictionary:
	var gaps := {}
	var minutes := 0.0
	var blocked := false
	for id: String in RESOURCE_INFO:
		var gap: int = maxi(0, int(cost.get(id, 0)) - state.get_resource_amount(StringName(id)))
		if gap == 0:
			continue
		gaps[id] = gap
		var net: float = state.get_resource_net_per_minute(StringName(id))
		if net <= 0.0:
			blocked = true
		else:
			minutes = maxf(minutes, float(gap) / net)
	return {"gaps": gaps, "minutes": -1.0 if blocked else minutes}

static func cost_hint(state: Node, cost: Dictionary) -> String:
	var estimate := estimate_cost(state, cost)
	var parts := PackedStringArray()
	for id: String in estimate["gaps"]:
		parts.append("%s%d" % [RESOURCE_INFO[id]["name"], int(estimate["gaps"][id])])
	if parts.is_empty():
		return "资源已足够；请主动确认操作"
	var text := "还差：" + "、".join(parts)
	if float(estimate["minutes"]) < 0.0:
		return text + "；缺口资源无正净产出，先调整岗位"
	return text + "；按当前净产出约需%.1f分钟（期间不支出且岗位、粮食状态不变）" % float(estimate["minutes"])

static func _step(id: String, title: String, body: String, action: String, target: String = "") -> Dictionary:
	return {"id": id, "title": title, "body": body, "action": action, "target": target}

static func _site_step(state: Node, id: String, title: String, body: String, site: String, needs_more_workers: bool = false) -> Dictionary:
	if state.total_disciples <= state.assigned_disciples and (state.get_assignment(StringName(site)) == 0 or needs_more_workers):
		return _step(id, title, body + "没有空闲弟子，请在名册将一人从其他岗位调来。", "disciples")
	return _step(id, title, body, "site", site)

static func _building_step(state: Node, kind: StringName, title: String) -> Dictionary:
	var data: Dictionary = BuildingData.get_data(kind)
	for building: Dictionary in state.buildings:
		if StringName(building["type"]) == kind and not bool(building["completed"]):
			return _step(String(kind), title, "%s施工中，等待完工；不必重复建造。" % data["name"], "build_menu")
	return _step(String(kind), title, cost_hint(state, data["cost"]), "build", String(kind))

static func guidance(state: Node) -> Dictionary:
	var report := overview(state)
	var food: Dictionary = report["rows"]["food"]
	if report["hungry"] or float(food["net"]) <= 0.0:
		var body := "派普通弟子到现有灵谷资源点，先保证口粮净增长；不必先建灵田。"
		if report["hungry"]:
			body = "缺粮：生产效率为50%。" + ("已有粮食生产，继续生产可恢复，也可调更多人种粮。" if float(food["net"]) > 0.0 else body)
		return _site_step(state, "food", "先稳定粮食", body, "field", float(food["net"]) <= 0.0)
	for site: StringName in [&"forest", &"mine"]:
		if state.get_assignment(site) == 0:
			return _site_step(state, String(site), "建立基础生产", "安排普通弟子采集木材和灵石；三种基础资源均可直接分配岗位。", String(site))
	if state.total_disciples - state.assigned_disciples > 0:
		return _step("idle", "安排闲置弟子", "尚有空闲人手，可补充采集；如有演武场，也可在名册安排修炼。", "disciples")
	if state.get_completed_building_count(&"disciple_quarters") == 0:
		return _building_step(state, &"disciple_quarters", "扩充居住容量")
	if state.total_disciples < 4:
		if state.is_recruiting():
			return _step("recruit", "等待弟子入门", "招募已开始，完成后再安排岗位。", "disciples")
		return _step("recruit", "补充宗门人手", cost_hint(state, state.RECRUIT_COST), "disciples")
	if state.get_training_capacity() == 0:
		return _building_step(state, &"training_ground", "建立修炼条件")
	var trained := false
	for disciple: Dictionary in state.disciples:
		if int(disciple["realm_level"]) >= 3:
			trained = true
	if not trained and state.training_disciples == 0:
		return _step("training", "验证修炼与突破", "选择一名普通弟子安排修炼，修为足够时突破至炼气三层。保留粮食生产；当前先用普通弟子培养。", "disciples")
	if state.get_forging_level() == 0:
		return _building_step(state, &"artifact_forge", "准备装备打造")
	if state.equipment_crafts_completed == 0:
		return _step("craft", "打造第一件装备", cost_hint(state, CraftingData.get_recipe(&"initiate_weapon", &"common")["cost"]), "growth")
	var body := "生产、修炼与打造已接通，可检查现有装备。"
	if not trained:
		body += "修炼可以并行推进，修为足够再突破，不必停工等待。"
	body += "核心弟子和主动副本仍在后续阶段，旧挂机不等于主动副本。"
	return _step("prepared", "基础发展准备完成", body, "growth")
