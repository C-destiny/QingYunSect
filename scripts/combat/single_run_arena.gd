extends "res://scripts/combat/practice_arena.gd"
const FullSimulation = preload("res://scripts/combat/single_run_simulation.gd")
var choice_panel: VBoxContainer
var signature := ""

func _ready() -> void:
	simulation = FullSimulation.new()
	super._ready()
	choice_panel = VBoxContainer.new()
	choice_panel.position = Vector2(380,200)
	get_child(0).add_child(choice_panel)
	get_child(0).get_child(0).get_child(1).text += "\n圆形追击 · 方形远攻 · 三角冲锋 · 大红圆为首领"

func _restart_run() -> void:
	simulation = FullSimulation.new()
	simulation.configure(stats)
	signature = ""

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var suffix := "战斗中 · 7分30秒首领降临"
	if simulation.phase == "victory":
		suffix = "胜利！首领已击败 · 本阶段不发永久奖励"
	elif simulation.phase == "defeat":
		suffix = "失败 · 可重新试炼或返回宗门"
	elif simulation.pending_choices > 0:
		suffix = "升级：请选择强化（战斗已暂停）"
	status.text += "\n等级%d · 经验%d/%d · %s" % [simulation.level,simulation.experience,8+simulation.level*4,suffix]
	var next_signature: String = str(simulation.pending_choices)+str(simulation.levels)+simulation.phase
	if next_signature != signature:
		signature = next_signature
		for child in choice_panel.get_children():
			choice_panel.remove_child(child)
			child.queue_free()
		if simulation.pending_choices > 0 and simulation.phase == "combat":
			for id: String in simulation.choices():
				var button := Button.new()
				button.custom_minimum_size = Vector2(500,70)
				if id == "recover":
					button.text = "调息 · 恢复30生命"
				else:
					button.text = "%s %d/3 → %d/3\n%s" % [FullSimulation.UPGRADES[id][0],int(simulation.levels.get(id,0)),int(simulation.levels.get(id,0))+1,FullSimulation.UPGRADES[id][1]]
				choice_panel.add_child(button)
				button.pressed.connect(func() -> void: simulation.choose_upgrade(id))
			if choice_panel.get_child_count() > 0:
				choice_panel.get_child(0).grab_focus()

func _draw() -> void:
	super._draw()
	if int(simulation.levels.get("orbit",0)) > 0:
		draw_arc(simulation.player,130+25*int(simulation.levels.get("orbit_range",0)),0,TAU,64,Color("82d8ba"),2)
	for enemy: Dictionary in simulation.enemies:
		match str(enemy.get("kind","")):
			"ranged": draw_rect(Rect2(enemy["pos"]-Vector2(14,14),Vector2(28,28)),Color("a291d4"))
			"charger":
				draw_colored_polygon(PackedVector2Array([enemy["pos"]+Vector2(0,-20),enemy["pos"]+Vector2(20,18),enemy["pos"]+Vector2(-20,18)]),Color("dbbd68"))
				if float(enemy["warning"]) >= 0:
					draw_line(enemy["pos"],enemy["target"],Color("f6d77e"),3)
			"boss":
				draw_circle(enemy["pos"],35,Color("cc4c6e"))
				draw_line(enemy["pos"]+Vector2(-40,-45),enemy["pos"]+Vector2(-40+80*clampf(float(enemy["hp"])/float(enemy["max_hp"]),0,1),-45),Color("f5cf80"),5)
				if float(enemy["warning"]) >= 0:
					draw_arc(enemy["target"],100,0,TAU,64,Color("ff5e78"),4)
