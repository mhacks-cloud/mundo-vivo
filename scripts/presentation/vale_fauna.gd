class_name ValeFauna
extends Node3D

const TYPES := {
	"galinha": {"size": 0.035, "speed": 0.81, "radius": 1.80, "tint": "ddbd8d"},
	"vaca": {"size": 0.075, "speed": 0.52, "radius": 3.45, "tint": "aa7b59"},
	"ovelha": {"size": 0.049, "speed": 0.74, "radius": 2.15, "tint": "d8d5b7"},
	"pássaro": {"size": 0.030, "speed": 2.6, "radius": 3.45, "tint": "6d8d8c"},
	"gato": {"size": 0.035, "speed": 0.91, "radius": 2.15, "tint": "b78455"},
	"cão": {"size": 0.049, "speed": 1.09, "radius": 3.20, "tint": "85624a"}
}
var animals: Array[Dictionary] = []
var sprites: Dictionary = {}
var rng := RandomNumberGenerator.new()
var cue_delay := 3.0
var contacts := 0

func _ready() -> void:
	rng.seed = 75104
	_spawn("galinha", Vector3(-10.0, 0.06, 7.35))
	_spawn("galinha", Vector3(-9.14, 0.06, 8.0))
	_spawn("galinha", Vector3(-10.42, 0.06, 7.75))
	_spawn("vaca", Vector3(-16.18, 0.06, 16.23))
	_spawn("vaca", Vector3(-18.1, 0.06, 17.8))
	_spawn("ovelha", Vector3(-12.9, 0.06, 15.9))
	_spawn("ovelha", Vector3(-11.4, 0.06, 15.6))
	_spawn("ovelha", Vector3(-13.9, 0.06, 15.1))
	_spawn("pássaro", Vector3(2.7, 0.08, 4.64))
	_spawn("pássaro", Vector3(1.92, 0.08, 4.32))
	_spawn("gato", Vector3(-4.39, 0.06, -3.60))
	_spawn("cão", Vector3(4.66, 0.06, 3.36))

func _spawn(kind: String, p: Vector3) -> void:
	var data: Dictionary = TYPES[kind]
	var body := CharacterBody3D.new()
	body.name = kind.capitalize().validate_node_name()
	body.position = p
	body.collision_layer = 0
	body.collision_mask = 1
	body.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var hit := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.38 if kind == "vaca" else 0.22
	hit.position.y = shape.radius + 0.015
	hit.shape = shape
	body.add_child(hit)
	var visual := AnimatedSprite3D.new()
	visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	visual.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	visual.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	visual.position.y = 9.0 * float(data.size)
	visual.pixel_size = data.size
	if not sprites.has(kind):
		sprites[kind] = _frames(kind, Color(data.tint))
	visual.sprite_frames = sprites[kind]
	body.add_child(visual)
	add_child(body, true)
	visual.play("act")
	animals.append({"kind": kind, "home": p, "body": body, "visual": visual, "target": p,
		"pause": rng.randf_range(1.0, 4.0), "step": 0.0, "rest": true})

func update_animals(player: Vector3, right: Vector3, light: Color, delta: float, audio: ValeAudio) -> void:
	cue_delay -= delta
	for animal in animals:
		var body: CharacterBody3D = animal.body
		var visual: AnimatedSprite3D = animal.visual
		var data: Dictionary = TYPES[animal.kind]
		var elapsed: float = animal.step + delta
		animal.step = elapsed
		var near := player.distance_squared_to(body.position) < 25.0 * 25.0
		if elapsed < (0.05 if near else 0.22):
			continue
		animal.step = 0.0
		visual.modulate = light
		if animal.rest:
			animal.pause -= elapsed
			if animal.pause > 0.0:
				continue
			_choose(animal)
		var offset: Vector3 = animal.target - body.position
		if offset.length_squared() > 0.14 * 0.14:
			var motion := offset.limit_length(float(data.speed) * elapsed)
			var collision := body.move_and_collide(motion)
			if collision != null:
				contacts += 1
				_choose(animal)
			if absf(motion.dot(right)) > 0.005:
				visual.flip_h = motion.dot(right) < 0
			if visual.animation != &"walk":
				visual.play("walk")
		else:
			if animal.kind == "pássaro" and body.position.y > 0.26:
				var spot := body.position
				spot.y = animal.home.y
				animal.target = spot
				continue
			animal.rest = true
			animal.pause = rng.randf_range(4.0, 9.0) if animal.kind == "gato" else rng.randf_range(1.3, 5.0)
			visual.play("act")
			if cue_delay <= 0.0 and player.distance_squared_to(body.position) < 14.0 * 14.0:
				audio.animal_cue(animal.kind, body.position)
				cue_delay = rng.randf_range(3.8, 7.2)

func _choose(animal: Dictionary) -> void:
	var data: Dictionary = TYPES[animal.kind]
	var angle := rng.randf() * TAU
	var radius := rng.randf_range(0.45, data.radius)
	animal.target = animal.home + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
	if animal.kind == "pássaro":
		animal.target.y = rng.randf_range(1.25, 2.9)
	animal.rest = false

func _frames(kind: String, color: Color) -> SpriteFrames:
	var result := SpriteFrames.new()
	result.remove_animation("default")
	for animation in [&"walk", &"act"]:
		result.add_animation(animation)
		result.set_animation_speed(animation, 7.0 if animation == &"walk" else 2.7)
		for frame in 4:
			result.add_frame(animation, _draw(kind, color, frame, animation == &"walk"))
	return result

func _draw(kind: String, color: Color, frame: int, moving: bool) -> ImageTexture:
	var img := Image.create(36, 24, false, Image.FORMAT_RGBA8)
	var ink := Color("343133")
	var shade := color.darkened(0.33)
	var glow := color.lightened(0.30)
	var phase := frame % 2
	if kind == "pássaro":
		var wing_y := 8 - (3 if moving and phase == 0 else 0)
		_rect(img, 11, 13, 14, 6, ink)
		_rect(img, 13, 13, 13, 5, color)
		_rect(img, 20, 10, 7, 6, shade)
		_rect(img, 23, 11, 3, 3, glow)
		_rect(img, 27, 13, 3, 1, Color("d2a365"))
		_rect(img, 25, 11, 1, 1, ink)
		_rect(img, 11, wing_y if moving else 13, 9, 4, shade)
		_rect(img, 13, wing_y + 1 if moving else 14, 7, 2, glow)
	elif kind == "galinha":
		var head := 11 if not moving and phase == 1 else 7
		_rect(img, 10, 12, 14, 8, ink)
		_rect(img, 11, 12, 12, 6, color)
		_rect(img, 13, 13, 6, 3, glow)
		_rect(img, 21, head, 6, 8, shade)
		_rect(img, 22, head, 4, 6, color)
		_rect(img, 23, head - 2, 3, 2, Color("c06143"))
		_rect(img, 26, head + 3, 3, 2, Color("e5a15a"))
		_rect(img, 25, head + 1, 1, 1, ink)
		_rect(img, 13 + phase, 19, 2, 3, Color("bb7b43"))
		_rect(img, 18 - phase, 19, 2, 3, Color("bb7b43"))
	else:
		var big := kind in ["vaca", "ovelha"]
		var y := 9 if big else 13
		var length := 20 if big else 16
		var x := 5 if big else 8
		var sit := not moving and kind == "gato"
		if sit:
			y += 3
		var legs := 6 if big else 4
		_rect(img, x, y, length, 8 if big else 6, ink)
		_rect(img, x + 1, y + 1, length - 2, 6 if big else 4, color)
		_rect(img, x + 2, y + 1, length - 5, 2, glow)
		if kind == "vaca":
			_rect(img, x + 3, y + 2, 5, 5, shade)
			_rect(img, x + 11, y + 4, 5, 3, Color("dfc9a1"))
		elif kind == "ovelha":
			for i in 4:
				_rect(img, x + 2 + i * 4, y - i % 2, 4, 3, glow if i % 2 == 0 else color)
		else:
			_rect(img, x - 3, y - 1 - phase, 4, 2, shade)
			_rect(img, x - 3, y - phase, 2, 4, shade)
		if not sit:
			for i in 3:
				_rect(img, x + 2 + i * 6 + (phase if moving and i % 2 == 0 else 0), y + (6 if big else 5), 2, legs, shade)
		var head := y - 3 + (4 if not moving and phase == 1 and big else 0)
		_rect(img, x + length - 1, head, 8, 7, ink)
		_rect(img, x + length, head + 1, 6, 5, shade if kind == "ovelha" else color)
		_rect(img, x + length + 4, head + 2, 1, 1, ink)
		_rect(img, x + length + 5, head + 4, 2, 2, glow)
		_rect(img, x + length, head - 2, 2, 3, shade)
		if kind == "vaca":
			_rect(img, x + length + 4, head - 2, 2, 3, Color("e9d6a9"))
		elif kind == "cão":
			_rect(img, x + length + 1, head + 3, 2, 3, shade)
	return ImageTexture.create_from_image(img)

func _rect(img: Image, x: int, y: int, w: int, h: int, tint: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), tint)
