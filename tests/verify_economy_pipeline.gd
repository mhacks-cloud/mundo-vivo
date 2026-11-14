extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var clock := WorldClock.new()
	clock.elapsed = WorldClock.DAY_SECONDS * 0.4
	var trade := FrontierTrade.new()
	var world := RealmWorld.new()
	world.stock.wheat = 0
	world.purse = 0
	world.treasury = 100
	trade.stock.wheat = 3
	var total := world.purse + world.treasury + trade.purse
	check(world.reserve(trade, clock) and world.market_support > 0 and world.treasury > 0,
		"intendência transfere verba existente ao mercado para comprar trigo")
	check(world.purse + world.treasury + trade.purse == total and world.shipment.item == "wheat",
		"compra conserva ouro e reserva carga física")
	var copy := RealmWorld.new()
	copy.restore(world.snapshot())
	check(copy.shipment.item == "wheat" and copy.market_support == world.market_support,
		"carga e transferência sobrevivem à recarga")
	world = RealmWorld.new()
	trade = FrontierTrade.new()
	trade.stock.wood = 0
	world.stock.wood = 12
	check(world.reserve_wood(trade, clock) and world.shipment.item == "wood",
		"serraria separa madeira para o entreposto")
	copy.restore(world.snapshot())
	check(copy.shipment.item == "wood", "frete de madeira sobrevive à recarga")
	for step in 220:
		clock.advance(1)
		world.advance(clock, trade, 1.0)
		if world.shipment.is_empty():
			break
	check(world.shipment.is_empty() and trade.stock.wood == 3 and world.wood_exports == 3,
		"carroça entrega madeira física no entreposto")
	world.imported_iron = 1
	trade.stock.iron = 1
	check(world.forge_import(trade, clock.total_day()) and trade.stock.hoe == 1 and trade.stock.wood == 1,
		"ferraria consome ferro importado e madeira transportada")
	var game := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	root.add_child(game)
	game.career.frontier.stock.hoe = 1
	var buyer_cash: int = game.career.life.market_cash
	check(game.markets._buy_frontier_tools(game) and game.simulation.economy.stock.amount("depot", "ferramentas") == 3
		and game.career.life.market_cash == buyer_cash - 4 and game.career.frontier.purse == 124,
		"depósito compra ferramenta do entreposto com caixa real")
	print("%d verificações da cadeia produtiva, %d falhas." % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("OK " if ok else "FALHA ") + label)
