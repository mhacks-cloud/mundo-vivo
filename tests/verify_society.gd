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
	career.confirm_character("Eva do Vale", "farmer", "amieiro", 0, 0)
	career.confirm_plot("sul-01")
	var town: TownSociety = vale.society
	var clock: WorldClock = vale.simulation.clock
	var stock: VillageInventory = vale.simulation.economy.stock
	var old: Dictionary = vale.saves.read_state(vale.save_path)
	old.erase("society")
	vale.saves.write_state(old, vale.save_path)
	check(vale._load(true) and town.families.oficina.members.size() == 2, "migração inicializa lares estáveis")
	var wage: int = town.people.baltasar.cash
	var employer: int = town.shops.forge.cash
	var plan: Dictionary = vale.residents.plans[3]
	plan.pending = true
	plan.wait = 0.0
	vale.residents._work_at_stop(plan)
	check(town.people.baltasar.cash == wage + 3 and town.shops.forge.cash == employer - 3
		and not town.work("baltasar", clock.total_day()), "trabalho paga salário único do caixa da ferraria")
	var food := stock.amount("market", "alimentos")
	var shop_cash: int = town.shops.trade.cash
	check(vale.residents._buy_food(plan) and stock.amount("market", "alimentos") == food - 1
		and town.people.baltasar.cash == wage + 1 and town.shops.trade.cash == shop_cash + 1, "refeição debita morador e credita banca e imposto")
	vale._save()
	vale._load(true)
	check(town.people.baltasar.cash == wage + 1 and town.shops.forge.cash == employer - 3, "carteiras e caixas sobrevivem à recarga")
	var econ: EconomyManager = vale.markets
	var life := career.life
	vale.player.position = ValeLife.STATIONS.contracts
	check(career.perform("economy_accept", "harvest").begins_with("Pagamento"), "pedido recorrente reserva o primeiro ciclo")
	life.bag.add("wheat", 4)
	career.perform("economy_deliver", "harvest")
	check(not econ.available("harvest", 2) and econ.available("harvest", 3) and town.civic_reputation.vale == 1,
		"prazo de reposição e reputação civil derivam da entrega")
	var realm: RealmWorld = vale.realms.world
	realm.stock.iron = 19
	career.frontier.stock.iron = 5
	var purse: int = career.frontier.purse
	check(realm.reserve_iron(career.frontier, clock) and realm.stock.iron == 16 and career.frontier.purse < purse,
		"ferro vendido sai da capital e reserva percurso inverso")
	realm.restore(realm.snapshot())
	for i in 1000:
		realm.advance(clock, career.frontier, 0.10)
		if realm.shipment.is_empty():
			break
	check(realm.shipment.is_empty() and career.frontier.stock.iron == 8, "ferro chega ao entreposto uma vez após recarga")
	realm.houses = 1
	realm.entrepreneur_cash = 20
	var wood: int = realm.stock.wood
	check(realm.propose("workshop", "Tomás").begins_with("Aprovada") and realm.entrepreneur_cash == 2 and realm.stock.wood == wood - 2,
		"oficina financia licença com poupança e reserva materiais")
	check(not realm.workshop, "oficina aguarda obra física")
	for i in 1500:
		realm.work(clock, 0.1)
		if realm.workshop and realm.stock.hoe > 0:
			break
	check(realm.workshop and realm.stock.hoe == 1 and realm.entrepreneur_cash == 6, "obra abre oficina e ferramenta produzida entra no mercado")
	realm.restore(realm.snapshot())
	check(realm.workshop and realm.stock.hoe == 1, "empreendimento e estoque persistem")
	clock.elapsed += 10.0 * WorldClock.DAY_SECONDS
	town.advance(vale)
	var before := life.bag.amount("food")
	check(town.fair_open(clock) and town.buy_fair(life, clock) and life.bag.amount("food") == before + 1
		and not town.news.is_empty(), "feira compra de estoque real e publica notícia")
	for suffix in ["", ".previous", ".pre-4.1.bak"]:
		DirAccess.remove_absolute(vale.save_path + suffix)
	print("%d verificações de sociedade, %d falhas." % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("OK " if ok else "FALHA ") + label)
