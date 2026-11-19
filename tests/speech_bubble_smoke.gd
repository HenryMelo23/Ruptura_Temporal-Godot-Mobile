extends SceneTree

## Baloes de fala genericos + monologo da primeira partida da Geovana.
## Garante que as falas antigas da Geovana (cooldown, abate, dano, chefe, loja,
## vida baixa, ambiente) nao voltam e que o sistema serve para inimigos.

var game: Node
var failed := false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("SPEECH_BUBBLE_FAIL " + message)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		return
	var dir_path := ProjectSettings.globalize_path("res://.codex")
	DirAccess.make_dir_recursive_absolute(dir_path)
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://.codex/speech_bubble_%s_%dx%d.png" % [label, root.size.x, root.size.y]))


func _run() -> void:
	await process_frame
	game.run_tutorial_enabled = false
	game._start_game()
	game._finish_startup_thanks()
	game.set_process(false)
	game._reset_tutorial_state()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.mode = "game"
	game.time_alive = 120.0
	game.player_pos = Vector2(620.0, 420.0)
	game.player_hp = game.player_hp_max
	game.current_phase = 1
	var bubbles = game.speech_bubbles
	bubbles.clear()

	# 1) As falas automaticas antigas sumiram: nada dispara balao sozinho.
	_check(not game.has_method("_geovana_bark"), "_geovana_bark facade still exists")
	game.player_hp = int(float(game.player_hp_max) * 0.2)
	for i in range(240):
		game.time_alive += 1.0
		bubbles.update(game, 1.0)
		game.geovana_first_run_monologue.update(game, 1.0)
	_check(bubbles.bubbles.is_empty(), "a bubble appeared outside the first-run tutorial")
	game.player_hp = game.player_hp_max

	# 2) Sistema generico: jogador e inimigo falam ao mesmo tempo.
	_check(bubbles.say(game, "player", "Teste do jogador.", {"priority": 1}), "player bubble rejected")
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(260.0, 0.0))
	var uid: int = int(game.enemies[-1]["uid"])
	var speaker: String = RTSpeechBubbles.enemy_speaker(uid)
	_check(bubbles.say(game, speaker, "Grr... voce de novo.", {"priority": 0}), "enemy bubble rejected")
	_check(bubbles.is_speaking("player") and bubbles.is_speaking(speaker), "bubbles are not independent per speaker")
	_check(not bubbles.say(game, "player", "Menor prioridade.", {"priority": 0}), "lower priority replaced the active bubble")
	var short_duration: float = bubbles.reading_duration_for("Toma essa.")
	var long_duration: float = bubbles.reading_duration_for("Acham que vao me parar, mas eu preciso chegar la, por voce, meu amor.")
	_check(long_duration > short_duration + 2.0, "reading duration is not scaling with words")
	bubbles.update(game, 0.3) # passa o fade-in
	await _capture("generic")
	# Inimigo morto leva o balao junto.
	game.enemies[-1]["hp"] = 0.0
	bubbles.update(game, 0.01)
	_check(not bubbles.is_speaking(speaker), "dead enemy kept its bubble")
	bubbles.clear()
	game.enemies.clear()

	# 3) Monologo da primeira partida: so com tutorial pratico ou missao.
	var mono = game.geovana_first_run_monologue
	mono.reset_run()
	game.tutorial_state = game.TUTORIAL_STATE_ATTACK
	_check(mono.eligible(game), "Geovana tutorial step is not eligible for the monologue")
	mono.update(game, 0.016)
	_check(bubbles.is_speaking("player"), "attack step did not start Geovana's monologue")
	var first_line: String = bubbles.text_of("player")
	_check(first_line.contains("mão"), "unexpected first tutorial line: " + first_line)
	bubbles.update(game, 0.3)
	await _capture("tutorial")
	for i in range(30):
		bubbles.update(game, 0.5)
		mono.update(game, 0.5)
	_check(mono.said.has("step:attack"), "attack step lines were not tracked")
	game.is_multiplayer = true
	_check(not mono.eligible(game), "multiplayer accepted the monologue")
	game.is_multiplayer = false
	game._reset_tutorial_state()
	_check(not mono.eligible(game), "monologue still eligible after the tutorial ended")

	print("SPEECH_BUBBLE_SMOKE_%s" % ("FAIL" if failed else "OK"))
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	quit(1 if failed else 0)
