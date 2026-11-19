extends SceneTree

## QA visual: Simbiose (Fome baixa/maxima + mordida), Verme-Rei comum, Rei Perfeito,
## troca subterranea, Devorar Hospedeiro e chefe sendo devorado.
## Args: --mobile (844x390 Android landscape) --gif (frames do ciclo)

var game: Node
var ctl: RTParasiticaController
var out_dir := "res://.agent_logs/para"
var prefix := "desk"
var mobile := false
var gif := false
var frame_i := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--mobile":
			mobile = true
		elif arg == "--gif":
			gif = true
	prefix = "mob" if mobile else "desk"
	root.size = Vector2i(844, 390) if mobile else Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _shot(name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("%s/%s_%s.png" % [out_dir, prefix, name]))


func _gif_frame() -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.resize(640, int(640.0 * float(img.get_height()) / float(img.get_width())))
	img.save_png(ProjectSettings.globalize_path("%s/gif_%s_%03d.png" % [out_dir, prefix, frame_i]))
	frame_i += 1


func _advance(seconds: float, capture: bool = false) -> void:
	var dt := 1.0 / 30.0
	var n := int(seconds / dt)
	for i in range(n):
		game.time_alive += dt
		ctl.update(dt)
		for e in game.enemies:
			if float(e.get("hp", 0.0)) <= 0.0:
				continue
		for j in range(game.enemies.size() - 1, -1, -1):
			if float(game.enemies[j].get("hp", 0.0)) <= 0.0:
				game._kill_enemy(game.enemies[j])
		if capture and gif:
			await _gif_frame()
		elif not capture:
			pass


func _enemy(offset: Vector2, hp: float = 60000.0, kind: String = "") -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON if kind == "" else kind, game.player_pos + offset)
	var e: Dictionary = game.enemies[-1]
	e["hp"] = hp
	e["max_hp"] = hp
	e["speed"] = 0.0
	e["damage"] = 0.0
	return e


func _seed(e: Dictionary, n: int) -> void:
	e["seeds"] = n
	e["parasite_mark_time"] = game.PARASITE_MARK_DURATION


func _base() -> void:
	game.forced_initial_phase = 1
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.startup_thanks_done = true
	game.set_process(false)
	if mobile:
		game.ui_platform_override = game.UI_PLATFORM_ANDROID
	else:
		game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.mode = "game"
	game.manifestation_key = "parasitica"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 240.0
	game.player_damage = 120.0
	game.player_pos = Vector2(1500, 1100)
	game.camera_follow_initialized = false
	game.enemies.clear()
	game.effects.clear()
	game.boss_active = false
	game.arauto.clear()
	game.last_skill_time = -999.0
	game.last_secondary_time = -999.0
	ctl = game._parasitica()
	ctl.clear_all()
	game._update_button_layout(Vector2(root.size))


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	_base()
	# --- Simbiose com Fome baixa
	var a := _enemy(Vector2(200, -30))
	var b := _enemy(Vector2(240, 90))
	var c := _enemy(Vector2(-230, 40))
	_seed(a, 2)
	_seed(b, 4)
	_seed(c, 1)
	game._use_skill()
	ctl.hunger = 2
	await _advance(0.2)
	await _shot("01_symbiosis_low")
	# --- Fome maxima + mordida
	ctl.hunger = 12
	ctl.bite_visuals.append({"from": game.player_pos, "to": Vector2(a["pos"]), "life": 0.16, "max": 0.32})
	await _shot("02_symbiosis_max_bite")
	# --- Verme-Rei comum (host com 4 larvas) surgindo e atacando
	ctl.bite_visuals.clear()
	game._use_secondary_skill()
	await _advance(0.2)
	await _shot("03_king_emerge")
	await _advance(0.6)
	ctl.king["bite"] = 0.18
	await _shot("04_king_attack")
	# --- Troca subterranea
	ctl.king["target"] = ctl.enemy_ref(c)
	ctl._begin_tunnel(ctl._desired_attack_pos(ctl.enemy_ref(c)))
	await _advance(0.32)
	await _shot("05_king_tunnel")
	# --- Devorar hospedeiro (comum)
	await _advance(0.5)
	_seed(c, 5)
	ctl._devour(ctl.enemy_ref(c))
	await _advance(0.12)
	await _shot("06_devour")
	# --- Rei Perfeito
	_base()
	var m := _enemy(Vector2(220, 0))
	_enemy(Vector2(-200, 80))
	_seed(m, 5)
	game._use_skill()
	ctl.hunger = 12
	game._use_secondary_skill()
	await _advance(0.9)
	ctl.king["fed"] = 9
	await _shot("07_perfect_king")
	# --- Chefe sendo devorado
	_base()
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = 90000.0
	game.boss_hp_max = 120000.0
	game.boss_pos = game.player_pos + Vector2(300, -40)
	game.boss_parasite_seeds = 5
	game.boss_parasite_mark_time = 8.0
	game._use_skill()
	ctl.hunger = 9
	game.boss_parasite_seeds = 5
	game.boss_parasite_mark_time = 8.0
	game._use_secondary_skill()
	await _advance(0.7)
	game.boss_parasite_seeds = 5
	game.boss_parasite_mark_time = 8.0
	ctl._devour({"kind": "boss", "uid": -1})
	await _advance(0.1)
	await _shot("08_boss_devoured")
	# --- GIF do ciclo completo
	if gif:
		_base()
		var h1 := _enemy(Vector2(210, -20))
		var h2 := _enemy(Vector2(-240, 70))
		var h3 := _enemy(Vector2(60, 220))
		_seed(h1, 3)
		_seed(h2, 2)
		game._use_skill()
		for k in range(40):
			game.time_alive += 1.0 / 30.0
			if k % 5 == 0:
				game._apply_bullet_effect({"kind": "parasitica", "damage": 60.0, "pos": h1["pos"]}, h1)
			ctl.update(1.0 / 30.0)
			await _gif_frame()
		game._use_secondary_skill()
		for k in range(150):
			game.time_alive += 1.0 / 30.0
			var tgt = null
			if ctl.king_active() and String(Dictionary(ctl.king.get("target", {})).get("kind", "")) == "enemy":
				tgt = game._enemy_by_uid(int(ctl.king["target"]["uid"]))
			if k % 5 == 0 and tgt != null and float(tgt.get("hp", 0.0)) > 0.0:
				game._apply_bullet_effect({"kind": "parasitica", "damage": 60.0, "pos": tgt["pos"]}, tgt)
			ctl.update(1.0 / 30.0)
			for j in range(game.enemies.size() - 1, -1, -1):
				if float(game.enemies[j].get("hp", 0.0)) <= 0.0:
					game._kill_enemy(game.enemies[j])
			if game.enemies.size() < 3:
				var ne := _enemy(Vector2.from_angle(randf() * TAU) * 230.0, 4000.0)
				_seed(ne, 3)
			await _gif_frame()
	print("PARASITICA_VISUAL_DEMO_DONE frames=%d" % frame_i)
	quit(0)
