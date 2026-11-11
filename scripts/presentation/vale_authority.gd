class_name ValeAuthority
extends Node3D

const HOLD := Vector3(18.25, 0.10, -4.20)
const WATCH := [Vector3(22.35, 0.1, -8.1), Vector3(22.6, 0.1, -12.9), Vector3(19.1, 0.1, -10.3), HOLD]
const WITNESS := [Vector3(23.8, 0.1, -13.25), Vector3(22.9, 0.1, -9.25)]
var justice := RegionalJustice.new()
var underworld := Underworld.new()
var works := CivicWorks.new()
var game: Node3D
var career: ValeLife
var guard: PixelActor
var town_guard: PixelActor
var town_index := 0
const TOWN_WATCH := [Vector3(2.8, 0.1, -8.6), Vector3(-0.7, 0.1, -5.8), Vector3(3.2, 0.1, -2.6)]
var worker: PixelActor
var witness: PixelActor
var runner: PixelActor
var work_mesh := Node3D.new()
var road: StaticBody3D
var collision_key := ""
var routes: Dictionary = {}
var guard_index := 0
var witness_index := 0
var escort_calls := 0
var escort_bonus := 0
var control_timer := 0.0

func setup(scene: Node3D, owner: ValeLife) -> void:
	game = scene
	career = owner
	guard = _actor("Guarda Nuno", "63787c", 3, WATCH[0])
	town_guard = _actor("Guarda Dália", "5c766c", 3, TOWN_WATCH[0])
	worker = _actor("Mestra Iara", "936f4e", 2, CivicWorks.WORKER_HOME)
	witness = _actor("Vigia do mercado", "778366", 1, WITNESS[0])
	runner = _actor("Téo da Estrada", "5e6451", 4, Underworld.HIDEOUT)
	runner.hide()
	_actor(Underworld.NPC, "635a6d", 4, Underworld.HIDEOUT + Vector3(0, 0, -0.76))
	_actor("Escrivã da Coroa", "6e7961", 1, CivicWorks.HALL + Vector3(0.47, 0, -0.62))
	_stall(Underworld.HIDEOUT, "O JUNCO", "mossroof")
	_stall(CivicWorks.HALL, "PREFEITURA", "roof")
	_stall(HOLD, "GUARDA", "mossroof")
	add_child(work_mesh)
	road = _body(CivicWorks.CROSSING, Vector3(0.36, 1.25, 2.55))
	works.changed.connect(_refresh_works)
	_refresh_works()
	game.interactions.register("Mira · mercado clandestino", Underworld.HIDEOUT, func() -> void: career.ui.open("underworld"), 1.9)
	game.interactions.register("Prefeitura · propostas ao rei", CivicWorks.HALL, func() -> void: career.ui.open("works"), 1.9)
	game.interactions.register("Guarda · consultar multas", HOLD, func() -> void: career.ui.open("justice"), 1.9)

func detained() -> bool:
	return game.simulation.clock.elapsed < justice.jail_until

func advance(delta: float) -> void:
	var clock: WorldClock = game.simulation.clock
	var world: WorldSimulation = game.simulation
	var life := career.life
	var now := clock.elapsed
	justice.advance(now)
	if detained() and game.player.position.distance_to(HOLD) > 2.3:
		game.player.position = HOLD + Vector3.BACK * 0.78
	if game.navigation.revision <= 0:
		return
	control_timer += delta
	if control_timer >= 0.75:
		control_timer = 0.0
		var sample := career.frontier.climate.sample(clock.total_day(), clock.hour())
		if works.flood(clock.total_day(), sample.humidity, sample.weather, world.construction.complete()):
			world.economy.journal.record(clock, "flood", "Chuva intensa fechou o acesso norte. Fretes usam a ponte de pedra.")
		var needs_guard := justice.reputation >= 2 and "guard" not in works.completed
		if works.approved.is_empty() and clock.hour() >= 6.0 and clock.hour() < 19.0:
			if works.road_closed and clock.total_day() > works.flood_day:
				if life.treasury >= CivicWorks.OPTIONS.road.price and world.economy.stock.amount("depot", "madeira") >= 2 and world.economy.stock.amount("depot", "pedra") >= 2:
					works.propose("road", life, world, "Rei Aldren")
			elif needs_guard and life.treasury >= CivicWorks.OPTIONS.guard.price and world.economy.stock.amount("depot", "madeira") >= 2 and world.economy.stock.amount("depot", "pedra") >= 2:
				works.propose("guard", life, world, "Rei Aldren")
	_tick_guard(now, delta)
	if _walk(town_guard, TOWN_WATCH[town_index], 1.52, delta):
		town_index = (town_index + 1) % TOWN_WATCH.size()
	if _walk(witness, WITNESS[witness_index], 1.43, delta):
		witness_index = (witness_index + 1) % WITNESS.size()
	var working := clock.hour() >= 6.0 and clock.hour() < 19.0
	var destination := works.destination() if working else CivicWorks.WORKER_HOME
	var hammer := working and not works.approved.is_empty() and int(works.approved.step) >= 4 and worker.position.distance_to(destination) < 0.55
	var arrived := _walk(worker, destination, 1.82, delta, hammer)
	works.worker_position = worker.position
	if working:
		works.work(clock, delta, arrived, world.economy.journal)
	var cargo: String = works.approved.get("cargo", "")
	worker.set_cargo("wood" if cargo == "madeira" else "stone" if cargo == "pedra" else "")
	_tick_runner(now, delta)

func _tick_guard(now: float, delta: float) -> void:
	var life := career.life
	var player: PixelActor = game.player
	var wanted := justice.wanted(life.profile.get("uid", ""), now)
	var investigate: Variant = justice.alert_position(now)
	var goal: Vector3 = WATCH[guard_index]
	if wanted:
		var last: Array = justice.case_file.at
		goal = Vector3(last[0], 0.1, last[1])
		if _sees(guard, player.position, 10.0 if "guard" in works.completed else 8.2):
			goal = player.position
			if guard.position.distance_to(player.position) < 1.15 and justice.settle(life, now, true):
				if detained():
					player.position = HOLD + Vector3.BACK * 0.78
				game.hud.show_message("A guarda aplicou a decisão. Consulte o registro no posto.")
				return
	elif investigate is Vector3:
		goal = investigate
	if _walk(guard, goal, 2.58 if wanted else 1.62, delta) and not wanted and not investigate is Vector3:
		guard_index = (guard_index + 1) % WATCH.size()

func _tick_runner(now: float, delta: float) -> void:
	var loot := career.frontier.loot
	var active: bool = not loot.is_empty() and now >= float(loot.expires) - 106.0 and now < float(loot.expires)
	active = active and not underworld._has_origin(String(loot.get("origin", "")))
	if not active:
		runner.hide()
		return
	if not runner.visible:
		runner.position = Underworld.HIDEOUT
		runner.show()
	if _walk(runner, loot.position, 2.12, delta) and underworld.salvage(career.frontier):
		game.simulation.economy.journal.record(game.simulation.clock, "black_market", "A Irmandade recolheu parte da carga perdida.")
		runner.hide()

func _sees(actor: PixelActor, at: Vector3, range_value: float) -> bool:
	if actor.position.distance_to(at) > range_value:
		return false
	var query := PhysicsRayQueryParameters3D.create(actor.position + Vector3.UP * 0.8, at + Vector3.UP * 0.8, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func witnessed_trade() -> void:
	var at: Vector3 = game.player.position
	var observer := ""
	if _sees(guard, at, 8.2):
		observer = "Guarda Nuno"
	elif _sees(witness, at, 3.4):
		observer = "Vigia do mercado"
	var now: float = game.simulation.clock.elapsed
	if justice.report("trade", career.life.profile.get("uid", ""), "brumaria", observer, at, now):
		game.simulation.economy.journal.record(game.simulation.clock, "law", observer + " comunicou comércio clandestino.")

func raid_alert(at: Vector3) -> void:
	if justice.ambush(at, "Condutor da carroça", game.simulation.clock.elapsed):
		escort_calls += 1
		escort_bonus = 4

func reward_escort() -> void:
	if escort_bonus <= 0 or career.life.treasury < escort_bonus:
		return
	career.life.treasury -= escort_bonus
	career.life.gold += escort_bonus
	career.life.logbook("Prêmio da Coroa pela escolta · +%d ouro" % escort_bonus)
	escort_bonus = 0

func award_bounty() -> void:
	if career.life.treasury < 4:
		return
	career.life.treasury -= 4
	career.life.gold += 4
	game.simulation.economy.journal.record(game.simulation.clock, "bounty", "A Coroa pagou 4 ouro pela defesa da carroça.")

func perform(action: String, id: String) -> String:
	var life := career.life
	var at: Vector3 = game.player.position
	var now: float = game.simulation.clock.elapsed
	var success := false
	if action.begins_with("secret_"):
		if at.distance_to(Underworld.HIDEOUT) > 2.55:
			return "Aproxime-se de Mira."
		match action:
			"secret_join": success = underworld.join(life)
			"secret_buy": success = underworld.buy(life, id)
			"secret_sell": success = underworld.sell(life, id)
			"secret_contract": success = underworld.accept(life)
			"secret_deliver": success = underworld.deliver(life, id)
		if success and action in ["secret_buy", "secret_sell", "secret_deliver"]:
			witnessed_trade()
	elif action == "royal":
		if at.distance_to(CivicWorks.HALL) > 2.55:
			return "Apresente a proposta na prefeitura."
		return works.propose(id, life, game.simulation, life.profile.name)
	elif action == "fine" and at.distance_to(HOLD) <= 2.55:
		success = justice.settle(life, now, false)
	return "Concluído." if success else "Ação indisponível."

func snapshot() -> Dictionary:
	return {"justice": justice.snapshot(), "underworld": underworld.snapshot(), "works": works.snapshot(),
		"town": [town_guard.position.x, town_guard.position.z], "town_index": town_index, "calls": escort_calls, "bonus": escort_bonus, "guard": [guard.position.x, guard.position.z]}

func restore(data: Variant) -> void:
	if not data is Dictionary:
		data = {}
	justice.restore(data.get("justice"))
	underworld.restore(data.get("underworld"), career.life.profile.get("uid", ""))
	works.restore(data.get("works"))
	worker.position = works.worker_position
	guard.position = WATCH[0]
	if data.get("guard") is Array and data.guard.size() == 2:
		guard.position = Vector3(LifeCatalog.number(data.guard[0], WATCH[0].x, -30, 32), 0.10,
			LifeCatalog.number(data.guard[1], WATCH[0].z, -32, 32))
	routes.clear()
	town_index = int(LifeCatalog.number(data.get("town_index"), 0, 0, TOWN_WATCH.size() - 1))
	town_guard.position = TOWN_WATCH[town_index]
	if data.get("town") is Array and data.town.size() == 2:
		town_guard.position = Vector3(LifeCatalog.number(data.town[0], town_guard.position.x, -30, 32), 0.1,
			LifeCatalog.number(data.town[1], town_guard.position.z, -32, 32))
	escort_calls = int(LifeCatalog.number(data.get("calls"), 0, 0, 10000))
	escort_bonus = int(LifeCatalog.number(data.get("bonus"), 0, 0, 4))

func _walk(actor: PixelActor, target: Vector3, speed: float, delta: float, hammer := false) -> bool:
	var id := actor.get_instance_id()
	var cache: Dictionary = routes.get(id, {})
	var now: float = game.simulation.clock.elapsed
	if cache.is_empty() or cache.revision != game.navigation.revision or (now >= cache.retry and (cache.path.is_empty() or target.distance_to(cache.goal) >= 0.55)):
		cache = {"goal": target, "path": game.navigation.find(actor.position, target), "cursor": 0,
			"revision": game.navigation.revision, "retry": now + 0.42}
		routes[id] = cache
	var path: PackedVector3Array = cache.path
	var movement := Vector3.ZERO
	if not path.is_empty():
		while cache.cursor < path.size() and actor.position.distance_to(path[cache.cursor]) < 0.12:
			cache.cursor += 1
		if cache.cursor < path.size():
			var before := actor.position
			var offset := path[int(cache.cursor)] - before
			var hit := actor.move_and_collide(offset.limit_length(speed * delta))
			movement = (actor.position - before) / delta
			if hit != null and movement.length_squared() < 0.02:
				cache.path = PackedVector3Array()
	actor.pose(movement, game.camera.global_basis.x, game.sprite_light, hammer)
	return not path.is_empty() and cache.cursor >= path.size() and actor.position.distance_to(target) < 0.52

func _refresh_works() -> void:
	for child in work_mesh.get_children():
		work_mesh.remove_child(child)
		child.queue_free()
	road.collision_layer = 1 if works.road_closed else 0
	career.frontier.warehouse = "warehouse" in works.completed
	career.frontier.road_closed = works.road_closed
	if works.road_closed:
		_box(work_mesh, CivicWorks.CROSSING, Vector3(0.38, 0.70, 2.56), "board")
	if "road" in works.completed and not works.road_closed:
		_box(work_mesh, Vector3(16.93, 0.02, -12.0), Vector3(2.25, 0.055, 2.48), "stone")
	for id in ["warehouse", "guard"]:
		if id in works.completed:
			var at: Vector3 = CivicWorks.OPTIONS[id].at
			_box(work_mesh, at + Vector3.UP * 0.67, Vector3(1.6, 1.3, 0.78), "stone" if id == "guard" else "board")
			_box(work_mesh, at + Vector3.UP * 1.39, Vector3(1.9, 0.18, 1.04), "mossroof")
			_body(at + Vector3.UP * 0.67, Vector3(1.58, 1.3, 0.76), work_mesh)
	if not works.approved.is_empty():
		var at: Vector3 = CivicWorks.OPTIONS[works.approved.id].at
		var done: int = works.approved.done
		for i in done + 1:
			_box(work_mesh, at + Vector3(0.67, 0.13 + i * 0.13, 0.62), Vector3(0.60, 0.18, 0.53), "board" if i % 2 else "stone")
		if done >= 1:
			_box(work_mesh, at + Vector3(0, 0.12, -0.65), Vector3(1.6, 0.23, 0.67), "stone")
		if done >= 2:
			for x in [-0.62, 0.62]:
				_box(work_mesh, at + Vector3(x, 0.77, -0.65), Vector3(0.11, 1.37, 0.12), "wood")
		if done >= 3:
			_box(work_mesh, at + Vector3(0, 1.46, -0.65), Vector3(1.73, 0.12, 0.82), "roof")
	var key := str(works.road_closed) + str(works.completed)
	if key != collision_key:
		collision_key = key
		game.nav_dirty = true
		game.hud.update_bridge(game.simulation.construction, works.road_closed)

func _actor(label: String, color: String, hat: int, at: Vector3) -> PixelActor:
	var actor := PixelActor.new()
	actor.configure(Color(color), Color("68533d"), hat, false, "guard")
	actor.position = at
	add_child(actor)
	_label(actor, Vector3.UP * 1.64, label)
	return actor

func _stall(at: Vector3, label: String, roof: String) -> void:
	var center := at - Vector3.BACK * 0.74
	_box(self, center + Vector3.UP * 0.51, Vector3(1.51, 0.97, 0.58), "wood")
	_box(self, center + Vector3.UP * 1.07, Vector3(1.62, 0.13, 0.70), "oak")
	for x in [-0.71, 0.71]:
		_box(self, center + Vector3(x, 1.47, 0), Vector3(0.10, 1.56, 0.11), "wood")
	_box(self, center + Vector3.UP * 2.13, Vector3(1.85, 0.18, 0.94), roof)
	_label(self, center + Vector3(0, 1.58, 0.49), label)

func _label(parent: Node3D, at: Vector3, value: String) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = at
	label.font_size = 26
	label.pixel_size = 0.0048
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("e8c997")
	label.visibility_range_end = 27.0
	parent.add_child(label)

func _box(parent: Node3D, at: Vector3, size: Vector3, material: String) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = game.diorama.palette.materials[material]
	mesh.position = at
	parent.add_child(mesh)

func _body(at: Vector3, size: Vector3, parent: Node3D = null) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var box := BoxShape3D.new()
	box.size = size
	var hit := CollisionShape3D.new()
	hit.shape = box
	body.add_child(hit)
	var container := self if parent == null else parent
	container.add_child(body)
	return body
