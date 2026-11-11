class_name RegionalJustice
extends RefCounted

const LAWS := {
	"vale": {"trade": 12, "assault": 24, "jail": 48.0},
	"brumaria": {"trade": 18, "assault": 30, "jail": 72.0},
	"salmar": {"trade": 15, "assault": 34, "jail": 60.0},
	"estrada": {"trade": 9, "assault": 18, "jail": 32.0},
	"sem_lei": {"trade": 0, "assault": 0, "jail": 0.0}
}
const SEIZABLE := {"wheat": 2, "wood": 2, "iron": 4, "herb": 2}
var record: Array[Dictionary] = []
var convictions := 0
var reputation := 0
var jail_until := 0.0
var debt := 0
var case_file: Dictionary = {}
var alert: Dictionary = {}

func state(now: float) -> String:
	if now < jail_until:
		return "PRESO"
	if not case_file.is_empty():
		if now < float(case_file.ready):
			return "SUSPEITO"
		return "FORA_DA_LEI" if convictions >= 2 else "CRIMINOSO"
	return "REINCIDENTE" if convictions >= 2 else "CIDADÃO"

func report(kind: String, accused: String, region: String, witness: String, at: Vector3, now: float, lawful_defense := false, victim := false) -> bool:
	if lawful_defense or victim or accused.is_empty() or witness.is_empty() or not LAWS.has(region) or not case_file.is_empty():
		return false
	var amount: int = LAWS[region].get(kind, 0)
	if amount <= 0:
		return false
	case_file = {"kind": kind, "uid": accused, "region": region, "witness": witness, "ready": now + 3.0,
		"fine": amount + convictions * 4, "at": [at.x, at.z]}
	_add("Testemunha %s registrou %s em %s." % [witness, "comércio ilícito" if kind == "trade" else "agressão", region])
	return true

func ambush(at: Vector3, witness: String, now: float) -> bool:
	if witness.is_empty():
		return false
	alert = {"at": [at.x, at.z], "witness": witness, "ready": now + 3.0, "expires": now + 42.0}
	_add(witness + " relatou uma emboscada na estrada.")
	return true

func wanted(uid: String, now: float) -> bool:
	return not case_file.is_empty() and case_file.uid == uid and now >= float(case_file.ready)

func alert_position(now: float) -> Variant:
	if alert.is_empty() or now < float(alert.ready) or now >= float(alert.expires):
		return null
	return Vector3(alert.at[0], 0.10, alert.at[1])

func settle(life: PlayerLife, now: float, allow_seizure: bool) -> bool:
	if not wanted(life.profile.get("uid", ""), now):
		return false
	var fine: int = case_file.fine
	if not allow_seizure and life.gold < fine:
		return false
	var paid := mini(life.gold, fine)
	life.gold -= paid
	life.treasury += paid
	var balance := fine - paid
	var seized := 0
	if allow_seizure:
		for id in SEIZABLE:
			if balance <= 0:
				break
			if id in life.equipment.values():
				continue
			var unit: int = SEIZABLE[id]
			var qty := mini(life.bag.amount(id), floori(float(balance) / unit))
			if qty > 0 and life.bag.spend({id: qty}):
				balance = maxi(0, balance - qty * unit)
				seized += qty
	debt = balance
	convictions += 1
	reputation += 2
	if balance > 0:
		jail_until = now + float(LAWS[case_file.region].jail) + mini(3, convictions - 1) * 12.0
	_add("Multa de %d ouro · pagos %d · %d itens recolhidos." % [fine, paid, seized])
	if balance > 0:
		_add("Saldo penal de %d convertido em prisão temporária." % balance)
	case_file.clear()
	return true

func advance(now: float) -> void:
	if jail_until > 0 and now >= jail_until:
		jail_until = 0
		debt = 0
		_add("Pena cumprida.")
	if not alert.is_empty() and now >= float(alert.expires):
		alert.clear()

func _add(message: String) -> void:
	record.append({"detail": message})
	if record.size() > 36:
		record.pop_front()

func snapshot() -> Dictionary:
	return {"record": record.duplicate(true), "convictions": convictions, "reputation": reputation,
		"jail": jail_until, "debt": debt, "case": case_file.duplicate(true), "alert": alert.duplicate(true)}

func restore(data: Variant) -> void:
	if not data is Dictionary:
		data = {}
	convictions = int(LifeCatalog.number(data.get("convictions"), 0, 0, 10000))
	reputation = int(LifeCatalog.number(data.get("reputation"), 0, 0, 10000))
	jail_until = LifeCatalog.number(data.get("jail"), 0, 0, 3e10)
	debt = int(LifeCatalog.number(data.get("debt"), 0, 0, 50000))
	case_file.clear()
	alert.clear()
	record.clear()
	var cases: Variant = data.get("case")
	if cases is Dictionary and cases.get("uid") is String and cases.get("witness") is String and cases.get("region") in ["vale", "brumaria", "salmar", "estrada"] and cases.get("kind") in ["trade","assault"] and _valid_point(cases.get("at")):
		case_file = {"uid": cases.uid.left(32), "witness": cases.witness.left(64), "region": cases.region, "kind": cases.kind,
			"at": cases.at.duplicate(), "ready": LifeCatalog.number(cases.get("ready"), 0, 0, 3e10),
			"fine": int(LifeCatalog.number(cases.get("fine"), 0, 1, 50000))}
	var notice: Variant = data.get("alert")
	if notice is Dictionary and notice.get("witness") is String and _valid_point(notice.get("at")):
		alert = {"witness": notice.witness.left(64), "at": notice.at.duplicate(),
			"ready": LifeCatalog.number(notice.get("ready"), 0, 0, 3e10), "expires": LifeCatalog.number(notice.get("expires"), 0, 0, 3e10)}
	if data.get("record") is Array:
		for entry in data.record.slice(0, 36):
			if entry is Dictionary and entry.get("detail") is String:
				_add(entry.detail.left(160))

func _valid_point(value: Variant) -> bool:
	return value is Array and value.size() == 2 and absf(LifeCatalog.number(value[0], 90, -90, 90)) <= 75 and absf(LifeCatalog.number(value[1], 90, -90, 90)) <= 75
