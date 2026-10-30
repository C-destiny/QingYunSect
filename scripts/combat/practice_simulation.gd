extends RefCounted
var player := Vector2(600, 380)
var hp := 100.0
var maximum_hp := 100.0
var attack := 11.0
var defense := 5.0
var elapsed := 0.0
var cooldown := 0.0
var spawn_clock := 0.0
var kills := 0
var paused := false
var enemies: Array[Dictionary] = []
var slash_target := Vector2.ZERO
var slash_time := 0.0
const BOUNDS := Rect2(40, 100, 1120, 600)

func configure(stats: Dictionary) -> void:
	maximum_hp = float(stats.get("hp", 100))
	hp = maximum_hp
	attack = float(stats.get("attack", 11))
	defense = float(stats.get("defense", 5))

func step(delta: float, direction: Vector2) -> void:
	if paused or hp <= 0 or delta <= 0:
		return
	elapsed += delta
	player += direction.limit_length() * 240.0 * delta
	player = player.clamp(BOUNDS.position, BOUNDS.end)
	cooldown -= delta
	slash_time = maxf(0, slash_time - delta)
	spawn_clock -= delta
	if spawn_clock <= 0 and enemies.size() < 12:
		var side := kills + enemies.size()
		var pos := Vector2(70, 140 + (side * 137) % 500) if side % 2 == 0 else Vector2(1130, 140 + (side * 137) % 500)
		if pos.distance_to(player) > 220:
			enemies.append({"pos": pos, "hp": 24.0, "warning": -1.0, "target": Vector2.ZERO})
		spawn_clock = 2.5
	for enemy: Dictionary in enemies:
		var pos: Vector2 = enemy["pos"]
		if float(enemy["warning"]) >= 0:
			enemy["warning"] = float(enemy["warning"]) - delta
			if float(enemy["warning"]) <= 0:
				if player.distance_to(enemy["target"]) < 65:
					hp = maxf(0, hp - maxf(1, 18 - defense))
				enemy["warning"] = -1.0
		else:
			enemy["pos"] = pos.move_toward(player, 70 * delta)
			if pos.distance_to(player) < 145:
				enemy["target"] = player
				enemy["warning"] = 0.9
	if cooldown <= 0:
		var nearest: Dictionary = {}
		var distance := 260.0
		for enemy: Dictionary in enemies:
			var d := player.distance_to(enemy["pos"])
			if d < distance:
				nearest = enemy
				distance = d
		if not nearest.is_empty():
			nearest["hp"] = float(nearest["hp"]) - maxf(1, attack)
			slash_target = nearest["pos"]
			slash_time = 0.16
			cooldown = 0.55
	for i: int in range(enemies.size() - 1, -1, -1):
		if float(enemies[i]["hp"]) <= 0:
			enemies.remove_at(i)
			kills += 1
