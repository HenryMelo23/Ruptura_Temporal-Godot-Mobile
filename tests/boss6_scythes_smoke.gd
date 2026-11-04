extends SceneTree

## Matriarca (rework): Foices Vertebrais: ondas em cone que re-miram no disparo, acertam
## uma vez por onda, poupam quem esta atras ou da dash.

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
	push_error("BOSS6_SCYTHES_FAIL " + message)
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


func _scythe() -> Dictionary:
	for attack in game.boss_attacks:
		if String(Dictionary(attack).get("kind", "")) == game.BOSS6_ABILITY_SCYTHES:
			return attack
	return {}


func _run() -> void:
	_setup()
	var ctrl = game.boss6_controller
	game.boss_attacks.clear()
	game.player_pos = game.boss_pos + Vector2(-300.0, 0.0)
	game._start_boss6_vertebral_scythes()
	var attack: Dictionary = _scythe()
	var waves: Array = Array(attack.get("waves", []))
	_check(waves.size() == 2, "stage 1 should have two waves")
	_check(float(Dictionary(waves[0])["side"]) != float(Dictionary(waves[1])["side"]), "waves do not alternate the sweep side")
	var hp0: float = game.player_hp
	_step(0.44)
	var hp1: float = game.player_hp
	_check(hp1 < hp0, "first wave missed a player inside the cone")
	var single: float = hp0 - hp1
	# O jogador se move; a segunda onda re-mira no disparo.
	game.player_pos = game.boss_pos + Vector2(0.0, 300.0)
	_step(0.1)
	attack = _scythe()
	var second: Dictionary = Array(attack["waves"])[1]
	_check(absf(angle_difference(float(second["angle"]), PI * 0.5)) < 0.2, "second wave did not re-aim at the moved player")
	_step(0.6)
	_check(game.player_hp < hp1, "second wave missed the moved player")
	_check(hp1 - game.player_hp <= single * 1.05 + 1.0, "a wave hit more than once")

	# Atras dela nao toma dano.
	_setup()
	game.boss_attacks.clear()
	game.player_pos = game.boss_pos + Vector2(-300.0, 0.0)
	game._start_boss6_vertebral_scythes()
	game.player_pos = game.boss_pos + Vector2(300.0, 0.0)
	var waves2: Array = Array(_scythe()["waves"])
	for w in waves2:
		Dictionary(w)["aimed"] = true
		Dictionary(w)["angle"] = PI
	hp0 = game.player_hp
	_step(2.0)
	_check(is_equal_approx(game.player_hp, hp0), "player behind the boss was hit")

	# Dash atravessa.
	_setup()
	game.boss_attacks.clear()
	game.player_pos = game.boss_pos + Vector2(-300.0, 0.0)
	game._start_boss6_vertebral_scythes()
	hp0 = game.player_hp
	for _i in range(100):
		game.last_dash_time = game.time_alive
		_step(0.02)
	_check(is_equal_approx(game.player_hp, hp0), "dashing player was hit by a scythe wave")
	_check(_scythe().is_empty(), "scythe attack did not expire")

	# Estagio 3: tres ondas mais rapidas.
	_setup()
	game.boss6_stage = 3
	var w3: Array = ctrl.build_scythe_waves()
	_check(w3.size() == 3, "stage 3 should sweep three waves")
	_check(ctrl.scythe_duration(w3, 3) < 2.0, "stage 3 scythes are too slow")
	if failed:
		return
	print("BOSS6_SCYTHES_OK waves=2/3 alternate=true hit=true reaim=true single_hit=true behind_safe=true dash=true expire=true")
	quit(0)
