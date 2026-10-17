class_name DevelopmentGoalCatalog
extends RefCounted

const GOAL_IDS := [
	&"sect_level_2",
	&"unlock_east",
	&"build_forge",
	&"craft_first_item",
	&"build_library",
	&"raise_disciple",
	&"win_ten_battles",
	&"unlock_south",
]

const GOALS := {
	"sect_level_2": {"name": "初具规模", "description": "将宗门提升到2级", "condition": "sect_level", "target": 2, "reward": {"wood": 40, "spirit_stone": 20, "food": 30}},
	"unlock_east": {"name": "开拓东麓", "description": "解锁东部山麓", "condition": "region", "target": "east", "reward": {"wood": 80, "spirit_stone": 40, "food": 50}},
	"build_forge": {"name": "开炉炼器", "description": "建成至少1级炼器坊", "condition": "building_level", "target": "artifact_forge", "value": 1, "reward": {"wood": 80, "spirit_stone": 60, "food": 40}},
	"craft_first_item": {"name": "宗门法器", "description": "完成第1件装备打造", "condition": "crafts", "target": 1, "reward": {"wood": 100, "spirit_stone": 80, "food": 60}},
	"build_library": {"name": "藏经传承", "description": "建成至少1级藏经阁", "condition": "building_level", "target": "scripture_library", "value": 1, "reward": {"wood": 80, "spirit_stone": 80, "food": 80}},
	"raise_disciple": {"name": "门下有成", "description": "培养1名炼气三层弟子", "condition": "disciple_realm", "target": 3, "reward": {"wood": 120, "spirit_stone": 100, "food": 100}},
	"win_ten_battles": {"name": "外山扬名", "description": "累计取得10场战斗胜利", "condition": "battle_victories", "target": 10, "reward": {"wood": 160, "spirit_stone": 120, "food": 120}},
	"unlock_south": {"name": "宗门拓境", "description": "解锁南部山坡", "condition": "region", "target": "south", "reward": {"wood": 240, "spirit_stone": 180, "food": 180}},
}


static func get_data(goal_id: StringName) -> Dictionary:
	return GOALS.get(String(goal_id), {})


static func normalize_claimed_goals(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result
	for index: int in range(value.size()):
		var raw_id: Variant = value[index]
		var goal_id := StringName(str(raw_id))
		if index >= GOAL_IDS.size() or goal_id != GOAL_IDS[index]:
			return []
		result.append(String(goal_id))
	return result


static func get_reward_text(goal_id: StringName) -> String:
	var reward: Dictionary = get_data(goal_id).get("reward", {})
	return "木材%d 灵石%d 灵谷%d" % [int(reward.get("wood", 0)), int(reward.get("spirit_stone", 0)), int(reward.get("food", 0))]
