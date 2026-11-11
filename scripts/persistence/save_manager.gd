class_name SaveManager
extends RefCounted

const PATH := "user://vale_do_amieiro.json"

const SLOT_DIR := "user://characters"
const VERSION := 4

func new_slot() -> String:
	if DirAccess.make_dir_recursive_absolute(SLOT_DIR) != OK:
		return ""
	while true:
		var path := "%s/%s.json" % [SLOT_DIR, Crypto.new().generate_random_bytes(16).hex_encode()]
		if not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".previous"):
			return path
	return ""

func list_slots() -> Array[Dictionary]:
	var paths := PackedStringArray([PATH])
	var directory := DirAccess.open(SLOT_DIR)
	if directory != null:
		var files := directory.get_files()
		files.sort()
		for filename in files:
			var canonical := filename.trim_suffix(".previous")
			if _slot_filename(canonical):
				var path := SLOT_DIR.path_join(canonical)
				if path not in paths:
					paths.append(path)
	var slots: Array[Dictionary] = []
	for path in paths:
		var data := read_state(path)
		var recovering := data.is_empty()
		if recovering:
			data = read_state(path + ".previous")
		if data.is_empty():
			continue
		var career: Variant = data.get("career")
		var life: Variant = career.get("life") if career is Dictionary else null
		var profile: Variant = life.get("profile") if life is Dictionary else null
		var label: String = profile.name if profile is Dictionary and profile.get("name") is String else "Partida anterior"
		slots.append({"path": path, "label": label.left(40), "recover": recovering})
	return slots

func _slot_filename(filename: String) -> bool:
	if not filename.ends_with(".json") or filename.length() != 37:
		return false
	return filename.get_basename().is_valid_hex_number(false)

func write_state(state: Dictionary, path: String = PATH) -> Error:
	var previous := _document(path)
	if previous.has("version") and previous.version not in [1.0, 2.0, 3.0, 4.0]:
		return ERR_FILE_UNRECOGNIZED
	if not read_state(path).is_empty():
		var backup := path + (".pre-4.1.bak" if previous.version == 3 else ".pre-4.bak")
		if previous.version < VERSION and not FileAccess.file_exists(backup):
			var legacy_copy := DirAccess.copy_absolute(path, backup)
			if legacy_copy != OK:
				return legacy_copy
		var rotation := _replace(path + ".previous", FileAccess.get_file_as_string(path))
		if rotation != OK:
			return rotation
	var payload := JSON.stringify(state)
	return _replace(path, JSON.stringify({"version": VERSION, "payload": payload, "sha256": payload.sha256_text()}))

func _replace(path: String, content: String) -> Error:
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	return DirAccess.rename_absolute(temp, path)

func _document(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
		return {}
	return parser.data

func read_state(path: String = PATH) -> Dictionary:
	var document := _document(path)
	var version: Variant = document.get("version")
	var state: Variant
	if version == VERSION:
		var payload: Variant = document.get("payload")
		if not payload is String or payload.sha256_text() != document.get("sha256"):
			return {}
		state = JSON.parse_string(payload)
	elif version == 1 or version == 2 or version == 3:
		state = document.get("state")
	else:
		return {}
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
