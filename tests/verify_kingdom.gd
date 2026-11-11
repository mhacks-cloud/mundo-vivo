extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var vale := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	root.add_child(vale)
	var career: ValeLife = vale.career
	career.new_game()
	career.confirm_character("Bia do Junco", "warrior", "amieiro", 0, 0)
	career.confirm_plot("sul-01")
	var life := career.life
	var trade := career.frontier
	var authority := career.authority
	var law := authority.justice
	var secret := authority.underworld
	var works := authority.works
	var clock: WorldClock = vale.simulation.clock
	var legacy := career.snapshot()
	legacy.erase("authority")
	career.restore(legacy)
	check(law.state(clock.elapsed) == "CIDADÃO" and life.profile.name == "Bia do Junco",
		"save 4.1 restaura personagem e inicializa os sistemas novos")

	clock.elapsed += 2 * WorldClock.DAY_SECONDS
	life.bag.add("wheat", 3)
	vale.player.position = FrontierTrade.ORIGIN
	var opening: int = trade.stock.wheat
	var price := trade.price("wheat")
	check(career.perform("dispatch", "") == "Concluído.", "o frete parte pela entrada normal")
	for i in 5400:
		await physics_frame
		if not trade.loot.is_empty():
			break
	check(not trade.loot.is_empty() and authority.escort_calls == 1 and authority.escort_bonus == 4,
		"perda real de frete gera alerta e novo prêmio de escolta")
	check(trade.stock.wheat == opening - 1 and trade.price("wheat") > price,
		"escassez do trigo aumenta o preço no mercado de destino")
	check(law.case_file.is_empty(), "a vítima não recebe acusação")
	for i in 2400:
		await physics_frame
		if not secret.market.is_empty():
			break
	check(secret.market.size() == 1 and trade.loot.get("quantity") == 2,
		"batedor caminha até a carga e recolhe um único fardo")
	if not secret.market.is_empty():
		var lot: Dictionary = secret.market[0]
		vale.player.position = Underworld.HIDEOUT
		check(lot.owner == life.profile.uid and lot.quantity == 1 and not secret.salvage(trade),
			"lote tem proveniência e o mesmo saque não pode ser repetido")
		life.gold = 30
		check(career.perform("secret_join", "") == "Concluído." and career.guild.member.is_empty(),
			"registro clandestino independe da Companhia do Vau")
		authority.witness.position = Underworld.HIDEOUT + Vector3.BACK * 0.7
		var wheat := life.bag.amount("wheat")
		check(career.perform("secret_buy", lot.id) == "Concluído." and secret.fee_total == 1
			and life.bag.amount("wheat") == wheat, "compra cobra taxa e não converte em trigo comum")
		check(law.state(clock.elapsed) == "SUSPEITO" and not law.case_file.get("witness", "").is_empty(),
			"negociação observada aciona o registro de testemunha do mundo")
		check(secret.buy(life, lot.id) == false and secret.sell(life, lot.id) and secret.buy(life, lot.id),
			"revenda e recompra transferem o mesmo lote")
		check(secret.accept(life) and secret.deliver(life, lot.id) and not secret.deliver(life, lot.id),
			"contrato consome o lote uma única vez")
		var snapshot := career.snapshot()
		career.restore(snapshot)
		check(lot.id in secret.settled and trade.loot.get("quantity") == 2,
			"lote liquidado e saldo do saque persistem")

	var now := clock.elapsed
	law.restore(null)
	var uid: String = life.profile.uid
	check(not law.report("trade", uid, "brumaria", "", ValeAuthority.HOLD, now)
		and not law.report("assault", uid, "vale", "Dália", ValeAuthority.HOLD, now, true)
		and not law.report("assault", uid, "vale", "Dália", ValeAuthority.HOLD, now, false, true)
		and not law.report("trade", uid, "sem_lei", "Dália", ValeAuthority.HOLD, now),
		"sem testemunha, em legítima defesa, como vítima ou em território sem lei não há acusação")
	check(law.report("trade", uid, "brumaria", "Nuno", ValeAuthority.HOLD, now)
		and law.state(now) == "SUSPEITO" and law.state(now + 3) == "CRIMINOSO",
		"denúncia testemunhada passa por suspeita antes de virar mandado")
	life.gold = 30
	vale.player.position = ValeAuthority.HOLD
	clock.elapsed += 3.0
	check(career.perform("fine", "") == "Concluído." and life.gold == 12,
		"posto quita multa regional quando há saldo")
	now = clock.elapsed
	life.gold = 0
	for id in RegionalJustice.SEIZABLE:
		var amount := life.bag.amount(id)
		if amount > 0:
			life.bag.spend({id: amount})
	life.bag.add("wood", 1)
	var sword := life.bag.amount("sword")
	var arrest_at := Vector3(22.35, 0.10, -8.15)
	vale.player.position = arrest_at
	var plot := life.estate.owned(PlayerLife.ID)
	law.report("trade", uid, "brumaria", "Nuno", arrest_at, now)
	clock.elapsed += 3.0
	authority.guard.position = arrest_at + Vector3.BACK * 0.55
	await physics_frame
	await physics_frame
	check(authority.detained() and law.debt > 0 and life.gold == 0
		and life.bag.amount("sword") == sword and life.bag.amount("wood") == 0 and life.estate.owned(PlayerLife.ID) == plot,
		"guarda captura em alcance e pena preserva equipamento e propriedade")
	career.restore(career.snapshot())
	check(authority.detained() and law.state(clock.elapsed) == "PRESO", "prazo de prisão persiste no save")
	clock.elapsed = maxf(clock.elapsed, law.jail_until + 0.1)
	await physics_frame
	await physics_frame
	check(not authority.detained() and law.debt == 0 and law.state(clock.elapsed) == "REINCIDENTE",
		"calendário libera a pena e preserva reincidência")
	check(law.report("trade", uid, "brumaria", "Nuno", arrest_at, clock.elapsed)
		and law.state(clock.elapsed + 3.0) == "FORA_DA_LEI", "reincidência com novo mandado gera estado fora da lei")
	law.restore(null)

	clock.elapsed = 2 * WorldClock.DAY_SECONDS + 9.0 * WorldClock.DAY_SECONDS / 24.0
	vale.simulation.construction.stage = 3
	vale._bridge_changed()
	await physics_frame
	await physics_frame
	var before := _route_length(vale.navigation.find(FrontierTrade.ORIGIN, FrontierTrade.DESTINATION), FrontierTrade.ORIGIN)
	var quote := trade.freight_pay()
	var retail := trade.retail_price("wheat")
	check(works.flood(clock.total_day(), 0.91, "Chuva", vale.simulation.construction.complete()), "chuva intensa interdita a ponte norte")
	await physics_frame
	await physics_frame
	var blocked := _route_length(vale.navigation.find(FrontierTrade.ORIGIN, FrontierTrade.DESTINATION), FrontierTrade.ORIGIN)
	check(before > 0 and blocked > before and trade.freight_pay(works.road_closed) == quote - 3 and trade.retail_price("wheat") == retail + 1,
		"navegação calcula desvio mais longo e o frete tem custo de desvio")
	vale.player.position = CivicWorks.HALL
	var stock: VillageInventory = vale.simulation.economy.stock
	stock.add("depot", "madeira", 2)
	stock.add("depot", "pedra", 2)
	var budget := life.treasury
	var wood := stock.amount("depot", "madeira")
	var stone := stock.amount("depot", "pedra")
	check(career.perform("royal", "market").begins_with("Recusada"), "rei explica a recusa de terreno incompatível")
	check(career.perform("royal", "road").begins_with("Aprovada") and life.treasury == budget - 26
		and stock.amount("depot", "madeira") == wood - 2 and stock.amount("depot", "pedra") == stone - 2,
		"proposta na prefeitura reserva recursos reais")
	var carried := false
	var paused := false
	for i in 5400:
		await physics_frame
		if not works.approved.is_empty() and works.approved.cargo != "":
			carried = true
			if not paused:
				paused = true
				career.restore(career.snapshot())
		if not works.road_closed:
			break
	check(carried and "road" in works.completed and not works.road_closed,
		"trabalhadora transporta recursos, retoma de save e inaugura a obra")
	await physics_frame
	await physics_frame
	var reopened := _route_length(vale.navigation.find(FrontierTrade.ORIGIN, FrontierTrade.DESTINATION), FrontierTrade.ORIGIN)
	check(reopened > 0 and reopened < blocked and trade.freight_pay(works.road_closed) == quote and trade.retail_price("wheat") == retail,
		"reparo restaura o caminho curto e retira o custo extra")
	for suffix in ["", ".previous", ".pre-4.1.bak"]:
		DirAccess.remove_absolute(vale.save_path + suffix)
	print("%d verificações de reinos, %d falhas." % [checks, failures])
	quit(1 if failures else 0)

func _route_length(path: PackedVector3Array, origin: Vector3) -> float:
	var distance := 0.0
	for point in path:
		distance += origin.distance_to(point)
		origin = point
	return distance

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("OK " if ok else "FALHA ") + label)
