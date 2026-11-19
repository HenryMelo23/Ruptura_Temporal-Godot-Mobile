extends SceneTree

## Boss 4: Raio do Capacete varre um arco de 110 graus, acerta com cooldown
## por alvo, o dash atravessa e o visual escolhe quadros sem o raio pintado.

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
	push_error("BOSS4_BEAM_FAIL " + message)
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


func _step(seconds: float) -> void:
	var steps: int = int(round(seconds / 0.02))
	for _i in range(steps):
		game.time_alive += 0.02
		game.boss4_controller.update(0.02)


func _run() -> void:
	_setup()
	var ctrl = game.boss4_controller
	var Pres = game.Boss4AnimationPresentation
	game.player_pos = game.boss_pos + Vector2(-320.0, 0.0)
	ctrl.force_action_for_test("comet")
	ctrl.update(0.01)
	var ai: Dictionary = game.boss4_ai_state
	var arc: float = absf(angle_difference(float(ai["beam_from"]), float(ai["beam_to"])))
	_check(absf(arc - ctrl.BEAM_ARC) < 0.01, "beam arc is not 110 degrees (%.3f)" % arc)
	var mid: float = lerp_angle(float(ai["beam_from"]), float(ai["beam_to"]), 0.5)
	var to_player: float = (game.player_pos - game.boss_pos).angle()
	_check(absf(angle_difference(mid, to_player)) < 0.35, "beam arc is not centered on the player")
	var frame: Dictionary = Pres.comet_frame(game)
	_check(int(frame["index"]) != 2 or String(frame["key"]) == "boss4_rework_comet_v2", "windup used the frame with the painted beam")
	var hp_before: float = float(game.player_hp)
	_step(0.6)
	_check(String(ai["state"]) == ctrl.STATE_WINDUP, "beam left windup too early")
	_check(is_equal_approx(float(game.player_hp), hp_before), "player was hit during the beam windup")
	# Varredura: o angulo anda de from para to.
	_step(0.15)
	_check(String(ai["state"]) == ctrl.STATE_ACTIVE, "beam did not reach the active phase")
	var start_angle: float = float(ai["beam_angle"])
	_step(0.9)
	var swept: float = absf(angle_difference(start_angle, float(ai["beam_angle"])))
	_check(swept > ctrl.BEAM_ARC * 0.7, "beam did not sweep the arc (%.3f)" % swept)
	_check(float(game.player_hp) < hp_before, "sweeping beam missed a player in the arc")
	var hits_taken: float = hp_before - float(game.player_hp)
	var single: float = float(game._boss4_damage(0.06, 26.0))
	_check(hits_taken <= single * 4.0 + 1.0, "beam hit too many times (%.1f)" % hits_taken)

	# Dash atravessa o raio.
	_setup()
	game.player_pos = game.boss_pos + Vector2(-320.0, 0.0)
	ctrl.force_action_for_test("comet")
	ctrl.update(0.01)
	hp_before = float(game.player_hp)
	for _i in range(85):
		game.time_alive += 0.02
		game.last_dash_time = game.time_alive
		ctrl.update(0.02)
	_check(is_equal_approx(float(game.player_hp), hp_before), "dashing player was hit by the beam")

	# Fora do alcance nao toma dano.
	_setup()
	game.player_pos = game.boss_pos + Vector2(-320.0, 0.0)
	ctrl.force_action_for_test("comet")
	ctrl.update(0.01)
	game.player_pos = game.boss_pos + Vector2(ctrl.BEAM_RANGE + 140.0, 0.0)
	hp_before = float(game.player_hp)
	_step(2.3)
	_check(is_equal_approx(float(game.player_hp), hp_before), "beam hit a player behind the boss out of range")
	_check(String(game.boss4_ai_state.get("action", "")) != "comet", "beam action did not finish")
	if failed:
		return
	print("BOSS4_BEAM_OK arc=true centered=true windup_safe=true sweep=true hit=true dash=true range=true")
	quit(0)
