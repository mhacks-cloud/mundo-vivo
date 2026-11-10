class_name WorldSimulation
extends RefCounted

var clock := WorldClock.new()
var climate := RegionalClimate.new()
var construction := ConstructionManager.new()
var economy := VillageEconomy.new()

func tick(seconds: float) -> void:
	clock.advance(seconds)

func command(action: StringName) -> bool:
	if action == &"deliver_bridge_material":
		return reserve_build("player") and unload_build("player") and work_bridge()
	return false

func reserve_build(actor: String) -> bool:
	if construction.complete():
		return false
	var stock := economy.stock
	if not stock.first(actor).is_empty():
		return true
	var item := construction.required_item() if actor == "player" else _next_unreserved()
	if item.is_empty() or not stock.transfer("depot", actor, item, 1):
		return false
	construction.logistics(1)
	economy.journal.record(clock, "bridge_pickup", "%s separou %s no depósito da ponte." % [_actor_name(actor), item])
	return true

func _next_unreserved() -> String:
	var pending := {}
	for item in VillageInventory.GOODS:
		var count := 0
		for actor in ["ivo", "mara", "player", "site"]:
			count += economy.stock.amount(actor, item)
		pending[item] = count
	for index in range(construction.loads(), ConstructionManager.MATERIALS.size()):
		var item: String = ConstructionManager.MATERIALS[index]
		if pending[item] <= 0:
			return item
		pending[item] -= 1
	return ""

func unload_build(actor: String) -> bool:
	var stock := economy.stock
	var item := stock.first(actor)
	if construction.complete() or item.is_empty() or not stock.transfer(actor, "site", item, 1):
		return false
	construction.logistics(3)
	economy.journal.record(clock, "bridge_unload", "%s descarregou %s no canteiro." % [_actor_name(actor), item])
	_inspect_if_ready()
	return true

func work_bridge() -> bool:
	if construction.complete():
		return false
	_inspect_if_ready()
	if construction.inspection_until > clock.elapsed or not economy.stock.spend("site", {construction.required_item(): 1}):
		return false
	var prior := construction.phase()
	construction.deliver()
	if construction.phase() != prior:
		economy.journal.record(clock, "bridge", "Ponte nova · " + construction.phase_name() + ".")
	if construction.complete():
		for actor in ["ivo", "mara", "player", "site"]:
			return_build(actor)
	else:
		_inspect_if_ready()
	return true

func _inspect_if_ready() -> void:
	if construction.loads() == 7 and construction.inspection_until == 0.0 and economy.stock.amount("site", construction.required_item()) > 0:
		construction.inspect(clock.elapsed)
		economy.journal.record(clock, "bridge", "Ponte nova · inspeção de travessas e guarda-corpos.")

func return_build(actor: String) -> void:
	var stock := economy.stock
	for item in VillageInventory.GOODS:
		var amount := stock.amount(actor, item)
		if amount > 0:
			stock.transfer(actor, "depot", item, amount)

func snapshot() -> Dictionary:
	return {"elapsed": clock.elapsed, "bridge": construction.snapshot(), "economy": economy.snapshot()}

func restore(data: Dictionary) -> void:
	clock.elapsed = float(data["elapsed"])
	var economy_data: Variant = data.get("economy", {})
	economy.restore(economy_data if economy_data is Dictionary else {})
	construction.restore(data["bridge"])
	if not data.has("economy") and data.get("carrying") == true and not construction.complete():
		reserve_build("player")

func _actor_name(actor: String) -> String:
	return "O viajante" if actor == "player" else actor.capitalize()
