extends SceneTree

## UMBRA: visual da transmutacao (carga -> estalo -> frente da dimensao nova)
## e hitboxes contra a Geovana alinhadas com a arte (plasma, contato, chao).
## Com "capture" (e janela), salva quadros em .codex/umbra_transmute/ com as
## hitboxes desenhadas por cima.
var game: Node
var failed := false
var capture := false
var shot_n := 0


class Overlay extends Node2D:
	var game: Node
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		if game == null or not game.boss_active:
			return
		var cam: Vector2 = game._camera(get_viewport_rect().size)
		var p: Vector2 = game.player_pos - cam
		var col := Color(0.2, 1.0, 1.0, 0.9)
		draw_line(p + RTUmbraHitbox.BODY_TOP, p + RTUmbraHitbox.BODY_BOTTOM, col, 1.0)
		draw_arc(p + RTUmbraHitbox.BODY_TOP, RTUmbraHitbox.BODY_RADIUS, 0, TAU, 24, col, 1.5)
		draw_arc(p + RTUmbraHitbox.BODY_BOTTOM, RTUmbraHitbox.BODY_RADIUS, 0, TAU, 24, col, 1.5)
		draw_line(p + RTUmbraHitbox.BODY_TOP + Vector2(-RTUmbraHitbox.BODY_RADIUS, 0), p + RTUmbraHitbox.BODY_BOTTOM + Vector2(-RTUmbraHitbox.BODY_RADIUS, 0), col, 1.5)
		draw_line(p + RTUmbraHitbox.BODY_TOP + Vector2(RTUmbraHitbox.BODY_RADIUS, 0), p + RTUmbraHitbox.BODY_BOTTOM + Vector2(RTUmbraHitbox.BODY_RADIUS, 0), col, 1.5)
		draw_arc(p + RTUmbraHitbox.FEET, RTUmbraHitbox.FEET_RADIUS, 0, TAU, 16, Color(1, 1, 0.2, 0.9), 1.5)
		var b: Vector2 = game.boss_pos - cam
		var uc := Color(1.0, 0.3, 0.8, 0.8)
		draw_arc(b + RTUmbraHitbox.UMBRA_TOP, RTUmbraHitbox.UMBRA_RADIUS, 0, TAU, 32, uc, 1.5)
		draw_arc(b + RTUmbraHitbox.UMBRA_BOTTOM, RTUmbraHitbox.UMBRA_RADIUS, 0, TAU, 32, uc, 1.5)
		for bullet in game.enemy_bullets:
			if String(bullet.get("type", "")) != "umbra_plasma":
				continue
			var h: Vector2 = RTUmbraHitbox.plasma_head(Vector2(bullet["pos"]), Vector2(bullet["dir"])) - cam
			draw_arc(h, RTUmbraHitbox.PLASMA_RADIUS, 0, TAU, 24, Color(1, 0.3, 0.2, 0.95), 2.0)


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("UMBRA_TRANSMUTE_HITBOX_FAIL " + msg)


func _initialize() -> void:
	capture = "capture" in OS.get_cmdline_user_args()
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _freeze_ai() -> void:
	game.boss5_action_timer = 999.0
	game.boss5_decision_timer = 999.0


func _shot(name: String) -> void:
	if not capture:
		return
	shot_n += 1
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.codex/umbra_transmute/%02d_%s.png" % [shot_n, name])


func _frames(n: int) -> void:
	for i in n:
		_freeze_ai()
		if capture:
			await process_frame
		else:
			game._process(1.0 / 60.0)


func _run() -> void:
	await process_frame
	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.codex/umbra_transmute"))
		root.size = Vector2i(1280, 720)
		var ov := Overlay.new()
		ov.game = game
		ov.z_index = 4000
		game.add_child(ov)
	game.startup_thanks_done = true
	game._start_game()
	game._story().queue.clear()
	game._advance_to_phase(5)
	game._story().queue.clear()
	game.mode = "game"
	var intro: RTUmbraIntro = game._umbra_intro()
	game._story().seen[RTUmbraIntro.SEEN_KEY] = true
	intro.start()
	intro.skip()
	_check(game.boss_active, "a batalha deveria comecar")
	game.run_retry_invulnerability_timer = 0.0
	var center: Vector2 = game.experimental_phase_controller.boss_encounter_center()
	game.boss_pos = center
	game.player_pos = center + Vector2(360, 30)
	game.camera_follow_center = (game.boss_pos + game.player_pos) * 0.5
	await _frames(20)

	# --- Hitboxes (numerico) ---
	var P := Vector2(1000, 1000)
	_check(RTUmbraHitbox.body_hits_circle(P, P + Vector2(0, -36), 4.0), "cabeca deveria contar")
	_check(RTUmbraHitbox.body_hits_circle(P, P + Vector2(0, 36), 4.0), "pernas deveriam contar")
	_check(not RTUmbraHitbox.body_hits_circle(P, P + Vector2(40, 0), 4.0), "40 px ao lado nao deveria contar")
	_check(RTUmbraHitbox.feet_in_circle(P, P + Vector2(0, 34 + 100), 100.0), "pes na borda do circulo no chao")
	_check(not RTUmbraHitbox.feet_in_circle(P, P + Vector2(0, -150), 100.0), "cabeca dentro de area do chao nao conta")
	_check(RTUmbraHitbox.body_in_cone(P, P + Vector2(-200, 0), Vector2.RIGHT, 380.0, 0.1), "cone de frente")
	_check(not RTUmbraHitbox.body_in_cone(P, P + Vector2(-200, 0), Vector2.LEFT, 380.0, 0.4), "cone de costas")
	_check(RTUmbraHitbox.umbra_touches_body(P, P + Vector2(0, -120)), "encostar no cabelo/torso da UMBRA")
	_check(not RTUmbraHitbox.umbra_touches_body(P, P + Vector2(70, 0)), "70 px ao lado da UMBRA nao encosta")

	# --- Plasma: sai da mao, acerta a Geovana parada ---
	game.enemy_bullets.clear()
	var hp0: int = game.player_hp
	game._fire_umbra_projectile()
	var bullet: Dictionary = game.enemy_bullets.back()
	print("PLASMA_ORIGIN ", Vector2(bullet["pos"]) - game.boss_pos, " dir ", bullet["dir"], " player ", game.player_pos - game.boss_pos)
	_check(Vector2(bullet["pos"]).distance_to(RTUmbraHitbox.umbra_hand(game.boss_pos, Vector2(bullet["dir"]))) < 2.0, "plasma deveria sair da mao")
	_check(RTUmbraHitbox.umbra_hand(game.boss_pos, Vector2.RIGHT).y < game.boss_pos.y - 20.0, "mao acima de boss_pos")
	var hit := false
	for i in 240:
		await _frames(1)
		if capture and i == 30:
			await _shot("plasma_voando")
		if int(game.player_hp) < hp0:
			hit = true
			break
	_check(hit, "plasma deveria acertar a Geovana parada")
	if capture:
		await _shot("plasma_acerto")

	# --- Transmutacao ---
	game.run_retry_invulnerability_timer = 99.0
	game.enemy_bullets.clear()
	game.boss_pos = center
	game.player_pos = center + Vector2(260, 60)
	await _frames(10)
	RTUmbraBossAnimation.on_action(game, "TRANSMUTAR_VORTICE")
	game._transmute_umbra_dimension("TRANSMUTAR_VORTICE")
	game.phase5_telegraphs.clear()  # mantem a UMBRA no lugar para a captura
	_check(game.phase5_transmute_active, "vfx ativo")
	_check(is_equal_approx(game.phase5_transmute_duration, RTUmbraTransmuteVfx.DURATION), "duracao do vfx")
	_check(Vector2(game.phase5_transmute_center).distance_to(game.boss_pos) < 1.0, "centro na UMBRA")
	var marks := [0.25, 0.4, 0.5, 0.6, 0.72, 0.85, 1.1, 1.8]
	var mi := 0
	var saw_radius := false
	var guard := 0
	while game.phase5_transmute_active and guard < 600:
		guard += 1
		await _frames(1)
		if RTUmbraTransmuteVfx.radius(game) > 300.0:
			saw_radius = true
		if mi < marks.size() and float(game.phase5_transmute_timer) >= float(marks[mi]):
			if capture:
				await _shot("transmutar_%.2f" % float(marks[mi]))
			mi += 1
	_check(saw_radius, "a frente da dimensao deveria se espalhar")
	_check(not game.phase5_transmute_active, "vfx deveria terminar")
	_check(String(game.boss5_dimension) == "vortice", "dimensao trocada")
	if not failed:
		print("UMBRA_TRANSMUTE_HITBOX_SMOKE_OK shots=%d" % shot_n)
	quit(1 if failed else 0)
