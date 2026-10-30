extends "res://scripts/combat/practice_simulation.gd"
const UPGRADES := {
 "power": ["剑锋", "飞剑伤害+25%"], "haste": ["御剑", "飞剑间隔缩短12%"],
 "range": ["剑意", "飞剑射程+60"], "multi": ["分光", "飞剑同时攻击目标+1"],
 "orbit": ["护体剑环", "周围130范围持续伤害增强"], "orbit_range": ["回风", "剑环范围+25"],
 "guard": ["金身", "受到伤害减少2"], "vitality": ["生机", "生命上限+25并恢复25"],
 "stride": ["轻身", "移动速度+10%"] }
var levels: Dictionary = {}
var experience := 0
var level := 1
var pending_choices := 0
var choice_sequence := 0
var phase := "combat"
var boss_spawned := false
var spawn_sequence := 0
var orbit_clock := 0.0

func gain_experience(amount: int) -> void:
	experience += maxi(0, amount)
	while experience >= 8 + level * 4:
		experience -= 8 + level * 4
		level += 1
		pending_choices += 1

func choices() -> Array[String]:
	var result: Array[String] = []
	var keys := UPGRADES.keys()
	for offset: int in range(keys.size()):
		var id := str(keys[(choice_sequence + offset) % keys.size()])
		if int(levels.get(id, 0)) < 3 and (id != "orbit_range" or int(levels.get("orbit",0)) > 0):
			result.append(id)
		if result.size() == 3:
			break
	if result.size() < 3:
		result.append("recover")
	return result

func choose_upgrade(id: String) -> bool:
	if phase != "combat" or pending_choices <= 0 or id not in choices():
		return false
	if id == "recover":
		hp = minf(maximum_hp, hp + 30)
	else:
		levels[id] = int(levels.get(id, 0)) + 1
		if id == "vitality":
			maximum_hp += 25
			hp = minf(maximum_hp, hp + 25)
	pending_choices -= 1
	choice_sequence += 3
	return true

func add_enemy(kind: String, pos: Vector2) -> void:
	var health := 30.0 + elapsed * 0.05
	if kind == "boss":
		health = 1000
	enemies.append({"kind":kind,"pos":pos,"hp":health,"max_hp":health,"warning":-1.0,"target":Vector2.ZERO})

func step(delta: float, direction: Vector2) -> void:
	if phase != "combat":
		return
	if hp <= 0:
		phase = "defeat"
		return
	if paused or pending_choices > 0 or delta <= 0:
		return
	elapsed += delta
	if elapsed >= 600:
		phase = "defeat"
		return
	player = (player + direction.limit_length() * (240 + 24 * int(levels.get("stride",0))) * delta).clamp(BOUNDS.position,BOUNDS.end)
	cooldown -= delta
	orbit_clock -= delta
	slash_time = maxf(0,slash_time-delta)
	spawn_clock -= delta
	if elapsed >= 450 and not boss_spawned:
		boss_spawned = true
		var boss_pos := Vector2(100,200) if player.x > 600 else Vector2(1100,600)
		add_enemy("boss",boss_pos)
	if spawn_clock <= 0 and enemies.size() < 30:
		var pos := Vector2(70,150+(spawn_sequence*137)%500) if spawn_sequence%2 == 0 else Vector2(1130,150+(spawn_sequence*137)%500)
		if pos.distance_to(player) < 240:
			pos = Vector2(1130 if player.x < 600 else 70,350)
		var kind := "chaser"
		if elapsed > 60:
			kind = ["chaser","ranged","charger"][spawn_sequence%3]
		add_enemy(kind,pos)
		spawn_sequence += 1
		spawn_clock = maxf(0.7,2.5-elapsed/250)
	for enemy: Dictionary in enemies:
		if float(enemy["hp"]) <= 0:
			continue
		var kind: String = enemy["kind"]
		var pos: Vector2 = enemy["pos"]
		var radius := 100.0 if kind == "boss" else 65.0
		if float(enemy.get("dash_remaining",0)) > 0:
			enemy["pos"] = pos.move_toward(enemy["target"],700*delta)
			enemy["dash_remaining"] = float(enemy["dash_remaining"])-delta
			if float(enemy["dash_remaining"]) <= 0 and player.distance_to(enemy["pos"]) < 65:
				hp = maxf(0,hp-maxf(1,18-defense-2*int(levels.get("guard",0))))
			continue
		if float(enemy["warning"]) >= 0:
			enemy["warning"] = float(enemy["warning"]) - delta
			if float(enemy["warning"]) <= 0:
				if kind == "charger":
					enemy["dash_remaining"] = 0.25
				elif player.distance_to(enemy["target"]) < radius:
					hp = maxf(0,hp-maxf(1,(28 if kind == "boss" else 18)-defense-2*int(levels.get("guard",0))))
				enemy["warning"] = -1.0
		else:
			var reach := 420.0 if kind == "ranged" else 145.0
			if pos.distance_to(player) > reach or kind != "ranged":
				enemy["pos"] = pos.move_toward(player,(110 if kind == "charger" else 65)*delta)
			if pos.distance_to(player) < reach:
				enemy["target"] = player
				enemy["warning"] = 1.1 if kind in ["ranged","boss"] else 0.9
	if hp <= 0:
		phase = "defeat"
		return
	if cooldown <= 0:
		var ordered := enemies.duplicate()
		ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return player.distance_squared_to(a["pos"]) < player.distance_squared_to(b["pos"]))
		var hits := 0
		for enemy: Dictionary in ordered:
			if player.distance_to(enemy["pos"]) <= 260+60*int(levels.get("range",0)) and float(enemy["hp"]) > 0:
				enemy["hp"] -= attack*(1+0.25*int(levels.get("power",0)))
				slash_target = enemy["pos"]
				slash_time = 0.16
				hits += 1
				if hits >= 1+int(levels.get("multi",0)):
					break
		if hits > 0:
			cooldown = maxf(0.18,0.55*(1-0.12*int(levels.get("haste",0))))
	if orbit_clock <= 0 and int(levels.get("orbit",0)) > 0:
		for enemy: Dictionary in enemies:
			if player.distance_to(enemy["pos"]) <= 130+25*int(levels.get("orbit_range",0)):
				enemy["hp"] -= attack*0.4*int(levels["orbit"])
		orbit_clock = 0.5
	for i: int in range(enemies.size()-1,-1,-1):
		if float(enemies[i]["hp"]) <= 0:
			if enemies[i]["kind"] == "boss":
				phase = "victory"
			kills += 1
			gain_experience(3)
			enemies.remove_at(i)
