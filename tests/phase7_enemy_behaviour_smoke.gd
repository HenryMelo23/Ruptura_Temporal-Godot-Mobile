extends SceneTree

var game: Node
var failed: bool = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE7_ENEMY_BEHAVIOUR_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame

	game._start_game()
	game.current_phase = 7
	game.mode = "game"
	game.phase_started_at = 0.0
	game.time_alive = 0.0
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.phase7_ember_patches.clear()
	game.player_pos = Vector2(640, 420)
	_check(game._current_map_texture() == game.textures["map_phase_7"], "phase 7 did not use assets/sprites/Fase7.jpg")
	_check(game._enemy_limit() == game.PHASE7_ENEMY_LIMIT_BASE, "phase 7 should start capped at 7 enemies")
	game.time_alive = game.PHASE7_LIMIT_BREAK_TIME + 1.0
	game.phase1_limit_break_kills_start = -1
	game.enemies_killed = 200
	_check(game._enemy_limit() == game.PHASE7_ENEMY_LIMIT_BASE, "phase 7 should not add enemies immediately at limit break")
	game.enemies_killed = 249
	_check(game._enemy_limit() == game.PHASE7_ENEMY_LIMIT_BASE, "phase 7 should require 50 kills after 16 minutes for +1 limit")
	game.enemies_killed = 250
	_check(game._enemy_limit() == game.PHASE7_ENEMY_LIMIT_BASE + 1, "phase 7 should add +1 limit each 50 kills after 16 minutes")
	game.enemies_killed = 0
	game.phase1_limit_break_kills_start = -1
	game.boss_ready = true
	_check(game._boss_call_can_start(false), "phase 7 should allow boss call when ready")
	game.boss_ready = false
	_check(game.textures["enemy_phase_7_cinerido_mov"].all(func(t): return t != null), "Cinerido movement frames not loaded")
	_check(game.textures["enemy_phase_7_cinerido_atk"].all(func(t): return t != null), "Cinerido attack frames not loaded")
	_check(game.textures["enemy_phase_7_pangoliro"].all(func(t): return t != null), "Pangoliro movement frames not loaded")
	_check(game.textures["enemy_phase_7_pangoliro_atk"].all(func(t): return t != null), "Pangoliro attack frame not loaded")
	_check(game.textures["enemy_phase_7_corvol"].all(func(t): return t != null), "Corvol frames not loaded")

	game.time_alive = 20.0
	for i in range(8):
		_check(game._choose_phase7_enemy_type() == game.ENEMY_CINERIDO, "first 45s should spawn only Cinerido")
	game.time_alive = 150.0
	game.enemies.clear()
	for i in range(game.PHASE7_PANGOLIRO_LIMIT):
		game._spawn_enemy(game.ENEMY_PANGOLIRO, Vector2(300 + i * 24, 280))
	for i in range(game.PHASE7_CORVOL_LIMIT):
		game._spawn_enemy(game.ENEMY_CORVOL, Vector2(300 + i * 24, 360))
	for i in range(24):
		_check(game._choose_phase7_enemy_type() == game.ENEMY_CINERIDO, "phase 7 caps should fall back to Cinerido")

	game.enemies.clear()
	game.enemy_bullets.clear()
	game.player_pos = Vector2(500, 420)
	game.player_hp = game.player_hp_max
	game.time_alive = 300.0
	_check(is_equal_approx(float(game.PHASE7_CINERIDO_CONE_RANGE), 102.0), "Cinerido cone range should be 30px shorter")
	game._spawn_enemy(game.ENEMY_CINERIDO, Vector2(360, 420))
	var cinerido: Dictionary = game.enemies.back()
	_check(game._enemy_texture(cinerido) in game.textures["enemy_phase_7_cinerido_mov"], "Cinerido did not start with movement frame")
	cinerido["phase7_attack_cd"] = 0.0
	game._update_enemies(0.02)
	_check(String(cinerido.get("phase7_state", "")) != "windup", "Cinerido started attack from old 150px range")
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_CINERIDO, Vector2(395, 420))
	cinerido = game.enemies.back()
	cinerido["phase7_attack_cd"] = 0.0
	game._update_enemies(0.02)
	_check(String(cinerido.get("phase7_state", "")) == "windup", "Cinerido did not telegraph before attack")
	game._update_enemies(game.PHASE7_CINERIDO_WINDUP + 0.02)
	game._update_enemies(0.02)
	_check(game.player_hp < game.player_hp_max, "Cinerido cone did not damage the player")
	_check(String(cinerido.get("phase7_state", "")) in ["active", "recovery"], "Cinerido did not advance attack state")

	game.enemies.clear()
	game.player_pos = Vector2(720, 420)
	game._spawn_enemy(game.ENEMY_PANGOLIRO, Vector2(420, 420))
	var pangoliro: Dictionary = game.enemies.back()
	var hp_before: float = float(pangoliro["hp"])
	pangoliro["facing_dir"] = Vector2.RIGHT
	game._damage_enemy(pangoliro, 100.0, "phase7_smoke", false, false, Vector2(560, 420))
	var front_taken: float = hp_before - float(pangoliro["hp"])
	pangoliro["phase7_vulnerable"] = game.PHASE7_PANGOLIRO_VULNERABLE
	hp_before = float(pangoliro["hp"])
	game._damage_enemy(pangoliro, 100.0, "phase7_smoke", false, false, Vector2(560, 420))
	var vulnerable_taken: float = hp_before - float(pangoliro["hp"])
	_check(front_taken < 70.0, "Pangoliro front armor did not reduce damage")
	_check(vulnerable_taken > 120.0, "Pangoliro vulnerable state did not amplify damage")
	game.enemies.clear()
	game.player_pos = Vector2(720, 420)
	game._spawn_enemy(game.ENEMY_PANGOLIRO, Vector2(420, 420))
	pangoliro = game.enemies.back()
	pangoliro["phase7_attack_cd"] = 0.0
	game._update_enemies(0.02)
	_check(String(pangoliro.get("phase7_state", "")) == "align", "Pangoliro did not start charge alignment")
	game._update_enemies(game.PHASE7_PANGOLIRO_ALIGN_TIME + 0.02)
	game._update_enemies(game.PHASE7_PANGOLIRO_WINDUP + 0.02)
	_check(String(pangoliro.get("phase7_state", "")) == "roll", "Pangoliro did not enter roll state")

	game.enemies.clear()
	game.enemy_bullets.clear()
	game.player_pos = Vector2(680, 420)
	game._spawn_enemy(game.ENEMY_CORVOL, Vector2(430, 420))
	var corvol: Dictionary = game.enemies.back()
	corvol["phase7_attack_cd"] = 0.0
	game._update_enemies(0.02)
	_check(String(corvol.get("phase7_state", "")) == "prepare", "Corvol did not enter dive preparation")
	game._update_enemies(game.PHASE7_CORVOL_PREPARE + 0.02)
	game._update_enemies(game.PHASE7_CORVOL_ASCEND + 0.02)
	game._update_enemies(game.PHASE7_CORVOL_DIVE_TIME + 0.2)
	game._update_enemies(0.02)
	_check(game.enemy_bullets.any(func(bullet): return String(bullet.get("type", "")) == "corvol_pena"), "Corvol dive did not release feather projectiles")

	if failed:
		_cleanup()
		quit(1)
		return
	print("PHASE7_ENEMY_BEHAVIOUR_OK map=Fase7.jpg cinerido pangoliro corvol boss_ready_gate")
	_cleanup()
	quit(0)


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	if game.get_parent() == root:
		root.remove_child(game)
	game.free()
