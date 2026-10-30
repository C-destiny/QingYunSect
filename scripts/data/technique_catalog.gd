extends RefCounted
const COST := 20
const ITEMS := {
	"edge": {"name":"简剑诀（试制）", "effect":"攻击+3", "hp":0.0, "attack":3.0},
	"guard": {"name":"守元诀（试制）", "effect":"生命+30", "hp":30.0, "attack":0.0}
}
static func valid(value: Variant, state: Node) -> bool:
	if not value is Dictionary:
		return false
	for key: Variant in value:
		if not key is String or key != str(int(key)) or state.get_disciple(int(key)).is_empty():
			return false
		var entry: Variant = value[key]
		if not entry is Dictionary or entry.size() != 2 or not entry.get("learned") is Array or not entry.get("active") is String:
			return false
		var seen := []
		for id: Variant in entry["learned"]:
			if not id is String or not ITEMS.has(id) or id in seen:
				return false
			seen.append(id)
		if entry["active"] != "" and entry["active"] not in seen:
			return false
	return true