class_name PixelActor
extends CharacterBody3D

var visual := AnimatedSprite3D.new()
var parcel := MeshInstance3D.new()
var contact := MeshInstance3D.new()

func configure(primary: Color, hair: Color, hat: int, is_player: bool) -> void:
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := CapsuleShape3D.new()
	shape.radius = 0.29
	shape.height = 1.36
	var hit := CollisionShape3D.new()
	hit.shape = shape
	hit.position.y = 0.75
	add_child(hit)
	visual.sprite_frames = _frames(primary, hair, hat)
	visual.position.y = 0.855
	visual.pixel_size = 0.052
	visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	visual.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	visual.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	visual.shaded = false
	add_child(visual)
	visual.play("idle")
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.31, 0.31, 0.27)
	parcel.mesh = mesh
	parcel.position = Vector3(0.35, 0.75, 0.12)
	var wrap := StandardMaterial3D.new()
	wrap.albedo_color = Color("bb8950")
	parcel.material_override = wrap
	add_child(parcel)
	parcel.hide()

	var disk := CylinderMesh.new()
	disk.top_radius = 0.26
	disk.bottom_radius = 0.26
	disk.height = 0.013
	disk.radial_segments = 16
	contact.mesh = disk
	contact.position.y = -0.043
	var shadow := StandardMaterial3D.new()
	shadow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow.albedo_color = Color(0.10, 0.12, 0.08, 0.33)
	contact.material_override = shadow
	contact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(contact)
	if is_player:
		visual.render_priority = 1

func pose(direction: Vector3, camera_right: Vector3, lighting: Color, building := false) -> void:
	var lateral := direction.dot(camera_right)
	if absf(lateral) > 0.15:
		visual.flip_h = lateral < 0.0
	var animation := &"walk" if direction.length_squared() > 0.035 else &"idle"
	if building:
		animation = &"work"
	if visual.animation != animation:
		visual.play(animation)
	visual.modulate = lighting
	parcel.position.x = -0.35 if visual.flip_h else 0.35

func _frames(primary: Color, hair: Color, hat: int) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation in [&"idle", &"walk", &"work"]:
		frames.add_animation(animation)
		frames.set_animation_speed(animation, 7.7 if animation == &"walk" else 5.2 if animation == &"work" else 2.1)
		for i in (6 if animation == &"walk" else 3):
			frames.add_frame(animation, _draw(primary, hair, hat, i, animation))
	return frames

func _draw(primary: Color, hair: Color, hat: int, frame: int, animation: StringName) -> ImageTexture:
	var img := Image.create(24, 32, false, Image.FORMAT_RGBA8)
	var ink := Color("30272b")
	var skin := Color("dcaa78")
	var sun_skin := Color("ffdb9c")
	var leather := Color("664534")
	var gold := Color("debb69")
	var shirt_light := primary.lightened(0.29)
	var shirt_dark := primary.darkened(0.37)
	var phase := [0, 1, 1, 0, -1, -1]
	var stride: int = phase[frame] if animation == &"walk" else 0
	var bob := 1 if animation == &"work" and frame == 2 else -1 if frame == 1 or frame == 4 else 0
	_paint(img, 7 + stride, 24, 4, 6 - maxi(stride, 0), ink)
	_paint(img, 13 - stride, 24, 4, 6 + mini(stride, 0), ink)
	_paint(img, 8 + stride, 25, 2, 3 - maxi(stride, 0), leather)
	_paint(img, 14 - stride, 25, 2, 3 + mini(stride, 0), leather)
	_paint(img, 7 + stride, 28 - maxi(stride, 0), 4, 1, Color("997455"))
	_paint(img, 13 - stride, 28 + mini(stride, 0), 4, 1, Color("997455"))
	_paint(img, 6, 14 + bob, 12, 11, ink)
	_paint(img, 5 + stride, 17 + bob, 4, 7, ink)
	_paint(img, 16 - stride, 17 + bob, 4, 7, ink)
	_paint(img, 7, 15 + bob, 10, 8, primary)
	_paint(img, 8, 15 + bob, 8, 2, shirt_light)
	_paint(img, 7, 17 + bob, 2, 5, shirt_dark)
	_paint(img, 15, 17 + bob, 2, 5, shirt_dark)
	_paint(img, 6 + stride, 18 + bob, 2, 3, primary)
	_paint(img, 17 - stride, 18 + bob, 2, 3, primary)
	_paint(img, 6 + stride, 21 + bob, 2, 2, skin)
	_paint(img, 17 - stride, 21 + bob, 2, 2, sun_skin)
	_paint(img, 7, 22 + bob, 10, 2, leather)
	_paint(img, 12, 22 + bob, 2, 2, gold)
	_paint(img, 10, 16 + bob, 4, 3, shirt_dark)
	_paint(img, 11, 16 + bob, 2, 2, Color("eee0b8"))
	_paint(img, 15, 17 + bob, 1, 5, leather)
	_paint(img, 13, 19 + bob, 2, 1, leather)
	_paint(img, 7, 5 + bob, 11, 10, ink)
	_paint(img, 9, 4 + bob, 7, 2, ink)
	_paint(img, 8, 6 + bob, 9, 7, hair.darkened(0.22))
	_paint(img, 9, 5 + bob, 7, 3, hair)
	_paint(img, 10, 5 + bob, 4, 1, hair.lightened(0.33))
	_paint(img, 10, 8 + bob, 7, 6, skin)
	_paint(img, 11, 8 + bob, 5, 4, sun_skin)
	_paint(img, 9, 10 + bob, 1, 3, hair)
	_paint(img, 10, 9 + bob, 2, 1, hair)
	_paint(img, 12, 10 + bob, 1, 2, ink)
	_paint(img, 16, 10 + bob, 1, 2, ink)
	_paint(img, 14, 13 + bob, 2, 1, Color("a86453"))
	_paint(img, 10, 14 + bob, 6, 1, ink)
	if hat == 1:
		_paint(img, 7, 4 + bob, 11, 3, ink)
		_paint(img, 9, 3 + bob, 8, 4, shirt_dark)
		_paint(img, 10, 3 + bob, 6, 1, shirt_light)
		_paint(img, 6, 7 + bob, 13, 1, primary)
	elif hat == 2:
		_paint(img, 7, 5 + bob, 12, 3, leather)
		_paint(img, 9, 4 + bob, 8, 3, gold)
		_paint(img, 5, 7 + bob, 15, 2, gold)
		_paint(img, 6, 8 + bob, 13, 1, leather)
	else:
		_paint(img, 8, 7 + bob, 2, 2, hair.lightened(0.15))
		_paint(img, 8, 12 + bob, 2, 3, hair)
	if animation == &"work":
		var strike := frame == 2
		_paint(img, 18, 16 if strike else 10, 2, 7, leather)
		_paint(img, 17, 15 if strike else 9, 5, 2, Color("8a9b9a"))
		_paint(img, 18, 19 if strike else 16, 2, 3, sun_skin)
	return ImageTexture.create_from_image(img)

func _paint(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), color)
