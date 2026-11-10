class_name ValeLife
extends Node

const STATIONS := {
	"store": Vector3(-7.12, 0.1, -0.15), "forge": Vector3(-11.1, 0.1, 5.25),
	"alchemy": Vector3(-5.63, 0.1, -4.19), "carpentry": Vector3(-2.85, 0.1, -3.75),
	"contracts": Vector3(3.8, 0.1, -3.72), "coop": Vector3(-9.44, 0.1, 8.35)
}
const GATHER := {"wood": Vector3(-13.9, 0.1, -4.90), "herb": Vector3(-4.7, 0.1, 8.7),
	"stone": Vector3(20.2, 0.1, -13.80), "iron": Vector3(22.0, 0.1, -17.0)}
var life := PlayerLife.new()
var training := TrainingSession.new()
var housing := ValeHousing.new()
var ui := ValeLifeUI.new()
var game: Node3D
var setup_stage := ""
var plot_focus := ""
var build_kind := ""
var build_dir := 0
var build_cell := Vector2i(-1, -1)
var build_reason := ""
var target_models: Array[Node3D] = []
var target_labels: Array[Label3D] = []
var projectiles: Array[Dictionary] = []
var default_appearance := Vector2i(-1, -1)
var view_timer := 0.0

func setup(scene: Node3D) -> void:
	game = scene
	game.diorama.add_child(housing)
	housing.setup(life, game.diorama.palette)
	life.estate.changed.connect(func() -> void: game.nav_dirty = true)
	add_child(ui)
	ui.setup(self)
	_create_training()
	_register()
	default_appearance = Vector2i.ZERO

func start_setup() -> void:
	if life.profile.is_empty():
		setup_stage = "creator"
		ui.creator()
	elif life.estate.owned(PlayerLife.ID).is_empty():
		setup_stage = "plot"
		ui.plots()
	ui.update_status()

func confirm_character(name_value: String, profession: String, nation: String, coat: int, hair: int) -> String:
	if setup_stage != "creator" or not life.create(name_value, profession, nation, coat, hair):
		return "Use 3–22 caracteres, com letras, espaços, apóstrofo ou hífen. Escolha uma nação disponível."
	_apply_appearance()
	setup_stage = "plot"
	ui.plots()
	return ""

func confirm_plot(plot: String) -> String:
	if setup_stage != "plot" or not life.claim(plot):
		return "O lote está ocupado ou falta ouro."
	setup_stage = ""
	plot_focus = ""
	housing.select_plot("")
	ui.hide_panel()
	ui.update_status()
	game._save()
	game.hud.show_message("Terreno registrado. H abre a construção na zona residencial ao sul.")
	return ""

func show_plot(plot: String) -> void:
	if Homestead.PLOTS.has(plot):
		plot_focus = plot
		housing.select_plot(plot)

func camera_point(fallback: Vector3) -> Vector3:
	if setup_stage == "plot" and not plot_focus.is_empty():
		return Homestead.center(plot_focus, Vector2i(2, 2)) + Vector3.UP * 0.50
	return fallback

func preview_actor(coat: int, hair: int) -> Texture2D:
	return game.player.preview_texture(Color(LifeCatalog.COLORS[coat]), Color(LifeCatalog.HAIR[hair]))

func _apply_appearance() -> void:
	if life.profile.is_empty():
		if default_appearance != Vector2i(0, 0):
			game.player.appearance(Color(LifeCatalog.COLORS[0]), Color(LifeCatalog.HAIR[0]))
			default_appearance = Vector2i.ZERO
		return
	var selected := Vector2i(life.profile.coat, life.profile.hair)
	if selected != default_appearance:
		game.player.appearance(Color(LifeCatalog.COLORS[selected.x]), Color(LifeCatalog.HAIR[selected.y]))
		default_appearance = selected

func active() -> bool:
	return not life.profile.is_empty()

func snapshot() -> Dictionary:
	var shots: Array[Dictionary] = []
	for shot in projectiles:
		var p: Vector3 = shot.node.position
		shots.append({"at": [p.x, p.y, p.z], "target": shot.target, "amount": shot.amount})
	return {"life": life.snapshot(), "training": training.snapshot(), "shots": shots}

func restore(data: Variant) -> void:
	life.restore(data.get("life") if data is Dictionary else null)
	training.restore(data.get("training") if data is Dictionary else null)
	for shot in projectiles:
		shot.node.queue_free()
	projectiles.clear()
	if data is Dictionary and data.get("shots") is Array and life.role() in ["archer", "mage"]:
		for shot in data.shots.slice(0, 8):
			if not shot is Dictionary or not shot.get("at") is Array or shot.at.size() != 3:
				continue
			var target := int(LifeCatalog.number(shot.get("target"), -1, -1, 2))
			var amount := 18.0 if life.role() == "archer" else 27.0
			if target < 0 or target > 1 or shot.get("amount") != amount:
				continue
			var p := Vector3(LifeCatalog.number(shot.at[0], -100, -75, 75),
				LifeCatalog.number(shot.at[1], -100, -5, 12), LifeCatalog.number(shot.at[2], -100, -75, 75))
			if p.distance_squared_to(TrainingSession.SPOTS[target]) < 13.0 * 13.0:
				_launch(target, p, amount)
	_apply_appearance()
	cancel_build()
	ui.update_status()

func tick(delta: float) -> void:
	view_timer += delta
	if view_timer >= 0.15:
		view_timer = 0.0
		ui.update_status()
		housing.update_view(game.player.position, game.simulation.clock.elapsed)
		for i in target_models.size():
			target_labels[i].text = "%s · %d PV" % [TrainingSession.TARGET_NAMES[i], ceili(training.health[i])] if training.available(i) else "Exercício concluído"
			target_models[i].scale.y = 1.0 if training.available(i) else 0.75
	if build_kind.is_empty():
		return
	var plot := life.estate.owned(PlayerLife.ID)
	if plot.is_empty():
		cancel_build()
		return
	var camera := game.camera as Camera3D
	var mouse := camera.get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var ray := camera.project_ray_normal(mouse)
	var ground_hit: Variant = Plane(Vector3.UP, 0.03).intersects_ray(origin, ray)
	build_cell = Homestead.cell_at(plot, ground_hit) if ground_hit is Vector3 else Vector2i(-1, -1)
	build_reason = _placement(plot, build_cell)
	housing.preview(plot, build_kind, build_cell, build_dir, build_reason.is_empty())
	var action := "Clique para confirmar · Z gira · Esc cancela" if build_reason.is_empty() else build_reason
	ui.build_hint("%s  /  %d°\n%s" % [Homestead.PIECES[build_kind].name, build_dir * 90, action])

func physics(delta: float) -> void:
	if not active():
		return
	var player := game.player as PixelActor
	var player_pos := player.position
	training.tick(life, player_pos, Input.is_physical_key_pressed(KEY_SHIFT), delta)
	if life.hp <= 0.0:
		player.position = Vector3(0.85, 0.10, 4.28)
		life.hp = life.max_hp() * 0.65
		life.mana = life.max_mana() * 0.55
		life.logbook("O treino terminou. Você se recuperou junto à praça.")
		game.hud.show_message("Você se recuperou na praça.")
	if game.raining:
		life.rain(game.simulation.clock.elapsed)
	var space := game.get_world_3d().direct_space_state
	for i in range(projectiles.size() - 1, -1, -1):
		var shot := projectiles[i]
		var mesh: Node3D = shot.node
		var direction: Vector3 = shot.destination - mesh.position
		var next := mesh.position + direction.limit_length(delta * 17.0)
		var blocked := not space.intersect_ray(PhysicsRayQueryParameters3D.create(mesh.position, next, 1)).is_empty()
		if blocked or direction.length() <= delta * 17.0:
			if not blocked:
				training.apply(life, shot.target, shot.amount)
			mesh.queue_free()
			projectiles.remove_at(i)
		else:
			mesh.position = next

func input_event(event: InputEvent) -> bool:
	if not setup_stage.is_empty():
		return true
	if not active():
		return false
	if event.is_action_pressed("ui_cancel"):
		if not build_kind.is_empty():
			cancel_build()
			return true
		if ui.panel.visible:
			ui.hide_panel()
			return true
	if not build_kind.is_empty():
		if _key(event, KEY_Z):
			build_dir = (build_dir + 1) % 4
			return true
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var plot := life.estate.owned(PlayerLife.ID)
			var camera := game.camera as Camera3D
			var point: Variant = Plane(Vector3.UP, 0.03).intersects_ray(camera.project_ray_origin(event.position), camera.project_ray_normal(event.position))
			var cell := Homestead.cell_at(plot, point) if point is Vector3 else Vector2i(-1, -1)
			var reason := place_piece(plot, cell)
			if not reason.is_empty():
				game.hud.show_message(reason)
			return true
	if _key(event, KEY_B):
		_toggle("inventory")
	elif _key(event, KEY_C):
		_toggle("character")
	elif _key(event, KEY_H):
		_toggle("build")
	elif _key(event, KEY_M):
		_toggle("contracts")
	elif _key(event, KEY_F):
		_attack()
	else:
		return false
	return true

func _toggle(page: String) -> void:
	if ui.panel.visible and ui.page == page:
		ui.hide_panel()
	else:
		cancel_build()
		ui.open(page)

func start_build(kind: String) -> void:
	if not Homestead.PIECES.has(kind) or not _near_plot():
		ui.feedback.text = "Aproxime-se do seu lote na zona residencial ao sul."
		return
	build_kind = kind
	build_dir = 0
	ui.hide_panel()

func cancel_build() -> void:
	build_kind = ""
	housing.hide_preview()
	ui.build_hint("")

func place_piece(plot: String, cell: Vector2i) -> String:
	if build_kind.is_empty():
		return "Selecione uma peça."
	var reason := _placement(plot, cell)
	if not reason.is_empty():
		return reason
	return life.estate.install(PlayerLife.ID, plot, build_kind, cell, build_dir, life.bag)

func _placement(plot: String, cell: Vector2i) -> String:
	if not _near_plot():
		return "Aproxime-se do seu terreno."
	var reason := life.estate.check(PlayerLife.ID, plot, build_kind, cell, build_dir)
	if not reason.is_empty():
		return reason
	if not life.bag.has(Homestead.PIECES[build_kind].cost):
		return "Materiais insuficientes."
	var center := Homestead.center(plot, cell)
	if Homestead.PIECES[build_kind].layer == "edge":
		var direction: Vector2i = Homestead.DIRECTIONS[build_dir]
		center += Vector3(direction.x, 0, direction.y) * Homestead.CELL * 0.5
		var offset: Vector3 = game.player.position - center
		var perpendicular := absf(offset.x) if build_dir % 2 else absf(offset.z)
		var along := absf(offset.z) if build_dir % 2 else absf(offset.x)
		if perpendicular < 0.48 and along < 1.0:
			return "Saia do encaixe antes de instalar a peça."
	elif build_kind == "chair" and center.distance_squared_to(game.player.position) < 0.8 * 0.8:
		return "Afaste-se antes de instalar a mobília."
	return ""

func _near_plot() -> bool:
	var plot := life.estate.owned(PlayerLife.ID)
	return not plot.is_empty() and game.player.position.distance_squared_to(Homestead.center(plot, Vector2i(2, 2))) <= 8.2 * 8.2

func _near_station(station: String) -> bool:
	return STATIONS.has(station) and game.player.position.distance_squared_to(STATIONS[station]) <= 2.55 * 2.55

func _open_store() -> bool:
	var hour: float = game.simulation.clock.hour()
	return _near_station("store") and hour >= 7.0 and hour < 19.0

func open_near(page: String) -> void:
	if not active():
		return
	if (page in ["chest", "farm"] and _near_plot()) or _near_station(page):
		cancel_build()
		ui.open(page)
	else:
		game.hud.show_message("Aproxime-se do terreno ou da bancada correspondente.")

func perform(verb: String, id: String) -> String:
	if not active():
		return "Registre seu personagem."
	var success := false
	match verb:
		"use": success = life.use_item(id) or life.equip(id)
		"unequip": success = life.unequip(id)
		"discard": success = life.discard(id, 1)
		"store", "take": success = _near_plot() and life.transfer(id, 1, verb == "store")
		"buy": success = _open_store() and life.buy(id, 1)
		"sell": success = _open_store() and life.sell(id, 1, game.simulation.economy.stock)
		"craft":
			var recipe: Dictionary = LifeCatalog.RECIPES.get(id, {})
			success = not recipe.is_empty() and _near_station(recipe.station) and life.craft(id, recipe.station)
		"repair", "self_repair": success = _near_station("forge") and life.repair(id, verb == "self_repair")
		"contract": success = _near_station("contracts") and life.fulfill(id, game.simulation)
		"starter":
			if not _near_plot():
				return "Aproxime-se do lote para montar a casa."
			var plot := life.estate.owned(PlayerLife.ID)
			var cell := Homestead.cell_at(plot, game.player.position)
			if cell.x in [1, 2] and cell.y in [1, 2]:
				return "Fique fora das quatro células centrais antes de montar."
			var result := life.estate.starter(PlayerLife.ID, plot, life.bag)
			return "Casa inicial montada." if result.is_empty() else result
		"plant":
			var args := id.split(":")
			if _near_plot() and args.size() == 3 and args[0].is_valid_int() and args[1].is_valid_int():
				success = life.farm(Vector2i(int(args[0]), int(args[1])), args[2], game.simulation.clock.elapsed, game.raining)
	return "Concluído." if success else "Ação indisponível. Confira local, requisitos, estoque, capacidade e saldo."

func _register() -> void:
	game.interactions.register("Bancada de alquimia", STATIONS.alchemy, func() -> void: open_near("alchemy"), 1.55)
	game.interactions.register("Oficina de marcenaria", STATIONS.carpentry, func() -> void: open_near("carpentry"), 1.55)
	game.interactions.register("Galinheiro · alimentar ou colher ovos", STATIONS.coop, func() -> void:
		if active() and life.coop(game.simulation.clock.elapsed):
			game.hud.show_message("Galinheiro atendido.")
		else:
			game.hud.show_message("Agricultores alimentam as galinhas com trigo. Os ovos levam um tempo."), 1.55)
	game.interactions.register("Campo de treino · técnicas", TrainingSession.CENTER, func() -> void:
		if active():
			life.explore("Campo de treino")
			ui.open("character")
		game.hud.show_message("F usa a técnica da classe. Guerreiro: segure Shift para defender."), 2.0)
	game.interactions.register("Rastrear pegadas do bosque", Vector3(20.18, 0.10, -16.45), func() -> void:
		if life.role() == "archer" and life.explore("Pegadas do bosque"):
			game.hud.show_message("Pegadas recentes seguem rumo ao rio. Rastreio registrado.")
		else:
			game.hud.show_message("As marcas rasas se perdem entre as pedras."), 1.65)
	for key in GATHER:
		var item: String = key
		game.interactions.register("Coletar " + LifeCatalog.label(item).to_lower(), GATHER[item], func() -> void:
			if active() and life.gather(item, game.simulation.clock.elapsed):
				game.hud.show_message(LifeCatalog.label(item) + " foi para o inventário.")
			else:
				game.hud.show_message("Recurso indisponível ou inventário cheio."), 1.55)

func _attack() -> void:
	var player := game.player as PixelActor
	var position := player.position
	if position.distance_squared_to(TrainingSession.CENTER) > 12.0 * 12.0:
		game.hud.show_message("O campo de treino fica na margem leste, ao sul da ponte de pedra.")
		return
	var index := 0
	var range_value := 0.0
	match life.role():
		"warrior": range_value = 2.2
		"archer":
			index = 1
			range_value = 11.0
		"mage":
			index = 0 if position.distance_to(TrainingSession.SPOTS[0]) <= position.distance_to(TrainingSession.SPOTS[1]) or not training.available(1) else 1
			if not training.available(index):
				index = 1 - index
			range_value = 9.0
		"healer":
			index = 2
			range_value = 6.0
	var target: Vector3 = TrainingSession.SPOTS[index]
	if range_value == 0.0 or position.distance_to(target) > range_value:
		game.hud.show_message("Aproxime-se do alvo da sua classe.")
		return
	var skill := training.begin(life, index)
	if skill.is_empty():
		game.hud.show_message("Técnica indisponível. Confira alvo, equipamento e recursos.", 2.1)
		return
	player.face(target - position)
	player.gesture()
	if skill.projectile:
		_launch(index, position + Vector3.UP * 0.80, skill.amount)
	else:
		training.apply(life, index, skill.amount)
	game.hud.show_message(skill.name, 1.2)

func _launch(index: int, origin: Vector3, amount: float) -> void:
	var shot := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.08, 0.08, 0.27)
	shot.mesh = mesh
	shot.material_override = game.diorama.palette.materials.fire if life.role() == "mage" else game.diorama.palette.materials.oak
	game.add_child(shot)
	shot.position = origin
	var destination: Vector3 = TrainingSession.SPOTS[index] + Vector3.UP * 0.77
	if not origin.is_equal_approx(destination):
		shot.look_at(destination)
	projectiles.append({"node": shot, "destination": destination, "target": index, "amount": amount})

func _create_training() -> void:
	for index in TrainingSession.SPOTS.size():
		var model := Node3D.new()
		model.position = TrainingSession.SPOTS[index]
		game.add_child(model)
		target_models.append(model)
		if index == 2:
			var ally := PixelActor.new()
			ally.configure(Color("667989"), Color("493a37"), 3, false, "guard")
			ally.collision_mask = 0
			ally.collision_layer = 0
			model.add_child(ally)
			ally.pose(Vector3.ZERO, Vector3.RIGHT, Color.WHITE, false, "RESTING")
		else:
			_prop(model, Vector3(0, 0.53, 0), Vector3(0.14, 1.07, 0.16), "wood")
			_prop(model, Vector3(0, 0.87, 0.02), Vector3(0.70, 0.69, 0.17), "oak")
			for side in [-1.0, 1.0]:
				_prop(model, Vector3(0, 0.87, 0.12 * side), Vector3(0.48, 0.47, 0.05), "wine")
				_prop(model, Vector3(0, 0.87, 0.155 * side), Vector3(0.20, 0.21, 0.035), "ivory")
		var label := Label3D.new()
		label.position.y = 1.65
		label.pixel_size = 0.0046
		label.font_size = 31
		label.outline_size = 4
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("f0d5a2")
		label.visibility_range_end = 34.0
		model.add_child(label)
		target_labels.append(label)
	for station in ["carpentry", "alchemy"]:
		var bench := Node3D.new()
		bench.position = STATIONS[station] + Vector3(0, 0, -0.55)
		game.add_child(bench)
		_prop(bench, Vector3(0, 0.57, 0), Vector3(1.23, 0.15, 0.54), "oak")
		for x in [-0.49, 0.49]:
			_prop(bench, Vector3(x, 0.26, 0), Vector3(0.11, 0.52, 0.45), "wood")
		_prop(bench, Vector3(0.15, 0.73, 0), Vector3(0.24, 0.17, 0.21), "wellwater" if station == "alchemy" else "iron")

func _prop(root: Node3D, p: Vector3, size: Vector3, material: String) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = p
	instance.material_override = game.diorama.palette.materials[material]
	root.add_child(instance)

func _key(event: InputEvent, key: Key) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == key
