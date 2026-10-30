extends Node2D
signal exited
const Simulation = preload("res://scripts/combat/practice_simulation.gd")
var simulation = Simulation.new()
var stats: Dictionary = {}
var character_name := "普通弟子"
var status: Label

func _ready() -> void:
	simulation.configure(stats)
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(24, 16)
	layer.add_child(panel)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 22)
	panel.add_child(status)
	var hint := Label.new()
	hint.text = "WASD / 方向键移动 · 自动攻击 · 躲开红圈 · Esc暂停\n试炼无奖励，宗门暂停；退出保留原角色与装备"
	panel.add_child(hint)
	var row := HBoxContainer.new()
	panel.add_child(row)
	for caption: String in ["暂停 / 继续", "重新试炼", "返回宗门"]:
		var button := Button.new()
		button.text = caption
		button.custom_minimum_size = Vector2(160, 38)
		row.add_child(button)
		button.pressed.connect(func() -> void:
			match caption:
				"暂停 / 继续": simulation.paused = not simulation.paused
				"重新试炼":
					_restart_run()
				"返回宗门": exited.emit()
		)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		simulation.paused = not simulation.paused
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	simulation.step(delta, direction)
	status.text = "%s · 生命 %.0f/%.0f · 击败 %d · %.1f秒%s" % [character_name, simulation.hp, simulation.maximum_hp, simulation.kills, simulation.elapsed, " · 已倒下，请重新试炼或返回" if simulation.hp <= 0 else (" · 暂停" if simulation.paused else "")]
	queue_redraw()

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	# World uses a fixed 1200x760 logical arena; presentation scales independently.
	scale = viewport_size / Vector2(1200, 760)
	draw_rect(Rect2(0, 0, 1200, 760), Color("101f28"))
	draw_rect(Simulation.BOUNDS, Color("213c40"))
	for x: int in range(40, 1161, 80):
		draw_line(Vector2(x,100), Vector2(x,700), Color("2a484b"))
	for enemy: Dictionary in simulation.enemies:
		if float(enemy["warning"]) >= 0:
			draw_circle(enemy["target"], 65, Color(0.9, 0.2, 0.15, 0.25))
			draw_arc(enemy["target"], 65, 0, TAU, 40, Color("ff8b65"), 3)
		draw_circle(enemy["pos"], 18, Color("cc715e"))
		draw_line(enemy["pos"] + Vector2(-18,-25), enemy["pos"] + Vector2(-18 + 36 * clampf(float(enemy["hp"]) / float(enemy.get("max_hp",24)),0,1),-25), Color("edc478"), 4)
	if simulation.slash_time > 0:
		draw_line(simulation.player, simulation.slash_target, Color("d6fff2"), 5)
	draw_circle(simulation.player, 18, Color("86dbc6"))
	draw_arc(simulation.player, 24, -PI / 2, -PI / 2 + TAU * simulation.hp / simulation.maximum_hp, 40, Color("e8cd89"), 4)

func _restart_run() -> void:
	simulation = Simulation.new()
	simulation.configure(stats)
