extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := WorldEditStore.PATH
	for suffix in ["", ".previous", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	var game := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	root.add_child(game)
	game.career.new_game()
	game.career.confirm_character("Ana", "farmer", "amieiro", 0, 0)
	game.career.confirm_plot("sul-01")
	var editor: WorldEditor = game.world_editor
	check(editor.allowed(), "modo de desenvolvimento disponível")
	editor.open()
	check(editor.active and game.diorama.editable_objects.has("founders_well"), "editor abre com poço selecionável")
	check(editor.validate_world().is_empty(), "cenário original passa na validação")
	var well: Node3D = game.diorama.editable_objects.founders_well.root
	var old := well.position
	check(editor._change("founders_well", old + Vector3(0.5, 0, 0), 0), "poço se move após validar")
	check(editor._change("tree_1", Vector3(5.4, 0, -1.4), 0), "árvore se move após validar")
	check(editor._change("barrel_0", Vector3(-2.5, 0, -5), 0), "barril se move após validar")
	check(not editor._change("founders_well", Vector3(12.5, 0, -1), 0), "rio bloqueia posição inválida")
	editor.undo()
	editor.redo()
	check(editor.working.entries.has("barrel_0"), "desfazer e refazer restauram edição")
	editor._paint_at(Vector3(-1, 0, 6))
	check(editor.working.terrain.get("t_-1_6") == "grass", "pintura registra terreno em coordenada negativa")
	editor.save()
	check(WorldEditStore.read().entries.size() == 3, "três alterações persistidas separadas do save")
	check(WorldEditStore.read().terrain.get("t_-1_6") == "grass", "pintura persiste após salvar")
	editor._select("barrel_0")
	editor.view_center = Vector3(-2.5, 0.6, -3.5)
	editor._add_object(true)
	check(editor.working.entries.size() == 4, "duplicação adiciona um objeto com ID próprio")
	editor._remove_selected()
	check(editor.working.entries.size() == 4, "remoção preserva registro para desfazer")
	editor.cancel()
	check(WorldEditStore.read().entries.size() == 3, "cancelar descarta adição e remoção não salvas")
	game.queue_free()
	await process_frame
	var reopened := (load("res://scenes/vale.tscn") as PackedScene).instantiate()
	root.add_child(reopened)
	check(reopened.diorama.editable_objects.founders_well.root.position.distance_to(old + Vector3(0.5, 0, 0)) < 0.01,
		"poço reaparece na nova posição")
	check(reopened.diorama.editable_objects.tree_1.root.position.z > -2.0 and reopened.diorama.editable_objects.barrel_0.root.position.x > -3.0,
		"árvore e barril reaparecem em novas posições")
	check(reopened.diorama.editable_objects.size() == 17, "IDs estáveis sem duplicação ao reabrir")
	reopened.navigation.rebuild(reopened.diorama, false)
	var path_npc: PackedVector3Array = reopened.navigation.find(Vector3(-7, 0.1, 2), Vector3(7, 0.1, 3))
	check(not path_npc.is_empty(), "navegação dos moradores permanece aberta")
	reopened.career.new_game()
	reopened.career.confirm_character("Ana", "farmer", "amieiro", 0, 0)
	reopened.career.confirm_plot("sul-01")
	var positions: Array[Vector3] = []
	for npc in reopened.people:
		positions.append(npc.position)
	for step in 120:
		await physics_frame
	var moved := false
	for i in reopened.people.size():
		moved = moved or reopened.people[i].position.distance_to(positions[i]) > 0.2
	check(moved, "NPCs continuam caminhando após carregar o cenário editado")
	var original := WorldEditStore.empty()
	var write_result := WorldEditStore.write(original)
	check(write_result == OK and WorldEditStore.restore_previous(), "backup permite restaurar a versão anterior")
	check(WorldEditStore.read().entries.size() == 3, "versão anterior do cenário restaurada")
	for suffix in ["", ".previous", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	print("%d verificações do Sistema Deus, %d falhas." % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("OK " if ok else "FALHA ") + label)
