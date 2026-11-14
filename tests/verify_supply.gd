extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var days := int(args[0]) if not args.is_empty() else 30
	var game := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	root.add_child(game)
	var career: ValeLife = game.career
	career.new_game()
	career.confirm_character("Ana do Vale", "farmer", "amieiro", 0, 0)
	career.confirm_plot("sul-01")
	var realm: RealmWorld = game.realms.world
	realm.discover("capital")
	var clock: WorldClock = game.simulation.clock
	var village: VillageInventory = game.simulation.economy.stock
	var trade := career.frontier
	var initial_wheat: int = realm.stock.wheat
	var days_empty := 0
	var recovery := false
	var lowest := 32
	var lowest_treasury := realm.treasury
	var saw_block := false
	var saw_reopen := false
	var starting_money := realm.purse + realm.treasury + trade.purse + career.life.market_cash
	for day in days:
		clock.elapsed = day * WorldClock.DAY_SECONDS + 9.0 * WorldClock.DAY_SECONDS / 24.0
		if days >= 60 and day == 12:
			realm.damage(day)
		if days == 96 and day == 25:
			realm.population = maxi(realm.population, 7)
		if days == 96 and day == 42:
			realm.entrepreneur_cash = 0
		var economy: VillageEconomy = game.simulation.economy
		game.markets.tick(game)
		# Rotinas econômicas em ordem de trabalho; a rota do Vale ainda usa física e navegação.
		for step in 2:
			economy.farm(clock, false)
			clock.advance(80.0)
			economy.farm(clock, false)
			economy.store_harvest(clock)
			economy.pick_wheat(clock)
			economy.deliver_wheat(clock)
			economy.market(clock)
		for step in 1500:
			await physics_frame
			if trade.shipment.is_empty() and step > 180:
				break
		for step in 160:
			clock.advance(1.0)
			game.markets.tick(game)
			realm.advance(clock, trade, 1.0)
			realm.work(clock, 1.0)
		saw_block = saw_block or realm.damaged
		saw_reopen = saw_reopen or (saw_block and not realm.damaged)
		var wheat: int = realm.stock.wheat
		lowest = mini(lowest, wheat)
		lowest_treasury = mini(lowest_treasury, realm.treasury)
		days_empty += 1 if wheat == 0 else 0
		recovery = recovery or (days_empty > 0 and wheat > 0)
		if wheat != initial_wheat + realm.deliveries * FrontierTrade.BATCH - realm.wheat_consumed:
			push_error("Balanço físico do trigo da capital divergente no dia %d." % (day + 1))
			failed = true
		if wheat < 0 or wheat > RealmWorld.LIMITS.wheat or realm.purse < 0 or trade.purse < 0 or realm.treasury < 0 or career.life.market_cash < 0:
			failed = true
		print("Dia %02d | Vale trigo=%d alimentos=%d | Entreposto trigo=%d caixa=%d | Capital trigo=%d consumo=%d entregas=%d caixa=%d tesouro=%d população=%d casas=%d obra=%s rota=%s tarifa=%d preço=%d pedidos=%d salários=%d" %
			[day + 1, village.amount("market", "trigo"), village.amount("market", "alimentos"), trade.stock.wheat, trade.purse,
			wheat, realm.wheat_consumed, realm.deliveries, realm.purse, realm.treasury, realm.population, realm.houses,
			realm.project.get("id", "—"), realm.route(), realm.tariff(day), realm.price("wheat"),
			game.markets.contracts.size(), game.society.shops.trade.wages])
		if day % 10 == 0:
			game._save()
			if not game._load(true) or realm.stock.wheat != wheat:
				failed = true
	print("Caixas de abastecimento | inicial=%d final=%d (inclui transferências com outros caixas)" % [starting_money, realm.purse + realm.treasury + trade.purse + career.life.market_cash])
	print("Abastecimento | dias=%d mínimo=%d zerados=%d recuperação=%s entregas=%d final=%d" %
		[days, lowest, days_empty, recovery, realm.deliveries, realm.stock.wheat])
	print("Estrada | bloqueio=%s reabertura=%s" % [saw_block, saw_reopen])
	print("Cadeia serrana | tesouro mínimo=%d final=%d suporte interno=%d madeira exportada=%d enxadas forjadas=%d ferramentas gastas=%d" %
		[lowest_treasury, realm.treasury, realm.market_support, realm.wood_exports, realm.tools_made, game.markets.tools_retired])
	if realm.deliveries < 2 or realm.stock.wheat == 0 or (days >= 60 and not saw_reopen):
		failed = true
	if days >= 192 and (lowest_treasury <= 0 or realm.wood_exports < 3 or realm.tools_made < 1 or game.markets.tools_retired < 1):
		failed = true
	for suffix in ["", ".previous"]:
		DirAccess.remove_absolute(game.save_path + suffix)
	quit(1 if failed else 0)
