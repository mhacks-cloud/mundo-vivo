class_name ValeAudio
extends Node3D

const RATE := 16000
var random := RandomNumberGenerator.new()
var wind := AudioStreamPlayer.new()
var water := AudioStreamPlayer3D.new()
var village := AudioStreamPlayer3D.new()
var birds := AudioStreamPlayer3D.new()
var steps := AudioStreamPlayer3D.new()
var animal := AudioStreamPlayer3D.new()
var animal_streams: Dictionary = {}
var hammers: Array[AudioStreamPlayer3D] = []
var bird_timer := 3.0
var step_distance := 0.0
var hammer_timer := [0.0, 0.0, 0.0]

func _ready() -> void:
	random.seed = 40571
	wind.stream = _synthesize("wind", 5.6, true)
	wind.volume_db = -25
	add_child(wind)
	_place(water, _synthesize("river", 4.4, true), Vector3(13, 0.2, 2), -16, 26)
	_place(village, _synthesize("hearth", 3.4, true), Vector3(-8, 0.3, -4), -27, 15)
	_place(birds, _synthesize("birds", 1.6), Vector3(-7, 4, -8), -19, 27)
	_place(steps, _synthesize("step", 0.19), Vector3.ZERO, -14, 18)
	for species in ["galinha", "vaca", "ovelha", "pássaro", "gato", "cão"]:
		animal_streams[species] = _synthesize(species, 0.64)
	_place(animal, animal_streams["galinha"], Vector3.ZERO, -17, 18)
	var hit := _synthesize("hammer", 0.29)
	for i in 3:
		var sound := AudioStreamPlayer3D.new()
		_place(sound, hit, Vector3.ZERO, -14, 23)
		hammers.append(sound)
	if DisplayServer.get_name() != "headless":
		wind.play()
		water.play()
		village.play()

func listen(player: PixelActor, people: Array[PixelActor], hour: float, wet: bool, delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	water.position.z = player.position.z
	wind.volume_db = lerpf(wind.volume_db, -18.0 if wet else -28.0, 0.9 * delta)
	village.volume_db = -23.0 if hour >= 17.5 or hour < 5.0 else -28.0
	bird_timer -= delta
	if bird_timer <= 0.0 and hour > 6.0 and hour < 18.5 and not wet:
		birds.position = player.position + Vector3(random.randf_range(-8, 7), 4, random.randf_range(-10, -3))
		birds.pitch_scale = random.randf_range(0.84, 1.12)
		birds.play()
		bird_timer = random.randf_range(5.5, 13.0)
	step_distance += player.get_real_velocity().length() * delta
	if step_distance >= 0.78:
		step_distance = fposmod(step_distance, 0.78)
		steps.position = player.position
		steps.pitch_scale = random.randf_range(0.89, 1.13)
		steps.play()
	for i in hammers.size():
		var actor := people[i if i < 2 else 3]
		hammer_timer[i] = maxf(0.0, hammer_timer[i] - delta)
		if actor.visual.animation == &"work" and actor.visual.frame == 2 and hammer_timer[i] == 0.0:
			hammers[i].position = actor.position
			hammers[i].pitch_scale = random.randf_range(0.86, 1.11)
			hammers[i].play()
			hammer_timer[i] = 0.38

func animal_cue(kind: String, p: Vector3) -> void:
	if DisplayServer.get_name() == "headless" or not animal_streams.has(kind):
		return
	animal.stream = animal_streams[kind]
	animal.position = p
	animal.pitch_scale = random.randf_range(0.87, 1.11)
	animal.play()

func _place(source: AudioStreamPlayer3D, stream: AudioStreamWAV, p: Vector3, volume: float, reach: float) -> void:
	source.stream = stream
	source.position = p
	source.volume_db = volume
	source.unit_size = 4.5
	source.max_distance = reach
	add_child(source)

func _synthesize(kind: String, duration: float, loop := false) -> AudioStreamWAV:
	var frames := roundi(duration * RATE)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var slow := 0.0
	var fast := 0.0
	var crackle := 0.0
	for i in frames:
		var t := float(i) / RATE
		var noise := random.randf_range(-1.0, 1.0)
		slow = lerpf(slow, noise, 0.018)
		fast = lerpf(fast, noise, 0.16)
		var value := 0.0
		match kind:
			"wind":
				value = (slow * 2.4 + fast * 0.14) * (0.55 + 0.42 * sin(TAU * t / duration))
			"river":
				value = fast * (0.64 + 0.21 * sin(t * 8.0)) + slow * 1.12 + noise * 0.055
			"hearth":
				crackle *= 0.93
				if absf(noise) > 0.999:
					crackle = random.randf_range(0.24, 0.83)
				value = slow * 1.15 + crackle * noise
			"birds":
				var pulse := fposmod(t, 0.44)
				var chirp := sin(TAU * (2090.0 * pulse + 1660.0 * pulse * pulse))
				value = chirp * sin(clampf(pulse / 0.16, 0.0, 1.0) * PI) * 0.56
			"step":
				value = (fast * 0.74 + noise * 0.13 + sin(t * TAU * 94.0) * 0.19) * exp(-t * 22.0)
			"hammer":
				value = (0.45 * sin(TAU * 670.0 * t) + 0.18 * sin(TAU * 1163.0 * t)
					+ noise * exp(-t * 91.0) * 0.56) * exp(-t * 19.0)
			"galinha":
				var beat := fposmod(t, 0.18)
				value = (sin(TAU * (770.0 * beat - 1400.0 * beat * beat)) * 0.50 + fast * 0.19) * exp(-beat * 27.0)
			"vaca", "ovelha", "gato":
				var root := 112.0 if kind == "vaca" else 245.0 if kind == "ovelha" else 404.0
				var phase := TAU * (root * t + 46.0 * t * t) + 1.4 * sin(t * 10.0)
				value = (sin(phase) * 0.38 + sin(phase * 2.0) * 0.18 + fast * 0.06) * sin(PI * t / duration)
			"cão":
				var bark := fposmod(t, 0.29)
				value = (sin(TAU * (188.0 * bark - 115.0 * bark * bark)) * 0.46 + fast * 0.42) * exp(-bark * 22.0)
			"pássaro":
				var beat := fposmod(t, 0.23)
				value = sin(TAU * (1600.0 * beat + 2400.0 * beat * beat)) * sin(PI * clampf(beat / 0.12, 0, 1)) * 0.44
		var envelope := minf(1.0, minf(t * 150.0, (duration - t) * 105.0))
		bytes.encode_s16(i * 2, roundi(clampf(value * envelope, -1, 1) * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = frames
	return stream
