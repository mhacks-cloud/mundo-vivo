class_name WorldEditStore
extends RefCounted

const SCHEMA := 1
const REGION := "vale"
const PATH := "user://world_edits/vale.json"
const MAX_ENTRIES := 128
const TYPES := ["well", "tree", "barrel", "crate"]
const TERRAIN := ["grass", "dirt", "stone", "paving", "path", "road"]

static func empty() -> Dictionary:
	return {"schema": SCHEMA, "region": REGION, "revision": 0, "edited_at": "", "entries": {}, "terrain": {}}

static func read(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return empty()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("schema") != SCHEMA or parsed.get("region") != REGION:
		return empty()
	var result := empty()
	result.revision = int(LifeCatalog.number(parsed.get("revision"), 0, 0, 1000000))
	result.edited_at = str(parsed.get("edited_at", "")).left(48)
	if parsed.get("entries") is Dictionary:
		for id in parsed.entries:
			if result.entries.size() >= MAX_ENTRIES:
				break
			var row: Variant = parsed.entries[id]
			if not id is String or not id.is_valid_identifier() or not row is Dictionary or row.get("type") not in TYPES:
				continue
			var at: Variant = row.get("position")
			if not at is Array or at.size() != 2 or not _finite(at[0]) or not _finite(at[1]):
				continue
			var x := float(at[0])
			var z := float(at[1])
			if x < -29.0 or x > 31.0 or z < -30.0 or z > 29.0:
				continue
			var angle: Variant = row.get("rotation", 0.0)
			if not _finite(angle):
				continue
			result.entries[id] = {"region": REGION, "id": id, "type": row.type, "position": [x, z],
				"rotation": wrapf(float(angle), -PI, PI), "state": "removed" if row.get("state") == "removed" else "active",
				"edited_at": str(row.get("edited_at", "")).left(48), "schema": SCHEMA}
	if parsed.get("terrain") is Dictionary:
		for id in parsed.terrain:
			if result.terrain.size() >= 256:
				break
			var parts: PackedStringArray = str(id).split("_")
			if parts.size() == 3 and parts[0] == "t" and parts[1].is_valid_int() and parts[2].is_valid_int() \
				and absi(int(parts[1])) <= 31 and absi(int(parts[2])) <= 30 and parsed.terrain[id] in TERRAIN:
				result.terrain[id] = parsed.terrain[id]
	return result

static func write(data: Dictionary, path: String = PATH) -> Error:
	var normalized := empty()
	normalized.revision = int(data.get("revision", 0)) + 1
	normalized.edited_at = Time.get_datetime_string_from_system()
	normalized.entries = data.get("entries", {}).duplicate(true)
	normalized.terrain = data.get("terrain", {}).duplicate(true)
	if normalized.entries.size() > MAX_ENTRIES or normalized.terrain.size() > 256:
		return ERR_INVALID_DATA
	var parent := path.get_base_dir()
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(parent))
	if err != OK:
		return err
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(normalized, "\t"))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".previous"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".previous"))
		err = DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".previous"))
		if err != OK:
			return err
	err = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path))
	return err

static func restore_previous(path: String = PATH) -> bool:
	var prior := path + ".previous"
	if not FileAccess.file_exists(prior):
		return false
	var previous := read(prior)
	if previous.revision == 0 and previous.entries.is_empty() and previous.terrain.is_empty():
		return false
	return write(previous, path) == OK

static func _finite(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
