class_name CivicWorks
extends RefCounted

signal changed
const HALL := Vector3(1.02, 0.10, -9.80)
const DEPOT := Vector3(21.50, 0.10, -8.65)
const CROSSING := Vector3(16.24, 0.55, -12.0)
const WORKER_HOME := Vector3(20.80, 0.10, -6.40)
const OPTIONS := {
	"road": {"name": "Reparar acesso norte", "price": 26, "at": Vector3(17.6, 0.1, -10.72)},
	"warehouse": {"name": "Armazém da fronteira", "price": 39, "at": Vector3(24.5, 0.1, -10.4)},
	"guard": {"name": "Posto de guarda", "price": 33, "at": Vector3(18.1, 0.1, -6.7)},
	"bridge": {"name": "Ponte nova"}, "market": {"name": "Mercado"}, "irrigation": {"name": "Irrigação"},
	"plaza": {"name": "Praça"}, "trade": {"name": "Infraestrutura comercial"}
}
const MATERIALS := ["pedra", "madeira", "pedra", "madeira"]
const STAGES := ["Planejamento", "Aquisição", "Transporte", "Descarga", "Preparação", "Fundação",
	"Estrutura", "Acabamento", "Inspeção", "Inauguração"]
var road_closed := false
var flood_day := -1
var approved: Dictionary = {}
var decisions: Array[String] = []
var completed: Array[String] = []
var worker_position := WORKER_HOME

func flood(day: int, humidity: float, weather: String, bridge_open: bool) -> bool:
	if road_closed or not bridge_open or day < 1 or (flood_day >= 0 and day <= flood_day + 5) or humidity < 0.83 or weather != "Chuva":
		return false
	flood_day = day
	road_closed = true
	changed.emit()
	return true

func propose(id: String, life: PlayerLife, world: WorldSimulation, sponsor: String) -> String:
	if not OPTIONS.has(id):
		return "Proposta desconhecida."
	if not approved.is_empty():
		return _decision(id, "Recusada · já há uma equipe em obra.")
	if not OPTIONS[id].has("at"):
		var reason := "A Ponte Nova já é atendida pela obra original." if id == "bridge" else "Falta um terreno público compatível no cadastro."
		return _decision(id, "Recusada · " + reason)
	if id in completed and id != "road":
		return _decision(id, "Recusada · terreno público ocupado.")
	if id == "road" and not road_closed:
		return _decision(id, "Recusada · o acesso norte está transitável.")
	var at: Vector3 = OPTIONS[id].at
	if Homestead.within_residential(at.x, at.z):
		return _decision(id, "Recusada · local reservado para residência.")
	var cost: int = OPTIONS[id].price
	if life.treasury < cost:
		return _decision(id, "Recusada · tesouro insuficiente.")
	if not world.economy.stock.spend("depot", {"madeira": 2, "pedra": 2}):
		return _decision(id, "Recusada · o depósito precisa de 2 madeiras e 2 pedras.")
	life.treasury -= cost
	approved = {"id": id, "step": 0, "done": 0, "cargo": "", "ground": "", "wait": 1.0, "sponsor": sponsor, "cost": cost}
	changed.emit()
	return _decision(id, "Aprovada por Rei Aldren · %s · %d ouro, 2 madeiras e 2 pedras reservados." % [sponsor, cost])

func stage() -> String:
	return "Equipe disponível" if approved.is_empty() else STAGES[int(approved.step)]

func destination() -> Vector3:
	if approved.is_empty():
		return WORKER_HOME
	if int(approved.step) <= 1:
		return DEPOT
	return OPTIONS[approved.id].at

func work(clock: WorldClock, delta: float, arrived: bool, journal: VillageJournal) -> void:
	if approved.is_empty() or not arrived:
		return
	approved.wait = maxf(0.0, float(approved.wait) - delta)
	if approved.wait > 0:
		return
	match int(approved.step):
		0:
			approved.step = 1
		1:
			approved.cargo = MATERIALS[int(approved.done)]
			approved.step = 2
		2:
			approved.ground = approved.cargo
			approved.cargo = ""
			approved.step = 3
		3:
			approved.step = 4 + int(approved.done)
		4, 5, 6, 7:
			approved.ground = ""
			approved.done += 1
			approved.step = 8 if approved.done == MATERIALS.size() else 1
		8:
			var id: String = approved.id
			if id == "road":
				road_closed = false
			if id not in completed:
				completed.append(id)
			approved.clear()
			journal.record(clock, "royal_works", OPTIONS[id].name + " · obra inaugurada pelo reino.")
			_decision(id, "Inaugurada · rota e infraestrutura atualizadas.")
			changed.emit()
			return
	approved.wait = 1.8 if int(approved.step) >= 4 else 0.55
	changed.emit()

func _decision(id: String, detail: String) -> String:
	decisions.append(OPTIONS[id].name + " · " + detail)
	if decisions.size() > 25:
		decisions.pop_front()
	return detail

func snapshot() -> Dictionary:
	return {"road": road_closed, "flood_day": flood_day, "approved": approved.duplicate(),
		"completed": completed.duplicate(), "decisions": decisions.duplicate(), "worker": [worker_position.x, worker_position.z]}

func restore(data: Variant) -> void:
	if not data is Dictionary:
		data = {}
	road_closed = data.get("road") == true
	flood_day = int(LifeCatalog.number(data.get("flood_day"), -1, -1, 3650000))
	approved.clear()
	completed.clear()
	decisions.clear()
	var record: Variant = data.get("approved")
	if record is Dictionary and OPTIONS.get(record.get("id", ""), {}).has("at"):
		var step := int(LifeCatalog.number(record.get("step"), 0, 0, 8))
		var count := int(LifeCatalog.number(record.get("done"), 0, 0, 4))
		if step == 8 or count < 4:
			approved = {"id": record.id, "step": step, "done": count, "wait": LifeCatalog.number(record.get("wait"), 0, 0, 10),
				"cargo": record.get("cargo", "") if record.get("cargo") in MATERIALS else "",
				"ground": record.get("ground", "") if record.get("ground") in MATERIALS else "",
				"sponsor": String(record.get("sponsor", "Rei Aldren")).left(40), "cost": OPTIONS[record.id].price}
	if data.get("completed") is Array:
		for id in ["road", "warehouse", "guard"]:
			if id in data.completed:
				completed.append(id)
	if data.get("decisions") is Array:
		for decision in data.decisions.slice(0, 25):
			if decision is String:
				decisions.append(decision.left(200))
	worker_position = WORKER_HOME
	if data.get("worker") is Array and data.worker.size() == 2:
		worker_position = Vector3(LifeCatalog.number(data.worker[0], WORKER_HOME.x, 17, 32), 0.1,
			LifeCatalog.number(data.worker[1], WORKER_HOME.z, -22, -3))
	changed.emit()
