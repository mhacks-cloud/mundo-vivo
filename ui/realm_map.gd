class_name RealmMap
extends CanvasLayer

class Atlas extends Control:
	const GOLD := Color("e8c789")
	const INK := Color("171c1b")
	const MIST := Color("a5ada1")
	const CREAM := Color("eee4ce")
	var service: Node
	var zoom := 1.0
	var pan := Vector2.ZERO
	var sheet := Rect2()
	var drag_distance := 0.0

	func _ready() -> void:
		mouse_default_cursor_shape = Control.CURSOR_CROSS

	func _draw() -> void:
		var world: RealmWorld = service.world
		var game: Node3D = service.game
		var font := ThemeDB.fallback_font
		var panel_size := Vector2(minf(size.x - 32.0, 1110.0), minf(size.y - 44.0, 605.0))
		var panel := Rect2((size - panel_size) * 0.5, panel_size)
		draw_style_box(_frame(), panel)
		var left := panel.position.x + 19
		var top := panel.position.y + 33
		draw_string(font, Vector2(left, top), "Atlas dos Reinos", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, CREAM)
		draw_string(font, Vector2(left, top + 24), "Roda para aproximar  ·  Arraste para mover  ·  Clique em um local  ·  P / Esc para fechar",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MIST)
		sheet = Rect2(Vector2(left, top + 42), Vector2(panel.size.x * 0.66 - 32, panel.size.y - 95))
		draw_rect(sheet, Color("373c34"))
		draw_rect(sheet, Color("6f6750"), false, 1.0)
		draw_style_box(_frame(), Rect2(Vector2(sheet.end.x + 12, sheet.position.y), Vector2(panel.end.x - sheet.end.x - 29, sheet.size.y)))
		_draw_terrain(font)
		var bridge: bool = game.simulation.construction.complete()
		var flood: bool = game.career.authority.works.road_closed
		for id in RealmWorld.ROUTES:
			var route: Dictionary = RealmWorld.ROUTES[id]
			if route.from not in world.discovered and route.to not in world.discovered:
				continue
			var first := _point(RealmWorld.PLACES[route.from].at)
			var last := _point(RealmWorld.PLACES[route.to].at)
			var bend := (first + last) * 0.5
			if id in ["lower", "stone"]:
				bend.y += 24
			elif id in ["ridge", "north"]:
				bend.y -= 17
			var state := world.access(id, bridge, flood)
			var tint := Color("d1b482") if state == "ABERTA" else Color("c37f68")
			if sheet.has_point(first) and sheet.has_point(last) and sheet.has_point(bend):
				if state == "ABERTA":
					draw_polyline(PackedVector2Array([first, bend, last]), tint, 2.0, true)
				else:
					draw_dashed_line(first, bend, tint, 2.0, 5.0)
					draw_dashed_line(bend, last, tint, 2.0, 5.0)
		var current := world.current(game.player.position)
		for id in RealmWorld.PLACES:
			var place: Dictionary = RealmWorld.PLACES[id]
			var at := _point(place.at)
			if not sheet.grow(-10.0).has_point(at):
				continue
			var known: bool = id in world.discovered
			var available: bool = id not in ["salmar", "hamlet"] or (id == "hamlet" and world.houses > 0)
			var color := GOLD if known else Color("a89c81") if available else Color("837b69")
			if id == world.selected:
				draw_arc(at, 12.0, 0.0, TAU, 24, GOLD, 1.5, true)
			if id == current:
				draw_circle(at, 8.0, Color("83c3ae"), true, -1.0, true)
			_icon(at, String(place.type), color)
			var name_value: String = place.name if known or id in ["capital", "frontier", "salmar", "hamlet"] else "A descobrir"
			var line_at := at + Vector2(10, -9)
			if line_at.x + font.get_string_size(name_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > sheet.end.x - 5:
				line_at.x = at.x - font.get_string_size(name_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x - 9
			draw_string(font, line_at, name_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		_draw_details(font, current, bridge, flood)

	func _draw_terrain(font: Font) -> void:
		var border := [_point(Vector2(0.39, 0.04)), _point(Vector2(0.44, 0.31)), _point(Vector2(0.36, 0.55)), _point(Vector2(0.46, 0.96))]
		_clipped_line(border, Color("868474"), 1.4, true)
		var river := [_point(Vector2(0.28, 0.03)), _point(Vector2(0.30, 0.29)), _point(Vector2(0.39, 0.49)),
			_point(Vector2(0.31, 0.75)), _point(Vector2(0.44, 0.97))]
		_clipped_line(river, Color("6f9b9a"), 3.0)
		var lake := _point(Vector2(0.27, 0.77))
		if sheet.grow(-18).has_point(lake):
			draw_set_transform(lake, 0.28, Vector2(1.0, 0.58))
			draw_circle(Vector2.ZERO, 12, Color("688c8b"), true, -1.0, true)
			draw_set_transform(Vector2.ZERO)
		for index in 16:
			var at := _point(Vector2(0.64 + float(index % 5) * 0.066, 0.10 + float(index / 5) * 0.075 + (0.037 if index % 2 == 0 else 0.0)))
			if sheet.grow(-12).has_point(at):
				draw_colored_polygon(PackedVector2Array([at + Vector2(-7, 5), at + Vector2(0, -6), at + Vector2(8, 5)]), Color("737e74"))
		for index in 17:
			var at := _point(Vector2(0.09 + float(index % 5) * 0.048, 0.17 + float(index / 5) * 0.071))
			if sheet.grow(-10).has_point(at):
				draw_colored_polygon(PackedVector2Array([at + Vector2(-4, 5), at + Vector2(0, -5), at + Vector2(4, 5)]), Color("829475"))
		for label in [["COROA DO AMIEIRO", Vector2(0.07, 0.88)], ["BRUMÁRIA", Vector2(0.72, 0.84)]]:
			var at := _point(label[1])
			if sheet.grow(-20).has_point(at) and at.x + 125 < sheet.end.x:
				draw_string(font, at, label[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c1b79c"))

	func _draw_details(font: Font, current: String, bridge: bool, flood: bool) -> void:
		var world: RealmWorld = service.world
		var game: Node3D = service.game
		var info: Dictionary = RealmWorld.PLACES[world.selected]
		var origin := Vector2(sheet.end.x + 25, sheet.position.y + 29)
		var lines: Array[String] = [info.name, info.type, LifeCatalog.NATIONS[info.realm].name,
			"Descoberto" if world.selected in world.discovered else "Ainda não visitado", "", "Agora · " + RealmWorld.PLACES[current].name]
		if world.selected != "salmar":
			var climate := world.regional_climate(world.selected, game.simulation.climate, game.career.frontier.climate)
			var clock: WorldClock = game.simulation.clock
			var weather := climate.sample(clock.total_day(), clock.hour())
			lines.append("%s · %d °C" % [weather.weather, roundi(weather.temperature)])
		lines.append("")
		lines.append("Rotas")
		for id in RealmWorld.ROUTES:
			var route: Dictionary = RealmWorld.ROUTES[id]
			if world.selected in [route.from, route.to]:
				var labels := {"forest": "Bosque", "stone": "Ponte de pedra", "north": "Ponte Nova", "ruin": "Ruína",
					"ridge": "Caminho alto", "lower": "Estrada da encosta", "mine": "Pedreira", "hamlet": "Pouso da Geada"}
				lines.append("%s · %s" % [labels[id], world.access(id, bridge, flood).to_lower()])
		if not world.project.is_empty():
			lines.append("")
			lines.append("Obra · " + RealmWorld.WORKS[world.project.id].name)
			lines.append(RealmWorld.WORK_STEPS[world.project.step])
		var width := maxf(70, (size.x + minf(size.x - 32.0, 1110.0)) * 0.5 - origin.x - 25)
		for index in lines.size():
			if origin.y + index * 20 >= sheet.end.y - 9:
				break
			draw_string(font, origin + Vector2(0, index * 20), lines[index], HORIZONTAL_ALIGNMENT_LEFT, width,
				17 if index == 0 else 13, GOLD if index == 0 else CREAM)

	func _icon(at: Vector2, kind: String, tint: Color) -> void:
		if kind in ["Minas", "Floresta"]:
			draw_colored_polygon(PackedVector2Array([at + Vector2(-5, 4), at + Vector2(0, -6), at + Vector2(5, 4)]), tint)
		elif kind == "Masmorra":
			draw_circle(at, 5, tint, false, 2.0, true)
		else:
			draw_rect(Rect2(at - Vector2(4, 4), Vector2(8, 8)), tint)

	func _clipped_line(points: Array, tint: Color, width: float, dash := false) -> void:
		for index in range(1, points.size()):
			var first: Vector2 = points[index - 1]
			var last: Vector2 = points[index]
			if sheet.has_point(first) and sheet.has_point(last):
				if dash:
					draw_dashed_line(first, last, tint, width, 6.0)
				else:
					draw_line(first, last, tint, width, true)

	func _point(normalized: Vector2) -> Vector2:
		return sheet.get_center() + (normalized - Vector2(0.5, 0.5)) * sheet.size * zoom + pan

	func _frame() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = INK
		style.border_color = Color("817358")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		return style

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and sheet.has_point(event.position):
			if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				var old_zoom := zoom
				zoom = clampf(zoom * (1.17 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.855), 0.75, 2.9)
				var center: Vector2 = event.position - sheet.get_center()
				pan = center - (center - pan) * zoom / old_zoom
			elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				drag_distance = 0.0
			elif event.button_index == MOUSE_BUTTON_LEFT and drag_distance < 7.0:
				for id in RealmWorld.PLACES:
					if event.position.distance_to(_point(RealmWorld.PLACES[id].at)) < 17.0:
						service.world.selected = id
						break
			queue_redraw()
			accept_event()
		elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if sheet.has_point(event.position):
				drag_distance += event.relative.length()
				pan = (pan + event.relative).clamp(-sheet.size, sheet.size)
				queue_redraw()
				accept_event()

var atlas: Atlas
var refresh := 0.0

func setup(owner: Node) -> void:
	layer = 23
	atlas = Atlas.new()
	atlas.service = owner
	add_child(atlas)
	atlas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()

func _process(delta: float) -> void:
	if not visible:
		return
	refresh += delta
	if refresh >= 0.4:
		refresh = 0.0
		atlas.queue_redraw()

func toggle() -> void:
	visible = not visible
	atlas.queue_redraw()
