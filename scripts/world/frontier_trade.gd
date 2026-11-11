class_name FrontierTrade
extends RefCounted

const GOODS := ["wheat", "wood", "iron", "herb", "health"]
const ORIGIN := Vector3(-1.45, 0.10, -8.80)
const DESTINATION := Vector3(22.35, 0.10, -8.15)
const BATCH := 3
var stock := {"wheat": 2, "wood": 7, "iron": 15, "herb": 3, "health": 2}
var purse := 120
var treasury := 70
var shipment: Dictionary = {}
var history: Array[String] = []
var deliveries := 0
var loot: Dictionary = {}
var last_day := -1
var climate := RegionalClimate.new()

func _init() -> void:
	climate.latitude = 44.5
	climate.altitude = 880
	climate.biome = "serra"

func price(id: String) -> int:
	if id not in GOODS:
		return 0
	var factor := clampf(1.58 - int(stock[id]) * 0.045, 0.78, 1.58)
	return maxi(2, roundi(float(LifeCatalog.GOODS[id][4]) * factor))

func buy(life: PlayerLife, id: String) -> bool:
	var charge := price(id)
	if life.profile.is_empty() or charge == 0 or stock[id] <= 0 or life.gold < charge or not life.bag.add(id, 1):
		return false
	var tax := maxi(1, floori(charge * 0.12))
	life.gold -= charge
	purse += charge - tax
	treasury += tax
	stock[id] -= 1
	_record("Compra · %s · %d ouro" % [LifeCatalog.label(id), charge])
	life.logbook("Brumária · −%d ouro" % charge)
	return true

func sell(life: PlayerLife, id: String) -> bool:
	var quote := price(id)
	var credit := maxi(1, floori(quote * 0.4))
	if life.profile.is_empty() or quote == 0 or purse < credit or stock[id] >= 999 or not life.bag.spend({id: 1}):
		return false
	stock[id] += 1
	purse -= credit
	life.gold += credit
	_record("Venda · %s · %d ouro" % [LifeCatalog.label(id), credit])
	life.logbook("Brumária · +%d ouro" % credit)
	return true

func dispatch(life: PlayerLife, day: int) -> bool:
	var reserved := price("wheat") * BATCH
	if life.profile.is_empty() or not shipment.is_empty() or day <= last_day or purse < reserved or not life.bag.spend({"wheat": BATCH}):
		return false
	purse -= reserved
	shipment = {"quantity": BATCH, "pay": reserved, "position": ORIGIN, "risk": 0 if day % 3 == 2 else 2,
		"guard": 3, "raider": 31.0}
	last_day = day
	_record("Carroça saiu do Vale com %d trigos." % BATCH)
	life.logbook("Frete para Brumária · 3 trigos carregados")
	return true

func arrive(life: PlayerLife) -> bool:
	if shipment.is_empty() or shipment.position.distance_squared_to(DESTINATION) > 0.4 * 0.4:
		return false
	var quantity: int = shipment.quantity
	if stock.wheat + quantity > 999:
		return false
	var payment: int = shipment.pay
	stock.wheat += quantity
	life.gold += payment
	deliveries += 1
	shipment.clear()
	_record("Frete entregue · %d trigos · %d ouro" % [quantity, payment])
	life.logbook("Carroça chegou a Brumária · +%d ouro" % payment)
	return true

func lose(now: float) -> bool:
	if shipment.is_empty():
		return false
	purse += int(shipment.pay)
	loot = {"quantity": shipment.quantity, "position": shipment.position, "expires": now + 120.0}
	shipment.clear()
	_record("A carroça foi derrotada. A carga caiu no caminho.")
	return true

func collect(life: PlayerLife, position: Vector3, now: float) -> bool:
	if loot.is_empty() or now >= float(loot.expires) or position.distance_to(loot.position) > 1.8:
		return false
	if not life.bag.add("wheat", int(loot.quantity)):
		return false
	loot.clear()
	_record("Carga caída recuperada.")
	return true

func _record(message: String) -> void:
	history.append(message)
	if history.size() > 24:
		history.pop_front()

func snapshot() -> Dictionary:
	var load_state := shipment.duplicate()
	if not shipment.is_empty():
		var p: Vector3 = shipment.position
		load_state.position = [p.x, p.z]
	var fallen := loot.duplicate()
	if not loot.is_empty():
		var p: Vector3 = loot.position
		fallen.position = [p.x, p.z]
	return {"loot": fallen, "stock": stock.duplicate(), "purse": purse, "treasury": treasury, "shipment": load_state,
		"history": history.duplicate(), "deliveries": deliveries, "last_day": last_day}

func restore(data: Variant) -> void:
	stock = {"wheat": 2, "wood": 7, "iron": 15, "herb": 3, "health": 2}
	purse = 120
	treasury = 70
	last_day = -1
	deliveries = 0
	shipment.clear()
	loot.clear()
	history.clear()
	if not data is Dictionary:
		return
	purse = int(LifeCatalog.number(data.get("purse"), purse, 0, 1000000))
	treasury = int(LifeCatalog.number(data.get("treasury"), treasury, 0, 1000000))
	last_day = int(LifeCatalog.number(data.get("last_day"), -1, -1, 3650000))
	deliveries = int(LifeCatalog.number(data.get("deliveries"), 0, 0, 3650000))
	if data.get("stock") is Dictionary:
		for id in GOODS:
			stock[id] = int(LifeCatalog.number(data.stock.get(id), stock[id], 0, 999))
	if data.get("history") is Array:
		for entry in data.history.slice(0, 24):
			if entry is String:
				history.append(entry.left(120))
	var load_state: Variant = data.get("shipment")
	if load_state is Dictionary and load_state.get("quantity") == BATCH and load_state.get("position") is Array and load_state.position.size() == 2:
		var p := Vector3(LifeCatalog.number(load_state.position[0], ORIGIN.x, -30, 32), 0.10,
			LifeCatalog.number(load_state.position[1], ORIGIN.z, -32, 32))
		var payment := int(LifeCatalog.number(load_state.get("pay"), 0, 0, 100))
		if payment > 0:
			shipment = {"quantity": BATCH, "pay": payment, "position": p,
				"risk": int(LifeCatalog.number(load_state.get("risk"), 2, 0, 2)),
				"guard": int(LifeCatalog.number(load_state.get("guard"), 3, 0, 3)),
				"raider": LifeCatalog.number(load_state.get("raider"), 31.0, 0, 31.0)}
	var fallen: Variant = data.get("loot")
	if fallen is Dictionary and fallen.get("quantity") == BATCH and fallen.get("position") is Array and fallen.position.size() == 2:
		var p := Vector3(LifeCatalog.number(fallen.position[0], ORIGIN.x, -30, 32), 0.10,
			LifeCatalog.number(fallen.position[1], ORIGIN.z, -32, 32))
		loot = {"quantity": BATCH, "position": p, "expires": LifeCatalog.number(fallen.get("expires"), 0, 0, 3.0e10)}
