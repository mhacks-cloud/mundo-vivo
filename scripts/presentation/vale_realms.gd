class_name ValeRealms
extends Node

var world := RealmWorld.new()
var game: Node3D
var scene: BrumaDiorama
var worker: PixelActor
var miner: PixelActor
var guard: PixelActor
var driver: PixelActor
var queen: PixelActor
var resident: PixelActor
var newcomer: PixelActor
var wagon: Node3D
var raider: PixelActor
var scout: PixelActor
var fallen_marker: MeshInstance3D
var fallen_target: Dictionary
var last_convoy_status := ""
var map: RealmMap
var last_region := ""
var open_marker: Dictionary

func setup(vale: Node3D) -> void:
	game = vale
	world.convoy_finished.connect(func(delivered: bool, distance: float, covered: float) -> void:
		game.career.guild.settle_highland_escort(game.career.life, delivered, distance, covered))
	map = RealmMap.new()
	add_child(map)
	map.setup(self)
	game.interactions.register("Portão leste · Alto da Bruma", RealmWorld.ROAD_ENTRY, func() -> void: travel(true), 2.0)
	game.interactions.register("Portão oeste · voltar à fronteira", RealmWorld.GATE, func() -> void: travel(false), 1.9)
	game.interactions.register("Guarda da fronteira · taxas e inspeções", RealmWorld.GATE + Vector3(2.8, 0, 1.5), _customs, 1.45)
	game.interactions.register("Coroa de Brumária · Rainha Elira", RealmWorld.HALL, func() -> void: game.career.ui.open("bruma_works"), 2.0)
	game.interactions.register("Forja de Alto da Bruma", Vector3(61.9, 0.1, 44.5), func() -> void: game.career.ui.open("forge"), 1.8)
	game.interactions.register("Mercado de Alto da Bruma", RealmWorld.MARKET, func() -> void: game.career.ui.open("bruma_market"), 2.0)
	game.interactions.register("Pedreira do Sino · extrair ferro por 2 ouro", RealmWorld.MINE, _mine, 1.8)
	game.interactions.register("Pouso da Geada · consultar ocupação", Vector3(100, 0, 100), _visit_hamlet, 2.0)
	open_marker = game.interactions.targets.back()
	game.interactions.register("Recolher carga da encosta", Vector3(100, 0, 100), _recover, 1.8)
	fallen_target = game.interactions.targets.back()
	var marker := Label3D.new()
	marker.text = "ALTO DA BRUMA"
	marker.position = RealmWorld.ROAD_ENTRY + Vector3.UP * 1.25
	marker.font_size = 24
	marker.pixel_size = 0.005
	marker.modulate = Color("efd097")
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	game.diorama.add_child(marker)
	var source: ValeDiorama = game.diorama
	source.paving(RealmWorld.ROAD_ENTRY + Vector3(-1.7, 0.002, 0), Vector2(7.0, 1.75), "cobble")
	for side in [-1.47, 1.47]:
		var pillar := RealmWorld.ROAD_ENTRY + Vector3(0.83, 1.14, side)
		source.box(pillar, Vector3(0.46, 2.27, 0.56), "stone")
		source.collider(pillar, Vector3(0.46, 2.27, 0.56), source)
	source.box(RealmWorld.ROAD_ENTRY + Vector3(0.83, 2.42, 0), Vector3(0.66, 0.30, 3.66), "wood")
	source._flush()
	game.nav_dirty = true

func travel(entering: bool) -> void:
	var at: Vector3 = game.player.position
	if not game.career.active() or game.career.authority.detained() or world.active == entering:
		return
	if at.distance_to(RealmWorld.ROAD_ENTRY if entering else RealmWorld.GATE) > 2.1:
		return
	game.career.ui.hide_panel()
	game.career.cancel_build()
	world.active = entering
	_sync_scene()
	game.player.position = RealmWorld.GATE + Vector3.RIGHT * 2.5 if entering else RealmWorld.ROAD_ENTRY + Vector3.LEFT * 2.1
	game.player.face(Vector3.RIGHT if entering else Vector3.LEFT)
	game.follow = game.player.position + Vector3.UP * 0.65
	world.discover(world.current(game.player.position))
	game.hud.show_message("Alto da Bruma · entrada em Brumária" if entering else "Entreposto da fronteira")

func reset() -> void:
	world.restore(null)
	_sync_scene()

func restore(data: Variant) -> void:
	map.hide()
	world.restore(data)
	_sync_scene()
	if world.active:
		_sync_loot()

func tick(delta: float) -> void:
	var clock: WorldClock = game.simulation.clock
	var career: ValeLife = game.career
	if not career.active():
		return
	if "capital" in world.discovered:
		world.advance(clock, career.frontier, delta, game.player.position)
		world.scout_loot(career.authority.underworld, clock.elapsed, delta)
		world.work(clock, delta)
	var status: String = world.shipment.get("status", "")
	if status == "ATACADA" and last_convoy_status != status:
		game.career.authority.escort_calls += 1
		game.career.authority.escort_bonus = 4
		game.simulation.economy.journal.record(clock, "raid", "Brumária informou uma emboscada na encosta.")
	last_convoy_status = status
	var region := world.current(game.player.position)
	if last_region != region:
		last_region = region
		world.discover(region)
	if not world.active or not is_instance_valid(scene):
		return
	scene.sync(world)
	game.hud.update_regional_work(world)
	open_marker.position = RealmWorld.HAMLET if world.houses > 0 else Vector3(100, 0, 100)
	var right: Vector3 = game.camera.global_basis.x
	var light: Color = game.sprite_light
	var moving := (world.worker_at - worker.position) / maxf(delta, 0.001)
	worker.position = world.worker_at
	var step: int = world.project.get("step", -1)
	worker.set_cargo(("ferro" if int(world.project.done) % 2 == 0 else ("pedra" if world.project.get("material") == "stone" else "madeira")) if step == 1 else "")
	worker.pose(moving, right, light, step == 3 and moving.length_squared() < 0.02)
	var working := clock.hour() >= 7.0 and clock.hour() < 18.0
	var mine_goal := RealmWorld.MINE + Vector3(1.1, 0, 0.4) if working else Vector3(57.5, 0.1, 34.0)
	_move_actor(miner, mine_goal, right, light, delta, working and world.mine_units > 0)
	var gate_goal := RealmWorld.GATE + Vector3(2.8, 0, 1.5 if fmod(clock.elapsed, 22.0) < 11.0 else -1.4)
	_move_actor(guard, gate_goal, right, light, delta)
	queen.pose(Vector3.ZERO, right, light)
	resident.visible = world.houses > 0
	if resident.visible:
		var goal := Vector3(58.6, 0.1, 44.4) if working else RealmWorld.HAMLET
		_move_actor(resident, goal, right, light, delta)
	newcomer.visible = game.society.migration >= 4
	if newcomer.visible:
		var destination := RealmWorld.WORKS.district.at as Vector3
		if game.society.migration < 6:
			destination = RealmWorld.GATE.lerp(destination, 1.0 - float(game.society.travel_left) / 55.0)
		elif working and game.society.employment_misses < 3:
			destination = RealmWorld.WORKS.workshop.at
		_move_actor(newcomer, destination, right, light, delta)
	_pose_convoy(right, light, delta)
	_sync_loot()
	scout.visible = not world.loot.is_empty() and not world.loot.get("salvaged", false) and clock.elapsed >= float(world.loot.expires) - 106.0
	if scout.visible:
		var target: Vector3 = world.loot.scout
		scout.pose((target - scout.position) / maxf(delta, 0.001), right, light)
		scout.position = target

func _pose_convoy(right: Vector3, light: Color, delta: float) -> void:
	var moving := not world.shipment.is_empty()
	wagon.visible = moving
	driver.visible = moving
	raider.visible = world.shipment.get("status") == "ATACADA"
	if not moving:
		return
	var at: Vector3 = world.shipment.at
	var direction := at - driver.position
	driver.position = at
	driver.pose(direction / maxf(delta, 0.001), right, light)
	if raider.visible:
		raider.position = at + Vector3.BACK * 1.3
		raider.pose(Vector3.ZERO, right, light, fmod(game.simulation.clock.elapsed, 1.2) < 0.35)
	if direction.length_squared() > 0.00001:
		wagon.rotation.y = atan2(direction.x, direction.z)
	wagon.position = at - wagon.basis.z * 1.03

func _move_actor(actor: PixelActor, goal: Vector3, right: Vector3, light: Color, delta: float, building := false) -> void:
	var origin := actor.position
	actor.move_and_collide((goal - origin).limit_length(delta * 1.3))
	var movement := (actor.position - origin) / maxf(delta, 0.001)
	actor.pose(movement, right, light, building and movement.length_squared() < 0.01)

func _sync_scene() -> void:
	game.diorama.visible = not world.active
	if not world.active:
		game.hud.update_bridge(game.simulation.construction, game.career.authority.works.road_closed)
	game.fauna.visible = not world.active
	for person in game.people:
		person.visible = not world.active
	if world.active and not is_instance_valid(scene):
		scene = BrumaDiorama.new()
		game.add_child(scene)
		scene.foliage.quality(game.quality)
		scene.sync(world)
		worker = _actor("Mestra Avelina", world.worker_at, "946c57", 2, "carrier")
		miner = _actor("Tomás · mineiro", RealmWorld.MINE + Vector3(1, 0, 0.3), "77838a", 3, "guard")
		guard = _actor("Guarda da fronteira", RealmWorld.GATE + Vector3(2.8, 0, 1.5), "627b86", 3, "guard")
		driver = _actor("Aldo · condutor", RealmWorld.GATE, "876c4d", 2, "carrier")
		raider = _actor("Saqueador da encosta", RealmWorld.GATE, "7d626c", 4, "guard")
		scout = _actor("Batedora do Junco", RealmWorld.GATE, "65616d", 4, "carrier")
		scout.hide()
		queen = _actor("Rainha Elira", RealmWorld.HALL + Vector3(0.8, 0, -0.72), "826997", 4, "guard")
		newcomer = _actor("Beatriz", RealmWorld.WORKS.district.at if game.society.migration >= 6 else RealmWorld.GATE, "787c56", 4, "resident")
		newcomer.visible = game.society.migration >= 4
		resident = _actor("Célia do Pouso", RealmWorld.HAMLET, "8b8e5e", 1, "carrier")
		wagon = Node3D.new()
		scene.add_child(wagon)
		_wagon_box(Vector3(0, 0.41, 0), Vector3(0.84, 0.26, 1.16), "wood")
		_wagon_box(Vector3(0, 0.69, 0), Vector3(0.70, 0.35, 0.82), "goldroof")
		for side in [-0.48, 0.48]:
			var wheel := MeshInstance3D.new()
			var disk := CylinderMesh.new()
			disk.height = 0.12
			disk.top_radius = 0.25
			disk.bottom_radius = 0.25
			wheel.mesh = disk
			wheel.position = Vector3(side, 0.26, 0.1)
			wheel.rotation.z = PI / 2.0
			wheel.material_override = scene.palette.materials.wood
			wagon.add_child(wheel)
		fallen_marker = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.68, 0.52, 0.62)
		fallen_marker.mesh = box
		fallen_marker.material_override = scene.palette.materials.goldroof
		scene.add_child(fallen_marker)
		_pose_convoy(game.camera.global_basis.x, game.sprite_light, 1.0)
		_sync_loot()
	elif not world.active and is_instance_valid(scene):
		game.remove_child(scene)
		scene.queue_free()
		scene = null
	open_marker.position = RealmWorld.HAMLET if world.active and world.houses > 0 else Vector3(100, 0, 100)
	last_region = ""
	last_convoy_status = world.shipment.get("status", "")
	if not world.active:
		fallen_target.position = Vector3(100, 0, 100)

func _wagon_box(at: Vector3, size: Vector3, material: String) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = at
	mesh.material_override = scene.palette.materials[material]
	wagon.add_child(mesh)

func _actor(label: String, at: Vector3, color: String, hat: int, role: String) -> PixelActor:
	var actor := PixelActor.new()
	actor.configure(Color(color), Color("67513b"), hat, false, role)
	actor.position = at
	scene.add_child(actor)
	var title := Label3D.new()
	title.text = label
	title.font_size = 24
	title.pixel_size = 0.0047
	title.modulate = Color("eed8ac")
	title.position.y = 1.6
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.visibility_range_end = 23.0
	actor.add_child(title)
	return actor

func _sync_loot() -> void:
	fallen_marker.visible = not world.loot.is_empty()
	fallen_target.position = world.loot.at if fallen_marker.visible else Vector3(100, 0, 100)
	if fallen_marker.visible:
		fallen_marker.position = world.loot.at + Vector3.UP * 0.28

func _recover() -> void:
	if world.active and world.recover(game.career.life, game.player.position, game.simulation.clock.elapsed):
		_sync_loot()
		game.hud.show_message("Carga da encosta recuperada.")

func defend() -> bool:
	if not world.active or world.shipment.get("status") != "ATACADA":
		return false
	var player: PixelActor = game.player
	var life: PlayerLife = game.career.life
	var role := life.role()
	if role not in ["warrior", "archer", "mage"] or life.cooldown > 0:
		return true
	if life.equipped("weapon") != LifeCatalog.CLASSES[role].start:
		return true
	var reach := 2.2 if role == "warrior" else 9.0
	if player.position.distance_to(raider.position) > reach:
		return true
	var sight := PhysicsRayQueryParameters3D.create(player.position + Vector3.UP * 0.8, raider.position + Vector3.UP * 0.8, 1)
	if not game.get_world_3d().direct_space_state.intersect_ray(sight).is_empty():
		return true
	if role == "archer" and not life.bag.spend({"arrow": 1}):
		return true
	if role == "mage":
		if life.mana < 18:
			return true
		life.mana -= 18
	player.face(raider.position - player.position)
	player.gesture()
	life.wear("weapon")
	life.cooldown = 0.65
	if world.repel() and world.shipment.status != "ATACADA":
		game.career.authority.award_bounty()
	return true

func _customs() -> void:
	game.career.ui.open("bruma_customs")

func _mine() -> void:
	var message := "Ferro recolhido · −2 ouro." if world.extract(game.career.life) else "Sem veio disponível, espaço ou ouro."
	game.hud.show_message(message)

func _visit_hamlet() -> void:
	game.hud.show_message("Pouso da Geada · moradia habitada. População regional: %d." % world.population)

func perform(verb: String, id: String) -> String:
	var at: Vector3 = game.player.position
	var career: ValeLife = game.career
	if not world.active:
		return "Viaje até Alto da Bruma."
	if verb == "bruma_escort":
		if at.distance_to(RealmWorld.GATE + Vector3(2.8, 0, 1.5)) > 2.6:
			return "Vá ao posto da fronteira."
		return "Escolta reservada." if world.sign_escort(career.guild, career.life) else "A Companhia exige associação, saldo e comboio junto ao portão."
	if verb == "bruma_propose" and at.distance_to(RealmWorld.HALL) <= 2.5:
		return world.propose(id, career.life.profile.name)
	if at.distance_to(RealmWorld.MARKET) > 2.5:
		return "Aproxime-se do mercado."
	if verb == "bruma_buy" and world.buy(career.life, id):
		return "Compra concluída."
	if verb == "bruma_sell" and world.sell(career.life, id):
		return "Venda concluída."
	return "Confira estoque, saldo e capacidade."
