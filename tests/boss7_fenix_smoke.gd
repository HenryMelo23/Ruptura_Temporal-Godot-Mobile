extends SceneTree

var game: Node
var failed: bool = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("BOSS7_FENIX_SMOKE_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame

	game._start_game()
	game.set_process(false)
	game.current_phase = 7
	game.mode = "game"
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(180, 120)
	game.player_hp = game.player_hp_max
	game.boss_ready = false
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.boss_attacks.clear()
	game.time_alive = game.BOSS_READY_TIME + 0.01
	game._update_game(0.02)
	_check(game.boss_ready, "Fenix boss ready flag was not released by normal phase 7 update")
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.boss_attacks.clear()

	_check(game.textures["boss7_fly"].all(func(t): return t != null), "Fenix fly frames missing")
	_check(game.textures["boss7_dive"].all(func(t): return t != null), "Fenix dive frames missing")
	_check(game.textures["boss7_core"].all(func(t): return t != null), "Fenix core frames missing")
	_check(game.BOSS7_VISUAL_SIZE.x >= 360.0 and game.BOSS7_VISUAL_SIZE.y >= 330.0, "Fenix visual size was not doubled")
	_check(is_equal_approx(float(game._boss_hit_radius()), float(game.BOSS7_HIT_RADIUS)), "Fenix hit radius is not using phase 7 tuning")
	_check(game._boss_call_can_start(false), "Fenix boss call gate is closed")

	game._start_boss_call_local()
	game.boss_call_timer = 0.01
	game._update_boss_call(0.02)
	_check(game.boss_active, "Fenix did not become active after boss call")
	_check(String(game.boss_name) == "FENIX", "Fenix boss name mismatch")
	_check(is_equal_approx(float(game.boss_hp_max), float(game._boss_hp_for_phase(7))), "Fenix HP scaling mismatch")
	_check(String(game.boss7_state) == game.BOSS7_STATE_INTRO, "Fenix did not start in intro state")

	for i in range(18):
		game._update_boss(0.12)
	_check(String(game.boss7_state) == game.BOSS7_STATE_FLY, "Fenix did not finish intro into fly state")

	game.boss_attacks.clear()
	game._start_boss7_feather_volley()
	game._update_boss7_state(game.BOSS7_FEATHER_WINDUP + 0.02)
	_check(game.boss_attacks.any(func(a): return String(a.get("kind", "")) == game.BOSS7_ATTACK_FEATHER), "Fenix feather volley did not spawn projectiles")

	game.boss_attacks.clear()
	game.enemy_bullets.clear()
	game._start_boss7_whirlwind()
	_check(game.boss7_whirlwind_shots_left == 60, "Fenix whirlwind should start with 60 shots left")
	for step in range(65):
		game._update_boss7_whirlwind(0.05)
	_check(game.enemy_bullets.size() == 60, "Fenix whirlwind should spawn exactly 60 fireballs")
	_check(is_equal_approx(float(game.enemy_bullets[0].get("speed_mult", 0.0)), 170.0 / 210.0), "Fenix whirlwind fireball speed should be reduced by 50% (170/210)")

	game.enemy_bullets.clear()
	game.boss7_flame_waves.clear()
	var dive_target: Vector2 = game.player_pos + Vector2(160.0, -44.0)
	game._spawn_boss7_dive_fireball(dive_target)
	_check(game.enemy_bullets.size() == 1, "Fenix dive fake fireball did not spawn")
	var fireball: Dictionary = game.enemy_bullets[0]
	_check(String(fireball.get("type", "")) == "boss7_dive_fireball", "Fenix dive fake fireball type mismatch")
	_check(Vector2(fireball.get("impact_pos", Vector2.ZERO)).distance_to(dive_target) < 0.01, "Fenix dive fake fireball impact does not match threatened landing")
	_check(float(fireball.get("radius", 0.0)) >= game.BOSS7_DIVE_FIREBALL_RADIUS, "Fenix dive fake fireball stayed too small")
	_check(is_equal_approx(float(fireball.get("wave_radius", 0.0)), 250.0 * game.BOSS7_DIVE_FIREBALL_WAVE_RADIUS_MULT), "Fenix dive fake fireball wave is not 50 percent larger")
	game.player_pos = dive_target + Vector2(190.0, 0.0)
	for step in range(36):
		game._update_enemy_bullets(0.04)
	_check(game.enemy_bullets.is_empty(), "Fenix dive fake fireball did not resolve after reaching ground")
	_check(not game.boss7_flame_waves.is_empty(), "Fenix dive fake fireball did not create a flame wave on ground")
	_check(is_equal_approx(float(game.boss7_flame_waves.back().get("max_radius", 0.0)), 375.0), "Fenix dive fake fireball ground wave radius mismatch")

	game.enemy_bullets.clear()
	game.boss7_flame_waves.clear()
	game.player_pos = dive_target + Vector2(0.0, -86.0)
	game.player_hp = game.player_hp_max
	var hp_before_fireball: float = float(game.player_hp)
	game._spawn_boss7_dive_fireball(dive_target)
	for step in range(40):
		game._update_enemy_bullets(0.04)
	_check(float(game.player_hp) < hp_before_fireball - 100.0, "Fenix dive fake fireball did not deal brutal direct damage")
	_check(game.boss7_flame_waves.is_empty(), "Fenix dive fake fireball should not explode after direct player collision")

	game.boss_attacks.clear()
	game.boss7_reborn = true
	game._start_boss7_crown()
	_check(game.boss_attacks.any(func(a): return String(a.get("kind", "")) == game.BOSS7_ATTACK_CROWN), "Fenix reborn crown did not spawn")
	game.boss7_reborn = false

	game.boss_attacks.clear()
	var hp_before_rebirth: float = float(game.boss_hp_max)
	game._damage_boss(float(game.boss_hp) + 9999.0, "boss7_smoke", false, false, "", game.player_pos)
	_check(game.boss7_core_active, "Fenix first death did not enter ash core")
	_check(not game.boss_dead, "Fenix first death incorrectly ended the fight")
	_check(float(game.boss7_core_hp_max) > 0.0, "Fenix ash core HP not initialized")

	game._damage_boss(float(game.boss7_core_hp_max) * 0.5, "boss7_core_smoke", false, false, "", game.player_pos)
	game.boss7_core_timer = 0.0
	game._update_boss7_core(0.02)
	_check(game.boss7_reborn, "Fenix did not rebirth after ash core timer")
	_check(not game.boss7_core_active, "Fenix ash core stayed active after rebirth")
	_check(float(game.boss_hp) > 0.0 and float(game.boss_hp) < hp_before_rebirth, "Fenix rebirth HP ratio invalid")

	if failed:
		await _cleanup()
		quit(1)
		return
	print("BOSS7_FENIX_SMOKE_OK call hp attacks=[feather,crown] rebirth")
	await _cleanup()
	quit(0)


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
