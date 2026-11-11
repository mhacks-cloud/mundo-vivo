extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var vale := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	root.add_child(vale)
	var career: ValeLife = vale.career
	check(career.setup_stage == "menu", "a entrada padrão abre o menu principal")
	career.new_game()
	check(career.setup_stage == "creator" and vale.save_path.begins_with(SaveManager.SLOT_DIR), "nova partida recebe arquivo próprio")
	career.confirm_character("Nara do Vale", "warrior", "amieiro", 0, 0)
	career.confirm_plot("sul-01")
	var life := career.life
	var id: String = life.profile.uid
	var first: String = vale.save_path
	var second: String = vale.saves.new_slot()
	check(not id.is_empty() and first != second and not FileAccess.file_exists(second), "identidade única e caminho independente")
	var slots: Array[Dictionary] = vale.saves.list_slots()
	check(slots.any(func(entry: Dictionary) -> bool: return entry.path == first and entry.label == "Nara do Vale"), "menu lista o nome gravado")
	var original_gold := life.gold
	life.gold += 2
	vale._save()
	var corrupt := FileAccess.open(first, FileAccess.WRITE)
	corrupt.store_string('{"version":4,"payload":"alterado","sha256":"inválido"}')
	corrupt.close()
	check(vale.saves.read_state(first).is_empty() and not vale.saves.read_state(first + ".previous").is_empty(), "checksum rejeita corrupção e preserva cópia anterior")
	career.start_menu()
	for entry in vale.saves.list_slots():
		if entry.path == first:
			check(entry.recover, "menu oferece recuperação explícita")
			career.open_save(entry)
			break
	check(life.gold == original_gold and life.profile.uid == id and career.setup_stage.is_empty(), "recuperação restaura ouro e identidade do mesmo personagem")
	vale._save()
	check(not vale.saves.read_state(first).is_empty(), "salvar após recuperação restaura o arquivo principal")

	var another := PlayerLife.new()
	another.create("Dora da Serra", "mage", "amieiro", 0, 0)
	another.claim("sul-02")
	var legacy: Dictionary = vale.saves.read_state(first)
	legacy.career.life = another.snapshot()
	var old_format := FileAccess.open(second, FileAccess.WRITE)
	old_format.store_string(JSON.stringify({"version": 3, "state": legacy}))
	old_format.close()
	career.start_menu()
	for entry in vale.saves.list_slots():
		if entry.path == second:
			career.open_save(entry)
			break
	check(life.role() == "mage" and life.profile.uid != id and life.estate.owned(PlayerLife.ID) == "sul-02",
		"segunda partida em esquema 3 tem classe, identidade e terreno independentes")
	vale._save()
	check(FileAccess.file_exists(second + ".pre-4.1.bak"), "migração do esquema 3 guarda o arquivo original")
	career.start_menu()
	for entry in vale.saves.list_slots():
		if entry.path == first:
			career.open_save(entry)
			break
	check(life.profile.uid == id and life.estate.owned(PlayerLife.ID) == "sul-01", "retornar à primeira partida preserva o progresso separado")
	for suffix in ["", ".previous", ".pre-4.1.bak"]:
		DirAccess.remove_absolute(second + suffix)

	var estate := life.estate
	var plot := estate.owned(PlayerLife.ID)
	var origin := Vector2i(1, 1)
	var destination := Vector2i(2, 1)
	for cell in [origin, destination]:
		estate.install(PlayerLife.ID, plot, "foundation", cell, 0, life.bag)
		estate.install(PlayerLife.ID, plot, "floor", cell, 0, life.bag)
	life.bag.add("chair", 1)
	estate.install(PlayerLife.ID, plot, "chair", origin, 0, life.bag)
	var furniture := estate.pieces.size() - 1
	var wood := life.bag.amount("wood")
	check(not estate.remove(PlayerLife.ID, 1).is_empty(), "piso com banco não pode ser removido")
	check(not estate.move("terceiro", furniture, destination, 2).is_empty(), "reforma valida o proprietário")
	check(estate.move(PlayerLife.ID, furniture, destination, 2).is_empty() and life.bag.amount("wood") == wood
		and estate.layer_at(plot, destination, "furniture"), "mover banco preserva a peça sem gerar recursos")
	check(estate.remove(PlayerLife.ID, 1).is_empty() and not estate.layer_at(plot, origin, "floor"), "piso livre pode ser removido")
	var reloaded := Homestead.new()
	reloaded.restore(estate.snapshot())
	check(reloaded.layer_at(plot, destination, "furniture"), "reforma persiste no carregamento")

	var farmer := PlayerLife.new()
	farmer.create("Helena", "farmer", "amieiro", 0, 0)
	farmer.claim("sul-01")
	farmer.estate.install(PlayerLife.ID, "sul-01", "garden", origin, 0, farmer.bag)
	farmer.bag.add("egg", 1)
	check(farmer.farm(origin, "seed", 5, false, 4) and farmer.farm(origin, "water", 5)
		and farmer.farm(origin, "fertilize", 5) and not farmer.farm(origin, "harvest", 30), "frio retarda a lavoura e o adubo é consumido")
	check(farmer.farm(origin, "harvest", 45) and farmer.bag.amount("wheat") == 6, "adubação aumenta o rendimento")

	vale.player.position = Vector3(21, 0.1, -18.4)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	vale._unhandled_input(event)
	check(RuinRun.inside(vale.player.position) and not career.ruin.run.gate_open(), "entrada real da ruína e câmara fechada")
	var run := career.ruin.run
	check(not run.strike(life, 2, 100), "chefe protegido enquanto os vigias estão vivos")
	for i in 2:
		run.strike(life, i, 100)
	career.ruin.refresh()
	check(run.gate_open() and career.ruin.gate.collision_layer == 0, "derrotar vigias abre a passagem física")
	await physics_frame
	vale.player.position = career.ruin.enemies[2].actor.position - Vector3.RIGHT
	life.cooldown = 0.0
	career._attack()
	check(run.health[2] < RuinRun.MAX_HP[2], "técnica do guerreiro causa dano no chefe pela cena")
	run.strike(life, 2, 100)
	var ore := life.bag.amount("iron")
	check(run.recover(life) and life.bag.amount("iron") == ore + 4 and not run.recover(life), "cofre entrega recompensa uma vez")
	vale._save()
	run.health[2] = 91.0
	vale._load(true)
	check(run.claimed and run.health[2] == 0 and RuinRun.inside(vale.player.position), "masmorra e recompensa persistem")
	career.ruin.leave()
	check(vale.player.position.is_equal_approx(RuinRun.EXIT), "saída devolve o jogador ao Vale")
	var valley_stock: VillageInventory = vale.simulation.economy.stock
	vale.simulation.clock.elapsed = WorldClock.DAY_SECONDS * 10 / 24
	var town_log: VillageJournal = vale.simulation.economy.journal
	for i in 4200:
		await physics_frame
		if valley_stock.amount("market", "trigo") > 0 and town_log.entries.any(func(item: Dictionary) -> bool: return item.kind == "delivery"):
			break
	var initial_wheat := valley_stock.amount("market", "trigo")
	vale.player.position = ValeLife.STATIONS.store
	check(career.perform("buy", "wheat") == "Concluído." and valley_stock.amount("market", "trigo") == initial_wheat - 1,
		"jogador compra o trigo produzido e entregue pelos NPCs")
	life.bag.add("wheat", 2)
	vale.player.position = GuildLedger.HALL
	check(career.perform("join_guild", "") == "Concluído." and career.guild.member == id, "sede registra o membro pelo identificador persistente")
	check(career.perform("guild_deposit", "wood") == "Concluído." and career.guild.storage.amount("wood") == 1
		and career.perform("guild_withdraw", "wood") != "Concluído.", "armazém transfere itens e impede retirada sem cargo")
	var trade := career.frontier
	var frontier_wheat: int = trade.stock.wheat
	var quote := trade.price("wheat")
	var gold := life.gold
	vale.player.position = FrontierTrade.ORIGIN
	check(career.perform("dispatch_escort", "") == "Concluído." and life.bag.amount("wheat") == 0
		and life.gold == gold and trade.stock.wheat == frontier_wheat, "frete reserva carga e pagamento antes de viajar")
	check(career.guild.escort and career.guild.treasury == 60 - GuildLedger.PAY, "contrato de escolta reserva ouro da guilda")
	for i in 300:
		if not trade.shipment.is_empty():
			vale.player.position = trade.shipment.position
		await physics_frame
	check(not trade.shipment.is_empty() and trade.shipment.position.distance_to(FrontierTrade.ORIGIN) > 1.5
		and trade.stock.wheat == frontier_wheat, "carroça avança fisicamente sem entregar à distância")
	var position: Vector3 = trade.shipment.position
	var saved_wheat := valley_stock.amount("market", "trigo")
	vale._save()
	vale._load(true)
	check(trade.shipment.position.is_equal_approx(position) and valley_stock.amount("market", "trigo") == saved_wheat,
		"posição, carga e estoque da banca persistem")
	for i in 3900:
		if not trade.shipment.is_empty():
			vale.player.position = trade.shipment.position
		await physics_frame
		if trade.shipment.is_empty():
			break
	check(trade.shipment.is_empty() and trade.deliveries == 1 and trade.stock.wheat == frontier_wheat + 3
		and life.gold == gold + quote * 3 + GuildLedger.PAY, "chegada credita carga e ouro uma única vez")
	check(not career.guild.escort and career.guild.reputation == 1, "acompanhar a carroça conclui a escolta e concede reputação")
	check(trade.price("wheat") < quote and not trade.arrive(life), "preço responde ao estoque e entrega não duplica")
	vale.player.position = FrontierTrade.DESTINATION
	check(career.perform("frontier_buy", "wheat") == "Concluído." and trade.stock.wheat == frontier_wheat + 2,
		"mercado de Brumária negocia com estoque independente")
	var cargo := life.bag.amount("wheat")
	life.bag.add("wheat", 3)
	var kept_gold := life.gold
	var kept_weapon := life.bag.amount("sword")
	vale.simulation.clock.elapsed = WorldClock.DAY_SECONDS * 2 + 3000.0
	vale.player.position = FrontierTrade.ORIGIN
	check(career.perform("dispatch_escort", "") == "Concluído.", "frete de dia de risco pode partir com contrato")
	for i in 3500:
		await physics_frame
		if trade.shipment.is_empty():
			break
	check(trade.shipment.is_empty() and not trade.loot.is_empty() and trade.loot.quantity == 3,
		"emboscada derrota a carroça e toda a carga se torna recuperável")
	check(life.gold == kept_gold and life.bag.amount("sword") == kept_weapon and not career.guild.escort,
		"derrota encerra a escolta e preserva ouro e equipamento pessoal")
	var location: Vector3 = trade.loot.get("position", FrontierTrade.DESTINATION)
	vale.player.position = location
	vale._save()
	vale._load(true)
	check(trade.collect(life, location, vale.simulation.clock.elapsed) and life.bag.amount("wheat") == cargo + 3
		and not trade.collect(life, location, vale.simulation.clock.elapsed), "carga recupera uma única vez após recarregar")
	for suffix in ["", ".previous"]:
		DirAccess.remove_absolute(first + suffix)
	print("%d verificações da expansão, %d falhas." % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("OK ", label)
	else:
		failures += 1
		push_error("FALHA: " + label)
