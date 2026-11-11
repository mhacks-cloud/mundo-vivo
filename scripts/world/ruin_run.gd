class_name RuinRun
extends RefCounted

const ENTRANCE := Vector3(49.6, 0.10, -19.0)
const EXIT := Vector3(21.0, 0.10, -17.0)
const CACHE := Vector3(68.2, 0.10, -19.0)
const SPAWNS := [Vector3(54.0, 0.10, -21.3), Vector3(56.2, 0.10, -16.7), Vector3(65.5, 0.10, -19.0)]
const NAMES := ["Vigia da galeria", "Guardião das pedras", "Sentinela do Amieiro"]
const MAX_HP := [39.0, 52.0, 91.0]
var health := MAX_HP.duplicate()
var day := -1
var claimed := false
var ally_hp := 65.0

static func inside(p: Vector3) -> bool:
	return p.x >= 48.0 and p.x <= 71.0 and p.z >= -25.0 and p.z <= -13.0

func enter(day_number: int) -> void:
	if day < 0:
		day = day_number

func empowered() -> bool:
	return day >= 0 and day % 3 == 2

func gate_open() -> bool:
	return health[0] <= 0.0 and health[1] <= 0.0

func alive(index: int) -> bool:
	return index >= 0 and index < health.size() and health[index] > 0.0 and (index != 2 or gate_open())

func strike(life: PlayerLife, index: int, amount: float) -> bool:
	if not alive(index) or not is_finite(amount) or amount <= 0.0:
		return false
	health[index] = maxf(0.0, float(health[index]) - amount)
	if health[index] == 0.0:
		life.award(40 if index == 2 else 14)
		life.logbook("Ruína da Serra · " + NAMES[index] + " derrotado.")
	return true

func recover(life: PlayerLife) -> bool:
	if claimed or health[2] > 0.0 or not life.bag.can_add("iron", 4):
		return false
	life.bag.add("iron", 4)
	claimed = true
	life.award(18)
	life.logbook("Ruína da Serra · 4 ferros recuperados do cofre.")
	return true

func snapshot() -> Dictionary:
	return {"health": health.duplicate(), "day": day, "claimed": claimed, "ally": ally_hp}

func restore(data: Variant) -> void:
	health = MAX_HP.duplicate()
	day = -1
	claimed = false
	ally_hp = 65.0
	if not data is Dictionary:
		return
	var values: Variant = data.get("health")
	if values is Array and values.size() == health.size():
		for i in health.size():
			health[i] = LifeCatalog.number(values[i], health[i], 0, MAX_HP[i])
	day = int(LifeCatalog.number(data.get("day"), -1, -1, 3650000))
	claimed = data.get("claimed") == true
	ally_hp = LifeCatalog.number(data.get("ally"), 65, 0, 100)
