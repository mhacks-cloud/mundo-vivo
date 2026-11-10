extends SceneTree

var failed := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/vale.tscn") as PackedScene
	var vale := scene.instantiate()
	vale.save_path = "user://teste_apresentacao_%d.json" % OS.get_process_id()
	vale.onboarding_enabled = false
	root.add_child(vale)
	for i in 5:
		await physics_frame
	var facade: Node3D = vale.diorama.get_node("Fachada0")
	vale.diorama.camera_visibility(Vector3(-6.7, 1.4, -2.1), Vector3(-6.7, 1.0, -10.5))
	_check(not facade.visible, "fachada oclusora temporariamente oculta")
	vale.diorama.camera_visibility(Vector3(-2, 7, 3), Vector3(-2, 1, 2))
	_check(facade.visible, "fachada volta ao sair da linha de visão")
	_press(vale, KEY_F1)
	_check(vale.hud.help_panel.visible, "F1 abre os controles")
	_press(vale, KEY_F10)
	_check(not vale.hud.visible, "F10 oculta toda a interface")
	_press(vale, KEY_F10)
	_check(vale.hud.visible, "F10 restaura a interface")
	_press(vale, KEY_F7)
	_check(not vale.lens_pass.visible, "F7 desativa o efeito")
	_press(vale, KEY_F7)
	_check(vale.lens_pass.visible, "F7 restaura o efeito")
	vale.quality = 0
	vale._refresh_quality()
	var low := _visible_batches(vale.diorama.foliage)
	var low_distance: float = vale.camera.far
	vale.quality = 2
	vale._refresh_quality()
	_check(low < _visible_batches(vale.diorama.foliage) and low_distance < vale.camera.far,
		"perfil baixo reduz vegetação e alcance")
	vale.player.pose(Vector3.FORWARD, Vector3.RIGHT, Color.WHITE)
	_check(vale.player.view_index == 1 and vale.player.visual.animation == &"walk", "sprite de costas animado")
	vale.player.pose(Vector3.LEFT, Vector3.RIGHT, Color.WHITE)
	_check(vale.player.view_index == 2 and vale.player.visual.flip_h, "sprite lateral orientado")
	vale.simulation.clock.elapsed = WorldClock.DAY_SECONDS * (49 + 15.0 / 24.0)
	vale._refresh_environment(1.0)
	_check(vale.hud.date.text.begins_with("OUTONO"), "estação exibida")
	var ground: ShaderMaterial = vale.diorama.ground
	_check(ground.get_shader_parameter("ground_tint") == Color("d9ac69"), "solo recebe a paleta de outono")
	vale.diorama.weather(3, true, false, 0.5)
	_check(is_zero_approx(ground.get_shader_parameter("frost")), "chuva de inverno sem geada automática")
	vale.diorama.weather(3, true, true, 0.5)
	_check(ground.get_shader_parameter("frost") > 0.0, "geada leve quando a simulação indica neve")
	_check(vale.ambience.water.stream is AudioStreamWAV and vale.ambience.hammers.size() == 3,
		"fontes sonoras locais")
	print("%d verificações de apresentação, %d falhas." % [checks, failed])
	quit(1 if failed else 0)

func _visible_batches(foliage: ValeFoliage) -> int:
	var total := 0
	for group in foliage.groups:
		total += 1 if group.visible else 0
	return total

func _press(vale: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = key
	vale._unhandled_input(event)

func _check(passed: bool, label: String) -> void:
	checks += 1
	if passed:
		print("OK ", label)
	else:
		failed += 1
		push_error("FALHA: " + label)
