class_name ValeDiorama
extends Node3D

var palette := ValePalette.new()
var rng := RandomNumberGenerator.new()
var cube := BoxMesh.new()
var tuft := PrismMesh.new()
var leaf := SphereMesh.new()
var batches: Dictionary = {}
var permanent_bridge: Node3D
var project_bridge: Node3D
var lanterns: Array[OmniLight3D] = []
var halos: Array[Sprite3D] = []
var halo_texture: ImageTexture

func _ready() -> void:
	rng.seed = 92451
	tuft.left_to_right = 0.25
	leaf.radial_segments = 7
	leaf.rings = 3
	_build_land()
	_build_village()
	_flush()
	permanent_bridge = Node3D.new()
	add_child(permanent_bridge)
	_bridge(permanent_bridge, 2.0, 3, true)
	project_bridge = Node3D.new()
	add_child(project_bridge)
	update_bridge(0)

func _build_land() -> void:
	box(Vector3(-18.5, -0.69, 0), Vector3(57, 1.32, 87), "earth")
	box(Vector3(-18.5, -0.11, 0), Vector3(57, 0.20, 87), "grass")
	box(Vector3(31.5, -0.69, 0), Vector3(31, 1.32, 87), "earth")
	box(Vector3(31.5, -0.11, 0), Vector3(31, 0.20, 87), "grass")
	var water := MeshInstance3D.new()
	var surface := PlaneMesh.new()
	surface.size = Vector2(6, 87)
	water.mesh = surface
	var river := ShaderMaterial.new()
	river.shader = preload("res://shaders/river.gdshader")
	water.material_override = river
	water.position = Vector3(13, -0.48, 0)
	add_child(water)
	for z in range(-43, 44):
		for bank in [9.95, 16.05]:
			var rock_at := Vector3(bank + rng.randf_range(-0.16, 0.16), -0.24, z + rng.randf())
			piece(leaf, rock_at, Vector3(rng.randf_range(0.35, 0.67), 0.37, 0.82), "stone", Vector3(0, rng.randf() * TAU, 0))
			if rng.randf() < 0.48:
				grass(Vector3(bank + (-0.33 if bank < 13 else 0.33), 0, float(z)), 1.5)
	for edge in [Vector3(-32, 0, 0), Vector3(34, 0, 0)]:
		collider(edge + Vector3.UP, Vector3(1, 2, 69), self)
	for edge_z in [-34, 33]:
		collider(Vector3(1, 1, edge_z), Vector3(67, 2, 1), self)
	var left_z := -34.0
	for gap in [-12.0, 2.0, 33.0]:
		var end_z: float = gap - (0.0 if gap == 33.0 else 1.25)
		var length := end_z - left_z
		for side in [9.93, 16.07]:
			collider(Vector3(side, 0.5, (end_z + left_z) * 0.5), Vector3(0.23, 2, length), self)
		left_z = gap + 1.25
	for i in 60:
		var z := rng.randf_range(-42, -22)
		var x := rng.randf_range(-42, 43)
		if x < 8 or x > 18:
			piece(leaf, Vector3(x, -1.5, z), Vector3(8, rng.randf_range(3, 7), 8), "354b33")
	for i in 172:
		var x := rng.randf_range(-39, 39)
		var z := rng.randf_range(-41, 34)
		if (x > -15 and x < 17 and z > -19 and z < 18) or (x > 8 and x < 18):
			continue
		if x > 16 and x < 26 and z > -17 and z < 6:
			continue
		tree(Vector3(x, 0, z), rng.randf_range(0.68, 1.4), z < -14 or rng.randf() > 0.46, false)
	for i in 1750:
		var x := rng.randf_range(-29, 30)
		var z := rng.randf_range(-32, 29)
		if x > 9.5 and x < 16.5:
			continue
		if absf(z - 2) < 1.55 or absf(z + 12) < 0.95 or absf(x + 0.2) < 1.25:
			continue
		if absf(x) < 5.8 and z > -4.9 and z < 5.0:
			continue
		grass(Vector3(x, 0, z), rng.randf_range(0.42, 1.05))

func _build_village() -> void:
	paving(Vector3(0, 0, 0), Vector2(12, 9.2), "cobble")
	paving(Vector3(0, 0, 2), Vector2(19.7, 2.6), "cobble")
	paving(Vector3(20.3, 0, 2), Vector2(8.6, 2.5), "trail")
	paving(Vector3(21, 0, -4.8), Vector2(2.15, 15.8), "trail")
	paving(Vector3(0, 0, -9), Vector2(2.1, 11.2), "cobble")
	paving(Vector3(0, 0, 8.5), Vector2(2.2, 12), "trail")
	paving(Vector3(-1, 0, -12), Vector2(21.7, 1.9), "trail")
	paving(Vector3(18.7, 0, -12), Vector2(5.5, 2.0), "trail")
	paving(Vector3(-9, 0, 7), Vector2(16, 1.65), "trail")

	house(Vector3(-6.7, 0, -6.6), 4.9, 4.0, 2.67, "plaster", "roof", "wine", "A RAPOSA DOURADA")
	house(Vector3(2.6, 0, -7.1), 3.9, 3.3, 2.35, "ivory", "goldroof", "teal")
	house(Vector3(7.0, 0, -5.5), 4.0, 3.15, 2.23, "sage", "mossroof", "wine")
	house(Vector3(-8.8, 0, 2.8), 4.4, 3.75, 2.15, "ivory", "goldroof", "teal", "FORJA DO AMIEIRO")
	house(Vector3(-7.0, 0, 11.4), 4.0, 3.7, 2.28, "sage", "roof", "wine")
	house(Vector3(6.25, 0, 10.5), 3.45, 3.1, 2.2, "plaster", "goldroof", "teal")
	house(Vector3(-7.6, 0, -16.1), 3.5, 3.4, 2.05, "ivory", "mossroof", "wine")
	house(Vector3(4.4, 0, -17.0), 4.05, 3.5, 2.65, "stone", "roof", "teal")
	house(Vector3(24.8, 0, -3.0), 3.8, 3.4, 2.2, "plaster", "roof", "teal")

	well(Vector3(0.8, 0, -0.8))
	bench(Vector3(3.8, 0, -3.72))
	bench(Vector3(-3.9, 0, -3.72))
	bench(Vector3(7.9, 0, 3.9))
	for point in [Vector3(-5.7, 0, 3.55), Vector3(4.7, 0, 3.8), Vector3(8.8, 0, 3.55), Vector3(17.5, 0, 3.5), Vector3(8.3, 0, -11.0), Vector3(21.9, 0, -17.6)]:
		lamp(point)
	for point in [Vector3(-10.8, 0, -4.9), Vector3(5.4, 0, -2.45), Vector3(6.4, 0, 5.5), Vector3(-4.8, 0, 8.7), Vector3(7.8, 0, -9.5), Vector3(-4.3, 0, -10.7), Vector3(18.6, 0, -2.7), Vector3(-11, 0, 9.1)]:
		tree(point, rng.randf_range(0.72, 1.05), false, true)
	for center in [Vector3(-3.6, 0, -4.8), Vector3(4.5, 0, -4.8), Vector3(5.8, 0, 4.8), Vector3(-5.5, 0, 5.0), Vector3(8.8, 0, -8.2), Vector3(-5, 0, 10), Vector3(17.5, 0, -1.2), Vector3(23.0, 0, -2.0)]:
		for i in 24:
			var p: Vector3 = center + Vector3(rng.randf_range(-1.1, 1.1), 0, rng.randf_range(-0.55, 0.55))
			grass(p, rng.randf_range(0.7, 1.5))
			if i % 3 == 0:
				flower(p)
	for center in [Vector3(-2.2, 0, 5.15), Vector3(3.7, 0, 5.15), Vector3(-3.5, 0, -4.95),
			Vector3(4.15, 0, -4.95), Vector3(8.45, 0, 5.85), Vector3(-5.2, 0, 6.1),
			Vector3(7.8, 0, -9.3), Vector3(-8.4, 0, -10.6), Vector3(17.8, 0, -2.0)]:
		for i in 5:
			shrub(center + Vector3(i * 0.39 - 0.78, 0, rng.randf_range(-0.14, 0.14)))
	_farm()
	_forge()
	_market(Vector3(7.65, 0, -0.8), "wine")
	_market(Vector3(-7.4, 0, -1.35), "teal")
	_cave()
	for point in [Vector3(-3.7, 0, -5), Vector3(-9.6, 0, -4.6), Vector3(-10, 0, 5.3), Vector3(8.8, 0, -3.55), Vector3(8.6, 0, -13.5), Vector3(7.6, 0, -13.65), Vector3(17.7, 0, -13.8), Vector3(3.9, 0, 9.15)]:
		barrel(point)
	for i in 5:
		box(Vector3(6.4, 0.2 + 0.15 * (i % 2), -12.8 - i * 0.19), Vector3(2.1, 0.18, 0.18), "oak")

func house(p: Vector3, w: float, d: float, h: float, wall: String, roof: String, door: String, sign_text := "") -> void:
	var front := d * 0.5
	var ridge := w * 0.34
	box(p + Vector3(0, h * 0.5, 0), Vector3(w, h, d), wall)
	box(p + Vector3(0, 0.25, 0), Vector3(w + 0.12, 0.5, d + 0.13), "stone")
	collider(p + Vector3(0, h * 0.5, 0), Vector3(w, h, d), self)
	_gable(p + Vector3(0, h, 0), w, d, ridge, wall)
	for side in [-1.0, 1.0]:
		var z: float = side * (front + 0.045)
		for y in [0.49, h * 0.63, h - 0.05]:
			box(p + Vector3(0, y, z), Vector3(w + 0.17, 0.135, 0.14), "wood")
		for x in [-w * 0.5, -w * 0.24, 0.0, w * 0.24, w * 0.5]:
			box(p + Vector3(x, h * 0.53, z), Vector3(0.132, h * 0.92, 0.14), "wood")
		for x in [-1.0, 1.0]:
			beam(p + Vector3(x * w * 0.48, h + 0.015, z), p + Vector3(0, h + ridge, z), 0.16, "wood")
			beam(p + Vector3(x * w * 0.44, h * 0.64, z + 0.025), p + Vector3(x * w * 0.26, h * 0.96, z + 0.025), 0.12, "wood")
			box(p + Vector3(x * w * 0.21, h + ridge * 0.20, z), Vector3(0.10, ridge * 0.45, 0.13), "wood")
		box(p + Vector3(0, h + ridge * 0.37, z), Vector3(0.11, ridge * 0.73, 0.15), "wood")
	for x in [-w * 0.5, w * 0.5]:
		for y in [0.49, h * 0.63, h - 0.05]:
			box(p + Vector3(x, y, 0), Vector3(0.14, 0.14, d + 0.13), "wood")
		for z in [-d * 0.27, 0.0, d * 0.27]:
			box(p + Vector3(x, h * 0.52, z), Vector3(0.13, h * 0.94, 0.14), "wood")
	var run := w * 0.5 + 0.35
	var angle := atan2(ridge + 0.18, run)
	var slope := Vector2(run, ridge + 0.18).length()
	for side in [-1.0, 1.0]:
		var rot := Vector3(0, 0, -angle * side)
		box(p + Vector3(side * run * 0.5, h + ridge * 0.5 - 0.01, 0), Vector3(slope + 0.04, 0.15, d + 0.65), roof, rot)
		for z in [-front - 0.31, front + 0.31]:
			box(p + Vector3(side * run * 0.5, h + ridge * 0.5 - 0.05, z), Vector3(slope + 0.06, 0.16, 0.13), "wood", rot)
		for i in range(1, 7):
			var t := float(i) / 7.0
			box(p + Vector3(side * run * t, h + ridge - (ridge + 0.18) * t + 0.085, 0), Vector3(0.061, 0.057, d + 0.58), roof, rot)
	box(p + Vector3(0, h + ridge + 0.08, 0), Vector3(0.19, 0.17, d + 0.70), roof)
	box(p + Vector3(w * 0.32, h + ridge * 0.50, -d * 0.23), Vector3(0.58, 1.67, 0.58), "stone")
	box(p + Vector3(w * 0.32, h + ridge * 0.50 + 0.84, -d * 0.23), Vector3(0.71, 0.16, 0.71), "stone")
	var f := front + 0.12
	box(p + Vector3(0, 0.76, f), Vector3(0.93, 1.51, 0.14), "wood")
	box(p + Vector3(0, 0.77, f + 0.085), Vector3(0.75, 1.39, 0.06), door)
	for x in [-0.24, 0.0, 0.24]:
		box(p + Vector3(x, 0.77, f + 0.123), Vector3(0.033, 1.33, 0.025), "wood")
	box(p + Vector3(0.24, 0.72, f + 0.155), Vector3(0.085, 0.08, 0.07), "brass")
	box(p + Vector3(0, 0.09, f + 0.16), Vector3(1.12, 0.18, 0.57), "stone")
	for x in [-w * 0.33, w * 0.33]:
		window(p + Vector3(x, 1.20, f), 0.61, 0.73, door)
		if x > 0:
			box(p + Vector3(x, 0.82, f + 0.13), Vector3(0.77, 0.16, 0.26), "board")
			for j in 6:
				var q := p + Vector3(x - 0.31 + j * 0.12, 0.92, f + 0.19)
				piece(leaf, q, Vector3(0.17, 0.19, 0.19), "638044")
				piece(leaf, q + Vector3.UP * 0.085, Vector3(0.075, 0.07, 0.075), "e3b79c" if j % 2 else "f1d999")
	window(p + Vector3(0, h + ridge * 0.41, f), 0.51, 0.56, door)
	if not sign_text.is_empty():
		var at := p + Vector3(0, h - 0.34, f + 0.12)
		box(at, Vector3(w * 0.67, 0.32, 0.13), "wood")
		box(at + Vector3(0, 0, 0.074), Vector3(w * 0.63, 0.245, 0.027), door)
		sign_label(at + Vector3(0, 0, 0.096), sign_text, 0.0053)
		light_at(p + Vector3(0.75, 1.76, f + 0.60), 4.6, 1.55)
		box(p + Vector3(0.75, 1.82, f + 0.25), Vector3(0.18, 0.29, 0.18), "glass")

func _gable(p: Vector3, w: float, d: float, h: float, material: String) -> void:
	var a := p + Vector3(-w / 2.0, 0, -d / 2.0)
	var b := p + Vector3(w / 2.0, 0, -d / 2.0)
	var c := p + Vector3(0, h, -d / 2.0)
	var dz := Vector3(0, 0, d)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [a, b, c, a + dz, c + dz, b + dz, a, c, c + dz, a, c + dz, a + dz,
			b, b + dz, c + dz, b, c + dz, c]:
		surface.add_vertex(v)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = palette.materials[material]
	add_child(mesh)

func window(p: Vector3, w: float, h: float, shutter: String) -> void:
	box(p, Vector3(w + 0.10, h + 0.11, 0.12), "wood")
	box(p + Vector3(0, 0, 0.066), Vector3(w, h, 0.018), "glass")
	box(p + Vector3(0, 0, 0.091), Vector3(0.049, h, 0.052), "wood")
	box(p + Vector3(0, 0.035, 0.091), Vector3(w, 0.046, 0.052), "wood")
	for side in [-1.0, 1.0]:
		box(p + Vector3(side * (w * 0.5 + 0.105), 0, 0.038), Vector3(0.175, h + 0.035, 0.10), shutter)

func well(p: Vector3) -> void:
	cylinder(p + Vector3.UP * 0.05, 1.28, 0.16, "stone", 12)
	cylinder(p + Vector3.UP * 0.42, 0.94, 0.68, "stone", 12)
	cylinder(p + Vector3.UP * 0.77, 0.70, 0.024, "wellwater", 12)
	for i in 12:
		var theta := i * TAU / 12.0
		box(p + Vector3(cos(theta) * 0.85, 0.78, sin(theta) * 0.85), Vector3(0.35, 0.22, 0.48), "stone", Vector3(0, -theta, 0))
	for side in [-1, 1]:
		box(p + Vector3(side * 0.84, 1.42, 0), Vector3(0.17, 1.82, 0.19), "wood")
		beam(p + Vector3(side * 0.84, 1.49, 0), p + Vector3(side * 0.40, 2.02, 0), 0.09, "wood")
		box(p + Vector3(0, 2.15, side * 0.40), Vector3(2.22, 0.13, 1.10), "roof", Vector3(side * 0.36, 0, 0))
	box(p + Vector3(0, 2.36, 0), Vector3(2.26, 0.15, 0.14), "oak")
	beam(p + Vector3(-0.88, 1.7, 0), p + Vector3(0.88, 1.7, 0), 0.09, "oak")
	box(p + Vector3(0, 1.26, 0), Vector3(0.04, 0.91, 0.04), "oak")
	cylinder(p + Vector3(0, 0.91, 0), 0.13, 0.23, "board")
	collider(p + Vector3.UP * 0.55, Vector3(1.8, 1.1, 1.8), self)

func tree(p: Vector3, s: float, conifer: bool, solid: bool) -> void:
	var trunk := (3.7 if conifer else 2.4) * s
	beam(p + Vector3.UP * 0.03, p + Vector3(0.14 * s, trunk, -0.09 * s), 0.26 * s, "wood")
	if solid:
		collider(p + Vector3.UP * 0.95, Vector3(0.56, 1.9, 0.56) * s, self)
	var shades := ["253d32", "354b33", "415e39", "4f6839", "638044", "77964e", "8da956", "a0af58"]
	if conifer:
		for level in 5:
			var size := 2.9 - level * 0.49
			for i in 4:
				var a := i * TAU / 4.0 + level * 0.58
				var spread := size * 0.21
				var q := p + Vector3(cos(a) * spread, 1.65 + level * 0.55, sin(a) * spread) * s
				piece(leaf, q, Vector3(size * 0.77, 1.48, size * 0.77) * s, shades[mini(6, level + i % 3)], Vector3(0, a, 0.21))
	else:
		for i in 5:
			var a := i * TAU / 5.0
			var q := Vector3(cos(a) * 0.9, 2.58, sin(a) * 0.9) * s
			beam(p + Vector3.UP * 1.25 * s, p + q, 0.15 * s, "board")
		for i in 29:
			var a := i * 2.399
			var r := sqrt(float(i) / 28) * 1.43
			var y := rng.randf_range(2.32, 3.16) + (1.43 - r) * 0.46
			var q := p + Vector3(cos(a) * r, y, sin(a) * r) * s
			var size := rng.randf_range(0.76, 1.46)
			var shade := clampi(roundi((y - 2.38) * 4.0) + rng.randi_range(-1, 2), 0, 7)
			piece(leaf, q, Vector3(size, size * 0.76, size) * s, shades[shade], Vector3(0, a, 0))
			for k in 3:
				var twig := Vector3(cos(a + k * 0.78), 0.43 + k * 0.05, sin(a + k * 0.78)) * size * s * 0.42
				piece(leaf, q + twig, Vector3(0.48, 0.41, 0.46) * size * s, shades[mini(7, shade + k % 2)], Vector3(0, a + k, 0))

func grass(p: Vector3, scale: float) -> void:
	var shades := ["415e39", "638044", "77964e", "8da956", "b7bc65"]
	for i in 3:
		var h := rng.randf_range(0.13, 0.29) * scale
		var q := p + Vector3(rng.randf_range(-0.12, 0.12), h * 0.46, rng.randf_range(-0.12, 0.12))
		piece(tuft, q, Vector3(0.061 * scale, h, 0.045 * scale), shades[rng.randi_range(0, 4)], Vector3(0, rng.randf() * TAU, rng.randf_range(-0.39, 0.39)))

func shrub(p: Vector3) -> void:
	var greens := ["354b33", "415e39", "4f6839", "638044", "77964e", "8da956"]
	for i in 15:
		var a := i * 2.399
		var r := rng.randf_range(0.08, 0.39)
		var h := rng.randf_range(0.18, 0.57)
		var q := p + Vector3(cos(a) * r, h, sin(a) * r)
		var scale := rng.randf_range(0.21, 0.39)
		piece(leaf, q, Vector3(1.0, 0.82, 1.0) * scale, greens[clampi(floori(h * 9.0), 0, 5)], Vector3(0, a, 0))
		if i % 6 == 0:
			piece(leaf, q + Vector3.UP * 0.12, Vector3.ONE * 0.068, "e3b79c")

func flower(p: Vector3) -> void:
	var choices := ["f1d999", "e3b79c", "b784aa", "e2e4c1"]
	var tint: String = choices[rng.randi_range(0, choices.size() - 1)]
	for i in 3:
		var q := p + Vector3(rng.randf_range(-0.18, 0.18), 0, rng.randf_range(-0.18, 0.18))
		var h := rng.randf_range(0.14, 0.31)
		box(q + Vector3.UP * h * 0.5, Vector3(0.025, h, 0.025), "638044")
		piece(leaf, q + Vector3.UP * h, Vector3(0.102, 0.066, 0.102), tint)

func _farm() -> void:
	for i in 5:
		var x := -15.5 + i * 1.10
		paving(Vector3(x, 0, 11.0), Vector2(0.83, 5.0), "garden")
		for j in 13:
			var p := Vector3(x, 0.04, 8.8 + j * 0.36)
			for k in 3:
				var q := p + Vector3((k - 1) * 0.15, 0.11, rng.randf_range(-0.08, 0.08))
				piece(leaf, q, Vector3(0.26, 0.25, 0.25), "8da956" if (i + j + k) % 3 else "4f6839")
			if i % 2 == 0:
				piece(leaf, p + Vector3.UP * 0.24, Vector3(0.16, 0.14, 0.16), "d1aa60")
	fence(Vector3(-16.7, 0, 8.0), Vector3(-10.1, 0, 8.0), 5)
	fence(Vector3(-16.7, 0, 13.9), Vector3(-10.1, 0, 13.9), 5)
	fence(Vector3(-16.7, 0, 8.0), Vector3(-16.7, 0, 13.9), 5)
	barrel(Vector3(-10.55, 0, 9.05))
	sign_label(Vector3(-10.25, 0.98, 8.15), "HORTA", 0.0058)
	box(Vector3(-10.25, 0.96, 8.10), Vector3(0.83, 0.28, 0.10), "wood")
	box(Vector3(-10.25, 0.48, 8.10), Vector3(0.10, 0.96, 0.12), "wood")

func _forge() -> void:
	var p := Vector3(-12.1, 0, 3.48)
	box(p + Vector3(0, 0.33, 0), Vector3(1.35, 0.66, 1.25), "stone")
	box(p + Vector3(0, 0.67, 0), Vector3(1.17, 0.075, 0.99), "iron")
	for i in 8:
		var q := p + Vector3(rng.randf_range(-0.40, 0.40), rng.randf_range(0.67, 0.83), rng.randf_range(-0.34, 0.34))
		piece(leaf, q, Vector3(0.30, 0.24, 0.24), "fire")
	light_at(p + Vector3.UP, 5.1, 1.7)
	var anvil := p + Vector3(0.75, 0, 1.30)
	cylinder(anvil + Vector3.UP * 0.27, 0.33, 0.54, "board", 10)
	box(anvil + Vector3.UP * 0.59, Vector3(0.36, 0.16, 0.31), "iron")
	box(anvil + Vector3.UP * 0.74, Vector3(0.73, 0.16, 0.26), "iron")
	piece(tuft, anvil + Vector3(0.40, 0.73, 0), Vector3(0.34, 0.22, 0.25), "iron", Vector3(0, 0, -PI / 2.0))
	for x in [-0.83, 0.83]:
		for z in [-0.9, 0.9]:
			box(p + Vector3(x, 1.19, z), Vector3(0.13, 2.38, 0.14), "wood")
	box(p + Vector3(0, 2.37, 0), Vector3(2.24, 0.13, 2.23), "mossroof", Vector3(-0.18, 0, 0))
	collider(p + Vector3.UP * 0.47, Vector3(1.3, 0.94, 1.24), self)

func _market(p: Vector3, awning: String) -> void:
	for x in [-1.03, 1.03]:
		for z in [-0.55, 0.55]:
			box(p + Vector3(x, 0.96, z), Vector3(0.095, 1.92, 0.095), "wood")
	box(p + Vector3(0, 0.79, 0), Vector3(2.21, 0.14, 1.09), "oak")
	for i in 11:
		var tint := "ivory" if i % 2 == 0 else awning
		box(p + Vector3(-1.1 + i * 0.22, 1.93, 0), Vector3(0.22, 0.046, 1.42), tint, Vector3(0.12, 0, 0))
		box(p + Vector3(-1.1 + i * 0.22, 1.78, 0.69), Vector3(0.22, 0.18, 0.047), tint)
	for i in 4:
		var q := p + Vector3(-0.82 + i * 0.53, 0.88, 0.10)
		box(q, Vector3(0.41, 0.13, 0.42), "board")
		for j in 5:
			piece(leaf, q + Vector3(rng.randf_range(-0.14, 0.14), 0.10, rng.randf_range(-0.14, 0.14)), Vector3.ONE * 0.13, ["d1aa60", "e3b79c", "8da956", "f1d999"][i])
	collider(p + Vector3.UP * 0.44, Vector3(2.12, 0.88, 1.03), self)

func _cave() -> void:
	var p := Vector3(21.0, 0, -19.1)
	paving(Vector3(21, 0, -15.7), Vector2(2.4, 7.0), "trail")
	for i in 25:
		var q := p + Vector3(rng.randf_range(-4.8, 4.8), rng.randf_range(0.12, 1.15), rng.randf_range(-3.4, 0.2))
		if absf(q.x - p.x) < 1.4 and q.z > p.z - 0.8:
			continue
		var rock := rng.randf_range(1.1, 3.2)
		piece(leaf, q, Vector3(rock, rock * 0.93, rock), "stone" if i % 2 else "627b68", Vector3(0, i * 0.9, 0.2))
	box(p + Vector3.UP * 1.03, Vector3(2.02, 2.05, 0.27), "dark")
	for i in 9:
		var a := float(i) * PI / 8.0
		box(p + Vector3(cos(a) * 1.13, 1.12 + sin(a) * 1.13, 0.23), Vector3(0.43, 0.47, 0.52), "stone", Vector3(0, 0, a))
	for side in [-1, 1]:
		box(p + Vector3(side * 1.11, 0.56, 0.23), Vector3(0.46, 1.12, 0.55), "stone")
	collider(p + Vector3.UP, Vector3(8.1, 2.0, 0.45), self)
	lamp(p + Vector3(-2.0, 0, 0.8))
	lamp(p + Vector3(2.0, 0, 0.8))

func lamp(p: Vector3) -> void:
	box(p + Vector3.UP * 0.11, Vector3(0.37, 0.22, 0.34), "stone")
	box(p + Vector3.UP * 0.99, Vector3(0.105, 1.98, 0.105), "wood")
	box(p + Vector3.UP * 2.03, Vector3(0.26, 0.31, 0.26), "glass")
	for x in [-0.131, 0.131]:
		for z in [-0.131, 0.131]:
			box(p + Vector3(x, 2.03, z), Vector3(0.039, 0.36, 0.039), "iron")
	box(p + Vector3.UP * 1.86, Vector3(0.32, 0.06, 0.32), "iron")
	piece(tuft, p + Vector3.UP * 2.23, Vector3(0.39, 0.13, 0.39), "iron")
	light_at(p + Vector3.UP * 2.03, 5.1, 1.45)

func light_at(p: Vector3, radius: float, energy: float) -> void:
	if halo_texture == null:
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				var distance := (Vector2(x, y) - Vector2(15.5, 15.5)).length() / 15.5
				image.set_pixel(x, y, Color(1.0, 0.72, 0.37, pow(maxf(0.0, 1.0 - distance), 2.9)))
		halo_texture = ImageTexture.create_from_image(image)
	var halo := Sprite3D.new()
	halo.position = p + Vector3.UP * 0.01
	halo.texture = halo_texture
	halo.pixel_size = 0.039
	halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)
	halos.append(halo)
	var lamp_light := OmniLight3D.new()
	lamp_light.position = p
	lamp_light.light_color = Color("ffc081")
	lamp_light.omni_range = radius
	lamp_light.light_energy = energy
	lamp_light.set_meta("base_energy", energy)
	add_child(lamp_light)
	lanterns.append(lamp_light)

func bench(p: Vector3) -> void:
	for x in [-0.60, 0.60]:
		box(p + Vector3(x, 0.23, 0), Vector3(0.12, 0.46, 0.36), "wood")
		box(p + Vector3(x, 0.62, -0.17), Vector3(0.10, 0.68, 0.10), "wood")
	box(p + Vector3(0, 0.44, 0), Vector3(1.57, 0.11, 0.43), "oak")
	box(p + Vector3(0, 0.77, -0.17), Vector3(1.57, 0.18, 0.095), "board")

func barrel(p: Vector3) -> void:
	cylinder(p + Vector3.UP * 0.32, 0.27, 0.65, "oak", 10)
	for y in [0.13, 0.49]:
		cylinder(p + Vector3.UP * y, 0.285, 0.053, "iron", 10)

func fence(a: Vector3, b: Vector3, spans: int) -> void:
	for i in spans + 1:
		var p := a.lerp(b, float(i) / spans)
		box(p + Vector3.UP * 0.40, Vector3(0.14, 0.8, 0.15), "wood")
	for y in [0.30, 0.57]:
		beam(a + Vector3.UP * y, b + Vector3.UP * y, 0.086, "board")

func update_bridge(stage: int) -> void:
	for child in project_bridge.get_children():
		project_bridge.remove_child(child)
		child.queue_free()
	_bridge(project_bridge, -12.0, stage, false)

func _bridge(root: Node3D, z: float, stage: int, stone: bool) -> void:
	for x in [10.26, 15.74]:
		live_box(root, Vector3(x, -0.27, z), Vector3(0.76, 0.77, 2.85), "stone")
	if stone or stage >= 1:
		for x in [10.55, 12.14, 13.86, 15.45]:
			for offset in [-0.95, 0.95]:
				live_box(root, Vector3(x, -0.39, z + offset), Vector3(0.18, 1.47, 0.19), "board" if not stone else "stone")
	if stage >= 2:
		for offset in [-0.82, 0.82]:
			live_box(root, Vector3(13, -0.10, z + offset), Vector3(6.50, 0.24, 0.18), "wood")
	if stone or stage >= 3:
		for i in 27:
			live_box(root, Vector3(9.88 + 0.24 * i, 0.01, z), Vector3(0.23, 0.14, 2.53), "stone" if stone else "oak")
		for side in [-1, 1]:
			var rz: float = z + side * 1.24
			live_box(root, Vector3(13, 0.61, rz), Vector3(6.69, 0.12, 0.16), "stone" if stone else "board")
			live_box(root, Vector3(13, 0.27, rz), Vector3(6.64, 0.13, 0.13), "stone" if stone else "board")
			for x in [9.73, 10.81, 11.9, 13, 14.1, 15.19, 16.27]:
				live_box(root, Vector3(x, 0.36, rz), Vector3(0.21, 0.80, 0.21), "stone" if stone else "wood")
			collider(Vector3(13, 0.42, rz), Vector3(6.74, 1.1, 0.17), root)
	else:
		collider(Vector3(10.0, 0.60, z), Vector3(0.21, 1.7, 2.55), root)
		collider(Vector3(16.0, 0.60, z), Vector3(0.21, 1.7, 2.55), root)
		for side in [-1, 1]:
			var rz: float = z + side * 1.64
			for x in [8.99, 10.45, 15.55, 17.01]:
				live_box(root, Vector3(x, 0.87, rz), Vector3(0.16, 2.31, 0.16), "board")
			for x in [9.71, 16.29]:
				live_box(root, Vector3(x, 1.15, rz), Vector3(1.60, 0.13, 0.14), "oak", Vector3(0, 0, side * 0.65))
				live_box(root, Vector3(x, 1.83, rz), Vector3(1.76, 0.12, 0.79), "oak")
		for i in stage + 1:
			live_box(root, Vector3(8.86, 0.16 + i * 0.10, z - 0.95), Vector3(1.56, 0.11, 0.28), "oak")

func live_box(root: Node3D, p: Vector3, size: Vector3, material: String, rot := Vector3.ZERO) -> void:
	var node := MeshInstance3D.new()
	node.mesh = cube
	node.material_override = palette.materials[material]
	node.transform = Transform3D(Basis.from_euler(rot).scaled_local(size), p)
	root.add_child(node)

func paving(p: Vector3, size: Vector2, material: String) -> void:
	box(p + Vector3.UP * 0.003, Vector3(size.x, 0.035, size.y), material)

func cylinder(p: Vector3, radius: float, height: float, material: String, sides := 12) -> void:
	var node := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = sides
	shape.rings = 1
	node.mesh = shape
	node.position = p
	node.material_override = palette.materials[material]
	add_child(node)

func sign_label(p: Vector3, value: String, size: float) -> void:
	var sign := Label3D.new()
	sign.text = value
	sign.pixel_size = size
	sign.font_size = 32
	sign.outline_size = 0
	sign.modulate = Color("efdba5")
	sign.position = p
	add_child(sign)

func beam(a: Vector3, b: Vector3, width: float, material: String) -> void:
	var delta := b - a
	var basis := Basis(Quaternion(Vector3.UP, delta.normalized())).scaled_local(Vector3(width, delta.length(), width))
	_enqueue(cube, material, Transform3D(basis, (a + b) * 0.5))

func box(p: Vector3, size: Vector3, material: String, rot := Vector3.ZERO) -> void:
	piece(cube, p, size, material, rot)

func piece(mesh: Mesh, p: Vector3, size: Vector3, material: String, rot := Vector3.ZERO) -> void:
	_enqueue(mesh, material, Transform3D(Basis.from_euler(rot).scaled_local(size), p))

func _enqueue(mesh: Mesh, material: String, transform_value: Transform3D) -> void:
	var key := "%s:%s" % [mesh.get_instance_id(), material]
	if not batches.has(key):
		batches[key] = {"mesh": mesh, "material": material, "items": []}
	batches[key].items.append(transform_value)

func _flush() -> void:
	for entry in batches.values():
		var group := MultiMesh.new()
		group.transform_format = MultiMesh.TRANSFORM_3D
		group.mesh = entry.mesh
		group.instance_count = entry.items.size()
		for i in entry.items.size():
			group.set_instance_transform(i, entry.items[i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = group
		instance.material_override = palette.materials[entry.material]
		if entry.mesh == tuft:
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
	batches.clear()

func collider(p: Vector3, size: Vector3, root: Node3D) -> void:
	var body := StaticBody3D.new()
	var hitbox := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	hitbox.shape = shape
	body.position = p
	body.add_child(hitbox)
	root.add_child(body)
