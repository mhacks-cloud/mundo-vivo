class_name RealmWorld
extends RefCounted

signal convoy_finished(delivered: bool, distance: float, covered: float)

const GOODS := ["wheat", "iron", "wood", "herb"]
const PLACES := {
	"vale": {"name": "Vale do Amieiro", "realm": "amieiro", "type": "Vila agrícola", "at": Vector2(0.21, 0.58)},
	"forest": {"name": "Bosque do Amieiro", "realm": "amieiro", "type": "Floresta", "at": Vector2(0.12, 0.37)},
	"frontier": {"name": "Fronteira de Brumária", "realm": "brumaria", "type": "Entreposto", "at": Vector2(0.48, 0.52)},
	"ruin": {"name": "Ruína da Serra", "realm": "brumaria", "type": "Masmorra", "at": Vector2(0.55, 0.31)},
	"capital": {"name": "Alto da Bruma", "realm": "brumaria", "type": "Capital mineira", "at": Vector2(0.79, 0.38)},
	"mine": {"name": "Pedreira do Sino", "realm": "brumaria", "type": "Minas", "at": Vector2(0.88, 0.22)},
	"hamlet": {"name": "Pouso da Geada", "realm": "brumaria", "type": "Vila serrana", "at": Vector2(0.86, 0.63)},
	"salmar": {"name": "Costa do Sal", "realm": "salmar", "type": "Porto futuro", "at": Vector2(0.62, 0.83)}
}
const ROUTES := {
	"forest": {"from": "vale", "to": "forest", "distance": 15, "capacity": 1, "cost": 0, "security": "Patrulha"},
	"stone": {"from": "vale", "to": "frontier", "distance": 38, "capacity": 3, "cost": 3, "security": "Patrulha"},
	"north": {"from": "vale", "to": "frontier", "distance": 28, "capacity": 3, "cost": 0, "security": "Estrada"},
	"ruin": {"from": "frontier", "to": "ruin", "distance": 12, "capacity": 1, "cost": 0, "security": "Estrada"},
	"ridge": {"from": "frontier", "to": "capital", "distance": 22, "capacity": 3, "cost": 2, "security": "Alto"},
	"lower": {"from": "frontier", "to": "capital", "distance": 34, "capacity": 3, "cost": 5, "security": "Estrada"},
	"mine": {"from": "capital", "to": "mine", "distance": 8, "capacity": 1, "cost": 0, "security": "Patrulha"},
	"hamlet": {"from": "capital", "to": "hamlet", "distance": 12, "capacity": 2, "cost": 1, "security": "Patrulha"}
}
const GATE := Vector3(39.2, 0.10, 39.0)
const HALL := Vector3(55.5, 0.10, 38.8)
const MARKET := Vector3(57.6, 0.10, 42.0)
const MINE := Vector3(59.8, 0.10, 30.0)
const HAMLET := Vector3(61.0, 0.10, 49.2)
const DEPOT := Vector3(52.2, 0.10, 38.0)
const REPAIR := Vector3(46.55, 0.10, 37.1)
const ROAD_ENTRY := Vector3(29.0, 0.10, -8.15)
const PATHS := {
	"ridge": [GATE, Vector3(44.0, 0.1, 39.0), Vector3(50.2, 0.1, 39.0), Vector3(54.0, 0.1, 42.0), MARKET],
	"lower": [GATE, Vector3(42.0, 0.1, 39.0), Vector3(43.0, 0.1, 45.5), Vector3(51.2, 0.1, 46.2), Vector3(54.0, 0.1, 42.0), MARKET]
}
const WORKS := {"repair": {"name": "Reparar caminho alto", "cost": 23, "at": REPAIR},
	"house": {"name": "Construir uma moradia", "cost": 35, "at": HAMLET}}
const WORK_STEPS := ["Separação no depósito", "Transporte", "Descarga", "Fundação e estrutura", "Inspeção"]
const INITIAL_STOCK := {"wheat": 1, "iron": 13, "wood": 9, "herb": 4}
const LIMITS := {"wheat": 32, "iron": 23, "wood": 15, "herb": 13}
var climate := RegionalClimate.new()
var forest_climate := RegionalClimate.new()
var treasury := 1100
var purse := 190
var stock := INITIAL_STOCK.duplicate()
var discovered: Array[String] = ["vale"]
var selected := "vale"
var active := false
var damaged := false
var storms_day := -1
var last_day := 0
var next_convoy := 0.0
var mine_units := 12
var population := 5
var houses := 0
var deliveries := 0
var customs := 0
var shipment: Dictionary = {}
var loot: Dictionary = {}
var last_convoy := ""
var project: Dictionary = {}
var worker_at := DEPOT
var journal: Array[String] = []

func _init() -> void:
	climate.latitude = 46.8
	climate.altitude = 1380.0
	climate.biome = "serra"
	climate.ocean_distance = 0.72
	forest_climate.latitude = 42.1
	forest_climate.altitude = 370.0
	forest_climate.biome = "floresta"
	forest_climate.ocean_distance = 0.41

func current(at: Vector3) -> String:
	if active:
		if houses > 0 and at.distance_to(HAMLET) < 3.5:
			return "hamlet"
		return "mine" if at.distance_to(MINE) < 4.0 else "capital"
	if RuinRun.inside(at):
		return "ruin"
	if at.x > 16.8 and at.z < -4.0:
		return "frontier"
	return "forest" if at.x < -11.5 and at.z < -3.0 else "vale"

func regional_climate(id: String, valley: RegionalClimate, frontier: RegionalClimate) -> RegionalClimate:
	if id in ["capital", "mine", "hamlet"]:
		return climate
	if id in ["frontier", "ruin"]:
		return frontier
	return forest_climate if id == "forest" else valley

func discover(id: String) -> void:
	if id not in discovered:
		discovered.append(id)

func access(id: String, bridge: bool, flooded: bool) -> String:
	match id:
		"north": return "FECHADA" if flooded else "ABERTA" if bridge else "EM CONSTRUÇÃO"
		"ridge":
			if damaged:
				return "EM CONSTRUÇÃO" if project.get("id") == "repair" else "DANIFICADA"
		"hamlet": return "ABERTA" if houses > 0 else "EM CONSTRUÇÃO" if project.get("id") == "house" else "FECHADA"
	return "ABERTA"

func route() -> String:
	return "lower" if damaged else "ridge"

func price(id: String) -> int:
	if id not in GOODS:
		return 0
	var base: int = LifeCatalog.GOODS[id][4]
	var scarcity := clampf(1.58 - int(stock[id]) * 0.055, 0.75, 1.58)
	var transport := 0
	if id == "wheat":
		transport = int(ROUTES[route()].cost)
	return maxi(1, roundi(base * scarcity * (1.0 + LifeCatalog.NATIONS.brumaria.tax)) + transport)

func buy(life: PlayerLife, id: String) -> bool:
	var due := price(id)
	if due <= 0 or stock[id] <= 0 or life.gold < due or not life.bag.add(id, 1):
		return false
	var tax := maxi(1, floori(due * LifeCatalog.NATIONS.brumaria.tax))
	life.gold -= due
	stock[id] -= 1
	treasury += tax
	purse += due - tax
	return true

func sell(life: PlayerLife, id: String) -> bool:
	var due := price(id)
	if due == 0 or stock[id] >= LIMITS[id]:
		return false
	var paid := maxi(1, floori(due * 0.48))
	if purse < paid or not life.bag.spend({id: 1}):
		return false
	purse -= paid
	life.gold += paid
	stock[id] += 1
	return true

func extract(life: PlayerLife) -> bool:
	if mine_units < 1 or life.gold < 2 or not life.bag.add("iron", 1):
		return false
	mine_units -= 1
	life.gold -= 2
	treasury += 2
	return true

func reserve(frontier: FrontierTrade, clock: WorldClock) -> bool:
	var quote := frontier.retail_price("wheat") * 3
	var toll: int = ROUTES[route()].cost
	if not shipment.is_empty() or not loot.is_empty() or clock.elapsed < next_convoy or frontier.stock.wheat < 3 or purse < quote + toll:
		return false
	frontier.stock.wheat -= 3
	frontier.purse += quote
	purse -= quote
	shipment = {"id": "alto-%d" % int(clock.elapsed), "origin": "frontier", "destination": "capital",
		"quantity": 3, "weight": 0.75, "capacity": 3, "driver": "Aldo", "escort": false, "traveled": 0.0, "covered": 0.0, "risk": "Estrada" if damaged else "Patrulha",
		"status": "PREPARANDO", "route": route(), "cursor": 1, "at": GATE, "wait": 1.0, "tax": 0,
		"attacked": false, "raider_hp": 30.0}
	_record("Aldo comprou três trigos no entreposto da fronteira.")
	return true

func advance(clock: WorldClock, frontier: FrontierTrade, delta: float, player_at := Vector3.INF) -> void:
	if not loot.is_empty() and clock.elapsed >= float(loot.expires):
		loot.clear()
	var day := clock.total_day()
	if day > last_day:
		for elapsed_day in range(maxi(last_day + 1, day - 12), day + 1):
			_daily(elapsed_day)
		last_day = day
	if shipment.is_empty():
		if stock.wheat < 3 and clock.hour() >= 7.0 and clock.hour() <= 18.0:
			reserve(frontier, clock)
	else:
		_advance_convoy(clock, delta, player_at)

func _daily(day: int) -> void:
	var weather := climate.sample(day, 9.0)
	stock.wheat = maxi(0, int(stock.wheat) - (2 if population >= 7 else 1))
	var mining := 0 if weather.weather in ["Neve", "Chuva"] else mini(2, mini(mine_units, int(LIMITS.iron) - int(stock.iron)))
	stock.iron += mining
	mine_units = mini(12, mine_units - mining + (1 if day % 3 == 0 else 0))
	stock.herb = mini(LIMITS.herb, stock.herb + (1 if weather.humidity > 0.50 else 0))
	if day > storms_day and weather.humidity >= 0.79 and weather.weather in ["Chuva", "Neve"]:
		damage(day)

func damage(day: int) -> bool:
	if damaged or (storms_day >= 0 and day <= storms_day + 3):
		return false
	damaged = true
	storms_day = day
	_record("Uma tempestade danificou o caminho alto. O desvio pela encosta está aberto.")
	return true

func _advance_convoy(clock: WorldClock, delta: float, player_at: Vector3) -> void:
	var status: String = shipment.status
	if status == "ATACADA":
		shipment.wait = maxf(0, float(shipment.wait) - delta)
		if shipment.wait == 0:
			loot = {"at": shipment.at, "quantity": shipment.quantity, "expires": clock.elapsed + 120.0,
				"id": shipment.id, "salvaged": false, "scout": GATE}
			last_convoy = "PERDIDA"
			_finish_convoy(false)
			next_convoy = clock.elapsed + 65.0
			_record("O guarda registrou o ataque na encosta. A carga caiu inteira.")
		return
	if status in ["PREPARANDO", "CARREGANDO", "INTERROMPIDA", "ENTREGANDO"]:
		shipment.wait = maxf(0, float(shipment.wait) - delta)
		if shipment.wait > 0:
			return
		match status:
			"PREPARANDO":
				shipment.status = "CARREGANDO"
				shipment.wait = 1.0
			"CARREGANDO":
				shipment.route = route()
				var tax: int = ROUTES[shipment.route].cost
				if purse < tax:
					shipment.wait = 1.0
					return
				purse -= tax
				treasury += tax
				shipment.tax = tax
				customs += 1
				shipment.status = "VIAJANDO"
				_record("A guarda inspecionou o trigo e recolheu %d ouro." % tax)
			"INTERROMPIDA":
				shipment.status = "VIAJANDO"
			"ENTREGANDO":
				if stock.wheat + shipment.quantity > LIMITS.wheat:
					shipment.wait = 2.0
					return
				stock.wheat += shipment.quantity
				deliveries += 1
				last_convoy = "CONCLUÍDA"
				next_convoy = clock.elapsed + 70.0
				_finish_convoy(true)
				_record("Aldo entregou três trigos. Estoque da capital: %d." % stock.wheat)
		return
	if damaged and shipment.route == "ridge" and float(shipment.at.x) < 46.35:
		shipment.route = "lower"
		shipment.cursor = 1
		shipment.status = "INTERROMPIDA"
		shipment.wait = 1.0
		return
	if shipment.route == "lower" and int(shipment.cursor) >= 3 and clock.total_day() % 3 == 2 and not shipment.attacked:
		shipment.attacked = true
		shipment.status = "ATACADA"
		shipment.wait = 7.5
		_record("Aldo alertou a fronteira: emboscada no desvio da encosta.")
		return
	var points: Array = PATHS[shipment.route]
	var target: Vector3 = points[shipment.cursor]
	var at: Vector3 = shipment.at
	var weather := climate.sample(clock.total_day(), clock.hour())
	var speed := 1.28 if weather.weather in ["Chuva", "Neve"] else 1.9
	shipment.at = at.move_toward(target, speed * delta)
	var moved: float = at.distance_to(shipment.at)
	shipment.traveled += moved
	if player_at.distance_to(shipment.at) <= 6.5:
		shipment.covered += moved
	if shipment.at.distance_squared_to(target) < 0.0001:
		if shipment.cursor == points.size() - 1:
			shipment.status = "ENTREGANDO"
			shipment.wait = 0.8
		else:
			shipment.cursor += 1

func sign_escort(guild: GuildLedger, life: PlayerLife) -> bool:
	if shipment.is_empty() or shipment.escort or shipment.traveled > 4.0 or not guild.reserve_highland_escort(life):
		return false
	shipment.escort = true
	return true

func _finish_convoy(delivered: bool) -> void:
	var cargo := shipment
	shipment = {}
	if cargo.escort:
		convoy_finished.emit(delivered, cargo.traveled, cargo.covered)

func scout_loot(underworld: Underworld, now: float, delta: float) -> void:
	if loot.is_empty() or loot.salvaged or now < float(loot.expires) - 106.0:
		return
	var point: Vector3 = loot.scout
	var destination: Vector3 = loot.at
	loot.scout = point.move_toward(destination, delta * 1.5)
	if loot.scout.distance_to(destination) < 0.38 and underworld.receive_lot(loot.id, "Emboscada na encosta de Brumária", "aldo", "Aldo"):
		loot.quantity -= 1
		loot.salvaged = true
		_record("Uma batedora do Junco recolheu um fardo na encosta.")

func repel() -> bool:
	if shipment.get("status") != "ATACADA":
		return false
	shipment.raider_hp -= 17.0
	if shipment.raider_hp <= 0.0:
		shipment.status = "VIAJANDO"
		_record("A escolta afastou o saqueador. A carga segue intacta.")
	return true

func recover(life: PlayerLife, at: Vector3, now: float) -> bool:
	if loot.is_empty() or now >= float(loot.expires) or at.distance_to(loot.at) > 1.8:
		return false
	if not life.bag.add("wheat", int(loot.quantity)):
		return false
	loot.clear()
	_record("A carga perdida foi recolhida no desvio.")
	return true

func propose(id: String, sponsor: String) -> String:
	if id not in WORKS:
		return "Proposta desconhecida."
	var reason := ""
	if not project.is_empty():
		reason = "a equipe já está em obra"
	elif id == "repair" and not damaged:
		reason = "o caminho alto está transitável"
	elif id == "house" and (houses > 0 or deliveries < 2 or population < 6 or damaged):
		reason = "o terreno precisa de duas entregas, seis moradores e caminho alto aberto"
	elif treasury < int(WORKS[id].cost) or stock.wood < 2 or stock.iron < 2:
		reason = "faltam dois ferros, duas madeiras ou ouro"
	if not reason.is_empty():
		var refusal := "Recusada · %s." % reason
		_record(refusal)
		return refusal
	treasury -= int(WORKS[id].cost)
	stock.wood -= 2
	stock.iron -= 2
	project = {"id": id, "step": 0, "done": 0, "wait": 0.6, "sponsor": sponsor.left(40)}
	var approval := "Aprovada por Rainha Elira · %s." % WORKS[id].name
	_record(approval)
	return approval

func work(clock: WorldClock, delta: float) -> void:
	if project.is_empty() and clock.hour() >= 7.0 and clock.hour() < 18.0 and stock.wood >= 2 and stock.iron >= 2:
		if damaged and clock.total_day() > storms_day and treasury >= WORKS.repair.cost:
			propose("repair", "Rainha Elira")
		elif not damaged and deliveries >= 2 and houses == 0 and treasury >= WORKS.house.cost:
			population = maxi(6, population)
			propose("house", "Rainha Elira")
	if project.is_empty() or clock.hour() < 7.0 or clock.hour() >= 18.0:
		return
	var step: int = project.step
	var site: Vector3 = WORKS[project.id].at
	var target := DEPOT if step == 0 else site
	worker_at = worker_at.move_toward(target, delta * 1.8)
	if worker_at.distance_squared_to(target) > 0.0001:
		return
	project.wait = maxf(0, float(project.wait) - delta)
	if project.wait > 0:
		return
	match step:
		0, 1, 2:
			project.step += 1
		3:
			project.done += 1
			project.step = 4 if project.done == 4 else 0
		4:
			if project.id == "repair":
				damaged = false
			else:
				houses = 1
				population += 1
			_record("%s · obra inaugurada." % WORKS[project.id].name)
			project.clear()
			return
	project.wait = 1.5 if project.step >= 3 else 0.45

func _record(message: String) -> void:
	journal.append(message)
	if journal.size() > 24:
		journal.pop_front()

func snapshot() -> Dictionary:
	var cargo := shipment.duplicate()
	if not cargo.is_empty():
		cargo.at = _encode(cargo.at)
	var fallen := loot.duplicate()
	if not fallen.is_empty():
		fallen.at = _encode(fallen.at)
		fallen.scout = _encode(fallen.scout)
	return {"loot": fallen, "last_convoy": last_convoy, "treasury": treasury, "purse": purse, "stock": stock.duplicate(), "discovered": discovered.duplicate(),
		"selected": selected, "active": active, "damaged": damaged, "storms_day": storms_day, "day": last_day,
		"next": next_convoy, "mine": mine_units, "population": population, "houses": houses, "deliveries": deliveries,
		"customs": customs, "shipment": cargo, "project": project.duplicate(), "worker": _encode(worker_at), "journal": journal.duplicate()}

func restore(data: Variant) -> void:
	if not data is Dictionary:
		data = {}
	treasury = _bounded(data, "treasury", 1100)
	purse = _bounded(data, "purse", 190)
	stock = INITIAL_STOCK.duplicate()
	if data.get("stock") is Dictionary:
		for id in GOODS:
			stock[id] = _bounded(data.stock, id, stock[id], LIMITS[id])
	discovered.assign(["vale"])
	if data.get("discovered") is Array:
		for id in PLACES:
			if id in data.discovered:
				discover(id)
	selected = data.selected if data.get("selected") in PLACES else "vale"
	active = data.get("active") == true
	damaged = data.get("damaged") == true
	storms_day = int(LifeCatalog.number(data.get("storms_day"), -1, -1, 3650000))
	last_day = _bounded(data, "day", 0, 3650000)
	next_convoy = LifeCatalog.number(data.get("next"), 0, 0, 3.0e10)
	mine_units = _bounded(data, "mine", 12, 12)
	population = _bounded(data, "population", 5, 12)
	houses = _bounded(data, "houses", 0, 1)
	deliveries = _bounded(data, "deliveries", 0)
	customs = _bounded(data, "customs", 0)
	worker_at = _point(data.get("worker"), DEPOT)
	shipment.clear()
	loot.clear()
	last_convoy = str(data.get("last_convoy", "")).left(16)
	var fallen: Variant = data.get("loot")
	if fallen is Dictionary and (fallen.get("quantity") == 2 or fallen.get("quantity") == 3):
		loot = {"at": _point(fallen.get("at"), GATE), "quantity": int(fallen.quantity),
			"expires": LifeCatalog.number(fallen.get("expires"), 0, 0, 3e10), "id": str(fallen.get("id", "")).left(30),
			"salvaged": fallen.get("salvaged") == true, "scout": _point(fallen.get("scout"), GATE)}
	var cargo: Variant = data.get("shipment")
	if cargo is Dictionary and cargo.get("route") in PATHS and cargo.get("quantity") == 3 and cargo.get("id") is String:
		var status: String = cargo.get("status", "PREPARANDO")
		if status in ["PREPARANDO", "CARREGANDO", "VIAJANDO", "INTERROMPIDA", "ENTREGANDO", "ATACADA"]:
			shipment = {"id": cargo.id.left(30), "origin": "frontier", "destination": "capital", "quantity": 3, "weight": 0.75,
				"capacity": 3, "driver": "Aldo", "escort": cargo.get("escort") == true, "risk": ROUTES[cargo.route].security,
				"status": status, "route": cargo.route, "at": _point(cargo.get("at"), GATE),
				"cursor": int(LifeCatalog.number(cargo.get("cursor"), 1, 1, PATHS[cargo.route].size() - 1)),
				"wait": LifeCatalog.number(cargo.get("wait"), 0, 0, 8), "tax": _bounded(cargo, "tax", 0, 5),
				"attacked": cargo.get("attacked") == true, "raider_hp": LifeCatalog.number(cargo.get("raider_hp"), 30, 0, 30),
				"traveled": LifeCatalog.number(cargo.get("traveled"), 0, 0, 200), "covered": LifeCatalog.number(cargo.get("covered"), 0, 0, 200)}
	project.clear()
	var job: Variant = data.get("project")
	if job is Dictionary and job.get("id") in WORKS:
		var step := _bounded(job, "step", 0, 4)
		project = {"id": job.id, "step": step, "done": _bounded(job, "done", 0, 4 if step == 4 else 3),
			"wait": LifeCatalog.number(job.get("wait"), 0, 0, 8), "sponsor": str(job.get("sponsor", "Rainha Elira")).left(40)}
	journal.clear()
	if data.get("journal") is Array:
		for entry in data.journal.slice(0, 24):
			if entry is String:
				journal.append(entry.left(180))

func _encode(at: Vector3) -> Array:
	return [at.x, at.z]

func _point(values: Variant, fallback: Vector3) -> Vector3:
	if not values is Array or values.size() != 2:
		return fallback
	return Vector3(LifeCatalog.number(values[0], fallback.x, 38, 69), 0.1,
		LifeCatalog.number(values[1], fallback.z, 25, 54))

func _bounded(data: Dictionary, id: String, fallback: int, limit := 1000000) -> int:
	return int(LifeCatalog.number(data.get(id), fallback, 0, limit))
