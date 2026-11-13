extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	root.add_child(game)
	var career: ValeLife = game.career
	career.new_game()
	career.confirm_character("Rosa do Pouso", "farmer", "amieiro", 0, 0)
	career.confirm_plot("sul-01")
	var world: RealmWorld = game.realms.world
	var town: TownSociety = game.society
	var clock: WorldClock = game.simulation.clock
	var trade := career.frontier
	world.houses = 1
	world.population = 7
	world.workshop = true
	world.entrepreneur_cash = 34
	world.stock.wheat = 15
	world.stock.hoe = 2
	trade.stock.iron = 5
	var stock: VillageInventory = game.simulation.economy.stock
	var seen_travel := false
	var seen_works := false
	var seen_tool := false
	var seen_fair := false
	var maximum_population := world.population
	for day in 30:
		clock.elapsed = day * WorldClock.DAY_SECONDS + 9.0 * WorldClock.DAY_SECONDS / 24.0
		for step in 180:
			clock.advance(1)
			town.advance(game)
			world.advance(clock, trade, 1.0)
			world.work(clock, 1.0)
			seen_travel = seen_travel or town.migration == 4
			seen_works = seen_works or world.project.get("id") == "district"
			seen_tool = seen_tool or trade.stock.hoe > 0
		seen_fair = seen_fair or town.fair_open(clock)
		maximum_population = maxi(maximum_population, world.population)
		check(world.population <= 8 and world.houses <= 2 and world.treasury >= 0 and world.purse >= 0 and trade.purse >= 0
			and world.stock.values().all(func(v: Variant) -> bool: return v >= 0)
			and town.people.values().all(func(v: Dictionary) -> bool: return v.cash >= 0)
			and career.authority.justice.case_file.is_empty(), "limites e justiça · dia %d" % (day + 1))
		print("Dia %02d | pop=%d casas=%d emprego=%s trigo=%d ferro=%d ferramentas=%d caixa=%d feira=%s" %
			[day + 1, world.population, world.houses, TownSociety.MIGRATION[town.migration], world.stock.wheat,
			world.stock.iron, trade.stock.hoe, world.purse, town.fair_open(clock)])
		if day % 5 == 0:
			game._save()
			check(game._load(true), "recarga periódica · dia %d" % (day + 1))
	check(seen_works and seen_travel and town.migration == 6 and maximum_population == 8 and world.houses == 2,
		"vaga, obra, viagem e ocupação alteram a população uma vez")
	check(seen_tool and seen_fair, "ferramenta transportada e feira aberta durante a simulação")
	var frontier_iron: int = trade.stock.iron
	var frontier_wood: int = trade.stock.wood
	var frontier_tools: int = trade.stock.hoe
	var cash_total := trade.treasury + trade.purse
	var imported := RealmWorld.new()
	imported.imported_iron = 3
	trade.stock.hoe = 0
	check(imported.forge_import(trade, 30) and not imported.forge_import(trade, 30)
		and trade.stock.iron == frontier_iron - 1 and trade.stock.wood == frontier_wood - 2
		and trade.stock.hoe == 1 and trade.treasury + trade.purse == cash_total,
		"ferraria consome ferro e madeira, conserva ouro e produz uma vez por dia")
	trade.stock.hoe = frontier_tools
	check(stock.amount("market", "alimentos") >= 0 and town.news.size() <= 24, "estoque da feira e notícias limitados")
	for suffix in ["", ".previous", ".pre-4.1.bak"]:
		DirAccess.remove_absolute(game.save_path + suffix)
	print("%d verificações de civilização, %d falhas." % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("OK " if ok else "FALHA ") + label)
