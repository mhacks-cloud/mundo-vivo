class_name VillageJournal
extends RefCounted

signal recorded(entry: Dictionary)
const LIMIT := 64
var entries: Array[Dictionary] = []
var serial := 0

func record(clock: WorldClock, kind: String, detail: String) -> void:
	serial += 1
	var entry := {"id": serial, "day": clock.total_day() + 1, "time": clock.time_text(), "kind": kind, "detail": detail}
	entries.append(entry)
	if entries.size() > LIMIT:
		entries.pop_front()
	recorded.emit(entry)

func recent(limit := 5) -> String:
	var lines := PackedStringArray()
	for i in range(maxi(0, entries.size() - limit), entries.size()):
		var entry := entries[i]
		lines.append("Dia %d · %s  %s" % [entry.day, entry.time, entry.detail])
	return "Ainda não há ocorrências registradas." if lines.is_empty() else "\n".join(lines)

func restore(data: Variant) -> void:
	entries.clear()
	serial = 0
	if not data is Array:
		return
	for value in data.slice(maxi(0, data.size() - LIMIT)):
		if not value is Dictionary or not value.get("id") is float and not value.get("id") is int:
			continue
		if not is_finite(float(value.id)) or value.id <= serial or value.id > 2147483647:
			continue
		if not value.get("time") is String or not value.get("detail") is String or not value.get("kind") is String:
			continue
		var day: Variant = value.get("day", 1)
		if (not day is float and not day is int) or not is_finite(float(day)):
			continue
		entries.append({"id": int(value.id), "day": int(clampf(float(day), 1, 3650000)),
			"time": value.time.left(10), "kind": value.kind.left(30), "detail": value.detail.left(180)})
		serial = int(value.id)
