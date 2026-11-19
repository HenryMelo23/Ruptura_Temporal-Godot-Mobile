extends SceneTree

## Boss 4: Poco Gravitacional: carga sem dano, poco nasce no jogador, puxa,
## fere no nucleo, o sapo da 2 saltos em volta com ondas e o poco implode.

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
	push_error("BOSS4_GRAVITY_FAIL " + message)
	quit(1)


func _setup() -> void:
	game._start_game()
	game.set_process(false)
	game._advance_to_phase(4)
	game.mode = "game"
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 4000.0
	game.boss_hp = 4000.0
	game.boss_pos = game.boss4_entry_target
	game.player_hp_max = 3000.0
	game.player_hp = 3000.0
	game.player_defense = 0.0
	game.boss4_controller.reset()
	game.boss4_attack_timer = 99.0
	game.last_dash_time = -99.0


func _step(seconds: float, dash: bool = false) -> void:
	var steps: int = int(round(seconds / 0.02))
	for _i in range(steps):
		game.time_alive += 0.02
		if dash:
			game.last_dash_time = game.time_alive
		game.boss4_controller.update(0.02)
		game._update_phase4_enemy_hazards(0.02)


func _count(kind: String) -> int:
	var total: int = 0
	for hazard in game.phase4_enemy_hazards:
		if String(hazard.get("kind", "")) == kind:
			total += 1
	return total


func _run() -> void:
	_setup()
	var ctrl = game.boss4_controller
	var Pres = game.Boss4AnimationPresentation
	game.phase4_enemy_hazards.clear()
	game.player_pos = game.boss_pos + Vector2(-340.0, 0.0)
	ctrl.force_action_for_test("gravity")
	var well: Vector2 = Vector2(game.boss4_ai_state["well_pos"])
	_check(well.distance_to(game.player_pos) < 120.0, "well was not placed on the player")
	var hp_before: float = float(game.player_hp)
	_step(0.7)
	_check(_count("boss4_singularity") == 0, "well spawned during the windup")
	_check(is_equal_approx(float(game.player_hp), hp_before), "windup dealt damage")
	_step(0.14)
	_check(String(game.boss4_ai_state["state"]) == ctrl.STATE_ACTIVE, "gravity did not reach the active phase")
	_check(_count("boss4_singularity") == 1, "well was not created when the windup ended")
	# Jogador parado a 200 px do centro e puxado.
	game.player_pos = well + Vector2(200.0, 0.0)
	var start_distance: float = game.player_pos.distance_to(well)
	var boss_start: Vector2 = game.boss_pos
	_step(0.6)
	_check(game.player_pos.distance_to(well) < start_distance - 40.0, "well did not pull the player (%.1f)" % game.player_pos.distance_to(well))
	var frame: Dictionary = Pres.gravity_frame(game)
	_check(String(frame["key"]) in ["boss4_rework_hop", "boss4_rework_gravity", "boss4_rework_gravity_v2"], "unexpected gravity frame key")
	# Mantem o jogador fora do nucleo para medir so os saltos.
	var rings_seen: int = 0
	var airborne_seen := false
	var max_lift: float = 0.0
	for _i in range(75):
		game.player_pos = well + Vector2(0.0, 260.0)
		_step(0.02)
		if String(game.boss4_ai_state.get("hop_phase", "")) == ctrl.HOP_PHASE_AIR:
			airborne_seen = true
			max_lift = maxf(max_lift, game.boss_pos.y - Pres.draw_position(game).y)
		rings_seen = maxi(rings_seen, _count("boss4_shock_ring"))
	_check(airborne_seen, "boss did not hop around the well")
	_check(max_lift > 30.0, "orbit hop has no visible height (%.1f)" % max_lift)
	_check(game.boss_pos.distance_to(boss_start) > 100.0, "boss did not move while orbiting")
	_check(absf(game.boss_pos.distance_to(well) - ctrl.WELL_ORBIT_RADIUS) < 40.0, "boss did not land on the orbit ring (%.1f)" % game.boss_pos.distance_to(well))
	_check(rings_seen >= 1, "orbit hops spawned no shock rings")
	# Fica no centro ate a implosao.
	hp_before = float(game.player_hp)
	for _i in range(40):
		game.player_pos = well
		_step(0.02)
	_check(float(game.player_hp) < hp_before, "core/implosion did not damage a player at the center")
	_step(0.2)
	_check(String(game.boss4_ai_state.get("action", "")) != "gravity" or String(game.boss4_ai_state["state"]) == ctrl.STATE_RECOVER, "gravity did not reach recover")

	# Dash resiste ao puxao.
	_setup()
	game.phase4_enemy_hazards.clear()
	game.player_pos = game.boss_pos + Vector2(-340.0, 0.0)
	ctrl.force_action_for_test("gravity")
	well = Vector2(game.boss4_ai_state["well_pos"])
	_step(0.84)
	game.player_pos = well + Vector2(200.0, 0.0)
	_step(0.4, true)
	_check(game.player_pos.distance_to(well) > 195.0, "dashing player was still pulled")
	_step(3.0)
	_check(_count("boss4_singularity") == 0, "well was not cleaned up after its life")
	if failed:
		return
	print("BOSS4_GRAVITY_OK windup_safe=true spawn=true pull=true orbit_hops=true rings=true core_burst=true dash=true cleanup=true")
	quit(0)
