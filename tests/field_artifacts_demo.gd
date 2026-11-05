extends SceneTree

## Artefatos de campo (ima, furia, expurgo) no jogo real.
## -- [--frames=<dir>]
const DT := 1.0 / 60.0
var game: Node
var frames_dir := ""
var seq := 0
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="): frames_dir = a.substr(9)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("FIELD_ARTIFACTS_FAIL " + msg)


func _step(seconds: float, capture: bool) -> void:
	var t := 0.0
	var i := 0
	while t < seconds:
		t += DT
		game.time_alive += DT
		game.elapsed_unpaused += DT
		game.player_hp = game.player_hp_max
		game._field_artifacts().update(DT)
		game._update_heal_orbs(DT)
		game._update_effects(DT)
		if game.has_method("_update_arauto_card_drops"):
			game._update_arauto_card_drops(DT)
		i += 1
		if capture and frames_dir != "" and i % 2 == 0:
			game.queue_redraw()
			await process_frame
			var img := root.get_texture().get_image()
			img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
			img.save_png("%s/f_%03d.png" % [frames_dir, seq])
			seq += 1


func _artifact(kind: String, pos: Vector2) -> Dictionary:
	return game._spawn_gameplay_orb(game.POINT_BOOST_PICKUP_KIND, pos, {"collect_radius": 66.0, "artifact": true, "artifact_type": kind}, 0, 16.0)


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
	game.spawn_timer = 999.0
	game.time_alive = 400.0
	game.enemies.clear()
	game.heal_orbs.clear()
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
	var p: Vector2 = game.player_pos
	# --- IMA: pontos e cartas espalhados longe; o ima traz tudo.
	for i in range(14):
		game._spawn_enemy_point_drop(p + Vector2.from_angle(float(i) * 0.45) * (420.0 + float(i) * 40.0), 20)
	var card: Dictionary = Dictionary(game.CARDS[0]).duplicate(true)
	for i in range(3):
		game._append_owned_card_drop(card, p + Vector2(-500.0 + float(i) * 120.0, 260.0), 0.0, game._mp_unique_id(), 12.0, 0.0, 0.0, 0.0, 0.0, {})
	var score_before: int = int(game.score)
	var magnet := _artifact("ima", p + Vector2(40, 0))
	await _step(0.8, true)
	magnet["pos"] = game.player_pos
	await _step(2.2, true)
	var points_left: int = game.heal_orbs.filter(func(o): return String(o.get("kind", "")) == game.ENEMY_POINT_ORB_KIND).size()
	_check(points_left == 0, "ima nao puxou os pontos (%d sobraram)" % points_left)
	_check(int(game.score) > score_before, "ima nao gerou pontos")
	var cards_far: int = 0
	for d in game.arauto_card_drops:
		if Vector2(d.get("pos", p)).distance_to(game.player_pos) > 120.0:
			cards_far += 1
	_check(cards_far == 0, "ima nao puxou as cartas soltas")
	# --- FURIA
	var fury := _artifact("furia", game.player_pos)
	await _step(0.3, true)
	_check(is_equal_approx(game._field_artifacts().damage_multiplier(), 1.5), "furia nao ativou +50%")
	# --- EXPURGO: 14 comuns + 1 larapio na tela
	for i in range(14):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(float(i) * 0.45) * (180.0 + float(i % 4) * 60.0))
	game._spawn_enemy(game.ENEMY_LARAPIO, game.player_pos + Vector2(300, -120))
	await _step(0.6, true)
	var commons_before: int = game.enemies.filter(func(e): return String(e.get("type", "")) == game.ENEMY_COMMON).size()
	var purge := _artifact("expurgo", game.player_pos)
	await _step(1.4, true)
	var commons_after: int = game.enemies.filter(func(e): return String(e.get("type", "")) == game.ENEMY_COMMON).size()
	var larapio_alive: bool = game.enemies.any(func(e): return String(e.get("type", "")) == game.ENEMY_LARAPIO)
	_check(commons_before >= 10 and commons_after == 0, "expurgo nao limpou a tela (%d -> %d)" % [commons_before, commons_after])
	_check(larapio_alive, "expurgo matou o Larapio")
	await _step(1.0, true)
	if not failed:
		print("FIELD_ARTIFACTS_DEMO_OK magnet=true fury=true purge=%d->%d larapio_safe=true frames=%d" % [commons_before, commons_after, seq])
	quit(1 if failed else 0)
