extends SceneTree

var checks := 0
var failed := 0
var save_path := "user://verify_player_life_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_rules()
	var vale := _spawn()
	await _frames(5)
	var career: ValeLife = vale.career
	_check(career.setup_stage == "creator" and career.ui.form_preview.texture != null, "criação abre com a prévia do sprite")
	var creator := career.ui
	creator.form_name.text = "Eliana do Vale"
	creator.form_class.select(LifeCatalog.CLASSES.keys().find("farmer"))
	creator.form_coat.select(2)
	creator.confirm_button.pressed.emit()
	_check(career.setup_stage == "plot" and career.life.role() == "farmer" and not career.plot_focus.is_empty(),
		"botão confirma classe e abre escolha de terreno")
	career.ui.confirm_button.pressed.emit()
	var life := career.life
	var plot := life.estate.owned(PlayerLife.ID)
	_check(career.setup_stage.is_empty() and plot == "sul-01" and vale.saves.read_state(save_path).has("career"),
		"confirmação do lote entra no mundo e cria o salvamento")
	var x_before: float = vale.player.position.x
	Input.action_press("right")
	await _frames(20)
	Input.action_release("right")
	_check(vale.player.position.x > x_before + 0.5 and vale.camera.current and vale.people.size() == 9,
		"movimento, câmera e moradores permanecem ativos após criar")
	_press(vale, KEY_B)
	_check(career.ui.page == "inventory" and career.ui.panel.visible, "B abre o inventário")
	_press(vale, KEY_ESCAPE)
	vale.player.position = Homestead.center(plot, Vector2i(0, 0)) + Vector3.UP * 0.07
	career.start_build("garden")
	var cell := Vector2i(0, 2)
	var wood := life.bag.amount("wood")
	_check(career.place_piece(plot, cell).is_empty() and life.bag.amount("wood") == wood - 1,
		"construção pelo controlador consome exatamente uma madeira")
	career.cancel_build()
	_check(career.perform("plant", "0:2:seed") == "Concluído." and career.perform("plant", "0:2:water") == "Concluído.",
		"plantio e irrigação funcionam pelo controlador")
	_check(career.perform("plant", "0:2:harvest") != "Concluído.", "cultivo exige maturação")
	vale.simulation.tick(30.0)
	_check(career.perform("plant", "0:2:harvest") == "Concluído." and life.bag.amount("wheat") == 4 and life.xp > 0,
		"atividade completa rende trigo e experiência")
	_check(career.perform("starter", "") == "Casa inicial montada." and life.estate.pieces.size() == 21,
		"casa inicial cria 20 módulos e preserva o canteiro")
	await _frames(4)
	var space: PhysicsDirectSpaceState3D = vale.get_world_3d().direct_space_state
	var north := Homestead.center(plot, Vector2i(1, 1)) + Vector3.UP * 0.73
	var south := Homestead.center(plot, Vector2i(1, 2)) + Vector3.UP * 0.73
	var wall_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(north + Vector3.FORWARD * 1.25, north, 1))
	var door_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(south + Vector3.BACK * 1.25, south, 1))
	_check(not wall_hit.is_empty() and door_hit.is_empty(), "parede tem colisão e vão da porta é atravessável")
	_check(career.perform("store", "stone") == "Concluído." and life.chest.amount("stone") == 1,
		"baú recebe item sem duplicar")
	career.perform("plant", "0:2:herb_seed")
	var estate := life.estate.snapshot()
	var where: Vector3 = vale.player.position
	var gold := life.gold
	var xp := life.xp
	var original_condition: int = life.bag.condition["hoe"]
	vale._save()
	root.remove_child(vale)
	vale.free()
	var reopened := _spawn()
	await _frames(4)
	var resume: ValeLife = reopened.career
	_check(resume.setup_stage.is_empty() and resume.life.profile.name == "Eliana do Vale"
		and resume.life.role() == "farmer" and resume.life.profile.nation == "amieiro" and reopened.player.position.is_equal_approx(where),
		"reabertura restaura identidade, classe, nação e posição")
	_check(resume.life.estate.snapshot() == estate and resume.life.plants.has("0:2")
		and resume.life.chest.amount("stone") == 1 and resume.life.bag.condition.hoe == original_condition,
		"reabertura mantém casa, cultivo, baú e durabilidade")
	_check(resume.life.gold == gold and resume.life.xp == xp and not resume.life.claim("sul-02"),
		"ouro, XP e exclusividade persistem")
	resume.game.player.position = ValeLife.STATIONS.store
	var previous_food := resume.life.bag.amount("food")
	_check(resume.perform("buy", "food") == "Concluído." and resume.life.bag.amount("food") == previous_food + 1,
		"compra ocorre junto à banca")
	resume.game.player.position = Vector3.ZERO
	_check(resume.perform("buy", "food") != "Concluído.", "banca valida proximidade")
	resume.game.player.position = ValeLife.STATIONS.contracts
	var market_wheat: int = reopened.simulation.economy.stock.amount("market", "trigo")
	_check(resume.perform("contract", "provision") == "Concluído."
		and reopened.simulation.economy.stock.amount("market", "trigo") == market_wheat + 3
		and resume.perform("contract", "provision") != "Concluído.", "contrato entrega ao estoque da vila uma única vez")
	root.remove_child(reopened)
	reopened.free()
	DirAccess.remove_absolute(save_path)
	var legacy := FileAccess.open(save_path, FileAccess.WRITE)
	legacy.store_string('{"version":2,"state":{"elapsed":4800,"bridge":{"stage":3,"delivered":0},"player":[1,0.1,2],"economy":{"stocks":{"farm":{"trigo":7}}}}}')
	legacy.close()
	var migrated := _spawn()
	var migrated_career: ValeLife = migrated.career
	_check(migrated_career.setup_stage == "creator" and migrated.simulation.construction.complete()
		and migrated.simulation.economy.stock.amount("farm", "trigo") == 7,
		"legado abre o cadastro sem perder a ponte nem o estoque")
	migrated_career.confirm_character("Lauro do Vale", "mage", "amieiro", 0, 0)
	migrated_career.confirm_plot("sul-02")
	_check(FileAccess.file_exists(save_path + ".pre-4.bak") and migrated.simulation.construction.complete()
		and migrated_career.life.role() == "mage", "migração grava backup legado antes do novo esquema")
	migrated.player.position = Vector3(22.18, 0.10, 4.58)
	_press(migrated, KEY_F)
	_check(migrated_career.projectiles.size() == 1 and migrated_career.training.health[1] == 48.0,
		"disparo cria projétil antes de acertar o alvo")
	migrated._save()
	migrated._load(true)
	_check(migrated_career.projectiles.size() == 1 and migrated_career.life.cooldown > 0.0,
		"salvamento retoma projétil em voo e intervalo da técnica")
	await _frames(22)
	_check(migrated_career.projectiles.is_empty() and migrated_career.training.health[1] < 48.0,
		"projétil voa e acerta no campo de treino")
	root.remove_child(migrated)
	migrated.free()
	DirAccess.remove_absolute(save_path)
	DirAccess.remove_absolute(save_path + ".pre-4.bak")
	print("%d verificações do RPG, %d falhas." % [checks, failed])
	quit(1 if failed else 0)

func _rules() -> void:
	var person := PlayerLife.new()
	_check(not person.create("X1", "smith", "amieiro", 0, 0) and not person.create("Élan", "smith", "salmar", 0, 0),
		"nome inválido e nação futura são rejeitados")
	_check(person.create("Élan", "smith", "amieiro", 0, 0)
		and not person.create("Élan", "mage", "amieiro", 0, 0) and person.role() == "smith",
		"classe permanente após confirmação")
	_check(person.claim("sul-01") and not person.estate.claim("sul-01", "outro") and not person.claim("sul-02"),
		"terreno exclusivo e um lote inicial por personagem")
	var initial := person.bag.amount("stone")
	_check(not person.estate.install(PlayerLife.ID, "sul-01", "foundation", Vector2i(-1, 0), 0, person.bag).is_empty()
		and person.bag.amount("stone") == initial, "construção fora dos limites não gasta recursos")
	_check(person.estate.install(PlayerLife.ID, "sul-01", "foundation", Vector2i(1, 1), 0, person.bag).is_empty()
		and person.bag.amount("stone") == initial - 1, "fundação deduz pedra ao instalar")
	_check(person.estate.install(PlayerLife.ID, "sul-01", "wall", Vector2i(1, 1), 1, person.bag).is_empty()
		and not person.estate.check(PlayerLife.ID, "sul-01", "window", Vector2i(2, 1), 3).is_empty(),
		"bordas compartilhadas não se sobrepõem")
	_check(not person.bag.add("stone", -1) and not person.bag.add("stone", 999) and not person.bag.spend({"stone": -1}),
		"inventário rejeita peso excessivo e quantidades negativas")
	var durability: int = person.bag.condition.hammer
	_check(person.craft("sword", "forge") and person.bag.condition.hammer == durability - 1
		and person.bag.amount("sword") == 1 and not person.equip("sword"), "forja produz, desgasta ferramenta e respeita classe ao equipar")
	_check(not person.craft("health", "forge") and person.repair("hammer", true)
		and person.bag.condition.hammer == durability, "receitas exclusivas e reparo por ofício")
	var before_xp := person.xp
	_check(not person.repair("hammer", true) and person.xp == before_xp, "repetição sem resultado não concede XP")
	var bank := VillageInventory.new()
	var cash := person.gold
	_check(person.buy("herb", 1) and person.sell("herb", 1, bank) and person.gold < cash, "comprar e revender não cria ouro")
	var artisan := PlayerLife.new()
	artisan.create("Iria", "artisan", "amieiro", 0, 1)
	_check(artisan.craft("chair", "carpentry") and artisan.craft("joinery", "carpentry")
		and not artisan.craft("sword", "forge"), "artesão produz móveis e componentes")
	var doctor := PlayerLife.new()
	doctor.create("Aurélia", "doctor", "amieiro", 0, 1)
	_check(doctor.craft("health", "alchemy") and doctor.craft("mana", "alchemy") and not doctor.use_item("health"),
		"médico produz remédio e mana, sem consumo inútil")
	doctor.hp = 39.0
	_check(doctor.use_item("health") and doctor.hp > 39.0 and doctor.bag.amount("health") == 0, "consumível restaura vida uma vez")
	for role in ["warrior", "archer", "mage", "healer"]:
		var adventurer := PlayerLife.new()
		adventurer.create("Ariel", role, "amieiro", 0, 0)
		var session := TrainingSession.new()
		var target := 2 if role == "healer" else 1 if role == "archer" else 0
		var mana := adventurer.mana
		var arrows := adventurer.bag.amount("arrow")
		for i in 3:
			adventurer.cooldown = 0
			var result := session.begin(adventurer, target)
			if not result.is_empty():
				session.apply(adventurer, target, result.amount)
		_check(adventurer.xp == 24 and not session.available(target), "%s conclui exercício e recebe XP uma vez" % role)
		if role in ["mage", "healer"]:
			_check(adventurer.mana < mana, "%s consome mana" % role)
		if role == "archer":
			_check(adventurer.bag.amount("arrow") == arrows - 3, "arco consome munição")
	var guard := PlayerLife.new()
	guard.create("Guilherme", "warrior", "amieiro", 0, 0)
	var field := TrainingSession.new()
	field.tick(guard, TrainingSession.SPOTS[0], true, 1.1)
	var defended := guard.max_hp() - guard.hp
	field.tick(guard, TrainingSession.SPOTS[0], false, 3.0)
	_check(defended < (guard.max_hp() - guard.hp - defended) and guard.bag.condition.armor < 36, "defesa reduz dano e armadura se desgasta")

func _spawn() -> Node:
	var vale := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	vale.save_path = save_path
	root.add_child(vale)
	return vale

func _frames(count: int) -> void:
	for i in count:
		await physics_frame

func _press(vale: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = key
	vale._unhandled_input(event)

func _check(result: bool, label: String) -> void:
	checks += 1
	if result:
		print("OK ", label)
	else:
		failed += 1
		push_error("FALHA: " + label)
