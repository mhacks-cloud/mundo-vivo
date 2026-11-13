extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	root.add_child(game)
	var career: ValeLife = game.career
	career.ui.settings()
	check(career.ui.page == "settings", "configurações acessíveis antes de criar personagem")
	game.preferences.sensitivity = 1.5
	game.preferences.quality = 0
	game.apply_preferences()
	game.preferences.sensitivity = 1.0
	game._load_preferences()
	check(game.quality == 0 and game.preferences.sensitivity == 1.5, "preferências persistem fora da campanha")
	career.start_menu()
	career.new_game()
	check(career.confirm_character("Eva do Amieiro", "farmer", "amieiro", 0, 0).is_empty()
		and career.confirm_plot("sul-01").is_empty(), "nova agricultora registra seu terreno")
	check(game.player.profession == "farmer", "traje em jogo acompanha a classe mesmo com cores iniciais")
	var preview := career.preview_actor(0, 0, "farmer").get_image()
	var other := career.preview_actor(0, 0, "smith").get_image()
	check(preview.get_size() == Vector2i(32, 40) and preview.get_data() != other.get_data(), "prévia mantém escala pixel art e diferencia classes")
	var life := career.life
	var at := Homestead.center("sul-01", Vector2i(0, 0))
	game.player.position = at
	career.start_build("garden")
	check(career.place_piece("sul-01", Vector2i(0, 0)).is_empty(), "primeiro canteiro instalado")
	check(career.perform("campaign_claim", "home") == "Marco registrado.", "construção libera marco pacífico")
	var clock: WorldClock = game.simulation.clock
	var cell := Vector2i(0, 0)
	check(life.farm(cell, "seed", clock.elapsed, false, 18.0)
		and life.farm(cell, "water", clock.elapsed)
		and life.farm(cell, "harvest", clock.elapsed + 100.0), "plantio, irrigação e colheita produzem trigo")
	game.player.position = ValeLife.STATIONS.contracts
	check(career.perform("contract", "provision") == "Concluído."
		and career.perform("campaign_claim", "market") == "Marco registrado.", "colheita abastece contrato do Vale")
	game.player.position = GuildLedger.HALL
	check(career.perform("join_guild", "") == "Concluído."
		and career.perform("campaign_claim", "guild") == "Marco registrado.", "filiação libera marco da guilda")
	game.player.position = ValeLife.FISHING
	var seed := life.bag.amount("seed")
	var fish := life.bag.amount("fish")
	game.interactions.interact(game.player.position)
	check(life.bag.amount("fish") == fish + 1 and life.bag.amount("seed") == seed - 1, "pesca consome isca e produz item real")
	game.player.position = RealmWorld.ROAD_ENTRY
	game.realms.travel(true)
	check(game.realms.world.active and career.perform("campaign_claim", "journey") == "Marco registrado.",
		"travessia descobre a capital e libera exploração")
	life.hp = life.max_hp() - 20
	check(life.use_item("fish") and life.bag.amount("fish") == fish, "peixe pode ser consumido para recuperar vida")
	var xp := life.xp
	game._save()
	game._load(true)
	check(life.xp == xp and life.bag.amount("fish") == fish and game.realms.world.active,
		"recarga preserva personagem, região e progresso")
	check(career.perform("campaign_claim", "journey") != "Marco registrado." and life.xp == xp,
		"recompensa de campanha é única após recarga")
	check(life.role() == "farmer" and life.estate.pieces.size() == 1, "campanha pode continuar com profissão e propriedade")
	for suffix in ["", ".previous"]:
		DirAccess.remove_absolute(game.save_path + suffix)
	DirAccess.remove_absolute("user://preferences.cfg")
	print("%d verificações de campanha, %d falhas." % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("OK " if ok else "FALHA ") + label)
