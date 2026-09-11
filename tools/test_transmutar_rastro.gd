extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("TEST_RASTRO: Failed to load Main scene")
		quit(1)
		return

	var game: Node = main_scene.instantiate()
	root.add_child(game)
	current_scene = game

	for f in range(5):
		await process_frame

	if not ("current_phase" in game):
		push_error("TEST_RASTRO: Could not find main game node with current_phase")
		quit(1)
		return

	print("--- STARTING TRANSMUTAR_RASTRO & PRAGA_RATOS SMOKE TEST ---")

	# 1. Force Phase 5 & Transmutar Rastro
	game.set("current_phase", 5)
	game.set("boss_active", true)
	var boss_hp_max: float = 10000.0
	game.set("boss_hp_max", boss_hp_max)
	game.set("boss_hp", 5000.0) # start half HP to verify 0.2% heal (20 HP)
	var world_size: Vector2 = game.get("WORLD_SIZE")

	game.call("_transmute_umbra_dimension", "TRANSMUTAR_RASTRO")

	var current_dim: String = String(game.get("boss5_dimension"))
	var map_key: String = String(game.call("_boss5_dimension_map_key", current_dim))
	print("[TEST LOG] Transmuted to dimension: %s | Map Key: %s" % [current_dim, map_key])

	if map_key != "map_phase_9":
		push_error("TEST_RASTRO FAIL: Expected map_key map_phase_9 for rastro, got %s" % map_key)
		quit(1)
		return

	# 2. Test initial spawn with PRAGA_RATOS
	game.call("_spawn_umbra_action", "PRAGA_RATOS")

	var rats: Array = game.get("phase5_rats")
	print("[TEST LOG] Spawner spawned %d rats. Active rats: %d" % [rats.size(), rats.size()])

	if rats.size() != 4:
		push_error("TEST_RASTRO FAIL: Expected 4 initial rats (1 per corner), got %d" % rats.size())
		quit(1)
		return

	# Verify 4 corners positions
	var corners_found: Array[int] = []
	for r in rats:
		var c_idx: int = int(r.get("corner_idx", -1))
		corners_found.append(c_idx)

	print("[TEST LOG] Corners spawned: %s" % [corners_found])
	if corners_found.size() < 4:
		push_error("TEST_RASTRO FAIL: Rats did not spawn in 4 corners!")
		quit(1)
		return

	# ==========================================
	# 3. TEST PLAYER COLLISION, DAMAGE, HEAL & EXTRAS
	# ==========================================
	print("\n--- TEST COLISÃO, DANO, CURA E EXTRAS ---")

	var extras_before: int = int(game.get("boss5_rat_extras"))
	var player_hp_before: int = int(game.get("player_hp"))
	var boss_hp_before: float = float(game.get("boss_hp"))

	# Move player right on top of rat 0
	var first_rat: Dictionary = rats[0]
	var rat_pos: Vector2 = Vector2(first_rat.get("pos", Vector2.ZERO))
	game.set("player_pos", rat_pos)
	game.set("invulnerable_timer", 0.0)

	# Update rats by 0.05s to trigger collision
	game.call("_update_phase5_rats", 0.05)
	await process_frame

	var extras_after: int = int(game.get("boss5_rat_extras"))
	var player_hp_after: int = int(game.get("player_hp"))
	var boss_hp_after: float = float(game.get("boss_hp"))

	var damage_dealt: int = player_hp_before - player_hp_after
	var boss_healed: float = boss_hp_after - boss_hp_before
	var active_rats_after_hit: int = (game.get("phase5_rats") as Array).size()

	print("[TEST LOG] RAT HIT RESULT:")
	print("  - Extras Antes: %d | Extras Depois: %d" % [extras_before, extras_after])
	print("  - Player HP Antes: %d | Player HP Depois: %d | Dano Causado: %d (esperado: 80)" % [player_hp_before, player_hp_after, damage_dealt])
	print("  - Umbra HP Antes: %.1f | Umbra HP Depois: %.1f | Cura Umbra: %.1f (esperado: 20.0 = 0.2%% de 10000)" % [boss_hp_before, boss_hp_after, boss_healed])
	print("  - Ratos Ativos Restantes: %d (esperado: 3)" % active_rats_after_hit)

	if extras_after != extras_before + 1:
		push_error("TEST_RASTRO FAIL: Expected rat extras to increment from %d to %d, got %d" % [extras_before, extras_before + 1, extras_after])
		quit(1)
		return

	if damage_dealt != 80:
		push_error("TEST_RASTRO FAIL: Expected 80 damage, got %d" % damage_dealt)
		quit(1)
		return

	if absf(boss_healed - 20.0) > 0.1:
		push_error("TEST_RASTRO FAIL: Expected 20.0 heal for Umbra, got %.1f" % boss_healed)
		quit(1)
		return

	if active_rats_after_hit != 3:
		push_error("TEST_RASTRO FAIL: Rat did not disappear on hit! Remaining: %d" % active_rats_after_hit)
		quit(1)
		return

	# ==========================================
	# 4. TEST SPAWN WITH EXTRAS & CAP OF 40
	# ==========================================
	print("\n--- TEST SPAWN COM EXTRAS E CAP DE 40 ---")
	# Force boss5_rat_extras to 4 (max)
	game.set("boss5_rat_extras", 4)
	# Spawn 5 waves (8 rats each = 40 rats max)
	for w in range(6):
		game.call("_spawn_umbra_action", "PRAGA_RATOS")

	var total_rats: int = (game.get("phase5_rats") as Array).size()
	print("[TEST LOG] Total de ratos após múltiplas ondas com extras = 4: %d (Cap: 40)" % total_rats)

	if total_rats > 40:
		push_error("TEST_RASTRO FAIL: Rat cap of 40 exceeded! Current: %d" % total_rats)
		quit(1)
		return

	# ==========================================
	# 5. TEST DIMENSION CLEANUP
	# ==========================================
	print("\n--- TEST LIMPEZA AO TROCAR DE DIMENSÃO ---")
	game.call("_transmute_umbra_dimension", "TRANSMUTAR_ATRITO")

	var rats_after_transmute: int = (game.get("phase5_rats") as Array).size()
	var new_dim: String = String(game.get("boss5_dimension"))
	print("[TEST LOG] Nova dimensão: %s | Ratos restantes: %d (esperado: 0)" % [new_dim, rats_after_transmute])

	if rats_after_transmute != 0:
		push_error("TEST_RASTRO FAIL: Rats were not cleared upon leaving rastro dimension! Count: %d" % rats_after_transmute)
		quit(1)
		return

	print("\n--- ALL TRANSMUTAR_RASTRO & PRAGA_RATOS SMOKE TESTS PASSED CLEANLY ---")
	quit(0)
