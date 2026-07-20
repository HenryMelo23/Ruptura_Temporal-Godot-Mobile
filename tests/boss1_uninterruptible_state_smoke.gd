extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS1_UNINTERRUPTIBLE_STATE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _configure_phase1() -> void:
	game._start_game()
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 3000.0
	game.boss_hp = 3000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(420.0, 0.0)
	game.boss_entry_timer = 0.0
	game.boss_stage_timer = 0.0
	game.boss_stage_approaching = false
	game.boss_attacks.clear()
	game.boss_transition_waves.clear()
	game.boss1_time_wave.clear()
	game.boss1_absorb_timer = 0.0
	game.boss1_absorb_cooldown = 99.0
	game.boss1_rewind_sequence.clear()
	game.manifestation_secondaries.clear()
	game.boss_tp_stun_timer = 0.0


func _lock_boss_with_gravitante() -> void:
	game.manifestation_secondaries = [{
		"kind": "gravitante",
		"life": game.SECONDARY_GRAVITANTE_DURATION * 0.5,
		"max": game.SECONDARY_GRAVITANTE_DURATION,
		"center": game.boss_pos,
		"pulse_tick": 0.0,
		"captured": 0,
		"orbital_bonus": 0,
		"finalized": false
	}]
	_check(game._boss_trapped_by_gravitante(), "gravitante did not lock the boss in the reproduced setup")


func _run() -> void:
	_configure_phase1()
	_lock_boss_with_gravitante()
	game.boss1_absorb_timer = 4.2
	game._update_boss(0.5)
	_check(game.boss1_absorb_timer < 4.0, "absorb timer froze while boss was trapped by Gravitante")

	_configure_phase1()
	game.boss_tp_stun_timer = 2.0
	game.boss1_absorb_timer = 0.45
	game._update_boss(0.6)
	_check(is_equal_approx(game.boss1_absorb_timer, 0.0), "absorb timer froze while boss was stunned")
	_check(game.boss1_absorb_cooldown > 0.0, "absorb did not finish cleanly after stun overlap")

	_configure_phase1()
	_lock_boss_with_gravitante()
	game._start_boss_stage()
	game.boss_stage_safe_angle = 0.0
	var stage_before: float = game.boss_stage_timer
	game._update_boss(0.75)
	_check(game.boss_stage_timer < stage_before, "stage jump timer froze while boss was trapped by Gravitante")

	_configure_phase1()
	game.boss_pos = game.WORLD_SIZE * 0.5 + Vector2(360.0, 0.0)
	_lock_boss_with_gravitante()
	game._start_boss_stage()
	var approach_before: float = game.boss_pos.distance_to(game.WORLD_SIZE * 0.5)
	game._update_boss(0.5)
	_check(game.boss_pos.distance_to(game.WORLD_SIZE * 0.5) < approach_before, "stage approach froze while boss was trapped by Gravitante")

	_configure_phase1()
	_lock_boss_with_gravitante()
	game.boss1_time_wave = {
		"origin": game.boss_pos,
		"radius": 48.0,
		"direction": 1.0,
		"max_radius": 1800.0,
		"age": 0.0,
		"variant": 0,
		"target_peer": game._mp_unique_id()
	}
	game._update_boss(0.25)
	_check(float(game.boss1_time_wave.get("age", 0.0)) > 0.20, "time wave age froze while boss was trapped by Gravitante")

	print("BOSS1_UNINTERRUPTIBLE_STATE_SMOKE_OK absorb_gravitante=true absorb_stun=true stage_gravitante=true approach_gravitante=true time_wave_gravitante=true")
	quit(0)
