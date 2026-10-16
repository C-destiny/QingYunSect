extends Node

signal save_completed(success: bool, message: String)
signal load_completed(success: bool, message: String)

const SAVE_VERSION := 1
const TEMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"

var save_path := "user://savegame.json"
var game_state: Node


func _ready() -> void:
	if game_state == null:
		game_state = get_node_or_null("/root/GameState")


func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(get_backup_path())


func get_backup_path() -> String:
	return save_path + BACKUP_SUFFIX


func get_temp_path() -> String:
	return save_path + TEMP_SUFFIX


func save_game() -> bool:
	if game_state == null:
		save_completed.emit(false, "游戏状态尚未初始化")
		return false
	var payload := {
		"version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"game_state": game_state.export_save_data(),
	}
	var serialized := JSON.stringify(payload, "\t")
	var temp_path := get_temp_path()
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		save_completed.emit(false, "无法写入临时存档：%s" % FileAccess.get_open_error())
		return false
	file.store_string(serialized)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_remove_file_if_exists(temp_path)
		save_completed.emit(false, "存档写入失败：%s" % write_error)
		return false
	var verification := _read_payload(temp_path)
	if not bool(verification.get("success", false)) or not _validate_payload_game_state(verification["payload"]):
		_remove_file_if_exists(temp_path)
		save_completed.emit(false, "临时存档校验失败")
		return false
	var replace_result := _replace_save_with_temp(temp_path)
	if replace_result != OK:
		_remove_file_if_exists(temp_path)
		save_completed.emit(false, "存档替换失败：%s" % replace_result)
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
	var primary_result := _load_from_path(save_path)
	if bool(primary_result.get("success", false)):
		load_completed.emit(true, "已读取")
		return true
	var backup_path := get_backup_path()
	if FileAccess.file_exists(backup_path):
		var backup_result := _load_from_path(backup_path)
		if bool(backup_result.get("success", false)):
			load_completed.emit(true, "主存档不可用，已从备份读取")
			return true
		load_completed.emit(false, "主存档与备份均不可用：%s；%s" % [primary_result.get("message", "未知错误"), backup_result.get("message", "未知错误")])
		return false
	load_completed.emit(false, str(primary_result.get("message", "存档读取失败")))
	return false


func _load_from_path(path: String) -> Dictionary:
	var result := _read_payload(path)
	if not bool(result.get("success", false)):
		return result
	var payload: Dictionary = result["payload"]
	if not payload.has("game_state") or not payload["game_state"] is Dictionary:
		return {"success": false, "message": "存档数据缺失"}
	if not game_state.import_save_data(payload["game_state"]):
		return {"success": false, "message": "存档数据校验失败"}
	return {"success": true, "message": "已读取"}


func _read_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"success": false, "message": "存档文件不存在"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"success": false, "message": "无法读取存档：%s" % FileAccess.get_open_error()}
	var json_text := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		return {"success": false, "message": "存档读取失败：%s" % read_error}
	var json := JSON.new()
	if json.parse(json_text) != OK:
		return {"success": false, "message": "存档格式损坏"}
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		return {"success": false, "message": "存档格式损坏"}
	var payload: Dictionary = parsed
	if not payload.has("version") or typeof(payload["version"]) not in [TYPE_INT, TYPE_FLOAT] or int(payload["version"]) != SAVE_VERSION:
		return {"success": false, "message": "存档版本不受支持"}
	return {"success": true, "payload": payload}


func _replace_save_with_temp(temp_path: String) -> Error:
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_save := ProjectSettings.globalize_path(save_path)
	var backup_path := get_backup_path()
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	var had_primary := FileAccess.file_exists(save_path)
	if had_primary:
		var primary_check := _read_payload(save_path)
		if bool(primary_check.get("success", false)) and _validate_payload_game_state(primary_check["payload"]):
			_remove_file_if_exists(backup_path)
			var backup_error := DirAccess.copy_absolute(absolute_save, absolute_backup)
			if backup_error != OK:
				return backup_error
		var remove_error := DirAccess.remove_absolute(absolute_save)
		if remove_error != OK:
			return remove_error
	var replace_error := DirAccess.rename_absolute(absolute_temp, absolute_save)
	if replace_error == OK:
		return OK
	if had_primary and FileAccess.file_exists(backup_path) and not FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(absolute_backup, absolute_save)
	return replace_error


func _validate_payload_game_state(payload: Dictionary) -> bool:
	if not payload.has("game_state") or not payload["game_state"] is Dictionary:
		return false
	var state_script: Script = game_state.get_script()
	if state_script == null:
		return false
	var validator: Node = state_script.new()
	var valid: bool = validator.import_save_data(payload["game_state"])
	validator.free()
	return valid


func _remove_file_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

