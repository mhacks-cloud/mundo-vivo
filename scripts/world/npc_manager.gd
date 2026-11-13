class_name NPCManager
extends RefCounted

const STATES := {"IDLE": "Em pausa", "WALKING": "A caminho", "WORKING": "Trabalhando",
	"TRANSPORTING": "Transportando", "EATING": "Almoçando", "RESTING": "Descansando",
	"SLEEPING": "Dormindo", "INTERACTING": "Conversando", "SEEKING_SHELTER": "Buscando abrigo"}
const LUNCH := Vector3(-4.72, 0.10, -2.80)
var plans: Array[Dictionary] = []
var world: WorldSimulation
var society: TownSociety
var last_social := -30.0
var last_watch := -1

func _init(simulation: WorldSimulation) -> void:
	world = simulation
	plans = [
		_resident("Ivo", "carpinteiro", "builder", "8b653e", "604332", 1, 6.0, 19.5,
			Vector2(6.60, -9.65), Vector2(6.42, -9.9), [Vector2(6.18, -12.05), Vector2(9.03, -12.02), Vector2(7.45, -11.55)]),
		_resident("Mara", "carpinteira", "builder", "97604e", "493a37", 2, 6.0, 19.5,
			Vector2(5.35, -10.15), Vector2(5.41, -9.9), [Vector2(6.18, -11.55), Vector2(9.03, -12.45), Vector2(7.10, -12.62)]),
		_resident("Lina", "comerciante", "market", "875c8b", "7b503a", 0, 7.0, 19.0,
			Vector2(-6.72, -3.76), Vector2(-6.72, -3.98), [Vector2(-6.22, -1.29), Vector2(-5.13, -2.56)]),
		_resident("Baltasar", "ferreiro", "forge", "537783", "53433b", 1, 7.0, 18.0,
			Vector2(-8.74, 5.12), Vector2(-11.58, 4.49), [Vector2(-11.21, 5.04), Vector2(-11.30, 4.60)]),
		_resident("Teresa", "agricultora", "farm", "637e4b", "a1744e", 2, 6.0, 18.0,
			Vector2(-7.04, 13.87), Vector2(-7.04, 13.87), [Vector2(-11.67, 10.74), Vector2(-10.07, 8.83)]),
		_resident("Nilo", "transportador", "carrier", "467c79", "8e6947", 0, 6.5, 19.0,
			Vector2(24.8, -0.80), Vector2(24.7, -0.80), [Vector2(-10.17, 8.94), Vector2(-6.10, -1.61),
				Vector2(6.30, -12.80), Vector2(-11.02, 5.05), Vector2(6.30, -12.80), Vector2(18.20, -12.0)]),
		_resident("Afonso", "guarda do dia", "guard", "8e5e57", "493e30", 3, 6.0, 17.0,
			Vector2(2.68, -4.94), Vector2(2.68, -4.94), [Vector2(2.65, 2.1), Vector2(9.0, 2.0), Vector2(18.1, 2.0), Vector2(4.9, -9.0)]),
		_resident("Beatriz", "moradora", "resident", "787c56", "bbb1a1", 4, 8.0, 19.0,
			Vector2(6.20, 12.32), Vector2(6.20, 12.32), [Vector2(3.00, 3.72), Vector2(-5.92, -1.28),
				Vector2(-3.4, -0.40), Vector2(4.4, 5.8)]),
		_resident("Branca", "guarda da noite", "guard", "706189", "56443d", 3, 17.0, 6.0,
			Vector2(7.0, -3.47), Vector2(7.0, -3.47), [Vector2(7.9, -8.6), Vector2(9.0, -11.5), Vector2(17.75, -11.4), Vector2(3.5, 0.3)])
	]
	reset()

func _resident(label: String, job: String, role: String, palette: String, hair: String, hat: int,
		begin: float, end: float, home: Vector2, shelter: Vector2, route: Array) -> Dictionary:
	var points: Array[Vector3] = []
	for p in route:
		points.append(Vector3(p.x, 0.10, p.y))
	return {"name": label, "id": label.to_lower(), "job": job, "role": role, "worker": role == "builder",
		"palette": palette, "hair": hair, "hat": hat, "start": begin, "end": end,
		"home": Vector3(home.x, 0.10, home.y), "shelter": Vector3(shelter.x, 0.10, shelter.y),
		"route": points, "workplace": points[0]}

func reset() -> void:
	last_social = -30.0
	last_watch = -1
	for plan in plans:
		plan.index = 0
		plan.wait = 0.0
		plan.talk = 0.0
		plan.carry = false
		plan.building = false
		plan.pending = false
		plan.state = "IDLE"
		plan.intent = ""
		plan.detail = "Preparando a jornada"
		plan.meal_day = -1
		plan.hunger = 0.20
		plan.fatigue = 0.15
		plan.position = plan.home
		plan.destination = plan.home

func working(plan: Dictionary, hour: float) -> bool:
	if plan.worker and world.construction.complete():
		return false
	if plan.start > plan.end:
		return hour >= plan.start or hour < plan.end
	return hour >= plan.start and hour < plan.end

func goal(plan: Dictionary, wet: bool, delta: float) -> Vector3:
	var hour := world.clock.hour()
	var day := world.clock.total_day()
	var on_duty := working(plan, hour)
	plan.wait = maxf(0.0, plan.wait - delta)
	plan.talk = maxf(0.0, plan.talk - delta)
	plan.hunger = clampf(plan.hunger + delta / 1100.0, 0, 1)
	plan.fatigue = clampf(plan.fatigue + (delta / 1600.0 if on_duty else -delta / 70.0), 0, 1)
	var intent := "job"
	var goal_position: Vector3 = plan.route[plan.index]
	if not on_duty:
		intent = "home"
		goal_position = plan.home
	elif wet and plan.role != "guard":
		intent = "shelter"
		goal_position = plan.shelter
	elif ((hour >= 12.0 and hour < 14.0) or (hour >= 10.5 and hour < 12.0 and plan.hunger > 0.74)) and plan.meal_day != day and not plan.worker and plan.role != "guard":
		intent = "meal"
		goal_position = LUNCH
	elif plan.role == "guard" and wet:
		intent = "watch"
		goal_position = Vector3(8.95, 0.10, 2.03)
	if intent != plan.intent:
		plan.pending = false
		plan.building = false
		plan.wait = 0.0
		plan.intent = intent
	plan.destination = goal_position
	plan.carry = not world.economy.stock.first(plan.id).is_empty()
	return goal_position

func moving(plan: Dictionary) -> void:
	plan.state = "SEEKING_SHELTER" if plan.intent == "shelter" else "TRANSPORTING" if plan.carry else "WALKING"

func arrived(plan: Dictionary) -> void:
	var hour := world.clock.hour()
	if plan.talk > 0:
		plan.state = "INTERACTING"
		return
	match plan.intent:
		"home":
			plan.state = "SLEEPING" if hour >= 21.0 or hour < 5.5 else "RESTING"
			plan.detail = "Em casa"
			if plan.worker and plan.carry:
				world.return_build(plan.id)
		"shelter":
			plan.state = "RESTING"
			plan.detail = "Espera a chuva passar"
		"meal":
			plan.state = "EATING"
			if not plan.pending:
				plan.pending = true
				plan.wait = 4.0
				plan.detail = "Pausa para comer"
				return
			if plan.wait == 0.0:
				if _buy_food(plan):
					plan.hunger = 0.08
				plan.fatigue = maxf(0.0, plan.fatigue - 0.32)
				plan.meal_day = world.clock.total_day()
				plan.pending = false
		"watch":
			plan.state = "WORKING"
			plan.detail = "Vigia a correnteza durante a chuva"
			if last_watch != world.clock.total_day():
				last_watch = world.clock.total_day()
				world.economy.journal.record(world.clock, "watch", "%s reforçou a vigia do rio durante a chuva." % plan.name)
		"job":
			_work_at_stop(plan)

func _buy_food(plan: Dictionary) -> bool:
	if society != null and not society.afford_food(plan.id):
		return false
	if not world.economy.buy(world.clock, plan.name):
		return false
	if society != null:
		society.buy_food(plan.id, world.clock.total_day())
	return true

func _work_at_stop(plan: Dictionary) -> void:
	if not plan.pending:
		plan.pending = true
		plan.state = "WORKING" if plan.role in ["forge", "farm", "market", "builder"] else "IDLE"
		plan.wait = 1.15 if plan.worker else 2.0
		plan.detail = "Em serviço"
		if plan.worker and plan.index == 2:
			plan.state = "RESTING"
			plan.detail = "Descansa no canteiro"
			plan.fatigue = maxf(0.0, plan.fatigue - 0.19)
		elif plan.worker and plan.index == 1:
			world.unload_build(plan.id)
			plan.building = true
			plan.wait = 2.8
			plan.detail = world.construction.phase_name()
		elif plan.role == "forge" and plan.index == 0:
			plan.building = true
		return
	if plan.wait > 0:
		return
	var economy := world.economy
	var index: int = plan.index
	if society != null and (not plan.worker or index != 2):
		society.work(plan.id, world.clock.total_day())
	match plan.role:
		"builder":
			if index == 0:
				plan.detail = "Busca " + world.construction.required_item()
				world.reserve_build(plan.id)
			elif index == 1:
				world.work_bridge()
			else:
				plan.detail = "Pausa no canteiro"
		"farm":
			if index == 0:
				plan.detail = economy.farm(world.clock, false)
			else:
				economy.store_harvest(world.clock)
				plan.detail = "Organiza o depósito"
		"forge":
			plan.detail = economy.forge(world.clock) if index == 0 else "Organiza o carvão e as ferramentas"
		"market":
			plan.detail = economy.market(world.clock)
		"carrier":
			match index:
				0: economy.pick_wheat(world.clock)
				1:
					if economy.deliver_wheat(world.clock) and society != null:
						society.procurement("trade", "farm", 2)
				2: economy.pick_forge_supply(world.clock)
				3: economy.deliver_forge_supply(world.clock)
				4: economy.deliver_tools(world.clock)
			plan.detail = "Cumpre as encomendas do vale"
		"resident":
			if index == 1:
				_buy_food(plan)
			plan.detail = "Visita a praça e os comércios"
		"guard":
			plan.detail = "Patrulha as travessias"
	plan.pending = false
	plan.building = false
	plan.index = (index + 1) % plan.route.size()

func social() -> void:
	if world.clock.elapsed < last_social + 25.0:
		return
	for i in range(2, plans.size()):
		var a := plans[i]
		if a.state not in ["IDLE", "WALKING"] or a.intent != "job":
			continue
		for j in range(i + 1, plans.size()):
			var b := plans[j]
			if b.state not in ["IDLE", "WALKING", "WORKING"] or b.intent != "job":
				continue
			if a.position.distance_squared_to(b.position) > 3.24:
				continue
			last_social = world.clock.elapsed
			a.talk = 2.2
			b.talk = 2.2
			a.detail = "Cumprimenta " + b.name
			b.detail = "Conversa com " + a.name
			var topic := "a ponte inaugurada" if world.construction.complete() else "o andamento da ponte"
			world.economy.journal.record(world.clock, "greeting", "%s e %s conversaram sobre %s." % [a.name, b.name, topic])
			return

func snapshot() -> Dictionary:
	var result := {}
	for plan in plans:
		var pos: Vector3 = plan.position
		var destination: Vector3 = plan.destination
		result[plan.id] = {"position": [pos.x, pos.z], "destination": [destination.x, destination.z],
			"index": plan.index, "state": plan.state, "wait": plan.wait, "intent": plan.intent,
			"pending": plan.pending, "building": plan.building, "meal_day": plan.meal_day,
			"hunger": plan.hunger, "fatigue": plan.fatigue, "detail": plan.detail, "talk": plan.talk}
	return {"people": result, "social": last_social, "watch": last_watch}

func restore(saved: Dictionary) -> void:
	reset()
	last_social = _number(saved.get("social"), -30.0, -30.0, world.clock.elapsed)
	last_watch = int(_number(saved.get("watch"), -1.0, -1.0, world.clock.total_day()))
	var data: Variant = saved.get("people")
	if not data is Dictionary:
		return
	for plan in plans:
		var entry: Variant = data.get(plan.id)
		if not entry is Dictionary:
			continue
		plan.position = _point(entry.get("position"), plan.home)
		plan.destination = _point(entry.get("destination"), plan.home)
		plan.index = int(_number(entry.get("index"), 0, 0, plan.route.size() - 1))
		var state: Variant = entry.get("state")
		plan.state = state if state is String and STATES.has(state) else "IDLE"
		var intent: Variant = entry.get("intent")
		plan.intent = intent if intent is String and intent in ["job", "home", "shelter", "meal", "watch"] else ""
		plan.wait = _number(entry.get("wait"), 0, 0, 10)
		plan.talk = _number(entry.get("talk"), 0, 0, 3)
		if entry.get("detail") is String:
			plan.detail = entry.detail.left(150)
		plan.pending = entry.get("pending") == true
		plan.building = entry.get("building") == true and plan.pending and plan.intent == "job"
		plan.meal_day = int(_number(entry.get("meal_day"), -1, -1, world.clock.total_day()))
		plan.hunger = _number(entry.get("hunger"), 0.2, 0, 1)
		plan.fatigue = _number(entry.get("fatigue"), 0.15, 0, 1)

func _point(value: Variant, fallback: Vector3) -> Vector3:
	if not value is Array or value.size() != 2:
		return fallback
	return Vector3(_number(value[0], fallback.x, -31.0, 33.0), 0.10,
		_number(value[1], fallback.z, -33.0, 32.0))

func _number(value: Variant, fallback: float, low: float, high: float) -> float:
	if (value is float or value is int) and is_finite(float(value)):
		return clampf(float(value), low, high)
	return fallback
