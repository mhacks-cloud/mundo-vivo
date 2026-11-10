extends Node3D

const SPAWN := Vector3(0.85, 0.10, 4.28)
const QUALITY := ["Baixos", "Médios", "Altos"]
var simulation := WorldSimulation.new()
var residents := NPCManager.new(simulation.construction)
var interactions := InteractionSystem.new()
var saves := SaveManager.new()
var save_path := SaveManager.PATH
var diorama := ValeDiorama.new()
var player := PixelActor.new()
var people: Array[PixelActor] = []
var camera := Camera3D.new()
var sun := DirectionalLight3D.new()
var env := Environment.new()
var atmosphere := ProceduralSkyMaterial.new()
var hud := ValeHUD.new()
var ambience := ValeAudio.new()
var lens_pass := MeshInstance3D.new()
var wet_blend := 0.0
var raining := false
var lens: ShaderMaterial
var precipitation: ShaderMaterial
var follow := SPAWN + Vector3(0, 0.65, -2.15)
var yaw := 0.19
var target_yaw := yaw
var distance := 25.0
var target_distance := distance
var sprite_light := Color.WHITE
var quality := 1
var focus := true
var hidden_marker := Label3D.new()
var bridge_target: Dictionary
var last_climate_update := 0.0
var visual_time := 0.0

func _ready() -> void:
	_configure_inputs()
	var region: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regiao.json"))
	simulation.climate.latitude = region.latitude
	simulation.climate.altitude = region.altitude
	simulation.climate.biome = region.bioma
	add_child(diorama)
	add_child(camera)
	camera.current = true
	camera.fov = 42.0
	camera.far = 115.0
	_setup_light()
	_setup_overlays()
	add_child(hud)
	add_child(ambience)
	simulation.construction.changed.connect(_bridge_changed)
	player.configure(Color("417b89"), Color("dfaf62"), 0, true)
	player.position = SPAWN
	add_child(player)
	var ears := AudioListener3D.new()
	ears.position.y = 0.85
	player.add_child(ears)
	ears.make_current()
	hidden_marker.text = "◆"
	hidden_marker.font_size = 26
	hidden_marker.outline_size = 6
	hidden_marker.pixel_size = 0.009
	hidden_marker.modulate = Color("f1d999")
	hidden_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hidden_marker.no_depth_test = true
	hidden_marker.position.y = 1.72
	player.add_child(hidden_marker)
	hidden_marker.hide()
	for plan in residents.plans:
		var npc := PixelActor.new()
		npc.name = plan.name
		npc.configure(Color(plan.palette), Color(plan.hair), plan.hat, false)
		add_child(npc)
		people.append(npc)
		var person := npc
		var resident: Dictionary = plan
		interactions.register("Conversar com " + plan.name, Vector3.ZERO,
			func() -> void: _talk(resident), 1.65)
		interactions.targets.back()["actor"] = person
	_register_landmarks()
	_load(false)
	_reset_people()
	_camera_frame(1.0)
	_refresh_quality()
	_refresh_environment(0.16)
	hud.update_bridge(simulation.construction)
	hud.show_message("Siga pela praça. Os carpinteiros trabalham rio acima.", 5.5)

func _process(delta: float) -> void:
	simulation.tick(delta)
	visual_time += delta
	_camera_frame(delta)
	last_climate_update += delta
	if last_climate_update >= 0.10:
		_refresh_environment(last_climate_update)
		last_climate_update = 0.0
	var target := interactions.closest(player.position)
	hud.prompt(String(target.get("label", "")))

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("left", "right", "up", "down")
	var right := camera.global_basis.x
	var forward := Vector3.UP.cross(right)
	var move := right * input.x - forward * input.y
	player.velocity = move * 3.65
	player.move_and_slide()
	player.pose(player.get_real_velocity(), right, sprite_light)
	hidden_marker.visible = diorama.camera_visibility(camera.position, player.position + Vector3.UP * 0.83)
	for i in people.size():
		var npc := people[i]
		var plan := residents.plans[i]
		interactions.targets[i].position = npc.position
		var hour := simulation.clock.hour()
		plan.wait = maxf(0.0, plan.wait - delta)
		var offset := residents.goal(plan, hour) - npc.position
		npc.velocity = Vector3.ZERO
		if plan.wait <= 0.0:
			if offset.length_squared() <= 0.12 * 0.12:
				if residents.arrived(plan, hour):
					simulation.command(&"deliver_bridge_material")
			else:
				npc.velocity = offset.normalized() * minf(1.65, offset.length() / delta)
		npc.move_and_slide()
		npc.parcel.visible = plan.carry
		npc.pose(npc.get_real_velocity(), right, sprite_light, plan.building)
	ambience.listen(player, people, simulation.clock.hour(), raining, delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interactions.interact(player.position)
	elif event.is_action_pressed("save_game"):
		_save()
	elif event.is_action_pressed("load_game"):
		_load(true)
	elif event.is_action_pressed("quality"):
		quality = (quality + 1) % QUALITY.size()
		_refresh_quality()
	elif event.is_action_pressed("focus"):
		focus = not focus
		_refresh_quality()
	elif event.is_action_pressed("toggle_hud"):
		hud.visible = not hud.visible
	elif event.is_action_pressed("help"):
		hud.toggle_help()
	elif event.is_action_pressed("skip_time"):
		simulation.tick(WorldClock.DAY_SECONDS / 8.0)
		_refresh_environment(0.16)
		hud.show_message("Três horas se passaram. Agora são " + simulation.clock.time_text() + ".")
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance = maxf(11.0, target_distance - 2.2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance = minf(32.0, target_distance + 2.2)

func _configure_inputs() -> void:
	var bindings := {"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S,
		"interact": KEY_E, "orbit_left": KEY_Q, "orbit_right": KEY_R, "save_game": KEY_F5,
		"quality": KEY_F6, "focus": KEY_F7, "load_game": KEY_F9, "skip_time": KEY_T,
		"toggle_hud": KEY_F10, "help": KEY_F1}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action, event)

func _camera_frame(delta: float) -> void:
	target_yaw = wrapf(target_yaw + Input.get_axis("orbit_left", "orbit_right") * 1.34 * delta, -PI, PI)
	yaw = lerp_angle(yaw, target_yaw, 1.0 - exp(-10.0 * delta))
	distance = lerpf(distance, target_distance, 1.0 - exp(-9.0 * delta))
	var radial := Vector3(sin(yaw), 0, cos(yaw))
	var point := player.position + Vector3.UP * 0.65 - radial * (distance * 0.09)
	follow = follow.lerp(point, 1.0 - exp(-5.2 * delta))
	camera.position = follow + (radial * 0.868 + Vector3.UP * 0.497) * distance
	camera.look_at(follow, Vector3.UP)
	lens.set_shader_parameter("focal_distance", -camera.to_local(player.position + Vector3.UP * 0.70).z)

func _setup_light() -> void:
	var sky := Sky.new()
	sky.sky_material = atmosphere
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dfebdd")
	env.ambient_light_energy = 0.45
	env.ambient_light_sky_contribution = 0.0
	env.fog_enabled = true
	env.fog_density = 0.004
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 72
	sun.directional_shadow_fade_start = 0.79
	sun.shadow_blur = 1.8
	sun.shadow_bias = 0.035
	sun.shadow_normal_bias = 0.55
	add_child(sun)

func _setup_overlays() -> void:
	var effects := CanvasLayer.new()
	effects.layer = 1
	add_child(effects)
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	lens = ShaderMaterial.new()
	lens.shader = preload("res://shaders/lens.gdshader")
	lens.render_priority = -10
	lens_pass.mesh = quad
	lens_pass.material_override = lens
	lens_pass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lens_pass.extra_cull_margin = 16384.0
	camera.add_child(lens_pass)
	precipitation = _effect(effects, preload("res://shaders/precipitation.gdshader"))

func _effect(parent: CanvasLayer, shader: Shader) -> ShaderMaterial:
	var surface := ColorRect.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var effect := ShaderMaterial.new()
	effect.shader = shader
	surface.material = effect
	return effect

func _refresh_environment(delta: float) -> void:
	var hour := simulation.clock.hour()
	var solar := sin((hour - 6.0) * TAU / 24.0)
	var light := smoothstep(-0.20, 0.64, solar)
	var golden := (1.0 - smoothstep(0.18, 0.75, solar)) * smoothstep(-0.20, 0.05, solar)
	var climate := simulation.climate.sample(simulation.clock.total_day(), hour)
	var wet: bool = climate.weather == "Chuva" or climate.weather == "Neve"
	var mist: bool = climate.weather == "Névoa"
	raining = wet
	wet_blend = lerpf(wet_blend, 1.0 if wet else 0.0, clampf(delta * 1.9, 0.0, 1.0))
	var season_index := simulation.climate.seasons.index(simulation.clock.total_day(), simulation.climate.latitude)
	diorama.weather(season_index, wet, climate.weather == "Neve", light)
	var fog := Color("222d48").lerp(Color("7d9ea1"), light)
	sun.rotation_degrees = Vector3(-15.0 - maxf(0.0, solar) * 49.0, -66.0 - (hour - 8.5) * 8.5, 0)
	sun.light_color = Color("8d9bd0").lerp(Color("fff0d7").lerp(Color("ffc28a"), golden), light)
	sun.light_energy = (0.12 + light * 0.79) * (1.0 - wet_blend * 0.38)
	env.ambient_light_color = Color("8196c8").lerp(Color("bfcfca"), light)
	env.ambient_light_energy = 0.36 + light * 0.18
	atmosphere.sky_top_color = Color("10182f").lerp(Color("679fb2"), light)
	atmosphere.sky_horizon_color = fog
	atmosphere.ground_horizon_color = fog
	atmosphere.ground_bottom_color = Color("26353c").lerp(Color("738060"), light)
	env.fog_light_color = fog
	env.fog_density = 0.0023 + wet_blend * 0.014 + (0.009 if mist else 0.0)
	precipitation.set_shader_parameter("strength", wet_blend * 0.78)
	precipitation.set_shader_parameter("snow", climate.weather == "Neve")
	for lamp in diorama.lanterns:
		lamp.light_energy = float(lamp.get_meta("base_energy")) * (1.02 - light * 0.83)
		lamp.light_energy *= 0.96 + 0.06 * sin(visual_time * 5.0 + lamp.position.x)
	for halo in diorama.halos:
		halo.modulate.a = (0.8 - light * 0.73) * (0.94 + sin(visual_time * 3.4 + halo.position.x) * 0.06)
	diorama.palette.materials.glass.emission_energy_multiplier = lerpf(0.92, 0.22, light)
	sprite_light = sprite_light.lerp(Color("768bb1").lerp(Color("fff2da"), light * (1.0 - wet_blend * 0.19)), clampf(delta * 3.0, 0.0, 1.0))
	hud.update_clock(simulation.clock,
		simulation.climate.seasons.name_for(simulation.clock.total_day(), simulation.climate.latitude), climate)

func _refresh_quality() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if quality == 0 else Viewport.MSAA_2X if quality == 1 else Viewport.MSAA_4X
	sun.shadow_enabled = quality > 0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if quality == 2 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 62.0 if quality == 2 else 38.0
	sun.shadow_blur = 2.1 if quality == 2 else 1.55
	camera.far = [59.0, 83.0, 115.0][quality]
	diorama.foliage.quality(quality)
	env.fog_enabled = quality > 0
	for lamp in diorama.lanterns:
		lamp.visible = quality > 0
	for halo in diorama.halos:
		halo.visible = quality > 0
	lens_pass.visible = quality > 0 and focus
	lens.set_shader_parameter("strength", 1.02 if quality == 2 else 0.67)
	hud.update_options(QUALITY[quality], focus)

func _register_landmarks() -> void:
	interactions.register("Poço dos Fundadores", Vector3(0.8, 0.1, -0.8),
		func() -> void: hud.show_message("A água do Amieiro é fria mesmo no auge do verão."), 2.6)
	interactions.register("Taberna da Raposa Dourada", Vector3(-6.7, 0.10, -3.95),
		func() -> void: hud.show_message("A Raposa Dourada · pão de centeio e sidra da colheita."))
	interactions.register("Forja do Amieiro", Vector3(-11.1, 0.10, 5.25),
		func() -> void: hud.show_message("Baltasar mantém as ferramentas da obra afiadas."))
	interactions.register("Horta de Teresa", Vector3(-10.22, 0.10, 8.7),
		func() -> void: hud.show_message("As primeiras mudas dividem os canteiros com as ervas da taberna."))
	interactions.register("Ruína da Serra", Vector3(21, 0.10, -18.4),
		func() -> void: hud.show_message("Uma corrente de ar frio escapa da entrada. O portal está selado."), 2.9)
	interactions.register("Canteiro · entregar uma carga", Vector3(9.1, 0.10, -12.0),
		func() -> void:
			if simulation.construction.complete():
				hud.show_message("A ponte nova está aberta. Pode atravessar.")
			elif not player.parcel.visible:
				hud.show_message("Pegue madeira na pilha, junto ao caminho a oeste.")
			elif simulation.command(&"deliver_bridge_material"):
				player.parcel.hide()
				hud.show_message("Carga entregue à obra. " + simulation.construction.status()), 1.72)
	bridge_target = interactions.targets.back()
	interactions.register("Pilha de madeira · pegar uma carga", Vector3(6.4, 0.10, -12.8),
		func() -> void:
			if simulation.construction.complete():
				hud.show_message("A madeira que sobrou fica para o próximo reparo.")
			else:
				player.parcel.show()
				hud.show_message("Leve a madeira até a margem da ponte nova."), 1.8)
	interactions.register("Obra da ponte", Vector3(17.35, 0.10, -12.0),
		func() -> void: hud.show_message(simulation.construction.status()))

func _talk(plan: Dictionary) -> void:
	var person := people[residents.plans.find(plan)]
	person.face(player.position - person.position)
	player.face(person.position - player.position)
	plan.wait = maxf(plan.wait, 1.3)
	var text_value: String
	if plan.worker:
		text_value = "A última tábua já foi assentada." if simulation.construction.complete() else "A madeira é do bosque. Ajude a levar uma carga à margem."
	elif residents.working(plan, simulation.clock.hour()):
		text_value = {"Lina": "Passe na Raposa quando a luz baixar.", "Baltasar": "As ferramentas da ponte saíram desta forja.",
			"Teresa": "A terra ainda guarda o frio da madrugada.", "Nilo": "Depois da ponte de pedra, siga o caminho para o norte."}[plan.name]
	else:
		text_value = "Amanhã nos vemos de novo na vila."
	hud.show_message("%s, %s  ·  %s" % [plan.name, plan.job, text_value])

func _reset_people() -> void:
	residents.reset()
	for i in people.size():
		var plan := residents.plans[i]
		people[i].position = plan.route[0] if residents.working(plan, simulation.clock.hour()) else plan.home
		if not residents.working(plan, simulation.clock.hour()):
			plan.exit_index = plan.exit.size()
			plan.returning = true
		interactions.targets[i].position = people[i].position

func _bridge_changed() -> void:
	if simulation.construction.complete():
		player.parcel.hide()
	if not diorama.has_meta("bridge_stage") or diorama.get_meta("bridge_stage") != simulation.construction.stage:
		diorama.set_meta("bridge_stage", simulation.construction.stage)
		diorama.update_bridge(simulation.construction.stage)
	bridge_target.label = "Ponte nova" if simulation.construction.complete() else "Canteiro · entregar uma carga"
	hud.update_bridge(simulation.construction)

func _save() -> void:
	var state := simulation.snapshot()
	state["carrying"] = player.parcel.visible
	state["player"] = [player.position.x, player.position.y, player.position.z]
	var result := saves.write_state(state, save_path)
	hud.show_message("Vale salvo." if result == OK else "Falha ao salvar · " + error_string(result))

func _load(show_feedback: bool) -> void:
	var state := saves.read_state(save_path)
	if state.is_empty():
		if show_feedback:
			hud.show_message("Nenhum salvamento válido para carregar.")
		return
	simulation.restore(state)
	player.parcel.visible = state.get("carrying", false) == true and not simulation.construction.complete()
	player.position = Vector3(state.player[0], 0.10, state.player[2])
	follow = player.position + Vector3.UP * 0.65
	if show_feedback:
		_reset_people()
		hud.show_message("Vale restaurado · " + simulation.clock.time_text())
