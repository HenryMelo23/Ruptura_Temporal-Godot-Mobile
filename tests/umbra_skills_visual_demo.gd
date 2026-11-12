extends SceneTree

## Captura cada habilidade da UMBRA no meio do efeito, na fase 5 definitiva.
## Saida: .agent_logs/umbra_skills/<nn>_<acao>.png
## Arg opcional: --only=ACAO

var game: Node
const OUT := "res://.agent_logs/umbra_skills/"

const SHOTS: Array = [
	# [acao, dimensao, segundos ate a foto]
	["ATAQUE", "base", 0.35],
	["TELEPORTE", "base", 0.3],
	["TELEPORTE_JUKE", "base", 0.3],
	["SIFON", "base", 1.2],
	["REBOBINAR", "base", 1.1, Vector2(230, -60)],
	["ECO_PROFETICO", "base", 0.7, Vector2(160, 40)],
	["TRANSMUTAR_NECROSE", "base", 0.35],
	["VORTICE", "vortice", 1.6],
	["PRISAO", "gravidade", 0.5],
	["MIASMA", "necrose", 1.0],
	["DESCARGA_ELETRICA", "ressonancia", 1.0],
	["CAMINHO_ESPINHOS", "hemorragia", 2.0],
	["LASER_SOBRECARGA", "atrito", 4.5],
	["PRAGA_RATOS", "rastro", 0.8],
]


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _shot(name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))


func _setup() -> void:
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 30000.0
	game.boss_hp = 24000.0
	var c: Vector2 = game.experimental_phase_controller.boss_encounter_center()
	game.boss_pos = c + Vector2(260, -40)
	game.player_pos = c + Vector2(-260, 60)
	game.player_hp_max = 999999
	game.player_hp = 999999
	game.boss5_velocity = Vector2.ZERO
	game.phase5_hazards.clear()
	game.phase5_telegraphs.clear()
	game.phase5_rats.clear()
	game.enemy_bullets.clear()
	game.boss5_siphon_timer = 0.0
	game.boss5_transmute_hangover = 0.0
	game.boss5_authoritative_decision = {}
	game.phase5_player_history.clear()
	for i in range(12):
		game.phase5_player_history.append(game.player_pos + Vector2(-float(12 - i) * 9.0, 0.0))
	game.camera_follow_initialized = false


func _step(seconds: float, move: Vector2 = Vector2.ZERO) -> void:
	var dt := 1.0 / 30.0
	var t := 0.0
	while t < seconds:
		game.player_pos += move * dt
		game.time_alive += dt
		game._update_phase5_telegraphs(dt)
		game._update_phase5_hazards(dt)
		game._update_phase5_rats(dt)
		game._update_enemy_bullets(dt)
		if game.has_method("_umbra_base_skills"):
			game._umbra_base_skills().update(dt)
		if game.boss5_siphon_timer > 0.0:
			game.boss5_siphon_timer -= dt
		game.boss_phase += dt * 7.2
		game.player_hp = game.player_hp_max
		t += dt


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--only="):
			only = String(arg).substr(7)
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game._advance_to_phase(5)
	game.set_process(false)
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	game._load_umbra_mobile_memory()
	var n := 0
	for entry in SHOTS:
		n += 1
		var action: String = String(entry[0])
		if only != "" and only != action:
			continue
		_setup()
		game.boss5_dimension = String(entry[1])
		game.boss5_dimension_timer = 30.0 if game.boss5_dimension != "base" else 0.0
		game.boss5_teleport_cooldown = 0.0
		game.boss5_ability_cooldowns.clear()
		game._spawn_umbra_action(action)
		_step(float(entry[2]), Vector2(entry[3]) if entry.size() > 3 else Vector2.ZERO)
		if game.has_method("_update_camera"):
			game._update_camera(0.016)
		await _shot("%02d_%s" % [n, action.to_lower()])
		print("UMBRA_SKILL_SHOT ", action, " hazards=", game.phase5_hazards.size(), " tele=", game.phase5_telegraphs.size(), " bullets=", game.enemy_bullets.size(), " rats=", game.phase5_rats.size())
	print("UMBRA_SKILLS_VISUAL_DONE")
	quit(0)
