extends SceneTree

const TEST_SAVE := "user://teste_mundo_vivo.json"
var failed := 0
var checked := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := WorldSimulation.new()
	world.clock.elapsed = 0
	world.tick(7200.0)
	_check(world.clock.day_of_year() == 2 and world.clock.hour() == 0, "120 minutos reais por dia")
	world.tick(7200.0 * 95)
	_check(world.clock.day_of_year() == 1 and world.clock.year() == 2, "virada de ano de 96 dias")
	var seasons := SeasonManager.new()
	for i in 4:
		_check(seasons.index(i * 24, 42) == i and seasons.index(i * 24 + 23, 42) == i
			and seasons.index(i * 24, -42) == (i + 2) % 4, "estação %d, 24 dias e hemisférios" % i)
	var climate := RegionalClimate.new()
	var low := climate.sample(8, 12)
	climate.altitude += 1200
	climate.biome = "floresta"
	var high := climate.sample(8, 12)
	_check(low.temperature > high.temperature and low.humidity != high.humidity, "altitude e bioma no clima")
	climate.latitude = -42
	_check(not is_equal_approx(climate.sample(8, 12).temperature, high.temperature), "hemisfério no clima")
	climate.latitude = -12
	_check(not is_equal_approx(climate.sample(8, 12).temperature, high.temperature), "latitude no clima")
	var saver := SaveManager.new()
	for i in 3:
		world.command(&"deliver_bridge_material")
	var snapshot := world.snapshot()
	snapshot.player = [1.0, 0.1, 2.0]
	_check(saver.write_state(snapshot, TEST_SAVE) == OK, "gravação do salvamento")
	snapshot.player = [2.0, 0.1, 3.0]
	_check(saver.write_state(snapshot, TEST_SAVE) == OK, "substituição do salvamento existente")
	var restored := WorldSimulation.new()
	var state := saver.read_state(TEST_SAVE)
	_check(not state.is_empty() and is_equal_approx(state.player[0], 2.0), "leitura do salvamento")
	if not state.is_empty():
		restored.restore(state)
	_check(restored.clock.year() == 2 and restored.construction.stage == 1
		and restored.construction.delivered == 1, "calendário e etapa após restauração")
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	if file != null:
		file.store_string("{\"version\":1,\"state\":{}}")
		file.close()
	_check(saver.read_state(TEST_SAVE).is_empty(), "rejeição de dados incompletos")
	DirAccess.remove_absolute(TEST_SAVE)

	var scene := load("res://scenes/vale.tscn") as PackedScene
	var vale := scene.instantiate()
	vale.save_path = TEST_SAVE
	vale.onboarding_enabled = false
	root.add_child(vale)
	await _ticks(4)
	_check(vale.camera.current and vale.people.size() == 9, "cena principal, câmera e nove NPCs")
	vale.simulation.construction.restore({})
	vale.simulation.clock.elapsed = 2550
	vale._reset_people()
	vale.target_yaw = 0.0
	vale.yaw = 0.0
	vale.player.position = Vector3(-3, 0.10, 4)
	Input.action_press("up")
	await _ticks(28)
	_check(vale.player.position.z < 2.6 and vale.player.visual.animation == &"walk", "WASD e animação de caminhada")
	Input.action_release("up")
	await _ticks(4)
	_check(vale.player.visual.animation == &"idle", "animação de repouso")
	vale.player.position = Vector3(-6.70, 0.10, -3.7)
	Input.action_press("up")
	await _ticks(75)
	Input.action_release("up")
	_check(vale.player.position.z > -4.40, "colisão na fachada da taberna")
	vale.player.position = Vector3(8.6, 0.10, -12)
	Input.action_press("right")
	await _ticks(72)
	Input.action_release("right")
	_check(vale.player.position.x < 10.0, "obra bloqueia a travessia antes da inauguração")
	vale.player.position = Vector3(8.6, 0.10, 2.0)
	Input.action_press("right")
	await _ticks(160)
	Input.action_release("right")
	_check(vale.player.position.x > 17.5, "ponte de pedra atravessável")
	vale.player.position = Vector3(6.42, 0.10, -13.08)
	_press(vale, KEY_E)
	_check(vale.player.parcel.visible, "E recolhe material no depósito")
	vale.player.position = Vector3(9.42, 0.10, -11.15)
	var before: int = _loads(vale.simulation.construction)
	_press(vale, KEY_E)
	_check(not vale.player.parcel.visible and _loads(vale.simulation.construction) == before + 1,
		"E entrega material na margem")
	_press(vale, KEY_F5)
	var saved_progress: Dictionary = vale.simulation.construction.snapshot()
	vale.player.position = Vector3.ZERO
	vale.simulation.construction.restore({})
	_press(vale, KEY_F9)
	_check(vale.simulation.construction.snapshot() == saved_progress and vale.player.position.x > 9.0,
		"F5/F9 restauram posição e obra")
	DirAccess.remove_absolute(TEST_SAVE)
	var carried := false
	var hammered := false
	for i in 3600:
		await physics_frame
		for npc in vale.people:
			carried = carried or npc.parcel.visible
			hammered = hammered or npc.visual.animation == &"work"
		if vale.simulation.construction.complete():
			break
	_check(carried and hammered, "NPCs transportam madeira e usam animação de trabalho")
	_check(vale.simulation.construction.complete(), "NPCs concluem todas as etapas")
	vale.player.position = Vector3(8.6, 0.10, -12)
	Input.action_press("right")
	await _ticks(160)
	Input.action_release("right")
	_check(vale.player.position.x > 17.5, "ponte nova atravessável após a inauguração")
	var previous_yaw: float = vale.target_yaw
	Input.action_press("orbit_right")
	await _ticks(18)
	Input.action_release("orbit_right")
	_check(not is_equal_approx(previous_yaw, vale.target_yaw), "rotação de câmera")
	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	var previous_distance: float = vale.target_distance
	vale._unhandled_input(wheel)
	_check(vale.target_distance < previous_distance, "zoom da câmera")
	_press(vale, KEY_F6)
	_press(vale, KEY_F7)
	_check(vale.quality == 2 and not vale.focus, "presets gráficos e desfoque")
	var old_hour: float = vale.simulation.clock.hour()
	_press(vale, KEY_T)
	_check(is_equal_approx(vale.simulation.clock.hour(), old_hour + 3), "avanço de três horas")
	vale.simulation.clock.elapsed = 7200 * 21.0 / 24.0
	await _ticks(780)
	var in_bed: bool = vale.people[0].position.distance_to(vale.residents.plans[0].home) < 0.35
	_check(in_bed, "carpinteiro retorna ao ponto de descanso")
	print("%d verificações, %d falhas." % [checked, failed])
	quit(1 if failed else 0)

func _ticks(count: int) -> void:
	for i in count:
		await physics_frame

func _press(vale: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = key
	vale._unhandled_input(event)

func _loads(bridge: ConstructionManager) -> int:
	return [0, 2, 5, 8][bridge.stage] + bridge.delivered

func _check(result: bool, label: String) -> void:
	checked += 1
	if result:
		print("OK ", label)
	else:
		failed += 1
		push_error("FALHA: " + label)
