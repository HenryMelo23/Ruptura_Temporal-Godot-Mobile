extends SceneTree

## Matriarca (rework): rasteja por passos ate a distancia desejada, mergulha
## (imune), o monte persegue, avisa, irrompe com dano e volta a ficar de pe.

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
	push_error("BOSS6_BURROW_FAIL " + message)
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
		game._update_boss_phase6(0.02)


func _run() -> void:
	_setup()
	var ctrl = game.boss6_controller
	game.boss6_ai_state["burrow_cd"] = 99.0
	# 1) Rastejar: aproxima por passos (velocidade varia), olha para o jogador.
	game.player_pos = game.boss_pos + Vector2(-450.0, 0.0)
	var start: Vector2 = game.boss_pos
	var speeds: Array = []
	for _i in range(40):
		var before: Vector2 = game.boss_pos
		_step(0.02)
		speeds.append(game.boss_pos.distance_to(before) / 0.02)
	_check(ctrl.mode() == ctrl.MODE_CRAWL, "boss did not crawl toward a distant player")
	_check(game.boss_pos.x < start.x - 15.0, "crawl did not move toward the player")
	_check(ctrl.facing() < 0.0, "boss is not facing the player on the left")
	_check(speeds.max() > speeds.min() * 1.8, "crawl speed is constant (sliding)")
	# Para perto da distancia desejada.
	game.player_pos = game.boss_pos + Vector2(-ctrl.DESIRED_DISTANCE, 0.0)
	_step(0.1)
	_check(ctrl.mode() == ctrl.MODE_IDLE, "boss kept crawling at the desired distance")

	# 2) Mergulho completo.
	_setup()
	game.player_pos = game.boss_pos + Vector2(-480.0, 120.0)
	ctrl.start_burrow()
	_step(ctrl.SUBMERGE_TIME + 0.04)
	_check(ctrl.mode() == ctrl.MODE_TRAVEL, "boss did not go underground after submerging")
	var hp_before: float = game.boss_hp
	game._damage_boss(500.0, "test")
	_check(is_equal_approx(game.boss_hp, hp_before), "burrowed boss took damage")
	var travel_t := 0.0
	while ctrl.mode() == ctrl.MODE_TRAVEL and travel_t < 3.0:
		_step(0.02)
		travel_t += 0.02
	_check(ctrl.mode() == ctrl.MODE_WARN, "mound did not stop to warn")
	var emerge_at: Vector2 = Vector2(game.boss6_ai_state["emerge_at"])
	_check(emerge_at.distance_to(game.player_pos) <= ctrl.EMERGE_OFFSET + 40.0, "emerge point is not near the player")
	var player_hp: float = game.player_hp
	_step(ctrl.WARN_TIME + 0.06)
	_check(ctrl.mode() == ctrl.MODE_EMERGE, "boss did not emerge after the warning")
	_check(game.boss_pos.is_equal_approx(emerge_at), "boss did not surface at the warned point")
	_check(game.player_hp < player_hp, "emerging under the player dealt no damage")
	_step(ctrl.EMERGE_TIME + 0.04)
	_check(not ctrl.is_burrow_busy(), "burrow did not finish")
	_check(float(game.boss6_ai_state["burrow_cd"]) > 0.0, "burrow cooldown not set")

	# 3) Dash no aviso escapa do dano.
	_setup()
	game.player_pos = game.boss_pos + Vector2(-300.0, 0.0)
	ctrl.start_burrow()
	_step(ctrl.SUBMERGE_TIME + 0.04)
	while ctrl.mode() == ctrl.MODE_TRAVEL:
		_step(0.02)
	player_hp = game.player_hp
	game.last_dash_time = game.time_alive + ctrl.WARN_TIME
	_step(ctrl.WARN_TIME + 0.06)
	_check(is_equal_approx(game.player_hp, player_hp), "dash did not avoid the emerge hit")

	# 4) Jogador longe dispara o mergulho sozinho quando a recarga acaba.
	_setup()
	game.boss6_ai_state["burrow_cd"] = 0.0
	var inward: Vector2 = (game.WORLD_SIZE * 0.5 - game.boss_pos)
	inward = inward.normalized() if inward.length() > 50.0 else Vector2.LEFT
	game.player_pos = game.boss_pos + inward * 700.0
	_step(0.04)
	_check(ctrl.is_burrow_busy(), "far player did not trigger the burrow")
	# 5) Virada de estagio cancela o mergulho e devolve o corpo.
	_step(ctrl.SUBMERGE_TIME + 0.1)
	game.boss_hp = game.boss_hp_max * 0.6
	game.boss6_stage_controller.update(0.02)
	_check(not ctrl.is_burrow_busy(), "stage transition did not cancel the burrow")
	_check(game.save_controller._interrupted_run_field_names().has("boss6_ai_state"), "save omitted boss6_ai_state")
	if failed:
		return
	print("BOSS6_BURROW_OK crawl=steps facing=true idle_at_range=true submerge=true immune=true chase=true warn=true emerge_hit=true dash=true auto_far=true stage_cancel=true save=true")
	quit(0)
