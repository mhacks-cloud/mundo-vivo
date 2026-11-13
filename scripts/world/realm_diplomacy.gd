class_name RealmDiplomacy
extends RefCounted

const TERMS := {"trade": "Acordo comercial", "passage": "Tratado de passagem",
	"supply": "Acordo de abastecimento", "works": "Cooperação em obras"}
var relation := 0
var treaties: Dictionary = {}
var history: Array[String] = []
var last_negotiation := -1

func label() -> String:
	if relation <= -60:
		return "Hostil"
	if relation <= -20:
		return "Tensa"
	return "Amistosa" if relation >= 25 else "Neutra"

func change(amount: int, reason: String) -> void:
	relation = clampi(relation + amount, -100, 100)
	_note("%s · relação %d" % [reason, relation])

func active(id: String, day: int) -> bool:
	return treaties.has(id) and day < int(treaties[id].ends)

func negotiate(id: String, day: int, vale: PlayerLife, bruma: RealmWorld) -> bool:
	if not TERMS.has(id) or treaties.has(id) or relation < -19:
		return false
	var fee := 4 if id == "works" else 2
	if vale.treasury < fee:
		return false
	vale.treasury -= fee
	if id == "works":
		bruma.shared_funds += fee
	else:
		bruma.treasury += fee
	treaties[id] = {"ends": day + 4, "start": day, "cost": fee}
	_note("Aldren e Elira firmaram %s até o dia %d." % [TERMS[id], day + 4])
	return true

func advance(day: int, vale: PlayerLife, bruma: RealmWorld) -> void:
	if day <= last_negotiation:
		return
	last_negotiation = day
	for id in treaties.keys():
		if not active(id, day):
			if id == "works":
				vale.treasury += bruma.shared_funds
				bruma.shared_funds = 0
			_note(TERMS[id] + " expirou.")
			treaties.erase(id)
	if day < 1:
		return
	if relation >= 15 and day % 3 == 1:
		negotiate("trade", day, vale, bruma)
	elif relation >= 6 and bruma.stock.wheat < 2:
		negotiate("supply", day, vale, bruma)
	elif relation >= 20 and bruma.damaged:
		negotiate("works", day, vale, bruma)
	elif relation >= 25:
		negotiate("passage", day, vale, bruma)

func tariff(base: int, day: int) -> int:
	return maxi(0, base + (2 if relation <= -20 else 0) - (2 if active("trade", day) else 0) - (1 if active("passage", day) else 0))

func _note(message: String) -> void:
	history.append(message)
	if history.size() > 24:
		history.pop_front()

func snapshot() -> Dictionary:
	return {"relation": relation, "treaties": treaties.duplicate(true), "history": history.duplicate(), "day": last_negotiation}

func restore(data: Variant) -> void:
	if not data is Dictionary:
		data = {}
	relation = int(LifeCatalog.number(data.get("relation"), 0, -100, 100))
	last_negotiation = int(LifeCatalog.number(data.get("day"), -1, -1, 3650000))
	treaties.clear()
	history.clear()
	if data.get("treaties") is Dictionary:
		for id in TERMS:
			var entry: Variant = data.treaties.get(id)
			if entry is Dictionary and entry.get("ends") == float(entry.get("start", -99)) + 4:
				treaties[id] = entry.duplicate()
	if data.get("history") is Array:
		for line in data.history.slice(0, 24):
			if line is String:
				history.append(line.left(180))
