extends RefCounted
static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 2:
		return false
	for key: String in ["stock", "remaining"]:
		if not value.has(key) or typeof(value[key]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value[key])):
			return false
	return float(value["stock"]) == floor(float(value["stock"])) and float(value["stock"]) >= 0 and float(value["stock"]) <= 20 and float(value["remaining"]) >= 0 and float(value["remaining"]) <= 60 and (float(value["remaining"]) == 0 or float(value["stock"]) < 20)