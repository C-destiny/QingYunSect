extends Node

signal save_completed(success: bool, message: String)
signal load_completed(success: bool, message: String)

const SAVE_VERSION := 1

var save_path := "user://savegame.json"
var game_state: Node


func _ready() -> void:
	if game_state == null:
		game_state = get_node_or_null("/root/GameState")


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game() -> bool:
	if game_state == null:
		save_completed.emit(false, "游戏状态尚未初始化")
		return false
	var payload := {
		"version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"game_state": game_state.export_save_data(),
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		save_completed.emit(false, "无法写入存档：%s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		save_completed.emit(false, "存档写入失败：%s" % write_error)
		return false
	save_completed.emit(true, "已保存")
	return true


func load_game() -> bool:
	if game_state == null:
		load_completed.emit(false, "游戏状态尚未初始化")
		return false
	if not has_save():
		load_completed.emit(false, "尚无本地存档")
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		load_completed.emit(false, "无法读取存档：%s" % FileAccess.get_open_error())
		return false
	var json_text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_text)
	if not parsed is Dictionary:
		load_completed.emit(false, "存档格式损坏")
		return false
	var payload: Dictionary = parsed
	if int(payload.get("version", -1)) != SAVE_VERSION:
		load_completed.emit(false, "存档版本不受支持")
		return false
	if not payload.has("game_state") or not game_state.import_save_data(payload["game_state"]):
		load_completed.emit(false, "存档数据校验失败")
		return false
	load_completed.emit(true, "已读取")
	return true

