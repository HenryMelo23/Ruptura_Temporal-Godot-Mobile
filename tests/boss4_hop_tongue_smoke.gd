extends SceneTree

## Boss 4: locomocao por saltos (sem deslizar), Lingua-Arpao (mira que trava,
## acerto puxa + tapa, dash solta, erro puxa o boss) e anel do Salto Esmagador.

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
	push_error("BOSS4_HOP_TONGUE_FAIL " + message)
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


func _run() -> void:
	_setup()
	var ctrl = game.boss4_controller
	game.player_pos = game.boss_pos + Vector2(-360.0, 0.0)
	# 1) Salto: parado na preparacao, desloca so no ar, pousa.
	game.boss4_ai_state["hop_t"] = 99.0
	ctrl.update(0.01)
	_check(String(game.boss4_ai_state["hop_phase"]) == "prep", "hop did not start with preparation")
	var before: Vector2 = game.boss_pos
	ctrl.update(ctrl.HOP_PREP * 0.8)
	_check(game.boss_pos.is_equal_approx(before), "boss slid during hop preparation")
	ctrl.update(ctrl.HOP_PREP * 0.3)
	ctrl.update(ctrl.HOP_PUSH + 0.01)
	_check(String(game.boss4_ai_state["hop_phase"]) == "air", "hop did not reach the air phase")
	ctrl.update(ctrl.HOP_AIR * 0.5)
	_check(game.boss_pos.distance_to(before) > 20.0, "boss did not travel while airborne")
	_check(game.Boss4AnimationPresentation.draw_position(game).y < game.boss_pos.y - 20.0, "hop has no visible height")
	ctrl.update(ctrl.HOP_AIR * 0.6)
	_check(String(game.boss4_ai_state["hop_phase"]) == "impact", "hop did not land")
	var travelled: float = game.boss_pos.distance_to(before)
	_check(travelled >= ctrl.HOP_DISTANCE_RANGE.x - 1.0 and travelled <= ctrl.HOP_DISTANCE_RANGE.y + 1.0, "hop length out of range: %.1f" % travelled)

	# 2) Lingua: mira acompanha, depois trava.
	_setup()
	game.player_pos = game.boss_pos + Vector2(-300.0, 0.0)
	ctrl.force_action_for_test("tongue")
	ctrl.update(0.1)
	game.player_pos = game.boss_pos + Vector2(-300.0, 120.0)
	ctrl.update(0.1)
	var tracked: Vector2 = Vector2(game.boss4_ai_state["attack_dir"])
	_check(tracked.y > 0.2, "tongue aim did not follow the player while tracking")
	ctrl.update(0.15)
	_check(bool(game.boss4_ai_state["aim_locked"]), "tongue aim did not lock")
	var locked: Vector2 = Vector2(game.boss4_ai_state["attack_dir"])
	game.player_pos = game.boss_pos + Vector2(-300.0, -200.0)
	ctrl.update(0.05)
	_check(Vector2(game.boss4_ai_state["attack_dir"]).is_equal_approx(locked), "locked aim still followed the player")

	# 3) Acerto: puxa e da o tapa.
	_setup()
	game.player_pos = game.boss_pos + Vector2(-260.0, 0.0)
	ctrl.force_action_for_test("tongue")
	for _step in range(12):
		ctrl.update(0.05)
	var hp_start: float = game.player_hp
	var distance_start: float = game.player_pos.distance_to(game.boss_pos)
	ctrl.update(0.05)
	_check(bool(game.boss4_ai_state["tongue_hit"]), "tongue missed a player on its line")
	_check(game.player_hp < hp_start, "tongue hit dealt no damage")
	for _step in range(5):
		ctrl.update(0.05)
	_check(game.player_pos.distance_to(game.boss_pos) < distance_start - 60.0, "tongue did not pull the player")
	var hp_before_slap: float = game.player_hp
	for _step in range(4):
		ctrl.update(0.05)
	_check(game.player_hp < hp_before_slap, "grab did not end with the slap")

	# 4) Dash solta a lingua: sem tapa.
	_setup()
	game.player_pos = game.boss_pos + Vector2(-260.0, 0.0)
	ctrl.force_action_for_test("tongue")
	for _step in range(6):
		ctrl.update(0.1)
	for _step in range(4):
		ctrl.update(0.05)
	game.last_dash_time = game.time_alive
	ctrl.update(0.05)
	_check(bool(game.boss4_ai_state["tongue_broken"]), "dash did not break the grab")
	var hp_after_break: float = game.player_hp
	for _step in range(10):
		ctrl.update(0.05)
	_check(is_equal_approx(game.player_hp, hp_after_break), "broken grab still slapped")

	# 5) Erro: a lingua gruda e o sapo se puxa.
	_setup()
	game.player_pos = game.boss_pos + Vector2(0.0, -420.0)
	ctrl.force_action_for_test("tongue")
	for _step in range(3):
		ctrl.update(0.1)
	game.player_pos = game.boss_pos + Vector2(600.0, 500.0)
	for _step in range(3):
		ctrl.update(0.1)
	var boss_before_pull: Vector2 = game.boss_pos
	for _step in range(9):
		ctrl.update(0.05)
	_check(not bool(game.boss4_ai_state["tongue_hit"]), "tongue hit a player far from its line")
	_check(game.boss_pos.distance_to(boss_before_pull) > 80.0, "missed tongue did not pull the boss")

	# 6) Salto Esmagador: anel acerta quem esta na frente da onda; dash atravessa.
	_setup()
	game.phase4_enemy_hazards.clear()
	var center: Vector2 = game.boss_pos
	game.phase4_enemy_hazards.append({"kind": "boss4_shock_ring", "center": center, "age": 0.0, "life": ctrl.SHOCK_RING_LIFE, "max": ctrl.SHOCK_RING_LIFE, "hit": {}})
	var ring: Dictionary = game.phase4_enemy_hazards[0]
	ring["age"] = ctrl.SHOCK_RING_LIFE * 0.5
	var radius: float = ctrl.shock_ring_radius(0.5)
	game.player_pos = center + Vector2(radius, 0.0)
	var hp_ring: float = game.player_hp
	ctrl.update(0.0)
	_check(game.player_hp < hp_ring, "shock ring did not hit a player on its front")
	var hp_once: float = game.player_hp
	ctrl.update(0.0)
	_check(is_equal_approx(game.player_hp, hp_once), "shock ring hit twice")
	ring["hit"] = {}
	game.last_dash_time = game.time_alive
	var hp_dash: float = game.player_hp
	ctrl.update(0.0)
	_check(is_equal_approx(game.player_hp, hp_dash), "dash did not pass through the shock ring")
	if failed:
		return
	print("BOSS4_HOP_TONGUE_OK hop=prep_air_land no_slide=true aim_lock=true grab_pull_slap=true dash_break=true miss_self_pull=true shock_ring=true")
	quit(0)
