class_name VillageEconomy
extends RefCounted

const CROP_NAMES := ["Preparar a terra", "Plantar", "Regar", "Cultivar", "Colher"]
const MARKET_HOURS := "07:00–19:00"
const FORGE_HOURS := "07:00–18:00"
var stock := VillageInventory.new()
var journal := VillageJournal.new()
var crop := 4
var dry := false
var supply_priority := false
var crop_due := 0.0
var demand := 0
var last_forge := -90.0
var last_purchase := -30.0

func farm(clock: WorldClock, wet: bool) -> String:
	if crop == 3 and clock.elapsed < crop_due:
		return "Cuida dos brotos"
	match crop:
		0, 1:
			crop += 1
			return CROP_NAMES[crop - 1]
		2:
			crop = 3
			crop_due = clock.elapsed + (27.0 if demand > 0 else 44.0) * (1.45 if dry else 1.0)
			return "A chuva regou a horta" if wet else "Rega os canteiros"
		3, 4:
			if stock.add("teresa", "trigo", 3):
				crop = 0
				demand = maxi(0, demand - 1)
				journal.record(clock, "harvest", "Teresa colheu 3 feixes de trigo.")
				return "Leva a colheita ao depósito"
	return "Depósito da horta cheio"

func forge(clock: WorldClock) -> String:
	if clock.elapsed >= last_forge + 35.0 and stock.craft("forge", {"ferro": 1, "madeira": 1}, "ferramentas", 1):
		last_forge = clock.elapsed
		journal.record(clock, "forge", "Baltasar forjou uma ferramenta com ferro e madeira.")
		return "Forja uma ferramenta"
	return "Organiza a oficina"

func market(clock: WorldClock) -> String:
	if supply_priority and stock.amount("market", "alimentos") >= 4 and stock.amount("market", "trigo") <= 7:
		return "Preserva a reserva de trigo"
	if stock.craft("market", {"trigo": 2}, "alimentos", 3):
		journal.record(clock, "market", "A banca preparou 3 rações a partir do trigo.")
		return "Prepara as rações"
	return "Arruma as mercadorias"

func buy(clock: WorldClock, buyer: String) -> bool:
	if clock.hour() < 7.0 or clock.hour() >= 19.0 or clock.elapsed < last_purchase + 18.0:
		return false
	if not stock.spend("market", {"alimentos": 1}):
		return false
	last_purchase = clock.elapsed
	demand = mini(25, demand + 1)
	journal.record(clock, "sale", "%s comprou alimento. A banca pediu mais trigo." % buyer)
	return true

func pick_wheat(clock: WorldClock) -> bool:
	if stock.amount("nilo", "trigo") > 0:
		return true
	var count := mini(3, stock.amount("farm", "trigo"))
	if count == 0 or not stock.transfer("farm", "nilo", "trigo", count):
		return false
	journal.record(clock, "pickup", "Nilo recolheu %d feixes na horta." % count)
	return true

func deliver_wheat(clock: WorldClock) -> bool:
	var count := stock.amount("nilo", "trigo")
	if count == 0 or not stock.transfer("nilo", "market", "trigo", count):
		return false
	journal.record(clock, "delivery", "Nilo entregou %d feixes à banca." % count)
	return true

func store_harvest(clock: WorldClock) -> bool:
	var count := stock.amount("teresa", "trigo")
	if count == 0 or not stock.transfer("teresa", "farm", "trigo", count):
		return false
	journal.record(clock, "farm_store", "Teresa guardou %d feixes no depósito da horta." % count)
	return true

func pick_forge_supply(clock: WorldClock) -> void:
	for item in ["ferro", "madeira"]:
		if stock.amount("forge", item) < 3 and stock.amount("nilo", item) == 0 and stock.transfer("depot", "nilo", item, 2):
			journal.record(clock, "pickup", "Nilo carregou %s para a forja." % item)

func deliver_forge_supply(clock: WorldClock) -> void:
	for item in ["ferro", "madeira"]:
		var count := stock.amount("nilo", item)
		if count > 0 and stock.transfer("nilo", "forge", item, count):
			journal.record(clock, "supply", "Nilo entregou %s à forja." % item)
	if stock.amount("nilo", "ferramentas") == 0 and stock.transfer("forge", "nilo", "ferramentas", 1):
		journal.record(clock, "pickup", "Nilo recolheu uma ferramenta na forja.")

func deliver_tools(clock: WorldClock) -> void:
	if stock.transfer("nilo", "depot", "ferramentas", 1):
		journal.record(clock, "supply", "Nilo entregou uma ferramenta no depósito da ponte.")

func rain(clock: WorldClock) -> void:
	if crop == 2:
		farm(clock, true)
		journal.record(clock, "rain", "A chuva regou os canteiros de Teresa.")

func snapshot() -> Dictionary:
	return {"stocks": stock.stocks.duplicate(true), "journal": journal.entries.duplicate(true),
		"crop": crop, "crop_due": crop_due, "demand": demand, "last_forge": last_forge, "last_purchase": last_purchase}

func restore(data: Dictionary) -> void:
	var stocks: Variant = data.get("stocks", {})
	stock.restore(stocks if stocks is Dictionary else {})
	journal.restore(data.get("journal", []))
	crop = int(_bounded(data.get("crop"), 4, 0, 4))
	demand = int(_bounded(data.get("demand"), 0, 0, 25))
	crop_due = _bounded(data.get("crop_due"), 0, 0, 3.0e10)
	last_forge = _bounded(data.get("last_forge"), -90, -90, 3.0e10)
	last_purchase = _bounded(data.get("last_purchase"), -30, -30, 3.0e10)

func _bounded(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	if (value is int or value is float) and is_finite(float(value)):
		return clampf(float(value), minimum, maximum)
	return fallback
