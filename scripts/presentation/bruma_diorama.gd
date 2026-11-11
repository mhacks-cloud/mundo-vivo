class_name BrumaDiorama
extends ValeDiorama

const CENTER := Vector3(53.5, 0.0, 39.0)
var worksite := Node3D.new()
var work_key := ""
var barricade: StaticBody3D

func _ready() -> void:
	add_child(crop_full)
	add_child(crop_sprouts)
	rng.seed = 1216
	palette.make("shale", "576576", "stone", 0.51)
	palette.make("slateroof", "556b79", "tiles", 0.52)
	palette.make("riverbruma", "486c78")
	palette.materials.slateroof.albedo_color = Color("819ba9")
	palette.materials.shale.albedo_color = Color("8796a4")
	leaf.radial_segments = 7
	leaf.rings = 4
	trunks.top_radius = 0.30
	trunks.bottom_radius = 0.52
	add_child(foliage)
	box(CENTER + Vector3.DOWN * 0.61, Vector3(57, 1.0, 53), "shale")
	_soil(CENTER - Vector3.UP * 0.013, Vector2(57, 53))
	for edge in [Vector3(38.0, 0.75, 39), Vector3(69.0, 0.75, 39)]:
		collider(edge, Vector3(0.45, 1.5, 31), self)
	for edge in [Vector3(53.5, 0.75, 24), Vector3(53.5, 0.75, 54)]:
		collider(edge, Vector3(31, 1.5, 0.45), self)
	for id in RealmWorld.PATHS:
		var path: Array = RealmWorld.PATHS[id]
		for index in range(1, path.size()):
			_path(path[index - 1], path[index], 2.0 if id == "ridge" else 1.50)
	_path(Vector3(54, 0.1, 42), RealmWorld.MINE, 1.45)
	_path(Vector3(54, 0.1, 42), RealmWorld.HAMLET, 1.25)
	for x in range(36, 72, 4):
		_rock(Vector3(x, -0.1, 20.0), rng.randf_range(6.2, 10.6), rng.randf_range(6.2, 10.9))
		_rock(Vector3(x + 1.7, -0.25, 24.4), rng.randf_range(3.0, 6.9), rng.randf_range(2.7, 6.4))
	for z in [28, 37, 43, 52]:
		_rock(Vector3(34, -0.45, z), rng.randf_range(4.0, 8.5), rng.randf_range(2.2, 6.0))
	var pond := Vector3(45.9, 0.02, 30.0)
	cylinder(pond, 2.55, 0.055, "mossstone", 17)
	cylinder(pond + Vector3.UP * 0.037, 2.24, 0.05, "riverbruma", 17)
	for side in [-1.9, 1.9]:
		collider(pond + Vector3(side, 0.43, 0), Vector3(0.62, 0.9, 2.3), self)
	for z in [29.0, 33.0, 47.0, 51.0]:
		_rock(Vector3(67.0, 0, z), 2.9, rng.randf_range(3.4, 5.6))
	for at in [Vector3(43, 0, 31), Vector3(50, 0, 28), Vector3(45, 0, 49), Vector3(40.5, 0, 44), Vector3(64, 0, 47), Vector3(48, 0, 51), Vector3(64, 0, 33)]:
		for i in 5:
			tree(at + Vector3(rng.randf_range(-1.6, 1.6), 0, rng.randf_range(-1.5, 1.5)), rng.randf_range(0.65, 1.02), true, false)
	house(Vector3(55.6, 0, 35.65), 4.2, 2.8, 2.4, "stone", "slateroof", "teal", "Coroa de Brumária")
	house(Vector3(61.9, 0, 42.7), 3.25, 2.6, 2.1, "plaster", "slateroof", "wine", "Forja")
	house(Vector3(49.4, 0, 34.7), 2.85, 2.55, 1.95, "sage", "mossroof", "teal")
	house(Vector3(53.8, 0, 47.7), 3.05, 2.5, 2.05, "stone", "roof", "wine")
	_market(Vector3(59.35, 0, 41.15), "slateroof")
	well(Vector3(55.45, 0, 43.7))
	for at in [Vector3(42, 0, 39.95), Vector3(53, 0, 39.9), Vector3(57, 0, 40), Vector3(60.9, 0, 33)]:
		lamp(at)
	for at in [RealmWorld.DEPOT + Vector3(0, 0, -0.6), RealmWorld.DEPOT + Vector3(0.6, 0, -0.62), RealmWorld.MARKET + Vector3(1, 0, 0.4)]:
		barrel(at)
	for x in [-1.65, 1.65]:
		var at := RealmWorld.GATE + Vector3(1.8, 0, x)
		box(at + Vector3.UP * 1.3, Vector3(0.50, 2.6, 0.6), "stone")
		collider(at + Vector3.UP * 1.3, Vector3(0.50, 2.6, 0.6), self)
	box(RealmWorld.GATE + Vector3(1.8, 2.72, 0), Vector3(0.7, 0.45, 3.9), "slateroof")
	sign_label(RealmWorld.GATE + Vector3(0.65, 1.3, 1.55), "PORTÃO DE BRUMÁRIA", 0.005)
	for at in [Vector3(60.5, 0, 27.9), Vector3(59.3, 0, 28.0), Vector3(61.2, 0, 29.1)]:
		_rock(at, 1.2, 1.35)
		box(at + Vector3(0.18, 0.76, 0.29), Vector3(0.38, 0.27, 0.32), "iron", Vector3(0.4, 0.2, 0.25))
	sign_label(RealmWorld.MINE + Vector3(0.2, 1.05, -0.65), "PEDREIRA DO SINO", 0.005)
	for i in 430:
		var p := CENTER + Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(-14, 14))
		if p.x > 50 and p.x < 60 and p.z > 36.5 and p.z < 43.5:
			continue
		if absf(p.z - 39.0) > 1.1 and absf(p.z - 45.5) > 1.0:
			grass(p, rng.randf_range(0.65, 1.16))
			if i % 7 == 0:
				flower(p)
			if i % 9 == 0:
				shrub(p)
	ground.set_shader_parameter("footprints", footprints)
	foliage.build()
	_flush()
	add_child(worksite)
	barricade = collider(Vector3(46.1, 0.45, 39.0), Vector3(0.5, 0.9, 2.85), self)

func weather(index: int, wet: bool, snow: bool, light: float) -> void:
	foliage.atmosphere(index, wet)
	var tones := [Color("acbea2"), Color("c2c6a1"), Color("bbad82"), Color("aeb9b5")]
	ground.set_shader_parameter("ground_tint", tones[index])
	ground.set_shader_parameter("wetness", 1.0 if wet else 0.0)
	ground.set_shader_parameter("frost", 0.44 if snow else 0.0)
	for lamp in lanterns:
		lamp.light_energy = float(lamp.get_meta("base_energy")) * (1.0 - light * 0.78)

func _path(from: Vector3, to: Vector3, width: float) -> void:
	var direction := to - from
	box((from + to) * 0.5 - Vector3.UP * 0.094, Vector3(width, 0.035, direction.length() + 0.15),
		"cobble", Vector3(0, atan2(direction.x, direction.z), 0))

func _rock(at: Vector3, width: float, height: float) -> void:
	piece(leaf, at + Vector3.UP * height * 0.35, Vector3(width, height, width * 0.82), "shale",
		Vector3(0.16, rng.randf_range(-PI, PI), 0.23))

func sync(world: RealmWorld) -> void:
	var key := "%s:%s:%s" % [world.damaged, world.houses, world.project.get("done", 0)]
	if key == work_key:
		return
	work_key = key
	for child in worksite.get_children():
		worksite.remove_child(child)
		child.queue_free()
	barricade.collision_layer = 1 if world.damaged else 0
	batch_root = worksite
	if world.damaged:
		box(Vector3(46.1, 0.38, 39.0), Vector3(0.28, 0.40, 2.8), "board")
		for side in [-1.28, 1.28]:
			box(Vector3(46.1, 0.43, 39.0 + side), Vector3(0.20, 0.89, 0.19), "wood")
	if not world.project.is_empty():
		var site: Vector3 = RealmWorld.WORKS[world.project.id].at
		for i in int(world.project.done):
			box(site + Vector3(0, 0.15 + i * 0.21, 0), Vector3(2.1, 0.20, 0.88), "stone" if i < 2 else "board")
	if world.houses > 0 and not has_meta("built_hamlet"):
		set_meta("built_hamlet", true)
		house(RealmWorld.HAMLET + Vector3(1.05, 0, -1.6), 2.85, 2.25, 1.95, "sage", "slateroof", "teal", "Pouso da Geada")
		batch_root = worksite
	_flush()
	ground.set_shader_parameter("footprints", footprints)
	batch_root = null
