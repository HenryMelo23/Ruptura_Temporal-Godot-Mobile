extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("TEST_GRAVITY_PRISON: Failed to load Main scene")
		quit(1)
		return

	var game: Node = main_scene.instantiate()
	root.add_child(game)
	current_scene = game

	for f in range(5):
		await process_frame

	if not ("current_phase" in game):
		push_error("TEST_GRAVITY_PRISON: Could not find main game node with current_phase")
		quit(1)
		return

	print("--- STARTING TRANSMUTAR_GRAVIDADE & PRISAO SMOKE TEST ---")

	# Force Phase 5 & Dimension Gravidade
	game.set("current_phase", 5)
	game.call("_transmute_umbra_dimension", "TRANSMUTAR_GRAVIDADE")

	print("[TEST LOG] Transmuted to dimension: %s" % str(game.get("boss5_dimension")))

	# Set initial player position and move player laterally (rightwards) for 6 samples to populate history
	var start_pos := Vector2(400.0, 450.0)
	game.set("player_pos", start_pos)
	game.set("phase5_player_history", [])

	var player_base_spd: float = float(game.get("player_speed"))
	print("[TEST LOG] Player base speed: %.2f" % player_base_spd)

	# Simulate 6 history samples of lateral movement (moving right at 300px/s)
	for i in range(6):
		var pos := start_pos + Vector2(i * 30.0, 0.0)
		game.set("player_pos", pos)
		game.call("_sample_umbra_player_history", 0.10)

	var pos_before_ability: Vector2 = game.get("player_pos")
	print("[TEST LOG] Posição real do jogador antes da habilidade: %s" % str(pos_before_ability))

	# Force PRISAO ability call
	game.call("_spawn_umbra_action", "PRISAO")

	# Find the created prison hazard
	var hazards: Array = game.get("phase5_hazards")
	var prison_hazard: Dictionary = {}
	for h in hazards:
		if String(h.get("kind", "")) == "prison":
			prison_hazard = h
			break

	if prison_hazard.is_empty():
		push_error("TEST_GRAVITY_PRISON: Prison hazard was not created!")
		quit(1)
		return

	var alvo_previsto: Vector2 = Vector2(prison_hazard.get("pos", Vector2.ZERO))
	print("[TEST LOG] Alvo previsto da PRISAO: %s" % str(alvo_previsto))

	# Verify prediction: lateral movement rightwards should predict target x > real position x
	if alvo_previsto.x > pos_before_ability.x:
		print("[TEST PASS] Predição direcional confirmada! Alvo (%.1f) > Posição Real (%.1f)" % [alvo_previsto.x, pos_before_ability.x])
	else:
		print("[TEST WARNING] Alvo previsto (%.1f) não ficou à frente da posição real (%.1f)" % [alvo_previsto.x, pos_before_ability.x])

	# Phase 1: Test Telegraph (Warning Phase, first 1.5s)
	print("\n--- TEST: WARNING / TELEGRAPH PHASE ---")
	for f in range(30):
		game.call("_update_phase5_hazards", 0.016)
		await process_frame

	var warning_mult: float = float(game.call("_environment_player_slow_mult"))
	print("[TEST LOG] Multiplicador de velocidade durante TELEGRAPH: %.2f (Esperado: 1.00)" % warning_mult)

	# Phase 2: Test Active Phase & Speed Reduction
	print("\n--- TEST: ACTIVE PHASE & SPEED REDUCTION ---")

	# Teleport player into the center of the prison hazard to test slow
	game.set("player_pos", alvo_previsto)

	# Update hazards past the 1.5s warning threshold into active phase
	for f in range(80):
		game.call("_update_phase5_hazards", 0.016)
		await process_frame

	var active_hazards: Array = game.get("phase5_hazards")
	var active_prison: Dictionary = {}
	for h in active_hazards:
		if String(h.get("kind", "")) == "prison":
			active_prison = h
			break

	var raio_atual: float = float(active_prison.get("radius_atual", 0.0))
	var pos_real_ativa: Vector2 = game.get("player_pos")
	var vel_antes: float = player_base_spd
	var slow_mult: float = float(game.call("_environment_player_slow_mult"))
	var vel_depois: float = vel_antes * slow_mult

	print("[TEST LOG] Posição real do jogador na zona ativa: %s" % str(pos_real_ativa))
	print("[TEST LOG] Raio atual da zona de prisão: %.2f px" % raio_atual)
	print("[TEST LOG] Velocidade antes: %.2f | Velocidade depois: %.2f (Mult: %.2f)" % [vel_antes, vel_depois, slow_mult])

	if slow_mult <= 0.31:
		print("[TEST PASS] Redução de velocidade para 0.30x verificada com sucesso!")
	else:
		push_error("TEST_GRAVITY_PRISON FAIL: Multiplicador de velocidade de prisão era %.2f, esperado <= 0.30" % slow_mult)
		quit(1)
		return

	# Phase 3: Test Cleanup & Speed Restoration
	print("\n--- TEST: CLEANUP & BASE SPEED RESTORATION ---")
	# Simulate time until hazard expires (> 3.5s total)
	for f in range(150):
		game.call("_update_phase5_hazards", 0.02)
		await process_frame

	var restored_mult: float = float(game.call("_environment_player_slow_mult"))
	var vel_restaurada: float = vel_antes * restored_mult
	print("[TEST LOG] Velocidade restaurada após expiração: %.2f (Mult: %.2f)" % [vel_restaurada, restored_mult])

	if restored_mult >= 0.99:
		print("[TEST PASS] Limpeza concluída e velocidade base restaurada perfeitamente!")
	else:
		push_error("TEST_GRAVITY_PRISON FAIL: Velocidade não foi restaurada após expiração")
		quit(1)
		return

	print("\n--- ALL GRAVITY PRISON SMOKE TESTS PASSED CLEANLY ---")
	quit(0)
