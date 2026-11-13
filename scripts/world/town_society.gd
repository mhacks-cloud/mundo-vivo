class_name TownSociety
extends RefCounted

const START_CASH := 48
const FOOD_PRICE := 2
const WAGE := 3
const RENT := 1
const INTERVAL := 5.0
const HOMES := {"ivo": "oficina", "mara": "oficina", "lina": "banca", "baltasar": "forja",
	"teresa": "horta", "nilo": "entreposto", "afonso": "posto", "beatriz": "casa", "branca": "vigia"}
const EMPLOYERS := {"ivo": "civic", "mara": "civic", "lina": "trade", "baltasar": "forge",
	"teresa": "farm", "nilo": "trade", "afonso": "civic", "branca": "civic"}
const SHOPS := {"farm": "Fazenda de Teresa", "forge": "Ferraria de Baltasar",
	"trade": "Banca de Lina e Companhia do Vau", "civic": "Administração do Vale"}
var people: Dictionary = {}
var shops: Dictionary = {}
var families: Dictionary = {}
var news: Array[String] = []
var last_day := -1
var next_poll := 0.0
var last_houses := 0
var last_workshop := false
var fair_day := -1
var fair_food := 0
var civic_reputation: Dictionary = {}

func _init() -> void:
	restore(null)

func work(id: String, day: int) -> bool:
	if not EMPLOYERS.has(id) or int(people[id].paid) == day:
		return false
	var employer: Dictionary = shops[EMPLOYERS[id]]
	if employer.cash < WAGE:
		return false
	employer.cash -= WAGE
	employer.wages += WAGE
	people[id].cash += WAGE
	people[id].paid = day
	return true

func afford_food(id: String) -> bool:
	if not people.has(id):
		return false
	var family: Dictionary = families[HOMES[id]]
	return people[id].cash + family.cash >= FOOD_PRICE

func buy_food(id: String, day: int) -> void:
	if not afford_food(id):
		return
	var direct := mini(int(people[id].cash), FOOD_PRICE)
	people[id].cash -= direct
	families[HOMES[id]].cash -= FOOD_PRICE - direct
	shops.trade.cash += FOOD_PRICE - 1
	shops.civic.cash += 1
	shops.trade.sales += 1
	people[id].meal = day

func procurement(source: String, destination: String, price: int) -> bool:
	if shops[source].cash < price:
		return false
	shops[source].cash -= price
	shops[destination].cash += price
	return true

func advance(game: Node3D) -> void:
	var clock: WorldClock = game.simulation.clock
	if clock.elapsed < next_poll and next_poll - clock.elapsed <= INTERVAL:
		return
	next_poll = clock.elapsed + INTERVAL
	var day := clock.total_day()
	var realm: RealmWorld = game.realms.world
	if realm.houses > last_houses:
		note("Pouso da Geada · Célia ocupou a moradia inaugurada em Brumária.")
	last_houses = realm.houses
	if realm.workshop and not last_workshop:
		note("Alto da Bruma · oficina de Tomás inaugurada no Pouso da Geada.")
	last_workshop = realm.workshop
	if day == last_day:
		return
	last_day = day
	for id in people:
		var person: Dictionary = people[id]
		var household: Dictionary = families[HOMES[id]]
		if person.cash >= 7:
			person.cash -= RENT
			household.cash += RENT
		if household.cash >= 8:
			household.cash -= RENT
			shops.civic.cash += RENT
	if day > 0 and day % 24 == 10:
		fair_day = day
		var stock: VillageInventory = game.simulation.economy.stock
		if fair_food == 0 and stock.spend("market", {"alimentos": 2}):
			fair_food += 2
		note("Vale · Feira da Colheita marcada na praça.")

func fair_open(clock: WorldClock) -> bool:
	return fair_day == clock.total_day() and clock.hour() >= 8.0 and clock.hour() < 19.0

func buy_fair(life: PlayerLife, clock: WorldClock) -> bool:
	if not fair_open(clock) or fair_food <= 0 or life.gold < FOOD_PRICE or not life.bag.add("food", 1):
		return false
	fair_food -= 1
	life.gold -= FOOD_PRICE
	shops.trade.cash += FOOD_PRICE
	shops.trade.sales += 1
	return true

func satisfaction(game: Node3D, region: String) -> int:
	if region == "capital":
		var realm: RealmWorld = game.realms.world
		return clampi(40 + int(realm.stock.wheat) * 3 + realm.houses * 15 - (12 if realm.damaged else 0), 0, 100)
	var food: int = game.simulation.economy.stock.amount("market", "alimentos")
	var safety := 0 if game.career.authority.works.road_closed else 12
	var staffed := 0
	for id in EMPLOYERS:
		if people[id].paid == last_day and last_day >= 0:
			staffed += 1
	return clampi(24 + mini(26, food * 4) + staffed * 4 + safety, 0, 100)

func note(message: String) -> void:
	news.append(message)
	if news.size() > 24:
		news.pop_front()

func snapshot() -> Dictionary:
	return {"people": people.duplicate(true), "shops": shops.duplicate(true), "families": families.duplicate(true),
		"news": news.duplicate(), "day": last_day, "houses": last_houses, "workshop": last_workshop, "fair": fair_day, "fair_food": fair_food, "reputation": civic_reputation.duplicate()}

func restore(data: Variant) -> void:
	if not data is Dictionary:
		data = {}
	people.clear()
	shops.clear()
	families.clear()
	news.clear()
	civic_reputation.clear()
	for id in HOMES:
		var entry := _row(data, "people", id)
		people[id] = {"cash": _number(entry, "cash", 6), "paid": _number(entry, "paid", -1), "meal": _number(entry, "meal", -1)}
		var home: String = HOMES[id]
		if not families.has(home):
			families[home] = {"cash": _number(_row(data, "families", home), "cash", 0), "members": []}
		families[home].members.append(id)
	for id in SHOPS:
		var entry := _row(data, "shops", id)
		shops[id] = {"cash": _number(entry, "cash", START_CASH), "wages": _number(entry, "wages", 0), "sales": _number(entry, "sales", 0)}
	last_day = _number(data, "day", -1)
	last_houses = _number(data, "houses", 0)
	last_workshop = data.get("workshop") == true
	fair_day = _number(data, "fair", -1)
	fair_food = _number(data, "fair_food", 0)
	next_poll = 0
	if data.get("reputation") is Dictionary:
		for region in ["vale", "frontier", "capital"]:
			civic_reputation[region] = _number(data.reputation, region, 0)
	if data.get("news") is Array:
		for line in data.news.slice(0, 24):
			if line is String:
				news.append(line.left(180))

func _row(data: Dictionary, group: String, id: String) -> Dictionary:
	if data.get(group) is Dictionary and data[group].get(id) is Dictionary:
		return data[group][id]
	return {}

func _number(data: Dictionary, id: String, fallback: int) -> int:
	return int(LifeCatalog.number(data.get(id), fallback, -1 if fallback < 0 else 0, 1000000))
