extends "res://scripts/combat/single_run_arena.gd"
signal sect_tick(delta: float)
var service: RefCounted
var run_id := 0
var disciple_id := 0
var confirmed_kills := 0
var retry_clock := 0.0
var settlement_message := ""
func _ready() -> void:
	super._ready()
	get_child(0).get_child(0).get_child(1).text = "WASD移动 · 自动攻击 · Esc暂停\n击杀各得1木材/灵石（最多60），胜利额外30木/20石/20粮；首通稀有法器\n战斗时宗门生产，选择强化/暂停/终局停时；返回按本局结果结算"
func _physics_process(delta: float) -> void:
	if run_id == 0:
		status.text = settlement_message
		return
	var before: float = simulation.elapsed
	super._physics_process(delta)
	status.text = status.text.replace("本阶段不发永久奖励","返回或重试时领取奖励")
	var advanced: float = simulation.elapsed-before
	if advanced > 0:
		sect_tick.emit(advanced)
		retry_clock -= advanced
		if simulation.kills != confirmed_kills and retry_clock <= 0:
			if service.checkpoint(run_id,mini(simulation.kills,500),minf(simulation.elapsed,600)):
				confirmed_kills = simulation.kills
			else:
				settlement_message = "进度保存失败；返回结算时可重试"
				retry_clock = 1
	status.text += "\n本局普通收益 %d木/%d石 · %s" % [mini(simulation.kills,60),mini(simulation.kills,60),settlement_message]
func settle() -> bool:
	if run_id == 0:
		return true
	if not service.finish(run_id,mini(simulation.kills,500),minf(simulation.elapsed,600),simulation.phase == "victory"):
		settlement_message = "结算保存失败，未发奖励；请重试返回或重试按钮"
		return false
	run_id = 0
	return true
func _restart_run() -> void:
	if not settle():
		return
	run_id = service.begin(disciple_id)
	if run_id == 0:
		settlement_message = "上一局已结算；新一局保存失败，可重试或返回"
		simulation.paused = true
		return
	confirmed_kills = 0
	retry_clock = 0
	settlement_message = ""
	super._restart_run()
