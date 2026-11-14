class_name RealmWorld
extends RefCounted

signal convoy_finished(delivered: bool, distance: float, covered: float)

const GOODS := ["wheat", "iron", "wood", "herb", "hoe", "stone"]
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
	"house": {"name": "Construir uma moradia", "cost": 35, "at": HAMLET},
	"district": {"name": "Ampliar o Pouso da Geada", "cost": 28, "at": Vector3(59.4, 0.1, 50.6)},
	"workshop": {"name": "Licenciar oficina do Pouso", "cost": 18, "at": Vector3(64.1, 0.1, 47.8)}}
const WORK_STEPS := ["Separação no depósito", "Transporte", "Descarga", "Fundação e estrutura", "Inspeção"]
const INITIAL_STOCK := {"wheat": 1, "iron": 13, "wood": 9, "herb": 4, "hoe": 0, "stone": 8}
const LIMITS := {"wheat": 32, "iron": 23, "wood": 15, "herb": 13, "hoe": 8, "stone": 18}
const PUBLIC_MEAL_PRICE := 2
var climate := RegionalClimate.new()
var diplomacy: RealmDiplomacy
var frontier_market: FrontierTrade
var mining_total := 0
var wheat_consumed := 0
var food_spending := 0
var imported_iron := 0
var tools_made := 0
var timber_total := 0
var wood_exports := 0
var market_support := 0
var forge_day := -1
var workshop_cash := 0
var shared_funds := 0
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
var workshop := false
var entrepreneur_cash := 6
var enterprise_day := -1
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

func tariff(day: int) -> int:
	var cost: int = ROUTES[route()].cost
	return diplomacy.tariff(cost, day) if diplomacy != null else cost

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
	if due == 0 or stock[id] >= LIMITS[id] or id in life.equipment.values():
		return false
	if LifeCatalog.max_durability(id) > 0 and int(life.bag.condition.get(id, 0)) < LifeCatalog.max_durability(id):
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
	var quote := maxi(2, floori(frontier.price("wheat") * 0.55)) * 3
	var toll := tariff(clock.total_day())
	if (diplomacy != null and diplomacy.relation <= -60) or not shipment.is_empty() or not loot.is_empty() or clock.elapsed < next_convoy or frontier.stock.wheat < 3:
		return false
	if purse < quote + toll:
		var transfer := mini(treasury, quote + toll - purse)
		treasury -= transfer
		purse += transfer
		market_support += transfer
	if purse < quote + toll:
		return false
	frontier.stock.wheat -= 3
	frontier.purse += quote
	purse -= quote
	shipment = {"id": "alto-%d" % int(clock.elapsed), "origin": "frontier", "destination": "capital",
		"item": "wheat", "quantity": 3, "weight": 0.75, "capacity": 3, "driver": "Aldo", "escort": false, "traveled": 0.0, "covered": 0.0, "risk": "Estrada" if damaged else "Patrulha",
		"status": "PREPARANDO", "route": route(), "cursor": 1, "at": GATE, "wait": 1.0, "tax": 0,
		"attacked": false, "raider_hp": 30.0}
	_record("Aldo comprou três trigos no entreposto da fronteira.")
	return true

func reserve_iron(frontier: FrontierTrade, clock: WorldClock) -> bool:
	return _reserve_export(frontier, clock, "iron", 3, 16, 15 if imported_iron == 0 else 12)

func reserve_wood(frontier: FrontierTrade, clock: WorldClock) -> bool:
	return _reserve_export(frontier, clock, "wood", 3, 8, 5)

func _reserve_export(frontier: FrontierTrade, clock: WorldClock, item: String, quantity: int, minimum: int, maximum: int) -> bool:
	var cost := price(item) * quantity
	if not shipment.is_empty() or not loot.is_empty() or clock.elapsed < next_convoy or stock[item] < minimum or frontier.stock[item] > maximum:
		return false
	# O entreposto mantém reserva para pagar os fretes de trigo antes de comprar exportações.
	if frontier.purse < cost + 70 or purse < tariff(clock.total_day()) or (diplomacy != null and diplomacy.relation <= -60):
		return false
	frontier.purse -= cost
	stock[item] -= quantity
	purse += cost
	shipment = {"id": "%s-%d" % [item, int(clock.elapsed)], "origin": "capital", "destination": "frontier", "item": item,
		"quantity": quantity, "weight": float(LifeCatalog.GOODS[item][2]) * quantity, "capacity": 3, "driver": "Aldo", "escort": false, "traveled": 0.0, "covered": 0.0,
		"risk": ROUTES[route()].security, "status": "PREPARANDO", "route": route(), "cursor": 1, "at": MARKET,
		"wait": 1.0, "tax": 0, "attacked": false, "raider_hp": 30.0}
	_record("Aldo carregou mercadorias compradas pelo entreposto.")
	return true

func daily_wheat_need() -> int:
	return 2 if population >= 7 else 1

func wheat_target() -> int:
	return daily_wheat_need() * 3

func advance(clock: WorldClock, frontier: FrontierTrade, delta: float, player_at := Vector3.INF) -> void:
	frontier_market = frontier
	if not loot.is_empty() and clock.elapsed >= float(loot.expires):
		loot.clear()
	var day := clock.total_day()
	if day > last_day:
		for elapsed_day in range(maxi(last_day + 1, day - 12), day + 1):
			_daily(elapsed_day)
		last_day = day
	if shipment.is_empty():
		if clock.hour() >= 7.0 and clock.hour() < 18.0:
			# Quando há dois dias de comida, uma janela fica disponível para bens produtivos.
			if stock.wheat >= daily_wheat_need() * 2 + 1:
				if reserve_iron(frontier, clock) or reserve_wood(frontier, clock) or _reserve_export(frontier, clock, "hoe", 1, 2, 1):
					return
			if stock.wheat < wheat_target():
				reserve(frontier, clock)
	else:
		_advance_convoy(clock, delta, player_at)

func _daily(day: int) -> void:
	var weather := climate.sample(day, 9.0)
	# A intendência paga o preço local por cada ração; não consome unidades sem verba.
	var consumed := mini(int(stock.wheat), mini(daily_wheat_need(), floori(float(treasury) / PUBLIC_MEAL_PRICE)))
	var meal_payment := consumed * PUBLIC_MEAL_PRICE
	treasury -= meal_payment
	purse += meal_payment
	food_spending += meal_payment
	stock.wheat -= consumed
	wheat_consumed += consumed
	var mining := 0 if weather.weather in ["Neve", "Chuva"] else mini(2, mini(mine_units, int(LIMITS.iron) - int(stock.iron)))
	stock.iron += mining
	if mining > 0 and purse >= 2 and stock.wheat >= daily_wheat_need():
		purse -= 2
		entrepreneur_cash += 2
	if mining > 0:
		stock.stone = mini(LIMITS.stone, stock.stone + 1)
	mining_total += mining
	mine_units = mini(12, mine_units - mining + (1 if day % 3 == 0 else 0))
	stock.herb = mini(LIMITS.herb, stock.herb + (1 if weather.humidity > 0.50 else 0))
	if day % 2 == 0 and int(stock.wood) < LIMITS.wood:
		stock.wood += 1
		timber_total += 1
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
				"id": shipment.id, "item": shipment.item, "salvaged": false, "scout": GATE}
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
				var tax := tariff(clock.total_day())
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
				var item: String = shipment.item
				var destination: Dictionary = frontier_market.stock if item != "wheat" else stock
				var cap: int = 120 if item != "wheat" else LIMITS.wheat
				if int(destination[item]) + int(shipment.quantity) > cap:
					shipment.wait = 2.0
					return
				destination[item] += shipment.quantity
				if item == "iron":
					imported_iron += int(shipment.quantity)
				if item == "wood":
					wood_exports += int(shipment.quantity)
				if item == "wheat":
					deliveries += 1
				_record("Aldo entregou %d × %s. Estoque de destino: %d." % [shipment.quantity, LifeCatalog.label(item), destination[item]])
				last_convoy = "CONCLUÍDA"
				next_convoy = clock.elapsed + (45.0 if diplomacy != null and diplomacy.active("supply", clock.total_day()) else 70.0)
				_finish_convoy(true)
		return
	if damaged and shipment.route == "ridge" and ((shipment.item == "wheat" and float(shipment.at.x) < 46.35) or (shipment.item != "wheat" and float(shipment.at.x) > 46.35)):
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
	var target_index: int = shipment.cursor if shipment.item == "wheat" else points.size() - 1 - int(shipment.cursor)
	var target: Vector3 = points[target_index]
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
	if loot.is_empty() or loot.get("item", "wheat") != "wheat" or loot.salvaged or now < float(loot.expires) - 106.0:
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
	if not life.bag.add(loot.get("item", "wheat"), int(loot.quantity)):
		return false
	loot.clear()
	_record("A carga perdida foi recolhida no desvio.")
	return true

func forge_import(frontier: FrontierTrade, day: int) -> bool:
	if imported_iron < 1 or frontier.stock.iron < 1 or frontier.stock.wood < 2 or frontier.stock.hoe >= 4 or frontier.treasury < 2:
		return false
	if tools_made > 0 and forge_day == day:
		return false
	frontier.stock.iron -= 1
	frontier.stock.wood -= 2
	frontier.stock.hoe += 1
	frontier.treasury -= 2
	frontier.purse += 2
	imported_iron -= 1
	tools_made += 1
	forge_day = day
	_record("A ferraria do entreposto produziu uma enxada com ferro entregue.")
	return true

func propose(id: String, sponsor: String) -> String:
	if id not in WORKS:
		return "Proposta desconhecida."
	if id == "district" and (houses != 1 or not workshop or damaged):
		return "Recusada · o bairro precisa de oficina e estrada aberta."
	if id == "workshop" and (workshop or houses == 0 or entrepreneur_cash < WORKS.workshop.cost):
		return "Recusada · a oficina exige moradia e 18 ouro do proponente."
	var material := "stone" if id == "repair" and stock.wood < 2 else "wood"
	var reason := ""
	if not project.is_empty():
		reason = "a equipe já está em obra"
	elif id == "repair" and not damaged:
		reason = "o caminho alto está transitável"
	elif id == "house" and (houses > 0 or deliveries < 2 or population < 6 or damaged):
		reason = "o terreno precisa de duas entregas, seis moradores e caminho alto aberto"
	elif (id != "workshop" and treasury + (shared_funds if id == "repair" else 0) < int(WORKS[id].cost)) or stock[material] < 2 or stock.iron < 2:
		reason = "faltam dois ferros, duas madeiras ou ouro"
	if not reason.is_empty():
		var refusal := "Recusada · %s." % reason
		_record(refusal)
		return refusal
	var subsidy := mini(shared_funds, int(WORKS[id].cost)) if id == "repair" else 0
	shared_funds -= subsidy
	if id == "workshop":
		entrepreneur_cash -= int(WORKS[id].cost)
	else:
		treasury -= int(WORKS[id].cost) - subsidy
	stock[material] -= 2
	stock.iron -= 2
	project = {"id": id, "step": 0, "done": 0, "wait": 0.6, "sponsor": sponsor.left(40), "wages": int(WORKS[id].cost), "material": material}
	var approval := "Aprovada por Rainha Elira · %s." % WORKS[id].name
	_record(approval)
	return approval

func work(clock: WorldClock, delta: float) -> void:
	var day := clock.total_day()
	if workshop and day != enterprise_day and clock.hour() >= 7.0 and clock.hour() < 18.0 and stock.hoe < 2 and stock.iron >= 1 and stock.wood >= 2 and purse >= 4:
		stock.iron -= 1
		stock.wood -= 2
		stock.hoe += 1
		purse -= 4
		entrepreneur_cash += 4
		enterprise_day = day
		_record("A oficina de Tomás entregou uma enxada ao mercado.")
	if project.is_empty() and clock.hour() >= 7.0 and clock.hour() < 18.0 and stock.iron >= 2:
		if damaged and clock.total_day() > storms_day and treasury + shared_funds >= WORKS.repair.cost and (stock.wood >= 2 or stock.stone >= 2):
			propose("repair", "Rainha Elira")
		elif not damaged and stock.wood >= 2 and deliveries >= 2 and houses == 0 and treasury >= WORKS.house.cost:
			population = maxi(6, population)
			propose("house", "Rainha Elira")
		elif stock.wood >= 2 and houses > 0 and not workshop and entrepreneur_cash >= WORKS.workshop.cost and stock.hoe < 2:
			propose("workshop", "Tomás")
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
			elif project.id == "district":
				houses = 2
			elif project.id == "workshop":
				workshop = true
			else:
				houses = 1
				population += 1
			workshop_cash += int(project.get("wages", 0))
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
	return {"workshop": workshop, "enterprise_cash": entrepreneur_cash, "enterprise_day": enterprise_day, "mined": mining_total, "consumed": wheat_consumed, "food_spending": food_spending, "imported_iron": imported_iron, "tools_made": tools_made, "timber_total": timber_total, "wood_exports": wood_exports, "market_support": market_support, "forge_day": forge_day, "wages": workshop_cash, "shared": shared_funds, "loot": fallen, "last_convoy": last_convoy, "treasury": treasury, "purse": purse, "stock": stock.duplicate(), "discovered": discovered.duplicate(),
		"selected": selected, "active": active, "damaged": damaged, "storms_day": storms_day, "day": last_day,
		"next": next_convoy, "mine": mine_units, "population": population, "houses": houses, "deliveries": deliveries,
		"customs": customs, "shipment": cargo, "project": project.duplicate(), "worker": _encode(worker_at), "journal": journal.duplicate()}

func restore(data: Variant) -> void:
	if not data is Dictionary:
		data = {}
	workshop = data.get("workshop") == true
	entrepreneur_cash = _bounded(data, "enterprise_cash", 6)
	enterprise_day = int(LifeCatalog.number(data.get("enterprise_day"), -1, -1, 3650000))
	mining_total = _bounded(data, "mined", 0)
	wheat_consumed = _bounded(data, "consumed", 0)
	food_spending = _bounded(data, "food_spending", 0)
	imported_iron = _bounded(data, "imported_iron", 0)
	tools_made = _bounded(data, "tools_made", 0)
	timber_total = _bounded(data, "timber_total", 0)
	wood_exports = _bounded(data, "wood_exports", 0)
	market_support = _bounded(data, "market_support", 0)
	forge_day = int(LifeCatalog.number(data.get("forge_day"), -1, -1, 3650000))
	workshop_cash = _bounded(data, "wages", 0)
	shared_funds = _bounded(data, "shared", 0, 1000)
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
	houses = _bounded(data, "houses", 0, 2)
	deliveries = _bounded(data, "deliveries", 0)
	customs = _bounded(data, "customs", 0)
	worker_at = _point(data.get("worker"), DEPOT)
	shipment.clear()
	loot.clear()
	last_convoy = str(data.get("last_convoy", "")).left(16)
	var fallen: Variant = data.get("loot")
	if fallen is Dictionary and (fallen.get("quantity") == 2 or fallen.get("quantity") == 3 or (fallen.get("quantity") == 1 and fallen.get("item") == "hoe")):
		loot = {"at": _point(fallen.get("at"), GATE), "quantity": int(fallen.quantity),
			"expires": LifeCatalog.number(fallen.get("expires"), 0, 0, 3e10), "id": str(fallen.get("id", "")).left(30),
			"item": fallen.get("item", "wheat") if fallen.get("item", "wheat") in ["wheat", "iron", "wood", "hoe"] else "wheat", "salvaged": fallen.get("salvaged") == true, "scout": _point(fallen.get("scout"), GATE)}
	var cargo: Variant = data.get("shipment")
	if cargo is Dictionary and cargo.get("route") in PATHS and (cargo.get("quantity") == 3 or (cargo.get("quantity") == 1 and cargo.get("item") == "hoe")) and cargo.get("id") is String:
		var status: String = cargo.get("status", "PREPARANDO")
		if status in ["PREPARANDO", "CARREGANDO", "VIAJANDO", "INTERROMPIDA", "ENTREGANDO", "ATACADA"]:
			var item: String = cargo.get("item", "wheat") if cargo.get("item", "wheat") in ["iron", "wood", "hoe", "wheat"] else "wheat"
			shipment = {"id": cargo.id.left(30), "origin": "capital" if item != "wheat" else "frontier", "destination": "frontier" if item != "wheat" else "capital",
				"item": item, "quantity": int(cargo.quantity), "weight": float(LifeCatalog.GOODS[item][2]) * int(cargo.quantity),
				"capacity": 3, "driver": "Aldo", "escort": cargo.get("escort") == true, "risk": ROUTES[cargo.route].security,
				"status": status, "route": cargo.route, "at": _point(cargo.get("at"), GATE),
				"cursor": int(LifeCatalog.number(cargo.get("cursor"), 1, 1, PATHS[cargo.route].size() - 1)),
				"wait": LifeCatalog.number(cargo.get("wait"), 0, 0, 8), "tax": _bounded(cargo, "tax", 0, 7),
				"attacked": cargo.get("attacked") == true, "raider_hp": LifeCatalog.number(cargo.get("raider_hp"), 30, 0, 30),
				"traveled": LifeCatalog.number(cargo.get("traveled"), 0, 0, 200), "covered": LifeCatalog.number(cargo.get("covered"), 0, 0, 200)}
	project.clear()
	var job: Variant = data.get("project")
	if job is Dictionary and job.get("id") in WORKS:
		var step := _bounded(job, "step", 0, 4)
		project = {"id": job.id, "step": step, "done": _bounded(job, "done", 0, 4 if step == 4 else 3),
			"wait": LifeCatalog.number(job.get("wait"), 0, 0, 8), "sponsor": str(job.get("sponsor", "Rainha Elira")).left(40),
			"material": "stone" if job.get("material") == "stone" else "wood", "wages": _bounded(job, "wages", int(WORKS[job.id].cost), int(WORKS[job.id].cost))}
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
