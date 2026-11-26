extends SceneTree
## Coletora: a execucao de um inimigo dispara a animacao da foice (sombras,
## angulo, corte, explosao), que dura 0,8 s e nunca passa de 6 ao mesmo tempo.
## Com "capture" salva as fases em .agent_logs/coletora/ (precisa de janela).
## godot4 --headless --path . --script tests/coletora_scythe_smoke.gd
## godot4 --path . --audio-driver Dummy --resolution 1280x720 --script tests/coletora_scythe_smoke.gd -- capture

const UserFileGuard = preload("res://tests/support/user_file_guard.gd")
const OUT := "res://.agent_logs/coletora/"

var game: Node
var failures: Array[String] = []
var guards: Array = []
var capture := false


func _initialize() -> void:
	capture = "capture" in OS.get_cmdline_user_args()
	for path in ["user://hud_config.save", "user://interrupted_run.save", "user://player_progress_cache.json", "user://player_profile.save"]:
		guards.append(UserFileGuard.new(path))
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)


func _enemy(offset: Vector2) -> Dictionary:
	var e := {"type": game.ENEMY_COMMON, "uid": 7000 + game.enemies.size(), "pos": game.player_pos + offset, "hp": 100.0, "max_hp": 100.0, "speed": game.enemy_speed_base, "stun": 0.0, "phase": 0.0}
	game.enemies.append(e)
	return e


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.enemies.clear()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	var fx = game.coletora_scythe_fx
	# Execucao de verdade pelo dano: limite de 20% e o golpe deixa o alvo em 10%.
	game.execute_threshold = 0.2
	var target := _enemy(Vector2(160, 0))
	game._damage_enemy(target, 90.0, "atk", false, true, game.player_pos, "basic_attack")
	_check(fx.fx.size() == 1, "execucao nao disparou a foice (%d)" % fx.fx.size())
	_check(fx.fx.size() == 0 or Dictionary(fx.fx[0]).get("tex") != null, "foice sem a copia do inimigo")
	fx.update(0.85)
	_check(fx.fx.is_empty(), "animacao deveria acabar em 0,8 s")
	for k in range(9):
		fx.on_execute(_enemy(Vector2(100 + k * 20, 0)))
	_check(fx.fx.size() == 6, "limite de 6 foices simultaneas (%d)" % fx.fx.size())
	fx.reset()
	game.boss_pos = game.player_pos + Vector2(0, -200)
	fx.on_execute_boss()
	_check(fx.fx.size() == 1 and Dictionary(fx.fx[0]).get("tex") == null, "foice do chefe")
	fx.reset()
	game.execute_threshold = 0.0

	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
		game.enemies.clear()
		var times := [0.14, 0.33, 0.47, 0.56, 0.7]
		for k in range(times.size()):
			fx.on_execute(_enemy(Vector2(-440 + k * 220, 40)))
			fx.fx[k]["t"] = times[k]
		game.enemies.clear()
		for f in range(3):
			game.queue_redraw()
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "fases_1280x720.png"))
		fx.reset()

	game.mode = "menu"
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for guard in guards:
		guard.restore()
	if failures.is_empty():
		print("COLETORA_SCYTHE_SMOKE_OK")
		quit(0)
	else:
		for f in failures:
			printerr("COLETORA_SCYTHE_SMOKE_FAIL " + f)
		quit(1)
