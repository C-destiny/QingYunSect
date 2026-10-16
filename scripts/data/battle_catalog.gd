class_name BattleCatalog
extends RefCounted

const MAX_PARTY_SIZE := 3
const ROUND_TIME := 1.0
const RESTART_DELAY := 2.0
const MIN_DAMAGE := 1.0

const DISCIPLE_BASE_HP := 100.0
const DISCIPLE_HP_PER_REALM := 20.0
const DISCIPLE_BASE_ATTACK := 10.0
const DISCIPLE_ATTACK_PER_REALM := 3.0
const DISCIPLE_BASE_DEFENSE := 5.0
const DISCIPLE_DEFENSE_PER_REALM := 2.0

const STAGES := {
	1: {"name": "山门试炼", "enemy": "山野狼群", "hp": 120.0, "attack": 9.0, "defense": 2.0, "rewards": {"wood": 20, "food": 10}},
	2: {"name": "林中除妖", "enemy": "青木妖藤", "hp": 190.0, "attack": 13.0, "defense": 4.0, "rewards": {"wood": 30, "spirit_stone": 8, "food": 12}},
	3: {"name": "矿洞清剿", "enemy": "噬灵石兽", "hp": 280.0, "attack": 18.0, "defense": 7.0, "rewards": {"wood": 20, "spirit_stone": 18, "food": 15}},
	4: {"name": "荒谷巡守", "enemy": "赤羽妖禽", "hp": 390.0, "attack": 24.0, "defense": 10.0, "rewards": {"wood": 35, "spirit_stone": 25, "food": 22}},
	5: {"name": "外山镇邪", "enemy": "黑煞散修", "hp": 540.0, "attack": 31.0, "defense": 14.0, "rewards": {"wood": 50, "spirit_stone": 40, "food": 30}},
}


static func get_stage(stage_id: int) -> Dictionary:
	return STAGES.get(stage_id, {})


static func get_stage_count() -> int:
	return STAGES.size()


static func get_disciple_stats(realm_level: int) -> Dictionary:
	var realm_offset := float(maxi(1, realm_level) - 1)
	return {
		"hp": DISCIPLE_BASE_HP + realm_offset * DISCIPLE_HP_PER_REALM,
		"attack": DISCIPLE_BASE_ATTACK + realm_offset * DISCIPLE_ATTACK_PER_REALM,
		"defense": DISCIPLE_BASE_DEFENSE + realm_offset * DISCIPLE_DEFENSE_PER_REALM,
	}


static func calculate_damage(attack: float, defense: float) -> float:
	return maxf(MIN_DAMAGE, attack - defense)


static func get_reward_text(stage_id: int) -> String:
	var rewards: Dictionary = get_stage(stage_id).get("rewards", {})
	var parts := PackedStringArray()
	if int(rewards.get("wood", 0)) > 0: parts.append("木材%d" % int(rewards["wood"]))
	if int(rewards.get("spirit_stone", 0)) > 0: parts.append("灵石%d" % int(rewards["spirit_stone"]))
	if int(rewards.get("food", 0)) > 0: parts.append("灵谷%d" % int(rewards["food"]))
	return "、".join(parts)
