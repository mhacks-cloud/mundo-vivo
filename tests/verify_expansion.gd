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
