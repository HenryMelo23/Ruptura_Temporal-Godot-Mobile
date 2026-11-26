extends SceneTree

## Capturas do lote 2026-11-19: Teclado e mouse (automatico e cursor),
## Jogabilidade desktop/Android e modo de cor (sobre a tela de atalhos).
## Uso (fora do headless, para renderizar):
##   godot4 --path . --windowed --resolution 1280x720 --script tests/gameplay_batch_nov19_capture.gd -- --capture-size=1280x720
## Saida: res://.codex/nov19/*.png. Nao grava configuracao em disco.

const OUT := "res://.codex/nov19"

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func capture(label: String) -> void:
	for i in range(3):
		game.queue_redraw()
		await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var path := "%s/%s_%dx%d.png" % [OUT, label, root.size.x, root.size.y]
	var err: int = root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("CAPTURE ", path, " err=", err)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var size: Vector2i = DisplayServer.window_get_size()
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--capture-size="):
			var parts: PackedStringArray = String(arg).trim_prefix("--capture-size=").split("x")
			size = Vector2i(int(parts[0]), int(parts[1]))
	root.size = size
	root.content_scale_size = size
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(size)
	await process_frame
	game.color_vision_mode = "off"
	game.ColorVisionFilterScript.apply(game)
	game.mode = "menu"
	await process_frame
	# Configuracoes desktop.
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.desktop_attack_aim_mode = game.DESKTOP_ATTACK_AIM_AUTO
	game._reset_keyboard_bindings()
	game.settings_selected = 0
	game.mode = "settings_keys"
	await capture("keys_auto")
	game._cycle_desktop_attack_aim_mode()
	await capture("keys_cursor")
	game._cycle_desktop_attack_aim_mode()
	game.mode = "settings_gameplay"
	await capture("gameplay_desktop")
	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	await capture("gameplay_android")
	# Modos de cor sobre a tela de atalhos (cores de destaque por acao). A
	# partida tambem passa pelo filtro: ele e um CanvasLayer acima de tudo.
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.mode = "settings_keys"
	for mode: String in game.ColorVisionFilterScript.MODES:
		game.color_vision_mode = mode
		game.ColorVisionFilterScript.apply(game)
		await capture("color_" + mode)
	game.color_vision_mode = "off"
	game.ColorVisionFilterScript.apply(game)
	print("GAMEPLAY_BATCH_NOV19_CAPTURE_DONE")
	quit(0)
