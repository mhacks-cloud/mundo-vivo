class_name ValeFoliage
extends Node3D

const SHADER := preload("res://shaders/foliage.gdshader")
const VARIANTS := ["oak_leaf", "pine_bough", "bramble", "meadow_tuft"]
var records: Dictionary = {}
var groups: Array[MultiMeshInstance3D] = []
var materials: Dictionary = {}
var plane := QuadMesh.new()
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 5371

func plant(kind: String, p: Vector3, size: Vector2, turn: float, tier: int, tint: Color, tilt := 0.0) -> void:
	var key := "%s:%s" % [kind, tier]
	if not records.has(key):
		records[key] = {"kind": kind, "tier": tier, "items": []}
	var orient := Basis.from_euler(Vector3(tilt, turn, rng.randf_range(-0.14, 0.14)))
	var xform := Transform3D(orient.scaled_local(Vector3(size.x, size.y, 1.0)), p)
	records[key].items.append([xform, tint])

func build() -> void:
	for name_value in VARIANTS:
		var texture_path := "res://assets/textures/%s.png" % name_value
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("foliage_texture", load(texture_path) if ResourceLoader.exists(texture_path) else _fallback(name_value))
		material.set_shader_parameter("wind", 0.13 if name_value == "meadow_tuft" else 0.07)
		materials[name_value] = material
	for entry in records.values():
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_colors = true
		instances.mesh = plane
		instances.instance_count = entry.items.size()
		for i in entry.items.size():
			instances.set_instance_transform(i, entry.items[i][0])
			instances.set_instance_color(i, entry.items[i][1])
		var group := MultiMeshInstance3D.new()
		group.multimesh = instances
		group.material_override = materials[entry.kind]
		group.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED if entry.tier == 0 and entry.kind in ["oak_leaf", "pine_bough"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		group.set_meta("tier", entry.tier)
		add_child(group)
		groups.append(group)
	records.clear()

func quality(value: int) -> void:
	for group in groups:
		group.visible = int(group.get_meta("tier")) <= value

func atmosphere(index: int, wet: bool) -> void:
	var tones := [Color("b9d07d"), Color("faf3cb"), Color("e59a4d"), Color("9c9d70")]
	for kind in materials:
		var material: ShaderMaterial = materials[kind]
		var tint: Color = tones[index]
		if kind == "pine_bough":
			tint = tint.lerp(Color("d4e2c6"), 0.77)
		material.set_shader_parameter("season_tint", tint)
		material.set_shader_parameter("wind", (0.13 if kind == "meadow_tuft" else 0.07) * (1.75 if wet else 1.0))

func camera_window(from: Vector3, target: Vector3) -> void:
	for material in materials.values():
		material.set_shader_parameter("camera_origin", from)
		material.set_shader_parameter("actor_position", target)
		material.set_shader_parameter("cutaway", 1.0)

func _fallback(kind: String) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var random := RandomNumberGenerator.new()
	random.seed = 5412
	var grass := kind == "meadow_tuft"
	for i in (145 if grass else 820):
		var angle := random.randf() * TAU
		var radius := sqrt(random.randf())
		var x := roundi(31 + cos(angle) * radius * 29.0)
		var y := roundi(33 + sin(angle) * radius * 24.0)
		var shade := random.randf_range(0.4, 1.0)
		var tone := Color("334729").lerp(Color("aab961"), shade)
		if grass:
			x = random.randi_range(4, 59)
			y = random.randi_range(19, 46)
		for d in (random.randi_range(6, 17) if grass else 4):
			img.set_pixel(clampi(x + (d / 5 if grass else d % 3), 0, 63), clampi(y + (d if grass else d / 3), 0, 63), tone)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
