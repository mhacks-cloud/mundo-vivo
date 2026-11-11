class_name ValeRuin
extends Node3D

var game: Node3D
var career: ValeLife
var run := RuinRun.new()
var enemies: Array[Dictionary] = []
var bolts: Array[Dictionary] = []
var gate: StaticBody3D
var ally: PixelActor
var ally_attack := 0.0

func setup(scene: Node3D, controller: ValeLife) -> void:
	game = scene
	career = controller
	_box(Vector3(59.5, -0.86, -19), Vector3(66, 0.7, 56), "dark")
	_box(Vector3(59.5, -0.18, -19), Vector3(23, 0.36, 11), "stone")
	_wall(Vector3(59.5, 1.12, -24.5), Vector3(23, 2.24, 0.48))
	_wall(Vector3(59.5, 1.12, -13.5), Vector3(23, 2.24, 0.48))
	_wall(Vector3(48.4, 1.12, -19), Vector3(0.48, 2.24, 11))
	_wall(Vector3(70.5, 1.12, -19), Vector3(0.48, 2.24, 11))
	_wall(Vector3(60.4, 1.12, -22.9), Vector3(0.65, 2.24, 3.2))
	_wall(Vector3(60.4, 1.12, -15.1), Vector3(0.65, 2.24, 3.2))
	gate = _wall(Vector3(60.4, 1.12, -19), Vector3(0.26, 2.24, 4.6), "wood")
	var gate_face: Node3D = gate.get_meta("facade")
	for z in [-2.0, -1.2, -0.4, 0.4, 1.2, 2.0]:
		var beam := _box(gate.position + Vector3(0, 0, z), Vector3(0.36, 2.26, 0.12), "iron")
		beam.reparent(gate_face)
	for x in [50.0, 54.3, 58.6, 63.0, 67.3]:
		for z in [-24.10, -13.9]:
			_box(Vector3(x, 1.0, z), Vector3(0.77, 2.04, 0.62), "mossstone")
			_box(Vector3(x, 0.16, z), Vector3(0.98, 0.30, 0.78), "stone")
			_box(Vector3(x, 1.92, z), Vector3(0.97, 0.22, 0.73), "stone")
	for x in range(49, 72):
		for side in [-1.0, 1.0]:
			var rock := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radial_segments = 7
			mesh.rings = 3
			rock.mesh = mesh
			rock.position = Vector3(x + sin(float(x)) * 0.48, -0.32, -19.0 + side * (6.4 + cos(float(x)) * 0.87))
			rock.scale = Vector3(1.55 + 0.6 * sin(float(x) * 0.8), 1.25 + 0.4 * cos(float(x) * 0.9), 1.66)
			rock.material_override = game.diorama.palette.materials.mossstone
			add_child(rock)
	for point in [Vector3(50, 0, -23.8), Vector3(56, 0, -23.8), Vector3(56, 0, -14.2), Vector3(63, 0, -23.8), Vector3(68, 0, -14.2)]:
		_box(point + Vector3.UP * 0.96, Vector3(0.13, 1.92, 0.13), "wood")
		_box(point + Vector3.UP * 1.96, Vector3(0.23, 0.31, 0.23), "fire")
		var light := OmniLight3D.new()
		light.position = point + Vector3.UP * 1.9
		light.light_color = Color("ffc890")
		light.light_energy = 1.55
		light.omni_range = 8.3
		add_child(light)
	_box(RuinRun.CACHE + Vector3.UP * 0.25, Vector3(0.92, 0.49, 0.59), "oak")
	_box(RuinRun.CACHE + Vector3.UP * 0.53, Vector3(0.94, 0.12, 0.61), "wood")
	for i in 3:
		var actor := PixelActor.new()
		actor.configure(Color(["616e68", "6b6456", "855d56"][i]), Color("4a464b"), 3, false, "guard")
		actor.position = RuinRun.SPAWNS[i]
		add_child(actor)
		var title := Label3D.new()
		title.position.y = 1.62
		title.pixel_size = 0.005
		title.font_size = 27
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		title.modulate = Color("e1b996")
		actor.add_child(title)
		enemies.append({"actor": actor, "label": title, "mode": "patrol", "timer": 0.0, "phase": float(i)})
	ally = PixelActor.new()
	ally.configure(Color("677c84"), Color("c0a987"), 1, false, "guard")
	ally.position = RuinRun.ENTRANCE + Vector3.BACK
	add_child(ally)
	ally.hide()
	game.interactions.register("Sair da Ruína", RuinRun.ENTRANCE, leave, 1.55)
	game.interactions.register("Abrir cofre da Sentinela", RuinRun.CACHE, _recover, 1.8)
	refresh()
	hide()

func enter() -> void:
	if career.life.role() not in ["warrior", "archer", "mage", "healer"]:
		game.hud.show_message("A galeria é uma expedição para classes de aventura.")
		return
	run.enter(game.simulation.clock.total_day())
	show()
	game.player.position = RuinRun.ENTRANCE + Vector3.RIGHT * 0.65
	ally.position = RuinRun.ENTRANCE + Vector3.BACK
	game.follow = game.player.position
	game.hud.show_message("Ruína da Serra · derrote os vigias para abrir a câmara." if not run.empowered() else "Ruína da Serra · vigias fortalecidos neste dia.")
	refresh()

func leave() -> void:
	if not RuinRun.inside(game.player.position):
		return
	hide()
	game.player.position = RuinRun.EXIT
	game.follow = game.player.position
	_clear_bolts()

func restore(data: Variant) -> void:
	run.restore(data)
	_clear_bolts()
	for i in enemies.size():
		enemies[i].actor.position = RuinRun.SPAWNS[i]
		enemies[i].mode = "patrol"
		enemies[i].timer = 0.0
	refresh()

func refresh() -> void:
	gate.visible = not run.gate_open()
	gate.collision_layer = 0 if run.gate_open() else 1
	for i in enemies.size():
		var enemy := enemies[i]
		enemy.actor.visible = run.alive(i)
		enemy.label.text = "%s · %d PV" % [RuinRun.NAMES[i], ceili(run.health[i])]

func cast() -> void:
	var life := career.life
	if life.cooldown > 0 or life.hp <= 0:
		return
	var player: PixelActor = game.player
	var index := _closest(player.position)
	if life.role() == "healer":
		if run.ally_hp >= 100 or life.mana < 18 or life.equipped("accessory") != "charm" or player.position.distance_to(ally.position) > 6.0:
			game.hud.show_message("A cura exige mana, talismã e um aliado próximo com vida a recuperar.")
			return
		life.mana -= 18
		life.wear("accessory")
		run.ally_hp = minf(100, run.ally_hp + 35)
		life.cooldown = 0.62
		player.gesture()
		game.hud.show_message("Aliado restaurado · %d PV" % ceili(run.ally_hp))
		return
	if index < 0:
		return
	var target: PixelActor = enemies[index].actor
	var reach := 2.2 if life.role() == "warrior" else 10.0
	var weapon: String = LifeCatalog.CLASSES[life.role()].start
	if player.position.distance_to(target.position) > reach or life.equipped("weapon") != weapon:
		game.hud.show_message("Aproxime-se e confira seu equipamento.")
		return
	var origin := player.position + Vector3.UP * 0.82
	var destination := target.position + Vector3.UP * 0.8
	if not _line_clear(origin, destination):
		return
	var damage := 23.0
	match life.role():
		"archer":
			if not life.bag.spend({"arrow": 1}):
				game.hud.show_message("Você precisa de flechas.")
				return
			damage = 19.0
		"mage":
			if life.mana < 18:
				game.hud.show_message("Você precisa de mana.")
				return
			life.mana -= 18
			damage = 29.0
	player.face(target.position - player.position)
	player.gesture()
	life.wear("weapon")
	life.cooldown = 0.67
	if life.role() == "warrior":
		run.strike(life, index, damage)
		refresh()
	else:
		var bolt := _box(origin, Vector3(0.11, 0.11, 0.27), "fire" if life.role() == "mage" else "oak")
		bolts.append({"node": bolt, "index": index, "damage": damage, "remaining": 0.9})

func physics(delta: float) -> void:
	var player: PixelActor = game.player
	var life := career.life
	var inside := RuinRun.inside(player.position)
	visible = inside
	ally.visible = inside and life.role() == "healer" and run.ally_hp > 0
	if not inside:
		return
	life.cooldown = maxf(0.0, life.cooldown - delta)
	var right: Vector3 = game.camera.global_basis.x
	for i in enemies.size():
		if run.alive(i):
			_update_enemy(i, player, right, delta)
	_update_ally(player, right, delta)
	_update_bolts(delta)
	if life.hp <= 0:
		life.hp = life.max_hp() * 0.55
		life.mana = life.max_mana() * 0.55
		run.ally_hp = maxf(35.0, run.ally_hp)
		leave()
		game.hud.show_message("Você recuou para a entrada da ruína.")

func _update_enemy(i: int, player: PixelActor, right: Vector3, delta: float) -> void:
	var enemy := enemies[i]
	var actor: PixelActor = enemy.actor
	var home: Vector3 = RuinRun.SPAWNS[i]
	var victim := ally if ally.visible and ally.position.distance_squared_to(actor.position) < 3.7 * 3.7 else player
	var offset := victim.position - actor.position
	var velocity := Vector3.ZERO
	enemy.timer = maxf(0.0, enemy.timer - delta)
	if enemy.mode == "windup":
		if enemy.timer <= 0:
			enemy.mode = "recover"
			enemy.timer = 0.75
			if offset.length() < (2.1 if i == 2 else 1.65) and _line_clear(actor.position + Vector3.UP * 0.8, victim.position + Vector3.UP * 0.8):
				var amount := (18.0 if i == 2 else 9.0) * (1.18 if run.empowered() else 1.0)
				if victim == ally:
					run.ally_hp = maxf(0, run.ally_hp - amount)
				else:
					var life := career.life
					if not life.equipped("armor").is_empty():
						amount *= 0.72
						life.wear("armor")
					if life.role() == "warrior" and Input.is_physical_key_pressed(KEY_SHIFT):
						amount *= 0.32
					life.hp = maxf(0, life.hp - amount)
	elif enemy.mode != "recover" or enemy.timer <= 0:
		var can_follow := offset.length() < 6.1 and actor.position.distance_to(home) < 5.4
		can_follow = can_follow and ((i == 2 and victim.position.x > 60.65) or (i != 2 and victim.position.x < 60.4))
		if can_follow and offset.length() < (1.7 if i == 2 else 1.35):
			enemy.mode = "windup"
			enemy.timer = 0.62 if i == 2 else 0.49
			actor.face(offset)
		elif can_follow:
			enemy.mode = "chase"
			velocity = offset.normalized() * (2.25 if i == 0 else 1.72)
		else:
			enemy.mode = "patrol"
			enemy.phase += delta * 0.85
			var desired := home + Vector3(0.9 * sin(enemy.phase), 0, 0.69 * cos(enemy.phase))
			velocity = (desired - actor.position).limit_length(1.0)
	actor.velocity = velocity
	actor.move_and_slide()
	actor.pose(velocity, right, Color("ffd8b9") if enemy.mode == "windup" else Color("c9bdab"), enemy.mode == "windup")

func _update_ally(player: PixelActor, right: Vector3, delta: float) -> void:
	if not ally.visible:
		return
	ally_attack = maxf(0, ally_attack - delta)
	var index := _closest(player.position)
	var destination := player.position - Vector3.RIGHT * 0.65
	if index >= 0 and player.position.distance_to(enemies[index].actor.position) < 6.0:
		destination = enemies[index].actor.position
	var offset := destination - ally.position
	ally.velocity = offset.normalized() * 2.3 if offset.length() > 1.05 else Vector3.ZERO
	ally.move_and_slide()
	ally.pose(ally.velocity, right, Color("dfd5b8"))
	if ally_attack == 0.0 and index >= 0 and ally.position.distance_to(enemies[index].actor.position) < 1.6:
		ally_attack = 1.1
		ally.gesture()
		run.strike(career.life, index, 13.0)
		refresh()

func _update_bolts(delta: float) -> void:
	for i in range(bolts.size() - 1, -1, -1):
		var shot := bolts[i]
		var node: Node3D = shot.node
		shot.remaining -= delta
		var target: PixelActor = enemies[shot.index].actor
		var destination := target.position + Vector3.UP * 0.80
		var offset := destination - node.position
		var next := node.position + offset.limit_length(17.0 * delta)
		var blocked := not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(node.position, next, 1)).is_empty()
		if blocked or shot.remaining <= 0 or not run.alive(shot.index) or offset.length() <= 17.0 * delta:
			if not blocked and shot.remaining > 0 and offset.length() <= 17.0 * delta:
				run.strike(career.life, shot.index, shot.damage)
				refresh()
			node.queue_free()
			bolts.remove_at(i)
		else:
			node.position = next
			node.look_at(destination)

func _line_clear(origin: Vector3, destination: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(origin, destination, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _clear_bolts() -> void:
	for shot in bolts:
		shot.node.queue_free()
	bolts.clear()

func _closest(position: Vector3) -> int:
	var best := -1
	var distance := INF
	for i in enemies.size():
		if not run.alive(i):
			continue
		var at: Vector3 = enemies[i].actor.position
		var squared := position.distance_squared_to(at)
		if squared < distance:
			distance = squared
			best = i
	return best

func _recover() -> void:
	if run.recover(career.life):
		game.hud.show_message("Cofre recuperado · quatro ferros e experiência.")
	else:
		game.hud.show_message("Derrote a Sentinela e verifique o espaço na bolsa.")

func _wall(at: Vector3, size: Vector3, material := "stone") -> StaticBody3D:
	var root := StaticBody3D.new()
	root.position = at
	add_child(root)
	var hit := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	hit.shape = shape
	root.add_child(hit)
	var display := _box(at, size, material)
	display.reparent(root)
	root.set_meta("facade", display)
	return root

func _box(at: Vector3, size: Vector3, material: String) -> MeshInstance3D:
	var display := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	display.mesh = mesh
	display.position = at
	display.material_override = game.diorama.palette.materials[material]
	add_child(display)
	return display
