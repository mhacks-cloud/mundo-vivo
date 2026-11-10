class_name SaveManager
extends RefCounted

const PATH := "user://vale_do_amieiro.json"

func write_state(state: Dictionary, path: String = PATH) -> Error:
	var backup := path + ".pre-4.bak"
	if FileAccess.file_exists(path) and not FileAccess.file_exists(backup):
		var prior: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if prior is Dictionary and (prior.get("version") == 1 or prior.get("version") == 2):
			var copy := DirAccess.copy_absolute(path, backup)
			if copy != OK:
				return copy
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"version": 3, "state": state}, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	return DirAccess.rename_absolute(path + ".tmp", path)

func read_state(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not document is Dictionary:
		return {}
	var version: Variant = document.get("version")
	if version != 1 and version != 2 and version != 3:
		return {}
	var state: Variant = document.get("state")
	if not state is Dictionary or not _number(state.get("elapsed")) or float(state.elapsed) < 0:
		return {}
	if float(state.elapsed) > WorldClock.DAY_SECONDS * 3650000.0:
		return {}
	var bridge: Variant = state.get("bridge")
	if not bridge is Dictionary or not _number(bridge.get("stage")) or not _number(bridge.get("delivered")):
		return {}
	var player: Variant = state.get("player")
	if not player is Array or player.size() != 3:
		return {}
	for coordinate in player:
		if not _number(coordinate) or absf(float(coordinate)) > 75.0:
			return {}
	return state

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
