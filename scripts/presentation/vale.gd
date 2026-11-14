extends Node3D

const SPAWN := Vector3(0.85, 0.10, 4.28)
const QUALITY := ["Baixos", "Médios", "Altos"]
var simulation := WorldSimulation.new()
var residents := NPCManager.new(simulation)
var navigation := VillageNavigation.new()
var paths: Array[Dictionary] = []
var nav_dirty := true
var offline_limit := 0.0
var fauna := ValeFauna.new()
var forge_sparks := GPUParticles3D.new()
var social_poll := 0.0
var interactions := InteractionSystem.new()
var saves := SaveManager.new()
var save_path := SaveManager.PATH
var onboarding_enabled := true
var career := ValeLife.new()
var realms := ValeRealms.new()
var markets := EconomyManager.new()
var society := TownSociety.new()
var diorama := ValeDiorama.new()
var world_editor := WorldEditor.new(self)
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
var preferences := {"resolution": 1, "fullscreen": false, "quality": 1, "volume": 1.0, "sensitivity": 1.0}

func _ready() -> void:
	_configure_inputs()
	var region: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regiao.json"))
	simulation.climate.latitude = region.latitude
	simulation.climate.altitude = region.altitude
	simulation.climate.biome = region.bioma
	offline_limit = clampf(float(region.get("limite_offline_minutos", 0.0)) * 60.0, 0.0, 7200.0)
	diorama.edits = WorldEditStore.read()
	add_child(diorama)
	add_child(camera)
	camera.current = true
	camera.fov = 42.0
	camera.far = 115.0
	_setup_light()
	_setup_overlays()
	add_child(hud)
	add_child(world_editor)
	add_child(ambience)
	add_child(fauna)
	_setup_sparks()
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
		npc.configure(Color(plan.palette), Color(plan.hair), plan.hat, false, plan.role)
		add_child(npc)
		people.append(npc)
		paths.append({})
		var person := npc
		var resident: Dictionary = plan
		interactions.register("Conversar com " + plan.name, Vector3.ZERO,
			func() -> void: _talk(resident), 1.65)
		interactions.targets.back()["actor"] = person
	_register_landmarks()
	add_child(career)
	career.setup(self)
	add_child(realms)
	realms.setup(self)
	residents.society = society
	interactions.register("Praça · Feira da Colheita", Vector3(0.9, 0.1, 3.4), _visit_fair, 1.45)
	realms.world.diplomacy = markets.diplomacy
	if onboarding_enabled and save_path == SaveManager.PATH:
		_reset_people()
		career.start_menu()
	else:
		if not _load(false):
			_reset_people()
		if onboarding_enabled:
			career.start_setup()
	_camera_frame(1.0)
	_load_preferences()
	_refresh_quality()
	_refresh_environment(0.16)
	hud.update_bridge(simulation.construction, career.authority.works.road_closed)
	hud.show_message("A vila está em movimento. J abre o diário do vale.", 5.5)

func _process(delta: float) -> void:
	_camera_frame(delta)
	if world_editor.active:
		return
	career.tick(delta)
	if not career.setup_stage.is_empty():
		return
	simulation.tick(delta)
	visual_time += delta
	last_climate_update += delta
	if last_climate_update >= 0.10:
		_refresh_environment(last_climate_update)
		last_climate_update = 0.0
	var target := interactions.closest(player.position)
	hud.prompt(String(target.get("label", "")))

func _physics_process(delta: float) -> void:
	if world_editor.active:
		return
	if not career.setup_stage.is_empty():
		return
	career.physics(delta)
	if career.active():
		markets.tick(self)
		society.advance(self)
	realms.tick(delta)
	var input := Vector2.ZERO if career.authority.detained() or realms.map.visible else Input.get_vector("left", "right", "up", "down")
	var right := camera.global_basis.x
	var forward := Vector3.UP.cross(right)
	var move := right * input.x - forward * input.y
	player.velocity = move * 3.65
	player.move_and_slide()
	player.pose(player.get_real_velocity(), right, sprite_light)
	var local_diorama: ValeDiorama = realms.scene if realms.world.active else diorama
	hidden_marker.visible = local_diorama.camera_visibility(camera.position, player.position + Vector3.UP * 0.83)
	if nav_dirty:
		navigation.rebuild(diorama, simulation.construction.complete() and not career.authority.works.road_closed)
		nav_dirty = false
	for i in people.size():
		if residents.plans[i].id == "beatriz" and society.migration >= 4:
			people[i].hide()
			continue
		_move_resident(i, right, delta)
	social_poll += delta
	if social_poll >= 0.5:
		social_poll = 0.0
		residents.social()
	var smith_working: bool = residents.plans[3].building
	forge_sparks.emitting = smith_working and quality > 0
	fauna.update_animals(player.position, right, sprite_light, delta, ambience)
	ambience.listen(player, people, simulation.clock.hour(), raining, delta)

func _move_resident(index: int, right: Vector3, delta: float) -> void:
	var npc := people[index]
	var plan := residents.plans[index]
	var cache := paths[index]
	var distant := npc.position.distance_squared_to(player.position) > 27.0 * 27.0
	var step: float = float(cache.get("step", 0.0)) + delta
	cache.step = step
	if distant and step < 0.105:
		return
	cache.step = 0.0
	cache.retry = maxf(0.0, float(cache.get("retry", 0.0)) - step)
	var goal := residents.goal(plan, raining, step)
	var movement := Vector3.ZERO
	if plan.talk > 0.0:
		plan.state = "INTERACTING"
	else:
		if cache.get("goal") != goal or cache.get("revision") != navigation.revision or (cache.get("failed", false) and cache.retry <= 0.0):
			cache.goal = goal
			cache.revision = navigation.revision
			cache.route = navigation.find(npc.position, goal)
			cache.cursor = 0
			cache.failed = cache.route.is_empty()
			cache.retry = 0.70
		var route: PackedVector3Array = cache.route
		if not route.is_empty():
			var cursor: int = cache.cursor
			if cursor < route.size() and npc.position.distance_squared_to(route[cursor]) <= 0.11 * 0.11:
				cursor += 1
				cache.cursor = cursor
			if cursor >= route.size():
				residents.arrived(plan)
			else:
				residents.moving(plan)
				if plan.worker and plan.carry:
					simulation.construction.logistics(2)
				var offset := route[cursor] - npc.position
				var origin := npc.position
				var hit := npc.move_and_collide(offset.limit_length((2.03 if plan.role == "carrier" else 1.86) * step))
				movement = (npc.position - origin) / step
				if hit != null and movement.length_squared() < 0.02 and cache.retry <= 0.0:
					cache.failed = true
					cache.retry = 0.22
		else:
			residents.moving(plan)
	plan.position = npc.position
	interactions.targets[index].position = npc.position
	npc.set_cargo(simulation.economy.stock.first(plan.id))
	npc.pose(movement, right, sprite_light, plan.building, plan.state)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F8 and world_editor.allowed():
		if world_editor.active:
			world_editor.close()
		else:
			world_editor.open()
		return
	if world_editor.active:
		world_editor.handle(event)
		return
	if career.setup_stage.is_empty() and career.active():
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_P:
			career.ui.hide_panel()
			realms.map.toggle()
			return
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_K and not realms.map.visible:
			career.ui.open("economy")
			return
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_U and not realms.map.visible:
			career.ui.open("society")
			return
		if realms.map.visible:
			if event.is_action_pressed("ui_cancel"):
				realms.map.hide()
			return
	if career.input_event(event):
		return
	if event.is_action_pressed("interact"):
		player.gesture()
		interactions.interact(player.position)
	elif event.is_action_pressed("satchel"):
		hud.inspect("Viajante", "Carga em trânsito", simulation.economy.stock.summary("player"), "player")
	elif event.is_action_pressed("ui_cancel") and hud.inspection.visible:
		hud.inspection.hide()
	elif event.is_action_pressed("journal"):
		hud.inspect("Diário do Vale", "Ocorrências registradas", simulation.economy.journal.recent(5))
	elif event.is_action_pressed("save_game"):
		_save()
	elif event.is_action_pressed("load_game"):
		_load(true)
	elif event.is_action_pressed("quality"):
		preferences.quality = (quality + 1) % QUALITY.size()
		apply_preferences()
	elif event.is_action_pressed("focus"):
		focus = not focus
		_refresh_quality()
	elif event.is_action_pressed("toggle_hud"):
		hud.visible = not hud.visible
		career.ui.visible = hud.visible
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
		"toggle_hud": KEY_F10, "help": KEY_F1, "journal": KEY_J, "satchel": KEY_I}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action, event)

func _camera_frame(delta: float) -> void:
	target_yaw = wrapf(target_yaw + Input.get_axis("orbit_left", "orbit_right") * 1.34 * float(preferences.sensitivity) * delta, -PI, PI)
	yaw = lerp_angle(yaw, target_yaw, 1.0 - exp(-10.0 * delta))
	distance = lerpf(distance, target_distance, 1.0 - exp(-9.0 * delta))
	var radial := Vector3(sin(yaw), 0, cos(yaw))
	var point := world_editor.view_center if world_editor.active else career.camera_point(player.position + Vector3.UP * 0.65 - radial * (distance * 0.09))
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
	var day := simulation.clock.total_day()
	var valley := simulation.climate.sample(day, hour)
	raining = valley.weather in ["Chuva", "Neve"]
	if valley.weather == "Chuva":
		simulation.economy.rain(simulation.clock)
	var at := player.position
	var underground := RuinRun.inside(at)
	var on_frontier := at.x > 16.8 and at.x < 33.0 and at.z < -4.0
	var in_bruma := realms.world.active
	var location := realms.world.current(at)
	var region := realms.world.regional_climate(location, simulation.climate, career.frontier.climate)
	var climate := valley if region == simulation.climate else region.sample(day, hour)
	if in_bruma or location == "forest":
		raining = climate.weather in ["Chuva", "Neve"]
	var wet: bool = climate.weather in ["Chuva", "Neve"]
	var mist: bool = climate.weather == "Névoa"
	var crop := simulation.economy.crop
	if crop == 3 and simulation.clock.elapsed >= simulation.economy.crop_due:
		crop = 4
	diorama.update_crop(crop)
	wet_blend = lerpf(wet_blend, 1.0 if wet else 0.0, clampf(delta * 1.9, 0.0, 1.0))
	var season_index := region.seasons.index(day, region.latitude)
	diorama.weather(season_index, wet, climate.weather == "Neve", light)
	if in_bruma and is_instance_valid(realms.scene):
		realms.scene.weather(season_index, wet, climate.weather == "Neve", light)
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
	precipitation.set_shader_parameter("strength", 0.0 if underground else wet_blend * 0.78)
	precipitation.set_shader_parameter("snow", climate.weather == "Neve")
	for lamp in diorama.lanterns:
		lamp.light_energy = float(lamp.get_meta("base_energy")) * (1.02 - light * 0.83)
		lamp.light_energy *= 0.96 + 0.06 * sin(visual_time * 5.0 + lamp.position.x)
	for halo in diorama.halos:
		halo.modulate.a = (0.8 - light * 0.73) * (0.94 + sin(visual_time * 3.4 + halo.position.x) * 0.06)
	diorama.palette.materials.glass.emission_energy_multiplier = lerpf(0.92, 0.22, light)
	sprite_light = sprite_light.lerp(Color("768bb1").lerp(Color("fff2da"), light * (1.0 - wet_blend * 0.19)), clampf(delta * 3.0, 0.0, 1.0))
	env.background_mode = Environment.BG_COLOR if underground else Environment.BG_SKY
	if underground:
		env.background_color = Color("111419")
		env.ambient_light_color = Color("aeb2c3")
		env.ambient_light_energy = 0.33
		env.fog_density = 0.006
		env.fog_light_color = Color("1b1d26")
		sun.light_energy = 0.13
	hud.region_title.text = RealmWorld.PLACES[location].name if in_bruma or location == "forest" else "Ruína da Serra" if underground else "Brumária" if on_frontier else "Vale do Amieiro"
	hud.update_clock(simulation.clock,
		region.seasons.name_for(day, region.latitude), climate)

func _load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load("user://preferences.cfg") != OK:
		return
	preferences.resolution = int(LifeCatalog.number(config.get_value("game", "resolution", 1), 1, 0, 2))
	preferences.quality = int(LifeCatalog.number(config.get_value("game", "quality", 1), 1, 0, 2))
	preferences.fullscreen = config.get_value("game", "fullscreen", false) == true
	preferences.volume = LifeCatalog.number(config.get_value("game", "volume", 1.0), 1.0, 0.0, 1.0)
	preferences.sensitivity = LifeCatalog.number(config.get_value("game", "sensitivity", 1.0), 1.0, 0.4, 2.0)
	_apply_preferences()

func apply_preferences() -> void:
	_apply_preferences()
	var config := ConfigFile.new()
	for id in preferences:
		config.set_value("game", id, preferences[id])
	var result := config.save("user://preferences.cfg")
	if result != OK:
		hud.show_message("Configurações aplicadas, mas não gravadas.")

func _apply_preferences() -> void:
	quality = preferences.quality
	_refresh_quality()
	AudioServer.set_bus_volume_linear(0, preferences.volume)
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	window.mode = Window.MODE_FULLSCREEN if preferences.fullscreen else Window.MODE_WINDOWED
	if not preferences.fullscreen:
		window.size = [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900)][preferences.resolution]

func _refresh_quality() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if quality == 0 else Viewport.MSAA_2X if quality == 1 else Viewport.MSAA_4X
	sun.shadow_enabled = quality > 0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if quality == 2 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 62.0 if quality == 2 else 38.0
	sun.shadow_blur = 2.1 if quality == 2 else 1.55
	camera.far = [59.0, 83.0, 115.0][quality]
	diorama.foliage.quality(quality)
	for plant in diorama.editable_foliage:
		plant.quality(quality)
	diorama.set_urban_quality(quality)
	if is_instance_valid(realms.scene):
		realms.scene.foliage.quality(quality)
		realms.scene.set_urban_quality(quality)
	env.fog_enabled = quality > 0
	for lamp in diorama.lanterns:
		lamp.visible = quality > 0
	for halo in diorama.halos:
		halo.visible = quality > 0
	lens_pass.visible = quality > 0 and focus
	lens.set_shader_parameter("strength", 1.02 if quality == 2 else 0.67)
	hud.update_options(QUALITY[quality], focus)

func _setup_sparks() -> void:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3.UP
	material.spread = 34.0
	material.gravity = Vector3(0, -5.0, 0)
	material.initial_velocity_min = 0.85
	material.initial_velocity_max = 2.2
	var ember := StandardMaterial3D.new()
	ember.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember.albedo_color = Color("ffc07c")
	ember.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var quad := QuadMesh.new()
	quad.size = Vector2(0.035, 0.035)
	quad.material = ember
	forge_sparks.amount = 14
	forge_sparks.lifetime = 0.58
	forge_sparks.position = Vector3(-11.36, 0.78, 4.77)
	forge_sparks.process_material = material
	forge_sparks.draw_pass_1 = quad
	forge_sparks.emitting = false
	add_child(forge_sparks)

func _register_landmarks() -> void:
	interactions.register("Poço dos Fundadores", diorama.editable_objects.founders_well.root.position + Vector3.UP * 0.1,
		func() -> void: hud.show_message("A água do Amieiro é fria mesmo no auge do verão."), 2.6)
	interactions.register("Taberna da Raposa Dourada", Vector3(-6.7, 0.10, -3.95),
		func() -> void: hud.inspect("Raposa Dourada", "Refeições · 12:00–14:00",
			"Pão de centeio e sidra da colheita. Os moradores fazem aqui a pausa do meio-dia."))
	interactions.register("Forja do Amieiro", Vector3(-11.1, 0.10, 5.25),
		func() -> void:
			if career.active(): career.open_near("forge")
			else: _stock_card("Forja do Amieiro", VillageEconomy.FORGE_HOURS, "forge"))
	interactions.register("Horta de Teresa", Vector3(-10.22, 0.10, 8.7),
		func() -> void: _stock_card("Horta de Teresa", "06:00–18:00 · " + VillageEconomy.CROP_NAMES[simulation.economy.crop], "farm"))
	interactions.register("Entrar na Ruína da Serra", Vector3(21, 0.10, -18.4),
		func() -> void:
			if career.active():
				career.ruin.enter()
			else:
				hud.show_message("Crie um personagem para explorar a galeria."), 2.9)
	interactions.register("Canteiro · entregar uma carga", Vector3(9.1, 0.10, -12.0),
		func() -> void:
			var bridge := simulation.construction
			if bridge.complete():
				_bridge_card()
			elif not simulation.economy.stock.first("player").is_empty() and simulation.unload_build("player"):
				player.set_cargo("")
				simulation.work_bridge()
				hud.show_message("Carga descarregada · " + bridge.status())
			elif bridge.phase() == 9 and simulation.work_bridge():
				hud.show_message("Inspeção concluída. Travessia aberta.")
			else:
				_bridge_card(), 1.72)
	bridge_target = interactions.targets.back()
	interactions.register("Depósito · recolher carga", Vector3(6.4, 0.10, -12.8),
		func() -> void:
			if simulation.reserve_build("player"):
				simulation.construction.logistics(2)
				var item := simulation.economy.stock.first("player")
				player.set_cargo(item)
				hud.show_message("Leve %s ao canteiro, na margem." % item)
			else:
				_stock_card("Depósito da Ponte", "Estoque público", "depot"), 1.8)
	interactions.register("Obra da ponte", Vector3(17.35, 0.10, -12.0), _bridge_card)
	interactions.register("Banca de Lina", Vector3(-7.12, 0.10, -0.15),
		func() -> void:
			if career.active(): career.open_near("store")
			else: _stock_card("Banca de Lina", VillageEconomy.MARKET_HOURS, "market"), 1.65)
	interactions.register("Quadro de estoques", Vector3(3.8, 0.10, -3.72),
		func() -> void:
			if career.active():
				career.open_near("contracts")
			var store := simulation.economy.stock
			hud.inspect("Estoques do vale", "Quadro público",
				"Horta · %s\nForja · %s\nBanca · %s\nDepósito · %s" % [
				store.summary("farm"), store.summary("forge"), store.summary("market"), store.summary("depot")]), 1.65)

func _stock_card(title: String, hours: String, place: String) -> void:
	var hour := simulation.clock.hour()
	var start := 6.0 if place == "farm" else 7.0
	var finish := 19.0 if place == "market" else 18.0
	var status := "Aberto" if hour >= start and hour < finish else "Fechado"
	var subtitle := hours if place == "depot" else "%s · %s" % [status, hours]
	hud.inspect(title, subtitle, simulation.economy.stock.summary(place))

func _bridge_card() -> void:
	var bridge := simulation.construction
	var required := "Travessia aberta." if bridge.complete() else "Próximo recurso: " + bridge.required_item() + "."
	hud.inspect("Ponte Nova", bridge.status(), required + "\nCanteiro · " + simulation.economy.stock.summary("site"))

func _visit_fair() -> void:
	if not career.active() or not society.fair_open(simulation.clock):
		hud.show_message("Feira da Colheita · dia 11 de cada estação, das 08:00 às 19:00.")
		return
	hud.show_message("Ração comprada por 2 ouro." if society.buy_fair(career.life, simulation.clock) else "A feira está sem rações, ou falta espaço ou ouro.")

func _talk(plan: Dictionary) -> void:
	var person := people[residents.plans.find(plan)]
	person.face(player.position - person.position)
	player.face(person.position - player.position)
	plan.talk = 2.7
	var topic := String(plan.detail)
	if plan.worker and not simulation.construction.complete():
		topic = simulation.construction.phase_name() + " · Próximo recurso: " + simulation.construction.required_item() + "."
	elif raining:
		topic = "A correnteza está mais forte. Vou esperar a chuva passar." if plan.role != "guard" else "Hoje reforço a vigia perto do rio."
	var hours := "%02d:%02d–%02d:%02d" % [int(plan.start), int(fposmod(plan.start, 1.0) * 60.0),
		int(plan.end), int(fposmod(plan.end, 1.0) * 60.0)]
	var home: Vector3 = plan.home
	var residence := "Margem leste" if home.x > 16 else "Casas do sul" if home.z > 8 else "Núcleo da vila"
	hud.inspect(plan.name, "%s  ·  %s" % [plan.job.capitalize(), NPCManager.STATES[plan.state]],
		"%s\nExpediente %s · %s\nFome %d%% · Cansaço %d%%" % [
			topic, hours, residence, roundi(plan.hunger * 100.0), roundi(plan.fatigue * 100.0)], plan.id)

func _reset_people() -> void:
	residents.reset()
	for plan in residents.plans:
		if residents.working(plan, simulation.clock.hour()) and plan.role in ["builder", "farm", "forge", "market"]:
			plan.position = plan.route[0]
	_apply_people()

func _apply_people() -> void:
	for i in people.size():
		var plan := residents.plans[i]
		people[i].position = plan.position
		people[i].set_cargo(simulation.economy.stock.first(plan.id))
		interactions.targets[i].position = people[i].position
		paths[i].clear()

func _bridge_changed() -> void:
	var bridge := simulation.construction
	if bridge.complete():
		player.set_cargo("")
	if diorama.get_meta("bridge_phase", -1) != bridge.phase():
		var was_open: bool = diorama.get_meta("bridge_open", false)
		diorama.set_meta("bridge_open", bridge.complete())
		diorama.set_meta("bridge_phase", bridge.phase())
		diorama.update_bridge(bridge.stage, bridge.phase())
		if was_open != bridge.complete():
			nav_dirty = true
	bridge_target.label = "Ponte nova" if bridge.complete() else "Canteiro · entregar uma carga"
	hud.update_bridge(bridge, career.authority.works.road_closed)

func _save() -> void:
	var state := simulation.snapshot()
	state["residents"] = residents.snapshot()
	state["career"] = career.snapshot()
	state["realms"] = realms.world.snapshot()
	state["regional_economy"] = markets.snapshot()
	state["society"] = society.snapshot()
	state["written_unix"] = Time.get_unix_time_from_system()
	state["player"] = [player.position.x, player.position.y, player.position.z]
	var result := saves.write_state(state, save_path)
	hud.show_message("Vale salvo." if result == OK else "Falha ao salvar · " + error_string(result))

func _load(show_feedback: bool, source := "") -> bool:
	var state := saves.read_state(save_path if source.is_empty() else source)
	if state.is_empty():
		if show_feedback:
			hud.show_message("Nenhum salvamento válido para carregar.")
		return false
	simulation.restore(state)
	career.restore(state.get("career"))
	society.restore(state.get("society"))
	realms.restore(state.get("realms"))
	markets.restore(state.get("regional_economy"))
	simulation.economy.dry = markets.drought
	if career.active() and not career.life.profile.has("uid"):
		career.life.profile.uid = save_path.sha256_text().left(32)
	var stamp: Variant = state.get("written_unix")
	if not show_feedback and (stamp is int or stamp is float) and is_finite(float(stamp)) and stamp > 0:
		simulation.tick(clampf(Time.get_unix_time_from_system() - float(stamp), 0.0, offline_limit))
	player.set_cargo(simulation.economy.stock.first("player"))
	player.position = Vector3(state.player[0], 0.10, state.player[2])
	follow = player.position + Vector3.UP * 0.65
	if state.get("residents") is Dictionary:
		residents.restore(state.residents)
		_apply_people()
	else:
		_reset_people()
	if show_feedback:
		hud.show_message("Vale restaurado · " + simulation.clock.time_text())
	return true
