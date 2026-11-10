class_name VillageInventory
extends RefCounted

const GOODS := ["madeira", "pedra", "ferro", "trigo", "alimentos", "ferramentas"]
const CAPACITY := 999
const INITIAL := {
	"farm": {"trigo": 0, "alimentos": 2}, "forge": {"ferro": 7, "madeira": 6},
	"market": {"alimentos": 5}, "depot": {"madeira": 14, "pedra": 8, "ferro": 8, "ferramentas": 2},
	"site": {}, "player": {}, "ivo": {}, "mara": {}, "nilo": {}, "teresa": {}
}
var stocks: Dictionary = INITIAL.duplicate(true)

func amount(place: String, item: String) -> int:
	var inventory: Dictionary = stocks.get(place, {})
	return inventory.get(item, 0)

func add(place: String, item: String, quantity: int) -> bool:
	if quantity <= 0 or item not in GOODS or amount(place, item) + quantity > CAPACITY:
		return false
	if not stocks.has(place):
		stocks[place] = {}
	stocks[place][item] = amount(place, item) + quantity
	return true

func spend(place: String, costs: Dictionary) -> bool:
	if costs.is_empty():
		return false
	for item in costs:
		if item not in GOODS or int(costs[item]) <= 0 or amount(place, item) < int(costs[item]):
			return false
	for item in costs:
		stocks[place][item] -= int(costs[item])
	return true

func transfer(origin: String, destination: String, item: String, quantity: int) -> bool:
	if origin == destination or amount(destination, item) + quantity > CAPACITY:
		return false
	if not spend(origin, {item: quantity}):
		return false
	return add(destination, item, quantity)

func craft(place: String, costs: Dictionary, product: String, quantity: int) -> bool:
	if product not in GOODS or quantity <= 0 or amount(place, product) + quantity > CAPACITY:
		return false
	return spend(place, costs) and add(place, product, quantity)

func first(place: String) -> String:
	for item in GOODS:
		if amount(place, item) > 0:
			return item
	return ""

func summary(place: String) -> String:
	var lines := PackedStringArray()
	for item in GOODS:
		var quantity := amount(place, item)
		if quantity > 0:
			lines.append("%s  %d" % [item.capitalize(), quantity])
	return "Estoque vazio" if lines.is_empty() else "   ·   ".join(lines)

func restore(data: Dictionary) -> void:
	stocks = INITIAL.duplicate(true)
	for place in INITIAL:
		if not data.get(place) is Dictionary:
			continue
		stocks[place] = {}
		for item in GOODS:
			var value: Variant = data[place].get(item, 0)
			if (value is int or value is float) and is_finite(float(value)):
				stocks[place][item] = int(clampf(float(value), 0, CAPACITY))
