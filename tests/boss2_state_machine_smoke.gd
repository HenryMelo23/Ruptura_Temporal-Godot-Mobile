extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("BOSS2_STATE_MACHINE_SMOKE_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()
	game.current_phase = 2
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 6000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(240, 60)
	game.boss_attacks.clear()
	game._reset_boss2_state()

	game._boss2_start_reposition()
	_expect(game.boss2_state == game.BOSS2_STATE_REPOSITION, "reposition_state_missing")
	game.boss2_target_position = game.boss_pos + Vector2(180, 0)
	game.boss2_action_timer = 3.0
	var old_pos: Vector2 = game.boss_pos
	game._boss2_update_reposition(0.35)
	_expect(game.boss_pos != old_pos, "boss2_did_not_walk")
	_expect(game.boss_attacks.all(func(a): return String(a.get("kind", "")) != "rush"), "boss2_created_rush")

	game.boss_attacks.clear()
	game._boss2_start_freezing_breath()
	_expect(game.boss2_state == game.BOSS2_STATE_FREEZING_BREATH, "breath_state_missing")
	_expect(game.boss_attacks.size() == 1 and String(game.boss_attacks[0].get("kind", "")) == "frost_breath", "breath_attack_missing")

	game.boss_attacks.clear()
	game.boss_hp = game.boss_hp_max
	game._boss2_start_spin_spit_up()
	_expect(game.boss_attacks.size() == 1 and String(game.boss_attacks[0].get("kind", "")) == "spin_spit_up", "spin_attack_missing")
	_expect(Array(game.boss_attacks[0].get("targets", [])).size() == 5, "spin_above_60_not_five")
	game.boss_attacks.clear()
	game.boss_hp = game.boss_hp_max * 0.35
	game._boss2_start_spin_spit_up()
	_expect(Array(game.boss_attacks[0].get("targets", [])).size() == 7, "spin_below_40_not_seven")

	game.boss_attacks.clear()
	game._boss2_start_glacial_stomp()
	_expect(String(game.boss_attacks[0].get("kind", "")) == "glacial_stomp", "stomp_attack_missing")
	_expect(Array(game.boss_attacks[0].get("cracks", [])).size() >= 3, "stomp_cracks_missing")

	game.boss_attacks.clear()
	game.player_pos = game.boss_pos + Vector2(120, 0)
	game._boss2_start_ice_prison()
	_expect(String(game.boss_attacks[0].get("kind", "")) == "ice_prison", "prison_attack_missing")
	_expect(Array(game.boss_attacks[0].get("crystals", [])).size() >= 3, "prison_crystals_missing")

	game.boss_attacks.clear()
	game._boss2_start_double_blizzard()
	_expect(game.boss_attacks.size() == 2, "double_blizzard_not_two_patterns")
	_expect(game.boss_attacks.all(func(a): return String(a.get("kind", "")) == "blizzard"), "double_blizzard_wrong_kind")

	print("BOSS2_STATE_MACHINE_SMOKE_OK reposition=true breath=true spin=true stomp=true prison=true double_blizzard=true")
	quit(0)
