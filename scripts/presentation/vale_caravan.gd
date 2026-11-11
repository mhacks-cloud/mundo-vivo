class_name ValeCaravan
extends Node3D

var actor: PixelActor
var wagon := Node3D.new()
var game: Node3D
var trade: FrontierTrade
var route := PackedVector3Array()
var cursor := 0
var revision := -1
var retry := 0.0
var raider: PixelActor
var loot_marker := Node3D.new()
var loot_target: Dictionary
var raid_timer := 0.8

func setup(scene: Node3D, market: FrontierTrade) -> void:
	game = scene
	trade = market
	actor = PixelActor.new()
	actor.configure(Color("8d7454"), Color("74533a"), 2, false, "carrier")
	add_child(actor)
	add_child(wagon)
	raider = PixelActor.new()
	raider.configure(Color("795c62"), Color("5d4139"), 4, false, "guard")
	add_child(raider)
	raider.hide()
	game.add_child(loot_marker)
	_box(loot_marker, Vector3(0, 0.23, 0), Vector3(0.58, 0.42, 0.46), "goldroof")
	loot_marker.hide()
	game.interactions.register("Recuperar carga caída", Vector3(100, 0, 100), _collect, 1.8)
	loot_target = game.interactions.targets.back()
	_box(wagon, Vector3(0, 0.47, 0), Vector3(0.87, 0.18, 1.16), "oak")
	for side in [-1.0, 1.0]:
		_box(wagon, Vector3(side * 0.47, 0.64, 0), Vector3(0.07, 0.25, 1.18), "wood")
		var wheel := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.28
		disc.bottom_radius = 0.28
		disc.height = 0.11
		disc.radial_segments = 12
		wheel.mesh = disc
		wheel.rotation.z = PI * 0.5
		wheel.position = Vector3(side * 0.54, 0.28, 0.12)
		wheel.material_override = game.diorama.palette.materials.wood
		wagon.add_child(wheel)
	_box(wagon, Vector3(0, 0.72, 0.12), Vector3(0.57, 0.42, 0.51), "goldroof")
	var receiving := Node3D.new()
	game.add_child(receiving)
	receiving.position = FrontierTrade.DESTINATION + Vector3(1.1, 0, -0.35)
	_box(receiving, Vector3(0, 0.73, 0), Vector3(1.43, 0.14, 0.69), "oak")
	for side in [-1.0, 1.0]:
		_box(receiving, Vector3(side * 0.59, 0.36, 0), Vector3(0.12, 0.74, 0.57), "wood")
		_box(receiving, Vector3(side * 0.67, 1.08, 0.31), Vector3(0.08, 2.15, 0.09), "wood")
	_box(receiving, Vector3(0, 2.12, 0), Vector3(1.61, 0.10, 1.02), "mossroof")
	_box(receiving, Vector3(0.31, 0.92, -0.06), Vector3(0.37, 0.26, 0.30), "board")
	_sign(receiving, Vector3(0, 1.51, 0.38), "BRUMÁRIA")
	_sign(game, FrontierTrade.ORIGIN + Vector3(0, 0.95, 0), "FRETES")
	reset()

func reset() -> void:
	visible = not trade.shipment.is_empty()
	revision = -1
	retry = 0.0
	route.clear()
	raid_timer = 0.8
	raider.hide()
	if visible:
		actor.position = trade.shipment.position
		wagon.position = actor.position + Vector3.BACK * 1.15
		if trade.shipment.risk == 1:
			raider.position = actor.position + Vector3.BACK * 1.3
			raider.show()
	_refresh_loot()

func advance(life: PlayerLife, guild: GuildLedger, delta: float) -> void:
	_refresh_loot()
	visible = not trade.shipment.is_empty()
	if not visible:
		return
	retry = maxf(0, retry - delta)
	if revision != game.navigation.revision or (route.is_empty() and retry == 0):
		revision = game.navigation.revision
		actor.position = trade.shipment.position
		route = game.navigation.find(actor.position, FrontierTrade.DESTINATION)
		cursor = 0
		retry = 0.8
	if route.is_empty():
		return
	if trade.shipment.risk == 0 and actor.position.x >= 19.4:
		trade.shipment.risk = 1
		raider.position = actor.position + Vector3.BACK * 2.1
		raider.show()
		raid_timer = 1.1
		game.simulation.economy.journal.record(game.simulation.clock, "raid", "Uma carroça foi interceptada perto de Brumária.")
		if game.player.position.distance_to(actor.position) < 14.0:
			game.hud.show_message("Emboscada na carroça. F defende o frete.")
	if trade.shipment.risk == 1:
		_raid(life, guild, delta)
		return
	if cursor < route.size() and actor.position.distance_to(route[cursor]) < 0.12:
		cursor += 1
	if cursor >= route.size():
		if trade.arrive(life):
			guild.finish(life)
		return
	var origin := actor.position
	var offset := route[cursor] - origin
	var motion := offset.limit_length(delta * 1.75)
	var hit := actor.move_and_collide(motion)
	if hit != null and actor.position.distance_squared_to(origin) < 0.00002:
		route.clear()
		return
	trade.shipment.position = actor.position
	guild.travel(actor.position.distance_to(origin), actor.position.distance_squared_to(game.player.position) <= 6.5 * 6.5)
	var right: Vector3 = game.camera.global_basis.x
	actor.pose((actor.position - origin) / delta, right, game.sprite_light)
	if motion.length_squared() > 0.00001:
		var direction := motion.normalized()
		var target := actor.position - direction * 1.10
		wagon.position = wagon.position.lerp(target, minf(1.0, delta * 9.0))
		wagon.rotation.y = lerp_angle(wagon.rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 8.0))

func defend(life: PlayerLife) -> bool:
	if trade.shipment.is_empty() or trade.shipment.risk != 1 or game.player.position.distance_to(raider.position) > 10.0:
		return false
	if life.cooldown > 0.0:
		return true
	var player: PixelActor = game.player
	if life.role() == "healer":
		if life.equipped("accessory") == "charm" and life.mana >= 18 and trade.shipment.guard < 3 and player.position.distance_to(actor.position) <= 6.0:
			life.mana -= 18
			life.wear("accessory")
			trade.shipment.guard += 1
			life.cooldown = 0.65
			player.gesture()
		return true
	if life.role() not in ["warrior", "archer", "mage"]:
		return true
	if life.equipped("weapon") != LifeCatalog.CLASSES[life.role()].start:
		return true
	var reach := 2.2 if life.role() == "warrior" else 10.0
	if player.position.distance_to(raider.position) > reach:
		return true
	var query := PhysicsRayQueryParameters3D.create(player.position + Vector3.UP * 0.8, raider.position + Vector3.UP * 0.8, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return true
	if life.role() == "archer" and not life.bag.spend({"arrow": 1}):
		return true
	if life.role() == "mage":
		if life.mana < 18:
			return true
		life.mana -= 18
	player.face(raider.position - player.position)
	player.gesture()
	life.wear("weapon")
	life.cooldown = 0.65
	trade.shipment.raider -= 17.0
	if trade.shipment.raider <= 0:
		life.award(12)
		_end_raid()
	return true

func _raid(life: PlayerLife, guild: GuildLedger, delta: float) -> void:
	var offset := actor.position - raider.position
	var right: Vector3 = game.camera.global_basis.x
	if offset.length() > 1.15:
		var move := offset.limit_length(delta * 2.1)
		raider.move_and_collide(move)
		raider.pose(move / delta, right, game.sprite_light)
		return
	raid_timer = maxf(0, raid_timer - delta)
	raider.pose(Vector3.ZERO, right, game.sprite_light, raid_timer < 0.44)
	actor.pose(Vector3.ZERO, right, game.sprite_light, raid_timer < 0.44)
	if raid_timer > 0:
		return
	raid_timer = 1.45
	trade.shipment.guard -= 1
	trade.shipment.raider -= 8
	if trade.shipment.raider <= 0:
		_end_raid()
	elif trade.shipment.guard <= 0:
		trade.lose(game.simulation.clock.elapsed)
		guild.finish(life, false)
		raider.hide()
		_refresh_loot()

func _end_raid() -> void:
	trade.shipment.risk = 2
	raider.hide()
	game.simulation.economy.journal.record(game.simulation.clock, "raid", "A carroça retomou o trajeto após a emboscada.")

func _refresh_loot() -> void:
	if not trade.loot.is_empty() and game.simulation.clock.elapsed >= trade.loot.expires:
		trade.loot.clear()
	loot_marker.visible = not trade.loot.is_empty()
	if loot_marker.visible:
		loot_marker.position = trade.loot.position
	loot_target.position = loot_marker.position if loot_marker.visible else Vector3(100, 0, 100)

func _collect() -> void:
	var life: PlayerLife = game.career.life
	if trade.collect(life, game.player.position, game.simulation.clock.elapsed):
		game.hud.show_message("Carga recuperada · 3 trigos.")
		_refresh_loot()

func _box(parent: Node3D, point: Vector3, size: Vector3, material: String) -> void:
	var display := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	display.mesh = mesh
	display.position = point
	display.material_override = game.diorama.palette.materials[material]
	parent.add_child(display)

func _sign(parent: Node3D, point: Vector3, value: String) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = point
	label.pixel_size = 0.005
	label.font_size = 30
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("f0d59d")
	parent.add_child(label)
