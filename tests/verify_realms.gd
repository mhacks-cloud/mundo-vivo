extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var vale := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	root.add_child(vale)
	var career: ValeLife = vale.career
	var realms: ValeRealms = vale.realms
	var world := realms.world
	career.new_game()
	career.confirm_character("Nara do Atlas", "warrior", "amieiro", 0, 0)
	career.confirm_plot("sul-01")
	var life := career.life
	var trade := career.frontier
	var clock: WorldClock = vale.simulation.clock
	var original: Dictionary = vale.saves.read_state(vale.save_path)
	original.erase("realms")
	vale.saves.write_state(original, vale.save_path)
	check(vale._load(true) and not world.active and world.discovered == ["vale"]
		and life.profile.name == "Nara do Atlas", "save anterior preserva personagem e recebe atlas inicial")
	check(RealmWorld.PLACES.capital.realm == "brumaria" and RealmWorld.PLACES.vale.realm == "amieiro"
		and world.treasury != life.treasury and world.stock.iron != trade.stock.iron,
		"coroas e mercados têm identidades e estoques independentes")
	var tropical := RegionalClimate.new()
	tropical.latitude = -8.0
	tropical.altitude = 750
	tropical.biome = "floresta"
	var north := world.climate
	var snowy := false
	for day in WorldClock.YEAR_DAYS:
		snowy = snowy or tropical.sample(day, 4.0).weather == "Neve"
	check(not snowy and tropical.seasons.index(0, tropical.latitude) == posmod(north.seasons.index(0, north.latitude) + 2, 4)
		and north.sample(70, 9.0).temperature < tropical.sample(70, 9.0).temperature,
		"hemisférios invertidos, altitude fria e floresta tropical sem neve")
	check(world.access("north", false, false) == "EM CONSTRUÇÃO" and world.access("north", true, false) == "ABERTA"
		and world.access("north", true, true) == "FECHADA", "atlas reflete a obra e a enchente do acesso existente")

	clock.elapsed = WorldClock.DAY_SECONDS * 10 / 24
	var local: VillageInventory = vale.simulation.economy.stock
	var log: VillageJournal = vale.simulation.economy.journal
	for i in 4200:
		await physics_frame
		if local.amount("market", "trigo") > 0 and log.entries.any(func(entry: Dictionary) -> bool: return entry.kind == "delivery"):
			break
	var available := local.amount("market", "trigo")
	vale.player.position = ValeLife.STATIONS.store
	check(career.perform("buy", "wheat") == "Concluído." and local.amount("market", "trigo") == available - 1,
		"trigo produzido pelo agricultor chega à banca e é comprado")
	life.bag.add("wheat", 2)
	vale.player.position = FrontierTrade.ORIGIN
	check(career.perform("dispatch", "") == "Concluído.", "frete do Vale inicia na estrada original")
	for i in 4900:
		await physics_frame
		if trade.deliveries == 1:
			break
	check(trade.deliveries == 1 and trade.stock.wheat >= 3, "carroça original entrega ao entreposto")
	var border_supply: int = trade.stock.wheat
	var destination_supply: int = world.stock.wheat
	var old_quote := world.price("wheat")
	var kingdom_gold := world.treasury
	var identity: String = life.profile.uid
	var time := clock.elapsed
	var gate := InputEventKey.new()
	gate.physical_keycode = KEY_E
	gate.pressed = true
	vale.player.position = RealmWorld.ROAD_ENTRY
	vale._unhandled_input(gate)
	check(world.active and is_instance_valid(realms.scene) and not vale.diorama.visible
		and world.current(vale.player.position) == "capital" and world.discovered.has("capital")
		and life.profile.uid == identity and clock.elapsed == time, "portão carrega a capital sem trocar identidade ou calendário")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_P
	key.pressed = true
	vale._unhandled_input(key)
	check(realms.map.visible, "tecla P abre o atlas vinculado ao estado atual")
	vale._unhandled_input(key)
	for i in 420:
		await physics_frame
		if world.shipment.get("status") == "VIAJANDO" and world.shipment.at.distance_to(RealmWorld.GATE) > 2.8:
			break
	check(not world.shipment.is_empty() and trade.stock.wheat == border_supply - 3 and world.stock.wheat == destination_supply
		and world.customs == 1 and world.treasury > kingdom_gold,
		"Aldo compra no entreposto, atravessa a inspeção e percorre o primeiro trecho sem entrega instantânea")
	if world.shipment.is_empty():
		_finish(vale)
		return
	career.guild.join(life)
	vale.player.position = RealmWorld.GATE + Vector3(2.8, 0, 1.5)
	var guild_gold := career.guild.treasury
	check(career.perform("bruma_escort", "") == "Escolta reservada." and world.shipment.escort
		and career.guild.treasury == guild_gold - GuildLedger.PAY, "contrato da Companhia reserva pagamento no posto da fronteira")
	var at: Vector3 = world.shipment.at
	world.selected = "mine"
	vale._save()
	vale._load(true)
	check(world.shipment.at.is_equal_approx(at) and world.selected == "mine" and world.active and world.customs == 1,
		"save conserva posição de caravana, seleção do atlas e passagem sem cobrar duas vezes")
	vale.player.position = RealmWorld.GATE
	vale._unhandled_input(gate)
	check(not world.active and not is_instance_valid(realms.scene) and vale.diorama.visible and not world.shipment.is_empty(),
		"retorno descarrega cenário serrano com a caravana ainda ativa")
	for i in 2400:
		await physics_frame
		if world.deliveries == 1:
			break
	check(world.deliveries == 1 and world.stock.wheat == destination_supply + 3 and world.price("wheat") < old_quote,
		"entrega fora da região visitada abastece o mercado e reduz o preço")
	check(career.guild.treasury == guild_gold, "escolta sem cobertura suficiente devolve a reserva")
	vale.player.position = RealmWorld.ROAD_ENTRY
	realms.travel(true)
	vale.player.position = RealmWorld.MINE
	var iron := life.bag.amount("iron")
	var deposits := world.mine_units
	vale._unhandled_input(gate)
	check(life.bag.amount("iron") == iron + 1 and world.mine_units == deposits - 1, "pedreira troca custo por minério de estoque finito")

	clock.elapsed = 2 * WorldClock.DAY_SECONDS + 10.0 * WorldClock.DAY_SECONDS / 24.0
	world.next_convoy = clock.elapsed
	world.stock.wheat = 1
	trade.stock.wheat = 6
	var normal_price := world.price("wheat")
	check(world.damage(2) and world.route() == "lower" and world.price("wheat") > normal_price,
		"dano fecha o caminho alto à carga e encarece o trigo")
	for i in 3000:
		await physics_frame
		if not world.loot.is_empty():
			break
	check(world.last_convoy == "PERDIDA" and world.loot.get("quantity") == 3
		and career.authority.justice.case_file.is_empty(), "emboscada no desvio derruba a carga integral sem acusar a vítima")
	if not world.loot.is_empty():
		var sample := RealmWorld.new()
		sample.restore(world.snapshot())
		var secret := Underworld.new()
		for index in 1200:
			sample.scout_loot(secret, clock.elapsed + 15.0, 1.0 / 60.0)
		check(secret.market.size() == 1 and sample.loot.quantity == 2 and secret.market[0].owner_name == "Aldo",
			"batedora transfere um único fardo rastreável ao Junco")
		vale.player.position = world.loot.at
		var carried := life.bag.amount("wheat")
		vale._save()
		vale._load(true)
		vale._unhandled_input(gate)
		check(world.loot.is_empty() and life.bag.amount("wheat") == carried + 3
			and not world.recover(life, vale.player.position, clock.elapsed), "carga salva é recolhida uma única vez")
	vale.player.position = RealmWorld.HALL
	var wood: int = world.stock.wood
	var steel: int = world.stock.iron
	check(career.perform("bruma_propose", "house").begins_with("Recusada"), "rainha recusa crescimento antes das condições")
	check(career.perform("bruma_propose", "repair").begins_with("Aprovada") and world.stock.wood == wood - 2
		and world.stock.iron == steel - 2, "rainha aprova reparo com reserva real de materiais")
	world.next_convoy = clock.elapsed + 500
	var moved := false
	for i in 5400:
		await physics_frame
		if not moved and world.project.get("step") == 1 and world.worker_at.distance_to(RealmWorld.DEPOT) > 1.3:
			moved = true
			var work_at := world.worker_at
			vale._save()
			vale._load(true)
			check(world.worker_at.is_equal_approx(work_at) and world.project.step == 1,
				"trabalhadora carrega material fisicamente e retoma a posição após recarga")
		if not world.damaged:
			break
	check(moved and not world.damaged and world.route() == "ridge" and world.access("ridge", true, false) == "ABERTA",
		"obra concluída reabre o caminho alto")
	world.next_convoy = clock.elapsed
	for i in 3600:
		await physics_frame
		if world.deliveries >= 2:
			break
	check(world.deliveries >= 2 and world.last_convoy == "CONCLUÍDA", "comboio volta a abastecer a capital pelo caminho reparado")
	for i in 9600:
		await physics_frame
		if world.houses > 0:
			break
	check(world.houses == 1 and world.population == 7 and world.access("hamlet", true, false) == "ABERTA",
		"atividade econômica inicia obra e libera o Pouso com nova moradora")
	vale.player.position = RealmWorld.HAMLET
	await physics_frame
	await physics_frame
	vale._save()
	vale._load(true)
	check(world.houses == 1 and world.current(vale.player.position) == "hamlet" and "hamlet" in world.discovered,
		"expansão, região ativa e descoberta do Pouso persistem")
	_finish(vale)

func _finish(vale: Node) -> void:
	for suffix in ["", ".previous", ".pre-4.1.bak"]:
		DirAccess.remove_absolute(vale.save_path + suffix)
	print("%d verificações territoriais, %d falhas." % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("OK " if ok else "FALHA ") + label)
