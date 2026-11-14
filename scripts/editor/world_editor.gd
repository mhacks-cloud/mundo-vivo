class_name WorldEditor
extends CanvasLayer

const LABELS := {"well": "Poço", "tree": "Árvore", "barrel": "Barril", "crate": "Caixa"}
const TILES := ["grass", "dirt", "stone", "paving", "path", "road"]
var game: Node3D
var active := false
var saved: Dictionary = {}
var working: Dictionary = {}
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var selected := ""
var dragging := false
var drag_origin := Vector3.ZERO
var snap := true
var paint := false
var view_center := Vector3(0, 0.6, 0)
var list := ItemList.new()
var info := Label.new()
var kind := OptionButton.new()
var tile := OptionButton.new()
var panel := PanelContainer.new()
var marker := MeshInstance3D.new()
var count := 0
var hud_was_visible := true
var career_was_visible := true

func _init(owner_game: Node3D = null) -> void:
	game = owner_game
	layer = 12

func _ready() -> void:
	visible = false
	print("Sistema Deus: habilitado" if allowed() else "Sistema Deus: desabilitado neste build")
	var ring := TorusMesh.new()
	ring.inner_radius = 1.04
	ring.outer_radius = 1.14
	ring.rings = 8
	ring.ring_segments = 40
	marker.mesh = ring
	var highlight := StandardMaterial3D.new()
	highlight.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight.albedo_color = Color(0.83, 0.98, 0.66, 0.94)
	highlight.emission_enabled = true
	highlight.emission = Color(0.52, 0.94, 0.74)
	highlight.emission_energy_multiplier = 1.8
	marker.material_override = highlight
	marker.visible = false
	game.call_deferred("add_child", marker)
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color(0.055, 0.075, 0.085, 0.95)
	backdrop.border_color = Color(0.54, 0.64, 0.55, 0.95)
	backdrop.set_border_width_all(1)
	backdrop.set_corner_radius_all(8)
	backdrop.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", backdrop)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(14, 14)
	panel.custom_minimum_size = Vector2(306, 0)
	var box := VBoxContainer.new()
	panel.add_child(box)
	add_child(panel)
	var heading := Label.new()
	heading.text = "SISTEMA DEUS  ·  Vale do Amieiro"
	box.add_child(heading)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size.y = 56
	box.add_child(info)
	list.custom_minimum_size = Vector2(282, 178)
	list.item_selected.connect(func(index: int) -> void: _select(str(list.get_item_metadata(index))))
	box.add_child(list)
	var row := HBoxContainer.new()
	box.add_child(row)
	for id in LABELS:
		kind.add_item(LABELS[id])
		kind.set_item_metadata(kind.item_count - 1, id)
	row.add_child(kind)
	_button(row, "Adicionar", func() -> void: _add_object(false))
	_button(row, "Duplicar", func() -> void: _add_object(true))
	row = HBoxContainer.new()
	box.add_child(row)
	_button(row, "Excluir", _remove_selected)
	_button(row, "Girar ↶", func() -> void: _rotate(-PI / 12.0))
	_button(row, "Girar ↷", func() -> void: _rotate(PI / 12.0))
	row = HBoxContainer.new()
	box.add_child(row)
	for label in ["←", "→", "↑", "↓"]:
		var direction: Vector3 = {"←": Vector3(-0.1, 0, 0), "→": Vector3(0.1, 0, 0),
			"↑": Vector3(0, 0, -0.1), "↓": Vector3(0, 0, 0.1)}[label]
		_button(row, label, func() -> void: _nudge(direction))
	var grid := CheckButton.new()
	grid.text = "Grade 0,5 m"
	grid.button_pressed = true
	grid.toggled.connect(func(value: bool) -> void: snap = value)
	box.add_child(grid)
	row = HBoxContainer.new()
	box.add_child(row)
	for name in ["Grama", "Terra", "Pedra", "Pavimento", "Caminho", "Estrada"]:
		tile.add_item(name)
	row.add_child(tile)
	var painting := CheckButton.new()
	painting.text = "Pintar"
	painting.toggled.connect(func(value: bool) -> void: paint = value)
	row.add_child(painting)
	row = HBoxContainer.new()
	box.add_child(row)
	_button(row, "Desfazer", undo)
	_button(row, "Refazer", redo)
	_button(row, "Anterior", restore_previous)
	row = HBoxContainer.new()
	box.add_child(row)
	_button(row, "Salvar", save)
	_button(row, "Cancelar", cancel)
	_button(row, "Fechar", close)
	_show("Clique para selecionar. Arraste para mover. Q/R giram a câmera.")

func _button(parent: Node, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(action)
	parent.add_child(button)

func allowed() -> bool:
	return OS.has_feature("editor") or OS.has_feature("sistema_deus_dev")

func open() -> void:
	if not allowed() or active or game.realms.world.active:
		return
	saved = WorldEditStore.read()
	working = saved.duplicate(true)
	undo_stack.clear()
	redo_stack.clear()
	active = true
	visible = true
	hud_was_visible = game.hud.visible
	career_was_visible = game.career.ui.visible
	game.career.ui.hide_panel()
	game.realms.map.hide()
	game.hud.inspection.hide()
	game.hud.visible = false
	game.career.ui.visible = false
	if game.navigation.revision == 0:
		game.navigation.rebuild(game.diorama, game.simulation.construction.complete() and not game.career.authority.works.road_closed)
	view_center = game.player.position + Vector3.UP * 0.6
	_refresh_list()
	_show("Simulação pausada. Selecione um objeto ou pinte o terreno.")

func close() -> void:
	if not active:
		return
	if working != saved:
		_apply(saved)
	active = false
	visible = false
	game.hud.visible = hud_was_visible
	game.career.ui.visible = career_was_visible
	selected = ""
	dragging = false
	marker.hide()
	game.nav_dirty = true
	_sync_landmarks()

func cancel() -> void:
	_apply(saved)
	close()

func save() -> void:
	if not active:
		return
	var reason := validate_world()
	if not reason.is_empty():
		_show(reason)
		return
	var result := WorldEditStore.write(working)
	if result != OK:
		_show("Falha ao salvar: " + error_string(result))
		return
	saved = WorldEditStore.read()
	working = saved.duplicate(true)
	undo_stack.clear()
	redo_stack.clear()
	game.nav_dirty = true
	_sync_landmarks()
	_show("Região salva, revisão %d. Backup anterior disponível." % saved.revision)

func restore_previous() -> void:
	if not WorldEditStore.restore_previous():
		_show("Nenhuma versão anterior válida.")
		return
	saved = WorldEditStore.read()
	_apply(saved)
	undo_stack.clear()
	redo_stack.clear()
	_show("Versão anterior restaurada.")

func undo() -> void:
	if undo_stack.is_empty():
		return
	redo_stack.append(working.duplicate(true))
	_apply(undo_stack.pop_back())

func redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(working.duplicate(true))
	_apply(redo_stack.pop_back())

func _remember() -> void:
	undo_stack.append(working.duplicate(true))
	if undo_stack.size() > 40:
		undo_stack.pop_front()
	redo_stack.clear()

func _select(id: String) -> void:
	selected = id
	if not game.diorama.editable_objects.has(id):
		return
	var root: Node3D = game.diorama.editable_objects[id].root
	view_center = root.position + Vector3.UP * 0.6
	marker.position = root.position + Vector3.UP * 0.11
	marker.scale = Vector3.ONE * (1.4 if game.diorama.editable_objects[id].type == "well" else 0.75)
	marker.show()
	_show("%s  ·  x %.2f  z %.2f" % [id, root.position.x, root.position.z])

func _refresh_list() -> void:
	list.clear()
	for id in game.diorama.editable_objects:
		var row: Dictionary = working.get("entries", {}).get(id, {})
		if row.get("state") == "removed":
			continue
		var entry: Dictionary = game.diorama.editable_objects[id]
		list.add_item("%s · %s" % [LABELS[entry.type], id])
		list.set_item_metadata(list.item_count - 1, id)

func _row(id: String, position: Vector3, angle: float, state := "active") -> Dictionary:
	return {"schema": WorldEditStore.SCHEMA, "region": WorldEditStore.REGION, "id": id,
		"type": game.diorama.editable_objects[id].type, "position": [position.x, position.z],
		"rotation": angle, "state": state, "edited_at": Time.get_datetime_string_from_system()}

func _change(id: String, position: Vector3, angle: float, state := "active") -> bool:
	if not game.diorama.editable_objects.has(id):
		return false
	var root: Node3D = game.diorama.editable_objects[id].root
	var old := root.position
	var prior_angle := root.rotation.y
	var was_visible := root.visible
	game.diorama.set_editable(id, position, angle, state == "removed")
	var reason := validate_world()
	if not reason.is_empty():
		game.diorama.set_editable(id, old, prior_angle, not was_visible)
		_show(reason)
		return false
	_remember()
	working.entries[id] = _row(id, position, angle, state)
	if selected == id:
		marker.position = position + Vector3.UP * 0.11
	game.navigation.rebuild(game.diorama, game.simulation.construction.complete() and not game.career.authority.works.road_closed)
	game.nav_dirty = true
	_sync_landmarks()
	_show("Posição confirmada. Salve para manter após reiniciar.")
	return true

func _nudge(delta: Vector3) -> void:
	if selected.is_empty():
		return
	var root: Node3D = game.diorama.editable_objects[selected].root
	_change(selected, root.position + delta, root.rotation.y)

func _rotate(delta: float) -> void:
	if selected.is_empty():
		return
	var root: Node3D = game.diorama.editable_objects[selected].root
	_change(selected, root.position, wrapf(root.rotation.y + delta, -PI, PI))

func _remove_selected() -> void:
	if selected.is_empty() or selected == "founders_well":
		_show("O poço dos Fundadores é um marco público e não pode ser removido.")
		return
	var root: Node3D = game.diorama.editable_objects[selected].root
	if _change(selected, root.position, root.rotation.y, "removed"):
		selected = ""
		marker.hide()
		_refresh_list()

func _add_object(duplicate: bool) -> void:
	if working.entries.size() >= WorldEditStore.MAX_ENTRIES:
		_show("Limite de objetos atingido.")
		return
	var type: String = game.diorama.editable_objects[selected].type if duplicate and not selected.is_empty() else kind.get_item_metadata(kind.selected)
	var at := view_center + Vector3(1.5, -view_center.y, 0)
	var id := "added_%d_%d" % [Time.get_unix_time_from_system(), count]
	count += 1
	game.diorama.add_editable(id, type, at)
	game.diorama.set_editable(id, at, 0, true)
	if _change(id, at, 0):
		_select(id)
		_refresh_list()

func _apply(data: Dictionary) -> void:
	working = data.duplicate(true)
	for id in working.get("entries", {}):
		if not game.diorama.editable_objects.has(id):
			var row: Dictionary = working.entries[id]
			game.diorama.add_editable(id, row.type, Vector3(float(row.position[0]), 0, float(row.position[1])))
	for id in game.diorama.editable_objects:
		var baseline: Dictionary = game.diorama.editable_objects[id]
		var row: Dictionary = working.get("entries", {}).get(id, {})
		if row.is_empty():
			game.diorama.set_editable(id, baseline.base, 0.0, id.begins_with("added_"))
		else:
			game.diorama.set_editable(id, Vector3(float(row.position[0]), 0, float(row.position[1])), float(row.rotation), row.state == "removed")
	game.diorama.set_terrain(working.get("terrain", {}))
	if not selected.is_empty() and game.diorama.editable_objects.has(selected):
		marker.position = game.diorama.editable_objects[selected].root.position + Vector3.UP * 0.11
	game.navigation.rebuild(game.diorama, game.simulation.construction.complete() and not game.career.authority.works.road_closed)
	game.nav_dirty = true
	_sync_landmarks()
	_refresh_list()

func validate_world() -> String:
	for id in game.diorama.editable_objects:
		var entry: Dictionary = game.diorama.editable_objects[id]
		var root: Node3D = entry.root
		if not root.visible:
			continue
		var at := root.position
		if not id.begins_with("added_") and at.distance_to(entry.base) < 0.01:
			continue
		if at.x < -29 or at.x > 31 or at.z < -30 or at.z > 29:
			return "Fora dos limites do Vale."
		if at.x > 9.2 and at.x < 16.8 and absf(at.z - 2.0) > 2.0 and absf(at.z + 12.0) > 2.0:
			return "Objeto dentro do rio."
		if Homestead.within_residential(at.x, at.z):
			return "Lote residencial reservado."
		if id == "founders_well" and at.distance_to(Vector3(0.8, 0, -0.8)) > 8.0:
			return "O poço deve permanecer acessível na praça."
		var radius := 1.1 if entry.type == "well" else 0.5 if entry.type == "tree" else 0.34
		for footprint in game.diorama.footprints:
			if absf(at.x - footprint.x) < footprint.z + radius + 0.45 and absf(at.z - footprint.y) < footprint.w + radius + 0.45:
				return "Colisão com construção ou acesso à porta."
		for other_id in game.diorama.editable_objects:
			if other_id == id:
				continue
			var other: Dictionary = game.diorama.editable_objects[other_id]
			if other.root.visible and at.distance_to(other.root.position) < radius + (1.1 if other.type == "well" else 0.5 if other.type == "tree" else 0.34):
				return "Colisão entre objetos editáveis."
		for body in game.diorama.find_children("*", "StaticBody3D", true, false):
			if root.is_ancestor_of(body) or (body.collision_layer & 1) == 0:
				continue
			for hit in body.get_children():
				if not hit is CollisionShape3D or not hit.shape is BoxShape3D:
					continue
				var center: Vector3 = hit.global_position
				if center.y > 2.5:
					continue
				var half: Vector3 = hit.shape.size * 0.5
				var basis: Basis = hit.global_basis
				var extent := basis.x.abs() * half.x + basis.y.abs() * half.y + basis.z.abs() * half.z
				if absf(at.x - center.x) < radius + extent.x + 0.06 and absf(at.z - center.z) < radius + extent.z + 0.06:
					return "Colisão com estrutura ou cerca existente."
		for target in game.interactions.targets:
			if target.has("actor") or target.label == "Poço dos Fundadores":
				continue
			var place: Vector3 = target.position
			if at.distance_to(place) < radius + 0.65:
				return "A edição bloqueia um ponto de interação."
	var candidate := VillageNavigation.new()
	candidate.rebuild(game.diorama, game.simulation.construction.complete() and not game.career.authority.works.road_closed)
	for route in [[Vector3(0, 0.1, 4), Vector3(0, 0.1, -5)],
		[Vector3(-4, 0.1, 2), Vector3(8, 0.1, 2)],
		[Vector3(-11, 0.1, 7), Vector3(7, 0.1, -10)]]:
		var revised: PackedVector3Array = candidate.find(route[0], route[1])
		if revised.is_empty():
			return "A edição bloqueia uma rota dos moradores."
		var original: PackedVector3Array = game.navigation.find(route[0], route[1])
		if not original.is_empty() and _route_length(revised, route[0]) > _route_length(original, route[0]) * 1.35 + 3.0:
			return "A edição cria um desvio excessivo em uma rua importante."
	return ""

func _route_length(path: PackedVector3Array, start: Vector3) -> float:
	var length := 0.0
	var prior := start
	for point in path:
		length += prior.distance_to(point)
		prior = point
	return length

func _sync_landmarks() -> void:
	var root: Node3D = game.diorama.editable_objects.founders_well.root
	for target in game.interactions.targets:
		if target.label == "Poço dos Fundadores":
			target.position = root.position + Vector3.UP * 0.1
			break

func handle(event: InputEvent) -> bool:
	if not active:
		return false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F8 or event.physical_keycode == KEY_ESCAPE:
			close()
			return true
		if event.ctrl_pressed and event.physical_keycode == KEY_Z:
			undo()
			return true
		if event.ctrl_pressed and event.physical_keycode == KEY_Y:
			redo()
			return true
		if event.ctrl_pressed and event.physical_keycode == KEY_S:
			save()
			return true
	if event is InputEventMouseButton:
		var point := _ground(event.position)
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			game.target_distance = clampf(game.target_distance + (-2.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 2.2), 11, 40)
			return true
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if point == Vector3.INF:
					return true
				if paint:
					_paint_at(point)
					return true
				var nearest := ""
				var distance := 1.6
				for id in game.diorama.editable_objects:
					var root: Node3D = game.diorama.editable_objects[id].root
					var d := Vector2(point.x, point.z).distance_to(Vector2(root.position.x, root.position.z))
					if root.visible and d < distance:
						distance = d
						nearest = id
				if not nearest.is_empty():
					_select(nearest)
					dragging = true
					drag_origin = game.diorama.editable_objects[nearest].root.position
			else:
				view_center = point + Vector3.UP * 0.6
			return true
		if dragging:
			dragging = false
			var root: Node3D = game.diorama.editable_objects[selected].root
			var at := root.position
			game.diorama.set_editable(selected, drag_origin, root.rotation.y)
			_change(selected, at, root.rotation.y)
			return true
	if event is InputEventMouseMotion and dragging and not selected.is_empty():
		var point := _ground(event.position)
		if point != Vector3.INF:
			var at := Vector3(snappedf(point.x, 0.5), 0, snappedf(point.z, 0.5)) if snap else Vector3(point.x, 0, point.z)
			game.diorama.set_editable(selected, at, game.diorama.editable_objects[selected].root.rotation.y)
			marker.position = at + Vector3.UP * 0.11
		return true
	return true

func _ground(screen: Vector2) -> Vector3:
	var camera: Camera3D = game.camera
	var origin := camera.project_ray_origin(screen)
	var normal := camera.project_ray_normal(screen)
	if absf(normal.y) < 0.001:
		return Vector3.INF
	var factor := -origin.y / normal.y
	return origin + normal * factor if factor > 0 else Vector3.INF

func _paint_at(point: Vector3) -> void:
	var x := roundi(point.x)
	var z := roundi(point.z)
	if x < -29 or x > 31 or z < -30 or z > 29 or Homestead.within_residential(x, z) or (x > 9 and x < 17):
		_show("Terreno fora da região editável ou área reservada.")
		return
	_remember()
	working.terrain["t_%d_%d" % [x, z]] = TILES[tile.selected]
	game.diorama.set_terrain(working.terrain)
	_show("Terreno pintado em %d, %d. Salve para persistir." % [x, z])

func _show(message: String) -> void:
	info.text = message
