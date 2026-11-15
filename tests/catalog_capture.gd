extends SceneTree

## Capturas do Catalogo Temporal (lista e detalhe) em desktop e celular.
## Uso (com tela): godot --path . --script res://tests/catalog_capture.gd -- [prefixo]
## Saida: res://.codex/catalog/<prefixo>_<n>_<rotulo>.png

var game: Node
var shots := 0
var prefix := "atual"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("-"):
			prefix = a
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _shot(label: String, size: Vector2i) -> void:
	root.size = size
	root.content_scale_size = size
	for i in range(3):
		game.queue_redraw()
		await process_frame
	var dir := ProjectSettings.globalize_path("res://.codex/catalog")
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_texture().get_image().save_png(dir + "/%s_%02d_%s.png" % [prefix, shots, label])
	shots += 1


func _run() -> void:
	await process_frame
	game._finish_startup_thanks()
	game.mode = "catalog"
	game.catalog_detail_open = false
	for tab in [1, 6, 4]:
		game._catalog_reset_tab(tab)
		await _shot("lista_tab%d" % tab, Vector2i(1280, 720))
	game._catalog_reset_tab(1)
	game.catalog_subfilter = "3"
	await _shot("lista_filtro_catedral", Vector2i(1280, 720))
	game._catalog_reset_tab(6)
	game.catalog_scroll_px = 520.0
	await _shot("lista_rolada", Vector2i(1280, 720))
	game._catalog_reset_tab(2)
	game.catalog_selected = 2
	game.catalog_detail_open = true
	await _shot("detalhe_chefe", Vector2i(1280, 720))
	game._catalog_reset_tab(6)
	for i in range(game._catalog_items().size()):
		if String(game._catalog_items()[i].get("id", "")) == "carta_zero":
			game.catalog_selected = i
	game.catalog_detail_open = true
	await _shot("detalhe_carta", Vector2i(1280, 720))
	game._catalog_reset_tab(4)
	game.catalog_selected = 1
	game.catalog_detail_open = true
	await _shot("detalhe_pessoa", Vector2i(1280, 720))
	game.catalog_detail_open = false
	game._catalog_reset_tab(1)
	await _shot("lista_celular", Vector2i(960, 540))
	game.catalog_selected = 3
	game.catalog_detail_open = true
	await _shot("detalhe_celular", Vector2i(960, 540))
	print("CATALOG_CAPTURE_OK shots=%d" % shots)
	quit(0)
