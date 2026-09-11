extends SceneTree

var game: Node
var failed := false


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _advance_effects(seconds: float, step := 0.05) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		var dt = min(step, seconds - elapsed)
		game._update_effects(dt)
		elapsed += dt


func _run() -> void:
	game.selected_manifestation = 1
	game._start_game()
	game.set_process(false)
	# This test starts after landing; startup deliberately blocks ability input.
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.manifestation_key = "lacerante"
	game.time_alive = 10.0
	game.player_damage = 100.0
	game.player_pos = Vector2(800, 450)
	game.enemies.clear()

	var slash_points: Array = game._lacerante_stage_points(game.player_pos, Vector2.RIGHT, 0)
	_check(Vector2(slash_points[-1]).distance_to(game.player_pos) > 150.0, "Lacerante ATK did not gain 15px reach")
	var common = {"type": game.ENEMY_COMMON}
	var large = {"type": game.ENEMY_AGGLOMERATOR}
	_check(game._lacerante_damage_for_enemy(100.0, large) > game._lacerante_damage_for_enemy(100.0, common), "large enemies do not receive bonus slash damage")

	game.lacerante_coagula = 10
	_check(is_equal_approx(game._lacerante_coagulum_damage_multiplier(), 1.03), "Coagulum damage scaling is incorrect")
	var interval_with_coagula = game._current_attack_interval()
	game.lacerante_coagula = 0
	_check(interval_with_coagula < game._current_attack_interval(), "Coagulum attack speed scaling is missing")

	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(90, 0))
	var target: Dictionary = game.enemies[0]
	target["hp"] = 1.0
	target["max_hp"] = 100.0
	_check(game._try_arm_lacerante_empower(), "reinforced slash did not arm")
	game._fire_lacerante(0, Vector2.RIGHT)
	_check(game.lacerante_coagula == 1, "reinforced execution did not grant exactly one Coagulum")
	_check(not game.lacerante_empowered_ready, "reinforced slash was not consumed")
	_check(not game._try_arm_lacerante_empower(), "reinforcement ignored its 3 second cooldown")

	game._update_button_layout(Vector2(1280, 720))
	_check(game.buttons.has("lacerante_empower"), "Lacerante reinforcement button is missing")
	var empower_center: Vector2 = game.buttons["lacerante_empower"].get_center()
	for control_key in ["attack", "skill", "secondary", "dash"]:
		_check(empower_center.distance_to(game.buttons[control_key].get_center()) >= 78.0, "reinforcement button overlaps " + control_key)
	game.last_skill_time = -999.0
	game._use_skill()
	_check(game.slashes.any(func(s): return String(s.get("kind", "")) == "lacerante_spin"), "Q did not create the rotating blade visual")

	game.enemies.clear()
	game.slashes.clear()
	game.effects.clear()
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 10000.0
	game.boss_hp = game.boss_hp_max
	game.boss_pos = game.player_pos + Vector2(92.0, 0.0)
	game.player_damage = 100.0
	game.lacerante_coagula = 0
	game.last_skill_time = -999.0
	game._use_skill()
	_advance_effects(game.LACERANTE_Q_DURATION + 0.08)
	var q_boss_damage: float = game.boss_hp_max - game.boss_hp
	_check(q_boss_damage > 180.0 and q_boss_damage <= 500.0, "Lacerante Q boss damage is not normalized: %.2f" % q_boss_damage)

	game.slashes.clear()
	game.effects.clear()
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 10000.0
	game.boss_hp = game.boss_hp_max
	game.lacerante_coagula = 1000
	game.last_skill_time = -999.0
	game._use_skill()
	_advance_effects(game.LACERANTE_Q_DURATION + 0.08)
	var q_boss_coagula_damage: float = game.boss_hp_max - game.boss_hp
	_check(q_boss_coagula_damage <= game.boss_hp_max * game.LACERANTE_Q_BOSS_TOTAL_HP_CAP + 1.0, "Lacerante Q coagulum scaling bypassed the boss damage cap: %.2f" % q_boss_coagula_damage)
	game.boss_active = false
	game.boss_dead = true
	game.lacerante_coagula = 0

	game.enemies.clear()
	game.score = 0
	game.score_total = 0
	game._spawn_enemy(game.ENEMY_PROJECTOR, Vector2(900, 450))
	var uncommon: Dictionary = game.enemies[0]
	var base_points = game._points_for_enemy(uncommon)
	game._kill_enemy(uncommon)
	_check(game.score == int(round(float(base_points) * game.LACERANTE_UNCOMMON_POINTS_MULT)), "uncommon enemy did not grant 50 percent extra points")

	var details: Dictionary = game._manifestation_details("lacerante")
	_check(String(details["traco"]).contains("Coagulo"), "manifestation screen does not explain Coagulum")
	_check(String(details["funcao"]).contains("50%"), "manifestation screen does not explain uncommon enemy bonus")

	if not failed:
		print("LACERANTE_REWORK_SMOKE_OK reach=%.1f coagula=%d interval=%.3f uncommon_bonus=50%% button=true q_blade=true" % [Vector2(slash_points[-1]).distance_to(game.player_pos), game.lacerante_coagula, interval_with_coagula])
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	quit(1 if failed else 0)
