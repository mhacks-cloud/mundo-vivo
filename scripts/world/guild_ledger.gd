class_name GuildLedger
extends RefCounted

const NAME := "Companhia do Vau"
const HALL := Vector3(-3.08, 0.10, -4.05)
const OFFICERS := {
	"Lina": "Líder", "Nilo": "Oficial", "Baltasar": "Tesoureiro", "Afonso": "Capitão"
}
const PAY := 9
var member := ""
var treasury := 60
var reputation := 0
var storage := LifeInventory.new()
var records: Array[String] = []
var escort := false
var traveled := 0.0
var guarded := 0.0

func _init() -> void:
	storage.capacity = 120.0

func role() -> String:
	if member.is_empty():
		return "Visitante"
	return "Oficial" if reputation >= 2 else "Membro"

func join(life: PlayerLife) -> bool:
	if not member.is_empty() or not life.profile.has("uid"):
		return false
	member = life.profile.uid
	_record(life.profile.name + " entrou na Companhia.")
	return true

func deposit(life: PlayerLife, id: String) -> bool:
	if not _member(life) or id in life.equipment.values() or not life.bag.transfer(storage, id, 1):
		return false
	_record("Armazém recebeu " + LifeCatalog.label(id) + ".")
	return true

func withdraw(life: PlayerLife, id: String) -> bool:
	if not _member(life) or reputation < 2 or not storage.transfer(life.bag, id, 1):
		return false
	_record("Oficial retirou " + LifeCatalog.label(id) + ".")
	return true

func contribute(life: PlayerLife) -> bool:
	if not _member(life) or life.gold < 5:
		return false
	life.gold -= 5
	treasury += 5
	_record("Tesouro recebeu 5 ouro.")
	life.logbook("Companhia do Vau · −5 ouro")
	return true

func sign(life: PlayerLife, trade: FrontierTrade) -> bool:
	if not _member(life) or escort or trade.shipment.is_empty() or trade.shipment.position.distance_to(FrontierTrade.ORIGIN) > 3.0 or treasury < PAY:
		return false
	treasury -= PAY
	escort = true
	traveled = 0
	guarded = 0
	_record("Escolta contratada · 9 ouro em reserva.")
	return true

func travel(distance: float, near: bool) -> void:
	if not escort or distance <= 0:
		return
	traveled += distance
	if near:
		guarded += distance

func finish(life: PlayerLife, delivered := true) -> void:
	if not escort:
		return
	escort = false
	if delivered and _member(life) and traveled >= 5.0 and guarded / traveled >= 0.60:
		life.gold += PAY
		reputation += 1
		_record("Escolta concluída · 9 ouro e 1 reputação.")
		life.logbook("Escolta da Companhia · +9 ouro")
	else:
		treasury += PAY
		_record("Escolta sem entrega válida · reserva devolvida à Companhia.")

func reserve_highland_escort(life: PlayerLife) -> bool:
	if not _member(life) or treasury < PAY:
		return false
	treasury -= PAY
	_record("Escolta de Alto da Bruma contratada · 9 ouro em reserva.")
	return true

func settle_highland_escort(life: PlayerLife, delivered: bool, traveled_distance: float, covered_distance: float) -> void:
	if delivered and _member(life) and traveled_distance >= 5.0 and covered_distance / traveled_distance >= 0.60:
		life.gold += PAY
		reputation += 1
		_record("Escolta de Alto da Bruma concluída · 9 ouro e 1 reputação.")
	else:
		treasury += PAY
		_record("Reserva da escolta de Alto da Bruma devolvida.")

func _member(life: PlayerLife) -> bool:
	return not member.is_empty() and member == life.profile.get("uid", "")

func _record(message: String) -> void:
	records.append(message)
	if records.size() > 24:
		records.pop_front()

func snapshot() -> Dictionary:
	return {"member": member, "treasury": treasury, "reputation": reputation, "storage": storage.snapshot(),
		"records": records.duplicate(), "escort": escort, "traveled": traveled, "guarded": guarded}

func restore(data: Variant, life: PlayerLife, trade: FrontierTrade) -> void:
	if not data is Dictionary:
		data = {}
	var id: Variant = data.get("member")
	member = id if id is String and id == life.profile.get("uid") else ""
	treasury = int(LifeCatalog.number(data.get("treasury"), 60, 0, 1000000))
	reputation = int(LifeCatalog.number(data.get("reputation"), 0, 0, 10000))
	storage.restore(data.get("storage"))
	records.clear()
	var lines: Variant = data.get("records")
	if lines is Array:
		for entry in lines.slice(0, 24):
			if entry is String:
				records.append(entry.left(120))
	escort = data.get("escort") == true and not member.is_empty()
	if escort and trade.shipment.is_empty():
		escort = false
		treasury += PAY
	traveled = LifeCatalog.number(data.get("traveled"), 0, 0, 10000)
	guarded = LifeCatalog.number(data.get("guarded"), 0, 0, traveled)
