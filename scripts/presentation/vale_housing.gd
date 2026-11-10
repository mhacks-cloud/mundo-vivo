class_name ValeHousing
extends Node3D

var rules: Homestead
var life: PlayerLife
var palette: ValePalette
var builds: Node3D
var ghost: Node3D
var preview_cell := Vector2i(-99, -99)
var preview_kind := ""
var preview_direction := 0
var preview_valid := false
var roofs: Array[Dictionary] = []
var garden_plants: Dictionary = {}
var preview_mat := StandardMaterial3D.new()
var invalid_mat := StandardMaterial3D.new()
var plot_selection := Node3D.new()

func setup(character: PlayerLife, style: ValePalette) -> void:
	life = character
	rules = life.estate
	palette = style
	builds = Node3D.new()
	add_child(builds)
	ghost = Node3D.new()
	add_child(ghost)
	for pair in [[preview_mat, Color(0.36, 0.78, 0.56, 0.68)], [invalid_mat, Color(0.80, 0.32, 0.24, 0.68)]]:
		var material: StandardMaterial3D = pair[0]
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = pair[1]
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_draw_plots()
	add_child(plot_selection)
	plot_selection.hide()
	rules.changed.connect(rebuild)
	rebuild()

func _draw_plots() -> void:
	for id in Homestead.PLOTS:
		var at: Vector2 = Homestead.PLOTS[id].at
		var width := Homestead.CELL * Homestead.SIDE
		for direction in 4:
			var normal: Vector2 = Vector2(Homestead.DIRECTIONS[direction])
			var middle := at + Vector2.ONE * width * 0.5 + normal * width * 0.5
			_box(self, Vector3(middle.x, 0.032, middle.y),
				Vector3(0.095 if direction % 2 else width, 0.055, width if direction % 2 else 0.095), "oak")
			var point := at + Vector2.ONE * width * 0.5 + normal * (width * 0.5 - 0.08)
			_box(self, Vector3(point.x, 0.21, point.y), Vector3(0.13, 0.42, 0.13), "wood")
		var sign_pos := Vector3(at.x + 1.0, 0.76, at.y + 0.18)
		_box(self, sign_pos - Vector3.UP * 0.36, Vector3(0.10, 0.72, 0.10), "wood")
		_box(self, sign_pos, Vector3(1.26, 0.27, 0.12), "board")
		var label := Label3D.new()
		label.text = Homestead.PLOTS[id].name
		label.position = sign_pos + Vector3(0, 0, 0.071)
		label.pixel_size = 0.0042
		label.font_size = 27
		label.modulate = Color("f0d4a0")
		label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		add_child(label)

func select_plot(id: String) -> void:
	_clear(plot_selection)
	if not Homestead.PLOTS.has(id):
		plot_selection.hide()
		return
	var origin: Vector2 = Homestead.PLOTS[id].at
	var width := Homestead.CELL * Homestead.SIDE
	var selected := StandardMaterial3D.new()
	selected.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selected.albedo_color = Color("eac681")
	for direction in 4:
		var normal: Vector2 = Vector2(Homestead.DIRECTIONS[direction])
		var p := origin + Vector2.ONE * width * 0.5 + normal * width * 0.5
		_box(plot_selection, Vector3(p.x, 0.071, p.y),
			Vector3(0.076 if direction % 2 else width, 0.032, width if direction % 2 else 0.076), "oak", Vector3.ZERO, selected)
	plot_selection.show()

func rebuild() -> void:
	_clear(builds)
	roofs.clear()
	garden_plants.clear()
	for part in rules.pieces:
		var model := Node3D.new()
		model.position = Homestead.center(part.plot, part.cell)
		builds.add_child(model)
		_module(model, part.kind, part.dir, true, null)
		if part.kind in ["roof", "roof_slate"]:
			roofs.append({"model": model, "at": model.position})
		if part.kind == "garden":
			var crops := Node3D.new()
			model.add_child(crops)
			for row in 2:
				for col in 3:
					var p := Vector3((col - 1) * 0.32, 0.13, row * 0.38 - 0.19)
					_box(crops, p, Vector3(0.12, 0.23, 0.12), "77964e", Vector3(0, 0.13, 0.25))
					_box(crops, p + Vector3.UP * 0.14, Vector3(0.09, 0.075, 0.09), "d1aa60")
			garden_plants["%d:%d" % [part.cell.x, part.cell.y]] = crops

func preview(plot: String, kind: String, cell: Vector2i, direction: int, valid: bool) -> void:
	if not Homestead.PLOTS.has(plot) or not Homestead.in_bounds(cell):
		hide_preview()
		return
	if ghost.visible and preview_kind == kind and preview_cell == cell and preview_direction == direction and preview_valid == valid:
		return
	_clear(ghost)
	ghost.show()
	ghost.position = Homestead.center(plot, cell)
	preview_kind = kind
	preview_cell = cell
	preview_direction = direction
	preview_valid = valid
	_module(ghost, kind, direction, false, preview_mat if valid else invalid_mat)

func hide_preview() -> void:
	ghost.hide()

func update_view(p: Vector3, now: float) -> void:
	var plot := life.estate.owned(PlayerLife.ID)
	var inside := not plot.is_empty() and rules.layer_at(plot, Homestead.cell_at(plot, p), "floor")
	for entry in roofs:
		entry.model.visible = not inside
	for key in garden_plants:
		var crops: Node3D = garden_plants[key]
		crops.visible = life.plants.has(key)
		if crops.visible:
			crops.scale.y = 1.0 if life.plants[key].wet and now >= life.plants[key].ready else 0.55

func _module(root: Node3D, kind: String, direction: int, solid: bool, material: Material) -> void:
	var width := Homestead.CELL
	match kind:
		"foundation":
			_box(root, Vector3(0, -0.075, 0), Vector3(width, 0.23, width), "stone", Vector3.ZERO, material)
		"floor":
			for i in 5:
				_box(root, Vector3(-0.6 + i * 0.3, 0.053, 0), Vector3(0.297, 0.056, width), "oak" if i % 2 == 0 else "board", Vector3.ZERO, material)
		"roof", "roof_slate":
			var top := Node3D.new()
			top.rotation.y = direction * PI * 0.5
			root.add_child(top)
			_box(top, Vector3(0, 2.28, 0), Vector3(1.65, 0.13, 1.58), "roof" if kind == "roof" else "mossroof", Vector3(0, 0, 0.33), material)
			_box(top, Vector3(0, 2.20, 0.77), Vector3(1.63, 0.11, 0.10), "wood", Vector3(0, 0, 0.33), material)
		"wall", "door", "door_oak", "window", "window_carved", "fence":
			var edge := Node3D.new()
			var offset: Vector2 = Vector2(Homestead.DIRECTIONS[direction]) * width * 0.5
			edge.position = Vector3(offset.x, 0, offset.y)
			edge.rotation.y = PI - direction * PI * 0.5
			root.add_child(edge)
			if kind == "fence":
				for x in [-0.65, 0.65]:
					_box(edge, Vector3(x, 0.39, 0), Vector3(0.13, 0.78, 0.14), "wood", Vector3.ZERO, material)
				for y in [0.27, 0.54]:
					_box(edge, Vector3(0, y, 0), Vector3(1.50, 0.12, 0.10), "board", Vector3.ZERO, material)
				if solid:
					_hit(edge, Vector3(0, 0.37, 0), Vector3(1.5, 0.74, 0.15), root)
				return
			for x in [-0.69, 0.69]:
				_box(edge, Vector3(x, 1.06, 0), Vector3(0.13, 2.14, 0.20), "wood", Vector3.ZERO, material)
			for y in [0.10, 2.05]:
				_box(edge, Vector3(0, y, 0), Vector3(1.50, 0.15, 0.22), "wood", Vector3.ZERO, material)
			if kind in ["door", "door_oak"]:
				_box(edge, Vector3(0, 1.89, 0), Vector3(1.38, 0.29, 0.18), "plaster", Vector3.ZERO, material)
				for x in [-0.53, 0.53]:
					_box(edge, Vector3(x, 0.91, 0), Vector3(0.31, 1.80, 0.21), "wood", Vector3.ZERO, material)
					if solid:
						_hit(edge, Vector3(x, 0.93, 0), Vector3(0.32, 1.86, 0.22), root)
				_box(edge, Vector3(-0.35, 0.89, 0.32), Vector3(0.10, 1.57, 0.64), "oak" if kind == "door_oak" else "teal", Vector3(0, -0.20, 0), material)
			else:
				_box(edge, Vector3(0, 0.31, 0), Vector3(1.42, 0.46, 0.19), "stone", Vector3.ZERO, material)
				_box(edge, Vector3(0, 1.23, 0), Vector3(1.37, 1.44, 0.16), "plaster", Vector3.ZERO, material)
				_box(edge, Vector3(0, 0.81, 0.09), Vector3(1.42, 0.11, 0.08), "wood", Vector3.ZERO, material)
				if kind in ["window", "window_carved"]:
					_box(edge, Vector3(0, 1.29, 0.10), Vector3(0.74, 0.69, 0.10), "wine" if kind == "window_carved" else "wood", Vector3.ZERO, material)
					_box(edge, Vector3(0, 1.29, 0.16), Vector3(0.58, 0.51, 0.04), "glass", Vector3.ZERO, material)
					_box(edge, Vector3(0, 1.29, 0.19), Vector3(0.07, 0.56, 0.07), "wood", Vector3.ZERO, material)
				else:
					_box(edge, Vector3(0, 1.27, 0.11), Vector3(0.10, 1.13, 0.10), "wood", Vector3(0, 0, 0.63), material)
				if solid:
					_hit(edge, Vector3(0, 1.05, 0), Vector3(1.50, 2.10, 0.20), root)
		"chair":
			var chair := Node3D.new()
			chair.rotation.y = direction * PI * 0.5
			root.add_child(chair)
			_box(chair, Vector3(0, 0.35, 0), Vector3(0.88, 0.11, 0.41), "oak", Vector3.ZERO, material)
			for x in [-0.34, 0.34]:
				_box(chair, Vector3(x, 0.19, 0), Vector3(0.11, 0.36, 0.31), "wood", Vector3.ZERO, material)
			_box(chair, Vector3(0, 0.60, -0.17), Vector3(0.87, 0.27, 0.075), "board", Vector3.ZERO, material)
			if solid:
				_hit(chair, Vector3(0, 0.22, 0), Vector3(0.89, 0.46, 0.40), root)
		"garden":
			_box(root, Vector3(0, 0.04, 0), Vector3(1.35, 0.11, 1.33), "garden", Vector3.ZERO, material)
			for side in [-0.62, 0.62]:
				_box(root, Vector3(side, 0.08, 0), Vector3(0.10, 0.14, 1.37), "board", Vector3.ZERO, material)
		"flowers":
			_box(root, Vector3(0, 0.15, 0), Vector3(0.34, 0.31, 0.33), "roof", Vector3.ZERO, material)
			for i in 5:
				var x := (i - 2) * 0.09
				_box(root, Vector3(x, 0.35, 0), Vector3(0.035, 0.29, 0.035), "638044", Vector3(0, 0, x), material)
				_box(root, Vector3(x, 0.50 + x * 0.2, 0), Vector3(0.085, 0.07, 0.085), "e3b79c", Vector3.ZERO, material)

func _box(root: Node3D, p: Vector3, size: Vector3, id: String, rotation_value := Vector3.ZERO, material: Material = null) -> void:
	var node := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	node.mesh = shape
	node.position = p
	node.rotation = rotation_value
	node.material_override = material if material != null else palette.materials[id]
	if material != null:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)

func _hit(root: Node3D, p: Vector3, size: Vector3, visual: Node3D) -> void:
	var body := StaticBody3D.new()
	body.position = p
	body.set_meta("facade", visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)

func _clear(root: Node3D) -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()
