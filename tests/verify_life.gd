extends SceneTree

var passed := 0
var failed := 0
var path := "user://verify_life_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_inventory_and_migration()
	var vale := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	vale.save_path = path
	root.add_child(vale)
	await _ticks(5)
	var world: WorldSimulation = vale.simulation
	var market := world.economy
	var stock := market.stock
	var route_before: PackedVector3Array = vale.navigation.find(Vector3(8.7, 0.1, -12), Vector3(17.6, 0.1, -12))
	_check(absf(_crossing_z(route_before) - 2.0) < 0.9, "navegação usa a ponte de pedra antes da inauguração")
	var afonso: Dictionary = vale.residents.plans[6]
	var branca: Dictionary = vale.residents.plans[8]
	_check(vale.residents.working(afonso, 8.0) and not vale.residents.working(branca, 8.0)
		and not vale.residents.working(afonso, 22.0) and vale.residents.working(branca, 22.0),
		"guardas alternam os turnos")
	var carrier: Dictionary = vale.residents.plans[5]
	var home: Vector3 = carrier.home
	var saw_work := false
	var saw_carry := false
	var captured := false
	var nav_before: int = vale.navigation.revision
	var initial_iron := stock.amount("forge", "ferro")
	var stage_seen := {}
	for i in 5400:
		await physics_frame
		stage_seen[world.construction.phase()] = true
		saw_work = saw_work or vale.people[0].visual.animation == &"work"
		saw_carry = saw_carry or vale.people[5].visual.animation == &"carry"
		var in_transit := stock.amount("nilo", "trigo")
		if not captured and in_transit > 0 and carrier.position.distance_to(carrier.destination) > 0.40:
			captured = true
			var position: Vector3 = carrier.position
			var event_total := market.journal.entries.size()
			var crop_due := market.crop_due
			_press(vale, KEY_F5)
			stock.spend("nilo", {"trigo": in_transit})
			vale.people[5].position = Vector3.ZERO
			_press(vale, KEY_F9)
			_check(stock.amount("nilo", "trigo") == in_transit and vale.people[5].position.is_equal_approx(position),
				"F5/F9 preservam carga e posição do transportador")
			_press(vale, KEY_F9)
			_check(stock.amount("nilo", "trigo") == in_transit and market.journal.entries.size() == event_total
				and is_equal_approx(market.crop_due, crop_due), "carregar duas vezes mantém inventário, lavoura e histórico")
		if _has(market.journal, "market") and _has(market.journal, "sale") and world.construction.complete() and i > 3100:
			break
	_check(captured and saw_carry and vale.people[5].position.distance_to(home) > 3.0,
		"transportador percorre o trajeto e exibe animação com carga")
	_check(_has(market.journal, "harvest") and _has(market.journal, "farm_store"),
		"agricultora colhe e deposita trigo")
	var harvest := _event_id(market.journal, "harvest")
	var deposit := _event_id(market.journal, "farm_store")
	var delivery := _event_id(market.journal, "delivery")
	var conversion := _event_id(market.journal, "market")
	_check(harvest > 0 and harvest < deposit and deposit < delivery and delivery < conversion,
		"colheita, depósito, transporte e processamento são encadeados")
	_check(stock.amount("forge", "ferro") < initial_iron and _has(market.journal, "forge"),
		"ferreiro consome ferro e produz ferramentas")
	_check(_has(market.journal, "sale") and market.demand > 0, "compra gera demanda real por trigo")
	_check(saw_work and stage_seen.has(5) and stage_seen.has(7) and stage_seen.has(9)
		and world.construction.complete(), "carpinteiros trabalham nas fases físicas até a inspeção")
	_check(vale.navigation.revision > nav_before, "inauguração reconstrói a navegação")
	var route_after: PackedVector3Array = vale.navigation.find(Vector3(8.7, 0.1, -12), Vector3(17.6, 0.1, -12))
	_check(absf(_crossing_z(route_after) + 12.0) < 0.8, "nova travessia encurta a rota")
	_check(_has(market.journal, "greeting"), "encontros na vila geram cumprimentos com intervalo")
	_check(vale.fauna.animals.size() == 12 and ValeFauna.TYPES.size() == 6
		and vale.ambience.animal_streams.size() == 6, "seis espécies com sprites e sons")
	var cat: Dictionary = vale.fauna.animals[10]
	var body: CharacterBody3D = cat.body
	body.position = Vector3(-6.3, 0.06, -3.95)
	var collision := body.move_and_collide(Vector3(0, 0, -1.75))
	_check(collision != null and body.position.z > -4.7, "fauna colide com a fachada")
	var animal_bounds := true
	for animal in vale.fauna.animals:
		if animal.kind == "gato":
			continue
		var p: Vector3 = animal.body.position
		var origin: Vector3 = animal.home
		var radius: float = ValeFauna.TYPES[animal.kind].radius
		animal_bounds = animal_bounds and Vector2(p.x - origin.x, p.z - origin.z).length() <= radius + 0.25
	_check(animal_bounds, "animais permanecem no raio da espécie")

	world.clock.elapsed = WorldClock.DAY_SECONDS * (1.0 + 10.0 / 24.0)
	vale._refresh_environment(0.2)
	await _ticks(150)
	var sheltering := false
	for plan in vale.residents.plans:
		sheltering = sheltering or plan.state == "SEEKING_SHELTER"
	_check(vale.raining and sheltering, "chuva muda destinos para abrigos")
	await _ticks(1000)
	_check(_has(market.journal, "watch"), "guarda reforça a vigia da margem chuvosa")
	world.clock.elapsed = WorldClock.DAY_SECONDS * 22.0 / 24.0
	vale._refresh_environment(0.2)
	await _ticks(1400)
	_check(vale.residents.plans[0].state == "SLEEPING" and vale.people[0].visual.animation == &"sleep",
		"carpinteiro volta para descansar e dorme")
	_press(vale, KEY_J)
	_check(vale.hud.inspection.visible and vale.hud.inspection_title.text == "Diário do Vale",
		"diário acessível durante a partida")
	_press(vale, KEY_I)
	_check(vale.hud.inspection_title.text == "Viajante", "jogador consulta a carga")
	var at_save: float = world.clock.elapsed
	var offline := world.snapshot()
	offline.player = [0.0, 0.1, 3.0]
	offline.written_unix = Time.get_unix_time_from_system() - 9000
	vale.saves.write_state(offline, path)
	vale._load(false)
	_check(is_equal_approx(world.clock.elapsed, at_save + 1800.0), "avanço fechado limitado a 30 minutos reais")
	DirAccess.remove_absolute(path)
	print("%d verificações da vila, %d falhas." % [passed + failed, failed])
	quit(1 if failed else 0)

func _check_inventory_and_migration() -> void:
	var world := WorldSimulation.new()
	var stock := world.economy.stock
	var start := stock.amount("depot", "pedra")
	_check(not stock.transfer("depot", "ivo", "pedra", 100) and stock.amount("depot", "pedra") == start,
		"transferência insuficiente deixa os estoques intactos")
	_check(world.reserve_build("ivo") and stock.amount("depot", "pedra") == start - 1
		and stock.amount("ivo", "pedra") == 1 and world.construction.phase() == 1, "separação física reserva uma pedra")
	_check(world.reserve_build("ivo") and stock.amount("depot", "pedra") == start - 1,
		"reservar novamente mantém uma única carga")
	world.construction.logistics(2)
	_check(world.unload_build("ivo") and stock.amount("site", "pedra") == 1 and world.construction.phase() == 3,
		"descarga transfere a pedra ao canteiro")
	_check(world.work_bridge() and stock.amount("site", "pedra") == 0
		and world.construction.phase() == 4 and not world.work_bridge(),
		"obra consome o recurso e bloqueia instalação duplicada")
	var legacy := FileAccess.open(path, FileAccess.WRITE)
	legacy.store_string('{"version":1,"state":{"elapsed":2550,"bridge":{"stage":1,"delivered":0},"player":[1,0.1,2],"carrying":true}}')
	legacy.close()
	var saver := SaveManager.new()
	var data := saver.read_state(path)
	if not data.is_empty():
		world.restore(data)
	_check(not data.is_empty() and world.construction.stage == 1
		and world.economy.stock.amount("player", "pedra") == 1, "migra progresso e carga de salvamento 1")
	DirAccess.remove_absolute(path)

func _event_id(logbook: VillageJournal, kind: String) -> int:
	for event in logbook.entries:
		if event.kind == kind:
			return event.id
	return -1

func _has(logbook: VillageJournal, kind: String) -> bool:
	return _event_id(logbook, kind) > 0

func _crossing_z(route: PackedVector3Array) -> float:
	for i in range(1, route.size()):
		var a := route[i - 1]
		var b := route[i]
		if a.x < 13.0 and b.x >= 13.0:
			return a.lerp(b, (13.0 - a.x) / (b.x - a.x)).z
	if not route.is_empty() and route[0].x > 13.0:
		return route[0].z
	return INF

func _ticks(count: int) -> void:
	for i in count:
		await physics_frame

func _press(vale: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = key
	vale._unhandled_input(event)

func _check(result: bool, label: String) -> void:
	if result:
		passed += 1
		print("OK ", label)
	else:
		failed += 1
		push_error("FALHA: " + label)
