class_name PlayerLife
extends RefCounted

signal changed
const ID := "local-viajante"
const CONTRACTS := {
	"provision": {"title": "Provisões do vale", "item": "wheat", "qty": 3, "pay": 15},
	"remedy": {"title": "Remédio para a taberna", "item": "health", "qty": 1, "pay": 10},
	"furniture": {"title": "Banco para a praça", "item": "chair", "qty": 1, "pay": 14},
	"ironwork": {"title": "Enxada de reposição", "item": "hoe", "qty": 1, "pay": 15},
	"bridge": {"title": "Madeira para a Ponte Nova", "item": "wood", "qty": 2, "pay": 8}
}
var profile: Dictionary = {}
var bag := LifeInventory.new()
var chest := LifeInventory.new()
var estate := Homestead.new()
var equipment: Dictionary = {}
var stock: Dictionary = LifeCatalog.STOCK.duplicate()
var journal: Array[String] = []
var completed: Array[String] = []
var plants: Dictionary = {}
var gather_due: Dictionary = {}
var discovered: Array[String] = []
var xp := 0
var gold := 0
var hp := 100.0
var mana := 60.0
var treasury := 800
var market_cash := 170
var reputation := 0
var coop_due := 0.0
var cooldown := 0.0

func _init() -> void:
	chest.capacity = 260.0

func role() -> String:
	return profile.get("class", "")

func level() -> int:
	return 1 + floori(sqrt(float(xp) / 55.0))

func max_hp() -> float:
	return 125.0 if role() == "warrior" else 100.0

func max_mana() -> float:
	return 100.0 if role() in ["mage", "healer"] else 60.0

func create(raw: String, profession: String, nation: String, coat: int, hair: int) -> bool:
	var clean := LifeCatalog.clean_name(raw)
	if not profile.is_empty() or clean.is_empty() or not LifeCatalog.CLASSES.has(profession) or not LifeCatalog.NATIONS.get(nation, {}).get("playable", false):
		return false
	if coat < 0 or coat >= LifeCatalog.COLORS.size() or hair < 0 or hair >= LifeCatalog.HAIR.size():
		return false
	profile = {"name": clean, "class": profession, "nation": nation, "coat": coat, "hair": hair,
		"uid": Crypto.new().generate_random_bytes(16).hex_encode()}
	gold = 48
	treasury = LifeCatalog.NATIONS[nation].treasury
	hp = max_hp()
	mana = max_mana()
	var starter := {"wood": 22, "stone": 8, "food": 2}
	match profession:
		"farmer": starter.merge({"seed": 4, "herb_seed": 3})
		"doctor": starter.merge({"herb": 7, "vial": 3})
		"smith": starter.merge({"iron": 6})
		"archer": starter.merge({"arrow": 24})
		"warrior": starter.merge({"armor": 1})
	for id in starter:
		bag.add(id, starter[id])
	var main_item: String = LifeCatalog.CLASSES[profession].start
	bag.add(main_item, 1)
	equip(main_item)
	if profession == "warrior":
		equip("armor")
	logbook("Carta de cidadania assinada.")
	return true

func claim(id: String) -> bool:
	if profile.is_empty() or not estate.can_claim(id, ID) or id not in LifeCatalog.NATIONS[profile.nation].plots:
		return false
	var price: int = Homestead.PLOTS[id].price
	if gold < price:
		return false
	gold -= price
	treasury += price
	estate.claim(id, ID)
	logbook("−%d ouro · terreno %s" % [price, Homestead.PLOTS[id].name])
	return true

func logbook(message: String) -> void:
	journal.append(message)
	if journal.size() > 36:
		journal.pop_front()
	changed.emit()

func award(amount: int) -> void:
	if not profile.is_empty() and amount > 0:
		xp = mini(500000, xp + amount)
		changed.emit()

func equip(id: String) -> bool:
	var slot := LifeCatalog.slot(id)
	if slot.is_empty() or bag.amount(id) != 1 or int(bag.condition.get(id, 0)) <= 0 or role() not in LifeCatalog.GOODS[id][7]:
		return false
	equipment[slot] = id
	changed.emit()
	return true

func equipped(slot: String) -> String:
	var item: String = equipment.get(slot, "")
	return item if bag.amount(item) > 0 and int(bag.condition.get(item, 0)) > 0 else ""

func wear(slot: String, quantity := 1) -> void:
	if quantity <= 0:
		return
	var item := equipped(slot)
	if not item.is_empty():
		bag.condition[item] = maxi(0, int(bag.condition[item]) - quantity)
		changed.emit()

func transfer(id: String, quantity: int, into_chest: bool) -> bool:
	if id in equipment.values() and into_chest:
		return false
	var origin := bag if into_chest else chest
	var destination := chest if into_chest else bag
	if not origin.transfer(destination, id, quantity):
		return false
	changed.emit()
	return true

func discard(id: String, quantity: int) -> bool:
	if id in equipment.values() or not bag.spend({id: quantity}):
		return false
	changed.emit()
	return true

func unequip(id: String) -> bool:
	var slot := LifeCatalog.slot(id)
	if equipment.get(slot) != id:
		return false
	equipment.erase(slot)
	changed.emit()
	return true

func use_item(id: String) -> bool:
	if (id in ["health", "food"] and hp < max_hp()) or (id == "mana" and mana < max_mana()):
		if not bag.spend({id: 1}):
			return false
		if id == "mana":
			mana = minf(max_mana(), mana + 45)
		else:
			hp = minf(max_hp(), hp + (45 if id == "health" else 14))
		changed.emit()
		return true
	return false

func buy(id: String, quantity: int) -> bool:
	if profile.is_empty() or not LifeCatalog.GOODS.has(id) or quantity <= 0 or quantity > int(stock.get(id, 0)) or not bag.can_add(id, quantity):
		return false
	var price: int = LifeCatalog.GOODS[id][4] * quantity
	if gold < price:
		return false
	bag.add(id, quantity)
	stock[id] -= quantity
	gold -= price
	var levy := maxi(1, floori(price * float(LifeCatalog.NATIONS[profile.nation].tax)))
	treasury += levy
	market_cash += price - levy
	logbook("−%d ouro · %s ×%d" % [price, LifeCatalog.label(id), quantity])
	return true

func buy_wheat(village: VillageInventory, price: int = 4) -> bool:
	price = maxi(1, price)
	if profile.is_empty() or gold < price or not bag.can_add("wheat", 1) or not village.spend("market", {"trigo": 1}):
		return false
	bag.add("wheat", 1)
	gold -= price
	treasury += 1
	market_cash += price - 1
	logbook("−%d ouro · trigo da banca de Lina" % price)
	return true

func sell(id: String, quantity: int, village: VillageInventory) -> bool:
	if profile.is_empty() or not LifeCatalog.GOODS.has(id) or quantity <= 0 or bag.amount(id) < quantity or id in equipment.values():
		return false
	if LifeCatalog.max_durability(id) > 0 and int(bag.condition.get(id, 0)) < LifeCatalog.max_durability(id):
		return false
	var payment := maxi(1, floori(float(LifeCatalog.GOODS[id][4]) * 0.42)) * quantity
	if market_cash < payment:
		return false
	if LifeCatalog.VILLAGE_GOODS.has(id):
		var mapped: String = LifeCatalog.VILLAGE_GOODS[id]
		var place := "depot" if id in ["wood", "stone", "iron"] else "market"
		if not village.add(place, mapped, quantity):
			return false
	elif int(stock.get(id, 0)) + quantity > 999:
		return false
	else:
		stock[id] = int(stock.get(id, 0)) + quantity
	bag.spend({id: quantity})
	market_cash -= payment
	gold += payment
	logbook("+%d ouro · venda de %s ×%d" % [payment, LifeCatalog.label(id), quantity])
	return true

func craft(id: String, station: String) -> bool:
	var recipe: Dictionary = LifeCatalog.RECIPES.get(id, {})
	if recipe.is_empty() or role() != recipe["class"] or station != recipe.station or level() < recipe.level or equipped("tool").is_empty():
		return false
	if not bag.transform(recipe.cost, id, recipe.qty):
		return false
	wear("tool")
	award(recipe.xp)
	logbook("Produção · %s ×%d" % [LifeCatalog.label(id), recipe.qty])
	return true

func repair(id: String, self_service: bool) -> bool:
	var maximum := LifeCatalog.max_durability(id)
	if maximum == 0 or bag.amount(id) == 0 or int(bag.condition.get(id, 0)) >= maximum:
		return false
	if self_service:
		if role() != "smith" or not bag.spend({"iron": 1}):
			return false
		award(6)
	else:
		if gold < 6:
			return false
		gold -= 6
		treasury += 6
		logbook("−6 ouro · reparo de " + LifeCatalog.label(id))
	bag.condition[id] = maximum
	changed.emit()
	return true

func fulfill(id: String, world: WorldSimulation) -> bool:
	var offer: Dictionary = CONTRACTS.get(id, {})
	if profile.is_empty() or offer.is_empty() or id in completed or treasury < offer.pay or offer.item in equipment.values() or not bag.has({offer.item: offer.qty}):
		return false
	if id == "bridge":
		if world.construction.complete() or not world.economy.stock.add("depot", "madeira", offer.qty):
			return false
		world.economy.journal.record(world.clock, "player_contract", profile.name + " forneceu madeira para a Ponte Nova.")
	elif id == "provision":
		if not world.economy.stock.add("market", "trigo", offer.qty):
			return false
	else:
		if int(stock.get(offer.item, 0)) + int(offer.qty) > 999:
			return false
		stock[offer.item] = int(stock.get(offer.item, 0)) + int(offer.qty)
	bag.spend({offer.item: offer.qty})
	completed.append(id)
	gold += offer.pay
	treasury -= offer.pay
	reputation += 2
	logbook("+%d ouro · contrato %s" % [offer.pay, offer.title])
	return true

func gather(source: String, now: float) -> bool:
	var yields := {"wood": 2, "stone": 2, "iron": 1, "herb": 2}
	if profile.is_empty() or not yields.has(source) or now < float(gather_due.get(source, 0.0)) or not bag.add(source, yields[source]):
		return false
	gather_due[source] = now + 85.0
	logbook("Coleta · " + LifeCatalog.label(source))
	return true

func farm(cell: Vector2i, action: String, now: float, rain := false, temperature := 18.0) -> bool:
	var plot := estate.owned(ID)
	if role() != "farmer" or equipped("tool").is_empty() or plot.is_empty():
		return false
	var key := "%d:%d" % [cell.x, cell.y]
	var has_bed := false
	for part in estate.pieces:
		if part.plot == plot and part.cell == cell and part.kind == "garden":
			has_bed = true
	if not has_bed:
		return false
	if action in ["seed", "herb_seed"]:
		if plants.has(key) or not bag.spend({action: 1}):
			return false
		var growth := 44.0 if temperature >= 12.0 and temperature <= 29.0 else 68.0
		plants[key] = {"crop": "wheat" if action == "seed" else "herb", "ready": now + growth, "wet": rain,
			"fertilized": false, "growth": growth}
		wear("tool")
		award(4)
	elif not plants.has(key):
		return false
	elif action == "water" and not plants[key].wet:
		plants[key].wet = true
		plants[key].ready = minf(plants[key].ready, now + float(plants[key].get("growth", 44.0)) * 0.5)
		award(3)
	elif action == "fertilize" and not plants[key].get("fertilized", false) and bag.spend({"egg": 1}):
		plants[key].fertilized = true
	elif action == "harvest" and plants[key].wet and now >= plants[key].ready:
		var yield_count := 6 if plants[key].get("fertilized", false) else 4
		if not bag.add(plants[key].crop, yield_count):
			return false
		var result: String = plants[key].crop
		plants.erase(key)
		wear("tool")
		award(18)
		logbook("Colheita · %s ×%d" % [LifeCatalog.label(result), yield_count])
	else:
		return false
	changed.emit()
	return true

func rain(now: float) -> void:
	for bed in plants.values():
		if not bed.wet:
			bed.wet = true
			bed.ready = minf(bed.ready, now + float(bed.get("growth", 44.0)) * 0.5)
			changed.emit()

func coop(now: float) -> bool:
	if role() != "farmer":
		return false
	if coop_due == 0.0 and bag.spend({"wheat": 1}):
		coop_due = now + 26.0
	elif coop_due > 0.0 and now >= coop_due and bag.add("egg", 2):
		coop_due = 0.0
		award(12)
		logbook("Galinheiro · 2 ovos recolhidos")
	else:
		return false
	changed.emit()
	return true

func explore(key: String) -> bool:
	if role() not in ["warrior", "archer", "mage", "healer"] or key in discovered:
		return false
	discovered.append(key)
	award(9)
	logbook("Descoberta · " + key)
	return true

func snapshot() -> Dictionary:
	return {"profile": profile.duplicate(), "xp": xp, "gold": gold, "hp": hp, "mana": mana, "treasury": treasury,
		"reputation": reputation, "market_cash": market_cash, "bag": bag.snapshot(), "chest": chest.snapshot(), "estate": estate.snapshot(),
		"equipment": equipment.duplicate(), "stock": stock.duplicate(), "journal": journal.duplicate(),
		"completed": completed.duplicate(), "plants": plants.duplicate(true), "gather": gather_due.duplicate(),
		"coop": coop_due, "cooldown": cooldown, "discovered": discovered.duplicate()}

func restore(data: Variant) -> void:
	if not data is Dictionary:
		data = {}
	profile.clear()
	var person: Variant = data.get("profile")
	if person is Dictionary and person.get("name") is String and person.get("class") is String and person.get("nation") is String:
		var name_value := LifeCatalog.clean_name(person.name)
		if not name_value.is_empty() and LifeCatalog.CLASSES.has(person["class"]) and LifeCatalog.NATIONS.get(person.nation, {}).get("playable", false):
			profile = {"name": name_value, "class": person["class"], "nation": person.nation,
				"coat": int(LifeCatalog.number(person.get("coat"), 0, 0, LifeCatalog.COLORS.size() - 1)),
				"hair": int(LifeCatalog.number(person.get("hair"), 0, 0, LifeCatalog.HAIR.size() - 1))}
	if not profile.is_empty() and person.get("uid") is String and person.uid.length() == 32 and person.uid.is_valid_hex_number(false):
		profile.uid = person.uid
	xp = int(LifeCatalog.number(data.get("xp"), 0, 0, 500000))
	gold = int(LifeCatalog.number(data.get("gold"), 0, 0, 1000000))
	hp = LifeCatalog.number(data.get("hp"), max_hp(), 0, max_hp())
	mana = LifeCatalog.number(data.get("mana"), max_mana(), 0, max_mana())
	treasury = int(LifeCatalog.number(data.get("treasury"), 800, 0, 1000000))
	reputation = int(LifeCatalog.number(data.get("reputation"), 0, 0, 10000))
	market_cash = int(LifeCatalog.number(data.get("market_cash"), 170, 0, 1000000))
	bag.restore(data.get("bag"))
	chest.restore(data.get("chest"))
	equipment.clear()
	var gear: Variant = data.get("equipment")
	if gear is Dictionary:
		for slot in ["weapon", "tool", "armor", "accessory"]:
			var id: Variant = gear.get(slot)
			if id is String and LifeCatalog.slot(id) == slot and bag.amount(id) > 0 and role() in LifeCatalog.GOODS[id][7]:
				equipment[slot] = id
	stock = LifeCatalog.STOCK.duplicate()
	var market: Variant = data.get("stock")
	if market is Dictionary:
		for id in LifeCatalog.GOODS:
			if market.has(id):
				stock[id] = int(LifeCatalog.number(market[id], 0, 0, 999))
	journal = _strings(data.get("journal"), 36)
	completed = _strings(data.get("completed"), CONTRACTS.size())
	discovered = _strings(data.get("discovered"), 12)
	plants.clear()
	var beds: Variant = data.get("plants")
	if beds is Dictionary:
		for key in beds.keys().slice(0, 25):
			var bed: Variant = beds[key]
			if key is String and key.length() == 3 and bed is Dictionary and bed.get("crop") in ["wheat", "herb"]:
				plants[key] = {"crop": bed.crop, "ready": LifeCatalog.number(bed.get("ready"), 0, 0, 3e10), "wet": bed.get("wet") == true,
					"fertilized": bed.get("fertilized") == true, "growth": LifeCatalog.number(bed.get("growth"), 44.0, 44.0, 68.0)}
	gather_due.clear()
	var gathered: Variant = data.get("gather")
	if gathered is Dictionary:
		for id in ["wood", "stone", "iron", "herb"]:
			gather_due[id] = LifeCatalog.number(gathered.get(id), 0, 0, 3e10)
	coop_due = LifeCatalog.number(data.get("coop"), 0, 0, 3e10)
	cooldown = LifeCatalog.number(data.get("cooldown"), 0, 0, 0.62)
	estate.restore(data.get("estate"))
	changed.emit()

func _strings(source: Variant, limit: int) -> Array[String]:
	var result: Array[String] = []
	if source is Array:
		for value in source.slice(0, limit):
			if value is String:
				result.append(value.left(160))
	return result
