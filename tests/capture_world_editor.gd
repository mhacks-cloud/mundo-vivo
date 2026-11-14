extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		quit(1)
		return
	var folder := args[0]
	DirAccess.make_dir_recursive_absolute(folder)
	var game := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	root.add_child(game)
	game.career.new_game()
	game.career.confirm_character("Nara do Amieiro", "smith", "amieiro", 1, 1)
	game.career.confirm_plot("sul-01")
	game.player.position = Vector3(0.8, 0.1, 4.5)
	game.target_yaw = 0.2
	game.target_distance = 18
	game.quality = 2
	game._refresh_quality()
	game.world_editor.open()
	game.world_editor._select("founders_well")
	game.world_editor.marker.hide()
	game._camera_frame(0.9)
	await _shot(folder.path_join("Sistema Deus - Editor.png"))
	game.world_editor._change("founders_well", Vector3(2.3, 0, -0.8), 0)
	game._camera_frame(0.9)
	await _shot(folder.path_join("Sistema Deus - Poco movido.png"))
	quit()

func _shot(path: String) -> void:
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	print("CAPTURA ", path, " ", root.get_texture().get_image().save_png(path))
