class_name PixelActor
extends CharacterBody3D

var visual := AnimatedSprite3D.new()
var parcel := MeshInstance3D.new()
var contact := MeshInstance3D.new()
var views: Array[SpriteFrames] = []
var view_index := 0
var facing := Vector3.BACK
var turn_timer := 0.0

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
	for i in 3:
		views.append(_frames(primary, hair, hat, i))
	visual.sprite_frames = views[0]
	visual.position.y = 0.725
	visual.pixel_size = 0.044
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
	contact.position.y = -0.099
	var shadow := StandardMaterial3D.new()
	shadow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow.albedo_color = Color(0.095, 0.11, 0.08, 0.24)
	contact.material_override = shadow
	contact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(contact)
	if is_player:
		visual.render_priority = 1

func face(toward: Vector3) -> void:
	if toward.length_squared() > 0.01:
		facing = toward.normalized()
		turn_timer = 1.3

func pose(direction: Vector3, camera_right: Vector3, lighting: Color, building := false) -> void:
	turn_timer = maxf(0.0, turn_timer - get_physics_process_delta_time())
	var moving := direction.length_squared() > 0.035
	if moving and turn_timer == 0.0:
		facing = direction.normalized()
	var lateral := facing.dot(camera_right)
	var forward := facing.dot(camera_right.cross(Vector3.UP))
	var selected := 2 if absf(lateral) > 0.66 else 1 if forward < 0.0 else 0
	visual.flip_h = selected == 2 and lateral < 0.0
	var animation := &"work" if building else &"walk" if moving else &"idle"
	if selected != view_index:
		var frame := visual.frame
		var progress := visual.frame_progress
		var matching := visual.animation == animation
		view_index = selected
		visual.sprite_frames = views[view_index]
		visual.play(animation)
		if matching:
			visual.set_frame_and_progress(frame, progress)
	elif visual.animation != animation:
		visual.play(animation)
	visual.modulate = lighting
	parcel.position.x = -0.35 if visual.flip_h else 0.35

func _frames(primary: Color, hair: Color, hat: int, view: int) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation in [&"idle", &"walk", &"work"]:
		frames.add_animation(animation)
		frames.set_animation_speed(animation, 8.3 if animation == &"walk" else 6.0 if animation == &"work" else 2.1)
		for i in (6 if animation == &"walk" else 4):
			frames.add_frame(animation, _draw(primary, hair, hat, i, animation, view))
	return frames

func _draw(coat: Color, hair: Color, hat: int, frame: int, animation: StringName, view: int) -> ImageTexture:
	var img := Image.create(32, 40, false, Image.FORMAT_RGBA8)
	var ink := Color("252631")
	var leather := Color("574035")
	var hide := Color("9d734b")
	var linen := Color("ddd2ac")
	var gold := Color("e3b568")
	var skin := Color("db9e73")
	var skin_light := Color("f4c894")
	var deep := coat.darkened(0.45)
	var gleam := coat.lightened(0.35)
	var cycle := [0, 2, 1, 0, -2, -1]
	var stride: int = cycle[frame] if animation == &"walk" else 0
	var bob := -1 if frame in [1, 4] else 0
	if animation == &"work":
		bob = 2 if frame == 2 else 0
	var side := view == 2
	var back := view == 1
	var a := 10 + stride
	var b := 17 - stride
	var left_y := 30 - maxi(stride, 0)
	var right_y := 30 + mini(stride, 0)
	for leg in [Vector2i(a, left_y), Vector2i(b, right_y)]:
		_paint(img, leg.x, leg.y, 5, 7, ink)
		_paint(img, leg.x + 1, leg.y + 1, 3, 3, leather)
		_paint(img, leg.x + 1, leg.y + 4, 4, 2, hide)
	_paint(img, 8 if not side else 10, 19 + bob, 16 if not side else 12, 13, ink)
	_paint(img, 9 if not side else 11, 20 + bob, 14 if not side else 10, 11, deep)
	_paint(img, 10 if not side else 12, 20 + bob, 12 if not side else 9, 9, coat)
	_paint(img, 11 if not side else 13, 20 + bob, 9 if not side else 6, 2, gleam)
	if hat == 0:
		_paint(img, 9, 20 + bob, 3, 9, deep)
		_paint(img, 10, 22 + bob, 1, 8, gleam)
	elif hat == 1 and not back:
		_paint(img, 13, 23 + bob, 7, 7, leather)
		_paint(img, 14, 24 + bob, 5, 5, hide.darkened(0.2))
	_paint(img, 12, 28 + bob, 9, 2, leather)
	_paint(img, 10, 30 + bob, 12, 1, gleam)
	for arm in [Vector2i(7 + stride, 22 + bob), Vector2i(21 - stride, 22 + bob)]:
		_paint(img, arm.x, arm.y, 4, 7, ink)
		_paint(img, arm.x + 1, arm.y + 1, 2, 4, coat)
		_paint(img, arm.x + 1, arm.y + 5, 2, 1, linen)
		_paint(img, arm.x + 1, arm.y + 6, 2, 1, skin)
	if back:
		_paint(img, 11, 21 + bob, 10, 7, deep)
		_paint(img, 12, 22 + bob, 8, 5, leather)
		_paint(img, 13, 23 + bob, 6, 3, hide)
		_paint(img, 14, 25 + bob, 4, 1, gold)
	else:
		_paint(img, 13, 19 + bob, 5, 2, linen)
		_paint(img, 15, 21 + bob, 2, 6, deep)
		_paint(img, 17, 27 + bob, 3, 2, gold)
		for i in 6:
			_paint(img, 19 - i, 21 + bob + i, 2, 1, hide)
	_paint(img, 10, 8 + bob, 13, 12, ink)
	_paint(img, 12, 6 + bob, 9, 2, ink)
	_paint(img, 11, 9 + bob, 11, 9, hair.darkened(0.28))
	_paint(img, 12, 7 + bob, 9, 4, hair)
	_paint(img, 13, 8 + bob, 6, 1, hair.lightened(0.34))
	_paint(img, 11, 10 + bob, 2, 5, hair)
	_paint(img, 12, 10 + bob, 1, 3, hair.lightened(0.24))
	if not back:
		_paint(img, 13 if not side else 15, 11 + bob, 8 if not side else 7, 7, skin)
		_paint(img, 14 if not side else 16, 11 + bob, 6, 4, skin_light)
		_paint(img, 20, 14 + bob, 3 if side else 1, 2, skin_light)
		_paint(img, 19, 13 + bob, 1, 2, ink)
		if not side and not (animation == &"idle" and frame == 3):
			_paint(img, 15, 13 + bob, 1, 2, ink)
		_paint(img, 18, 17 + bob, 2, 1, Color("ae6758"))
		_paint(img, 14 if not side else 16, 15 + bob, 1, 1, skin)
		_paint(img, 19, 16 + bob, 2, 1, skin_light)
		_paint(img, 14, 18 + bob, 6, 1, skin)
	else:
		_paint(img, 13, 13 + bob, 7, 4, hair)
		_paint(img, 14, 15 + bob, 2, 3, hair.lightened(0.18))
		_paint(img, 14, 18 + bob, 5, 1, skin)
	if hat != 0:
		var brim := gleam if hat == 1 else gold
		var crown := deep if hat == 1 else hide
		_paint(img, 11, 6 + bob, 11, 4, ink)
		_paint(img, 12, 6 + bob, 9, 3, crown)
		_paint(img, 13, 6 + bob, 6, 1, brim)
		_paint(img, 9, 9 + bob, 15, 2, ink)
		_paint(img, 10, 9 + bob, 13, 1, brim)
	if animation == &"work":
		var tool_y := 23 if frame == 2 else 13
		_paint(img, 25, tool_y, 2, 8, hide)
		_paint(img, 23, tool_y, 6, 3, Color("56676a"))
		_paint(img, 23, tool_y, 6, 1, Color("a6b3a3"))
		_paint(img, 24, tool_y + 6, 3, 2, skin_light)
	return ImageTexture.create_from_image(img)

func _paint(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), color)
