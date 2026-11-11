class_name Underworld
extends RefCounted

const NAME := "Irmandade do Junco"
const NPC := "Mira do Junco"
const HIDEOUT := Vector3(24.0, 0.10, -14.25)
const POSITIONS := {"Mira do Junco": "Líder", "Téo da Estrada": "Batedor"}
var member := ""
var reputation := 0
var treasury := 48
var purse := 70
var market: Array[Dictionary] = []
var carried: Array[Dictionary] = []
var settled: Array[String] = []
var history: Array[String] = []
var fee_total := 0
var contract := false
var paid_contract := false

func join(life: PlayerLife) -> bool:
	if not member.is_empty() or not life.profile.has("uid") or life.gold < 4:
		return false
	life.gold -= 4
	treasury += 4
	member = life.profile.uid
	_log(life.profile.name + " registrado por Mira.")
	return true

func salvage(trade: FrontierTrade) -> bool:
	if trade.loot.is_empty() or not receive_lot(str(trade.loot.get("origin", "")), "Emboscada na rota do Vale",
		str(trade.loot.get("owner", "")), str(trade.loot.get("owner_name", ""))):
		return false
	trade.loot.quantity -= 1
	if trade.loot.quantity <= 0:
		trade.loot.clear()
	return true

func receive_lot(id: String, origin: String, owner: String, owner_name: String) -> bool:
	if id.is_empty() or _has_origin(id) or market.size() >= 16:
		return false
	market.append({"id": id, "origin": origin, "owner": owner, "owner_name": owner_name,
		"quantity": 1, "state": "Retido no armazém"})
	reputation += 1
	_log("A Irmandade recolheu um fardo da carroça.")
	return true

func buy(life: PlayerLife, id: String) -> bool:
	var index := _find(market, id)
	if member != life.profile.get("uid") or index < 0 or carried.size() >= 6 or life.gold < 7:
		return false
	var lot := market.pop_at(index) as Dictionary
	life.gold -= 7
	purse += 6
	treasury += 1
	fee_total += 1
	lot.state = "Em posse do associado"
	carried.append(lot)
	_log("Compra de fardo rastreado · 7 ouro, com taxa.")
	return true

func sell(life: PlayerLife, id: String) -> bool:
	var index := _find(carried, id)
	if member != life.profile.get("uid") or index < 0 or purse < 3 or market.size() >= 16:
		return false
	var lot := carried.pop_at(index) as Dictionary
	purse -= 3
	life.gold += 3
	lot.state = "Retido no armazém"
	market.append(lot)
	reputation += 1
	_log("Revenda de fardo · 3 ouro líquidos.")
	return true

func accept(life: PlayerLife) -> bool:
	if member != life.profile.get("uid") or paid_contract or contract or treasury < 4:
		return false
	contract = true
	_log("Contrato clandestino registrado para um fardo rastreado.")
	return true

func deliver(life: PlayerLife, id: String) -> bool:
	var index := _find(carried, id)
	if member != life.profile.get("uid") or not contract or paid_contract or index < 0 or treasury < 4:
		return false
	treasury -= 4
	life.gold += 4
	carried.remove_at(index)
	settled.append(id)
	paid_contract = true
	contract = false
	reputation += 2
	_log("Contrato liquidado. O lote saiu de circulação.")
	return true

func _find(items: Array[Dictionary], id: String) -> int:
	for i in items.size():
		if items[i].id == id:
			return i
	return -1

func _has_origin(id: String) -> bool:
	return id in settled or _find(market, id) >= 0 or _find(carried, id) >= 0

func _log(message: String) -> void:
	history.append(message)
	if history.size() > 32:
		history.pop_front()

func snapshot() -> Dictionary:
	return {"member": member, "reputation": reputation, "treasury": treasury, "purse": purse, "market": market.duplicate(true),
		"carried": carried.duplicate(true), "settled": settled.duplicate(), "history": history.duplicate(),
		"fees": fee_total, "contract": contract, "paid": paid_contract}

func restore(data: Variant, uid: String) -> void:
	if not data is Dictionary:
		data = {}
	member = uid if data.get("member") == uid else ""
	reputation = int(LifeCatalog.number(data.get("reputation"), 0, 0, 10000))
	treasury = int(LifeCatalog.number(data.get("treasury"), 48, 0, 1000000))
	purse = int(LifeCatalog.number(data.get("purse"), 70, 0, 1000000))
	fee_total = int(LifeCatalog.number(data.get("fees"), 0, 0, 100000))
	contract = data.get("contract") == true
	paid_contract = data.get("paid") == true
	market.clear()
	carried.clear()
	settled.clear()
	history.clear()
	if data.get("settled") is Array:
		for id in data.settled.slice(0, 32):
			if id is String:
				settled.append(id.left(80))
	_restore_lots(data.get("market"), market, 16, "Retido no armazém")
	_restore_lots(data.get("carried"), carried, 6, "Em posse do associado")
	if data.get("history") is Array:
		for line in data.history.slice(0, 32):
			if line is String:
				_log(line.left(160))

func _restore_lots(values: Variant, target: Array[Dictionary], limit: int, state: String) -> void:
	if not values is Array:
		return
	for lot in values.slice(0, limit):
		if lot is Dictionary and lot.get("id") is String and lot.get("owner") is String and not _has_origin(lot.id.left(80)):
			target.append({"id": lot.id.left(80), "owner": lot.owner.left(32), "owner_name": str(lot.get("owner_name", "")).left(40), "origin": str(lot.get("origin", "Emboscada na rota do Vale")).left(80), "quantity": 1, "state": state})
