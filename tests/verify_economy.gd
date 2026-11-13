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
	career.confirm_character("Bia da Forja", "smith", "amieiro", 0, 0)
	career.confirm_plot("sul-01")
	var life := career.life
	var econ: EconomyManager = vale.markets
	var realm: RealmWorld = vale.realms.world
	var clock: WorldClock = vale.simulation.clock
	var dip := econ.diplomacy
	var stock: VillageInventory = vale.simulation.economy.stock
	var old: Dictionary = vale.saves.read_state(vale.save_path)
	old.erase("regional_economy")
	vale.saves.write_state(old, vale.save_path)
	check(vale._load(true) and econ.contracts.is_empty() and life.role() == "smith", "save 4.3 recebe economia inicial")
	var scarce := econ.quote(vale, "vale", "wheat")
	stock.add("market", "trigo", 20)
	check(econ.quote(vale, "vale", "wheat") < scarce, "abundância reduz preço efetivo")
	vale.player.position = ValeLife.STATIONS.contracts
	var treasury := life.treasury
	check(career.perform("economy_accept", "harvest").begins_with("Pagamento") and life.treasury == treasury - 18,
		"contrato reserva ouro no aceite")
	var gold := life.gold
	life.bag.add("wheat", 2)
	check(career.perform("economy_deliver", "harvest") == "Entrega parcial registrada." and life.gold == gold, "entrega parcial não paga")
	vale._save()
	vale._load(true)
	life.bag.add("wheat", 2)
	check(career.perform("economy_deliver", "harvest").begins_with("Entrega concluída") and life.gold == gold + 18
		and econ.contracts.harvest.done == 4, "conclusão após recarga paga a reserva")
	check(career.perform("economy_deliver", "harvest") == "Contrato sem entrega válida." and life.gold == gold + 18, "pagamento único")
	check(not life.craft("health", "alchemy") and not life.craft("chair", "carpentry"), "receitas preservam exclusividade")
	vale.player.position = RealmWorld.ROAD_ENTRY
	vale.realms.travel(true)
	vale.player.position = RealmWorld.MARKET
	var iron_before: int = realm.stock.iron
	life.gold = 100
	check(career.perform("bruma_buy", "iron") == "Compra concluída." and realm.stock.iron == iron_before - 1, "ferreiro compra ferro real")
	life.bag.add("wood", 2)
	vale.player.position = Vector3(61.9, 0.1, 44.5)
	check(career.perform("craft", "hoe") == "Concluído." and life.bag.amount("hoe") == 1, "forja serrana transforma insumos em ferramenta")
	vale.player.position = RealmWorld.MARKET
	check(career.perform("bruma_sell", "hoe") == "Venda concluída." and realm.stock.hoe == 1, "ferramenta entra no mercado")
	var farmer := PlayerLife.new()
	farmer.create("Eva do Campo", "farmer", "amieiro", 0, 0)
	farmer.gold = 100
	farmer.bag.spend({"hoe": 1})
	check(realm.buy(farmer, "hoe") and realm.stock.hoe == 0, "agricultora compra a ferramenta vendida")
	var prior: int = farmer.bag.condition.hoe
	farmer.wear("tool")
	var fee_gold := farmer.gold
	check(farmer.bag.condition.hoe == prior - 1 and farmer.repair("hoe", false) and farmer.gold == fee_gold - 6,
		"uso desgasta e reparo consome ouro")
	clock.elapsed = WorldClock.DAY_SECONDS * 10 / 24
	var day := clock.total_day()
	var tariff := realm.tariff(day)
	check(dip.negotiate("trade", day, life, realm) and not dip.negotiate("trade", day, life, realm)
		and realm.tariff(day) < tariff, "tratado único reduz tarifa")
	career.frontier.stock.wheat = 6
	var paid := realm.tariff(day)
	var royal := realm.treasury
	check(realm.reserve(career.frontier, clock), "comboio reserva carga comprada")
	for index in 250:
		await physics_frame
		if realm.customs > 0:
			break
	check(realm.customs == 1 and realm.shipment.get("tax") == paid and realm.treasury == royal + paid, "fronteira aplica taxa do tratado")
	vale._save()
	vale._load(true)
	check(dip.active("trade", day) and realm.customs == 1 and realm.tariff(day + 4) == tariff, "save preserva tratado e vencimento restaura tarifa")
	dip.change(25, "Teste de cooperação")
	check(dip.negotiate("works", day, life, realm) and realm.shared_funds == 4, "cooperação reserva contribuição")
	realm.damage(day)
	var budget := realm.treasury
	check(realm.propose("repair", "Elira").begins_with("Aprovada") and realm.shared_funds == 0
		and realm.treasury == budget - 19, "reparo físico combina orçamentos")
	var supplies := FrontierTrade.new()
	var origin := VillageInventory.new()
	origin.add("market", "trigo", 3)
	var previous_cash := life.market_cash
	var relief_day := day + 1
	check(supplies.dispatch_relief(origin, relief_day, false) and origin.amount("market", "trigo") == 0
		and not supplies.dispatch_relief(origin, relief_day, false), "abastecimento reserva trigo real uma única vez")
	var restored := FrontierTrade.new()
	restored.restore(supplies.snapshot())
	check(not restored.arrive(life), "abastecimento não paga antes da chegada")
	restored.shipment.position = FrontierTrade.DESTINATION
	check(restored.arrive(life) and restored.stock.wheat == 5 and life.market_cash > previous_cash
		and not restored.arrive(life), "abastecimento restaura e paga à banca uma vez")
	var dry_farm := VillageEconomy.new()
	dry_farm.crop = 2
	dry_farm.dry = true
	dry_farm.farm(clock, false)
	check(dry_farm.crop_due > clock.elapsed + 44.0, "seca alonga a maturação sem multiplicar insumos")
	for suffix in ["", ".previous", ".pre-4.1.bak"]:
		DirAccess.remove_absolute(vale.save_path + suffix)
	print("%d verificações econômicas, %d falhas." % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("OK " if ok else "FALHA ") + label)
