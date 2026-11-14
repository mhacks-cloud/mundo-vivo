extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var started := Time.get_ticks_usec()
	var game := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	root.add_child(game)
	var load_ms := (Time.get_ticks_usec() - started) / 1000.0
	game.career.new_game()
	game.career.confirm_character("Medidora", "farmer", "amieiro", 0, 0)
	game.career.confirm_plot("sul-01")
	await physics_frame
	var begin := Time.get_ticks_usec()
	for i in 300:
		await physics_frame
	var elapsed_ms := (Time.get_ticks_usec() - begin) / 1000.0
	print("BENCHMARK headless | carga_ms=%.2f | 300_frames_ms=%.2f | media_ms=%.3f | objetos_editaveis=%d | nos=%d" %
		[load_ms, elapsed_ms, elapsed_ms / 300.0, game.diorama.editable_objects.size(), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	quit()
