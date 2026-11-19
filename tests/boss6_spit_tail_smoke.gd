extends SceneTree

## Matriarca (rework): Estagio II: Cuspe Florado (bolas em leque, poca + respingo ao cair)
## e Cauda Condutiva (varre costas/lados, frente livre, so perto).

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition or failed:
		return
	failed = true
	push_error("BOSS6_SPIT_TAIL_FAIL " + message)
	quit(1)


func _setup() -> void:
	game._start_game()
	game.set_process(false)
	game._advance_to_phase(6)
	game.mode = "game"
	game.is_multiplayer = false
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = game._boss_hp_for_phase(6)
	game.boss_hp = game.boss_hp_max
	game.boss_pos = game.boss6_stage_controller.arena_center()
	game.boss6_stage = 1
	game.boss6_state = game.BOSS6_STATE_IDLE
	game.boss6_wait_timer = 99.0
	game.boss6_controller.reset()
	game.player_hp_max = 3000.0
	game.player_hp = 3000.0
	game.last_dash_time = -99.0


func _step(seconds: float) -> void:
	for _i in range(int(round(seconds / 0.02))):
		game.time_alive += 0.02
		game._update_boss_attacks(0.02)
		game.player_shove.update(game, 0.02)


func _attack(kind: String) -> Dictionary:
	for attack in game.boss_attacks:
		if String(Dictionary(attack).get("kind", "")) == kind:
			return attack
	return {}


func _run() -> void:
	_setup()
	var ctrl = game.boss6_controller
	game.boss6_stage = 2
	game.boss_attacks.clear()
	game.boss6_lodarian_pools.clear()
	game.player_pos = game.boss_pos + Vector2(-320.0, 0.0)
	game._start_boss6_acid_bloom(false)
	var spit: Dictionary = _attack(game.BOSS6_ABILITY_ACID_BLOOM)
	var spots: Array = Array(spit.get("spots", []))
	_check(spots.size() == 3, "stage 2 spit should lob three globs")
	var center_spot: Vector2 = Vector2(Dictionary(spots[1])["pos"])
	_check(center_spot.distance_to(game.player_pos) < 80.0, "middle glob is not aimed at the player")
	game.player_pos = center_spot
	var hp0: float = game.player_hp
	_step(0.5)
	_check(game.boss6_lodarian_pools.is_empty(), "glob landed before its flight time")
	_step(1.0)
	_check(game.boss6_lodarian_pools.size() == 3, "landed globs did not leave three pools")
	_check(is_equal_approx(float(Dictionary(game.boss6_lodarian_pools[0])["radius"]), ctrl.SPIT_POOL_RADIUS), "pool radius is not the smaller rework size")
	_check(game.player_hp < hp0, "splash did not hit the player under the glob")
	game.boss6_stage = 3
	_check(Array(ctrl.build_spit_attack(false)["spots"]).size() == 5, "stage 3 spit should lob five globs")

	# Cauda: atras leva, frente nao, longe nao dispara.
	_setup()
	game.boss6_stage = 2
	game.boss6_ai_state["facing"] = -1.0
	game.boss_attacks.clear()
	game.player_pos = game.boss_pos + Vector2(200.0, 40.0)
	_check(ctrl.tail_in_reach(), "close player is not in tail reach")
	game._start_boss6_conductive_tail()
	hp0 = game.player_hp
	_step(0.6)
	_check(game.player_hp < hp0, "tail missed a player behind the boss")
	_check(game.player_pos.distance_to(game.boss_pos) > 210.0, "tail did not knock the player back")
	_setup()
	game.boss6_stage = 2
	game.boss6_ai_state["facing"] = -1.0
	game.boss_attacks.clear()
	game.player_pos = game.boss_pos + Vector2(-200.0, 0.0)
	game._start_boss6_conductive_tail()
	hp0 = game.player_hp
	_step(0.8)
	_check(is_equal_approx(game.player_hp, hp0), "tail hit a player standing in front")
	game.player_pos = game.boss_pos + Vector2(600.0, 0.0)
	_check(not ctrl.tail_in_reach(), "far player still counts as in tail reach")
	var defs: Array = game._boss6_ability_defs()
	_check(not game._boss6_ability_available(defs[2], 0), "tail is available with nobody in reach")
	if failed:
		return
	print("BOSS6_SPIT_TAIL_OK globs=3/5 aimed=true flight=true pools=3 small_pool=true splash=true tail_back=true knockback=true tail_front_safe=true reach_gate=true")
	quit(0)
