extends SceneTree

## Capturas da Rede do Petro (maquina de fusao de DNA):
## maquina na oficina, tela de escolha, animacao da fusao e as 3 habilidades
## do Caranguejo Cosmico (Mare, Distorcao do Relogio, Ressaca Temporal).
## Uso: godot4 --path . --windowed --resolution 1280x720 --script tests/boss_dna_capture.gd -- --capture-size=1280x720
## Saida: res://.codex/boss_dna/*.png

var game: Node
const OUT := "res://.codex/boss_dna"


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func capture(label: String) -> void:
	for i in range(2):
		game.queue_redraw()
		await create_timer(0.25).timeout
	game.queue_redraw()
	await process_frame
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
	game.desktop_window_mode = game.DESKTOP_WINDOW_WINDOWED
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(size)
	game.run_tutorial_enabled = false
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.is_multiplayer = false
	var dim: RTMerchantDimension = game._merchant_dimension()
	var dna: RTBossDnaController = dim.dna
	for phase in [1, 1, 2, 4, 7, 10]:
		dna.on_boss_defeated(phase, Vector2.ZERO)
	dna.bursts.clear()
	dna.reminder_pending = false
	game.card_cost = 120
	game.score = 2400
	await _capture_workshop(dim)
	await _capture_screen(dim, dna)
	await _capture_animation(dim, dna)
	await _capture_abilities(dim, dna)
	print("BOSS_DNA_CAPTURE_DONE")
	quit(0)


func _capture_workshop(dim: RTMerchantDimension) -> void:
	game.mode = "game"
	dim.enter()
	dim.talked_this_visit = true
	game._dialogue().clear()
	game.player_pos = RTBossDnaMachine.POS + Vector2(140, 30)
	game.camera_follow_initialized = false
	await capture("1_oficina_maquina")
	game._merchant_npc().seen.erase(RTBossDnaMachine.SEEN_KEY)
	game.player_pos = RTBossDnaMachine.POS + Vector2(0, 50)
	dim.machine.armed = true
	dim.machine.update(2.0)
	var talk: RTDialogueController = game._dialogue()
	for i in range(3):
		talk.grace = 0.0
		talk.revealed = 9999.0
		talk.advance_input()
	talk.revealed = 9999.0
	await capture("2_mercador_explica")
	talk.clear()


func _capture_screen(dim: RTMerchantDimension, dna: RTBossDnaController) -> void:
	dna.owned["mare_cosmica"] = 1
	dim.fusion_screen.open()
	dim.fusion_screen.selected_ability = 1
	await capture("3_tela_fusao_caranguejo")
	dim.fusion_screen.selected_phase_index = RTBossDnaCatalog.PHASES.find(10)
	dim.fusion_screen.selected_ability = 0
	await capture("4_tela_fusao_dona_boleta")
	dim.fusion_screen.selected_phase_index = 0
	dim.fusion_screen.selected_ability = 1


func _capture_animation(dim: RTMerchantDimension, dna: RTBossDnaController) -> void:
	var screen: RTBossDnaFusionScreen = dim.fusion_screen
	screen.confirm()
	screen.fusing_started = screen._now() - RTBossDnaFusionScreen.ANIM_TIME * 0.18
	await capture("5_fusao_entrando")
	screen.fusing_started = screen._now() - RTBossDnaFusionScreen.ANIM_TIME * 0.5
	await capture("6_fusao_helice")
	screen.fusing_started = screen._now() - RTBossDnaFusionScreen.ANIM_TIME * 0.8
	await capture("7_fusao_completa")
	screen.fusing_started -= RTBossDnaFusionScreen.ANIM_TIME
	screen._tick_animation()
	screen.close()
	dim.leave(false)


func _ring(count: int, center: Vector2, radius: float) -> void:
	for i in range(count):
		game._spawn_enemy(game.ENEMY_COMMON, center + Vector2.from_angle(TAU * float(i) / float(count)) * radius)


func _capture_abilities(dim: RTMerchantDimension, dna: RTBossDnaController) -> void:
	game.mode = "game"
	game.current_phase = 1
	# Sem a cena de saida da fenda nem a fenda pedida pelo chefe nas fotos.
	game._rift_transition().reset_run()
	game.shop_rift_controller.clear_active()
	dna.rift_requested = false
	game.effects.clear()
	game.enemies.clear()
	game.player_pos = Vector2(game.WORLD_SIZE) * 0.5
	game.camera_follow_initialized = false
	dna.owned = {"mare_cosmica": 1, "distorcao_relogio": 1, "ressaca_temporal": 1}
	_ring(10, game.player_pos, 260.0)
	_ring(8, game.player_pos, 520.0)
	dna.fire("mare_cosmica")
	dna.update(0.3)
	await capture("8_hab_mare_cosmica")
	dna.slow_all_timer = 0.0
	dna.bursts.clear()
	dna.cooldowns["distorcao_relogio"] = 0.0
	var from: Vector2 = game.player_pos + Vector2(260, 40)
	dna.rewind_history = [{"t": float(game.time_alive) - 10.0, "pos": game.player_pos - Vector2(180, 60), "hp": 700, "enemies": []}]
	game.player_pos = from
	game.player_hp = 60
	game._damage_player(5000, "capture_lethal", true)
	dna.update(0.25)
	await capture("9_hab_distorcao_relogio")
	dna.rewind_fx = {}
	dna.bursts.clear()
	dna.cooldowns["ressaca_temporal"] = 0.0
	game.run_retry_invulnerability_timer = 0.0
	game._damage_player(10, "capture_hit", true)
	for i in range(8):
		dna.update(0.05)
	await capture("10_hab_ressaca_temporal")
