extends SceneTree

## Capturas do lote 2026-11-24: opcao TEXTO DAS CONVERSAS, conversa com o
## Mercador em fonte normal e maior, e a Profecia (olho fechado, abrindo,
## contagem, volta no tempo e replay com o "eu do passado").
## Uso (fora do headless, para renderizar):
##   godot4 --path . --windowed --resolution 1280x720 --script tests/gameplay_batch_nov24_capture.gd -- --capture-size=1280x720
##   godot4 --path . --windowed --resolution 800x360 --script tests/gameplay_batch_nov24_capture.gd -- --capture-size=800x360 --mobile
## Saida: res://.codex/nov24/*.png. Restaura os arquivos de usuario no fim.

const OUT := "res://.codex/nov24"
const UserFileGuard = preload("res://tests/support/user_file_guard.gd")
const DT := 1.0 / 30.0

var game: Node
var guards: Array = []


func _initialize() -> void:
	for path in ["user://hud_config.save", "user://interrupted_run.save", "user://merchant_npc.cfg", "user://story_progress.cfg", "user://quantum_chips.cfg"]:
		guards.append(UserFileGuard.new(path))
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func capture(label: String) -> void:
	for i in range(2):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/%s_%dx%d.png" % [OUT, label, root.size.x, root.size.y]
	var err: int = root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("CAPTURE ", path, " err=", err)


func _frames(seconds: float) -> void:
	for _i in range(int(round(seconds / DT))):
		game._process(DT)


func _fresh_run() -> void:
	game.forced_initial_phase = 1
	game.run_tutorial_enabled = false
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var size: Vector2i = DisplayServer.window_get_size()
	var mobile: bool = "--mobile" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--capture-size="):
			var parts: PackedStringArray = String(arg).trim_prefix("--capture-size=").split("x")
			size = Vector2i(int(parts[0]), int(parts[1]))
	root.size = size
	root.content_scale_size = size
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(size)
	await process_frame
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.ui_platform_override = game.UI_PLATFORM_ANDROID if mobile else game.UI_PLATFORM_DESKTOP
	# 1) Opcao nas configuracoes.
	game.dialogue_text_scale = 1.75
	game.mode = "settings_gameplay"
	game.settings_selected = game._gameplay_preference_index("dialogue_text")
	await capture("opcao_texto_conversas")
	# 2) Conversa com o Mercador: 100% e 175%.
	_fresh_run()
	var dim: RTMerchantDimension = game._merchant_dimension()
	dim.enter()
	_frames(3.0)
	var talk: RTDialogueController = game._dialogue()
	talk.start([{"who": "mercador", "text": "Pergunta. Velho adora pergunta: e a unica hora que alguem escuta a gente inteiro. Fala, menina, o que te traz na minha oficina?", "mood": "animado"}])
	talk.revealed = 99999.0
	talk.grace = 0.0
	game.dialogue_text_scale = 1.0
	await capture("conversa_fonte_100")
	game.dialogue_text_scale = 1.75
	await capture("conversa_fonte_175")
	talk.clear()
	game._merchant_npc().seen["intro"] = true
	game._merchant_npc().open_menu(dim)
	talk.revealed = 99999.0
	talk.grace = 0.0
	await capture("menu_balcao_fonte_175")
	talk.clear()
	dim.leave(false)
	game.dialogue_text_scale = 1.0
	# 3) Profecia.
	_fresh_run()
	game.aura_state = AuraSystem.create("Profetica", 1)
	game.enemies.clear()
	for offset in [Vector2(520, -60), Vector2(-480, 90), Vector2(90, 420), Vector2(-260, -330)]:
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + offset)
		game.enemies[-1]["hp"] = 100000.0
	game.spawn_timer = 99999.0
	var rewind: RTPropheticRewind = game.prophetic_rewind
	rewind.cooldown = 0.0
	game._process(DT)
	_frames(0.25)
	await capture("profecia_1_olho_fechado")
	while rewind.eye_open() < 0.5:
		game._process(DT)
	await capture("profecia_2_olho_abrindo")
	while rewind.state == RTPropheticRewind.STATE_OMEN:
		game._process(DT)
	await capture("profecia_3_contagem")
	# Ninguem encosta antes do golpe de teste (so para a captura ficar limpa).
	while rewind.clock < 2.5:
		game.run_retry_invulnerability_timer = 0.2
		game.player_pos += Vector2(0, -90) * DT
		game._process(DT)
	game.run_retry_invulnerability_timer = 0.0
	game._damage_player(40, "captura")
	_frames(RTPropheticRewind.REWIND_TIME * 0.5)
	await capture("profecia_4_tempo_volta")
	_frames(RTPropheticRewind.REWIND_TIME * 0.5 + DT)
	for _i in range(24):
		game.player_pos += Vector2(160, 40) * DT
		game._process(DT)
	await capture("profecia_5_replay_passado_presente")
	for guard in guards:
		guard.restore()
	print("GAMEPLAY_BATCH_NOV24_CAPTURE_DONE")
	quit(0)
