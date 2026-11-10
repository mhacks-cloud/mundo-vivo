class_name LifeInventory
extends RefCounted

var items: Dictionary = {}
var condition: Dictionary = {}
var capacity := 85.0

func amount(id: String) -> int:
	return items.get(id, 0)

func weight() -> float:
	var total := 0.0
	for id in items:
		total += float(LifeCatalog.GOODS[id][2]) * amount(id)
	return total

func can_add(id: String, quantity: int) -> bool:
	if not LifeCatalog.GOODS.has(id) or quantity <= 0:
		return false
	var cap := 1 if not LifeCatalog.slot(id).is_empty() else 999
	return amount(id) + quantity <= cap and weight() + float(LifeCatalog.GOODS[id][2]) * quantity <= capacity + 0.0001

func add(id: String, quantity: int, durability := -1) -> bool:
	if not can_add(id, quantity):
		return false
	items[id] = amount(id) + quantity
	if not LifeCatalog.slot(id).is_empty():
		var maximum := LifeCatalog.max_durability(id)
		condition[id] = maximum if durability < 0 else clampi(durability, 0, maximum)
	return true

func has(cost: Dictionary) -> bool:
	if cost.is_empty():
		return false
	for id in cost:
		if not LifeCatalog.GOODS.has(id) or not cost[id] is int or cost[id] <= 0 or amount(id) < cost[id]:
			return false
	return true

func spend(cost: Dictionary) -> bool:
	if not has(cost):
		return false
	for id in cost:
		var remaining: int = amount(id) - cost[id]
		if remaining == 0:
			items.erase(id)
			condition.erase(id)
		else:
			items[id] = remaining
	return true

func transform(cost: Dictionary, id: String, quantity: int) -> bool:
	if not has(cost) or not LifeCatalog.GOODS.has(id) or quantity <= 0:
		return false
	var cap := 1 if not LifeCatalog.slot(id).is_empty() else 999
	if amount(id) - int(cost.get(id, 0)) + quantity > cap:
		return false
	var delta := float(LifeCatalog.GOODS[id][2]) * quantity
	for material in cost:
		delta -= float(LifeCatalog.GOODS[material][2]) * int(cost[material])
	if weight() + delta > capacity + 0.0001:
		return false
	spend(cost)
	return add(id, quantity)

func transfer(destination: LifeInventory, id: String, quantity: int) -> bool:
	if destination == self or quantity <= 0 or amount(id) < quantity or not destination.can_add(id, quantity):
		return false
	var durability: int = condition.get(id, -1)
	spend({id: quantity})
	return destination.add(id, quantity, durability)

func snapshot() -> Dictionary:
	return {"items": items.duplicate(), "condition": condition.duplicate()}

func restore(state: Variant) -> void:
	items.clear()
	condition.clear()
	if not state is Dictionary or not state.get("items") is Dictionary:
		return
	var quality: Variant = state.get("condition")
	for id in LifeCatalog.GOODS:
		var maximum := LifeCatalog.max_durability(id)
		var quantity := int(LifeCatalog.number(state.items.get(id), 0, 0, 1 if maximum > 0 else 999))
		var durability := -1
		if quality is Dictionary and maximum > 0:
			durability = int(LifeCatalog.number(quality.get(id), maximum, 0, maximum))
		if quantity > 0:
			var fit := floori((capacity - weight() + 0.0001) / float(LifeCatalog.GOODS[id][2]))
			add(id, mini(quantity, fit), durability)
