extends SceneTree

## Captura de revisao dos VFX dos espectros (15 quadros/s).
## Uso (com tela): godot --path . --script res://tests/spectre_vfx_capture.gd -- <espectro>
## Saida: res://.codex/spectre_vfx/<espectro>_<n>.png

var game: Node
var shots := 0
var aura := "Racional"
var t := 0.0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("-"):
			aura = a
	call_deferred("_run")


func _shot() -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var dir := ProjectSettings.globalize_path("res://.codex/spectre_vfx")
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_texture().get_image().save_png(dir + "/%s_%03d.png" % [aura.to_lower(), shots])
	shots += 1


## Anda num oito em volta do centro, para os rastros terem para onde ir.
func _path(time: float) -> Vector2:
	return Vector2(1400.0, 1000.0) + Vector2(sin(time * 1.3) * 260.0, sin(time * 2.6) * 120.0)


func _play(seconds: float, move: bool) -> void:
	var dt := 1.0 / 30.0
	var e := 0.0
	var n := 0
	while e < seconds:
		if move:
			t += dt
			game.player_pos = _path(t)
		game._update_game(dt)
		_hook_tick(dt)
		e += dt
		n += 1
		if n % 2 == 0:
			await _shot()


func _run() -> void:
	await process_frame
	game.run_tutorial_enabled = false
	game.active_character_key = game.CHARACTER_GEOVANA
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game._finish_startup_thanks()
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.mode = "game"
	game.is_multiplayer = false
	game.spawn_timer = 99999.0
	game.shop_rift_controller.allow_rift = false
	game.aura_state = game.AuraSystem.create(aura, 5)
	game.player_pos = _path(0.0)
	game.enemies.clear()
	for i in range(14):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(float(i) * TAU / 14.0) * (220.0 + float(i % 4) * 60.0))
	for i in range(10):
		var from: Vector2 = game.player_pos + Vector2.from_angle(float(i) * 0.63) * 380.0
		game.enemy_bullets.append({"pos": from, "dir": (game.player_pos - from).normalized(), "life": 12.0, "damage": 0.0, "phase": 0.0})
	game.player_hp = game.player_hp_max * 50.0
	var warm := float(OS.get_environment("VFX_WARMUP")) if OS.get_environment("VFX_WARMUP") != "" else 0.0
	while warm > 0.0:
		t += 1.0 / 30.0
		game.player_pos = _path(t)
		game._update_game(1.0 / 30.0)
		warm -= 1.0 / 30.0
	await _play(0.3, true)
	await _hook_start()
	await _play(float(OS.get_environment("VFX_SECONDS")) if OS.get_environment("VFX_SECONDS") != "" else 3.6, true)
	print("SPECTRE_VFX_OK aura=%s shots=%d" % [aura, shots])
	quit(0)


var clock := 0.0
var marks := {}


func _once(key: String, at: float) -> bool:
	if clock >= at and not marks.has(key):
		marks[key] = true
		return true
	return false


func _hook_start() -> void:
	match aura:
		"Racional":
			game.aura_state["rational_cooldown"] = 0.0
			game._apply_aura_events(game.AuraSystem.on_dash(game.aura_state, {"player_pos": game.player_pos}))
		"Voraz":
			game.aura_state["voracious_hunger"] = game.AuraSystem.hunger_max(game.aura_state) * 0.8
			for enemy in game.enemies:
				enemy["hp"] = float(enemy.get("max_hp", 100.0)) * 0.12
		"Avarento":
			game.score = 4000
			game.aura_state["avarento_pending"] = 900
			game.aura_state["avarento_pending_lastro"] = 3.0
		"Profetica":
			game.aura_state["prophecy_vision_cd"] = 0.0


func _hook_tick(dt: float) -> void:
	clock += dt
	match aura:
		"Vanguarda":
			for at in [0.2, 1.4, 2.6]:
				if _once("hit%s" % at, at):
					var res: Dictionary = game.AuraSystem.on_player_hit(game.aura_state, 25.0, game.player_hp, game.player_hp_max)
					game._apply_aura_events(res.get("events", []))
		"Sanguinaria":
			for at in [0.8, 2.2]:
				if _once("kill%s" % at, at):
					var hunted: Dictionary = game._sanguinaria_find_hunt_enemy()
					if not hunted.is_empty():
						hunted["killed_by_category"] = {"basic_attack": "basic_attack", "hab1": "skill_q", "ultimate": "skill_e"}.get(String(game.aura_state.get("blood_hunt_rule", "")), "basic_attack")
						hunted["killed_by_source"] = "test"
						game._sanguinaria_handle_enemy_kill(hunted)
		"Voraz":
			for at in [0.6, 1.8, 3.0]:
				if _once("dash%s" % at, at) and not game.enemies.is_empty():
					var target: Vector2 = Vector2(game.enemies[0]["pos"]) + Vector2(60, 0)
					game._voraz_devour_dash(game.player_pos, target)
		"Profetica":
			for at in [1.0, 1.6]:
				if _once("dodge%s" % at, at) and game.AuraSystem.prophecy_register_dodge(game.aura_state):
					game._prophecy_on_dodge(game.player_pos + Vector2(80, -20))
			if _once("crit", 2.4):
				var shot := {"damage": 10.0}
				game._apply_aura_events(game.AuraSystem.on_attack(game.aura_state, shot))
