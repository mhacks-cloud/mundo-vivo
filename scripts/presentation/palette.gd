class_name ValePalette
extends RefCounted

var materials: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 77208
	make("grass", "667849", "grass", 0.55)
	make("earth", "836142", "earth", 0.65)
	make("trail", "a47a52", "earth", 0.78)
	make("garden", "67472e", "earth", 0.84)
	make("cobble", "91897a", "cobble", 0.51)
	make("stone", "a49a82", "stone", 0.54)
	make("mossstone", "69735b", "stone", 0.78)
	materials.mossstone.albedo_color = Color("839179")
	make("plaster", "e7c48d", "plaster", 0.5)
	make("ivory", "dfd6b9", "plaster", 0.5)
	make("sage", "a2af82", "plaster", 0.5)
	make("wood", "4a3429", "wood", 0.74)
	make("bark", "453b2b", "wood", 0.96)
	make("board", "895f3e", "wood", 0.83)
	make("oak", "a67e4d", "wood", 0.9)
	make("wine", "804f4a", "wood", 0.73)
	make("teal", "425d55", "wood", 0.73)
	make("roof", "a26546", "tiles", 0.53)
	make("mossroof", "849278", "tiles", 0.53)
	make("goldroof", "b88d55", "tiles", 0.53)
	make("iron", "4e5453")
	make("brass", "b48e50")
	make("dark", "282426")
	make("glass", "ffb666")
	make("fire", "ffbe69")
	materials.glass.emission_enabled = true
	materials.glass.emission = Color("ff9d46")
	materials.glass.emission_energy_multiplier = 0.72
	materials.fire.emission_enabled = true
	materials.fire.emission = Color("ff802d")
	materials.fire.emission_energy_multiplier = 1.3
	make("wellwater", "528f8d")
	for color in ["253d32", "354b33", "415e39", "4f6839", "638044", "77964e", "8da956", "a0af58",
			"b7bc65", "d1aa60", "f1d999", "e3b79c", "b784aa", "e2e4c1", "627b68", "a9987d"]:
		make(color, color)

func make(id: String, hex: String, pattern := "", scale := 1.0) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = 0.93
	if not pattern.is_empty():
		var asset := "res://assets/textures/%s.png" % pattern
		if ResourceLoader.exists(asset):
			mat.albedo_texture = load(asset)
			mat.albedo_color = Color(hex).lerp(Color.WHITE, 0.52)
			if id == "mossroof":
				mat.albedo_color = Color("61858b")
			elif id == "goldroof":
				mat.albedo_color = Color("e9d79c")
		else:
			mat.albedo_texture = texture(pattern)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
		mat.uv1_scale = Vector3.ONE * scale
	materials[id] = mat

func texture(pattern: String) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var v := rng.randf_range(0.80, 1.0)
			match pattern:
				"tiles", "stone", "cobble":
					var row_h := 8 if pattern == "tiles" else 11 if pattern == "stone" else 8
					var cell_w := 8 if pattern == "tiles" else 16 if pattern == "stone" else 10
					var row := floori(float(y) / row_h)
					var shift := (row * 9 + row % 2 * 3) % cell_w
					var dx := (x + shift) % cell_w
					var dy := y % row_h
					var cell := floori(float(x + shift) / cell_w)
					var shade := 0.79 + 0.21 * fposmod(sin(cell * 15.51 + row * 17.9) * 272.9, 1.0)
					if pattern == "tiles":
						v *= shade * (0.55 if dy == 0 else 1.16 - 0.043 * dy)
						v *= 0.58 + 0.55 * sin((dx + 0.8) * PI / cell_w)
					else:
						v *= shade * (0.46 if dy == 0 or dx == 0 else 1.16 if dy == 1 or dx == 1 else 0.98)
				"wood":
					v *= 0.55 if y % 16 == 0 else 0.89 + 0.12 * sin(float(y) * 1.8 + sin(x * 0.12))
				"grass", "earth":
					v *= 0.91 + 0.10 * sin(x * 0.44 + y * 0.61) * cos(y * 0.29)
				_:
					v = 0.94 + (v - 0.9) * 0.42
			img.set_pixel(x, y, Color(v, v, v))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
