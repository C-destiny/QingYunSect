extends RefCounted
static func empty() -> Dictionary:
	return {"sequence":0,"settled":0,"wins":0,"pending_weapon":0,"active":{}}
static func valid(raw: Variant, state: Node) -> bool:
	if not raw is Dictionary:
		return false
	for key: String in ["sequence","settled","wins","pending_weapon"]:
		if not raw.has(key) or typeof(raw[key]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(raw[key])) or float(raw[key]) != floor(float(raw[key])) or float(raw[key]) < 0 or float(raw[key]) > 1000000000:
			return false
	if int(raw["wins"]) > int(raw["settled"]) or int(raw["pending_weapon"]) > mini(1,int(raw["wins"])) or not raw.get("active") is Dictionary:
		return false
	var a: Dictionary = raw["active"]
	if a.is_empty():
		return int(raw["sequence"]) == int(raw["settled"])
	if state.auto_battle_enabled or state.battle_running:
		return false
	for key: String in ["id","disciple_id","kills","elapsed"]:
		if not a.has(key) or typeof(a[key]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(a[key])):
			return false
	if float(a["kills"]) != floor(float(a["kills"])) or float(a["id"]) != floor(float(a["id"])) or float(a["disciple_id"]) != floor(float(a["disciple_id"])):
		return false
	var disciple: Dictionary = state.get_disciple(int(a["disciple_id"]))
	return int(a["id"]) == int(raw["sequence"]) and int(raw["sequence"]) == int(raw["settled"])+1 and not disciple.is_empty() and disciple.get("job") == "idle" and float(a["kills"]) >= 0 and float(a["kills"]) <= 500 and float(a["elapsed"]) >= 0 and float(a["elapsed"]) <= 600
