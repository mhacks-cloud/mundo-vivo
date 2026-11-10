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
var foliage := ValeFoliage.new()
var ground := ShaderMaterial.new()
var river := ShaderMaterial.new()
var trunks := CylinderMesh.new()
var batch_root: Node3D
var footprints := PackedVector4Array()
var occluded: Array[Node3D] = []
var crop_full := Node3D.new()
var crop_sprouts := Node3D.new()

func _ready() -> void:
	rng.seed = 92451
	tuft.left_to_right = 0.25
	leaf.radial_segments = 7
	leaf.rings = 3
	trunks.top_radius = 0.32
	trunks.bottom_radius = 0.52
	trunks.height = 1.0
	trunks.radial_segments = 7
	trunks.rings = 0
	add_child(foliage)
	_build_land()
	_build_village()
	_ground_cover()
	ground.set_shader_parameter("footprints", footprints)
	foliage.build()
	_flush()
	permanent_bridge = Node3D.new()
	add_child(permanent_bridge)
	_bridge(permanent_bridge, 2.0, 3, true, 10)
	project_bridge = Node3D.new()
	add_child(project_bridge)
	update_bridge(0)

func _build_land() -> void:
	box(Vector3(-18.5, -0.69, -7), Vector3(57, 1.32, 104), "earth")
	_soil(Vector3(-18.5, -0.008, -7), Vector2(57, 104))
	box(Vector3(31.5, -0.69, -7), Vector3(31, 1.32, 104), "earth")
	_soil(Vector3(31.5, -0.008, -7), Vector2(31, 104))
	var water := MeshInstance3D.new()
	var surface := PlaneMesh.new()
	surface.size = Vector2(6, 104)
	water.mesh = surface
	river.shader = preload("res://shaders/river.gdshader")
	water.material_override = river
	water.position = Vector3(13, -0.48, -7)
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
	_ridge(-48.0, 9.0)
	_ridge(17.0, 48.0)
	for i in 172:
		var x := rng.randf_range(-39, 39)
		var z := rng.randf_range(-41, 34)
		if (x > -15 and x < 17 and z > -19 and z < 18) or (x > 8 and x < 18):
			continue
		if x > 16 and x < 26 and z > -17 and z < 6:
			continue
		if not Homestead.within_residential(x, z) and Vector2(x, z).distance_squared_to(Vector2(22.0, 5.7)) > 16.0:
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
	var appearance := footprints.size()
	batch_root = Node3D.new()
	batch_root.name = "Fachada%d" % appearance
	add_child(batch_root)
	footprints.append(Vector4(p.x, p.z, w * 0.5, d * 0.5))
	var front := d * 0.5
	var ridge := w * (0.43 if appearance in [0, 7] else 0.28 if appearance in [3, 5] else 0.34)
	box(p + Vector3(0, h * 0.5, 0), Vector3(w, h, d), wall)
	box(p + Vector3(0, 0.25, 0), Vector3(w + 0.12, 0.5, d + 0.13), "stone")
	var wall_hit := collider(p + Vector3(0, h * 0.5, 0), Vector3(w, h, d), self)
	wall_hit.set_meta("facade", batch_root)
	var roof_hit := collider(p + Vector3(0, h + ridge * 0.34, 0), Vector3(w * 0.77, ridge * 0.70, d + 0.30), self)
	roof_hit.collision_layer = 4
	roof_hit.set_meta("facade", batch_root)
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
	_facade_detail(p, w, d, h, ridge, appearance, door, roof)
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
	batch_root = null

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
	_visual_parent().add_child(mesh)

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
	var height := (rng.randf_range(4.1, 6.4) if conifer else rng.randf_range(3.3, 4.5)) * s
	var lean := Vector3(rng.randf_range(-0.43, 0.43), 0, rng.randf_range(-0.36, 0.36)) * s
	var fork := p + Vector3.UP * height * 0.48 + lean * 0.35
	_branch(p, fork, 0.34 * s)
	_branch(fork, p + Vector3.UP * height * 0.87 + lean, 0.21 * s)
	if solid:
		collider(p + Vector3.UP * 0.95, Vector3(0.49, 1.9, 0.49) * s, self)
	var turn := rng.randf() * TAU
	if conifer:
		var width := rng.randf_range(2.1, 3.45) * s
		for level in 6:
			var rise := float(level) / 5.0
			var y := height * (0.32 + rise * 0.62)
			var size := width * (1.0 - 0.80 * rise)
			for i in 4:
				var angle := turn + i * PI / 2.0 + level * 0.57
				var q := p + Vector3(cos(angle) * size * 0.13, y, sin(angle) * size * 0.13) + lean * rise
				foliage.plant("pine_bough", q, Vector2(size, size * 0.65), angle, 1 if i == 2 else 2 if i == 3 else 0,
					Color(0.70 + rise * 0.23, 0.80 + rise * 0.15, 0.73 + rise * 0.20, 0.82), 0.05 + rise * 0.24)
	else:
		var width := rng.randf_range(2.0, 3.1) * s
		for arm in 6:
			var a := turn + arm * 2.399
			var reach := width * rng.randf_range(0.16, 0.48)
			var branch := p + lean + Vector3(cos(a) * reach, height * rng.randf_range(0.60, 0.91), sin(a) * reach)
			_branch(fork, branch, s * rng.randf_range(0.10, 0.15))
			for i in 3:
				var q := branch + Vector3(cos(a) * i * 0.08, 0.30 + i * 0.12, sin(a) * i * 0.11)
				var shade := rng.randf_range(0.72, 1.03)
				foliage.plant("oak_leaf", q, Vector2(width, width * 0.59) * rng.randf_range(0.69, 1.04),
					a + PI / 3.0 * i, 0 if i < 2 else 1, Color(shade, shade, shade * 0.88, 0.02), -0.20 + 0.19 * i)
		foliage.plant("oak_leaf", p + lean + Vector3.UP * height, Vector2(width * 0.74, width * 0.49), turn, 0, Color(1, 1, 0.87, 0.0))
		if solid:
			for i in 20:
				var a := rng.randf() * TAU
				var r := rng.randf_range(0.60, 1.94)
				var spot := p + Vector3(cos(a) * r, 0.009, sin(a) * r)
				piece(tuft, spot, Vector3(0.07, 0.017, 0.11), "d1aa60" if i % 3 == 0 else "4f6839", Vector3(0, a, 0))

func _branch(a: Vector3, b: Vector3, width: float) -> void:
	var delta := b - a
	var basis := Basis(Quaternion(Vector3.UP, delta.normalized())).scaled_local(Vector3(width, delta.length(), width))
	_enqueue(trunks, "bark", Transform3D(basis, (a + b) * 0.5))

func grass(p: Vector3, scale: float) -> void:
	var height := scale * rng.randf_range(0.31, 0.58)
	var tone := rng.randf_range(0.69, 1.02)
	var tint := Color(tone, tone, tone * 0.89, 0.08)
	var facing := rng.randf() * TAU
	var q := p + Vector3.UP * height * 0.38
	var size := Vector2(height * 1.55, height)
	foliage.plant("meadow_tuft", q, size, facing, 1, tint)
	if rng.randf() > 0.59:
		foliage.plant("meadow_tuft", q, size, facing + PI * 0.5, 2, tint)

func shrub(p: Vector3) -> void:
	var scale := rng.randf_range(0.67, 1.28)
	var turn := rng.randf() * TAU
	for i in 3:
		var a := turn + i * PI / 3.0
		var q := p + Vector3(cos(a) * 0.11, 0.37 * scale, sin(a) * 0.11)
		foliage.plant("bramble", q, Vector2(scale, scale * 0.74), a, 0 if i < 2 else 1,
			Color(0.90 + i * 0.04, 0.89 + i * 0.04, 0.87, 0.20))
func flower(p: Vector3) -> void:
	var choices := ["f1d999", "e3b79c", "b784aa", "e2e4c1"]
	var tint: String = choices[rng.randi_range(0, choices.size() - 1)]
	for i in 3:
		var q := p + Vector3(rng.randf_range(-0.18, 0.18), 0, rng.randf_range(-0.18, 0.18))
		var h := rng.randf_range(0.14, 0.31)
		box(q + Vector3.UP * h * 0.5, Vector3(0.025, h, 0.025), "638044")
		piece(leaf, q + Vector3.UP * h, Vector3(0.102, 0.066, 0.102), tint)

func _farm() -> void:
	add_child(crop_full)
	add_child(crop_sprouts)
	for i in 5:
		var x := -15.5 + i * 1.10
		paving(Vector3(x, 0, 11.0), Vector2(0.83, 5.0), "garden")
		batch_root = crop_full
		for j in 13:
			var p := Vector3(x, 0.04, 8.8 + j * 0.36)
			for k in 3:
				var q := p + Vector3((k - 1) * 0.15, 0.11, rng.randf_range(-0.08, 0.08))
				piece(leaf, q, Vector3(0.26, 0.25, 0.25), "8da956" if (i + j + k) % 3 else "4f6839")
			if i % 2 == 0:
				piece(leaf, p + Vector3.UP * 0.24, Vector3(0.16, 0.14, 0.16), "d1aa60")
		batch_root = crop_sprouts
		for j in 13:
			box(Vector3(x, 0.065, 8.8 + j * 0.36), Vector3(0.065, 0.12, 0.055), "77964e", Vector3(0, 0, 0.31))
		batch_root = null
	fence(Vector3(-16.7, 0, 8.0), Vector3(-10.1, 0, 8.0), 5)
	fence(Vector3(-16.7, 0, 13.9), Vector3(-10.1, 0, 13.9), 5)
	fence(Vector3(-16.7, 0, 8.0), Vector3(-16.7, 0, 13.9), 5)
	barrel(Vector3(-10.55, 0, 9.05))
	sign_label(Vector3(-10.25, 0.98, 8.15), "HORTA", 0.0058)
	box(Vector3(-10.25, 0.96, 8.10), Vector3(0.83, 0.28, 0.10), "wood")
	box(Vector3(-10.25, 0.48, 8.10), Vector3(0.10, 0.96, 0.12), "wood")

func update_crop(phase: int) -> void:
	crop_full.visible = phase == 4
	crop_sprouts.visible = phase in [2, 3]

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
	for i in 25:
		var q := p + Vector3(rng.randf_range(-4.8, 4.8), rng.randf_range(0.12, 1.15), rng.randf_range(-3.4, 0.2))
		if absf(q.x - p.x) < 1.4 and q.z > p.z - 0.8:
			continue
		var rock := rng.randf_range(1.1, 3.2)
		piece(leaf, q, Vector3(rock, rock * 0.93, rock), "stone" if i % 2 else "mossstone", Vector3(0, i * 0.9, 0.2))
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
	_visual_parent().add_child(halo)
	halos.append(halo)
	var lamp_light := OmniLight3D.new()
	lamp_light.position = p
	lamp_light.light_color = Color("ffc081")
	lamp_light.omni_range = radius
	lamp_light.light_energy = energy
	lamp_light.set_meta("base_energy", energy)
	_visual_parent().add_child(lamp_light)
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
	var extent := (b - a).abs()
	collider((a + b) * 0.5 + Vector3.UP * 0.37, Vector3(extent.x + 0.11, 0.74, extent.z + 0.11), self)
	for i in spans + 1:
		var p := a.lerp(b, float(i) / spans)
		box(p + Vector3.UP * 0.40, Vector3(0.14, 0.8, 0.15), "wood")
	for y in [0.30, 0.57]:
		beam(a + Vector3.UP * y, b + Vector3.UP * y, 0.086, "board")

func update_bridge(stage: int, phase := 0) -> void:
	for child in project_bridge.get_children():
		project_bridge.remove_child(child)
		child.queue_free()
	_bridge(project_bridge, -12.0, stage, false, phase)

func _bridge(root: Node3D, z: float, stage: int, stone: bool, phase: int) -> void:
	batch_root = root
	if stone or phase >= 4:
		for x in [10.26, 15.74]:
			box(Vector3(x, -0.27, z), Vector3(0.76, 0.77, 2.85), "stone" if stone or phase >= 6 else "earth")
	if stone or phase >= 6:
		for x in [10.55, 12.14, 13.86, 15.45]:
			for offset in [-0.95, 0.95]:
				box(Vector3(x, -0.39, z + offset), Vector3(0.18, 1.47, 0.19), "board" if not stone else "stone")
	if stone or phase >= 7:
		for offset in [-0.82, 0.82]:
			box(Vector3(13, -0.10, z + offset), Vector3(6.50, 0.24, 0.18), "wood")
	if stone or phase >= 8:
		for i in (27 if stone or phase >= 9 else 17):
			box(Vector3(9.88 + 0.24 * i, 0.01, z), Vector3(0.23, 0.14, 2.53), "stone" if stone else "oak")
		for side in [-1, 1]:
			var rz: float = z + side * 1.24
			box(Vector3(13, 0.61, rz), Vector3(6.69, 0.12, 0.16), "stone" if stone else "board")
			box(Vector3(13, 0.27, rz), Vector3(6.64, 0.13, 0.13), "stone" if stone else "board")
			for x in [9.73, 10.81, 11.9, 13, 14.1, 15.19, 16.27]:
				box(Vector3(x, 0.36, rz), Vector3(0.21, 0.80, 0.21), "stone" if stone else "wood")
			if stone or stage >= 3:
				collider(Vector3(13, 0.42, rz), Vector3(6.74, 1.1, 0.17), root)
	if not stone and stage < 3:
		collider(Vector3(10.0, 0.60, z), Vector3(0.21, 1.7, 2.55), root)
		collider(Vector3(16.0, 0.60, z), Vector3(0.21, 1.7, 2.55), root)
		if phase >= 3:
			box(Vector3(8.84, 0.17, z + 1.45), Vector3(0.46, 0.32, 0.50), "board")
		for side in [-1, 1]:
			var rz: float = z + side * 1.64
			for x in [8.99, 10.45, 15.55, 17.01]:
				var height := 2.31 if phase >= 5 else 0.74
				box(Vector3(x, height * 0.37, rz), Vector3(0.16, height, 0.16), "board")
			if phase >= 5:
				for x in [9.71, 16.29]:
					box(Vector3(x, 1.15, rz), Vector3(1.60, 0.13, 0.14), "oak", Vector3(0, 0, side * 0.65))
					box(Vector3(x, 1.83, rz), Vector3(1.76, 0.12, 0.79), "oak")
		for i in stage + 1:
			box(Vector3(8.86, 0.16 + i * 0.10, z - 0.95), Vector3(1.56, 0.11, 0.28), "oak")
	batch_root = null
	_flush()

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
	_visual_parent().add_child(sign)

func beam(a: Vector3, b: Vector3, width: float, material: String) -> void:
	var delta := b - a
	var basis := Basis(Quaternion(Vector3.UP, delta.normalized())).scaled_local(Vector3(width, delta.length(), width))
	_enqueue(cube, material, Transform3D(basis, (a + b) * 0.5))

func box(p: Vector3, size: Vector3, material: String, rot := Vector3.ZERO) -> void:
	piece(cube, p, size, material, rot)

func piece(mesh: Mesh, p: Vector3, size: Vector3, material: String, rot := Vector3.ZERO) -> void:
	_enqueue(mesh, material, Transform3D(Basis.from_euler(rot).scaled_local(size), p))

func _enqueue(mesh: Mesh, material: String, transform_value: Transform3D) -> void:
	var root := _visual_parent()
	var key := "%s:%s:%s" % [mesh.get_instance_id(), material, root.get_instance_id()]
	if not batches.has(key):
		batches[key] = {"mesh": mesh, "material": material, "items": [], "root": root}
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
		entry.root.add_child(instance)
	batches.clear()

func collider(p: Vector3, size: Vector3, root: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	var hitbox := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	hitbox.shape = shape
	body.position = p
	body.add_child(hitbox)
	root.add_child(body)
	return body

func _visual_parent() -> Node3D:
	return batch_root if batch_root != null else self

func camera_visibility(from: Vector3, target: Vector3) -> bool:
	foliage.camera_window(from, target)
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, target, 5)
	var next: Array[Node3D] = []
	var exclude: Array[RID] = []
	var other := false
	for i in 5:
		query.exclude = exclude
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			break
		var body: StaticBody3D = hit.collider
		if not body.has_meta("facade"):
			other = true
			break
		var facade: Node3D = body.get_meta("facade")
		if facade not in next:
			next.append(facade)
		exclude.append(body.get_rid())
	for facade in occluded:
		if is_instance_valid(facade) and facade not in next:
			facade.show()
	for facade in next:
		facade.hide()
	occluded = next
	return other

func weather(index: int, wet: bool, snow: bool, light: float) -> void:
	foliage.atmosphere(index, wet)
	var tints := [Color("c7d59a"), Color("e1db9a"), Color("d9ac69"), Color("aaae9d")]
	ground.set_shader_parameter("ground_tint", tints[index])
	ground.set_shader_parameter("wetness", 1.0 if wet else 0.0)
	ground.set_shader_parameter("frost", 0.34 if snow else 0.0)
	river.set_shader_parameter("daylight", light)
	river.set_shader_parameter("rain", 1.0 if wet else 0.0)

func _soil(p: Vector3, size: Vector2) -> void:
	if ground.shader == null:
		ground.shader = preload("res://shaders/terrain.gdshader")
		var names := {"grass_map": ["meadow", "grass"], "dirt_map": ["path_dirt", "trail"],
			"cobble_map": ["setts", "cobble"], "bank_map": ["riverbank", "earth"]}
		for key in names:
			var entry: Array = names[key]
			var path := "res://assets/textures/%s.png" % entry[0]
			ground.set_shader_parameter(key, load(path) if ResourceLoader.exists(path) else palette.materials[entry[1]].albedo_texture)
	var node := MeshInstance3D.new()
	var surface := PlaneMesh.new()
	surface.size = size
	node.mesh = surface
	node.material_override = ground
	node.position = p
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)

func _ridge(left: float, right: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 13:
		for col in 18:
			var corners := PackedVector3Array()
			for offset in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var x := lerpf(left, right, (col + offset.x) / 18.0)
				var z: float = -26.0 - (row + offset.y) * 2.57
				var mound := (1.9 + 1.15 * sin(x * 0.19) + 0.63 * cos(x * 0.43 + z * 0.21))
				var y := -0.055 + mound * smoothstep(-28.0, -46.0, z)
				corners.append(Vector3(x, y, z))
			for i in [0, 2, 1, 0, 3, 2]:
				surface.add_vertex(corners[i])
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = ground
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

func _ground_cover() -> void:
	for i in 260:
		var z := rng.randf_range(-27, 20)
		var bank := 9.56 if i % 2 == 0 else 16.40
		if absf(z - 2.0) > 1.6 and absf(z + 12.0) > 1.7:
			var p := Vector3(bank + rng.randf_range(-0.25, 0.25), 0, z)
			grass(p, rng.randf_range(0.78, 1.68))
			if i % 18 == 0:
				shrub(p)
	for i in 176:
		var x := rng.randf_range(-11, 9.4)
		var z := rng.randf_range(-16, 14)
		if absf(x) < 5.7 and z > -4.6 and z < 4.65:
			continue
		var p := Vector3(x, 0.04, z)
		var size := rng.randf_range(0.075, 0.21)
		piece(leaf, p, Vector3(size, size * 0.49, size * 0.8), "stone", Vector3(0, rng.randf() * TAU, 0))
	for i in 75:
		var z := rng.randf_range(4.9, 14.6)
		var x := rng.randf_range(1.15, 2.75) * (-1.0 if i % 2 == 0 else 1.0)
		var p := Vector3(x, 0, z)
		grass(p, rng.randf_range(0.73, 1.49))
		if i % 7 == 0:
			flower(p)
	_cart(Vector3(-3.9, 0, -5.92))
	for p in [Vector3(-5.1, 0, -3.81), Vector3(3.97, 0, -5.11), Vector3(8.45, 0, -3.72), Vector3(-6.7, 0, 6.1)]:
		_planter(p)
	for p in [Vector3(-11.85, 0, 5.14), Vector3(7.4, 0, -13.58), Vector3(-7.97, 0, -2.39)]:
		_crate(p)

func _facade_detail(p: Vector3, w: float, d: float, h: float, ridge: float, style: int, trim: String, roof: String) -> void:
	var z := d * 0.5 + 0.10
	for j in 8:
		var x := (float(j) / 7.0 - 0.5) * (w - 0.3)
		box(p + Vector3(x, 0.21 + (j % 2) * 0.15, z), Vector3(0.30, 0.15, 0.11), "stone", Vector3(0, 0, (j % 3 - 1) * 0.04))
	for x in [-w * 0.32, w * 0.32]:
		box(p + Vector3(x, 1.65, z), Vector3(0.85, 0.09, 0.22), "oak")
		box(p + Vector3(x, 0.78, z), Vector3(0.87, 0.13, 0.22), "stone")
		for side in [-0.35, 0.35]:
			box(p + Vector3(x + side, 1.18, z + 0.06), Vector3(0.06, 0.76, 0.08), "oak")
	if style in [0, 2, 8]:
		var balcony := p + Vector3(0, h + 0.18, z + 0.34)
		box(balcony, Vector3(w * 0.54, 0.13, 0.78), "wood")
		box(balcony + Vector3(0, 0.48, 0.37), Vector3(w * 0.55, 0.10, 0.09), "oak")
		for i in 8:
			var x := (float(i) / 7.0 - 0.5) * w * 0.52
			box(balcony + Vector3(x, 0.25, 0.37), Vector3(0.062, 0.45, 0.065), trim)
		for x in [-w * 0.21, w * 0.21]:
			beam(balcony + Vector3(x, -0.47, -0.38), balcony + Vector3(x, 0, 0.27), 0.10, "wood")
	elif style in [1, 4, 5]:
		var lean := p + Vector3(-w * 0.23, h * 0.74, z + 0.39)
		box(lean, Vector3(w * 0.45, 0.12, 0.91), roof, Vector3(0.24, 0, 0))
		for x in [-w * 0.19, w * 0.19]:
			beam(lean + Vector3(x, -0.49, -0.40), lean + Vector3(x, 0, 0.32), 0.10, "wood")
	else:
		for x in [-w * 0.30, w * 0.30]:
			beam(p + Vector3(x, h + 0.05, z), p + Vector3(x * 0.3, h + ridge * 0.65, z), 0.095, "board")
	for row in 5:
		var y := h + ridge * 0.48 + 0.13 * row
		box(p + Vector3(w * 0.32, y, -d * 0.23), Vector3(0.59, 0.025, 0.59), "earth")

func _crate(p: Vector3) -> void:
	box(p + Vector3.UP * 0.21, Vector3(0.48, 0.43, 0.45), "board")
	for side in [-0.21, 0.21]:
		box(p + Vector3(side, 0.22, 0.23), Vector3(0.06, 0.43, 0.05), "oak")
	beam(p + Vector3(-0.20, 0.05, 0.24), p + Vector3(0.20, 0.38, 0.24), 0.043, "oak")

func _planter(p: Vector3) -> void:
	cylinder(p + Vector3.UP * 0.135, 0.18, 0.27, "roof", 9)
	cylinder(p + Vector3.UP * 0.265, 0.205, 0.07, "roof", 9)
	flower(p + Vector3.UP * 0.26)

func _cart(p: Vector3) -> void:
	box(p + Vector3.UP * 0.57, Vector3(0.80, 0.13, 1.18), "oak")
	for x in [-0.43, 0.43]:
		box(p + Vector3(x, 0.75, 0), Vector3(0.075, 0.28, 1.21), "board")
		beam(p + Vector3(x * 0.74, 0.54, 0.48), p + Vector3(x * 0.74, 0.34, 1.49), 0.075, "wood")
		for j in 10:
			var a := float(j) * TAU / 10.0
			var b := float(j + 1) * TAU / 10.0
			var center := p + Vector3(x * 1.26, 0.34, -0.08)
			var a_pos := center + Vector3(0, sin(a), cos(a)) * 0.34
			var b_pos := center + Vector3(0, sin(b), cos(b)) * 0.34
			beam(a_pos, b_pos, 0.058, "wood")
			if j % 2 == 0:
				beam(center, a_pos, 0.034, "oak")
	for q in [Vector3(-0.11, 0.65, -0.24), Vector3(0.10, 0.65, 0.27)]:
		_crate(p + q)
