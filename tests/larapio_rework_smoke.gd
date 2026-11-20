extends SceneTree

## Larapio: bote de roubo com aviso, leque de pedras, recarga por portal, portais
## visiveis e rastro de moedas. Com --frames=<dir> grava a demonstracao (~20 fps).
const DT := 1.0 / 60.0
var game: Node
var frames_dir := ""
var seq := 0
var step := 0
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="): frames_dir = a.substr(9)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("LARAPIO_REWORK " + message)


func _tick(seconds: float, player_dir: Vector2 = Vector2.ZERO) -> void:
	for _i in range(int(round(seconds / DT))):
		game.time_alive += DT
		game.elapsed_unpaused += DT
		if player_dir.length() > 0.0:
			game.player_pos = game._clamp_player_world(game.player_pos + player_dir * 230.0 * DT)
		game.player_stun_timer = maxf(0.0, game.player_stun_timer - DT)
		game.enemy_manager.update_enemies(DT)
		game._update_enemy_bullets(DT)
		game._update_larapio_coin_drops(DT)
		game._update_effects(DT)
		step += 1
		if frames_dir != "" and step % 3 == 0:
			game.queue_redraw()
			await process_frame
			var img := root.get_texture().get_image()
			img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
			img.save_png("%s/f_%03d.png" % [frames_dir, seq])
			seq += 1


func _larapio() -> Dictionary:
	for e in game.enemies:
		if String(e.get("type", "")) == game.ENEMY_LARAPIO:
			return e
	return {}


func _run() -> void:
	game.startup_thanks_done = true
	game.forced_initial_phase = 1
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_hp_max = 1.0e9
	game.player_hp = 1.0e9
	game.run_retry_invulnerability_timer = 999.0
	game.enemies.clear()
	game.score = 5000
	game.spawn_timer = 999.0
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
	game._spawn_enemy(game.ENEMY_LARAPIO, game.player_pos + Vector2(420.0, -60.0))
	var lar := _larapio()
	_check(not lar.is_empty(), "larapio did not spawn")
	# Ferido e sem saque, ele abandona a fuga e volta a pressionar o jogador.
	lar["hp"] = float(lar["max_hp"]) * game.LARAPIO_DESPERATE_HP_RATIO
	lar["stolen"] = 0
	lar["larapio_escape_timer"] = 1.4
	var pressure_distance_before: float = Vector2(lar["pos"]).distance_to(game.player_pos)
	game._move_enemy(lar, 0.2)
	var pressure_distance_after: float = Vector2(lar["pos"]).distance_to(game.player_pos)
	_check(game._larapio_desperate(lar), "low-health Larápio without loot did not become threatening")
	_check(pressure_distance_after < pressure_distance_before, "desperate Larápio kept escaping instead of closing distance")
	var desperate_interval: float = float(game._larapio_throw_interval(lar, pressure_distance_after, false, false, true))
	_check(desperate_interval < game.LARAPIO_AGGRESSIVE_THROW_INTERVAL and desperate_interval >= game.LARAPIO_DESPERATE_MIN_THROW_INTERVAL, "desperate attack-speed increase left its intended range")
	lar["stolen"] = 1
	_check(not game._larapio_desperate(lar), "Larápio carrying loot incorrectly entered the no-loss pressure state")
	_check(RTSupremeEnemyRewards.points_for("larapio_clean", 100) > RTSupremeEnemyRewards.points_for("larapio", 100), "Larápio clean kill should pay more points")
	lar["stolen"] = 0
	lar["hp"] = lar["max_hp"]
	lar["larapio_escape_timer"] = 0.0
	lar["spawned_at"] = game.time_alive - game.LARAPIO_AGGRESSIVE_AFTER - 1.0
	lar["larapio_lunge_cd"] = 0.0
	lar["steal_cd"] = 0.0
	# 1) Ele se aproxima e da o bote (aviso -> disparo).
	var saw_windup := false
	var saw_lunge := false
	var stole := false
	for _k in range(240):
		await _tick(DT)
		var st: String = game.larapio_lunge_state(lar)
		saw_windup = saw_windup or st == "windup"
		saw_lunge = saw_lunge or st == "lunge"
		if int(lar.get("stolen", 0)) > 0:
			stole = true
			break
	_check(saw_windup and saw_lunge, "lunge never telegraphed/fired (windup=%s lunge=%s)" % [saw_windup, saw_lunge])
	_check(stole, "larapio did not steal")
	# 2) Foge com o saque deixando rastro; o jogador corre atras.
	await _tick(2.4, Vector2.RIGHT)
	var trail: Array = RTLarapioPresentation.trails.get(int(lar.get("uid", -1)), [])
	_check(trail.size() >= 4, "coin trail too short (%d)" % trail.size())
	# 3) Leque de pedras quando agressivo e sem saque.
	lar["stolen"] = 0
	game.enemy_bullets.clear()
	lar["throw_cd"] = 0.0
	lar["alerted"] = true
	game._throw_larapio_projectile(lar)
	_check(game.enemy_bullets.size() == 3, "aggressive throw is not a 3-stone fan (%d)" % game.enemy_bullets.size())
	# 4) Ultimate: portais com recarga individual.
	lar["hp"] = float(lar["max_hp"]) * 0.5
	lar["larapio_ult_cd"] = 0.0
	game._start_larapio_ultimate(lar)
	var portals: Array = lar.get("larapio_ult_portals", [])
	_check(portals.size() == game.LARAPIO_ULTIMATE_PORTAL_COUNT, "portal count")
	game._larapio_jump_between_ultimate_portals(lar, game.player_pos)
	var cooling := 0
	for portal in portals:
		if float(Dictionary(portal).get("cd", 0.0)) > 0.0:
			cooling += 1
	_check(cooling == 2, "a jump must put entry and exit on cooldown (%d)" % cooling)
	game._larapio_jump_between_ultimate_portals(lar, game.player_pos)
	var before: Vector2 = lar["pos"]
	game._larapio_jump_between_ultimate_portals(lar, game.player_pos)
	_check(Vector2(lar["pos"]) == before, "jumped with every portal on cooldown")
	game.player_pos = Vector2(portals[0]["pos"]) + Vector2(-160, 40)
	await _tick(3.0)
	print("LARAPIO_REWORK_%s pressure=true rewards=2/3 lunge=%s steal=%s trail=%d fan=3 portal_cd=true frames=%d" % ["FAIL" if failed else "OK", saw_lunge, stole, trail.size(), seq])
	quit(1 if failed else 0)
