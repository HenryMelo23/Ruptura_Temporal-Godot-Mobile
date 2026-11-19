extends SceneTree
## Solo: Fragmento Instável, Impulso de Ruptura e Colapso Dimensional no
## runtime real (Main.tscn). Não abre rede.
## godot4 --headless --path . --script tests/dimension_rupture_smoke.gd

const UserFileGuard = preload("res://tests/support/user_file_guard.gd")
const R := preload("res://scripts/systems/phase/dimension_rupture_controller.gd")

var game: Node
var failures: Array[String] = []
var save_guard: UserFileGuard
var config_guard: UserFileGuard


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	save_guard = UserFileGuard.new("user://interrupted_run.save")
	config_guard = UserFileGuard.new("user://hud_config.save")
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _rupture() -> RTDimensionRuptureController:
	return game._dimension_rupture()


func _prepare(phase: int) -> void:
	game.run_tutorial_enabled = false
	game.is_multiplayer = false
	game._start_game()
	game.mode = "game"
	game.current_phase = phase
	game.time_alive = 900.0
	game.boss_active = false
	game.boss_entry_timer = 0.0
	game.phase_fragment = {}
	game.is_dead = false
	game.player_hp = float(game.player_hp_max)


## Mata o "objetivo": o portal nasce pelo owner de fase (mesmo caminho do chefe).
func _complete_objective(next_phase: int) -> void:
	game._phase_flow()._spawn_phase_fragment(Vector2(900, 700), next_phase)


func _cross_and_arrive(next_phase: int) -> void:
	game._phase_flow()._start_phase_transition(next_phase)
	var target: int = int(game.pending_phase)
	game._phase_flow()._advance_to_phase(target)
	game.mode = "game"
	game.time_alive = 900.0


func _tick(seconds: float, step: float = 0.5) -> void:
	var left := seconds
	while left > 0.0001:
		var d := minf(step, left)
		_rupture().update(d)
		left -= d


func _common_card() -> Dictionary:
	for value in game.CARDS:
		var card: Dictionary = value
		if game._card_available_for_reward(card, true, true) and game._card_rarity_key(card) == game.CARD_RARITY_COMMON:
			return card
	return {}


func _run() -> void:
	_test_constants()
	_test_clock_not_on_entry_and_single_activation()
	_test_bands_and_momentum()
	_test_token_consumption()
	_test_rarity_lock()
	_test_suspension()
	_test_miniboss_activation()
	_test_collapse_emergency_ejection()
	_test_save_resume()
	_test_new_run_clears()
	_finish()


func _test_constants() -> void:
	_check(is_equal_approx(R.FAST_WINDOW_SECONDS, 60.0), "FAST_WINDOW_SECONDS")
	_check(is_equal_approx(R.STANDARD_WINDOW_SECONDS, 120.0), "STANDARD_WINDOW_SECONDS")
	_check(is_equal_approx(R.COLLAPSE_START_SECONDS, 120.0), "COLLAPSE_START_SECONDS")
	_check(is_equal_approx(R.COLLAPSE_TOTAL_SECONDS, 180.0), "COLLAPSE_TOTAL_SECONDS")
	_check(is_equal_approx(R.EMERGENCY_ESCAPE_SECONDS, 18.0), "EMERGENCY_ESCAPE_SECONDS")
	_check(R.MAX_MOMENTUM_STACKS == 4, "MAX_MOMENTUM_STACKS")


func _test_clock_not_on_entry_and_single_activation() -> void:
	_prepare(2)
	_tick(240.0)
	_check(_rupture().current_state() == R.STATE_INACTIVE, "clock started on dimension entry")
	_complete_objective(3)
	_check(_rupture().current_state() == R.STATE_UNSTABLE, "fragment not activated by objective")
	var event_id := String(_rupture().state["event_id"])
	_check(event_id != "", "missing event_id")
	_check(not _rupture().activate(R.SOURCE_OBJECTIVE, 2), "second activation in same cycle")
	_complete_objective(3)
	_check(String(_rupture().state["event_id"]) == event_id, "portal respawn created a second fragment")
	_check(not _rupture().activate("debug", 2), "unauthorized source activated")


func _test_bands_and_momentum() -> void:
	_prepare(2)
	_complete_objective(3)
	_tick(59.0)
	_check(_rupture().current_band() == R.BAND_PERFECT, "59s should be perfect")
	var epoch_before := int(_rupture().state["epoch"])
	_cross_and_arrive(3)
	_check(_rupture().momentum() == 1, "perfect crossing did not add momentum")
	_check(String(_rupture().pending_token().get("tier", "")) == R.BAND_PERFECT, "perfect token missing")
	_check(int(_rupture().pending_token().get("attempts", 0)) == 2, "perfect token attempts != 1 + momentum")
	_check(int(_rupture().state["epoch"]) == epoch_before + 1, "epoch did not advance on arrival")
	_check(_rupture().current_state() == R.STATE_INACTIVE, "fragment survived into new dimension")

	_complete_objective(4)
	_tick(90.0)
	_check(_rupture().current_band() == R.BAND_STABLE, "90s should be stable")
	_cross_and_arrive(4)
	_check(_rupture().momentum() == 1, "stable crossing changed momentum")
	_check(String(_rupture().pending_token().get("tier", "")) == R.BAND_STABLE and int(_rupture().pending_token().get("attempts", 0)) == 1, "stable token wrong")

	_complete_objective(6)
	_tick(150.0)
	_check(_rupture().current_state() == R.STATE_COLLAPSE, "150s should be collapse")
	_cross_and_arrive(6)
	_check(_rupture().momentum() == 0, "weakened crossing kept momentum")
	_check(_rupture().pending_token().is_empty(), "weakened crossing granted token")

	# Cinco travessias perfeitas: teto em IV.
	var phases := [3, 4, 6, 7, 8]
	for i in range(5):
		_complete_objective(phases[i])
		_tick(10.0)
		_cross_and_arrive(phases[i])
	_check(_rupture().momentum() == R.MAX_MOMENTUM_STACKS, "momentum cap broken: %d" % _rupture().momentum())
	_check(int(_rupture().pending_token().get("attempts", 0)) == 1 + R.MAX_MOMENTUM_STACKS, "IV token attempts wrong")
	_check(R.roman(4) == "IV" and R.roman(1) == "I", "roman labels")


func _test_token_consumption() -> void:
	_prepare(3)
	var card := _common_card()
	_check(not card.is_empty(), "no common card with drop texture")
	_rupture().state["token"] = {"event_id": "tok-a", "tier": R.BAND_PERFECT, "attempts": 3}
	game.arauto_card_drops.clear()
	game._append_owned_card_drop(card, game.player_pos, 0.0, 0, 20.0, 50.0, 90.0, 80.0, 140.0, {"suturer_returned": true})
	_check(not _rupture().pending_token().is_empty(), "Suturador-returned card consumed the token")
	game._append_owned_card_drop(card, game.player_pos, 0.0, 0, 20.0, 50.0, 90.0, 80.0, 140.0)
	_check(_rupture().pending_token().is_empty(), "first natural card did not consume token")
	_check(Dictionary(_rupture().state["consumed_tokens"]).has("tok-a"), "consumption not recorded")
	game._append_owned_card_drop(card, game.player_pos, 0.0, 0, 20.0, 50.0, 90.0, 80.0, 140.0)
	_check(game.arauto_card_drops.size() == 3, "token changed the number of cards: %d" % game.arauto_card_drops.size())
	# Pacote/estado repetido com o mesmo token não reaplica.
	_rupture().state["token"] = {"event_id": "tok-a", "tier": R.BAND_PERFECT, "attempts": 3}
	var again: Dictionary = _rupture().apply_quality_token(card, 0, {})
	_check(again == card and _rupture().pending_token().is_empty(), "consumed token applied twice")


func _test_rarity_lock() -> void:
	_prepare(3)
	game.time_alive = 1200.0 # rampa de raridade no máximo
	var card := _common_card()
	_check(not game._rare_cards_unlocked(), "fixture unexpectedly has rare unlocked")
	var improved := 0
	for i in range(60):
		_rupture().state["token"] = {"event_id": "lock-%d" % i, "tier": R.BAND_PERFECT, "attempts": 5}
		var out: Dictionary = _rupture().apply_quality_token(card, 0, {})
		var rarity := String(game._card_rarity_key(out))
		_check(rarity != game.CARD_RARITY_RARE and rarity != game.CARD_RARITY_LEGENDARY, "token bypassed rarity lock: " + rarity)
		_check(game._card_available_for_reward(out, true, true), "token produced an unavailable card")
		if out != card:
			improved += 1
	_check(improved > 0, "token never improved quality in 60 tries")


func _test_suspension() -> void:
	_prepare(2)
	_tick(1.0)
	game._phase_flow()._spawn_phase_fragment(Vector2(900, 700), 3)
	_tick(5.0)
	var base := float(_rupture().state["elapsed"])
	game.mode = "paused"
	_tick(30.0)
	_check(is_equal_approx(float(_rupture().state["elapsed"]), base), "solo pause advanced clock")
	_check(String(_rupture().state["suspend_reason"]) == R.SUSPEND_MENU, "pause suspend reason")
	game.mode = "phase_transition"
	_tick(30.0)
	_check(is_equal_approx(float(_rupture().state["elapsed"]), base), "transition advanced clock")
	game.mode = "game"
	game.boss_active = true
	game.boss_entry_timer = 3.0
	_tick(2.0)
	_check(is_equal_approx(float(_rupture().state["elapsed"]), base), "boss intro advanced clock")
	game.boss_active = false
	game.boss_entry_timer = 0.0
	_tick(2.0)
	_check(is_equal_approx(float(_rupture().state["elapsed"]), base + 2.0), "clock did not resume")


func _test_miniboss_activation() -> void:
	_prepare(8)
	# Estado de miniboss que já chega derrotado (visita anterior) não ativa.
	game.sertao_controller.miniboss_defeated = true
	_tick(2.0)
	_check(_rupture().current_state() == R.STATE_INACTIVE, "persisted miniboss flag activated fragment")
	game.sertao_controller.miniboss_defeated = false
	_tick(1.0)
	game.sertao_controller.miniboss_defeated = true
	_tick(1.0)
	_check(_rupture().current_state() == R.STATE_UNSTABLE, "miniboss kill did not activate")
	_check(String(_rupture().state["source"]) == R.SOURCE_MINIBOSS, "wrong source")
	_tick(60.0)
	_check(is_equal_approx(float(_rupture().state["elapsed"]), 0.0), "clock ran while the portal was locked")
	_check(String(_rupture().state["suspend_reason"]) == R.SUSPEND_PORTAL_LOCKED, "portal lock not reported")
	var event_id := String(_rupture().state["event_id"])
	_complete_objective(9)
	_check(String(_rupture().state["event_id"]) == event_id, "boss kill created second fragment after miniboss")
	_tick(4.0)
	_check(is_equal_approx(float(_rupture().state["elapsed"]), 4.0), "clock did not start once portal opened")
	game.sertao_controller.miniboss_defeated = false


func _test_collapse_emergency_ejection() -> void:
	_prepare(3)
	game.dimension_route_queue = [6, 8, 2]
	_complete_objective(4)
	_rupture().state["momentum"] = 3
	_rupture().state["token"] = {"event_id": "old", "tier": R.BAND_PERFECT, "attempts": 4}
	var score_before := int(game.score)
	var drops_before: int = game.arauto_card_drops.size()
	var enemies_before: int = game.enemies.size()
	_tick(130.0)
	_check(_rupture().current_state() == R.STATE_COLLAPSE, "collapse did not start at 120s")
	_check(_rupture().collapse_intensity() > 0.0 and _rupture().collapse_intensity() < 1.0, "collapse intensity")
	_tick(50.0)
	_check(_rupture().current_state() == R.STATE_EMERGENCY, "emergency did not start at 180s")
	var dst := int(_rupture().state["eject_target"])
	_check(dst > 0 and dst != 3 and dst != int(game.DIMENSION_FINAL_PHASE), "bad ejection target %d" % dst)
	_check(String(game.event_alert_text) == R.MSG_EMERGENCY, "emergency message missing")
	_check(int(game.score) == score_before and game.arauto_card_drops.size() == drops_before and game.enemies.size() == enemies_before, "collapse generated rewards or enemies")
	game.player_hp = float(game.player_hp_max) * 0.1
	_tick(17.5)
	_check(_rupture().current_state() == R.STATE_EMERGENCY, "ejected before 18s")
	_tick(1.0)
	_check(game.mode == "phase_transition" and int(game.pending_phase) == dst, "ejection did not start group transition to %d (pending %d)" % [dst, int(game.pending_phase)])
	_check(_rupture().momentum() == 0 and _rupture().pending_token().is_empty(), "ejection kept momentum/token")
	_check(is_equal_approx(_rupture().disorientation_remaining(), R.DISORIENTATION_SECONDS), "disorientation not applied")
	var expected_route: Array = R.route_after_ejection([6, 8, 2], dst, 4)
	_check(Array(game.dimension_route_queue) == expected_route and not expected_route.has(dst), "route not adjusted after ejection: %s (dst %d)" % [str(game.dimension_route_queue), dst])
	_check(dst != 4 and int(expected_route[0]) == 4, "ejection reused normal next or did not requeue it")
	# Eject repetido não aplica nada de novo.
	_check(not _rupture().eject(), "second ejection accepted")
	game._phase_flow()._advance_to_phase(dst)
	game.mode = "game"
	_tick(0.1)
	_check(float(game.player_hp) >= float(game.player_hp_max) * 0.5, "arrival HP floor not applied")
	_check(String(game.event_alert_text) == R.MSG_EJECTED, "ejection arrival message missing")
	_check(is_equal_approx(_rupture().move_speed_multiplier(), R.DISORIENTATION_MOVE_MULT), "disorientation slow missing")
	_check(game._environment_player_slow_mult() <= R.DISORIENTATION_MOVE_MULT + 0.001, "runtime ignores disorientation")
	_tick(20.0)
	_check(is_equal_approx(_rupture().move_speed_multiplier(), 1.0), "disorientation did not expire")
	# Correção de vida não ressuscita nem mata.
	game.is_dead = true
	game.player_hp = 0.0
	_check(not _rupture().apply_arrival_hp_floor("other-event"), "HP floor revived a dead player")
	_check(float(game.player_hp) == 0.0, "HP floor touched a dead player")
	game.is_dead = false
	game.player_hp = 10.0
	_check(not _rupture().apply_arrival_hp_floor("other-event"), "HP floor applied twice for same event")
	# Destino determinístico e nunca a dimensão atual.
	for i in range(40):
		var candidates := R.eligible_ejection_targets(3, 4, [3, 5, 6, 8], 5)
		var pick := R.pick_deterministic(candidates, "ev-%d" % i, "run")
		_check(pick != 3 and pick != 5 and pick > 0, "pick returned invalid %d" % pick)
		_check(pick == R.pick_deterministic(candidates, "ev-%d" % i, "run"), "pick not deterministic")


func _test_save_resume() -> void:
	_prepare(4)
	_complete_objective(6)
	_tick(75.0)
	_rupture().state["momentum"] = 2
	_rupture().state["token"] = {"event_id": "saved-tok", "tier": R.BAND_STABLE, "attempts": 1}
	_check("dimension_rupture_state" in game.save_controller._interrupted_run_field_names(), "field missing from interrupted save list")
	var saved = str_to_var(var_to_str(game.dimension_rupture_state))
	var event_id := String(_rupture().state["event_id"])
	var epoch := int(_rupture().state["epoch"])
	var run_id := String(_rupture().state["run_id"])
	# Retomada: mesmo caminho do save controller (start_game(false) + set).
	game._start_game(false)
	_check(_rupture().current_state() == R.STATE_INACTIVE, "start_game(false) did not reset before restore")
	game.current_phase = 4
	game.phase_fragment = {"pos": Vector2(900, 700), "next_phase": 6, "pulse": 0.0, "life": 0.0}
	game.mode = "game"
	game.dimension_rupture_state = saved
	_check(String(_rupture().state["event_id"]) == event_id and int(_rupture().state["epoch"]) == epoch and String(_rupture().state["run_id"]) == run_id, "resume changed event identity")
	_check(is_equal_approx(float(_rupture().state["elapsed"]), 75.0), "resume counted offline time or lost clock")
	_check(_rupture().momentum() == 2 and String(_rupture().pending_token().get("event_id", "")) == "saved-tok", "resume lost momentum/token")
	_check(not _rupture().activate(R.SOURCE_OBJECTIVE, 4), "resume re-activated the fragment")
	_tick(1.0)
	_check(is_equal_approx(float(_rupture().state["elapsed"]), 76.0), "clock not running after resume")
	# Save de outra dimensão: descarta o fragmento, mantém Impulso/token.
	game._start_game(false)
	game.current_phase = 7
	game.dimension_rupture_state = saved
	_check(_rupture().current_state() == R.STATE_INACTIVE and String(_rupture().state["event_id"]) == "", "foreign-dimension fragment restored")
	_check(_rupture().momentum() == 2, "foreign-dimension save lost momentum")
	# Save antigo sem o campo: padrão, sem erro.
	game._start_game(false)
	game.dimension_rupture_state = {}
	_check(_rupture().current_state() == R.STATE_INACTIVE and _rupture().momentum() == 0, "legacy save defaults")


func _test_new_run_clears() -> void:
	_prepare(4)
	_complete_objective(6)
	_rupture().state["momentum"] = 3
	_rupture().state["token"] = {"event_id": "x", "tier": R.BAND_PERFECT, "attempts": 4}
	_rupture().state["disorientation"] = 9.0
	var old_run := String(_rupture().state["run_id"])
	game._start_game()
	_check(_rupture().current_state() == R.STATE_INACTIVE, "new run kept fragment")
	_check(_rupture().momentum() == 0 and _rupture().pending_token().is_empty() and _rupture().disorientation_remaining() == 0.0, "new run kept momentum/token/disorientation")
	_check(String(_rupture().state["run_id"]) != old_run, "new run reused run_id")


func _finish() -> void:
	game.mode = "menu"
	game.set_physics_process(false)
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	save_guard.restore()
	config_guard.restore()
	if failures.is_empty():
		print("DIMENSION_RUPTURE_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			printerr("DIMENSION_RUPTURE_SMOKE_FAIL " + failure)
		quit(1)
