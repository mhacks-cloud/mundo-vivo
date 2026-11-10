class_name TrainingSession
extends RefCounted

const SPOTS := [Vector3(20.30, 0.1, 6.15), Vector3(22.18, 0.1, 6.08), Vector3(23.88, 0.1, 5.45)]
const CENTER := Vector3(21.0, 0.10, 4.20)
const TARGET_NAMES := ["Alvo de guarda", "Alvo de precisão", "Aliada ferida"]
var health := [42.0, 48.0, 25.0]
var cooldowns := [0.0, 0.0, 0.0]
var registered := [false, false, false]
var hazard := 1.0

func available(index: int) -> bool:
	return index >= 0 and index < health.size() and not registered[index]

func begin(life: PlayerLife, index: int) -> Dictionary:
	if not available(index) or life.cooldown > 0.0 or life.hp <= 0:
		return {}
	var skill := {}
	match life.role():
		"warrior":
			if index == 0 and life.equipped("weapon") == "sword":
				skill = {"amount": 22.0, "range": 2.2, "projectile": false, "name": "Golpe de espada"}
		"archer":
			if index == 1 and life.equipped("weapon") == "bow" and life.bag.spend({"arrow": 1}):
				skill = {"amount": 18.0, "range": 11.0, "projectile": true, "name": "Flecha"}
		"mage":
			if index < 2 and life.equipped("weapon") == "staff" and life.mana >= 18:
				life.mana -= 18.0
				skill = {"amount": 27.0, "range": 9.0, "projectile": true, "name": "Centelha"}
		"healer":
			if index == 2 and life.equipped("accessory") == "charm" and life.mana >= 18:
				life.mana -= 18.0
				skill = {"amount": -31.0, "range": 6.0, "projectile": false, "name": "Restaurar"}
	if not skill.is_empty():
		life.cooldown = 0.62
		life.wear("accessory" if index == 2 else "weapon")
		life.changed.emit()
	return skill

func apply(life: PlayerLife, index: int, amount: float) -> bool:
	if not available(index) or (index == 2 and amount >= 0) or (index < 2 and amount <= 0):
		return false
	health[index] = clampf(health[index] - amount, 0, 100 if index == 2 else 48)
	if (index == 2 and health[index] >= 85) or (index < 2 and health[index] == 0.0):
		registered[index] = true
		cooldowns[index] = 22.0
		life.award(24)
		life.logbook("Treino concluído · " + TARGET_NAMES[index])
	return true

func tick(life: PlayerLife, p: Vector3, guarding: bool, delta: float) -> void:
	if life.profile.is_empty():
		return
	life.cooldown = maxf(0, life.cooldown - delta)
	for i in cooldowns.size():
		if registered[i]:
			cooldowns[i] = maxf(0, cooldowns[i] - delta)
			if cooldowns[i] == 0.0:
				registered[i] = false
				health[i] = [42.0, 48.0, 25.0][i]
	if p.distance_squared_to(SPOTS[0]) < 2.4 * 2.4 and available(0):
		hazard -= delta
		if hazard <= 0:
			hazard = 2.8
			var damage := 11.0
			if not life.equipped("armor").is_empty():
				damage *= 0.72
				life.wear("armor")
			if guarding and life.role() == "warrior" and not life.equipped("weapon").is_empty():
				damage *= 0.24
				life.wear("weapon")
			life.hp = maxf(0.0, life.hp - damage)
	elif p.distance_squared_to(CENTER) > 10.0 * 10.0:
		life.hp = minf(life.max_hp(), life.hp + delta * 3.2)
		life.mana = minf(life.max_mana(), life.mana + delta * 2.4)

func snapshot() -> Dictionary:
	return {"health": health.duplicate(), "wait": cooldowns.duplicate(), "registered": registered.duplicate(), "hazard": hazard}

func restore(data: Variant) -> void:
	health = [42.0, 48.0, 25.0]
	cooldowns = [0.0, 0.0, 0.0]
	registered = [false, false, false]
	hazard = 1.0
	if not data is Dictionary:
		return
	for i in 3:
		if data.get("health") is Array and data.health.size() == 3:
			health[i] = LifeCatalog.number(data.health[i], health[i], 0, 100)
		if data.get("wait") is Array and data.wait.size() == 3:
			cooldowns[i] = LifeCatalog.number(data.wait[i], 0, 0, 22)
		if data.get("registered") is Array and data.registered.size() == 3:
			registered[i] = data.registered[i] == true and cooldowns[i] > 0
	hazard = LifeCatalog.number(data.get("hazard"), 1, 0, 3)
