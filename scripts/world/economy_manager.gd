class_name EconomyManager
extends RefCounted

var diplomacy := RealmDiplomacy.new()
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy_rules.json"))
var contracts: Dictionary = {}
var deliveries: Dictionary = {}
var history: Array[String] = []
var next_update := 0.0
var last_day := -1
var drought := false
var prior_deliveries := -1
var prior_customs := -1

func tick(game: Node3D) -> void:
	var clock: WorldClock = game.simulation.clock
	if clock.elapsed < next_update and next_update - clock.elapsed <= float(rules.interval_seconds):
		return
	next_update = clock.elapsed + float(rules.interval_seconds)
	var day := clock.total_day()
	var life: PlayerLife = game.career.life
	var bruma: RealmWorld = game.realms.world
	if prior_deliveries >= 0 and bruma.deliveries > prior_deliveries:
		diplomacy.change(6, "Alimentos chegaram a Alto da Bruma")
	if prior_customs >= 0 and bruma.customs > prior_customs and bruma.last_convoy == "PERDIDA":
		diplomacy.change(-3, "A fronteira reforçou a fiscalização após a perda de carga")
	prior_deliveries = bruma.deliveries
	prior_customs = bruma.customs
	if day == last_day:
		_supply_relief(game, day)
		return
	last_day = day
	var weather: Dictionary = game.simulation.climate.sample(day, 12.0)
	drought = weather.humidity < float(rules.dry_humidity)
	game.simulation.economy.dry = drought
	if drought:
		_note("Seca no Vale · lavouras levam mais tempo para amadurecer.")
	for id in contracts:
		var job: Dictionary = contracts[id]
		if job.state in ["ACEITO", "EM_ANDAMENTO"] and day >= int(job.ends):
			_credit(game, rules.contracts[id].region, int(job.reserve))
			job.reserve = 0
			job.state = "FALHOU"
			_note("Prazo expirado · " + rules.contracts[id].issuer)
	if "capital" in bruma.discovered:
		diplomacy.advance(day, life, bruma)
		_supply_relief(game, day)

func _supply_relief(game: Node3D, day: int) -> void:
	if not diplomacy.active("supply", day) or diplomacy.relation <= -60 or game.realms.world.stock.wheat >= 2:
		return
	var village: VillageInventory = game.simulation.economy.stock
	var frontier: FrontierTrade = game.career.frontier
	if frontier.stock.wheat < 3 and frontier.dispatch_relief(village, day, frontier.road_closed):
		_note("A banca de Lina despachou trigo pelo acordo de abastecimento.")
		game.career.caravan.reset()

func location(game: Node3D) -> String:
	var position: Vector3 = game.player.position
	if game.realms.world.active:
		return "capital"
	return "frontier" if position.x > 16.8 and position.z < -4.0 else "vale"

func counter(region: String) -> Vector3:
	match region:
		"capital": return RealmWorld.MARKET
		"frontier": return FrontierTrade.DESTINATION
	return ValeLife.STATIONS.contracts

func quote(game: Node3D, region: String, item: String) -> int:
	if region == "capital" and item in RealmWorld.GOODS:
		return game.realms.world.price(item)
	if region == "frontier" and item in FrontierTrade.GOODS:
		return game.career.frontier.retail_price(item)
	var base: int = LifeCatalog.GOODS[item][4]
	if region != "vale" or item != "wheat":
		return base
	var stock := amount(game, region, item)
	var factor := clampf(1.45 - stock * float(rules.scarcity_per_unit),
		float(rules.price_floor), float(rules.price_ceiling))
	return maxi(1, roundi(base * factor))

func amount(game: Node3D, region: String, item: String) -> int:
	if region == "capital":
		return int(game.realms.world.stock.get(item, 0)) + int(deliveries.get(region, {}).get(item, 0))
	if region == "frontier":
		return int(game.career.frontier.stock.get(item, 0)) + int(deliveries.get(region, {}).get(item, 0))
	if item == "wheat":
		return game.simulation.economy.stock.amount("market", "trigo")
	return int(game.career.life.stock.get(item, 0))

func act(game: Node3D, id: String, verb: String) -> String:
	if not rules.contracts.has(id):
		return "Contrato desconhecido."
	var order: Dictionary = rules.contracts[id]
	var life: PlayerLife = game.career.life
	var at: Vector3 = game.player.position
	if at.distance_to(counter(order.region)) > 2.6 or location(game) != order.region:
		return "Vá ao balcão do contratante."
	var job: Dictionary = contracts.get(id, {})
	var day: int = game.simulation.clock.total_day()
	if verb == "economy_accept":
		if not available(id, day) or not _debit(game, order.region, int(order.pay)):
			return "Contrato indisponível ou sem orçamento."
		contracts[id] = {"state": "ACEITO", "ends": day + int(order.days), "reserve": int(order.pay),
			"uid": life.profile.uid, "done": 0, "reopen": day + int(order.get("repeat_days", 0))}
		_note("Pedido aceito · " + order.issuer)
		return "Pagamento reservado pelo contratante."
	if job.get("uid") != life.profile.uid or job.get("state") not in ["ACEITO", "EM_ANDAMENTO"] or day >= int(job.ends):
		return "Contrato sem entrega válida."
	if verb == "economy_cancel":
		_credit(game, order.region, int(job.reserve))
		job.state = "CANCELADO"
		job.reserve = 0
		return "Reserva devolvida ao contratante."
	if verb != "economy_deliver":
		return "Ação desconhecida."
	var item: String = order.item
	if item in life.equipment.values() or (LifeCatalog.max_durability(item) > 0 and int(life.bag.condition.get(item, 0)) < LifeCatalog.max_durability(item)):
		return "Entregue um produto em bom estado e fora do equipamento."
	var count := mini(life.bag.amount(item), int(order.quantity) - int(job.done))
	if count <= 0:
		return "Nenhum produto elegível na bolsa."
	if order.region == "vale" and item == "wheat":
		var stocks: VillageInventory = game.simulation.economy.stock
		if not stocks.add("market", "trigo", count):
			return "A banca está cheia."
	elif order.region == "capital" and item in RealmWorld.GOODS:
		var realm: RealmWorld = game.realms.world
		if int(realm.stock[item]) + count > int(RealmWorld.LIMITS[item]):
			return "O mercado está cheio."
		realm.stock[item] += count
	elif order.region == "vale":
		if amount(game, "vale", item) + count > 99:
			return "O contratante está sem espaço."
		life.stock[item] = amount(game, "vale", item) + count
	else:
		var store: Dictionary = deliveries.get_or_add(order.region, {})
		if int(store.get(item, 0)) + count > 99:
			return "O contratante está sem espaço."
		store[item] = int(store.get(item, 0)) + count
	life.bag.spend({item: count})
	job.done += count
	if int(job.done) < int(order.quantity):
		job.state = "EM_ANDAMENTO"
		return "Entrega parcial registrada."
	life.gold += int(job.reserve)
	job.reserve = 0
	job.state = "CONCLUÍDO"
	if order.region != "vale":
		diplomacy.change(4, "Fornecedor cumpriu pedido em Brumária")
	game.society.civic_reputation[order.region] = int(game.society.civic_reputation.get(order.region, 0)) + 1
	game.society.note(order.issuer + " recebeu a encomenda de " + life.profile.name + ".")
	_note("Pedido concluído · " + order.issuer)
	return "Entrega concluída e paga."

func available(id: String, day: int) -> bool:
	var job: Dictionary = contracts.get(id, {})
	return job.is_empty() or (int(rules.contracts[id].get("repeat_days", 0)) > 0
		and job.state in ["CONCLUÍDO", "FALHOU", "CANCELADO"] and day >= int(job.reopen))

func _debit(game: Node3D, region: String, value: int) -> bool:
	var balance: int = game.career.life.treasury if region == "vale" else game.realms.world.treasury
	if balance < value:
		return false
	_credit(game, region, -value)
	return true

func _credit(game: Node3D, region: String, value: int) -> void:
	if region == "vale":
		game.career.life.treasury += value
	else:
		game.realms.world.treasury += value

func _note(message: String) -> void:
	history.append(message)
	if history.size() > 20:
		history.pop_front()

func snapshot() -> Dictionary:
	return {"diplomacy": diplomacy.snapshot(), "contracts": contracts.duplicate(true), "deliveries": deliveries.duplicate(true),
		"history": history.duplicate(), "day": last_day, "dry": drought, "convoys": prior_deliveries, "customs": prior_customs}

func restore(data: Variant) -> void:
	if not data is Dictionary:
		data = {}
	diplomacy.restore(data.get("diplomacy"))
	contracts.clear()
	deliveries.clear()
	history.clear()
	next_update = 0.0
	last_day = int(LifeCatalog.number(data.get("day"), -1, -1, 3650000))
	prior_deliveries = int(LifeCatalog.number(data.get("convoys"), -1, -1, 1000000))
	prior_customs = int(LifeCatalog.number(data.get("customs"), -1, -1, 1000000))
	drought = data.get("dry") == true
	if data.get("contracts") is Dictionary:
		for id in rules.contracts:
			var job: Variant = data.contracts.get(id)
			if job is Dictionary and job.get("uid") is String and job.get("state") in ["ACEITO", "EM_ANDAMENTO", "CONCLUÍDO", "FALHOU", "CANCELADO"]:
				contracts[id] = {"state": job.state, "uid": job.uid.left(32),
					"ends": int(LifeCatalog.number(job.get("ends"), 0, 0, 3650000)),
					"reopen": int(LifeCatalog.number(job.get("reopen"), int(LifeCatalog.number(job.get("ends"), 0, 0, 3650000)) + 1, 0, 3650000)),
					"done": int(LifeCatalog.number(job.get("done"), 0, 0, rules.contracts[id].quantity)),
					"reserve": int(rules.contracts[id].pay) if job.state in ["ACEITO", "EM_ANDAMENTO"] else 0}
	if data.get("deliveries") is Dictionary:
		for order in rules.contracts.values():
			var row: Variant = data.deliveries.get(order.region)
			if order.region != "vale" and row is Dictionary:
				var saved: Dictionary = deliveries.get_or_add(order.region, {})
				saved[order.item] = int(LifeCatalog.number(row.get(order.item), 0, 0, 99))
	if data.get("history") is Array:
		for line in data.history.slice(0, 20):
			if line is String:
				history.append(line.left(160))
